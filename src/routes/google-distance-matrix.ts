import express, { Request, Response } from 'express';

const router = express.Router();

const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY || process.env.GOOGLE_PLACES_API_KEY || '';

/**
 * GET /api/distance-matrix
 * Proxy for Google Distance Matrix API
 *
 * Query params:
 *   origins    - pipe-delimited origins (e.g. "25.033,121.565|25.058,121.526")
 *   destinations - pipe-delimited destinations
 *   mode       - driving / transit / walking / bicycling (default: driving)
 *   language   - zh-TW (default)
 */
router.get('/', async (req: Request, res: Response) => {
  if (!GOOGLE_API_KEY) {
    res.status(500).json({ error: 'GOOGLE_API_KEY not configured' });
    return;
  }

  const { origins, destinations, mode = 'driving', language = 'zh-TW' } = req.query;

  if (!origins || !destinations) {
    res.status(400).json({ error: 'Missing origins or destinations' });
    return;
  }

  try {
    const url = `https://maps.googleapis.com/maps/api/distancematrix/json`
      + `?origins=${encodeURIComponent(String(origins))}`
      + `&destinations=${encodeURIComponent(String(destinations))}`
      + `&mode=${encodeURIComponent(String(mode))}`
      + `&language=${encodeURIComponent(String(language))}`
      + `&key=${GOOGLE_API_KEY}`;

    const response = await fetch(url, { signal: AbortSignal.timeout(10000) });
    const data = await response.json();

    res.json(data);
  } catch (e) {
    console.error('[DistanceMatrix] Error:', e);
    res.status(500).json({ error: 'Distance Matrix API request failed' });
  }
});

export default router;
