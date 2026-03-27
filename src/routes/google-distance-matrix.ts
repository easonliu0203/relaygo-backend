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

/**
 * GET /api/distance-matrix/directions
 * Proxy for Google Directions API (origin → destination only, supports transit)
 *
 * Query params:
 *   origin      - e.g. "25.033,121.565"
 *   destination - e.g. "25.058,121.526"
 *   mode        - driving / transit / walking (default: driving)
 *   language    - zh-TW (default)
 */
router.get('/directions', async (req: Request, res: Response) => {
  if (!GOOGLE_API_KEY) {
    res.status(500).json({ error: 'GOOGLE_API_KEY not configured' });
    return;
  }

  const { origin, destination, mode = 'driving', language = 'zh-TW' } = req.query;

  if (!origin || !destination) {
    res.status(400).json({ error: 'Missing origin or destination' });
    return;
  }

  try {
    const url = `https://maps.googleapis.com/maps/api/directions/json`
      + `?origin=${encodeURIComponent(String(origin))}`
      + `&destination=${encodeURIComponent(String(destination))}`
      + `&mode=${encodeURIComponent(String(mode))}`
      + `&language=${encodeURIComponent(String(language))}`
      + `&key=${GOOGLE_API_KEY}`;

    const response = await fetch(url, { signal: AbortSignal.timeout(10000) });
    const data = await response.json();

    // 簡化回傳：只回傳 duration + distance
    if (data.status === 'OK' && data.routes?.[0]?.legs?.[0]) {
      const leg = data.routes[0].legs[0];
      res.json({
        status: 'OK',
        duration: leg.duration,   // { text: "2 小時 48 分", value: 10080 }
        distance: leg.distance,   // { text: "95.2 公里", value: 95200 }
      });
    } else {
      res.json({ status: data.status || 'UNKNOWN', error_message: data.error_message });
    }
  } catch (e) {
    console.error('[Directions] Error:', e);
    res.status(500).json({ error: 'Directions API request failed' });
  }
});

export default router;
