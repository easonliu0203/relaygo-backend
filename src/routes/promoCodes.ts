import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

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
 */
router.post('/validate', async (req: Request, res: Response) => {
  try {
    const { promo_code, original_price } = req.body;

    console.log(`[Promo Code API] 驗證優惠碼: ${promo_code}, 原價: ${original_price}`);

    // 驗證必填欄位
    if (!promo_code || !original_price) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: '優惠代碼和原始價格為必填'
      });
    }

    // 驗證價格格式
    const price = parseFloat(original_price);
    if (isNaN(price) || price <= 0) {
      return res.status(400).json({
        success: false,
        error: '價格格式錯誤',
        details: '原始價格必須為正數'
      });
    }

    // 查詢優惠碼
    const { data: influencer, error } = await supabase
      .from('influencers')
      .select('*')
      .eq('promo_code', promo_code)
      .eq('is_active', true)
      .single();

    if (error || !influencer) {
      console.log(`[Promo Code API] ❌ 優惠碼無效: ${promo_code}`);
      return res.status(404).json({
        success: false,
        valid: false,
        error: '優惠碼無效',
        details: '找不到此優惠碼或優惠碼已停用'
      });
    }

    // 計算折扣
    let currentPrice = price;
    const calculationSteps: string[] = [];
    let discountAmountApplied = 0;
    let discountPercentageApplied = 0;

    calculationSteps.push(`原價：NT$ ${price.toLocaleString()}`);

    // 1. 先扣除固定金額折扣
    if (influencer.discount_amount_enabled && influencer.discount_amount > 0) {
      discountAmountApplied = influencer.discount_amount;
      currentPrice -= discountAmountApplied;
      calculationSteps.push(
        `固定折扣：-NT$ ${discountAmountApplied.toLocaleString()} = NT$ ${currentPrice.toLocaleString()}`
      );
    }

    // 2. 再計算百分比折扣
    if (influencer.discount_percentage_enabled && influencer.discount_percentage > 0) {
      discountPercentageApplied = influencer.discount_percentage;
      const discountMultiplier = 1 - (discountPercentageApplied / 100);
      currentPrice = currentPrice * discountMultiplier;
      calculationSteps.push(
        `百分比折扣：${(100 - discountPercentageApplied).toFixed(0)} 折 = NT$ ${Math.round(currentPrice).toLocaleString()}`
      );
    }

    // 四捨五入到整數
    const finalPrice = Math.round(currentPrice);

    console.log(`[Promo Code API] ✅ 優惠碼有效: ${promo_code}`);
    console.log(`[Promo Code API] 原價: ${price}, 最終價格: ${finalPrice}`);

    return res.json({
      success: true,
      valid: true,
      influencer_id: influencer.id,
      influencer_name: influencer.name,
      promo_code: influencer.promo_code,
      discount_amount_enabled: influencer.discount_amount_enabled || false, // ✅ 新增：是否啟用現金折扣
      discount_amount: discountAmountApplied,
      discount_percentage_enabled: influencer.discount_percentage_enabled || false, // ✅ 新增：是否啟用百分比折扣
      discount_percentage: discountPercentageApplied,
      commission_amount: influencer.commission_per_order || 0,
      original_price: price,
      final_price: finalPrice,
      total_discount: price - finalPrice,
      calculation_steps: calculationSteps
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
      commission_amount
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
        commission_amount: commissionToRecord
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

