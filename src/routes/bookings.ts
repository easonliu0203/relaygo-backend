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
    // ✅ 修復：優先使用客戶選擇的套餐價格（estimatedFare）
    // 只有在客戶沒有選擇套餐時，才使用配置的預設價格
    let basePrice = 1000; // 預設基本費用（降級方案）
    let depositRate = 0.3; // 預設訂金比例 30%
    let vehicleCategory = 'small'; // ✅ 提升到外層作用域，預設小型車

    // 優先使用客戶傳遞的 estimatedFare
    if (estimatedFare && estimatedFare > 0) {
      basePrice = estimatedFare;
      console.log('[API] ✅ 使用客戶選擇的套餐價格:', basePrice);
    } else {
      // 降級：如果客戶沒有選擇套餐，使用配置的預設價格
      console.log('[API] ⚠️ 客戶未選擇套餐，使用配置的預設價格');

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
        } catch (error) {
          console.error('[API] 解析價格配置失敗:', error);
        }
      }
    }

    // 使用配置的訂金比例
    if (pricingConfig && pricingConfig.depositRate) {
      depositRate = pricingConfig.depositRate;
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

    // 2. 驗證客戶權限並獲取完整用戶資料（包含 user_profiles）
    const { data: user } = await supabase
      .from('users')
      .select(`
        id,
        email,
        phone,
        user_profiles:user_profiles(first_name, last_name, phone)
      `)
      .eq('firebase_uid', customerUid)
      .single();

    if (!user || booking.customer_id !== user.id) {
      res.status(403).json({
        success: false,
        error: '無權限操作此訂單'
      });
      return;
    }

    // 3. 構建客戶姓名（優先使用 user_profiles，否則使用 booking.customer_name）
    const userProfile = Array.isArray(user.user_profiles) ? user.user_profiles[0] : user.user_profiles;
    const customerName = userProfile?.first_name && userProfile?.last_name
      ? `${userProfile.last_name}${userProfile.first_name}`
      : booking.customer_name || '客戶';

    // 4. 構建客戶電話（優先使用 users.phone，否則使用 user_profiles.phone 或 booking.customer_phone）
    const customerPhone = user.phone || userProfile?.phone || booking.customer_phone || '';

    // 5. 構建客戶信箱（從 users.email 獲取）
    const customerEmail = user.email || '';

    // 6. 檢查訂單狀態
    if (booking.status !== 'pending_payment') {
      res.status(400).json({
        success: false,
        error: `訂單狀態不正確（當前: ${booking.status}，需要: pending_payment）`
      });
      return;
    }

    // 7. 使用 PaymentProviderFactory 發起支付
    const { PaymentProviderFactory, PaymentProviderType } = await import('../services/payment/PaymentProvider');

    // 根據環境變數決定使用哪個支付提供者
    const paymentProviderType = process.env.PAYMENT_PROVIDER === 'gomypay'
      ? PaymentProviderType.GOMYPAY
      : PaymentProviderType.MOCK;

    console.log('[API] 使用支付提供者:', paymentProviderType);

    const provider = PaymentProviderFactory.createProvider({
      provider: paymentProviderType,
      isTestMode: process.env.GOMYPAY_TEST_MODE === 'true',
      config: {}
    });

    // 8. 發起支付（使用從 user_profiles 獲取的完整客戶資料）
    // ✅ 修復：為訂金支付添加 -DEPOSIT 後綴，避免與尾款支付的 Order_No 重複
    // GOMYPAY 要求每筆交易的 Order_No 必須唯一
    // 訂金: BK1763186275643-DEPOSIT
    // 尾款: BK1763186275643-BALANCE
    const paymentRequest = {
      orderId: `${booking.booking_number}-DEPOSIT`,  // ✅ 添加 -DEPOSIT 後綴
      amount: booking.deposit_amount,
      currency: 'TWD',
      description: `RelayGo 訂單訂金 - ${booking.booking_number}`,
      customerInfo: {
        id: user.id,
        name: customerName,      // ✅ 使用從 user_profiles 構建的姓名
        email: customerEmail,    // ✅ 使用從 users 獲取的信箱
        phone: customerPhone     // ✅ 使用從 users/user_profiles 獲取的電話
      },
      metadata: {
        bookingId: booking.id,
        paymentType: 'deposit'
      }
    };

    console.log('[API] 發起支付請求:', {
      provider: paymentProviderType,
      orderId: paymentRequest.orderId,
      amount: paymentRequest.amount,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone
    });

    const paymentResponse = await provider.initiatePayment(paymentRequest);

    if (!paymentResponse.success) {
      res.status(400).json({
        success: false,
        error: '支付發起失敗'
      });
      return;
    }

    console.log('[API] ✅ 支付發起成功:', {
      transactionId: paymentResponse.transactionId,
      hasPaymentUrl: !!paymentResponse.paymentUrl
    });

    // 9. 創建支付記錄（狀態為 pending，等待回調確認）
    const paymentData = {
      booking_id: bookingId,
      customer_id: booking.customer_id,
      transaction_id: paymentResponse.transactionId,
      type: 'deposit',
      amount: booking.deposit_amount,
      currency: 'TWD',
      status: 'pending', // 等待支付完成
      payment_provider: paymentProviderType,
      payment_method: paymentMethod || 'credit_card',
      is_test_mode: process.env.GOMYPAY_TEST_MODE === 'true',
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

    // 7. 返回支付 URL（如果有）或成功響應
    if (paymentResponse.paymentUrl) {
      // GoMyPay 或其他需要跳轉的支付方式
      res.json({
        success: true,
        data: {
          bookingId,
          paymentId: payment.id,
          transactionId: paymentResponse.transactionId,
          paymentUrl: paymentResponse.paymentUrl,
          instructions: paymentResponse.instructions,
          expiresAt: paymentResponse.expiresAt,
          requiresRedirect: true
        }
      });
    } else {
      // Mock 或其他自動完成的支付方式
      // 更新訂單狀態為已付訂金
      const { error: updateError } = await supabase
        .from('bookings')
        .update({
          status: 'paid_deposit',
          updated_at: new Date().toISOString()
        })
        .eq('id', bookingId);

      if (updateError) {
        console.error('[API] 更新訂單狀態失敗:', updateError);
      }

      res.json({
        success: true,
        data: {
          bookingId,
          paymentId: payment.id,
          transactionId: paymentResponse.transactionId,
          status: 'paid_deposit',
          depositAmount: booking.deposit_amount,
          requiresRedirect: false
        }
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
 * @route GET /api/bookings/:bookingId
 * @desc 獲取訂單詳情（用於訂單完成頁面）
 * @access Public
 */
router.get('/:bookingId', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;

    console.log('[API] 查詢訂單詳情:', bookingId);

    // 查詢訂單資料
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

    console.log('[API] ✅ 訂單查詢成功:', {
      booking_number: booking.booking_number,
      status: booking.status
    });

    // 返回訂單資料
    res.json({
      success: true,
      data: {
        id: booking.id,
        booking_number: booking.booking_number,
        status: booking.status,
        customer_id: booking.customer_id,
        driver_id: booking.driver_id,
        total_amount: booking.total_amount,
        deposit_amount: booking.deposit_amount,
        tip_amount: booking.tip_amount,
        created_at: booking.created_at,
        updated_at: booking.updated_at,
        completed_at: booking.completed_at
      }
    });

  } catch (error: any) {
    console.error('[API] 查詢訂單詳情失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '查詢訂單詳情失敗'
    });
  }
});

/**
 * @deprecated 使用 GET /api/reviews/check/:bookingId 替代
 * @route GET /api/bookings/:bookingId/rating
 * @desc 檢查訂單是否已評價（已棄用，使用舊的 ratings 表）
 * @access Public
 *
 * 修改歷史：
 * - 2025-11-23: 標記為 deprecated，統一使用 reviews 表
 */
router.get('/:bookingId/rating', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;

    console.log('[API] ⚠️  查詢訂單評價（使用已棄用的 ratings 表）:', bookingId);

    // 查詢評價資料（使用舊的 ratings 表）
    const { data: rating, error: ratingError } = await supabase
      .from('ratings')
      .select('*')
      .eq('booking_id', bookingId)
      .single();

    if (ratingError && ratingError.code !== 'PGRST116') {
      // PGRST116 = 沒有找到資料（正常情況）
      console.error('[API] 查詢評價失敗:', ratingError);
      res.status(500).json({
        success: false,
        error: '查詢評價失敗'
      });
      return;
    }

    if (rating) {
      console.log('[API] ✅ 訂單已評價');
      res.json({
        success: true,
        data: {
          hasRating: true,
          rating: rating
        }
      });
    } else {
      console.log('[API] ⚠️  訂單尚未評價');
      res.json({
        success: true,
        data: {
          hasRating: false
        }
      });
    }

  } catch (error: any) {
    console.error('[API] 查詢訂單評價失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '查詢訂單評價失敗'
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

