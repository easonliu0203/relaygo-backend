import express, { Request, Response } from 'express';

const router = express.Router();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';

/**
 * POST /api/ai/extract-address
 * 用 Gemini Flash 從社群貼文內容擷取地址資訊
 *
 * Body: { text: string }
 * Response: { address, country, city, district } | { error }
 */
router.post('/extract-address', async (req: Request, res: Response) => {
  if (!GEMINI_API_KEY) {
    res.status(500).json({ error: 'GEMINI_API_KEY not configured' });
    return;
  }

  const { text } = req.body;
  if (!text || typeof text !== 'string') {
    res.status(400).json({ error: 'Missing text' });
    return;
  }

  try {
    const prompt = `你是地址擷取助手。從以下社群媒體貼文中提取地點資訊。

規則（按優先順序，越前面越好）：
1. 最優先：完整街道地址（含門牌號碼、路名、區域，如「東京都中央区銀座7丁目6-4」「台北市中山區民生東路一段41號」）
2. 次優先：郵遞區號 + 地址（如「〒104-0061 東京都中央区銀座7丁目」）
3. 再次：地標名稱 + 所在區域（如「Siam Paragon 4樓」「강남역 근처 역삼동」）
4. 最低：只有城市或區域名（如「東京」「曼谷」）
5. 如果完全無法判斷地點，全部回 null

address 欄位請盡可能給出最完整、可用於 Google Maps 搜尋的地址。
country 請用中文國家名（台灣、日本、韓國、泰國等）。

回傳嚴格 JSON，不要 markdown 包裹：
{"address":"最完整的地址","country":"國家","city":"城市","district":"區域"}

貼文內容：
${text.slice(0, 2000)}`;

    const apiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.1, maxOutputTokens: 200 },
        }),
        signal: AbortSignal.timeout(8000),
      }
    );

    if (!apiRes.ok) {
      const errBody = await apiRes.text();
      console.error('[AI Extract] Gemini HTTP error:', apiRes.status, errBody);
      res.status(502).json({ error: 'Gemini API error', status: apiRes.status, detail: errBody.slice(0, 200) });
      return;
    }

    const data = await apiRes.json() as Record<string, any>;
    const raw = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';

    // 從回傳中提取 JSON
    const jsonMatch = raw.match(/\{[\s\S]*?\}/);
    if (!jsonMatch) {
      console.log('[AI Extract] No JSON in response:', raw.slice(0, 200));
      res.json({ address: null, country: null, city: null, district: null });
      return;
    }

    const parsed = JSON.parse(jsonMatch[0]);
    console.log('[AI Extract] Result:', JSON.stringify(parsed));
    res.json({
      address: parsed.address || null,
      country: parsed.country || null,
      city: parsed.city || null,
      district: parsed.district || null,
    });
  } catch (e) {
    console.error('[AI Extract] Error:', e);
    res.status(500).json({ error: 'AI extraction failed' });
  }
});

export default router;
