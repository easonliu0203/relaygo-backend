import express, { Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

// 初始化 Supabase 客戶端
const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const supabase = createClient(supabaseUrl, supabaseServiceKey);

/**
 * @route GET /api/admin/revenue-share-settings
 * @desc 獲取分潤設定
 * @access Admin
 */
router.get('/revenue-share-settings', async (req: Request, res: Response): Promise<void> => {
  try {
    console.log('[Admin API] 獲取分潤設定');

    // 獲取兩個場景的設定
    const { data, error } = await supabase
      .from('system_settings')
      .select('key, value, description, updated_at')
      .in('key', ['revenue_share_no_promo', 'revenue_share_with_promo']);

    if (error) {
      console.error('[Admin API] 獲取分潤設定失敗:', error);
      res.status(500).json({
        success: false,
        error: '獲取分潤設定失敗',
        details: error.message
      });
      return;
    }

    // 轉換為物件格式
    const settings: any = {};
    data?.forEach((item: any) => {
      settings[item.key] = {
        ...item.value,
        description: item.description,
        updated_at: item.updated_at
      };
    });

    res.json({
      success: true,
      data: settings,
      message: '獲取分潤設定成功'
    });
  } catch (error: any) {
    console.error('[Admin API] 獲取分潤設定錯誤:', error);
    res.status(500).json({
      success: false,
      error: '獲取分潤設定失敗',
      details: error.message
    });
  }
});

/**
 * @route PUT /api/admin/revenue-share-settings
 * @desc 更新分潤設定
 * @access Admin
 */
router.put('/revenue-share-settings', async (req: Request, res: Response): Promise<void> => {
  try {
    const { scenario, company_percentage, driver_percentage, company_base_percentage } = req.body;

    console.log('[Admin API] 更新分潤設定:', {
      scenario,
      company_percentage,
      driver_percentage,
      company_base_percentage
    });

    // 驗證輸入
    if (!scenario || (scenario !== 'no_promo' && scenario !== 'with_promo')) {
      res.status(400).json({
        success: false,
        error: '無效的場景類型，必須是 no_promo 或 with_promo'
      });
      return;
    }

    // 根據場景類型設定 key 和 value
    let key: string;
    let value: any;

    if (scenario === 'no_promo') {
      // 場景 1：未使用優惠碼
      if (company_percentage === undefined || driver_percentage === undefined) {
        res.status(400).json({
          success: false,
          error: '場景 1 需要提供 company_percentage 和 driver_percentage'
        });
        return;
      }

      // 驗證百分比總和為 100
      if (company_percentage + driver_percentage !== 100) {
        res.status(400).json({
          success: false,
          error: '公司和司機的百分比總和必須為 100'
        });
        return;
      }

      key = 'revenue_share_no_promo';
      value = {
        company_percentage,
        driver_percentage,
        updated_at: new Date().toISOString(),
        updated_by: req.body.user_id || 'admin'
      };
    } else {
      // 場景 2：使用優惠碼
      if (company_base_percentage === undefined || driver_percentage === undefined) {
        res.status(400).json({
          success: false,
          error: '場景 2 需要提供 company_base_percentage 和 driver_percentage'
        });
        return;
      }

      // 驗證百分比總和為 100
      if (company_base_percentage + driver_percentage !== 100) {
        res.status(400).json({
          success: false,
          error: '公司基準和司機的百分比總和必須為 100'
        });
        return;
      }

      key = 'revenue_share_with_promo';
      value = {
        company_base_percentage,
        driver_percentage,
        updated_at: new Date().toISOString(),
        updated_by: req.body.user_id || 'admin'
      };
    }

    // 更新設定
    const { error } = await supabase
      .from('system_settings')
      .update({
        value,
        updated_at: new Date().toISOString()
      })
      .eq('key', key);

    if (error) {
      console.error('[Admin API] 更新分潤設定失敗:', error);
      res.status(500).json({
        success: false,
        error: '更新分潤設定失敗',
        details: error.message
      });
      return;
    }

    res.json({
      success: true,
      data: { key, value },
      message: '分潤設定更新成功'
    });
  } catch (error: any) {
    console.error('[Admin API] 更新分潤設定錯誤:', error);
    res.status(500).json({
      success: false,
      error: '更新分潤設定失敗',
      details: error.message
    });
  }
});

/**
 * @route GET /api/admin/revenue-share-configs
 * @desc 獲取所有分潤配置 (支援篩選)
 * @access Admin
 */
router.get('/revenue-share-configs', async (req: Request, res: Response): Promise<void> => {
  try {
    const { country, region, service_type, has_promo_code, is_active } = req.query;

    console.log('[Admin API] 獲取分潤配置列表:', { country, region, service_type, has_promo_code, is_active });

    let query = supabase
      .from('revenue_share_configs')
      .select('*')
      .order('priority', { ascending: false })
      .order('created_at', { ascending: false });

    // 應用篩選條件
    if (country) query = query.eq('country', country);
    if (region) query = query.eq('region', region);
    if (service_type) query = query.eq('service_type', service_type);
    if (has_promo_code !== undefined) query = query.eq('has_promo_code', has_promo_code === 'true');
    if (is_active !== undefined) query = query.eq('is_active', is_active === 'true');

    const { data, error } = await query;

    if (error) {
      console.error('[Admin API] 獲取分潤配置失敗:', error);
      res.status(500).json({
        success: false,
        error: '獲取分潤配置失敗',
        details: error.message
      });
      return;
    }

    res.json({
      success: true,
      data: data || [],
      count: data?.length || 0,
      message: '獲取分潤配置成功'
    });
  } catch (error: any) {
    console.error('[Admin API] 獲取分潤配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '獲取分潤配置失敗',
      details: error.message
    });
  }
});

