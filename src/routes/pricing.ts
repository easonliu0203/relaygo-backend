import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import {
  REGION_SETTINGS,
  getLocalTime,
  getRegionSettings,
  calculateSurcharges,
  determineRegionFromCoords,
  isNightTime as checkNightTime,
  getActiveFestival,
  type RegionSettings,
  type RegionTimeInfo
} from '../../shared/constants/region_settings';

const router = Router();

// Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

// 新的車型映射：資料庫車型代碼 -> 內部車型類別
const VEHICLE_TYPE_MAPPING: Record<string, string> = {
  'XS': 'extra_small',  // Extra Small 特小型
  'S': 'small',         // Small 小型 (CAMRY 等)
  'M': 'medium',        // Medium 中型 (RAV4 等)
  'L': 'large',         // Large 大型 (VITO 等)
  'XL': 'extra_large',  // Extra Large 特大型
};

// 車型顯示名稱（多語言）
const VEHICLE_DISPLAY_NAMES_I18N: Record<string, Record<string, string>> = {
  'extra_small': {
    'zh-TW': 'Extra Small 特小型',
    'en': 'Extra Small',
    'ja': 'Extra Small 特小型',
    'ko': 'Extra Small 특소형',
    'vi': 'Extra Small Cực nhỏ',
    'th': 'Extra Small ขนาดเล็กพิเศษ',
    'ms': 'Extra Small Sangat Kecil',
    'id': 'Extra Small Sangat Kecil',
  },
  'small': {
    'zh-TW': 'Small 小型',
    'en': 'Small',
    'ja': 'Small 小型',
    'ko': 'Small 소형',
    'vi': 'Small Nhỏ',
    'th': 'Small ขนาดเล็ก',
    'ms': 'Small Kecil',
    'id': 'Small Kecil',
  },
  'medium': {
    'zh-TW': 'Medium 中型',
    'en': 'Medium',
    'ja': 'Medium 中型',
    'ko': 'Medium 중형',
    'vi': 'Medium Trung bình',
    'th': 'Medium ขนาดกลาง',
    'ms': 'Medium Sederhana',
    'id': 'Medium Sedang',
  },
  'large': {
    'zh-TW': 'Large 大型',
    'en': 'Large',
    'ja': 'Large 大型',
    'ko': 'Large 대형',
    'vi': 'Large Lớn',
    'th': 'Large ขนาดใหญ่',
    'ms': 'Large Besar',
    'id': 'Large Besar',
  },
  'extra_large': {
    'zh-TW': 'Extra Large 特大型',
    'en': 'Extra Large',
    'ja': 'Extra Large 特大型',
    'ko': 'Extra Large 특대형',
    'vi': 'Extra Large Cực lớn',
    'th': 'Extra Large ขนาดใหญ่พิเศษ',
    'ms': 'Extra Large Sangat Besar',
    'id': 'Extra Large Sangat Besar',
  },
};

// 「方案」翻譯
const PACKAGE_LABEL_I18N: Record<string, string> = {
  'zh-TW': '方案',
  'en': 'Package',
  'ja': 'プラン',
  'ko': '패키지',
  'vi': 'Gói',
  'th': 'แพ็คเกจ',
  'ms': 'Pakej',
  'id': 'Paket',
};

// 「小時」翻譯
const HOURS_LABEL_I18N: Record<string, string> = {
  'zh-TW': '小時',
  'en': 'hours',
  'ja': '時間',
  'ko': '시간',
  'vi': 'giờ',
  'th': 'ชั่วโมง',
  'ms': 'jam',
  'id': 'jam',
};

// 注意: features 欄位已不再使用,所有顯示內容來自 vehicle_pricing 表

/**
 * 輔助函數：從多語言 JSONB 資料中提取翻譯
 * @param i18nData - JSONB 多語言資料物件
 * @param lang - 目標語言代碼
 * @param fallback - 後備文字
 * @returns 翻譯後的文字
 */
