import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';

const router = Router();

// Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

// Multer 配置用於文件上傳
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('只允許上傳圖片文件'));
    }
  },
});

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

    // 檢查用戶是否存在（使用 firebase_uid 查詢）
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, email, firebase_uid')
      .eq('firebase_uid', user_id)
      .single();

    if (userError || !user) {
      console.error('[Affiliates API] 用戶查詢失敗:', userError);
      return res.status(404).json({
        success: false,
        error: '用戶不存在',
        details: userError?.message
      });
    }

    console.log(`[Affiliates API] 找到用戶: id=${user.id}, firebase_uid=${user.firebase_uid}`);

    // 使用 PostgreSQL UUID (user.id) 而不是 Firebase UID
    const userUuid = user.id;

    // 檢查用戶是否已經是推廣人
    const { data: existingAffiliate } = await supabase
      .from('influencers')
      .select('id, affiliate_status')
      .eq('user_id', userUuid)
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
        user_id: userUuid, // 使用 PostgreSQL UUID
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
        terms_accepted: true, // 記錄用戶已同意合作條款
        terms_accepted_at: new Date().toISOString(), // 記錄同意時間
        account_username: `affiliate_${userUuid.substring(0, 8)}`, // 自動生成帳號
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
    const { status, review_notes } = req.body;

    console.log(`[Affiliates API] 審核推廣人: ${id}, 狀態: ${status}`);

    // 驗證必填欄位
    if (!status) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: '審核狀態為必填'
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
        reviewed_by: null, // 客戶推廣人系統不追蹤審核人員
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

    console.log(`[Affiliates API] 獲取推廣人狀態: firebase_uid=${user_id}`);

    // 先通過 firebase_uid 查詢用戶的 UUID
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', user_id as string)
      .single();

    if (userError || !user) {
      console.error('[Affiliates API] 用戶查詢失敗:', userError);
      return res.status(404).json({
        success: false,
        error: '用戶不存在',
        details: userError?.message
      });
    }

    console.log(`[Affiliates API] 找到用戶 UUID: ${user.id}`);

    // 查詢用戶的推廣人記錄（使用 PostgreSQL UUID）
    const { data: affiliate, error } = await supabase
      .from('influencers')
      .select('id, promo_code, affiliate_status, is_active, total_referrals, total_earnings, applied_at, reviewed_at, review_notes')
      .eq('user_id', user.id)
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
        affiliate_status: affiliate.affiliate_status,
        is_active: affiliate.is_active,
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

/**
 * @route GET /api/affiliates/payment-account
 * @desc 獲取收款帳戶資訊
 * @access Customer (需要認證)
 */
