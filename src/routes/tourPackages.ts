import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

const router = Router();

// Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

interface TourPackage {
  id: string;
  name: string;
  description: string;
  name_i18n?: Record<string, string>;
  description_i18n?: Record<string, string>;
  is_active: boolean;
  display_order: number;
  created_at: string;
  updated_at: string;
}

/**
 * @route GET /api/tour-packages
 * @desc 獲取所有旅遊方案（包含停用的）
 * @access Public
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    console.log('[Tour Packages API] 獲取旅遊方案列表');

    // 獲取所有旅遊方案（包含停用的，讓 Web Admin 可以管理）
    const { data, error } = await supabase
      .from('tour_packages')
      .select('*')
      .order('display_order', { ascending: true });

    if (error) {
      console.error('[Tour Packages API] Supabase 查詢錯誤:', error);
      return res.status(500).json({
        success: false,
        error: '查詢旅遊方案失敗',
        details: error.message
      });
    }

    console.log(`[Tour Packages API] ✅ 成功獲取 ${data?.length || 0} 個旅遊方案`);

    return res.json({
      success: true,
      data: data || [],
      count: data?.length || 0
    });

  } catch (error) {
    console.error('[Tour Packages API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route GET /api/tour-packages/:id
 * @desc 獲取單一旅遊方案
 * @access Public
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    console.log(`[Tour Packages API] 獲取旅遊方案: ${id}`);

    const { data, error } = await supabase
      .from('tour_packages')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      console.error('[Tour Packages API] Supabase 查詢錯誤:', error);
      return res.status(404).json({
        success: false,
        error: '旅遊方案不存在',
        details: error.message
      });
    }

    console.log(`[Tour Packages API] ✅ 成功獲取旅遊方案: ${data.name}`);

    return res.json({
      success: true,
      data: data
    });

  } catch (error) {
    console.error('[Tour Packages API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route POST /api/tour-packages
 * @desc 新增旅遊方案
 * @access Admin
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const { name, description, name_i18n, description_i18n, is_active, display_order } = req.body;

    console.log('[Tour Packages API] 新增旅遊方案:', { name, description, name_i18n, description_i18n });

    // 驗證必填欄位
    if (!name) {
      return res.status(400).json({
        success: false,
        error: '方案名稱為必填欄位'
      });
    }

    const { data, error } = await supabase
      .from('tour_packages')
      .insert([{
        name,
        description: description || '',
        name_i18n: name_i18n || {},
        description_i18n: description_i18n || {},
        is_active: is_active !== undefined ? is_active : true,
        display_order: display_order || 0
      }])
      .select()
      .single();

    if (error) {
      console.error('[Tour Packages API] 新增失敗:', error);
      return res.status(500).json({
        success: false,
        error: '新增旅遊方案失敗',
        details: error.message
      });
    }

    console.log(`[Tour Packages API] ✅ 成功新增旅遊方案: ${data.name}`);

    return res.status(201).json({
      success: true,
      data: data
    });

  } catch (error) {
    console.error('[Tour Packages API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route PUT /api/tour-packages/:id
 * @desc 更新旅遊方案
 * @access Admin
 */
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { name, description, name_i18n, description_i18n, is_active, display_order } = req.body;

    console.log(`[Tour Packages API] 更新旅遊方案: ${id}`, { name, description, name_i18n, description_i18n });

    // 驗證必填欄位
    if (!name) {
      return res.status(400).json({
        success: false,
        error: '方案名稱為必填欄位'
      });
    }

    // 構建更新物件
    const updateData: any = {
      name,
      description: description || '',
      is_active: is_active !== undefined ? is_active : true,
      display_order: display_order !== undefined ? display_order : 0
    };

    // 只在提供了多語言資料時才更新
    if (name_i18n !== undefined) {
      updateData.name_i18n = name_i18n;
    }
    if (description_i18n !== undefined) {
      updateData.description_i18n = description_i18n;
    }

    const { data, error } = await supabase
      .from('tour_packages')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      console.error('[Tour Packages API] 更新失敗:', error);
      return res.status(500).json({
        success: false,
        error: '更新旅遊方案失敗',
        details: error.message
      });
    }

    console.log(`[Tour Packages API] ✅ 成功更新旅遊方案: ${data.name}`);

    return res.json({
      success: true,
      data: data
    });

  } catch (error) {
    console.error('[Tour Packages API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

/**
 * @route DELETE /api/tour-packages/:id
 * @desc 刪除旅遊方案
 * @access Admin
 */
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    console.log(`[Tour Packages API] 刪除旅遊方案: ${id}`);

    const { error } = await supabase
      .from('tour_packages')
      .delete()
      .eq('id', id);

    if (error) {
      console.error('[Tour Packages API] 刪除失敗:', error);
      return res.status(500).json({
        success: false,
        error: '刪除旅遊方案失敗',
        details: error.message
      });
    }

    console.log(`[Tour Packages API] ✅ 成功刪除旅遊方案: ${id}`);

    return res.json({
      success: true,
      message: '旅遊方案已刪除'
    });

  } catch (error) {
    console.error('[Tour Packages API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤'
    });
  }
});

export default router;

