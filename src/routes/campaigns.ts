import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

/**
 * 活動優惠碼（campaign）管理
 *
 * 與推廣人碼同存 influencers 表，用 affiliate_type='campaign' 區隔。
 * 活動碼沒有真人推廣者，因此不需要登入帳密、IG、銀行帳戶等欄位，
 * 也不發放佣金（佣金開關固定關閉，分潤 trigger 便自動算出 0）。
 *
 * 所有查詢一律加上 affiliate_type='campaign' 條件，避免誤改到真人推廣者。
 */
const router = Router();

const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

const CAMPAIGN_TYPE = 'campaign';

/** 前端可編輯的欄位 */
const EDITABLE_FIELDS = [
  'name',
  'is_active',
  'discount_percentage_enabled',
  'discount_percent_charter',
  'discount_percent_instant_ride',
  'discount_percent_airport_transfer',
  'discount_amount_enabled',
  'discount_amount',
  'limit_vehicle_types',
  'limit_service_types',
  'discount_base',
  'driver_payout_mode',
  'driver_fixed_amount',
  'valid_from',
  'valid_until',
  'per_user_limit',
] as const;

interface ValidationIssue {
  field: string;
  message: string;
}

function validateCampaignPayload(body: any, { partial }: { partial: boolean }): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  const has = (k: string) => body[k] !== undefined && body[k] !== null;

  if (!partial || has('name')) {
    if (!body.name || String(body.name).trim() === '') {
      issues.push({ field: 'name', message: '活動名稱為必填' });
    }
  }

  const pctFields = [
    'discount_percent_charter',
    'discount_percent_instant_ride',
    'discount_percent_airport_transfer',
  ];
  for (const f of pctFields) {
    if (has(f)) {
      const v = Number(body[f]);
      if (!Number.isFinite(v) || v < 0 || v > 100) {
        issues.push({ field: f, message: '折扣百分比必須在 0-100 之間' });
      }
    }
  }

  if (has('discount_base') && !['total', 'base_price'].includes(body.discount_base)) {
    issues.push({ field: 'discount_base', message: 'discount_base 必須是 total 或 base_price' });
  }

  if (has('driver_payout_mode') && !['percent', 'fixed'].includes(body.driver_payout_mode)) {
    issues.push({ field: 'driver_payout_mode', message: 'driver_payout_mode 必須是 percent 或 fixed' });
  }

  if (body.driver_payout_mode === 'fixed') {
    const amount = Number(body.driver_fixed_amount);
    if (!Number.isFinite(amount) || amount <= 0) {
      issues.push({ field: 'driver_fixed_amount', message: '固定給付模式必須填寫大於 0 的司機固定額' });
    }
  }

  if (has('per_user_limit')) {
    const v = Number(body.per_user_limit);
    if (!Number.isInteger(v) || v < 1) {
      issues.push({ field: 'per_user_limit', message: '每人使用次數必須是 1 以上的整數' });
    }
  }

  if (has('valid_from') && has('valid_until')) {
    if (new Date(body.valid_from) > new Date(body.valid_until)) {
      issues.push({ field: 'valid_until', message: '結束時間必須晚於開始時間' });
    }
  }

  for (const f of ['limit_vehicle_types', 'limit_service_types']) {
    if (has(f) && !Array.isArray(body[f])) {
      issues.push({ field: f, message: `${f} 必須是陣列` });
    }
  }

  return issues;
}

function pickEditable(body: any): Record<string, any> {
  const out: Record<string, any> = {};
  for (const f of EDITABLE_FIELDS) {
    if (body[f] !== undefined) out[f] = body[f];
  }
  // 空陣列視為「不限制」，統一存 NULL，避免 checkPromoConstraints 判讀不一致
  for (const f of ['limit_vehicle_types', 'limit_service_types']) {
    if (Array.isArray(out[f]) && out[f].length === 0) out[f] = null;
  }
  return out;
}

/**
 * @route GET /api/admin/campaigns
 * @desc 活動優惠列表
 */
