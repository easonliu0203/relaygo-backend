import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { getPaymentService } from '../services/payment';

dotenv.config();

const router = Router();

// 初始化 Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

/**
 * @route POST /api/bookings
 * @desc 創建新訂單
 * @access Customer
 */
router.post('/', async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      customerUid,
      pickupAddress,
      pickupLatitude,
      pickupLongitude,
      dropoffAddress,
      // dropoffLatitude,
      // dropoffLongitude,
      bookingTime,
      passengerCount,
      // luggageCount,
      notes,
      // packageId,
      packageName,
      estimatedFare,
    } = req.body;

    console.log('[API] 創建訂單:', {
      customerUid,
      pickupAddress,
      bookingTime,
      passengerCount,
    });

    // 1. 驗證必填欄位
    if (!customerUid) {
      res.status(400).json({
        success: false,
        error: '缺少客戶 UID'
      });
      return;
    }

    if (!pickupAddress || !pickupLatitude || !pickupLongitude) {
      res.status(400).json({
        success: false,
        error: '缺少上車地點資訊'
      });
      return;
    }

    if (!bookingTime) {
      res.status(400).json({
        success: false,
        error: '缺少預約時間'
      });
      return;
    }

    // 2. 驗證客戶是否存在
    const { data: customer, error: customerError } = await supabase
      .from('users')
      .select('id, email, role')
      .eq('firebase_uid', customerUid)
      .eq('role', 'customer')
      .single();

    if (customerError || !customer) {
      console.error('[API] 查詢客戶失敗:', customerError);
      res.status(404).json({
        success: false,
        error: '客戶不存在或非客戶角色'
      });
      return;
    }

    console.log('[API] 客戶資料:', customer);

    // 3. 生成訂單編號
    const bookingNumber = `BK${Date.now()}`;

    // 4. 從 system_settings 讀取價格配置
    const { data: pricingSettings, error: pricingError } = await supabase
      .from('system_settings')
      .select('value')
      .eq('key', 'pricing_config')
      .single();

    if (pricingError) {
      console.error('[API] 讀取價格配置失敗:', pricingError);
    }

    const pricingConfig = pricingSettings?.value || null;
    console.log('[API] 價格配置:', pricingConfig);

    // 5. 計算訂單金額
    let basePrice = estimatedFare || 1000; // 預設基本費用
    let depositRate = 0.3; // 預設訂金比例 30%
    let vehicleCategory = 'small'; // ✅ 提升到外層作用域，預設小型車

    // 如果有價格配置，使用配置的價格
    if (pricingConfig && pricingConfig.vehicleTypes) {
      try {
        // 確定車型類別（假設 packageName 包含車型資訊）
        if (packageName && (packageName.includes('8人') || packageName.includes('9人'))) {
          vehicleCategory = 'large';
        }

        // 獲取對應車型的價格配置
        const vehicleType = pricingConfig.vehicleTypes[vehicleCategory];
        if (vehicleType) {
          // 預設使用 8 小時套餐
          const packageType = vehicleType.packages['8_hours'] || vehicleType.packages['6_hours'];
          if (packageType) {
            basePrice = packageType.discount_price || packageType.original_price || basePrice;
            console.log('[API] 使用配置價格:', basePrice, '車型:', vehicleCategory);
          }
        }

        // 使用配置的訂金比例
        if (pricingConfig.depositRate) {
          depositRate = pricingConfig.depositRate;
        }
      } catch (error) {
        console.error('[API] 解析價格配置失敗:', error);
      }
    }

    const foreignLanguageSurcharge = 0; // 外語加價
    const overtimeFee = 0; // 超時費用
    const tipAmount = 0; // 小費
    const totalAmount = basePrice + foreignLanguageSurcharge + overtimeFee + tipAmount;
    const depositAmount = Math.round(totalAmount * depositRate);

    console.log('[API] 計算費用:', {
      basePrice,
      depositRate,
      totalAmount,
      depositAmount
    });

    // 6. 解析預約時間
    const bookingDateTime = new Date(bookingTime);
    const startDate = bookingDateTime.toISOString().split('T')[0]; // YYYY-MM-DD
    const startTime = bookingDateTime.toTimeString().split(' ')[0]; // HH:MM:SS

    // 6. 創建訂單
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .insert({
        customer_id: customer.id, // 使用 users.id，不是 firebase_uid
        driver_id: null, // 尚未分配司機
        booking_number: bookingNumber,
        status: 'pending_payment', // 待付訂金
        start_date: startDate,
        start_time: startTime,
        duration_hours: 8, // 預設 8 小時，可以從套餐資訊中獲取
        vehicle_type: vehicleCategory, // ✅ 修復：使用 vehicleCategory ('small' 或 'large')，不是 packageName
        pickup_location: pickupAddress,
        pickup_latitude: pickupLatitude,
        pickup_longitude: pickupLongitude,
        destination: dropoffAddress || '',
        special_requirements: notes || '',
        requires_foreign_language: false, // 可以從請求中獲取
        base_price: basePrice,
        foreign_language_surcharge: foreignLanguageSurcharge,
        overtime_fee: overtimeFee,
        tip_amount: tipAmount,
        total_amount: totalAmount,
        deposit_amount: depositAmount,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (bookingError) {
      console.error('[API] 創建訂單失敗:', bookingError);
      res.status(500).json({
        success: false,
        error: '創建訂單失敗: ' + bookingError.message
      });
      return;
    }

    console.log('[API] ✅ 訂單創建成功:', booking.id);

    // 7. 返回訂單資訊
    res.status(200).json({
      success: true,
      data: {
        id: booking.id,
        bookingNumber: booking.booking_number,
        status: booking.status,
        customerId: booking.customer_id,
        pickupLocation: booking.pickup_location,
        destination: booking.destination,
        startDate: booking.start_date,
        startTime: booking.start_time,
        totalAmount: booking.total_amount,
        depositAmount: booking.deposit_amount,
        createdAt: booking.created_at,
      },
      message: '訂單創建成功'
    });

  } catch (error: any) {
    console.error('[API] 創建訂單失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '創建訂單失敗'
    });
  }
});