/**
 * @route GET /api/admin/revenue-share-configs/:id
 * @desc 獲取單個分潤配置
 * @access Admin
 */
router.get('/revenue-share-configs/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    console.log('[Admin API] 獲取分潤配置:', id);

    const { data, error } = await supabase
      .from('revenue_share_configs')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      console.error('[Admin API] 獲取分潤配置失敗:', error);
      res.status(404).json({
        success: false,
        error: '找不到該分潤配置',
        details: error.message
      });
      return;
    }

    res.json({
      success: true,
      data,
      message: '獲取分潤配置成功'
    });
  } catch (error: any) {
    console.error('[Admin API] 獲取分潤配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '獲取分潤配置失敗',
      details: error.message
    });
  }
});

/**
 * @route POST /api/admin/revenue-share-configs
 * @desc 創建新的分潤配置
 * @access Admin
 */
router.post('/revenue-share-configs', async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      country,
      region,
      service_type,
      has_promo_code,
      company_percentage,
      driver_percentage,
      company_base_percentage,
      description,
      priority,
      created_by
    } = req.body;

    console.log('[Admin API] 創建分潤配置:', req.body);

    // 驗證必填欄位
    if (!country || !service_type || has_promo_code === undefined) {
      res.status(400).json({
        success: false,
        error: '缺少必填欄位: country, service_type, has_promo_code'
      });
      return;
    }

    if (company_percentage === undefined || driver_percentage === undefined) {
      res.status(400).json({
        success: false,
        error: '缺少必填欄位: company_percentage, driver_percentage'
      });
      return;
    }

    // 驗證百分比總和為 100
    if (company_percentage + driver_percentage !== 100) {
      res.status(400).json({
        success: false,
        error: '公司和司機的百分比總和必須為 100'
      });
      return;
    }

    // 驗證百分比範圍
    if (company_percentage < 0 || company_percentage > 100 || driver_percentage < 0 || driver_percentage > 100) {
      res.status(400).json({
        success: false,
        error: '百分比必須在 0-100 之間'
      });
      return;
    }

    // 插入新配置
    const { data, error } = await supabase
      .from('revenue_share_configs')
      .insert({
        country,
        region: region || null,
        service_type,
        has_promo_code,
        company_percentage,
        driver_percentage,
        company_base_percentage: has_promo_code ? (company_base_percentage || company_percentage) : null,
        description,
        priority: priority || 0,
        is_active: true,
        created_by,
        updated_by: created_by
      })
      .select()
      .single();

    if (error) {
      console.error('[Admin API] 創建分潤配置失敗:', error);
      res.status(500).json({
        success: false,
        error: '創建分潤配置失敗',
        details: error.message
      });
      return;
    }

    res.status(201).json({
      success: true,
      data,
      message: '分潤配置創建成功'
    });
  } catch (error: any) {
    console.error('[Admin API] 創建分潤配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '創建分潤配置失敗',
      details: error.message
    });
  }
});