function getTranslation(
  i18nData: Record<string, string> | null | undefined,
  lang: string,
  fallback: string
): string {
  // 如果沒有多語言資料，返回後備文字
  if (!i18nData || typeof i18nData !== 'object') {
    return fallback;
  }

  // 1. 嘗試使用請求的語言
  if (i18nData[lang]) {
    return i18nData[lang];
  }

  // 2. 後備到繁體中文（預設語言）
  if (i18nData['zh-TW']) {
    return i18nData['zh-TW'];
  }

  // 3. 返回原始後備文字
  return fallback;
}

interface VehiclePricing {
  id: string;
  vehicle_type: string;
  vehicle_description: string;
  vehicle_description_i18n?: Record<string, string>;
  capacity_info: string;
  capacity_info_i18n?: Record<string, string>;
  duration_hours: number;
  base_price: number;
  overtime_rate: number;
  is_active: boolean;
  display_order: number;
  effective_from: string;
  effective_until?: string;
  created_at: string;
  updated_at: string;
}

interface VehiclePackage {
  id: string;
  name: string;
  description: string;
  capacityInfo: string;
  duration: number;
  originalPrice: number;
  discountPrice: number;
  overtimeRate: number;
  vehicleCategory: string;
  vehicleType: string;
  features: string[];
}

/**
 * @route GET /api/pricing/packages
 * @desc 獲取所有可用的車型套餐（客戶端使用，支援多語言）
 * @query lang - 語言代碼（zh-TW, en, ja, ko, vi, th, ms, id）
 * @access Public
 */
router.get('/packages', async (req: Request, res: Response) => {
  try {
    // 獲取語言參數（從 query 或 Accept-Language header）
    const lang = (req.query.lang as string) ||
                 req.headers['accept-language']?.split(',')[0]?.split('-')[0] ||
                 'zh-TW';

    console.log(`[Pricing API] 獲取車型方案列表 (語言: ${lang})`);

    // 獲取所有啟用的價格配置
    const { data: pricingData, error } = await supabase
      .from('vehicle_pricing')
      .select('*')
      .eq('is_active', true)
      .order('display_order', { ascending: true });

    if (error) {
      console.error('[Pricing API] 查詢錯誤:', error);
      return res.status(500).json({
        success: false,
        error: '獲取價格配置失敗',
        message: error.message
      });
    }

    if (!pricingData || pricingData.length === 0) {
      return res.json({
        success: true,
        data: [],
        message: '目前沒有可用的車型方案',
        lang: lang,
      });
    }

    // 轉換為客戶端格式並應用多語言翻譯
    const packages: VehiclePackage[] = pricingData.map((pricing: VehiclePricing) => {
      const clientVehicleType = VEHICLE_TYPE_MAPPING[pricing.vehicle_type] || pricing.vehicle_type.toLowerCase();

      // 獲取翻譯後的車型顯示名稱
      const displayNameI18n = VEHICLE_DISPLAY_NAMES_I18N[clientVehicleType];
      const displayName = displayNameI18n
        ? getTranslation(displayNameI18n, lang, pricing.vehicle_description)
        : pricing.vehicle_description;

      // 獲取翻譯後的「小時」和「方案」標籤
      const hoursLabel = HOURS_LABEL_I18N[lang] || HOURS_LABEL_I18N['zh-TW'];
      const packageLabel = PACKAGE_LABEL_I18N[lang] || PACKAGE_LABEL_I18N['zh-TW'];

      // 提取翻譯後的內容
      const translatedVehicleDescription = getTranslation(
        pricing.vehicle_description_i18n,
        lang,
        pricing.vehicle_description
      );

      const translatedCapacityInfo = getTranslation(
        pricing.capacity_info_i18n,
        lang,
        pricing.capacity_info
      );

      return {
        id: pricing.id,
        name: `${displayName} ${pricing.duration_hours}${hoursLabel}${packageLabel}`,
        description: translatedVehicleDescription,
        capacityInfo: translatedCapacityInfo,
        duration: pricing.duration_hours,
        originalPrice: Number(pricing.base_price),
        discountPrice: Number(pricing.base_price), // 目前沒有折扣邏輯
        overtimeRate: Number(pricing.overtime_rate),
        vehicleCategory: clientVehicleType,
        vehicleType: pricing.vehicle_type,
        features: [], // 不再生成 features,保留欄位以維持向後兼容
      };
    });

    console.log(`[Pricing API] ✅ 成功返回 ${packages.length} 個價格方案 (語言: ${lang})`);

    return res.json({
      success: true,
      data: packages,
      lang: lang, // 返回使用的語言
    });

  } catch (error: any) {
    console.error('[Pricing API] 獲取價格配置失敗:', error);
    return res.status(500).json({
      success: false,
      error: '獲取價格配置失敗',
      message: error.message
    });
  }
});

