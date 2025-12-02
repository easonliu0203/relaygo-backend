import { Router } from 'express';
import { BookingFlowController } from '../controllers/BookingFlowController';
import { authMiddleware } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { rateLimitMiddleware } from '../middleware/rateLimit';

const router = Router();
const bookingFlowController = new BookingFlowController();

// 驗證中間件
const requireAuth = authMiddleware;
const requireCustomer = [authMiddleware, (req: any, res: any, next: any) => {
  // ✅ 修復：檢查 roles 陣列是否包含 'customer'，支援多角色用戶
  if (!req.user?.roles || !req.user.roles.includes('customer')) {
    return res.status(403).json({ success: false, error: 'Customer access required' });
  }
  next();
}];
const requireDriver = [authMiddleware, (req: any, res: any, next: any) => {
  // ✅ 修復：檢查 roles 陣列是否包含 'driver'，支援多角色用戶
  if (!req.user?.roles || !req.user.roles.includes('driver')) {
    return res.status(403).json({ success: false, error: 'Driver access required' });
  }
  next();
}];
const requireAdmin = [authMiddleware, (req: any, res: any, next: any) => {
  // ✅ 修復：檢查 roles 陣列是否包含 'admin'，支援多角色用戶
  if (!req.user?.roles || !req.user.roles.includes('admin')) {
    return res.status(403).json({ success: false, error: 'Admin access required' });
  }
  next();
}];

// 請求驗證規則
const createBookingValidation = validateRequest({
  body: {
    vehicleType: { type: 'string', required: true, enum: ['A', 'B', 'C', 'D'] },
    startDate: { type: 'string', required: true, format: 'date' },
    startTime: { type: 'string', required: true, format: 'time' },
    duration: { type: 'number', required: true, min: 6, max: 12 },
    pickupLocation: { type: 'string', required: true, minLength: 5 },
    pickupLatitude: { type: 'number', required: false },
    pickupLongitude: { type: 'number', required: false },
    specialRequirements: { type: 'string', required: false, maxLength: 500 }
  }
});

const payDepositValidation = validateRequest({
  body: {
    paymentMethod: { type: 'string', required: false, enum: ['mock', 'offline'] }
  }
});

const manualDispatchValidation = validateRequest({
  body: {
    driverId: { type: 'string', required: true, format: 'uuid' }
  }
});

// ==================== 客戶端路由 ====================

/**
 * @route POST /api/booking-flow/bookings
 * @desc 創建新預約
 * @access Customer
 */
router.post('/bookings', 
  rateLimitMiddleware({ windowMs: 15 * 60 * 1000, max: 10 }), // 15分鐘內最多10次
  requireCustomer,
  createBookingValidation,
  bookingFlowController.createBooking.bind(bookingFlowController)
);

/**
 * @route POST /api/booking-flow/bookings/:bookingId/deposit
 * @desc 支付訂金
 * @access Customer
 */
router.post('/bookings/:bookingId/deposit',
  rateLimitMiddleware({ windowMs: 5 * 60 * 1000, max: 5 }), // 5分鐘內最多5次
  requireCustomer,
  payDepositValidation,
  bookingFlowController.payDeposit.bind(bookingFlowController)
);

/**
 * @route POST /api/booking-flow/bookings/:bookingId/start-trip
 * @desc 客戶開始行程
 * @access Customer
 */
router.post('/bookings/:bookingId/start-trip',
  requireCustomer,
  bookingFlowController.startTrip.bind(bookingFlowController)
);

/**
 * @route POST /api/booking-flow/bookings/:bookingId/end-trip
 * @desc 客戶結束行程
 * @access Customer
 */
router.post('/bookings/:bookingId/end-trip',
  requireCustomer,
  bookingFlowController.endTrip.bind(bookingFlowController)
);

// ==================== 司機端路由 ====================

/**
 * @route POST /api/booking-flow/bookings/:bookingId/accept
 * @desc 司機確認接單
 * @access Driver
 */
router.post('/bookings/:bookingId/accept',
  requireDriver,
  bookingFlowController.driverAcceptBooking.bind(bookingFlowController)
);

/**
 * @route POST /api/booking-flow/bookings/:bookingId/reject
 * @desc 司機拒絕接單
 * @access Driver
 */
router.post('/bookings/:bookingId/reject',
  requireDriver,
  async (req: any, res: any) => {
    // TODO: 實作司機拒絕接單邏輯
    res.json({ success: true, message: 'Booking rejected' });
  }
);

/**
 * @route POST /api/booking-flow/bookings/:bookingId/depart
 * @desc 司機出發
 * @access Driver
 */
router.post('/bookings/:bookingId/depart',
  requireDriver,
  bookingFlowController.driverDepart.bind(bookingFlowController)
);

