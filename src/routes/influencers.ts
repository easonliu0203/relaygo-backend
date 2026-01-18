import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcryptjs';

const router = Router();

// Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

interface Influencer {
  id: string;
  name: string;
  instagram_url: string | null;
  promo_code: string;
  discount_amount_enabled: boolean;
  discount_amount: number;
  discount_percentage_enabled: boolean;
  discount_percentage: number;
  commission_per_order: number;
  account_username: string;
  account_password: string;
  bank_name: string | null;
  bank_code: string | null;
  bank_account_number: string | null;
  bank_account_name: string | null;
  created_at: string;
  updated_at: string;
  is_active: boolean;
}

/**
 * @route GET /api/admin/influencers
 * @desc 獲取所有網紅列表
 * @access Admin
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const { affiliate_type } = req.query;
    console.log('[Influencers API] 獲取網紅列表', { affiliate_type });

    // 建立查詢
    let query = supabase
      .from('influencers')
      .select('*');

    // 如果指定了 affiliate_type，則篩選
    if (affiliate_type) {
      query = query.eq('affiliate_type', affiliate_type);
    }

    // 排序
    query = query.order('created_at', { ascending: false });

    const { data, error } = await query;

    if (error) {
      console.error('[Influencers API] Supabase 查詢錯誤:', error);
      return res.status(500).json({
        success: false,
        error: '查詢網紅列表失敗',
        details: error.message
      });
    }

    // 移除密碼欄位（不回傳給前端）
    const influencersWithoutPassword = data?.map(({ account_password, ...rest }) => rest) || [];

    console.log(`[Influencers API] ✅ 成功獲取 ${data?.length || 0} 個網紅`);

    return res.json({
      success: true,
      data: influencersWithoutPassword,
      count: data?.length || 0
    });

  } catch (error) {
    console.error('[Influencers API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/admin/influencers/:id
 * @desc 獲取單一網紅資料
 * @access Admin
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log(`[Influencers API] 獲取網紅: ${id}`);

    const { data, error } = await supabase
      .from('influencers')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      console.error('[Influencers API] Supabase 查詢錯誤:', error);
      return res.status(404).json({
        success: false,
        error: '網紅不存在',
        details: error.message
      });
    }

    // 移除密碼欄位
    const { account_password, ...influencerWithoutPassword } = data;

    console.log(`[Influencers API] ✅ 成功獲取網紅: ${data.name}`);

    return res.json({
      success: true,
      data: influencerWithoutPassword
    });

  } catch (error) {
    console.error('[Influencers API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route POST /api/admin/influencers
 * @desc 新增網紅
 * @access Admin
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    console.log('[Influencers API] 新增網紅');

    const {
      name,
      instagram_url,
      promo_code,
      discount_amount_enabled,
      discount_amount,
      discount_percentage_enabled,
      discount_percentage,
      commission_per_order,
      account_username,
      account_password,
      bank_name,
      bank_code,
      bank_account_number,
      bank_account_name,
      is_active
    } = req.body;

    // 驗證必填欄位
    if (!name || !promo_code || !account_username || !account_password) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: '網紅名稱、優惠代碼、登入帳號和密碼為必填'
      });
    }

    // 檢查優惠代碼是否已存在
    const { data: existingPromoCode } = await supabase
      .from('influencers')
      .select('id')
      .eq('promo_code', promo_code)
      .single();

    if (existingPromoCode) {
      return res.status(409).json({
        success: false,
        error: '優惠代碼已存在',
        details: `優惠代碼 "${promo_code}" 已被使用`
      });
    }

    // 檢查帳號是否已存在
    const { data: existingUsername } = await supabase
      .from('influencers')
      .select('id')
      .eq('account_username', account_username)
      .single();

    if (existingUsername) {
      return res.status(409).json({
        success: false,
        error: '帳號已存在',
        details: `帳號 "${account_username}" 已被使用`
      });
    }

    // 加密密碼
    const hashedPassword = await bcrypt.hash(account_password, 10);

    // 新增網紅
    const { data, error } = await supabase
      .from('influencers')
      .insert({
        name,
        instagram_url: instagram_url || null,
        promo_code,
        discount_amount_enabled: discount_amount_enabled || false,
        discount_amount: discount_amount || 0,
        discount_percentage_enabled: discount_percentage_enabled || false,
        discount_percentage: discount_percentage || 0,
        commission_per_order: commission_per_order || 0,
        account_username,
        account_password: hashedPassword,
        bank_name: bank_name || null,
        bank_code: bank_code || null,
        bank_account_number: bank_account_number || null,
        bank_account_name: bank_account_name || null,
        is_active: is_active !== undefined ? is_active : true
      })
      .select()
      .single();

    if (error) {
      console.error('[Influencers API] 新增失敗:', error);
      return res.status(500).json({
        success: false,
        error: '新增網紅失敗',
        details: error.message
      });
    }

    // 移除密碼欄位
    const { account_password: _, ...influencerWithoutPassword } = data;

    console.log(`[Influencers API] ✅ 成功新增網紅: ${data.name} (ID: ${data.id})`);

    return res.status(201).json({
      success: true,
      data: influencerWithoutPassword,
      message: '網紅新增成功'
    });

  } catch (error) {
    console.error('[Influencers API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route PATCH /api/admin/influencers/:id
 * @desc 更新網紅資料
 * @access Admin
 */
