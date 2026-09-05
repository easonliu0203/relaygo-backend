import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import {
  PROMO_SELECT_FIELDS,
  PromoRecord,
  checkPromoConstraints,
  checkPerUserLimit,
  computeDiscount,
  resolveDriverPayout,
} from '../services/promo/promoRules';

const router = Router();

// Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

/**
 * @route POST /api/promo-codes/validate
 * @desc 驗證優惠碼並計算折扣
 * @access Public
 *
 * 支援兩種碼（皆存於 influencers 表，以 affiliate_type 區隔）：
 *   - 推廣人碼：有佣金，折扣套在總額
 *   - 活動碼(campaign)：無佣金，可限車型／服務類型／期間／每人次數，
 *                       折扣可只套在基本車資，司機可改為固定給付
 *
 * 有適用限制的碼需要呼叫端提供 service_type / vehicle_type，
 * 否則無法判斷是否適用，會直接回報無效而不是給出可能錯誤的金額。
 */
router.post('/validate', async (req: Request, res: Response) => {
  try {
    const {
      promo_code,
      original_price,
      user_id,
      service_type,
      vehicle_type,
      base_price,
    } = req.body;

    console.log(
      `[Promo Code API] 驗證優惠碼: ${promo_code}, 原價: ${original_price}, 基本車資: ${base_price ?? '未提供'}, ` +
      `用戶: ${user_id || '未提供'}, 服務類型: ${service_type || '未提供'}, 車型: ${vehicle_type || '未提供'}`
    );

    if (!promo_code || !original_price) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: '優惠代碼和原始價格為必填'
      });
    }

    const price = parseFloat(original_price);
    if (isNaN(price) || price <= 0) {
      return res.status(400).json({
        success: false,
        error: '價格格式錯誤',
        details: '原始價格必須為正數'
      });
    }

    // 查詢優惠碼（不分大小寫）
    const { data: influencer, error } = await supabase
      .from('influencers')
      .select(PROMO_SELECT_FIELDS)
      .ilike('promo_code', promo_code)
      .eq('is_active', true)
      .single<PromoRecord>();

    if (error || !influencer) {
      console.log(`[Promo Code API] ❌ 優惠碼無效: ${promo_code}`);
      return res.status(404).json({
        success: false,
        valid: false,
        error: '優惠碼無效',
        details: '找不到此優惠碼或優惠碼已停用'
      });
    }

    // ✅ 適用限制：期間、服務類型、車型
    const constraint = checkPromoConstraints(influencer, {
      serviceType: service_type,
      vehicleType: vehicle_type,
    });
    if (!constraint.valid) {
      console.log(`[Promo Code API] ❌ 不符使用條件 (${constraint.reason}): ${promo_code}`);
      return res.status(400).json({
        success: false,
        valid: false,
        error: constraint.error,
      });
    }

    // ✅ 每個帳號使用次數上限（user_id 可能是 firebase_uid，需轉成 users.id）
    let internalUserId: string | null = null;
    if (user_id) {
      const { data: userRow } = await supabase
        .from('users')
        .select('id')
        .or(`id.eq.${user_id},firebase_uid.eq.${user_id}`)
        .maybeSingle();
      internalUserId = userRow?.id || null;
    }

    const perUser = await checkPerUserLimit(supabase, influencer, internalUserId);
    if (!perUser.valid) {
      console.log(`[Promo Code API] ❌ 超過使用次數 (${perUser.reason}): ${promo_code}`);
      return res.status(400).json({
        success: false,
        valid: false,
        error: perUser.error,
      });
    }

    // ✅ 計算折扣（活動碼可設定只折基本車資，附加費照原價）
    const discount = computeDiscount(influencer, {
      originalTotal: price,
      basePrice: base_price != null ? parseFloat(base_price) : price,
      serviceType: service_type,
    });
    const payout = resolveDriverPayout(influencer);

    console.log(`[Promo Code API] ✅ 優惠碼有效: ${promo_code}`);
    console.log(`[Promo Code API] 原價: ${price}, 最終價格: ${discount.finalPrice}, 折扣基準: ${discount.discountBase}`);

    // 檢查推薦關係（如果提供了 user_id）
    let referral_info = null;
    if (internalUserId) {
      const { data: existingReferral } = await supabase
        .from('referrals')
        .select('id, referrer_id, created_at')
        .eq('referee_id', internalUserId)
        .maybeSingle();

      if (existingReferral) {
        referral_info = {
          has_referrer: true,
          is_first_use: false,
          message: '您已有推薦人，此次使用優惠碼僅享受折扣，不會建立新的推薦關係'
        };
      } else {
        referral_info = {
          has_referrer: false,
          is_first_use: true,
          message: '首次使用推薦碼，將建立推薦關係並享受折扣'
        };
      }
    }

    return res.json({
      success: true,
      valid: true,
      influencer_id: influencer.id,
      influencer_name: influencer.name,
      promo_code: influencer.promo_code,
      discount_amount_enabled: influencer.discount_amount_enabled || false,
      discount_amount: discount.fixedDiscountApplied,
      discount_percentage_enabled: influencer.discount_percentage_enabled || false,
      discount_percentage: discount.discountPercentage,
      commission_amount: influencer.commission_per_order || 0,
      original_price: price,
      final_price: discount.finalPrice,
      total_discount: discount.discountAmount,
      calculation_steps: discount.calculationSteps,
      referral_info,
      // ✅ 活動碼相關資訊（供前端顯示，實際金額仍以建單時後端驗算為準）
      is_campaign: influencer.affiliate_type === 'campaign',
      discount_base: discount.discountBase,
      limit_vehicle_types: influencer.limit_vehicle_types || null,
      limit_service_types: influencer.limit_service_types || null,
      driver_payout_mode: payout.driver_payout_mode,
      driver_fixed_amount: payout.driver_fixed_amount,
      valid_from: influencer.valid_from || null,
      valid_until: influencer.valid_until || null,
    });

  } catch (error) {
    console.error('[Promo Code API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route POST /api/promo-codes/record-usage
 * @desc 記錄優惠碼使用（在訂單建立時呼叫）
 * @access Private
 */
router.post('/record-usage', async (req: Request, res: Response) => {
  try {
    const {
      influencer_id,
      booking_id,
      promo_code,
      original_price,
      discount_amount_applied,
      discount_percentage_applied,
      final_price,
      commission_amount,
      service_type
    } = req.body;

    console.log(`[Promo Code API] 記錄優惠碼使用: ${promo_code} for booking ${booking_id}`);

    // 驗證必填欄位
    if (!influencer_id || !booking_id || !promo_code) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位'
      });
    }

    // 如果沒有提供 commission_amount，則從 influencers 表查詢當前的 commission_per_order
    let commissionToRecord = commission_amount;
    if (commissionToRecord === undefined || commissionToRecord === null) {
      const { data: influencer } = await supabase
        .from('influencers')
        .select('commission_per_order')
        .eq('id', influencer_id)
        .single();

      commissionToRecord = influencer?.commission_per_order || 0;
    }

    // 記錄優惠碼使用
    const { data, error } = await supabase
      .from('promo_code_usage')
      .insert({
        influencer_id,
        booking_id,
        promo_code,
        original_price: original_price || 0,
        discount_amount_applied: discount_amount_applied || 0,
        discount_percentage_applied: discount_percentage_applied || 0,
        final_price: final_price || 0,
        commission_amount: commissionToRecord,
        service_type: service_type || null,
      })
      .select()
      .single();

    if (error) {
      console.error('[Promo Code API] 記錄失敗:', error);
      return res.status(500).json({
        success: false,
        error: '記錄優惠碼使用失敗',
        details: error.message
      });
    }

    console.log(`[Promo Code API] ✅ 成功記錄優惠碼使用`);

    return res.status(201).json({
      success: true,
      data,
      message: '優惠碼使用記錄成功'
    });

  } catch (error) {
    console.error('[Promo Code API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

export default router;

