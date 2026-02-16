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
 * 獲取客戶端真實 IP 地址
 * 考慮代理伺服器情況（X-Forwarded-For, X-Real-IP 等）
 */
function getClientIp(req: Request): string {
  // 1. 檢查 X-Forwarded-For（最常見的代理 header）
  const forwardedFor = req.headers['x-forwarded-for'];
  if (forwardedFor) {
    // X-Forwarded-For 可能包含多個 IP，取第一個（客戶端真實 IP）
    const ips = (typeof forwardedFor === 'string' ? forwardedFor : forwardedFor[0]).split(',');
    return ips[0].trim();
  }

  // 2. 檢查 X-Real-IP（Nginx 常用）
  const realIp = req.headers['x-real-ip'];
  if (realIp) {
    return typeof realIp === 'string' ? realIp : realIp[0];
  }

  // 3. 檢查 CF-Connecting-IP（Cloudflare）
  const cfIp = req.headers['cf-connecting-ip'];
  if (cfIp) {
    return typeof cfIp === 'string' ? cfIp : cfIp[0];
  }

  // 4. 使用 req.ip 或 req.connection.remoteAddress
  return req.ip || req.socket.remoteAddress || 'unknown';
}

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
      dropoffLatitude,  // ✅ 啟用：下車地點緯度
      dropoffLongitude, // ✅ 啟用：下車地點經度
      bookingTime,
      passengerCount,
      luggageCount, // ✅ 修復：取消註解，從請求中獲取行李數量
      notes,
      // packageId,
      packageName,
      estimatedFare,
      tourPackageId,
      tourPackageName,
      // 優惠碼相關欄位（如果客戶使用優惠碼）
      promoCode, // 優惠碼
      influencerId, // 網紅 ID
      // influencerCommission 已移除，改為後端計算（訂單金額的 5%）
      originalPrice, // ✅ 新增：原始價格（未使用優惠碼前）
      discountAmount, // ✅ 新增：折扣金額
      finalPrice, // ✅ 新增：折扣後最終價格
      // 統一編號（選填）
      taxId, // 統一編號（8 位數字）
      // ✅ 新增：取消政策同意狀態
      policyAgreed, // 客戶是否已同意取消政策
      // ✅ 新增：多維度分潤配置欄位
      serviceType = 'charter', // 服務類型: 'charter' (包車旅遊) | 'instant_ride' (即時派車)
      country = 'TW', // 國家代碼 (ISO 3166-1 alpha-2)
      // ✅ 新增：機場接送欄位
      addAirportPickup = false,
      pickupFlightNumber,
      pickupAirportCode,
      pickupScheduledTime,
      pickupTerminal,
      addAirportDropoff = false,
      dropoffFlightNumber,
      dropoffAirportCode,
      dropoffScheduledTime,
      dropoffTerminal,
    } = req.body;

    console.log('[API] 創建訂單:', {
      customerUid,
      pickupAddress,
      bookingTime,
      passengerCount,
      tourPackageId,
      tourPackageName,
      serviceType,
      country,
    });

    // 1. 驗證必填欄位
    if (!customerUid) {
      res.status(400).json({
        success: false,
        error: '缺少客戶 UID'
      });
      return;
    }

    // ✅ 修正：機場模式需要航班資訊，地址模式需要地址+座標
    // 注意：原 `!pickupLatitude` 在 lat=0 時為 true（JS falsy），改用 == null 檢查
    if (addAirportPickup) {
      if (!pickupFlightNumber) {
        res.status(400).json({
          success: false,
          error: '缺少接機航班資訊'
        });
        return;
      }
    } else {
      if (!pickupAddress || pickupLatitude == null || pickupLongitude == null) {
        res.status(400).json({
          success: false,
          error: '缺少上車地點資訊'
        });
        return;
      }
    }

    if (!bookingTime) {
      res.status(400).json({
        success: false,
        error: '缺少預約時間'
      });
      return;
    }

    // ✅ 新增：驗證取消政策同意狀態
    if (policyAgreed !== true) {
      console.error('[API] 客戶未同意取消政策');
      res.status(400).json({
        success: false,
        error: '必須同意取消政策才能繼續支付'
      });
      return;
    }

    // 2. 驗證客戶是否存在
    const { data: customer, error: customerError } = await supabase
      .from('users')
      .select('id, email, role, roles')
      .eq('firebase_uid', customerUid)
      .contains('roles', ['customer']) // ✅ 修復：檢查 roles 陣列是否包含 'customer'，支援多角色用戶
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

    // ✅ 修正：如果有使用優惠碼，使用折扣後的價格
    let totalAmount = basePrice + foreignLanguageSurcharge + overtimeFee + tipAmount;
    let actualOriginalPrice = totalAmount; // 原始價格（未折扣前）
    let actualDiscountAmount = 0; // 折扣金額
    let actualFinalPrice = totalAmount; // 折扣後最終價格

    if (finalPrice && finalPrice > 0) {
      // 客戶使用了優惠碼
      actualOriginalPrice = originalPrice || totalAmount;
      actualFinalPrice = finalPrice;
      // ✅ 自動計算折扣金額（支援固定金額和百分比折扣）
      actualDiscountAmount = actualOriginalPrice - actualFinalPrice;
      totalAmount = finalPrice; // ✅ 使用折扣後的價格作為訂單總金額
      console.log('[API] ✅ 使用優惠碼折扣後價格:', {
        originalPrice: actualOriginalPrice,
        discountAmount: actualDiscountAmount,
        finalPrice: actualFinalPrice,
        discountPercentage: ((actualDiscountAmount / actualOriginalPrice) * 100).toFixed(2) + '%'
      });
    }

    const depositAmount = Math.round(totalAmount * depositRate);

    // ✅ 計算訂單促成費（支援固定金額、百分比、或兩者同時啟用）
    // 情境 1：無優惠碼/無推薦關係 → 促成費 = 0
    // 情境 2：僅固定金額 → 促成費 = commission_fixed
    // 情境 3：僅百分比 → 促成費 = actualFinalPrice × commission_percent / 100
    // 情境 4：兩者同時啟用 → 促成費 = commission_fixed + (actualFinalPrice × commission_percent / 100)
    let calculatedInfluencerCommission = 0;
    let commissionType: string | null = null;
    let commissionRate = 0;
    let commissionFixed = 0;
    let fixedAmount = 0;
    let percentAmount = 0;

    if (promoCode && influencerId) {
      // 查詢推廣者的佣金設定
      const { data: influencerData } = await supabase
        .from('influencers')
        .select('commission_fixed, commission_percent, is_commission_fixed_active, is_commission_percent_active')
        .eq('id', influencerId)
        .single();

      if (influencerData) {
        const isFixedActive = influencerData.is_commission_fixed_active === true;
        const isPercentActive = influencerData.is_commission_percent_active === true;

        // 計算固定金額佣金（如果啟用）
        if (isFixedActive) {
          commissionFixed = influencerData.commission_fixed || 0;
          fixedAmount = commissionFixed;
          calculatedInfluencerCommission += fixedAmount;
        }

        // 計算百分比佣金（如果啟用）
        if (isPercentActive) {
          commissionRate = influencerData.commission_percent || 0;
          percentAmount = Math.round(actualFinalPrice * commissionRate / 100);
          calculatedInfluencerCommission += percentAmount;
        }

        // 判斷佣金類型
        if (isFixedActive && isPercentActive) {
          commissionType = 'both';
          console.log('[API] ✅ 使用固定金額 + 百分比佣金:', {
            finalPrice: actualFinalPrice,
            commissionFixed,
            fixedAmount,
            commissionRate,
            percentAmount,
            totalCommission: calculatedInfluencerCommission
          });
        } else if (isFixedActive) {
          commissionType = 'fixed';
          console.log('[API] ✅ 使用固定金額佣金:', {
            commissionFixed,
            commission: calculatedInfluencerCommission
          });
        } else if (isPercentActive) {
          commissionType = 'percent';
          console.log('[API] ✅ 使用百分比佣金:', {
            finalPrice: actualFinalPrice,
            commissionRate,
            commission: calculatedInfluencerCommission
          });
        } else {
          console.log('[API] ⚠️ 推廣者未啟用任何佣金類型');
        }
      }
    }

    console.log('[API] 計算費用:', {
      basePrice,
      depositRate,
      totalAmount,
      depositAmount,
      hasPromoCode: !!promoCode,
      influencerCommission: calculatedInfluencerCommission
    });

    // 6. 獲取客戶端 IP 地址（用於防範 Chargeback 爭議）
    const clientIp = getClientIp(req);
    console.log('[API] 客戶端 IP:', clientIp);

    // 7. 解析預約時間
    const bookingDateTime = new Date(bookingTime);
    const startDate = bookingDateTime.toISOString().split('T')[0]; // YYYY-MM-DD
    const startTime = bookingDateTime.toTimeString().split(' ')[0]; // HH:MM:SS

    // 8. 創建訂單
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
        // ✅ 修正：機場模式下使用航班資訊作為地點描述
        pickup_location: addAirportPickup
          ? `機場接機 ${pickupAirportCode || ''}${pickupTerminal ? ' ' + pickupTerminal : ''} ${pickupFlightNumber || ''}`
          : pickupAddress,
        pickup_latitude: addAirportPickup ? null : pickupLatitude,
        pickup_longitude: addAirportPickup ? null : pickupLongitude,
        destination: addAirportDropoff
          ? `機場送機 ${dropoffAirportCode || ''}${dropoffTerminal ? ' ' + dropoffTerminal : ''} ${dropoffFlightNumber || ''}`
          : (dropoffAddress || ''),
        dropoff_latitude: addAirportDropoff ? null : (dropoffLatitude || null),
        dropoff_longitude: addAirportDropoff ? null : (dropoffLongitude || null),
        passenger_count: passengerCount || 1, // ✅ 新增：乘客數量（預設為 1）
        luggage_count: luggageCount || 0, // ✅ 新增：行李數量（預設為 0）
        special_requirements: notes || '',
        requires_foreign_language: false, // 可以從請求中獲取
        base_price: basePrice,
        foreign_language_surcharge: foreignLanguageSurcharge,
        overtime_fee: overtimeFee,
        tip_amount: tipAmount,
        total_amount: totalAmount,
        deposit_amount: depositAmount,
        // ✅ 新增：優惠碼相關欄位
        promo_code: promoCode || null, // 優惠碼
        influencer_id: influencerId || null, // 網紅 ID
        influencer_commission: calculatedInfluencerCommission, // ✅ 訂單促成費（後端計算：折後最終金額 × 5%）
        original_price: actualOriginalPrice, // 原始價格（未使用優惠碼前）
        discount_amount: actualDiscountAmount, // 折扣金額
        final_price: actualFinalPrice, // 折扣後最終價格
        tax_id: taxId || null, // ✅ 新增：統一編號（選填）
        tour_package_id: tourPackageId || null, // ✅ 新增：旅遊方案 ID
        tour_package_name: tourPackageName || null, // ✅ 新增：旅遊方案名稱
        policy_agreed: policyAgreed === true, // ✅ 新增：取消政策同意狀態
        policy_agreed_at: policyAgreed === true ? new Date().toISOString() : null, // ✅ 新增：同意時間戳記
        client_ip: clientIp, // ✅ 新增：客戶端 IP 地址（用於防範 Chargeback 爭議）
        // ✅ 新增：多維度分潤配置欄位
        service_type: serviceType, // 服務類型: 'charter' | 'instant_ride'
        country: country, // 國家代碼: 'TW', 'JP', 'KR', etc.
        // ✅ 新增：機場接送欄位
        add_airport_pickup: addAirportPickup || false,
        pickup_flight_number: pickupFlightNumber || null,
        pickup_airport_code: pickupAirportCode || null,
        pickup_scheduled_time: pickupScheduledTime || null,
        pickup_terminal: pickupTerminal || null,
        add_airport_dropoff: addAirportDropoff || false,
        dropoff_flight_number: dropoffFlightNumber || null,
        dropoff_airport_code: dropoffAirportCode || null,
        dropoff_scheduled_time: dropoffScheduledTime || null,
        dropoff_terminal: dropoffTerminal || null,
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

    // 7. 如果有使用優惠碼，記錄優惠碼使用
    if (promoCode && influencerId) {
      console.log('[API] 記錄優惠碼使用:', promoCode);

      // ✅ 修復：查找推薦關係，確定實際分潤對象
      // 場景 1 & 2: 客戶首次或繼續使用推廣人 A 的優惠碼 → 分潤給 A
      // 場景 3: 客戶使用推廣人 C 的優惠碼，但已有 A→B 推薦關係 → 分潤給 A（而非 C）
      console.log('[API] 檢查推薦關係:', { customerId: customer.id, influencerId, promoCode });

      const { data: existingReferral } = await supabase
        .from('referrals')
        .select('influencer_id')
        .eq('referee_id', customer.id)
        .single();

      // 使用推薦關係中的 influencer_id，如果沒有推薦關係則使用訂單的 influencer_id
      const actualCommissionInfluencerId = existingReferral?.influencer_id || influencerId;

      if (existingReferral) {
        console.log('[API] 找到現有推薦關係，分潤對象:', actualCommissionInfluencerId);
      } else {
        console.log('[API] 無現有推薦關係，分潤對象為優惠碼提供者:', actualCommissionInfluencerId);
      }

      const { error: usageError } = await supabase
        .from('promo_code_usage')
        .insert({
          influencer_id: actualCommissionInfluencerId, // ✅ 修復：使用實際分潤對象
          booking_id: booking.id,
          promo_code: promoCode,
          original_price: actualOriginalPrice, // ✅ 修正：使用實際的原始價格
          discount_amount_applied: actualDiscountAmount, // ✅ 修正：使用實際的折扣金額
          discount_percentage_applied: 0, // 百分比折扣（可以從前端傳遞）
          final_price: actualFinalPrice, // ✅ 修正：使用實際的折扣後價格
          commission_amount: calculatedInfluencerCommission, // ✅ 訂單促成費（支援固定金額和百分比）
          commission_type: commissionType, // ✅ 新增：佣金類型（fixed 或 percent）
          commission_rate: commissionRate, // ✅ 新增：百分比佣金率
          commission_fixed_amount: commissionFixed, // ✅ 新增：固定金額佣金
          order_amount: actualFinalPrice, // ✅ 訂單金額
        });

      if (usageError) {
        console.error('[API] 記錄優惠碼使用失敗:', usageError);
        // 不中斷訂單建立流程，只記錄錯誤
      } else {
        console.log('[API] ✅ 優惠碼使用記錄成功');
      }

      // ✅ 建立推薦關係（如果是首次使用推薦碼）
      // 檢查用戶是否已有推薦人（使用 users.id，不是 firebase_uid）
      // 注意：這裡重新查詢是為了獲取完整的推薦關係資訊（包括 id）
      const { data: existingReferralFull } = await supabase
        .from('referrals')
        .select('id')
        .eq('referee_id', customer.id)
        .single();

      if (!existingReferralFull) {
        // 首次使用推薦碼，建立推薦關係
        console.log('[API] 首次使用推薦碼，建立推薦關係');

        // 獲取推廣人的 user_id 和佣金設定（如果是客戶推廣人）
        const { data: influencerData } = await supabase
          .from('influencers')
          .select('user_id, affiliate_type, commission_fixed, commission_percent, is_commission_fixed_active, is_commission_percent_active')
          .eq('id', influencerId)
          .single();

        if (influencerData && influencerData.user_id && influencerData.affiliate_type === 'customer_affiliate') {
          // 客戶推廣人，建立推薦關係
          const { error: referralError } = await supabase
            .from('referrals')
            .insert({
              referrer_id: influencerData.user_id,
              referee_id: customer.id, // ✅ 修復：使用 users.id，不是 firebase_uid
              influencer_id: influencerId,
              promo_code: promoCode,
              first_booking_id: booking.id
            });

          if (referralError) {
            console.error('[API] 建立推薦關係失敗:', referralError);
          } else {
            console.log('[API] ✅ 推薦關係建立成功');

            // ✅ 新增：立即更新 promo_code_usage 記錄，填寫佣金相關欄位
            const updateCommissionType = influencerData.is_commission_fixed_active ? 'fixed' :
                                  influencerData.is_commission_percent_active ? 'percent' : null;
            const updateCommissionRate = influencerData.is_commission_percent_active ? influencerData.commission_percent : 0;
            const updateCommissionFixed = influencerData.is_commission_fixed_active ? influencerData.commission_fixed : 0;

            const { error: updateError } = await supabase
              .from('promo_code_usage')
              .update({
                referee_id: customer.id,
                commission_type: updateCommissionType,
                commission_rate: updateCommissionRate,
                commission_fixed_amount: updateCommissionFixed,
                order_amount: actualFinalPrice
              })
              .eq('booking_id', booking.id);

            if (updateError) {
              console.error('[API] 更新優惠碼使用記錄失敗:', updateError);
            } else {
              console.log('[API] ✅ 優惠碼使用記錄已更新佣金資訊');
            }
          }
        } else {
          console.log('[API] 網紅推廣碼或非客戶推廣人，不建立推薦關係');
        }
      } else {
        console.log('[API] 用戶已有推薦人，不建立新的推薦關係');
      }
    }

    // 8. 返回訂單資訊
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
    // ✅ 2026-02-04: 修復重複 Order_No 導致 GOMYPAY 卡住的問題
    // GOMYPAY 要求每筆交易的 Order_No 必須唯一，即使是同一訂單的重試支付
    // ⚠️ GOMYPAY 限制 Order_No 最大長度為 25 字符
    // 新格式: BK{timestamp}D{4位隨機} (D=Deposit, 總長度 20 字符)
    // 例如: BK1770199618207D7L7Y
    const uniqueSuffix = Math.random().toString(36).substring(2, 6).toUpperCase();
    const orderId = `${booking.booking_number}D${uniqueSuffix}`;
    console.log('[API] 生成唯一 Order_No:', orderId, '長度:', orderId.length);

    const paymentRequest = {
      orderId,  // ✅ 每次支付嘗試都使用唯一的 Order_No
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

    // 9. 檢查是否已存在 pending 狀態的支付記錄
    const { data: existingPayments } = await supabase
      .from('payments')
      .select('id, status, transaction_id')
      .eq('booking_id', bookingId)
      .eq('type', 'deposit')
      .in('status', ['pending', 'processing']);

    // 如果存在舊的 pending/processing 支付記錄，將其標記為 cancelled
    if (existingPayments && existingPayments.length > 0) {
      console.log('[API] 發現舊的支付記錄，將其標記為 cancelled:', existingPayments.map(p => p.id));

      const oldPaymentIds = existingPayments.map(p => p.id);
      await supabase
        .from('payments')
        .update({
          status: 'cancelled',
          updated_at: new Date().toISOString()
        })
        .in('id', oldPaymentIds);
    }

    // 10. 創建新的支付記錄（狀態為 pending，等待回調確認）
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

    // 11. 返回支付 URL
    // ⚠️ 所有支付都必須通過 GoMyPay，不再支援自動完成的模擬支付
    if (!paymentResponse.paymentUrl) {
      console.error('[API] 支付提供者未返回支付 URL');
      res.status(500).json({
        success: false,
        error: '支付發起失敗：未獲取到支付 URL'
      });
      return;
    }

    // 返回 GoMyPay 支付 URL
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