/**
 * Middleware: 驗證 Admin 權限
 */
function requireAdmin(req: Request, res: Response, next: any) {
  const user = (req as any).user;

  if (!user) {
    return res.status(401).json({
      success: false,
      error: '未授權',
      message: '請先登入'
    });
  }

  // 檢查用戶是否有 admin 角色
  if (!user.roles || !user.roles.includes('admin')) {
    return res.status(403).json({
      success: false,
      error: '權限不足',
      message: '需要管理員權限'
    });
  }

  next();
}

/**
 * @route GET /api/pricing/admin/vehicle-pricing
 * @desc 獲取所有車型方案（包含未啟用的）- Admin 專用
 * @access Admin
 */
router.get('/admin/vehicle-pricing', requireAdmin, async (_req: Request, res: Response) => {
  try {
    const { data, error } = await supabase
      .from('vehicle_pricing')
      .select('*')
      .order('display_order', { ascending: true });

    if (error) {
      console.error('[Admin Pricing API] 查詢錯誤:', error);
      return res.status(500).json({
        success: false,
        error: '獲取價格配置失敗',
        message: error.message
      });
    }

    return res.json({
      success: true,
      data: data || [],
    });

  } catch (error: any) {
    console.error('[Admin Pricing API] 獲取價格配置失敗:', error);
    return res.status(500).json({
      success: false,
      error: '獲取價格配置失敗',
      message: error.message
    });
  }
});

/**
 * @route POST /api/pricing/admin/vehicle-pricing
 * @desc 新增車型方案 - Admin 專用（支援多語言）
 * @access Admin
 */
router.post('/admin/vehicle-pricing', requireAdmin, async (req: Request, res: Response) => {
  try {
    const {
      vehicle_type,
      vehicle_description,
      vehicle_description_i18n,
      capacity_info,
      capacity_info_i18n,
      duration_hours,
      base_price,
      overtime_rate,
      is_active,
      display_order
    } = req.body;

    // 驗證必填欄位
    if (!vehicle_type || !duration_hours || base_price === undefined || overtime_rate === undefined) {
      return res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        message: '請提供 vehicle_type, duration_hours, base_price, overtime_rate'
      });
    }

    // 插入新記錄（包含多語言欄位）
    const { data, error } = await supabase
      .from('vehicle_pricing')
      .insert([{
        vehicle_type,
        vehicle_description: vehicle_description || '',
        vehicle_description_i18n: vehicle_description_i18n || {},
        capacity_info: capacity_info || '',
        capacity_info_i18n: capacity_info_i18n || {},
        duration_hours,
        base_price,
        overtime_rate,
        is_active: is_active !== undefined ? is_active : true,
        display_order: display_order || 0,
      }])
      .select()
      .single();

    if (error) {
      console.error('[Admin Pricing API] 新增失敗:', error);
      return res.status(500).json({
        success: false,
        error: '新增車型方案失敗',
        message: error.message
      });
    }

    console.log('[Admin Pricing API] 成功新增車型方案:', data.id);

    return res.json({
      success: true,
      data: data,
      message: '新增成功'
    });

  } catch (error: any) {
    console.error('[Admin Pricing API] 新增車型方案失敗:', error);
    return res.status(500).json({
      success: false,
      error: '新增車型方案失敗',
      message: error.message
    });
  }
});

/**
 * @route PUT /api/pricing/admin/vehicle-pricing/:id
 * @desc 更新車型方案 - Admin 專用（支援多語言）
 * @access Admin
 */