/**
 * @route PUT /api/admin/revenue-share-configs/:id
 * @desc 更新分潤配置
 * @access Admin
 */
router.put('/revenue-share-configs/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const {
      country,
      region,
      service_type,
      has_promo_code,
      company_percentage,
      driver_percentage,
      company_base_percentage,
      description,
      priority,
      is_active,
      updated_by
    } = req.body;

    console.log('[Admin API] 更新分潤配置:', id, req.body);

    // 驗證百分比總和為 100 (如果提供了百分比)
    if (company_percentage !== undefined && driver_percentage !== undefined) {
      if (company_percentage + driver_percentage !== 100) {
        res.status(400).json({
          success: false,
          error: '公司和司機的百分比總和必須為 100'
        });
        return;
      }

      // 驗證百分比範圍
      if (company_percentage < 0 || company_percentage > 100 || driver_percentage < 0 || driver_percentage > 100) {
        res.status(400).json({
          success: false,
          error: '百分比必須在 0-100 之間'
        });
        return;
      }
    }

    // 構建更新物件 (只更新提供的欄位)
    const updateData: any = {
      updated_at: new Date().toISOString(),
      updated_by
    };

    if (country !== undefined) updateData.country = country;
    if (region !== undefined) updateData.region = region || null;
    if (service_type !== undefined) updateData.service_type = service_type;
    if (has_promo_code !== undefined) updateData.has_promo_code = has_promo_code;
    if (company_percentage !== undefined) updateData.company_percentage = company_percentage;
    if (driver_percentage !== undefined) updateData.driver_percentage = driver_percentage;
    if (company_base_percentage !== undefined) updateData.company_base_percentage = company_base_percentage;
    if (description !== undefined) updateData.description = description;
    if (priority !== undefined) updateData.priority = priority;
    if (is_active !== undefined) updateData.is_active = is_active;

    // 更新配置
    const { data, error } = await supabase
      .from('revenue_share_configs')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[Admin API] 更新分潤配置失敗:', error);
      res.status(500).json({
        success: false,
        error: '更新分潤配置失敗',
        details: error.message
      });
      return;
    }

    res.json({
      success: true,
      data,
      message: '分潤配置更新成功'
    });
  } catch (error: any) {
    console.error('[Admin API] 更新分潤配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '更新分潤配置失敗',
      details: error.message
    });
  }
});

/**
 * @route DELETE /api/admin/revenue-share-configs/:id
 * @desc 刪除分潤配置 (軟刪除 - 設為 is_active = false)
 * @access Admin
 */
router.delete('/revenue-share-configs/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { updated_by } = req.body;

    console.log('[Admin API] 刪除分潤配置:', id);

    // 軟刪除 (設為 is_active = false)
    const { data, error } = await supabase
      .from('revenue_share_configs')
      .update({
        is_active: false,
        updated_at: new Date().toISOString(),
        updated_by
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[Admin API] 刪除分潤配置失敗:', error);
      res.status(500).json({
        success: false,
        error: '刪除分潤配置失敗',
        details: error.message
      });
      return;
    }

    res.json({
      success: true,
      data,
      message: '分潤配置已停用'
    });
  } catch (error: any) {
    console.error('[Admin API] 刪除分潤配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '刪除分潤配置失敗',
      details: error.message
    });
  }
});

/**
 * @route POST /api/admin/revenue-share-configs/query
 * @desc 查詢最佳匹配的分潤配置 (用於訂單計算)
 * @access Admin/System
 */
