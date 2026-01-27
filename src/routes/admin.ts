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

export default router;

