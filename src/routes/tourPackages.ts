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
 * 從多語言 JSONB 欄位中提取指定語言的內容
 * @param i18nData - JSONB 多語言資料
 * @param lang - 目標語言代碼
 * @param fallback - 後備內容
 * @returns 翻譯內容或後備內容
 */
function getTranslation(i18nData: Record<string, string> | null | undefined, lang: string, fallback: string): string {
  if (!i18nData || typeof i18nData !== 'object') {
    return fallback;
  }

  // 1. 嘗試返回請求的語言
  if (i18nData[lang]) {
    return i18nData[lang];
  }

  // 2. 後備到繁體中文
  if (i18nData['zh-TW']) {
    return i18nData['zh-TW'];
  }

  // 3. 返回原始後備內容
  return fallback;
}

/**
 * @route GET /api/tour-packages
 * @desc 獲取所有旅遊方案（支援多語言）
 * @query lang - 語言代碼（zh-TW, en, ja, ko, vi, th, ms, id）
 * @access Public
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    // 獲取語言參數（從 query 或 Accept-Language header）
    const lang = (req.query.lang as string) ||
                 req.headers['accept-language']?.split(',')[0]?.split('-')[0] ||
                 'zh-TW';

    console.log(`[Tour Packages API] 獲取旅遊方案列表 (語言: ${lang})`);

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

    // 處理多語言內容
    const translatedData = data?.map((pkg: TourPackage) => ({
      ...pkg,
      // 根據語言參數提取翻譯內容
      name: getTranslation(pkg.name_i18n, lang, pkg.name),
      description: getTranslation(pkg.description_i18n, lang, pkg.description || ''),
      // 保留原始多語言資料供 Web Admin 使用
      name_i18n: pkg.name_i18n,
      description_i18n: pkg.description_i18n,
    }));

    console.log(`[Tour Packages API] ✅ 成功獲取 ${translatedData?.length || 0} 個旅遊方案 (語言: ${lang})`);

    return res.json({
      success: true,
      data: translatedData || [],
      count: translatedData?.length || 0,
      lang: lang, // 返回使用的語言
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
    const {
      name, description, name_i18n, description_i18n, is_active, display_order,
      country, region, country_i18n, region_i18n
    } = req.body;

    console.log('[Tour Packages API] 新增旅遊方案:', { name, country, region, name_i18n, description_i18n });

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
        display_order: display_order || 0,
        country: country || 'TW',
        region: region || 'taipei',
        country_i18n: country_i18n || {},
        region_i18n: region_i18n || {}
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
    const {
      name, description, name_i18n, description_i18n, is_active, display_order,
      country, region, country_i18n, region_i18n
    } = req.body;

    console.log(`[Tour Packages API] 更新旅遊方案: ${id}`, { name, country, region, name_i18n, description_i18n });

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
    // 更新國家和地區欄位
    if (country !== undefined) {
      updateData.country = country;
    }
    if (region !== undefined) {
      updateData.region = region;
    }
    if (country_i18n !== undefined) {
      updateData.country_i18n = country_i18n;
    }
    if (region_i18n !== undefined) {
      updateData.region_i18n = region_i18n;
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