router.post('/revenue-share-configs/query', async (req: Request, res: Response): Promise<void> => {
  try {
    const { country, region, service_type, has_promo_code } = req.body;

    console.log('[Admin API] 查詢分潤配置:', { country, region, service_type, has_promo_code });

    // 驗證必填欄位
    if (!country || !service_type || has_promo_code === undefined) {
      res.status(400).json({
        success: false,
        error: '缺少必填欄位: country, service_type, has_promo_code'
      });
      return;
    }

    // 使用資料庫函數查詢最佳匹配
    const { data, error } = await supabase
      .rpc('get_revenue_share_config', {
        p_country: country,
        p_region: region || null,
        p_service_type: service_type,
        p_has_promo_code: has_promo_code
      });

    if (error) {
      console.error('[Admin API] 查詢分潤配置失敗:', error);

      // 如果找不到配置，回退到 system_settings
      console.log('[Admin API] 回退到 system_settings 全局配置');
      const settingKey = has_promo_code ? 'revenue_share_with_promo' : 'revenue_share_no_promo';

      const { data: settingData, error: settingError } = await supabase
        .from('system_settings')
        .select('value')
        .eq('key', settingKey)
        .single();

      if (settingError || !settingData) {
        // 使用硬編碼預設值
        const defaultConfig = has_promo_code
          ? { company_percentage: 30, driver_percentage: 70, company_base_percentage: 30 }
          : { company_percentage: 25, driver_percentage: 75 };

        res.json({
          success: true,
          data: defaultConfig,
          source: 'default',
          message: '使用預設分潤配置'
        });
        return;
      }

      res.json({
        success: true,
        data: settingData.value,
        source: 'system_settings',
        message: '使用全局分潤配置'
      });
      return;
    }

    if (!data || data.length === 0) {
      // 回退到 system_settings
      console.log('[Admin API] 未找到匹配配置，回退到 system_settings');
      const settingKey = has_promo_code ? 'revenue_share_with_promo' : 'revenue_share_no_promo';

      const { data: settingData, error: settingError } = await supabase
        .from('system_settings')
        .select('value')
        .eq('key', settingKey)
        .single();

      if (settingError || !settingData) {
        const defaultConfig = has_promo_code
          ? { company_percentage: 30, driver_percentage: 70, company_base_percentage: 30 }
          : { company_percentage: 25, driver_percentage: 75 };

        res.json({
          success: true,
          data: defaultConfig,
          source: 'default',
          message: '使用預設分潤配置'
        });
        return;
      }

      res.json({
        success: true,
        data: settingData.value,
        source: 'system_settings',
        message: '使用全局分潤配置'
      });
      return;
    }

    res.json({
      success: true,
      data: data[0],
      source: 'revenue_share_configs',
      message: '查詢分潤配置成功'
    });
  } catch (error: any) {
    console.error('[Admin API] 查詢分潤配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '查詢分潤配置失敗',
      details: error.message
    });
  }
});

// ========== 即時派車價格配置 API ==========

/**
 * @route GET /api/admin/instant-ride-pricing
 * @desc 獲取即時派車價格配置列表 (支援篩選)
 * @access Admin
 */
router.get('/instant-ride-pricing', async (req: Request, res: Response): Promise<void> => {
  try {
    const { country, region, vehicle_type_code, is_active } = req.query;

    console.log('[Admin API] 獲取即時派車價格配置:', { country, region, vehicle_type_code, is_active });

    let query = supabase
      .from('instant_ride_vehicle_types')
      .select('*')
      .order('country', { ascending: true })
      .order('region', { ascending: true })
      .order('display_order', { ascending: true });

    // 篩選條件
    if (country) {
      query = query.eq('country', country);
    }
    if (region) {
      query = query.eq('region', region);
    }
    if (vehicle_type_code) {
      query = query.eq('vehicle_type_code', vehicle_type_code);
    }
    if (is_active !== undefined) {
      query = query.eq('is_active', is_active === 'true');
    }

    const { data, error } = await query;

    if (error) {
      console.error('[Admin API] 查詢即時派車價格配置錯誤:', error);
      res.status(500).json({
        success: false,
        error: '查詢即時派車價格配置失敗',
        details: error.message
      });
      return;
    }

    res.json({
      success: true,
      data: data || [],
      count: data?.length || 0
    });
  } catch (error: any) {
    console.error('[Admin API] 獲取即時派車價格配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '獲取即時派車價格配置失敗',
      details: error.message
    });
  }
});

/**
 * @route GET /api/admin/instant-ride-pricing/:id
 * @desc 獲取單個即時派車價格配置
 * @access Admin
 */
router.get('/instant-ride-pricing/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    console.log('[Admin API] 獲取即時派車價格配置:', id);

    const { data, error } = await supabase
      .from('instant_ride_vehicle_types')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      console.error('[Admin API] 查詢即時派車價格配置錯誤:', error);
      res.status(404).json({
        success: false,
        error: '找不到該配置',
        details: error.message
      });
      return;
    }

    res.json({
      success: true,
      data
    });
  } catch (error: any) {
    console.error('[Admin API] 獲取即時派車價格配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '獲取即時派車價格配置失敗',
      details: error.message
    });
  }
});

/**
 * @route POST /api/admin/instant-ride-pricing
 * @desc 創建新的即時派車價格配置
 * @access Admin
 */
