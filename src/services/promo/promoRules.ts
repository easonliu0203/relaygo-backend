/**
 * 優惠碼 / 活動碼共用規則
 *
 * 推廣人碼與活動碼都存在 influencers 表，用 affiliate_type 區隔：
 *   - influencer / customer_affiliate：真人推廣者，有佣金，折扣通常套在總額
 *   - campaign：活動碼，無佣金，可限車型／服務類型／期間／每人次數，
 *               折扣可只套在基本車資，司機可改為固定給付
 *
 * 驗證與計算集中在這裡，讓 /api/promo-codes/validate 與建單流程共用同一套規則，
 * 避免前端顯示的金額與後端實際建立的訂單不一致。
 */

export interface PromoRecord {
  id: string;
  promo_code: string;
  name?: string | null;
  is_active?: boolean | null;
  affiliate_type?: string | null;

  discount_amount_enabled?: boolean | null;
  discount_amount?: number | string | null;
  discount_percentage_enabled?: boolean | null;
  discount_type?: string | null;
  discount_percentage?: number | string | null;
  discount_percent_charter?: number | string | null;
  discount_percent_instant_ride?: number | string | null;
  discount_percent_airport_transfer?: number | string | null;

  limit_vehicle_types?: string[] | null;
  limit_service_types?: string[] | null;
  discount_base?: string | null;
  driver_payout_mode?: string | null;
  driver_fixed_amount?: number | string | null;
  valid_from?: string | null;
  valid_until?: string | null;
  per_user_limit?: number | null;

  commission_per_order?: number | string | null;
}

export interface PromoContext {
  serviceType?: string | null;
  vehicleType?: string | null;
  /** users.id（不是 firebase_uid） */
  userId?: string | null;
}

export interface PromoCheckResult {
  valid: boolean;
  /** 給使用者看的訊息 */
  error?: string;
  /** 給 log 用的原因代碼 */
  reason?: string;
}

const num = (v: unknown): number => {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
};

/** 依服務類型取得折扣百分比（沿用既有的 unified / by_service_type 邏輯） */
export function resolveDiscountPercentage(promo: PromoRecord, serviceType?: string | null): number {
  if (!promo.discount_percentage_enabled) return 0;

  if (promo.discount_type === 'by_service_type' && serviceType) {
    switch (serviceType) {
      case 'charter':
        return num(promo.discount_percent_charter);
      case 'instant_ride':
        return num(promo.discount_percent_instant_ride);
      case 'airport_transfer':
        return num(promo.discount_percent_airport_transfer);
      default:
        return num(promo.discount_percentage);
    }
  }
  return num(promo.discount_percentage);
}

/**
 * 檢查優惠碼的適用限制（期間、服務類型、車型）。
 * 每人使用次數需查資料庫，另見 checkPerUserLimit。
 */
export function checkPromoConstraints(promo: PromoRecord, ctx: PromoContext): PromoCheckResult {
  if (promo.is_active === false) {
    return { valid: false, error: '優惠碼已停用', reason: 'inactive' };
  }

  const now = new Date();

  if (promo.valid_from && now < new Date(promo.valid_from)) {
    return { valid: false, error: '活動尚未開始', reason: 'not_started' };
  }

  if (promo.valid_until && now > new Date(promo.valid_until)) {
    return { valid: false, error: '活動已結束', reason: 'expired' };
  }

  const serviceLimits = promo.limit_service_types;
  if (serviceLimits && serviceLimits.length > 0) {
    if (!ctx.serviceType || !serviceLimits.includes(ctx.serviceType)) {
      return { valid: false, error: '此優惠碼不適用於本服務類型', reason: 'service_type_not_allowed' };
    }
  }

  const vehicleLimits = promo.limit_vehicle_types;
  if (vehicleLimits && vehicleLimits.length > 0) {
    if (!ctx.vehicleType || !vehicleLimits.includes(ctx.vehicleType)) {
      return {
        valid: false,
        error: `此優惠碼僅限 ${vehicleLimits.join('、')} 車型使用`,
        reason: 'vehicle_type_not_allowed',
      };
    }
  }

  return { valid: true };
}

/**
 * 檢查每個帳號的使用次數上限。
 *
 * 以 bookings 表為準，已取消／已退款的訂單不計入。
 * 注意：尚未付款（pending_payment）的訂單「會」佔用額度——寧可讓放棄結帳的客人
 * 需要客服取消舊單，也不要讓人靠重複下單多拿幾次折扣。
 */
