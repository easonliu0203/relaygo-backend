import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

const router = Router();

// Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

/**
 * 從多語言 JSONB 欄位中提取指定語言的內容
 * Fallback 順序：完全匹配 → 基礎語言匹配 → zh-TW → en → 原始 fallback
 */
function getI18nContent(
  i18nData: Record<string, string> | null | undefined,
  lang: string,
  fallback: string
): string {
  if (!i18nData || typeof i18nData !== 'object') return fallback;

  // 1. 完全匹配（如 zh-TW）
  if (i18nData[lang]) return i18nData[lang];

  // 2. 基礎語言匹配（如 zh → zh-TW）
  const baseLang = lang.split('-')[0];
  const matchKey = Object.keys(i18nData).find(k => k.startsWith(baseLang));
  if (matchKey && i18nData[matchKey]) return i18nData[matchKey];

  // 3. 預設 zh-TW
  if (i18nData['zh-TW']) return i18nData['zh-TW'];

  // 4. 預設 en
  if (i18nData['en']) return i18nData['en'];

  // 5. 原始 fallback
  return fallback;
}

/**
 * 從 request 解析語言
 */
function resolveLang(req: Request): string {
  return (
    (req.query.lang as string) ||
    req.headers['accept-language']?.split(',')[0]?.trim()?.split(';')[0] ||
    'zh-TW'
  );
}

/**
 * 生成完整 HTML 頁面（SSR）
 */
function renderHtmlPage(title: string, content: string, lang: string): string {
  const htmlLang = lang.startsWith('zh') ? 'zh-TW' : lang.split('-')[0];
  return `<!DOCTYPE html>
<html lang="${htmlLang}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="${title}">
  <title>${title} - RELAY GO</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.8;
      color: #333;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      background-color: white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 40px 20px;
      text-align: center;
      margin: -20px -20px 30px -20px;
    }
    h1 { font-size: 28px; margin-bottom: 10px; }
    h2 { color: #667eea; font-size: 22px; margin-top: 30px; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #667eea; }
    h3 { color: #764ba2; font-size: 18px; margin-top: 20px; margin-bottom: 10px; }
    p { margin-bottom: 15px; text-align: justify; }
    ul, ol { margin-left: 25px; margin-bottom: 15px; }
    li { margin-bottom: 8px; }
    .highlight { background-color: #FFF9C4; padding: 15px; border-left: 4px solid #FFC107; margin: 20px 0; }
    .warning { background-color: #FFEBEE; padding: 15px; border-left: 4px solid #F44336; margin: 20px 0; }
    .contact-info { background-color: #E8EAF6; padding: 20px; border-radius: 8px; margin-top: 30px; }
    footer { text-align: center; padding: 20px; margin-top: 40px; border-top: 1px solid #ddd; color: #666; font-size: 14px; }
    @media (max-width: 600px) {
      .container { padding: 15px; }
      header { padding: 30px 15px; margin: -15px -15px 20px -15px; }
      h1 { font-size: 24px; }
      h2 { font-size: 20px; }
      h3 { font-size: 16px; }
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>${title}</h1>
    </header>
    <div class="content">
      ${content}
    </div>
    <footer>
      <p>&copy; ${new Date().getFullYear()} RELAY GO. All rights reserved.</p>
    </footer>
  </div>
</body>
</html>`;
}

// ============================================
// GET /api/legal/documents
// 列出所有啟用的法律文件（可依 role 篩選）
// ============================================
router.get('/documents', async (req: Request, res: Response) => {
  try {
    const lang = resolveLang(req);
    const role = req.query.role as string | undefined;

    console.log(`[Legal API] 列出文件 (lang: ${lang}, role: ${role || 'all'})`);

    let query = supabase
      .from('legal_documents')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true });

    if (role) {
      query = query.or(`role.eq.${role},role.eq.all`);
    }

    const { data, error } = await query;

    if (error) {
      console.error('[Legal API] Supabase 查詢錯誤:', error);
      return res.status(500).json({
        success: false,
        error: '查詢法律文件失敗',
        details: error.message,
      });
    }

    const translated = data?.map((doc: any) => ({
      id: doc.id,
      doc_key: doc.doc_key,
      role: doc.role,
      title: getI18nContent(doc.title_i18n, lang, doc.title),
      version: doc.version,
      sort_order: doc.sort_order,
      updated_at: doc.updated_at,
    }));

    return res.json({
      success: true,
      data: translated || [],
      count: translated?.length || 0,
      lang,
    });
  } catch (error) {
    console.error('[Legal API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤',
    });
  }
});

// ============================================
// GET /api/legal/documents/by-id/:id
// 以 UUID 查詢單一文件（必須在 :docKey 路由之前宣告）
// ============================================
router.get('/documents/by-id/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const lang = resolveLang(req);

    console.log(`[Legal API] 查詢文件 by-id: ${id} (lang: ${lang})`);

    const { data, error } = await supabase
      .from('legal_documents')
      .select('*')
      .eq('id', id)
      .eq('is_active', true)
      .single();

    if (error || !data) {
      return res.status(404).json({
        success: false,
        error: '文件不存在',
      });
    }

    return res.json({
      success: true,
      data: {
        id: data.id,
        doc_key: data.doc_key,
        role: data.role,
        title: getI18nContent(data.title_i18n, lang, data.title),
        content: getI18nContent(data.content_i18n, lang, data.content),
        version: data.version,
        updated_at: data.updated_at,
      },
      lang,
    });
  } catch (error) {
    console.error('[Legal API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤',
    });
  }
});

// ============================================
// GET /api/legal/documents/:docKey
// 以 doc_key 查詢單一文件（支援 format=json|html）
// ============================================
router.get('/documents/:docKey', async (req: Request, res: Response) => {
  try {
    const { docKey } = req.params;
    const lang = resolveLang(req);
    const format = (req.query.format as string) || 'json';

    console.log(`[Legal API] 查詢文件: ${docKey} (lang: ${lang}, format: ${format})`);

    const { data, error } = await supabase
      .from('legal_documents')
      .select('*')
      .eq('doc_key', docKey)
      .eq('is_active', true)
      .single();

    if (error || !data) {
      if (format === 'html') {
        return res.status(404).type('html').send(
          renderHtmlPage('Document Not Found', '<p>The requested document was not found.</p>', lang)
        );
      }
      return res.status(404).json({
        success: false,
        error: '文件不存在',
      });
    }

    const title = getI18nContent(data.title_i18n, lang, data.title);
    const content = getI18nContent(data.content_i18n, lang, data.content);

    if (format === 'html') {
      res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
      return res.type('html').send(renderHtmlPage(title, content, lang));
    }

    return res.json({
      success: true,
      data: {
        id: data.id,
        doc_key: data.doc_key,
        role: data.role,
        title,
        content,
        version: data.version,
        updated_at: data.updated_at,
      },
      lang,
    });
  } catch (error) {
    console.error('[Legal API] 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '內部伺服器錯誤',
      details: error instanceof Error ? error.message : '未知錯誤',
    });
  }
});

export default router;