/**
 * @route POST /api/booking-flow/bookings/:bookingId/arrive
 * @desc 司機到達
 * @access Driver
 */
router.post('/bookings/:bookingId/arrive',
  requireDriver,
  bookingFlowController.driverArrive.bind(bookingFlowController)
);

// ==================== 管理員路由 ====================

/**
 * @route POST /api/booking-flow/admin/bookings/:bookingId/assign
 * @desc 手動派單
 * @access Admin
 */
router.post('/admin/bookings/:bookingId/assign',
  requireAdmin,
  manualDispatchValidation,
  bookingFlowController.manualDispatch.bind(bookingFlowController)
);

/**
 * @route POST /api/booking-flow/admin/bookings/:bookingId/auto-dispatch
 * @desc 觸發自動派單
 * @access Admin
 */
router.post('/admin/bookings/:bookingId/auto-dispatch',
  requireAdmin,
  async (req: any, res: any) => {
    try {
      const { bookingId } = req.params;
      const { dispatchService } = require('../services/dispatch/DispatchService');
      
      const result = await dispatchService.autoDispatch(bookingId);
      
      res.json({
        success: result.success,
        data: result,
        message: result.message
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

/**
 * @route GET /api/booking-flow/admin/bookings/pending-dispatch
 * @desc 獲取待派單的預約列表
 * @access Admin
 */
router.get('/admin/bookings/pending-dispatch',
  requireAdmin,
  async (req: any, res: any) => {
    try {
      // TODO: 實作獲取待派單預約列表
      res.json({
        success: true,
        data: {
          bookings: [],
          total: 0
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

/**
 * @route GET /api/booking-flow/admin/dispatch/config
 * @desc 獲取派單配置
 * @access Admin
 */
router.get('/admin/dispatch/config',
  requireAdmin,
  async (req: any, res: any) => {
    try {
      const { dispatchService } = require('../services/dispatch/DispatchService');
      const config = dispatchService.getAutoDispatchConfig();
      
      res.json({
        success: true,
        data: config
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

/**
 * @route PUT /api/booking-flow/admin/dispatch/config
 * @desc 更新派單配置
 * @access Admin
 */
router.put('/admin/dispatch/config',
  requireAdmin,
  validateRequest({
    body: {
      enabled: { type: 'boolean', required: false },
      maxRadius: { type: 'number', required: false, min: 1, max: 50 },
      maxRetryAttempts: { type: 'number', required: false, min: 1, max: 10 },
      retryDelayMs: { type: 'number', required: false, min: 1000, max: 300000 }
    }
  }),
  async (req: any, res: any) => {
    try {
      const { dispatchService } = require('../services/dispatch/DispatchService');
      dispatchService.updateAutoDispatchConfig(req.body);
      
      res.json({
        success: true,
        message: 'Dispatch configuration updated'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// ==================== 通用路由 ====================

/**
 * @route GET /api/booking-flow/bookings/:bookingId
 * @desc 獲取預約詳情
 * @access Authenticated
 */
router.get('/bookings/:bookingId',
  requireAuth,
  async (req: any, res: any) => {
    try {
      const { bookingId } = req.params;
      const userId = req.user.id;
      const userRole = req.user.role;
      
      // TODO: 實作獲取預約詳情，並檢查權限
      
      res.json({
        success: true,
        data: {
          booking: null // TODO: 返回預約資料
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

/**
 * @route GET /api/booking-flow/bookings/:bookingId/status
 * @desc 獲取預約狀態
 * @access Authenticated
 */
router.get('/bookings/:bookingId/status',
  requireAuth,
  async (req: any, res: any) => {
    try {
      const { bookingId } = req.params;
      
      // TODO: 實作獲取預約狀態
      
      res.json({
        success: true,
        data: {
          bookingId,
          status: 'pending_payment', // TODO: 從資料庫獲取實際狀態
          statusDisplayName: '待付訂金',
          availableActions: ['pay_deposit', 'cancel'],
          lastUpdated: new Date()
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

/**
 * @route POST /api/booking-flow/bookings/:bookingId/cancel
 * @desc 取消預約
 * @access Customer/Admin
 */
router.post('/bookings/:bookingId/cancel',
  requireAuth,
  validateRequest({
    body: {
      reason: { type: 'string', required: true, minLength: 5, maxLength: 200 }
    }
  }),
  async (req: any, res: any) => {
    try {
      const { bookingId } = req.params;
      const { reason } = req.body;
      const userId = req.user.id;
      const userRole = req.user.role;
      
      // TODO: 實作取消預約邏輯
      
      res.json({
        success: true,
        message: 'Booking cancelled successfully'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

export default router;