router.get('/', async (_req: Request, res: Response) => {
  try {
    const { data, error } = await supabase
      .from('influencers')
      .select('*')
      .eq('affiliate_type', CAMPAIGN_TYPE)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[Campaigns API] 查詢失敗:', error);
      return res.status(500).json({ success: false, error: '查詢活動優惠失敗', details: error.message });
    }

    const rows = (data || []).map(({ account_password, ...rest }) => rest);
    return res.json({ success: true, data: rows, count: rows.length });
  } catch (error) {
    console.error('[Campaigns API] 錯誤:', error);
    return res.status(500).json({ success: false, error: '內部伺服器錯誤' });
  }
});

/**
 * @route GET /api/admin/campaigns/:id/usage
 * @desc 活動使用狀況（訂單數、折扣總額、司機給付總額）
 */
router.get('/:id/usage', async (req: Request, res: Response) => {
  try {
    const { data: campaign } = await supabase
      .from('influencers')
      .select('promo_code')
      .eq('id', req.params.id)
      .eq('affiliate_type', CAMPAIGN_TYPE)
      .single();

    if (!campaign) {
      return res.status(404).json({ success: false, error: '找不到此活動' });
    }

    const { data: bookings, error } = await supabase
      .from('bookings')
      .select('id, status, total_amount, discount_amount, driver_earning, platform_fee, created_at')
      .eq('promo_code', campaign.promo_code);

    if (error) {
      console.error('[Campaigns API] 查詢使用狀況失敗:', error);
      return res.status(500).json({ success: false, error: '查詢使用狀況失敗', details: error.message });
    }

    const rows = bookings || [];
    const active = rows.filter((b) => !['cancelled', 'refunded'].includes(b.status));
    const sum = (key: string) => active.reduce((acc, b: any) => acc + Number(b[key] || 0), 0);

    return res.json({
      success: true,
      data: {
        total_bookings: rows.length,
        active_bookings: active.length,
        cancelled_bookings: rows.length - active.length,
        total_discount: sum('discount_amount'),
        total_amount: sum('total_amount'),
        total_driver_earning: sum('driver_earning'),
        total_platform_fee: sum('platform_fee'),
      },
    });
  } catch (error) {
    console.error('[Campaigns API] 錯誤:', error);
    return res.status(500).json({ success: false, error: '內部伺服器錯誤' });
  }
});

