import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

const router = Router();

// Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

/**
 * @route POST /api/affiliates/apply
 * @desc 客戶申請成為推廣人
 * @access Customer (需要認證)
 */
router.post('/apply', async (req: Request, res: Response) => {
  try {
    const { user_id, promo_code } = req.body;

    console.log(`[Affiliates API] 客戶申請推廣人: user_id=${user_id}, promo_code=${promo_code}`);

    // 驗證必填欄位
    if (!user_id || !promo_code) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: '用戶 ID 和推薦碼為必填'
      });
    }

    // 驗證推薦碼格式：6-20 個英數字混合（至少包含一個字母和一個數字）
    const promoCodeRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,20}$/;
    if (!promoCodeRegex.test(promo_code)) {
      return res.status(400).json({
        success: false,
        error: '推薦碼格式錯誤',
        details: '推薦碼必須為 6-20 個英數字混合（至少包含一個字母和一個數字）'
      });
    }

    // 檢查用戶是否存在
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, email')
      .eq('id', user_id)
      .single();

    if (userError || !user) {
      return res.status(404).json({
        success: false,
        error: '用戶不存在'
      });
    }

    // 檢查用戶是否已經是推廣人
    const { data: existingAffiliate } = await supabase
      .from('influencers')
      .select('id, affiliate_status')
      .eq('user_id', user_id)
      .single();

    if (existingAffiliate) {
      const statusText = {
        pending: '待審核',
        active: '已啟用',
        suspended: '已暫停',
        rejected: '已拒絕'
      }[existingAffiliate.affiliate_status] || '未知';

      return res.status(409).json({
        success: false,
        error: '您已經申請過推廣人',
        details: `當前狀態：${statusText}`
      });
    }

    // 檢查推薦碼是否已被使用（不分大小寫）
    const { data: existingPromoCode } = await supabase
      .from('influencers')
      .select('id')
      .ilike('promo_code', promo_code)
      .single();

    if (existingPromoCode) {
      return res.status(409).json({
        success: false,
        error: '推薦碼已被使用',
        details: '請選擇其他推薦碼'
      });
    }

    // 創建推廣人申請記錄
    const { data: newAffiliate, error: createError } = await supabase
      .from('influencers')
      .insert({
        user_id: user_id,
        name: user.email, // 暫時使用 email 作為名稱，後續可從 user_profiles 獲取
        promo_code: promo_code.toUpperCase(), // 統一轉為大寫
        affiliate_type: 'customer_affiliate',
        affiliate_status: 'pending',
        discount_amount_enabled: false,
        discount_amount: 0,
        discount_percentage_enabled: false,
        discount_percentage: 0,
        commission_fixed: 0,
        commission_percent: 5.0, // 預設 5% 分潤
        is_commission_fixed_active: false,
        is_commission_percent_active: true,
        is_active: false, // 待審核時設為 false
        applied_at: new Date().toISOString(),
        account_username: `affiliate_${user_id.substring(0, 8)}`, // 自動生成帳號
        account_password: 'temp_password' // 臨時密碼，客戶推廣人不需要登入
      })
      .select()
      .single();

    if (createError) {
      console.error('[Affiliates API] 創建申請失敗:', createError);
      return res.status(500).json({
        success: false,
        error: '創建申請失敗',
        details: createError.message
      });
    }

    console.log(`[Affiliates API] ✅ 成功創建推廣人申請: ${newAffiliate.id}`);

    // 移除敏感欄位
    const { account_password, ...affiliateWithoutPassword } = newAffiliate;

    return res.status(201).json({
      success: true,
      data: affiliateWithoutPassword,
      message: '推廣人申請已提交，請等待管理員審核'
    });

  } catch (error) {
    console.error('[Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route POST /api/affiliates/:id/review
 * @desc 管理員審核推廣人申請
 * @access Admin
 */
router.post('/:id/review', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status, review_notes, reviewed_by } = req.body;

    console.log(`[Affiliates API] 審核推廣人: ${id}, 狀態: ${status}`);

    // 驗證必填欄位
    if (!status || !reviewed_by) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: '審核狀態和審核人為必填'
      });
    }

    // 驗證狀態值
    if (!['active', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: '無效的審核狀態',
        details: '狀態必須為 active 或 rejected'
      });
    }

    // 檢查推廣人是否存在
    const { data: affiliate, error: fetchError } = await supabase
      .from('influencers')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !affiliate) {
      return res.status(404).json({
        success: false,
        error: '推廣人不存在'
      });
    }

    // 檢查是否為客戶推廣人
    if (affiliate.affiliate_type !== 'customer_affiliate') {
      return res.status(400).json({
        success: false,
        error: '只能審核客戶推廣人申請'
      });
    }

    // 檢查當前狀態
    if (affiliate.affiliate_status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: '該申請已被審核',
        details: `當前狀態：${affiliate.affiliate_status}`
      });
    }

    // 更新審核狀態
    const { data: updatedAffiliate, error: updateError } = await supabase
      .from('influencers')
      .update({
        affiliate_status: status,
        is_active: status === 'active', // 通過審核則啟用
        reviewed_at: new Date().toISOString(),
        reviewed_by: reviewed_by,
        review_notes: review_notes || null
      })
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      console.error('[Affiliates API] 審核失敗:', updateError);
      return res.status(500).json({
        success: false,
        error: '審核失敗',
        details: updateError.message
      });
    }

    console.log(`[Affiliates API] ✅ 成功審核推廣人: ${id}, 狀態: ${status}`);

    // 移除敏感欄位
    const { account_password, ...affiliateWithoutPassword } = updatedAffiliate;

    return res.json({
      success: true,
      data: affiliateWithoutPassword,
      message: status === 'active' ? '推廣人申請已通過' : '推廣人申請已拒絕'
    });

  } catch (error) {
    console.error('[Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/affiliates/check-promo-code/:code
 * @desc 檢查推薦碼是否可用
 * @access Public
 */
router.get('/check-promo-code/:code', async (req: Request, res: Response) => {
  try {
    const { code } = req.params;

    console.log(`[Affiliates API] 檢查推薦碼: ${code}`);

    // 驗證推薦碼格式：6-20 個英數字混合（至少包含一個字母和一個數字）
    const promoCodeRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,20}$/;
    if (!promoCodeRegex.test(code)) {
      console.log(`[Affiliates API] 推薦碼格式錯誤: ${code}`);
      return res.json({
        success: true,
        available: false,
        message: '推薦碼格式錯誤（必須為 6-20 個英數字混合）'
      });
    }

    // 檢查推薦碼是否已存在（不分大小寫）
    const { data: existingPromoCode, error } = await supabase
      .from('influencers')
      .select('id')
      .ilike('promo_code', code)
      .single();

    if (error && error.code !== 'PGRST116') {
      // PGRST116 是 "not found" 錯誤，這是正常的（表示推薦碼可用）
      console.error(`[Affiliates API] 資料庫查詢錯誤:`, error);
      throw error;
    }

    if (existingPromoCode) {
      console.log(`[Affiliates API] 推薦碼已被使用: ${code}`);
      return res.json({
        success: true,
        available: false,
        message: '推薦碼已被使用'
      });
    }

    console.log(`[Affiliates API] 推薦碼可用: ${code}`);
    return res.json({
      success: true,
      available: true,
      message: '推薦碼可用'
    });

  } catch (error) {
    console.error('[Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/affiliates/my-status
 * @desc 獲取當前用戶的推廣人狀態
 * @access Customer (需要認證)
 */
router.get('/my-status', async (req: Request, res: Response) => {
  try {
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({
        success: false,
        error: '缺少用戶 ID'
      });
    }

    console.log(`[Affiliates API] 獲取推廣人狀態: user_id=${user_id}`);

    // 查詢用戶的推廣人記錄
    const { data: affiliate, error } = await supabase
      .from('influencers')
      .select('id, promo_code, affiliate_status, total_referrals, total_earnings, applied_at, reviewed_at, review_notes')
      .eq('user_id', user_id)
      .eq('affiliate_type', 'customer_affiliate')
      .single();

    if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
      console.error('[Affiliates API] 查詢失敗:', error);
      return res.status(500).json({
        success: false,
        error: '查詢失敗',
        details: error.message
      });
    }

    if (!affiliate) {
      return res.json({
        success: true,
        data: {
          is_affiliate: false,
          status: null
        }
      });
    }

    return res.json({
      success: true,
      data: {
        is_affiliate: true,
        status: affiliate.affiliate_status,
        promo_code: affiliate.promo_code,
        total_referrals: affiliate.total_referrals || 0,
        total_earnings: affiliate.total_earnings || 0,
        applied_at: affiliate.applied_at,
        reviewed_at: affiliate.reviewed_at,
        review_notes: affiliate.review_notes
      }
    });

  } catch (error) {
    console.error('[Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

export default router;