router.get('/payment-account', async (req: Request, res: Response) => {
  try {
    const userId = req.headers['user-id'] as string;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: '未提供用戶 ID'
      });
    }

    // 查詢用戶的 UUID
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', userId)
      .single();

    if (userError || !user) {
      return res.status(404).json({
        success: false,
        error: '用戶不存在'
      });
    }

    // 查詢收款帳戶資訊
    const { data: account, error: accountError } = await supabase
      .from('affiliate_payment_accounts')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (accountError && accountError.code !== 'PGRST116') {
      throw accountError;
    }

    return res.json({
      success: true,
      data: account || null
    });

  } catch (error) {
    console.error('[Affiliates API] 獲取收款帳戶失敗:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route POST /api/affiliates/payment-account
 * @desc 創建或更新收款帳戶
 * @access Customer (需要認證)
 */
router.post('/payment-account', upload.fields([
  { name: 'id_card_front', maxCount: 1 },
  { name: 'id_card_back', maxCount: 1 },
  { name: 'passport', maxCount: 1 },
  { name: 'bankbook', maxCount: 1 }
]), async (req: Request, res: Response) => {
  try {
    const userId = req.headers['user-id'] as string;
    const files = req.files as { [fieldname: string]: Express.Multer.File[] };
    const { account_type, bank_name, branch_code, account_number, account_holder_name,
            bank_name_en, swift_code, account_holder_name_en, iban } = req.body;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: '未提供用戶 ID'
      });
    }

    // 查詢用戶的 UUID
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', userId)
      .single();

    if (userError || !user) {
      return res.status(404).json({
        success: false,
        error: '用戶不存在'
      });
    }

    const userUuid = user.id;

    // 上傳照片到 Supabase Storage
    const uploadedUrls: any = {};

    if (files.id_card_front && files.id_card_front[0]) {
      const file = files.id_card_front[0];
      const fileName = `${userUuid}/id_card_front_${uuidv4()}.${file.mimetype.split('/')[1]}`;
      const { data, error } = await supabase.storage
        .from('affiliate-payment-documents')
        .upload(fileName, file.buffer, {
          contentType: file.mimetype,
          upsert: true
        });

      if (error) throw error;
      uploadedUrls.id_card_front_url = fileName;
    }

    if (files.id_card_back && files.id_card_back[0]) {
      const file = files.id_card_back[0];
      const fileName = `${userUuid}/id_card_back_${uuidv4()}.${file.mimetype.split('/')[1]}`;
      const { data, error } = await supabase.storage
        .from('affiliate-payment-documents')
        .upload(fileName, file.buffer, {
          contentType: file.mimetype,
          upsert: true
        });

      if (error) throw error;
      uploadedUrls.id_card_back_url = fileName;
    }

    if (files.passport && files.passport[0]) {
      const file = files.passport[0];
      const fileName = `${userUuid}/passport_${uuidv4()}.${file.mimetype.split('/')[1]}`;
      const { data, error } = await supabase.storage
        .from('affiliate-payment-documents')
        .upload(fileName, file.buffer, {
          contentType: file.mimetype,
          upsert: true
        });

      if (error) throw error;
      uploadedUrls.passport_url = fileName;
    }

    if (files.bankbook && files.bankbook[0]) {
      const file = files.bankbook[0];
      const fileName = `${userUuid}/bankbook_${uuidv4()}.${file.mimetype.split('/')[1]}`;
      const { data, error } = await supabase.storage
        .from('affiliate-payment-documents')
        .upload(fileName, file.buffer, {
          contentType: file.mimetype,
          upsert: true
        });

      if (error) throw error;
      uploadedUrls.bankbook_url = fileName;
    }

    // 準備資料庫記錄
    const accountData: any = {
      user_id: userUuid,
      account_type,
      ...uploadedUrls,
      status: 'pending',
      updated_at: new Date().toISOString()
    };

    if (account_type === 'taiwan') {
      accountData.bank_name = bank_name;
      accountData.branch_code = branch_code;
      accountData.account_number = account_number;
      accountData.account_holder_name = account_holder_name;
    } else {
      accountData.bank_name_en = bank_name_en;
      accountData.swift_code = swift_code;
      accountData.account_holder_name_en = account_holder_name_en;
      accountData.iban = iban;
    }

    // 使用 upsert 創建或更新記錄
    const { data: result, error: upsertError } = await supabase
      .from('affiliate_payment_accounts')
      .upsert(accountData, {
        onConflict: 'user_id'
      })
      .select()
      .single();

    if (upsertError) {
      throw upsertError;
    }

    return res.json({
      success: true,
      message: '收款帳戶資料已提交',
      data: result
    });

  } catch (error) {
    console.error('[Affiliates API] 創建收款帳戶失敗:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/affiliates/my-referrals
 * @desc 獲取推廣人的下線列表（分頁）
 * @access Customer (需要認證)
 * @query user_id - 用戶 Firebase UID
 * @query page - 頁碼（從 1 開始，默認 1）
 * @query limit - 每頁數量（默認 10，最大 50）
 */
router.get('/my-referrals', async (req: Request, res: Response) => {
  try {
    const { user_id, page = '1', limit = '10' } = req.query;

    console.log(`[Affiliates API] 獲取下線列表: user_id=${user_id}, page=${page}, limit=${limit}`);

    // 驗證必填欄位
    if (!user_id) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: '用戶 ID 為必填'
      });
    }

    // 驗證分頁參數
    const pageNum = parseInt(page as string, 10);
    const limitNum = Math.min(parseInt(limit as string, 10), 50); // 最大 50 筆

    if (isNaN(pageNum) || pageNum < 1) {
      return res.status(400).json({
        success: false,
        error: '無效的頁碼',
        details: '頁碼必須為大於 0 的整數'
      });
    }

    if (isNaN(limitNum) || limitNum < 1) {
      return res.status(400).json({
        success: false,
        error: '無效的每頁數量',
        details: '每頁數量必須為大於 0 的整數'
      });
    }

    // 查找用戶
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', user_id)
      .single();

    if (userError || !user) {
      console.error('[Affiliates API] 用戶查詢失敗:', userError);
      return res.status(404).json({
        success: false,
        error: '用戶不存在',
        details: userError?.message
      });
    }

    // 查找推廣人資訊
    const { data: influencer, error: influencerError } = await supabase
      .from('influencers')
      .select('id')
      .eq('user_id', user.id)
      .single();

    if (influencerError || !influencer) {
      console.error('[Affiliates API] 推廣人查詢失敗:', influencerError);
      return res.status(404).json({
        success: false,
        error: '您不是推廣人',
        details: influencerError?.message
      });
    }

    // 計算分頁偏移量
    const offset = (pageNum - 1) * limitNum;

    // 查詢下線總數
    const { count: totalCount, error: countError } = await supabase
      .from('referrals')
      .select('*', { count: 'exact', head: true })
      .eq('influencer_id', influencer.id);

    if (countError) {
      console.error('[Affiliates API] 查詢下線總數失敗:', countError);
      return res.status(500).json({
        success: false,
        error: '查詢下線總數失敗',
        details: countError.message
      });
    }

    // 查詢下線列表（分頁）
    const { data: referrals, error: referralsError } = await supabase
      .from('referrals')
      .select(`
        id,
        referee_id,
        created_at,
        users!referrals_referee_id_fkey (
          email
        )
      `)
      .eq('influencer_id', influencer.id)
      .order('created_at', { ascending: false })
      .range(offset, offset + limitNum - 1);

    if (referralsError) {
      console.error('[Affiliates API] 查詢下線列表失敗:', referralsError);
      return res.status(500).json({
        success: false,
        error: '查詢下線列表失敗',
        details: referralsError.message
      });
    }

    // 處理信箱遮罩
    const maskedReferrals = (referrals || []).map(referral => {
      const email = (referral.users as any)?.email || '';
      const maskedEmail = maskEmail(email);

      return {
        id: referral.id,
        referee_id: referral.referee_id,
        email: maskedEmail,
        created_at: referral.created_at
      };
    });

    // 計算總頁數
    const totalPages = Math.ceil((totalCount || 0) / limitNum);

    console.log(`[Affiliates API] ✅ 成功獲取下線列表: ${maskedReferrals.length} 筆`);

    return res.json({
      success: true,
      data: {
        referrals: maskedReferrals,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total: totalCount || 0,
          totalPages
        }
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

/**
 * @route GET /api/affiliates/referral-orders/:refereeId
 * @desc 獲取下線的消費記錄（已完成訂單）
 * @access Customer (需要認證 - 僅限推廣人查看自己的下線)
 * @param refereeId - 下線的 user ID (UUID)
 * @query user_id - 推廣人的 Firebase UID
 * @query page - 頁碼（從 1 開始，默認 1）
 * @query limit - 每頁數量（默認 10，最大 50）
 */
router.get('/referral-orders/:refereeId', async (req: Request, res: Response) => {
  try {
    const { refereeId } = req.params;
    const { user_id, page = '1', limit = '10' } = req.query;

    console.log(`[Affiliates API] 查詢下線消費記錄: refereeId=${refereeId}, user_id=${user_id}`);

    // 驗證必填欄位
    if (!user_id || !refereeId) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: '用戶 ID 和下線 ID 為必填'
      });
    }

    // 驗證分頁參數
    const pageNum = parseInt(page as string, 10);
    const limitNum = Math.min(parseInt(limit as string, 10), 50);

    if (isNaN(pageNum) || pageNum < 1) {
      return res.status(400).json({
        success: false,
        error: '無效的頁碼',
        details: '頁碼必須為大於 0 的整數'
      });
    }

    if (isNaN(limitNum) || limitNum < 1) {
      return res.status(400).json({
        success: false,
        error: '無效的每頁數量',
        details: '每頁數量必須為大於 0 的整數'
      });
    }

    // 查找當前用戶
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', user_id)
      .single();

    if (userError || !user) {
      console.error('[Affiliates API] 用戶查詢失敗:', userError);
      return res.status(404).json({
        success: false,
        error: '用戶不存在',
        details: userError?.message
      });
    }

    // 查找推廣人資訊
    const { data: influencer, error: influencerError } = await supabase
      .from('influencers')
      .select('id')
      .eq('user_id', user.id)
      .single();

    if (influencerError || !influencer) {
      console.error('[Affiliates API] 推廣人查詢失敗:', influencerError);
      return res.status(404).json({
        success: false,
        error: '您不是推廣人',
        details: influencerError?.message
      });
    }

    // 驗證下線是否屬於此推廣人
    const { data: referral, error: referralError } = await supabase
      .from('referrals')
      .select(`
        id,
        referee_id,
        created_at,
        users!referrals_referee_id_fkey (
          email
        )
      `)
      .eq('influencer_id', influencer.id)
      .eq('referee_id', refereeId)
      .single();

    if (referralError || !referral) {
      console.error('[Affiliates API] 下線驗證失敗:', referralError);
      return res.status(403).json({
        success: false,
        error: '您沒有權限查看此下線的消費記錄',
        details: '此用戶不是您的下線'
      });
    }

    // 計算分頁偏移量
    const offset = (pageNum - 1) * limitNum;

    // 查詢下線的已完成訂單總數
    const { count: totalCount, error: countError } = await supabase
      .from('bookings')
      .select('*', { count: 'exact', head: true })
      .eq('customer_id', refereeId)
      .eq('influencer_id', influencer.id)
      .eq('status', 'completed');

    if (countError) {
      console.error('[Affiliates API] 查詢訂單總數失敗:', countError);
      return res.status(500).json({
        success: false,
        error: '查詢訂單總數失敗',
        details: countError.message
      });
    }

    // 查詢下線的已完成訂單（分頁）
    // 只查詢需要顯示的欄位，保護隱私
    const { data: orders, error: ordersError } = await supabase
      .from('bookings')
      .select(`
        id,
        completed_at,
        total_amount,
        final_price,
        influencer_commission,
        influencer_commission_type,
        influencer_commission_rate,
        influencer_commission_fixed,
        pickup_location,
        destination
      `)
      .eq('customer_id', refereeId)
      .eq('influencer_id', influencer.id)
      .eq('status', 'completed')
      .order('completed_at', { ascending: false })
      .range(offset, offset + limitNum - 1);

    if (ordersError) {
      console.error('[Affiliates API] 查詢訂單失敗:', ordersError);
      return res.status(500).json({
        success: false,
        error: '查詢訂單失敗',
        details: ordersError.message
      });
    }

    // 計算總分潤金額
    const { data: totalCommissionData, error: totalCommissionError } = await supabase
      .from('bookings')
      .select('influencer_commission')
      .eq('customer_id', refereeId)
      .eq('influencer_id', influencer.id)
      .eq('status', 'completed');

    let totalCommission = 0;
    if (!totalCommissionError && totalCommissionData) {
      totalCommission = totalCommissionData.reduce((sum, order) => {
        return sum + (parseFloat(order.influencer_commission) || 0);
      }, 0);
    }

    // 處理訂單資料，保護隱私
    const processedOrders = (orders || []).map(order => {
      // 從地址中提取城市/區域（只顯示到城市層級）
      const pickupRegion = extractRegion(order.pickup_location);
      const destinationRegion = extractRegion(order.destination);

      // 使用 final_price（折扣後價格）作為顯示金額，若無則使用 total_amount
      const orderAmount = order.final_price || order.total_amount || 0;

      return {
        completed_at: order.completed_at,
        order_amount: parseFloat(orderAmount) || 0,
        commission_amount: parseFloat(order.influencer_commission) || 0,
        commission_type: order.influencer_commission_type || 'percent',
        commission_rate: parseFloat(order.influencer_commission_rate) || 0,
        commission_fixed: parseFloat(order.influencer_commission_fixed) || 0,
        pickup_region: pickupRegion,
        destination_region: destinationRegion
      };
    });

    // 計算總頁數
    const totalPages = Math.ceil((totalCount || 0) / limitNum);

    // 取得下線的遮罩信箱
    const refereeEmail = (referral.users as any)?.email || '';
    const maskedEmail = maskEmail(refereeEmail);

    console.log(`[Affiliates API] ✅ 成功查詢下線消費記錄: ${processedOrders.length} 筆`);

    return res.json({
      success: true,
      data: {
        referral: {
          referee_id: refereeId,
          email: maskedEmail,
          total_orders: totalCount || 0,
          total_commission: totalCommission
        },
        orders: processedOrders,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total: totalCount || 0,
          totalPages
        }
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

/**
 * 從地址中提取區域（城市）
 * 例如：「台北市中山區南京東路三段123號」 -> 「台北市」
 * 例如：「新北市板橋區文化路123號」 -> 「新北市」
 */
function extractRegion(address: string | null | undefined): string {
  if (!address) {
    return '';
  }

  // 嘗試匹配台灣縣市
  const cityMatch = address.match(/([\u4e00-\u9fa5]{2,3}(市|縣))/);
  if (cityMatch) {
    return cityMatch[1];
  }

  // 如果無法匹配，返回空字串
  return '';
}

/**
 * 信箱遮罩函數
 * 只顯示前 3 個字符，中間用 *** 替代，保留 @ 及後續域名
 * 例如：123456789@gmail.com -> 123***@gmail.com
 */
function maskEmail(email: string): string {
  if (!email || !email.includes('@')) {
    return email;
  }

  const [localPart, domain] = email.split('@');

  if (localPart.length <= 3) {
    // 如果本地部分少於等於 3 個字符，全部顯示
    return email;
  }

  // 只顯示前 3 個字符，其餘用 *** 替代
  const maskedLocalPart = localPart.substring(0, 3) + '***';

  return `${maskedLocalPart}@${domain}`;
}

export default router;

