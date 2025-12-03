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

// 車型顯示名稱
const VEHICLE_DISPLAY_NAMES: Record<string, string> = {
  'extra_small': 'Extra Small 特小型',
  'small': 'Small 小型',
  'medium': 'Medium 中型',
  'large': 'Large 大型',
  'extra_large': 'Extra Large 特大型',
};

// 車型特色（基礎特色）
const BASE_FEATURES: string[] = [
  '專業司機服務',
  '車輛保險保障',
  '24小時客服支援',
];

interface VehiclePricing {
  id: string;
  vehicle_type: string;
  vehicle_description: string;
  capacity_info: string;
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
 * @desc 獲取所有可用的車型套餐（客戶端使用）
 * @access Public
 */
router.get('/packages', async (_req: Request, res: Response) => {
  try {
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
        message: '目前沒有可用的車型方案'
      });
    }

    // 轉換為客戶端格式
    const packages: VehiclePackage[] = pricingData.map((pricing: VehiclePricing) => {
      const clientVehicleType = VEHICLE_TYPE_MAPPING[pricing.vehicle_type] || pricing.vehicle_type.toLowerCase();
      const displayName = VEHICLE_DISPLAY_NAMES[clientVehicleType] || pricing.vehicle_description;

      // 組合特色列表
      const features = [
        ...BASE_FEATURES,
        pricing.capacity_info,
      ];

      // 8小時方案添加長時間優惠標籤
      if (pricing.duration_hours >= 8) {
        features.push('長時間包車優惠');
      }

      return {
        id: pricing.id,
        name: `${displayName} ${pricing.duration_hours}小時方案`,
        description: pricing.vehicle_description,
        capacityInfo: pricing.capacity_info,
        duration: pricing.duration_hours,
        originalPrice: Number(pricing.base_price),
        discountPrice: Number(pricing.base_price), // 目前沒有折扣邏輯
        overtimeRate: Number(pricing.overtime_rate),
        vehicleCategory: clientVehicleType,
        vehicleType: pricing.vehicle_type,
        features: features,
      };
    });

    console.log(`[Pricing API] 成功返回 ${packages.length} 個價格方案`);

    return res.json({
      success: true,
      data: packages,
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
 * @desc 新增車型方案 - Admin 專用
 * @access Admin
 */
router.post('/admin/vehicle-pricing', requireAdmin, async (req: Request, res: Response) => {
  try {
    const {
      vehicle_type,
      vehicle_description,
      capacity_info,
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

    // 插入新記錄
    const { data, error } = await supabase
      .from('vehicle_pricing')
      .insert([{
        vehicle_type,
        vehicle_description: vehicle_description || '',
        capacity_info: capacity_info || '',
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
 * @desc 更新車型方案 - Admin 專用
 * @access Admin
 */
router.put('/admin/vehicle-pricing/:id', requireAdmin, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      vehicle_type,
      vehicle_description,
      capacity_info,
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
    if (capacity_info !== undefined) updateData.capacity_info = capacity_info;
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