/**
 * @route POST /api/admin/campaigns
 * @desc 新增活動優惠
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const { promo_code } = req.body;

    if (!promo_code || String(promo_code).trim() === '') {
      return res.status(400).json({ success: false, error: '活動代碼為必填' });
    }

    const issues = validateCampaignPayload(req.body, { partial: false });
    if (issues.length > 0) {
      return res.status(400).json({ success: false, error: issues[0].message, issues });
    }

    const code = String(promo_code).trim();

    // 活動碼與推廣人碼共用同一個命名空間，不能重複
    const { data: existing } = await supabase
      .from('influencers')
      .select('id, affiliate_type')
      .ilike('promo_code', code)
      .maybeSingle();

    if (existing) {
      return res.status(409).json({
        success: false,
        error: `代碼「${code}」已被使用`,
      });
    }

    const payload = {
      ...pickEditable(req.body),
      promo_code: code,
      affiliate_type: CAMPAIGN_TYPE,
      affiliate_status: 'active',
      discount_type: 'by_service_type',
      // 活動碼不發佣金：兩個開關固定關閉，分潤 trigger 便算出 0
      is_commission_fixed_active: false,
      is_commission_percent_active: false,
      commission_fixed: 0,
      commission_percent: 0,
      commission_per_order: 0,
      // 活動碼不需登入，這兩個欄位為 NOT NULL，填入不可用於登入的佔位值
      account_username: `campaign_${code}`,
      account_password: 'NO_LOGIN_CAMPAIGN',
    };

    const { data, error } = await supabase
      .from('influencers')
      .insert(payload)
      .select()
      .single();

    if (error) {
      console.error('[Campaigns API] 新增失敗:', error);
      return res.status(500).json({ success: false, error: '新增活動失敗', details: error.message });
    }

    const { account_password, ...safe } = data;
    console.log(`[Campaigns API] ✅ 新增活動: ${code}`);
    return res.status(201).json({ success: true, data: safe });
  } catch (error) {
    console.error('[Campaigns API] 錯誤:', error);
    return res.status(500).json({ success: false, error: '內部伺服器錯誤' });
  }
});

/**
 * @route PUT /api/admin/campaigns/:id
 * @desc 更新活動優惠（活動代碼建立後不可更改，避免與已成立的訂單對不上）
 */
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const { data: existing } = await supabase
      .from('influencers')
      .select('id, promo_code, driver_payout_mode, driver_fixed_amount')
      .eq('id', id)
      .eq('affiliate_type', CAMPAIGN_TYPE)
      .single();

    if (!existing) {
      return res.status(404).json({ success: false, error: '找不到此活動' });
    }

    // 未指定 driver_payout_mode 時沿用現值，才能正確驗證固定額
    const merged = {
      driver_payout_mode: existing.driver_payout_mode,
      driver_fixed_amount: existing.driver_fixed_amount,
      ...req.body,
    };
    const issues = validateCampaignPayload(merged, { partial: true });
    if (issues.length > 0) {
      return res.status(400).json({ success: false, error: issues[0].message, issues });
    }

    const updateData = pickEditable(req.body);
    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ success: false, error: '沒有要更新的欄位' });
    }
    updateData.updated_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('influencers')
      .update(updateData)
      .eq('id', id)
      .eq('affiliate_type', CAMPAIGN_TYPE)
      .select()
      .single();

    if (error) {
      console.error('[Campaigns API] 更新失敗:', error);
      return res.status(500).json({ success: false, error: '更新活動失敗', details: error.message });
    }

    const { account_password, ...safe } = data;
    console.log(`[Campaigns API] ✅ 更新活動: ${existing.promo_code}`, updateData);
    return res.json({
      success: true,
      data: safe,
      // 提醒：司機固定額只影響之後建立的訂單
      note: updateData.driver_fixed_amount !== undefined
        ? '司機固定給付額已更新，僅影響之後建立的新訂單，已成立的訂單維持原快照'
        : undefined,
    });
  } catch (error) {
    console.error('[Campaigns API] 錯誤:', error);
    return res.status(500).json({ success: false, error: '內部伺服器錯誤' });
  }
});

/**
 * @route DELETE /api/admin/campaigns/:id
 * @desc 刪除活動優惠（已有訂單使用過就不允許刪除，只能停用）
 */
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const { data: existing } = await supabase
      .from('influencers')
      .select('id, promo_code')
      .eq('id', id)
      .eq('affiliate_type', CAMPAIGN_TYPE)
      .single();

    if (!existing) {
      return res.status(404).json({ success: false, error: '找不到此活動' });
    }

    const { count } = await supabase
      .from('bookings')
      .select('id', { count: 'exact', head: true })
      .eq('promo_code', existing.promo_code);

    if ((count || 0) > 0) {
      return res.status(409).json({
        success: false,
        error: `此活動已有 ${count} 筆訂單使用過，不能刪除，請改為停用`,
      });
    }

    const { error } = await supabase
      .from('influencers')
      .delete()
      .eq('id', id)
      .eq('affiliate_type', CAMPAIGN_TYPE);

    if (error) {
      console.error('[Campaigns API] 刪除失敗:', error);
      return res.status(500).json({ success: false, error: '刪除活動失敗', details: error.message });
    }

    console.log(`[Campaigns API] ✅ 刪除活動: ${existing.promo_code}`);
    return res.json({ success: true, message: '活動已刪除' });
  } catch (error) {
    console.error('[Campaigns API] 錯誤:', error);
    return res.status(500).json({ success: false, error: '內部伺服器錯誤' });
  }
});

export default router;
