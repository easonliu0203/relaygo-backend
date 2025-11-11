import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

const router = Router();

// Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

// 車型映射：資料庫車型 -> 客戶端車型
const VEHICLE_TYPE_MAPPING: Record<string, string> = {
  'A': 'small', // 3-4人座小型車
  'B': 'small', // 3-4人座小型車
  'C': 'large', // 8-9人座大型車
  'D': 'large', // 8-9人座大型車
};

// 車型顯示名稱
const VEHICLE_DISPLAY_NAMES: Record<string, string> = {
  'small': '3-4人座',
  'large': '8-9人座',
};

// 車型特色
const VEHICLE_FEATURES: Record<string, string[]> = {
  'small': [
    '專業司機服務',
    '車輛保險保障',
    '24小時客服支援',
    '3-4人座舒適空間',
    '經濟實惠',
    '適合小家庭',
  ],
  'large': [
    '專業司機服務',
    '車輛保險保障',
    '24小時客服支援',
    '8-9人座寬敞空間',
    '大型行李箱',
    '適合團體出行',
  ],
};

interface VehiclePricing {
  id: string;
  vehicle_type: string;
  duration_hours: number;
  base_price: number;
  overtime_rate: number;
  is_active: boolean;
  effective_from: string;
  effective_until?: string;
}

interface VehiclePackage {
  id: string;
  name: string;
  description: string;
  duration: number;
  originalPrice: number;
  discountPrice: number;
  overtimeRate: number;
  vehicleCategory: string;
  features: string[];
}

/**
 * @route GET /api/pricing/packages
 * @desc 獲取所有可用的車型套餐
 * @access Public
 */
router.get('/packages', async (req: Request, res: Response) => {
  try {
    let pricingData: any[] = [];
    let error: any = null;

    try {
      // 獲取所有有效的價格配置
      const result = await supabase
        .from('vehicle_pricing')
        .select('*')
        .eq('is_active', true)
        .is('effective_until', null) // 只取目前有效的價格
        .order('vehicle_type', { ascending: true })
        .order('duration_hours', { ascending: true });

      pricingData = result.data || [];
      error = result.error;

      if (error) {
        console.error('[Pricing API] Supabase 查詢錯誤:', error);
      }
    } catch (dbError) {
      console.warn('[Pricing API] 無法連接到 Supabase，使用模擬資料:', dbError);
      error = dbError;
    }

    // 如果資料庫查詢失敗或沒有資料，使用模擬資料
    if (error || !pricingData || pricingData.length === 0) {
      console.log('[Pricing API] 使用模擬價格配置資料');
      pricingData = [
        // A/B 類型：3-4人座小型車（價格較低）
        { vehicle_type: 'A', duration_hours: 6, base_price: 50, overtime_rate: 5 },
        { vehicle_type: 'A', duration_hours: 8, base_price: 60, overtime_rate: 5 },
        { vehicle_type: 'B', duration_hours: 6, base_price: 50, overtime_rate: 5 },
        { vehicle_type: 'B', duration_hours: 8, base_price: 60, overtime_rate: 5 },
        // C/D 類型：8-9人座大型車（價格較高）
        { vehicle_type: 'C', duration_hours: 6, base_price: 70, overtime_rate: 8 },
        { vehicle_type: 'C', duration_hours: 8, base_price: 85, overtime_rate: 8 },
        { vehicle_type: 'D', duration_hours: 6, base_price: 70, overtime_rate: 8 },
        { vehicle_type: 'D', duration_hours: 8, base_price: 85, overtime_rate: 8 },
      ];
    }

    if (!pricingData || pricingData.length === 0) {
      // 如果沒有價格配置，返回預設配置
      const defaultPackages = getDefaultPackages();
      return res.json({
        success: true,
        data: defaultPackages,
        source: 'default'
      });
    }

    // 轉換資料庫格式為客戶端格式，並去重
    // 使用 Map 來確保每個 (vehicleCategory, duration) 組合只出現一次
    const packagesMap = new Map<string, VehiclePackage>();

    pricingData.forEach((pricing: VehiclePricing) => {
      const clientVehicleType = VEHICLE_TYPE_MAPPING[pricing.vehicle_type];
      if (!clientVehicleType) {
        console.warn(`[Pricing API] 未知的車型: ${pricing.vehicle_type}`);
        return;
      }

      const packageKey = `${clientVehicleType}_${pricing.duration_hours}h`;

      // 如果這個組合已經存在，跳過（避免重複）
      if (packagesMap.has(packageKey)) {
        return;
      }

      const displayName = VEHICLE_DISPLAY_NAMES[clientVehicleType];
      const baseFeatures = [...VEHICLE_FEATURES[clientVehicleType]];

      // 8小時方案添加長時間優惠標籤
      const features = pricing.duration_hours >= 8
        ? [...baseFeatures, '長時間包車優惠']
        : baseFeatures;

      packagesMap.set(packageKey, {
        id: packageKey,
        name: `${displayName} ${pricing.duration_hours}小時方案`,
        description: `適合${pricing.duration_hours}小時內的${clientVehicleType === 'large' ? '大型車' : '小型車'}包車服務`,
        duration: pricing.duration_hours,
        originalPrice: pricing.base_price,
        discountPrice: pricing.base_price, // 目前沒有折扣邏輯，原價等於優惠價
        overtimeRate: pricing.overtime_rate,
        vehicleCategory: clientVehicleType,
        features: features,
      });
    });

    // 將 Map 轉換為陣列，並按車型和時長排序
    const packages = Array.from(packagesMap.values()).sort((a, b) => {
      // 先按車型排序（small 在前，large 在後）
      if (a.vehicleCategory !== b.vehicleCategory) {
        return a.vehicleCategory === 'small' ? -1 : 1;
      }
      // 再按時長排序（6小時在前，8小時在後）
      return a.duration - b.duration;
    });

    console.log(`[Pricing API] 成功返回 ${packages.length} 個價格方案`);

    res.json({
      success: true,
      data: packages,
      source: error ? 'mock' : 'database'
    });

  } catch (error: any) {
    console.error('[Pricing API] 獲取價格配置失敗:', error);
    res.status(500).json({
      success: false,
      error: '獲取價格配置失敗',
      message: error.message
    });
  }
});