export async function checkPerUserLimit(
  supabase: any,
  promo: PromoRecord,
  userId?: string | null
): Promise<PromoCheckResult> {
  const limit = promo.per_user_limit;
  if (!limit || limit <= 0) return { valid: true };

  if (!userId) {
    return { valid: false, error: '此優惠碼需要登入後使用', reason: 'user_required' };
  }

  const { count, error } = await supabase
    .from('bookings')
    .select('id', { count: 'exact', head: true })
    .eq('customer_id', userId)
    .eq('promo_code', promo.promo_code)
    .not('status', 'in', '(cancelled,refunded)');

  if (error) {
    console.error('[PromoRules] 查詢使用次數失敗:', error);
    // 查不到就放行，不因為統計失敗擋住正常下單
    return { valid: true };
  }

  if ((count || 0) >= limit) {
    return {
      valid: false,
      error: limit === 1 ? '此優惠碼每個帳號限用一次' : `此優惠碼每個帳號限用 ${limit} 次`,
      reason: 'per_user_limit_reached',
    };
  }

  return { valid: true };
}

export interface DiscountInput {
  /** 未折扣前的訂單總額（含所有附加費） */
  originalTotal: number;
  /** 基本車資（不含跨區費、超時費等附加費） */
  basePrice: number;
  serviceType?: string | null;
}

export interface DiscountResult {
  /** 折扣後的總額 */
  finalPrice: number;
  /** 折扣金額 */
  discountAmount: number;
  /** 實際套用的百分比 */
  discountPercentage: number;
  /** 實際套用的固定折抵金額 */
  fixedDiscountApplied: number;
  /** 折扣基準：total=折總額；base_price=只折基本車資 */
  discountBase: string;
  calculationSteps: string[];
}

/**
 * 計算折扣。
 *
 * discount_base = 'base_price' 時只對基本車資打折，跨區費／超時費／加購接送機
 * 等附加費一律照原價，不參與折扣。
 */
export function computeDiscount(promo: PromoRecord, input: DiscountInput): DiscountResult {
  const discountBase = promo.discount_base === 'base_price' ? 'base_price' : 'total';
  const originalTotal = num(input.originalTotal);
  const basePrice = num(input.basePrice);
  const steps: string[] = [];

  // 可折扣的部分，以及原價不動的部分
  const discountable = discountBase === 'base_price' ? Math.min(basePrice, originalTotal) : originalTotal;
  const untouched = originalTotal - discountable;

  steps.push(`原價：NT$ ${originalTotal.toLocaleString()}`);
  if (discountBase === 'base_price') {
    steps.push(`可折扣部分（基本車資）：NT$ ${discountable.toLocaleString()}；附加費 NT$ ${untouched.toLocaleString()} 不折扣`);
  }

  let current = discountable;
  let fixedDiscountApplied = 0;

  if (promo.discount_amount_enabled && num(promo.discount_amount) > 0) {
    fixedDiscountApplied = Math.min(num(promo.discount_amount), current);
    current -= fixedDiscountApplied;
    steps.push(`固定折扣：-NT$ ${fixedDiscountApplied.toLocaleString()}`);
  }

  const discountPercentage = resolveDiscountPercentage(promo, input.serviceType);
  if (discountPercentage > 0) {
    current = current * (1 - discountPercentage / 100);
    steps.push(`百分比折扣：${discountPercentage}% off`);
  }

  const finalPrice = Math.round(current) + untouched;
  steps.push(`折扣後總額：NT$ ${finalPrice.toLocaleString()}`);

  return {
    finalPrice,
    discountAmount: originalTotal - finalPrice,
    discountPercentage,
    fixedDiscountApplied,
    discountBase,
    calculationSteps: steps,
  };
}

/** 取得司機給付模式快照（活動碼可設固定給付） */
export function resolveDriverPayout(promo: PromoRecord | null | undefined): {
  driver_payout_mode: 'percent' | 'fixed';
  driver_fixed_amount: number;
} {
  if (promo?.driver_payout_mode === 'fixed') {
    return { driver_payout_mode: 'fixed', driver_fixed_amount: num(promo.driver_fixed_amount) };
  }
  return { driver_payout_mode: 'percent', driver_fixed_amount: 0 };
}

/** 這些欄位是計算與快照所需，查 influencers 時一併帶出 */
export const PROMO_SELECT_FIELDS = [
  'id',
  'name',
  'promo_code',
  'is_active',
  'affiliate_type',
  'discount_amount_enabled',
  'discount_amount',
  'discount_percentage_enabled',
  'discount_type',
  'discount_percentage',
  'discount_percent_charter',
  'discount_percent_instant_ride',
  'discount_percent_airport_transfer',
  'commission_fixed',
  'commission_percent',
  'commission_type',
  'commission_percent_charter',
  'commission_percent_instant_ride',
  'commission_percent_airport_transfer',
  'is_commission_fixed_active',
  'is_commission_percent_active',
  'commission_per_order',
  'limit_vehicle_types',
  'limit_service_types',
  'discount_base',
  'driver_payout_mode',
  'driver_fixed_amount',
  'valid_from',
  'valid_until',
  'per_user_limit',
].join(', ');