router.patch('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log(`[Influencers API] 更新網紅: ${id}`);

    const {
      name,
      instagram_url,
      promo_code,
      discount_amount_enabled,
      discount_amount,
      discount_percentage_enabled,
      discount_percentage,
      commission_per_order,
      account_username,
      account_password,
      bank_name,
      bank_code,
      bank_account_number,
      bank_account_name,
      is_active
    } = req.body;

    // 檢查網紅是否存在
    const { data: existingInfluencer, error: fetchError } = await supabase
      .from('influencers')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !existingInfluencer) {
      return res.status(404).json({
        success: false,
        error: '網紅不存在'
      });
    }

    // 如果要更新優惠代碼，檢查是否與其他網紅重複
    if (promo_code && promo_code !== existingInfluencer.promo_code) {
      const { data: duplicatePromoCode } = await supabase
        .from('influencers')
        .select('id')
        .eq('promo_code', promo_code)
        .neq('id', id)
        .single();

      if (duplicatePromoCode) {
        return res.status(409).json({
          success: false,
          error: '優惠代碼已存在',
          details: `優惠代碼 "${promo_code}" 已被其他網紅使用`
        });
      }
    }

    // 如果要更新帳號，檢查是否與其他網紅重複
    if (account_username && account_username !== existingInfluencer.account_username) {
      const { data: duplicateUsername } = await supabase
        .from('influencers')
        .select('id')
        .eq('account_username', account_username)
        .neq('id', id)
        .single();

      if (duplicateUsername) {
        return res.status(409).json({
          success: false,
          error: '帳號已存在',
          details: `帳號 "${account_username}" 已被其他網紅使用`
        });
      }
    }

    // 準備更新資料
    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (instagram_url !== undefined) updateData.instagram_url = instagram_url;
    if (promo_code !== undefined) updateData.promo_code = promo_code;
    if (discount_amount_enabled !== undefined) updateData.discount_amount_enabled = discount_amount_enabled;
    if (discount_amount !== undefined) updateData.discount_amount = discount_amount;
    if (discount_percentage_enabled !== undefined) updateData.discount_percentage_enabled = discount_percentage_enabled;
    if (discount_percentage !== undefined) updateData.discount_percentage = discount_percentage;
    if (commission_per_order !== undefined) updateData.commission_per_order = commission_per_order;
    if (account_username !== undefined) updateData.account_username = account_username;
    if (bank_name !== undefined) updateData.bank_name = bank_name;
    if (bank_code !== undefined) updateData.bank_code = bank_code;
    if (bank_account_number !== undefined) updateData.bank_account_number = bank_account_number;
    if (bank_account_name !== undefined) updateData.bank_account_name = bank_account_name;
    if (is_active !== undefined) updateData.is_active = is_active;

    // 如果有提供新密碼，則加密並更新
    if (account_password) {
      updateData.account_password = await bcrypt.hash(account_password, 10);
    }

    // 更新網紅資料
    const { data, error } = await supabase
      .from('influencers')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[Influencers API] 更新失敗:', error);
      return res.status(500).json({
        success: false,
        error: '更新網紅失敗',
        details: error.message
      });
    }

    // 移除密碼欄位
    const { account_password: _, ...influencerWithoutPassword } = data;

    console.log(`[Influencers API] ✅ 成功更新網紅: ${data.name}`);

    return res.json({
      success: true,
      data: influencerWithoutPassword,
      message: '網紅更新成功'
    });

  } catch (error) {
    console.error('[Influencers API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route DELETE /api/admin/influencers/:id
 * @desc 刪除網紅
 * @access Admin
 */
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log(`[Influencers API] 刪除網紅: ${id}`);

    // 檢查網紅是否存在
    const { data: existingInfluencer, error: fetchError } = await supabase
      .from('influencers')
      .select('name')
      .eq('id', id)
      .single();

    if (fetchError || !existingInfluencer) {
      return res.status(404).json({
        success: false,
        error: '網紅不存在'
      });
    }

    // 刪除網紅（CASCADE 會自動刪除相關的 promo_code_usage 記錄）
    const { error } = await supabase
      .from('influencers')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('[Influencers API] 刪除失敗:', error);
      return res.status(500).json({
        success: false,
        error: '刪除網紅失敗',
        details: error.message
      });
    }

    console.log(`[Influencers API] ✅ 成功刪除網紅: ${existingInfluencer.name}`);

    return res.json({
      success: true,
      message: '網紅刪除成功'
    });

  } catch (error) {
    console.error('[Influencers API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/admin/influencers/:id/performance
 * @desc 獲取網紅推廣績效
 * @access Admin
 */
router.get('/:id/performance', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log(`[Influencers API] 獲取網紅績效: ${id}`);

    // 1. 獲取網紅基本資訊
    const { data: influencer, error: influencerError } = await supabase
      .from('influencers')
      .select('*')
      .eq('id', id)
      .single();

    if (influencerError || !influencer) {
      return res.status(404).json({
        success: false,
        error: '網紅不存在'
      });
    }

    // 移除密碼欄位
    const { account_password, ...influencerWithoutPassword } = influencer;

    // 2. 獲取使用記錄（只查詢 promo_code_usage 表）
    const { data: usageRecords, error: usageError } = await supabase
      .from('promo_code_usage')
      .select('*')
      .eq('influencer_id', id)
      .order('used_at', { ascending: false });

    if (usageError) {
      console.error('[Influencers API] 查詢使用記錄失敗:', usageError);
      return res.status(500).json({
        success: false,
        error: '查詢使用記錄失敗',
        details: usageError.message
      });
    }

    // 3. 計算統計數據
    const totalUsageCount = usageRecords?.length || 0;
    const totalCommission = usageRecords?.reduce((sum, record) => sum + (record.commission_amount || 0), 0) || 0;

    // 計算本月統計（使用台灣時區）
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;
    const currentMonthStart = new Date(currentYear, currentMonth - 1, 1);
    const currentMonthEnd = new Date(currentYear, currentMonth, 0, 23, 59, 59);

    const currentMonthRecords = usageRecords?.filter(record => {
      const usedAt = new Date(record.used_at);
      return usedAt >= currentMonthStart && usedAt <= currentMonthEnd;
    }) || [];

    const currentMonthUsageCount = currentMonthRecords.length;
    const currentMonthCommission = currentMonthRecords.reduce((sum, record) => sum + (record.commission_amount || 0), 0);

    // 4. 如果有使用記錄，查詢訂單和客戶資訊
    let usageHistory: any[] = [];

    if (usageRecords && usageRecords.length > 0) {
      // 提取所有 booking_id
      const bookingIds = usageRecords.map(record => record.booking_id);

      // 查詢訂單資訊
      const { data: bookings, error: bookingsError } = await supabase
        .from('bookings')
        .select('id, status, customer_id')
        .in('id', bookingIds);

      if (bookingsError) {
        console.error('[Influencers API] 查詢訂單失敗:', bookingsError);
        // 不中斷，繼續處理
      }

      // 提取所有 customer_id
      const customerIds = bookings?.map(b => b.customer_id).filter(Boolean) || [];

      // 查詢客戶資訊
      let users: any[] = [];
      if (customerIds.length > 0) {
        const { data: usersData, error: usersError } = await supabase
          .from('users')
          .select('id, full_name, email')
          .in('id', customerIds);

        if (usersError) {
          console.error('[Influencers API] 查詢客戶失敗:', usersError);
          // 不中斷，繼續處理
        } else {
          users = usersData || [];
        }
      }

      // 組合資料
      usageHistory = usageRecords.map(record => {
        const booking = bookings?.find(b => b.id === record.booking_id);
        const customer = users.find(u => u.id === booking?.customer_id);

        return {
          id: record.id,
          booking_id: record.booking_id,
          customer_name: customer?.full_name || '未知客戶',
          customer_email: customer?.email || '',
          used_at: record.used_at,
          original_price: record.original_price,
          final_price: record.final_price,
          commission_amount: record.commission_amount,
          booking_status: booking?.status || 'unknown'
        };
      });
    }

    console.log(`[Influencers API] ✅ 成功獲取網紅績效: ${influencer.name}`);
    console.log(`[Influencers API] 總使用次數: ${totalUsageCount}, 總推廣獎金: NT$ ${totalCommission}`);

    return res.json({
      success: true,
      data: {
        influencer: influencerWithoutPassword,
        statistics: {
          total_usage_count: totalUsageCount,
          total_commission: totalCommission,
          current_month_usage_count: currentMonthUsageCount,
          current_month_commission: currentMonthCommission
        },
        usage_history: usageHistory
      }
    });

  } catch (error) {
    console.error('[Influencers API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/admin/influencers/:id/referrals
 * @desc 獲取推廣人的推薦記錄
 * @access Admin
 */
router.get('/:id/referrals', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log(`[Influencers API] 獲取推廣人推薦記錄: ${id}`);

    // 查詢推薦記錄，並關聯被推薦人資料
    const { data, error } = await supabase
      .from('referrals')
      .select(`
        id,
        referee_id,
        first_booking_id,
        created_at,
        users:referee_id (
          id,
          first_name,
          last_name
        )
      `)
      .eq('influencer_id', id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[Influencers API] 查詢推薦記錄錯誤:', error);
      return res.status(500).json({
        success: false,
        error: '查詢推薦記錄失敗',
        details: error.message
      });
    }

    // 格式化資料
    const referrals = data?.map((record: any) => ({
      id: record.id,
      referee_id: record.referee_id,
      referee_name: record.users ? `${record.users.first_name} ${record.users.last_name}` : '未知',
      first_booking_id: record.first_booking_id,
      created_at: record.created_at
    })) || [];

    console.log(`[Influencers API] ✅ 成功獲取 ${referrals.length} 筆推薦記錄`);

    return res.json({
      success: true,
      data: referrals,
      count: referrals.length
    });

  } catch (error) {
    console.error('[Influencers API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/admin/influencers/:id/commissions
 * @desc 獲取推廣人的分潤記錄
 * @access Admin
 */
router.get('/:id/commissions', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log(`[Influencers API] 獲取推廣人分潤記錄: ${id}`);

    // 查詢分潤記錄
    const { data, error } = await supabase
      .from('promo_code_usage')
      .select('*')
      .eq('influencer_id', id)
      .not('commission_amount', 'is', null)
      .order('used_at', { ascending: false });

    if (error) {
      console.error('[Influencers API] 查詢分潤記錄錯誤:', error);
      return res.status(500).json({
        success: false,
        error: '查詢分潤記錄失敗',
        details: error.message
      });
    }

    // 格式化資料
    const commissions = data?.map((record: any) => ({
      id: record.id,
      booking_id: record.booking_id,
      order_amount: record.order_amount || 0,
      commission_amount: record.commission_amount || 0,
      commission_type: record.commission_type || 'fixed',
      commission_rate: record.commission_rate,
      commission_status: record.commission_status || 'pending',
      used_at: record.used_at
    })) || [];

    console.log(`[Influencers API] ✅ 成功獲取 ${commissions.length} 筆分潤記錄`);

    return res.json({
      success: true,
      data: commissions,
      count: commissions.length
    });

  } catch (error) {
    console.error('[Influencers API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

export default router;

