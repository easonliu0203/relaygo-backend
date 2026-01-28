import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

const router = Router();

// Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

/**
 * @route POST /api/driver-affiliates/apply
 * @desc 司機申請成為推廣人
 * @access Driver (需要認證)
 */
router.post('/apply', async (req: Request, res: Response) => {
  try {
    const { user_id, promo_code } = req.body;

    console.log(`[Driver Affiliates API] 司機申請推廣人: user_id=${user_id}, promo_code=${promo_code}`);

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

    // 檢查用戶是否存在（使用 firebase_uid 查詢）
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, email, firebase_uid')
      .eq('firebase_uid', user_id)
      .single();

    if (userError || !user) {
      console.error('[Driver Affiliates API] 用戶查詢失敗:', userError);
      return res.status(404).json({
        success: false,
        error: '用戶不存在',
        details: userError?.message
      });
    }

    console.log(`[Driver Affiliates API] 找到用戶: id=${user.id}, firebase_uid=${user.firebase_uid}`);
    const userUuid = user.id;

    // 檢查用戶是否已經是司機推廣人
    const { data: existingAffiliate } = await supabase
      .from('driver_affiliates')
      .select('id, affiliate_status')
      .eq('driver_id', userUuid)
      .single();

    if (existingAffiliate) {
      const statusMap: Record<string, string> = {
        pending: '待審核',
        active: '已啟用',
        suspended: '已暫停',
        rejected: '已拒絕'
      };
      const statusText = statusMap[existingAffiliate.affiliate_status as string] || '未知';

      return res.status(409).json({
        success: false,
        error: '您已經申請過司機推廣人',
        details: `當前狀態：${statusText}`
      });
    }

    // 檢查推薦碼是否已被使用（不分大小寫）- 檢查 driver_affiliates 和 influencers 兩個表
    const { data: existingPromoCodeDriver } = await supabase
      .from('driver_affiliates')
      .select('id')
      .ilike('promo_code', promo_code)
      .single();

    if (existingPromoCodeDriver) {
      return res.status(409).json({
        success: false,
        error: '推薦碼已被使用',
        details: '請選擇其他推薦碼'
      });
    }

    const { data: existingPromoCodeInfluencer } = await supabase
      .from('influencers')
      .select('id')
      .ilike('promo_code', promo_code)
      .single();

    if (existingPromoCodeInfluencer) {
      return res.status(409).json({
        success: false,
        error: '推薦碼已被使用',
        details: '請選擇其他推薦碼'
      });
    }

    // 創建司機推廣人申請記錄
    const { data: newAffiliate, error: createError } = await supabase
      .from('driver_affiliates')
      .insert({
        driver_id: userUuid,
        promo_code: promo_code.toUpperCase(),
        affiliate_status: 'pending',
        commission_fixed_enabled: false,
        commission_fixed: 0,
        commission_percent_enabled: true,
        commission_percent: 1.0, // 預設 1% 分潤（從公司抽成中扣除）
        is_active: false
      })
      .select()
      .single();

    if (createError) {
      console.error('[Driver Affiliates API] 創建申請失敗:', createError);
      return res.status(500).json({
        success: false,
        error: '創建申請失敗',
        details: createError.message
      });
    }

    console.log(`[Driver Affiliates API] ✅ 成功創建司機推廣人申請: ${newAffiliate.id}`);

    return res.status(201).json({
      success: true,
      data: newAffiliate,
      message: '司機推廣人申請已提交，請等待管理員審核'
    });



/**
 * @route GET /api/driver-affiliates/check-promo-code/:code
 * @desc 檢查推薦碼是否有效（用於司機輸入推薦碼時驗證）
 * @access Public
 */
router.get('/check-promo-code/:code', async (req: Request, res: Response) => {
  try {
    const { code } = req.params;

    console.log(`[Driver Affiliates API] 檢查推薦碼: ${code}`);

    // 驗證推薦碼格式
    const promoCodeRegex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,20}$/;
    if (!promoCodeRegex.test(code)) {
      return res.json({
        success: true,
        valid: false,
        message: '推薦碼格式錯誤（必須為 6-20 個英數字混合）'
      });
    }

    // 檢查推薦碼是否存在且有效
    const { data: affiliate, error } = await supabase
      .from('driver_affiliates')
      .select('id, driver_id, promo_code, affiliate_status, is_active')
      .ilike('promo_code', code)
      .single();

    if (error && error.code !== 'PGRST116') {
      throw error;
    }

    if (!affiliate) {
      return res.json({
        success: true,
        valid: false,
        message: '推薦碼不存在'
      });
    }

    if (affiliate.affiliate_status !== 'active' || !affiliate.is_active) {
      return res.json({
        success: true,
        valid: false,
        message: '推薦碼已失效'
      });
    }

    // 獲取推薦人名稱
    const { data: referrer } = await supabase
      .from('users')
      .select('id, display_name, email')
      .eq('id', affiliate.driver_id)
      .single();

    return res.json({
      success: true,
      valid: true,
      message: '推薦碼有效',
      referrer: {
        id: affiliate.driver_id,
        name: referrer?.display_name || referrer?.email || '司機推廣人'
      }
    });

  } catch (error) {
    console.error('[Driver Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/driver-affiliates/my-status
 * @desc 獲取當前司機的推廣人狀態
 * @access Driver (需要認證)
 */
router.get('/my-status', async (req: Request, res: Response) => {
  try {
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({
        success: false,
        error: '缺少 user_id 參數'
      });
    }

    // 查詢用戶的 PostgreSQL UUID
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', user_id)
      .single();

    if (userError || !user) {
      return res.status(404).json({
        success: false,
        error: '用戶不存在'
      });
    }

    // 查詢司機推廣人狀態
    const { data: affiliate, error: affiliateError } = await supabase
      .from('driver_affiliates')
      .select('*')
      .eq('driver_id', user.id)
      .single();

    if (affiliateError && affiliateError.code !== 'PGRST116') {
      throw affiliateError;
    }

    if (!affiliate) {
      return res.json({
        success: true,
        data: null,
        message: '尚未申請成為司機推廣人'
      });
    }

    // 獲取推薦的司機列表
    const { data: referrals, error: referralsError } = await supabase
      .from('driver_referrals')
      .select(`
        id,
        referee_driver_id,
        promo_code,
        created_at
      `)
      .eq('referrer_driver_id', user.id);

    return res.json({
      success: true,
      data: {
        ...affiliate,
        referrals: referrals || [],
        referrals_count: referrals?.length || 0
      }
    });

  } catch (error) {
    console.error('[Driver Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route POST /api/driver-affiliates/save-referral-code
 * @desc 司機保存推薦碼（建立推薦關係，終身綁定）
 * @access Driver (需要認證)
 */
router.post('/save-referral-code', async (req: Request, res: Response) => {
  try {
    const { user_id, promo_code } = req.body;

    console.log(`[Driver Affiliates API] 司機保存推薦碼: user_id=${user_id}, promo_code=${promo_code}`);

    if (!user_id || !promo_code) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位'
      });
    }

    // 查詢用戶的 PostgreSQL UUID
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', user_id)
      .single();

    if (userError || !user) {
      return res.status(404).json({
        success: false,
        error: '用戶不存在'
      });
    }

    // 檢查是否已有推薦人（終身綁定，不可修改）
    const { data: existingReferral } = await supabase
      .from('driver_referrals')
      .select('*')
      .eq('referee_driver_id', user.id)
      .single();

    if (existingReferral) {
      return res.status(409).json({
        success: false,
        error: '您已有推薦人，推薦關係為終身綁定，不可修改',
        referrer_id: existingReferral.referrer_driver_id
      });
    }

    // 查詢推薦碼對應的推廣人
    const { data: affiliate, error: affiliateError } = await supabase
      .from('driver_affiliates')
      .select('driver_id, promo_code, affiliate_status, is_active')
      .ilike('promo_code', promo_code)
      .single();

    if (affiliateError || !affiliate) {
      return res.status(404).json({
        success: false,
        error: '推薦碼無效'
      });
    }

    if (affiliate.affiliate_status !== 'active' || !affiliate.is_active) {
      return res.status(400).json({
        success: false,
        error: '推薦碼已失效'
      });
    }

    // 防止自我推薦
    if (affiliate.driver_id === user.id) {
      return res.status(400).json({
        success: false,
        error: '不能使用自己的推薦碼'
      });
    }

    // 建立推薦關係
    const { data: newReferral, error: createError } = await supabase
      .from('driver_referrals')
      .insert({
        referrer_driver_id: affiliate.driver_id,
        referee_driver_id: user.id,
        promo_code: affiliate.promo_code
      })
      .select()
      .single();

    if (createError) {
      console.error('[Driver Affiliates API] 建立推薦關係失敗:', createError);
      return res.status(500).json({
        success: false,
        error: '建立推薦關係失敗',
        details: createError.message
      });
    }

    console.log(`[Driver Affiliates API] ✅ 成功建立推薦關係: ${newReferral.id}`);

    return res.status(201).json({
      success: true,
      data: newReferral,
      message: '推薦關係已建立（終身綁定）'
    });

  } catch (error) {
    console.error('[Driver Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/driver-affiliates/my-referrer
 * @desc 獲取當前司機的推薦人資訊
 * @access Driver (需要認證)
 */
router.get('/my-referrer', async (req: Request, res: Response) => {
  try {
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({
        success: false,
        error: '缺少 user_id 參數'
      });
    }

    // 查詢用戶的 PostgreSQL UUID
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', user_id)
      .single();

    if (userError || !user) {
      return res.status(404).json({
        success: false,
        error: '用戶不存在'
      });
    }

    // 查詢推薦關係
    const { data: referral, error: referralError } = await supabase
      .from('driver_referrals')
      .select('*')
      .eq('referee_driver_id', user.id)
      .single();

    if (referralError && referralError.code !== 'PGRST116') {
      throw referralError;
    }

    if (!referral) {
      return res.json({
        success: true,
        data: null,
        message: '尚未有推薦人'
      });
    }

    // 獲取推薦人名稱
    const { data: referrer } = await supabase
      .from('users')
      .select('id, display_name, email')
      .eq('id', referral.referrer_driver_id)
      .single();

    return res.json({
      success: true,
      data: {
        referrer_id: referral.referrer_driver_id,
        referrer_name: referrer?.display_name || referrer?.email || '司機推廣人',
        promo_code: referral.promo_code,
        created_at: referral.created_at
      }
    });

  } catch (error) {
    console.error('[Driver Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

// ============================================================
// 管理員 API
// ============================================================

/**
 * @route GET /api/driver-affiliates
 * @desc 管理員查詢所有司機推廣人
 * @access Admin
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const { status, search, page = 1, limit = 20 } = req.query;

    console.log(`[Driver Affiliates API] 查詢司機推廣人列表`);

    let query = supabase
      .from('driver_affiliates')
      .select('*, users!driver_affiliates_driver_id_fkey(display_name, email)')
      .order('created_at', { ascending: false });

    // 篩選狀態
    if (status && status !== 'all') {
      query = query.eq('affiliate_status', status);
    }

    // 搜尋（推薦碼）
    if (search) {
      query = query.ilike('promo_code', `%${search}%`);
    }

    // 分頁
    const from = (Number(page) - 1) * Number(limit);
    const to = from + Number(limit) - 1;
    query = query.range(from, to);

    const { data: affiliates, error, count } = await query;

    if (error) {
      throw error;
    }

    return res.json({
      success: true,
      data: affiliates || [],
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total: count || 0
      }
    });

  } catch (error) {
    console.error('[Driver Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/driver-affiliates/:id
 * @desc 管理員查詢單個司機推廣人詳情
 * @access Admin
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const { data: affiliate, error } = await supabase
      .from('driver_affiliates')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !affiliate) {
      return res.status(404).json({
        success: false,
        error: '司機推廣人不存在'
      });
    }

    // 獲取司機資訊
    const { data: driver } = await supabase
      .from('users')
      .select('id, display_name, email')
      .eq('id', affiliate.driver_id)
      .single();

    // 獲取推薦的司機列表
    const { data: referrals } = await supabase
      .from('driver_referrals')
      .select('*, users!driver_referrals_referee_driver_id_fkey(display_name, email)')
      .eq('referrer_driver_id', affiliate.driver_id);

    return res.json({
      success: true,
      data: {
        ...affiliate,
        driver: driver,
        referrals: referrals || []
      }
    });

  } catch (error) {
    console.error('[Driver Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route POST /api/driver-affiliates/:id/review
 * @desc 管理員審核司機推廣人申請
 * @access Admin
 */
router.post('/:id/review', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status, review_notes } = req.body;

    console.log(`[Driver Affiliates API] 審核司機推廣人: ${id}, 狀態: ${status}`);

    if (!status) {
      return res.status(400).json({
        success: false,
        error: '缺少審核狀態'
      });
    }

    if (!['active', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        error: '無效的審核狀態',
        details: '狀態必須為 active 或 rejected'
      });
    }

    // 檢查推廣人是否存在
    const { data: affiliate, error: fetchError } = await supabase
      .from('driver_affiliates')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !affiliate) {
      return res.status(404).json({
        success: false,
        error: '司機推廣人不存在'
      });
    }

    if (affiliate.affiliate_status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: '該申請已被審核',
        details: `當前狀態：${affiliate.affiliate_status}`
      });
    }

    // 更新審核狀態
    const { data: updatedAffiliate, error: updateError } = await supabase
      .from('driver_affiliates')
      .update({
        affiliate_status: status,
        is_active: status === 'active',
        reviewed_at: new Date().toISOString(),
        review_notes: review_notes || null
      })
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      throw updateError;
    }

    console.log(`[Driver Affiliates API] ✅ 成功審核司機推廣人: ${id}, 狀態: ${status}`);

    return res.json({
      success: true,
      data: updatedAffiliate,
      message: status === 'active' ? '司機推廣人申請已通過' : '司機推廣人申請已拒絕'
    });

  } catch (error) {
    console.error('[Driver Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route PUT /api/driver-affiliates/:id
 * @desc 管理員更新司機推廣人設定
 * @access Admin
 */
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      commission_fixed_enabled,
      commission_fixed,
      commission_percent_enabled,
      commission_percent,
      is_active,
      affiliate_status
    } = req.body;

    console.log(`[Driver Affiliates API] 更新司機推廣人: ${id}`);

    // 檢查推廣人是否存在
    const { data: existingAffiliate, error: fetchError } = await supabase
      .from('driver_affiliates')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !existingAffiliate) {
      return res.status(404).json({
        success: false,
        error: '司機推廣人不存在'
      });
    }

    // 建立更新物件
    const updateData: Record<string, any> = {};

    if (commission_fixed_enabled !== undefined) {
      updateData.commission_fixed_enabled = commission_fixed_enabled;
    }
    if (commission_fixed !== undefined) {
      if (commission_fixed < 0) {
        return res.status(400).json({
          success: false,
          error: '固定分潤金額不能為負數'
        });
      }
      updateData.commission_fixed = commission_fixed;
    }
    if (commission_percent_enabled !== undefined) {
      updateData.commission_percent_enabled = commission_percent_enabled;
    }
    if (commission_percent !== undefined) {
      if (commission_percent < 0 || commission_percent > 100) {
        return res.status(400).json({
          success: false,
          error: '分潤百分比必須在 0-100 之間'
        });
      }
      updateData.commission_percent = commission_percent;
    }
    if (is_active !== undefined) {
      updateData.is_active = is_active;
    }
    if (affiliate_status !== undefined) {
      if (!['pending', 'active', 'suspended', 'rejected'].includes(affiliate_status)) {
        return res.status(400).json({
          success: false,
          error: '無效的狀態值'
        });
      }
      updateData.affiliate_status = affiliate_status;
    }

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({
        success: false,
        error: '沒有要更新的欄位'
      });
    }

    // 更新資料
    const { data: updatedAffiliate, error: updateError } = await supabase
      .from('driver_affiliates')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      throw updateError;
    }

    console.log(`[Driver Affiliates API] ✅ 成功更新司機推廣人: ${id}`);

    return res.json({
      success: true,
      data: updatedAffiliate
    });

  } catch (error) {
    console.error('[Driver Affiliates API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

export default router;
