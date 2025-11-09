import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

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
    let basePrice = estimatedFare || 1000; // 優先使用客戶端傳遞的 estimatedFare
    let depositRate = 0.3; // 預設訂金比例 30%
    let vehicleCategory = 'small'; // ✅ 提升到外層作用域，預設小型車

    // 如果有價格配置，使用配置的訂金比例
    // ⚠️ 只有當 estimatedFare 不存在或為 0 時，才使用配置的價格作為後備
    if (pricingConfig && pricingConfig.vehicleTypes) {
      try {
        // 確定車型類別（假設 packageName 包含車型資訊）
        if (packageName && (packageName.includes('8人') || packageName.includes('9人'))) {
          vehicleCategory = 'large';
        }

        // 只有當 estimatedFare 不存在或為 0 時，才使用配置的價格
        if (!estimatedFare || estimatedFare === 0) {
          const vehicleType = pricingConfig.vehicleTypes[vehicleCategory];
          if (vehicleType) {
            // 預設使用 8 小時套餐
            const packageType = vehicleType.packages['8_hours'] || vehicleType.packages['6_hours'];
            if (packageType) {
              basePrice = packageType.discount_price || packageType.original_price || basePrice;
              console.log('[API] ⚠️  estimatedFare 不存在，使用配置價格:', basePrice, '車型:', vehicleCategory);
            }
          }
        } else {
          console.log('[API] ✅ 使用客戶端傳遞的 estimatedFare:', estimatedFare, '車型:', vehicleCategory);
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

    // 4. 模擬支付處理
    // 實際應該調用支付網關 API
    console.log('[API] 模擬支付處理:', {
      amount: booking.deposit_amount,
      method: paymentMethod
    });

    // 5. 創建支付記錄
    const transactionId = `txn_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const paymentData = {
      booking_id: bookingId,
      customer_id: booking.customer_id, // ✅ 添加必填欄位
      transaction_id: transactionId,
      type: 'deposit', // ✅ 修復：使用 'type' 而不是 'payment_type'
      amount: booking.deposit_amount,
      currency: 'TWD', // ✅ 添加 currency 欄位
      status: 'completed', // 支付成功
      payment_provider: 'mock', // ✅ 添加支付提供者
      payment_method: paymentMethod || 'cash',
      is_test_mode: true, // ✅ 添加測試模式標記
      confirmed_at: new Date().toISOString(), // ✅ 修復：使用 'confirmed_at' 而不是 'paid_at'
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

    // 6. 更新訂單狀態
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'paid_deposit', // 已付訂金
        updated_at: new Date().toISOString()
      })
      .eq('id', bookingId);

    if (updateError) {
      console.error('[API] 更新訂單狀態失敗:', updateError);
      res.status(500).json({
        success: false,
        error: '更新訂單狀態失敗'
      });
      return;
    }

    console.log('[API] ✅ 訂金支付成功');

    // 7. 返回成功響應
    res.json({
      success: true,
      data: {
        bookingId,
        paymentId: payment.id,
        transactionId: payment.transaction_id,
        status: 'paid_deposit',
        depositAmount: booking.deposit_amount,
        paidAt: payment.paid_at
      },
      message: '訂金支付成功'
    });

  } catch (error: any) {
    console.error('[API] 支付訂金失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '支付訂金失敗'
    });
  }
});

/**
 * @route GET /api/bookings/:bookingId
 * @desc 獲取訂單詳情（直接從 Supabase 讀取）
 * @access Public（用於支付完成後即時獲取訂單狀態）
 */
router.get('/:bookingId', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;

    console.log('[API] 獲取訂單詳情:', { bookingId });

    // 從 Supabase 查詢訂單
    const { data: booking, error } = await supabase
      .from('bookings')
      .select('*')
      .eq('id', bookingId)
      .single();

    if (error || !booking) {
      console.error('[API] 查詢訂單失敗:', error);
      res.status(404).json({
        success: false,
        error: '訂單不存在'
      });
      return;
    }

    console.log('[API] ✅ 訂單查詢成功:', booking.id);

    // 狀態映射：將 Supabase 狀態映射為 Flutter APP 期望的狀態
    const statusMapping: { [key: string]: string } = {
      'pending_payment': 'pending',       // 待付訂金 → 待配對
      'paid_deposit': 'pending',          // 已付訂金 → 待配對（等待派單）
      'assigned': 'awaitingDriver',       // 已分配司機 → 待司機確認
      'matched': 'awaitingDriver',        // 手動派單 → 待司機確認
      'driver_confirmed': 'matched',      // 司機確認後 → 已配對
      'driver_departed': 'inProgress',    // 司機已出發 → 進行中
      'driver_arrived': 'inProgress',     // 司機已到達 → 進行中
      'trip_started': 'inProgress',       // 行程開始 → 進行中
      'trip_ended': 'awaitingBalance',    // 行程結束 → 待付尾款
      'pending_balance': 'awaitingBalance', // 待付尾款 → 待付尾款
      'in_progress': 'inProgress',
      'completed': 'completed',           // 訂單完成 → 已完成
      'cancelled': 'cancelled',           // 已取消 → 已取消
    };

    const mappedStatus = statusMapping[booking.status] || 'pending';

    // 返回訂單資訊（包含映射後的狀態）
    res.status(200).json({
      success: true,
      data: {
        ...booking,
        status: mappedStatus  // 使用映射後的狀態
      }
    });

  } catch (error: any) {
    console.error('[API] 獲取訂單失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '獲取訂單失敗'
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