// 預設套餐配置（降級使用）
function getDefaultPackages(): VehiclePackage[] {
  return [
    {
      id: 'small_6h',
      name: '3-4人座 6小時方案',
      description: '適合6小時內的小型車包車服務',
      duration: 6,
      originalPrice: 50.0,
      discountPrice: 40.0,
      overtimeRate: 5.0,
      vehicleCategory: 'small',
      features: [
        '專業司機服務',
        '車輛保險保障',
        '24小時客服支援',
        '3-4人座舒適空間',
        '經濟實惠',
        '適合小家庭',
      ],
    },
    {
      id: 'small_8h',
      name: '3-4人座 8小時方案',
      description: '適合8小時內的小型車包車服務',
      duration: 8,
      originalPrice: 60.0,
      discountPrice: 50.0,
      overtimeRate: 5.0,
      vehicleCategory: 'small',
      features: [
        '專業司機服務',
        '車輛保險保障',
        '24小時客服支援',
        '3-4人座舒適空間',
        '經濟實惠',
        '適合小家庭',
        '長時間包車優惠',
      ],
    },
    {
      id: 'large_6h',
      name: '8-9人座 6小時方案',
      description: '適合6小時內的大型車包車服務',
      duration: 6,
      originalPrice: 70.0,
      discountPrice: 60.0,
      overtimeRate: 8.0,
      vehicleCategory: 'large',
      features: [
        '專業司機服務',
        '車輛保險保障',
        '24小時客服支援',
        '8-9人座寬敞空間',
        '大型行李箱',
        '適合團體出行',
      ],
    },
    {
      id: 'large_8h',
      name: '8-9人座 8小時方案',
      description: '適合8小時內的大型車包車服務',
      duration: 8,
      originalPrice: 85.0,
      discountPrice: 75.0,
      overtimeRate: 8.0,
      vehicleCategory: 'large',
      features: [
        '專業司機服務',
        '車輛保險保障',
        '24小時客服支援',
        '8-9人座寬敞空間',
        '大型行李箱',
        '適合團體出行',
        '長時間包車優惠',
      ],
    },
  ];
}

export default router;