router.put('/admin/vehicle-pricing/:id', requireAdmin, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      vehicle_type,
      vehicle_description,
      vehicle_description_i18n,
      capacity_info,
      capacity_info_i18n,
      duration_hours,
      base_price,
      overtime_rate,
      is_active,
      display_order
    } = req.body;

    // 構建更新物件（只更新提供的欄位）
    const updateData: any = {
      updated_at: new Date().toISOString(),
    };

    if (vehicle_type !== undefined) updateData.vehicle_type = vehicle_type;
    if (vehicle_description !== undefined) updateData.vehicle_description = vehicle_description;
    if (vehicle_description_i18n !== undefined) updateData.vehicle_description_i18n = vehicle_description_i18n;
    if (capacity_info !== undefined) updateData.capacity_info = capacity_info;
    if (capacity_info_i18n !== undefined) updateData.capacity_info_i18n = capacity_info_i18n;
    if (duration_hours !== undefined) updateData.duration_hours = duration_hours;
    if (base_price !== undefined) updateData.base_price = base_price;
    if (overtime_rate !== undefined) updateData.overtime_rate = overtime_rate;
    if (is_active !== undefined) updateData.is_active = is_active;
    if (display_order !== undefined) updateData.display_order = display_order;

    // 更新記錄
    const { data, error } = await supabase
      .from('vehicle_pricing')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[Admin Pricing API] 更新失敗:', error);
      return res.status(500).json({
        success: false,
        error: '更新車型方案失敗',
        message: error.message
      });
    }

    if (!data) {
      return res.status(404).json({
        success: false,
        error: '找不到該車型方案',
        message: `ID ${id} 不存在`
      });
    }

    console.log('[Admin Pricing API] 成功更新車型方案:', id);

    return res.json({
      success: true,
      data: data,
      message: '更新成功'
    });

  } catch (error: any) {
    console.error('[Admin Pricing API] 更新車型方案失敗:', error);
    return res.status(500).json({
      success: false,
      error: '更新車型方案失敗',
      message: error.message
    });
  }
});

/**
 * @route DELETE /api/pricing/admin/vehicle-pricing/:id
 * @desc 刪除車型方案 - Admin 專用
 * @access Admin
 */
router.delete('/admin/vehicle-pricing/:id', requireAdmin, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // 刪除記錄
    const { error } = await supabase
      .from('vehicle_pricing')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('[Admin Pricing API] 刪除失敗:', error);
      return res.status(500).json({
        success: false,
        error: '刪除車型方案失敗',
        message: error.message
      });
    }

    console.log('[Admin Pricing API] 成功刪除車型方案:', id);

    return res.json({
      success: true,
      message: '刪除成功'
    });

  } catch (error: any) {
    console.error('[Admin Pricing API] 刪除車型方案失敗:', error);
    return res.status(500).json({
      success: false,
      error: '刪除車型方案失敗',
      message: error.message
    });
  }
});

// ============================================
// 即時派車車型選項 API
// ============================================

/**
 * 地區設定已移至 shared/constants/region_settings.ts
 * 使用 REGION_SETTINGS 取代舊的 TAIWAN_REGIONS
 * 使用 determineRegionFromCoords 取代舊的 determineRegion
 * 使用 getLocalTime 取代舊的 getTaiwanTime
 */

// 向後相容：保留舊的函數名稱，內部呼叫新的實作
function determineRegion(lat: number, lng: number): string {
  return determineRegionFromCoords(lat, lng);
}

/**
 * 計算即時派車費用
 * 依據各地區計程車費率規定計算：
 * - 起程費用（依地區設定）
 * - 續程費用（每 200 公尺計費）
 * - 夜間加成（依地區設定的時段和金額）
 * - 節日加成（依地區設定的日期和金額）
 *
 * 注意：時間判斷使用上車地點座標對應的地區時區
 *
 * @param distanceKm 路程距離（公里）
 * @param durationMinutes 預估時間（分鐘）
 * @param vehicleType 車型費率設定
 * @param pickupLat 上車地點緯度
 * @param pickupLng 上車地點經度
 * @param pickupTime 上車時間（可選，預設為當前時間）
 */