router.post('/instant-ride-pricing', async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      vehicle_type_code,
      display_name_i18n,
      description_i18n,
      seat_capacity,
      icon_name,
      icon_color,
      country,
      region,
      base_fare,
      base_distance_km,
      fare_per_km,
      fare_per_minute,
      night_surcharge_rate,
      night_start_hour,
      night_end_hour,
      surge_multiplier,
      min_fare,
      display_order,
      is_active,
      created_by
    } = req.body;

    console.log('[Admin API] 創建即時派車價格配置:', { vehicle_type_code, country, region });

    // 驗證必填欄位
    if (!vehicle_type_code || !country || !region) {
      res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: 'vehicle_type_code, country, region 為必填'
      });
      return;
    }

    const { data, error } = await supabase
      .from('instant_ride_vehicle_types')
      .insert({
        vehicle_type_code,
        display_name_i18n: display_name_i18n || {},
        description_i18n: description_i18n || {},
        seat_capacity: seat_capacity || 4,
        icon_name: icon_name || 'directions_car',
        icon_color: icon_color || '#2196F3',
        country,
        region,
        base_fare: base_fare || 85,
        base_distance_km: base_distance_km || 1.25,
        fare_per_km: fare_per_km || 25,
        fare_per_minute: fare_per_minute || 5,
        night_surcharge_rate: night_surcharge_rate || 0.2,
        night_start_hour: night_start_hour || 23,
        night_end_hour: night_end_hour || 6,
        surge_multiplier: surge_multiplier || 1.0,
        min_fare: min_fare || 0,
        display_order: display_order || 0,
        is_active: is_active !== false,
        created_by: created_by || 'admin',
        updated_by: created_by || 'admin'
      })
      .select()
      .single();

    if (error) {
      console.error('[Admin API] 創建即時派車價格配置錯誤:', error);
      res.status(500).json({
        success: false,
        error: '創建即時派車價格配置失敗',
        details: error.message
      });
      return;
    }

    res.status(201).json({
      success: true,
      data,
      message: '即時派車價格配置創建成功'
    });
  } catch (error: any) {
    console.error('[Admin API] 創建即時派車價格配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '創建即時派車價格配置失敗',
      details: error.message
    });
  }
});

/**
 * @route PUT /api/admin/instant-ride-pricing/:id
 * @desc 更新即時派車價格配置
 * @access Admin
 */
router.put('/instant-ride-pricing/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const {
      vehicle_type_code,
      display_name_i18n,
      description_i18n,
      seat_capacity,
      icon_name,
      icon_color,
      country,
      region,
      base_fare,
      base_distance_km,
      fare_per_km,
      fare_per_minute,
      night_surcharge_rate,
      night_start_hour,
      night_end_hour,
      surge_multiplier,
      min_fare,
      display_order,
      is_active,
      updated_by
    } = req.body;

    console.log('[Admin API] 更新即時派車價格配置:', { id, vehicle_type_code, country, region });

    // 構建更新物件，只包含有值的欄位
    const updateData: Record<string, any> = {
      updated_at: new Date().toISOString(),
      updated_by: updated_by || 'admin'
    };

    if (vehicle_type_code !== undefined) updateData.vehicle_type_code = vehicle_type_code;
    if (display_name_i18n !== undefined) updateData.display_name_i18n = display_name_i18n;
    if (description_i18n !== undefined) updateData.description_i18n = description_i18n;
    if (seat_capacity !== undefined) updateData.seat_capacity = seat_capacity;
    if (icon_name !== undefined) updateData.icon_name = icon_name;
    if (icon_color !== undefined) updateData.icon_color = icon_color;
    if (country !== undefined) updateData.country = country;
    if (region !== undefined) updateData.region = region;
    if (base_fare !== undefined) updateData.base_fare = base_fare;
    if (base_distance_km !== undefined) updateData.base_distance_km = base_distance_km;
    if (fare_per_km !== undefined) updateData.fare_per_km = fare_per_km;
    if (fare_per_minute !== undefined) updateData.fare_per_minute = fare_per_minute;
    if (night_surcharge_rate !== undefined) updateData.night_surcharge_rate = night_surcharge_rate;
    if (night_start_hour !== undefined) updateData.night_start_hour = night_start_hour;
    if (night_end_hour !== undefined) updateData.night_end_hour = night_end_hour;
    if (surge_multiplier !== undefined) updateData.surge_multiplier = surge_multiplier;
    if (min_fare !== undefined) updateData.min_fare = min_fare;
    if (display_order !== undefined) updateData.display_order = display_order;
    if (is_active !== undefined) updateData.is_active = is_active;

    const { data, error } = await supabase
      .from('instant_ride_vehicle_types')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[Admin API] 更新即時派車價格配置錯誤:', error);
      res.status(500).json({
        success: false,
        error: '更新即時派車價格配置失敗',
        details: error.message
      });
      return;
    }

    res.json({
      success: true,
      data,
      message: '即時派車價格配置更新成功'
    });
  } catch (error: any) {
    console.error('[Admin API] 更新即時派車價格配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '更新即時派車價格配置失敗',
      details: error.message
    });
  }
});

