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

export default router;