function calculateInstantRideFare(
  distanceKm: number,
  durationMinutes: number,
  vehicleType: {
    base_fare: number;
    base_distance_km: number;
    fare_per_200m: number;        // 每 200 公尺費率
    fare_per_minute: number;
    night_surcharge_amount: number; // 夜間加成固定金額
    night_start_hour: number;
    night_end_hour: number;
    surge_multiplier: number;
    min_fare: number;
    spring_festival_surcharge?: number;
    spring_festival_start_date?: string;
    spring_festival_end_date?: string;
    spring_festival_enabled?: boolean;
  },
  pickupLat: number,
  pickupLng: number,
  pickupTime?: Date
): { estimatedPrice: number; isNightTime: boolean; isSpringFestival: boolean } {
  // 使用座標獲取當地時區時間（國際化支援）
  const surchargeInfo = calculateSurcharges(pickupLat, pickupLng, pickupTime);
  const regionSettings = getRegionSettings(surchargeInfo.regionCode);

  console.log(`[calculateInstantRideFare] 時間判斷 (國際化):`);
  console.log(`[calculateInstantRideFare]   座標: (${pickupLat}, ${pickupLng})`);
  console.log(`[calculateInstantRideFare]   地區: ${surchargeInfo.regionCode} (${surchargeInfo.regionName})`);
  console.log(`[calculateInstantRideFare]   時區: ${surchargeInfo.timezone}`);
  console.log(`[calculateInstantRideFare]   當地時間: ${surchargeInfo.localTimeInfo.dateString} ${surchargeInfo.localTimeInfo.hour}:00`);
  console.log(`[calculateInstantRideFare]   夜間時段: ${regionSettings.nightStartHour}:00 - ${regionSettings.nightEndHour}:00`);
  console.log(`[calculateInstantRideFare]   isNightTime: ${surchargeInfo.isNightTime}`);
  console.log(`[calculateInstantRideFare]   isSpringFestival: ${surchargeInfo.isSpringFestival}`);
  if (surchargeInfo.festivalName) {
    console.log(`[calculateInstantRideFare]   節日: ${surchargeInfo.festivalName}`);
  }

  // 使用地區設定的加成資訊
  const isNightTime = surchargeInfo.isNightTime;
  const isSpringFestival = surchargeInfo.isSpringFestival;

  // 計算基本費用（起跳價）
  let fare = vehicleType.base_fare;

  // 計算超過起跳距離的里程費（按 200 公尺為單位計費）
  if (distanceKm > vehicleType.base_distance_km) {
    const extraDistanceKm = distanceKm - vehicleType.base_distance_km;
    const extraDistanceMeters = extraDistanceKm * 1000;
    // 不足 200 公尺以 200 公尺計（無條件進位）
    const units = Math.ceil(extraDistanceMeters / 200);
    fare += units * vehicleType.fare_per_200m;
  }

  // 計算延滯計時費（車速低於 5km/h 時，每 60 秒 5 元）
  // 這裡簡化處理：假設平均時速 30km/h，超過預期時間的部分計算延滯費
  if (vehicleType.fare_per_minute > 0 && durationMinutes > 0) {
    const expectedMinutes = (distanceKm / 30) * 60;
    if (durationMinutes > expectedMinutes) {
      const delayMinutes = durationMinutes - expectedMinutes;
      fare += delayMinutes * vehicleType.fare_per_minute;
    }
  }

  // 套用夜間加成（固定金額，台北市規定 20 元）
  if (isNightTime && vehicleType.night_surcharge_amount > 0) {
    fare += vehicleType.night_surcharge_amount;
  }

  // 套用尖峰時段倍數
  if (vehicleType.surge_multiplier > 1) {
    fare *= vehicleType.surge_multiplier;
  }

  // 套用春節加成（每趟次加收固定金額，台北市規定 30 元）
  if (isSpringFestival && vehicleType.spring_festival_surcharge) {
    fare += vehicleType.spring_festival_surcharge;
  }

  // 確保不低於最低消費
  fare = Math.max(fare, vehicleType.min_fare);

  // 四捨五入到整數
  return {
    estimatedPrice: Math.round(fare),
    isNightTime,
    isSpringFestival
  };
}

/**
 * Icon 名稱到顏色的映射（用於前端顯示）
 */
const ICON_COLORS: Record<string, string> = {
  'directions_car': '#2196F3',
  'local_taxi': '#FFC107',
  'eco': '#4CAF50',
  'airport_shuttle': '#424242',
  'electric_car': '#00BCD4',
};