/**
 * @route POST /api/admin/instant-ride-pricing/batch
 * @desc 批量更新即時派車價格配置
 * @access Admin
 */
router.post('/instant-ride-pricing/batch', async (req: Request, res: Response): Promise<void> => {
  try {
    const { updates, updated_by } = req.body;

    console.log('[Admin API] 批量更新即時派車價格配置:', { count: updates?.length });

    if (!Array.isArray(updates) || updates.length === 0) {
      res.status(400).json({
        success: false,
        error: '缺少更新資料',
        details: 'updates 必須是非空陣列'
      });
      return;
    }

    const results: any[] = [];
    const errors: any[] = [];

    for (const update of updates) {
      const { id, ...updateFields } = update;

      if (!id) {
        errors.push({ error: '缺少 id', update });
        continue;
      }

      const updateData: Record<string, any> = {
        ...updateFields,
        updated_at: new Date().toISOString(),
        updated_by: updated_by || 'admin'
      };

      const { data, error } = await supabase
        .from('instant_ride_vehicle_types')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

      if (error) {
        errors.push({ id, error: error.message });
      } else {
        results.push(data);
      }
    }

    res.json({
      success: errors.length === 0,
      data: results,
      errors: errors.length > 0 ? errors : undefined,
      message: `成功更新 ${results.length} 筆，失敗 ${errors.length} 筆`
    });
  } catch (error: any) {
    console.error('[Admin API] 批量更新即時派車價格配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '批量更新即時派車價格配置失敗',
      details: error.message
    });
  }
});

/**
 * @route POST /api/admin/instant-ride-pricing/copy
 * @desc 複製其他地區的價格配置到目標地區
 * @access Admin
 */
router.post('/instant-ride-pricing/copy', async (req: Request, res: Response): Promise<void> => {
  try {
    const { source_country, source_region, target_country, target_region, created_by } = req.body;

    console.log('[Admin API] 複製即時派車價格配置:', {
      source: `${source_country}/${source_region}`,
      target: `${target_country}/${target_region}`
    });

    if (!source_country || !source_region || !target_country || !target_region) {
      res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: 'source_country, source_region, target_country, target_region 為必填'
      });
      return;
    }

    // 獲取來源配置
    const { data: sourceConfigs, error: sourceError } = await supabase
      .from('instant_ride_vehicle_types')
      .select('*')
      .eq('country', source_country)
      .eq('region', source_region);

    if (sourceError || !sourceConfigs || sourceConfigs.length === 0) {
      res.status(404).json({
        success: false,
        error: '找不到來源配置',
        details: sourceError?.message || '來源地區沒有配置'
      });
      return;
    }

    // 創建目標配置
    const newConfigs = sourceConfigs.map(config => ({
      vehicle_type_code: config.vehicle_type_code,
      display_name_i18n: config.display_name_i18n,
      description_i18n: config.description_i18n,
      seat_capacity: config.seat_capacity,
      icon_name: config.icon_name,
      icon_color: config.icon_color,
      country: target_country,
      region: target_region,
      base_fare: config.base_fare,
      base_distance_km: config.base_distance_km,
      fare_per_km: config.fare_per_km,
      fare_per_minute: config.fare_per_minute,
      night_surcharge_rate: config.night_surcharge_rate,
      night_start_hour: config.night_start_hour,
      night_end_hour: config.night_end_hour,
      surge_multiplier: config.surge_multiplier,
      min_fare: config.min_fare,
      display_order: config.display_order,
      is_active: true,
      created_by: created_by || 'admin',
      updated_by: created_by || 'admin'
    }));

    const { data, error } = await supabase
      .from('instant_ride_vehicle_types')
      .insert(newConfigs)
      .select();

    if (error) {
      console.error('[Admin API] 複製即時派車價格配置錯誤:', error);
      res.status(500).json({
        success: false,
        error: '複製即時派車價格配置失敗',
        details: error.message
      });
      return;
    }

    res.status(201).json({
      success: true,
      data,
      message: `成功複製 ${data?.length || 0} 筆配置`
    });
  } catch (error: any) {
    console.error('[Admin API] 複製即時派車價格配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '複製即時派車價格配置失敗',
      details: error.message
    });
  }
});