/**
 * @route POST /api/bookings/:bookingId/pay-deposit
 * @desc 支付訂金
 * @access Customer
 */
router.post('/:bookingId/pay-deposit', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { paymentMethod, customerUid } = req.body;

    console.log('[API] 支付訂金:', { bookingId, paymentMethod, customerUid });

    // 1. 查詢訂單
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('*')
      .eq('id', bookingId)
      .single();

    if (bookingError || !booking) {
      console.error('[API] 查詢訂單失敗:', bookingError);
      res.status(404).json({
        success: false,
        error: '訂單不存在'
      });
      return;
    }

    // 2. 驗證客戶權限（需要查詢 users 表獲取 user.id）
    const { data: user } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', customerUid)
      .single();

    if (!user || booking.customer_id !== user.id) {
      res.status(403).json({
        success: false,
        error: '無權限操作此訂單'
      });
      return;
    }

    // 3. 檢查訂單狀態
    if (booking.status !== 'pending_payment') {
      res.status(400).json({
        success: false,
        error: `訂單狀態不正確（當前: ${booking.status}，需要: pending_payment）`
      });
      return;
    }

    // 4. 調用支付服務發起支付
    console.log('[API] 發起支付:', {
      amount: booking.deposit_amount,
      method: paymentMethod
    });

    try {
      const paymentService = getPaymentService();
      const paymentResult = await paymentService.processPayment({
        orderId: booking.booking_number,
        amount: booking.deposit_amount,
        currency: 'TWD',
        description: `包車服務訂金 - ${booking.booking_number}`,
        customerInfo: {
          id: user.id,  // ✅ 修復：使用 'id' 而不是 'customerId'
          email: '', // 可以從 users 表獲取
          phone: ''  // 可以從 users 表獲取
        },
        metadata: {
          bookingId: bookingId,
          paymentType: 'deposit'
        }
      });

      console.log('[API] 支付服務響應:', paymentResult);

      // 5. 創建支付記錄
      const paymentData = {
        booking_id: bookingId,
        customer_id: booking.customer_id,
        transaction_id: paymentResult.transactionId,
        type: 'deposit',
        amount: booking.deposit_amount,
        currency: 'TWD',
        status: paymentResult.success ? 'pending' : 'failed',  // ✅ 修復：根據 success 判斷狀態
        payment_provider: 'mock',
        payment_method: paymentMethod || 'cash',
        payment_url: paymentResult.paymentUrl, // ✅ 添加支付 URL
        is_test_mode: true,
        expires_at: paymentResult.expiresAt,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const { data: payment, error: paymentError } = await supabase
        .from('payments')
        .insert(paymentData)
        .select()
        .single();

      if (paymentError) {
        console.error('[API] 創建支付記錄失敗:', paymentError);
        res.status(500).json({
          success: false,
          error: '創建支付記錄失敗'
        });
        return;
      }

      console.log('[API] ✅ 支付記錄創建成功:', payment.id);

      // 6. 返回支付 URL 讓客戶端跳轉
      res.json({
        success: true,
        data: {
          bookingId,
          paymentId: payment.id,
          transactionId: payment.transaction_id,
          status: payment.status,  // ✅ 修復：使用 payment.status 而不是 paymentResult.status
          depositAmount: booking.deposit_amount,
          paymentUrl: paymentResult.paymentUrl, // ✅ 返回支付 URL
          expiresAt: paymentResult.expiresAt
        },
        message: '請跳轉到支付頁面完成支付'
      });

    } catch (paymentError: any) {
      console.error('[API] 支付服務失敗:', paymentError);
      res.status(500).json({
        success: false,
        error: paymentError.message || '支付服務失敗'
      });
    }

  } catch (error: any) {
    console.error('[API] 支付訂金失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '支付訂金失敗'
    });
  }
});

/**
 * @route GET /api/bookings/test
 * @desc 測試路由
 */
router.get('/test', (_req: Request, res: Response) => {
  res.json({
    success: true,
    message: 'Bookings API is working',
    timestamp: new Date().toISOString()
  });
});

export default router;