interface InstantRideVehicleType {
  id: string;
  vehicle_type_code: string;
  display_name_i18n: Record<string, string>;
  description_i18n: Record<string, string>;
  seat_capacity: number;
  icon_name: string;
  icon_color: string;
  country: string;
  region: string;
  base_fare: number;
  base_distance_km: number;
  fare_per_200m: number;           // 每 200 公尺費率（台北市規定 5 元）
  fare_per_minute: number;
  night_surcharge_amount: number;  // 夜間加成固定金額（台北市規定 20 元）
  night_start_hour: number;
  night_end_hour: number;
  surge_multiplier: number;
  min_fare: number;
  spring_festival_surcharge?: number;
  spring_festival_start_date?: string;
  spring_festival_end_date?: string;
  spring_festival_enabled?: boolean;
  is_active: boolean;
  display_order: number;
}

/**
 * @route GET /api/pricing/instant-ride-options
 * @desc 獲取即時派車車型選項（根據上車地點判定地區，計算各車型預估價格）
 * @query pickup_lat - 上車地點緯度（必填）
 * @query pickup_lng - 上車地點經度（必填）
 * @query dropoff_lat - 下車地點緯度（可選，用於計算預估價格）
 * @query dropoff_lng - 下車地點經度（可選）
 * @query distance_km - 行駛距離（公里，可選，如果提供則直接使用）
 * @query duration_minutes - 行駛時間（分鐘，可選）
 * @query lang - 語言代碼（zh-TW, en, ja, ko）
 * @access Public
 */