/**
 * @route DELETE /api/admin/instant-ride-pricing/:id
 * @desc 刪除即時派車價格配置 (軟刪除)
 * @access Admin
 */
router.delete('/instant-ride-pricing/:id', async (req: Request, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { updated_by } = req.body;

    console.log('[Admin API] 刪除即時派車價格配置:', id);

    const { data, error } = await supabase
      .from('instant_ride_vehicle_types')
      .update({
        is_active: false,
        updated_at: new Date().toISOString(),
        updated_by: updated_by || 'admin'
      })
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[Admin API] 刪除即時派車價格配置錯誤:', error);
      res.status(500).json({
        success: false,
        error: '刪除即時派車價格配置失敗',
        details: error.message
      });
      return;
    }

    res.json({
      success: true,
      data,
      message: '即時派車價格配置已停用'
    });
  } catch (error: any) {
    console.error('[Admin API] 刪除即時派車價格配置錯誤:', error);
    res.status(500).json({
      success: false,
      error: '刪除即時派車價格配置失敗',
      details: error.message
    });
  }
});

/**
 * @route POST /api/admin/instant-ride-pricing/preview
 * @desc 預覽價格計算結果
 * @access Admin
 */
router.post('/instant-ride-pricing/preview', async (req: Request, res: Response): Promise<void> => {
  try {
    const { config_id, distance_km, duration_minutes, is_night_time } = req.body;

    console.log('[Admin API] 預覽價格計算:', { config_id, distance_km, duration_minutes, is_night_time });

    if (!config_id || distance_km === undefined) {
      res.status(400).json({
        success: false,
        error: '缺少必填欄位',
        details: 'config_id, distance_km 為必填'
      });
      return;
    }

    // 獲取配置
    const { data: config, error } = await supabase
      .from('instant_ride_vehicle_types')
      .select('*')
      .eq('id', config_id)
      .single();

    if (error || !config) {
      res.status(404).json({
        success: false,
        error: '找不到該配置',
        details: error?.message
      });
      return;
    }

    // 計算價格
    let price = config.base_fare;

    // 超過基本里程的部分
    if (distance_km > config.base_distance_km) {
      price += (distance_km - config.base_distance_km) * config.fare_per_km;
    }

    // 時間費用
    if (duration_minutes && config.fare_per_minute > 0) {
      price += duration_minutes * config.fare_per_minute;
    }

    // 夜間加成
    let nightSurcharge = 0;
    if (is_night_time && config.night_surcharge_rate > 0) {
      nightSurcharge = price * config.night_surcharge_rate;
      price += nightSurcharge;
    }

    // 尖峰時段倍數
    if (config.surge_multiplier > 1) {
      price *= config.surge_multiplier;
    }

    // 最低車資
    if (config.min_fare > 0 && price < config.min_fare) {
      price = config.min_fare;
    }

    res.json({
      success: true,
      data: {
        config_id,
        vehicle_type_code: config.vehicle_type_code,
        distance_km,
        duration_minutes,
        is_night_time,
        breakdown: {
          base_fare: config.base_fare,
          distance_fare: distance_km > config.base_distance_km
            ? (distance_km - config.base_distance_km) * config.fare_per_km
            : 0,
          time_fare: duration_minutes ? duration_minutes * config.fare_per_minute : 0,
          night_surcharge: nightSurcharge,
          surge_multiplier: config.surge_multiplier
        },
        estimated_price: Math.round(price),
        min_fare: config.min_fare
      }
    });
  } catch (error: any) {
    console.error('[Admin API] 預覽價格計算錯誤:', error);
    res.status(500).json({
      success: false,
      error: '預覽價格計算失敗',
      details: error.message
    });
  }
});

export default router;

