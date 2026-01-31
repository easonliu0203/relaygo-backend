import express, { Request, Response } from 'express';

const router = express.Router();

// Google API Key from environment variable
// 這個 Key 用於所有需要 HTTP 請求的 Google API（Places, Routes, Geocoding 等）
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY || process.env.GOOGLE_PLACES_API_KEY || '';

/**
 * 檢查 API Key 是否已配置
 */
function checkApiKey(res: Response, apiName: string): boolean {
  if (!GOOGLE_API_KEY) {
    console.error(`[${apiName}] ❌ GOOGLE_API_KEY not configured`);
    res.status(500).json({ error: `${apiName} not configured. Please set GOOGLE_API_KEY environment variable.` });
    return false;
  }
  return true;
}

// ============================================
// Places API (New) 端點
// ============================================

/**
 * POST /api/places/autocomplete
 * Proxy for Google Places API (New) Autocomplete
 */
router.post('/autocomplete', async (req: Request, res: Response) => {
  try {
    if (!checkApiKey(res, 'Places API')) return;

    const { input, languageCode = 'zh-TW', regionCode = 'TW', includedPrimaryTypes } = req.body;

    if (!input) {
      return res.status(400).json({ error: 'input is required' });
    }

    console.log(`[Places API] 🔍 Autocomplete: "${input}" (lang: ${languageCode})`);

    const requestBody: Record<string, unknown> = {
      input,
      languageCode,
      regionCode,
    };

    if (includedPrimaryTypes) {
      requestBody.includedPrimaryTypes = includedPrimaryTypes;
    }

    const response = await fetch('https://places.googleapis.com/v1/places:autocomplete', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GOOGLE_API_KEY,
        'X-Goog-FieldMask': 'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[Places API] ❌ Google API error: ${response.status}`, errorText);
      return res.status(response.status).json({ error: 'Google Places API error', details: errorText });
    }

    const data = await response.json() as { suggestions?: unknown[] };
    console.log(`[Places API] ✅ Found ${data.suggestions?.length || 0} suggestions`);
    return res.json(data);

  } catch (error) {
    console.error('[Places API] ❌ Error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/places/:placeId/details
 * Proxy for Google Places API (New) Place Details
 */
router.get('/:placeId/details', async (req: Request, res: Response) => {
  try {
    if (!checkApiKey(res, 'Places API')) return;

    const { placeId } = req.params;
    const { languageCode = 'zh-TW', regionCode = 'TW' } = req.query;

    if (!placeId) {
      return res.status(400).json({ error: 'placeId is required' });
    }

    console.log(`[Places API] 📍 Details: ${placeId} (lang: ${languageCode})`);

    const url = `https://places.googleapis.com/v1/places/${placeId}?languageCode=${languageCode}&regionCode=${regionCode}`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GOOGLE_API_KEY,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,shortFormattedAddress,location',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[Places API] ❌ Google API error: ${response.status}`, errorText);
      return res.status(response.status).json({ error: 'Google Places API error', details: errorText });
    }

    const data = await response.json() as { displayName?: { text?: string } };
    console.log(`[Places API] ✅ Got details for: ${data.displayName?.text || placeId}`);
    return res.json(data);

  } catch (error) {
    console.error('[Places API] ❌ Error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;