router.get('/instant-ride-options', async (req: Request, res: Response) => {
  try {
    const {
      pickup_lat,
      pickup_lng,
      distance_km,
      duration_minutes,
      lang = 'zh-TW'
    } = req.query;

    // 驗證必填參數
    if (!pickup_lat || !pickup_lng) {
      return res.status(400).json({
        success: false,
        error: '缺少必填參數',
        message: '請提供 pickup_lat 和 pickup_lng'
      });
    }

    const lat = parseFloat(pickup_lat as string);
    const lng = parseFloat(pickup_lng as string);
    const distanceKm = distance_km ? parseFloat(distance_km as string) : null;
    const durationMinutes = duration_minutes ? parseFloat(duration_minutes as string) : null;
    const language = lang as string;

    console.log(`[Instant Ride API] 獲取車型選項 (lat: ${lat}, lng: ${lng}, distance: ${distanceKm}km, lang: ${language})`);

    // 判定所屬地區
    const region = determineRegion(lat, lng);
    console.log(`[Instant Ride API] 判定地區: ${region}`);

    // 查詢該地區的所有可用車型
    const { data: vehicleTypes, error } = await supabase
      .from('instant_ride_vehicle_types')
      .select('*')
      .eq('country', 'TW')
      .eq('region', region)
      .eq('is_active', true)
      .order('display_order', { ascending: true });

    if (error) {
      console.error('[Instant Ride API] 查詢錯誤:', error);
      return res.status(500).json({
        success: false,
        error: '獲取車型選項失敗',
        message: error.message
      });
    }

    if (!vehicleTypes || vehicleTypes.length === 0) {
      // 如果該地區沒有車型，嘗試使用 taipei 作為預設
      const { data: defaultTypes, error: defaultError } = await supabase
        .from('instant_ride_vehicle_types')
        .select('*')
        .eq('country', 'TW')
        .eq('region', 'taipei')
        .eq('is_active', true)
        .order('display_order', { ascending: true });

      if (defaultError || !defaultTypes || defaultTypes.length === 0) {
        return res.json({
          success: true,
          data: {
            region: region,
            region_name: REGION_SETTINGS[region]?.name || region,
            options: []
          },
          message: '目前沒有可用的車型選項'
        });
      }

      // 使用預設車型
      vehicleTypes.push(...defaultTypes);
    }

    // 計算當前時間（用於 ETA 計算）
    const now = new Date();

    // 轉換為客戶端格式
    const options = vehicleTypes.map((vt: InstantRideVehicleType, index: number) => {
      // 獲取翻譯後的名稱和描述
      const displayName = getTranslation(vt.display_name_i18n, language, vt.vehicle_type_code);
      const description = getTranslation(vt.description_i18n, language, '');

      // 計算預估價格（如果有距離資訊）
      let estimatedPrice: number | null = null;
      let priceRange: string | null = null;
      let isNightTime = false;
      let isSpringFestival = false;

      if (distanceKm !== null) {
        // 使用上車座標計算費用（國際化：根據座標判斷時區）
        const fareResult = calculateInstantRideFare(
          distanceKm,
          durationMinutes || 0,
          {
            base_fare: Number(vt.base_fare),
            base_distance_km: Number(vt.base_distance_km),
            fare_per_200m: Number(vt.fare_per_200m) || 5,  // 每 200 公尺費率
            fare_per_minute: Number(vt.fare_per_minute),
            night_surcharge_amount: Number(vt.night_surcharge_amount) || 20,  // 夜間加成固定金額
            night_start_hour: vt.night_start_hour || 23,
            night_end_hour: vt.night_end_hour || 6,
            surge_multiplier: Number(vt.surge_multiplier) || 1,
            min_fare: Number(vt.min_fare) || 0,
            spring_festival_surcharge: vt.spring_festival_surcharge,
            spring_festival_start_date: vt.spring_festival_start_date,
            spring_festival_end_date: vt.spring_festival_end_date,
            spring_festival_enabled: vt.spring_festival_enabled
          },
          lat,   // 上車地點緯度
          lng,   // 上車地點經度
          now
        );
        estimatedPrice = fareResult.estimatedPrice;
        isNightTime = fareResult.isNightTime;
        isSpringFestival = fareResult.isSpringFestival;

        // 計程車類型顯示價格範圍
        if (vt.vehicle_type_code === 'taxi') {
          const minPrice = Math.round(estimatedPrice * 0.85);
          const maxPrice = Math.round(estimatedPrice * 1.05);
          priceRange = `${minPrice}-${maxPrice}`;
          estimatedPrice = null; // 計程車不顯示固定價格
        }
      }

      // 計算預估抵達時間（模擬：2-15 分鐘隨機）
      const etaMinutes = 2 + index * 3 + Math.floor(Math.random() * 3);
      const etaTime = new Date(now.getTime() + etaMinutes * 60 * 1000);
      const etaTimeStr = etaTime.toLocaleTimeString('zh-TW', { hour: '2-digit', minute: '2-digit', hour12: false });

      return {
        id: vt.id,
        vehicle_type_code: vt.vehicle_type_code,
        display_name: `${displayName} (${vt.seat_capacity}人座)`,
        description: description,
        icon_name: vt.icon_name,
        icon_color: vt.icon_color || ICON_COLORS[vt.icon_name] || '#2196F3',
        seat_capacity: vt.seat_capacity,
        estimated_price: estimatedPrice,
        price_range: priceRange,
        is_night_time: isNightTime,
        is_spring_festival: isSpringFestival,
        eta_minutes: etaMinutes,
        eta_time: etaTimeStr,
        // 計費參數（供前端顯示費用明細）
        pricing: {
          base_fare: Number(vt.base_fare),
          base_distance_km: Number(vt.base_distance_km),
          fare_per_200m: Number(vt.fare_per_200m) || 5,  // 每 200 公尺費率
          fare_per_minute: Number(vt.fare_per_minute),
          night_surcharge_amount: Number(vt.night_surcharge_amount) || 20,  // 夜間加成固定金額
          min_fare: Number(vt.min_fare),
          spring_festival_surcharge: vt.spring_festival_surcharge || 0,
          spring_festival_enabled: vt.spring_festival_enabled || false
        }
      };
    });

    console.log(`[Instant Ride API] ✅ 成功返回 ${options.length} 個車型選項 (地區: ${region}, 語言: ${language})`);

    return res.json({
      success: true,
      data: {
        region: region,
        region_name: REGION_SETTINGS[region]?.name || region,
        options: options
      },
      lang: language
    });

  } catch (error: any) {
    console.error('[Instant Ride API] 獲取車型選項失敗:', error);
    return res.status(500).json({
      success: false,
      error: '獲取車型選項失敗',
      message: error.message
    });
  }
});

export default router;

