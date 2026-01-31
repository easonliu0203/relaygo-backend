import express, { Request, Response } from 'express';

const router = express.Router();

// Google API Key from environment variable
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
// Geocoding API 端點
// https://developers.google.com/maps/documentation/geocoding
// ============================================

/**
 * GET /api/geocoding/address
 * Proxy for Google Geocoding API - Address to Coordinates
 * 地址轉經緯度
 */
router.get('/address', async (req: Request, res: Response) => {
  try {
    if (!checkApiKey(res, 'Geocoding API')) return;

    const { address, language = 'zh-TW', region = 'TW' } = req.query;

    if (!address) {
      return res.status(400).json({ error: 'address is required' });
    }

    console.log(`[Geocoding API] 📍 Geocoding address: "${address}"`);

    const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
    url.searchParams.set('address', address as string);
    url.searchParams.set('key', GOOGLE_API_KEY);
    url.searchParams.set('language', language as string);
    url.searchParams.set('region', region as string);

    const response = await fetch(url.toString());

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[Geocoding API] ❌ Google API error: ${response.status}`, errorText);
      return res.status(response.status).json({ error: 'Google Geocoding API error', details: errorText });
    }

    const data = await response.json() as { results?: unknown[]; status?: string };
    console.log(`[Geocoding API] ✅ Found ${data.results?.length || 0} results (status: ${data.status})`);
    return res.json(data);

  } catch (error) {
    console.error('[Geocoding API] ❌ Error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/geocoding/latlng
 * Proxy for Google Geocoding API - Coordinates to Address (Reverse Geocoding)
 * 經緯度轉地址
 */
router.get('/latlng', async (req: Request, res: Response) => {
  try {
    if (!checkApiKey(res, 'Geocoding API')) return;

    const { lat, lng, language = 'zh-TW' } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'lat and lng are required' });
    }

    console.log(`[Geocoding API] 📍 Reverse geocoding: (${lat}, ${lng})`);

    const url = new URL('https://maps.googleapis.com/maps/api/geocode/json');
    url.searchParams.set('latlng', `${lat},${lng}`);
    url.searchParams.set('key', GOOGLE_API_KEY);
    url.searchParams.set('language', language as string);

    const response = await fetch(url.toString());

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[Geocoding API] ❌ Google API error: ${response.status}`, errorText);
      return res.status(response.status).json({ error: 'Google Geocoding API error', details: errorText });
    }

    const data = await response.json() as { results?: unknown[]; status?: string };
    console.log(`[Geocoding API] ✅ Found ${data.results?.length || 0} results (status: ${data.status})`);
    return res.json(data);

  } catch (error) {
    console.error('[Geocoding API] ❌ Error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;

