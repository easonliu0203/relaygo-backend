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
    // 地址擷取 prompt：從社群貼文提取地點，回傳 JSON（address/country/city/district）
    // country 用中文國家名（台灣、日本、韓國…），address 盡量完整可 Google Maps 搜尋
    const prompt = `You are an address extraction assistant. Extract location info from the following social media post.

Rules (by priority, higher = better):
1. Best: Full street address with house number, road, district (e.g. "東京都中央区銀座7丁目6-4", "台北市中山區民生東路一段41號")
2. Good: Postal code + address (e.g. "〒104-0061 東京都中央区銀座7丁目")
3. OK: Landmark + area (e.g. "Siam Paragon 4F", "강남역 근처 역삼동")
4. Minimal: City or district only (e.g. "東京", "Bangkok")
5. If no location can be determined, return all fields as null

Multi-location rules (important):
- If the post covers 2+ locations (e.g. "3 must-eat ramen in Tokyo" featuring Shibuya, Shinjuku, Akasaka):
  - address = null (cannot represent all locations)
  - country and city = the common one (e.g. all in Tokyo, Japan → country=日本, city=東京)
  - district = null (spread across different districts)
- If locations span different cities (e.g. Tokyo + Osaka), city = null, only fill country

Output requirements:
- address: the most complete, Google Maps searchable address, or null
- country: Chinese country name (台灣, 日本, 韓國, 泰國, 越南, 馬來西亞, etc.)
- city/district: keep in the original language of the address

Return strict JSON only, no markdown wrapping:
{"address":"full address or null","country":"country in Chinese","city":"city or null","district":"district or null"}

Post content:
${text.slice(0, 2000)}`;

    const apiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-preview:generateContent?key=${GEMINI_API_KEY}`,
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

    // Gemini 2.5 thinking model 可能有 thoughtsText，實際回答在 text
    const parts = data?.candidates?.[0]?.content?.parts || [];
    let raw = '';
    for (const part of parts) {
      if (part.text) raw += part.text;
    }
    console.log('[AI Extract] Raw response:', raw.slice(0, 300));

    // 從回傳中提取 JSON（可能被 markdown ```json ``` 包裹）
    const jsonMatch = raw.match(/\{[\s\S]*?\}/);
    if (!jsonMatch) {
      console.log('[AI Extract] No JSON found in:', raw.slice(0, 200));
      res.json({ address: null, country: null, city: null, district: null });
      return;
    }

    const parsed = JSON.parse(jsonMatch[0]);
    console.log('[AI Extract] Parsed:', JSON.stringify(parsed));
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
