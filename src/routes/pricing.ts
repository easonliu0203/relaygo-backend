import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

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

export default router;

