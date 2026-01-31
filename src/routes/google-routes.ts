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
// Routes API 端點
// https://developers.google.com/maps/documentation/routes
// ============================================

/**
 * POST /api/routes/directions
 * Proxy for Google Routes API - Compute Routes
 * 計算兩點之間的路線
 */
router.post('/directions', async (req: Request, res: Response) => {
  try {
    if (!checkApiKey(res, 'Routes API')) return;

    const { origin, destination, travelMode = 'DRIVE', languageCode = 'zh-TW' } = req.body;

    if (!origin || !destination) {
      return res.status(400).json({ error: 'origin and destination are required' });
    }

    console.log(`[Routes API] 🚗 Computing route: ${JSON.stringify(origin)} → ${JSON.stringify(destination)}`);

    const requestBody = {
      origin: typeof origin === 'string' ? { address: origin } : { location: { latLng: origin } },
      destination: typeof destination === 'string' ? { address: destination } : { location: { latLng: destination } },
      travelMode,
      languageCode,
      routingPreference: 'TRAFFIC_AWARE',
      computeAlternativeRoutes: false,
      routeModifiers: {
        avoidTolls: false,
        avoidHighways: false,
        avoidFerries: false,
      },
    };

    const response = await fetch('https://routes.googleapis.com/directions/v2:computeRoutes', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GOOGLE_API_KEY,
        'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[Routes API] ❌ Google API error: ${response.status}`, errorText);
      return res.status(response.status).json({ error: 'Google Routes API error', details: errorText });
    }

    const data = await response.json() as { routes?: unknown[] };
    console.log(`[Routes API] ✅ Found ${data.routes?.length || 0} routes`);
    return res.json(data);

  } catch (error) {
    console.error('[Routes API] ❌ Error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/routes/matrix
 * Proxy for Google Routes API - Compute Route Matrix
 * 計算多個起點到多個終點的距離矩陣
 */
router.post('/matrix', async (req: Request, res: Response) => {
  try {
    if (!checkApiKey(res, 'Routes API')) return;

    const { origins, destinations, travelMode = 'DRIVE' } = req.body;

    if (!origins || !destinations || !Array.isArray(origins) || !Array.isArray(destinations)) {
      return res.status(400).json({ error: 'origins and destinations arrays are required' });
    }

    console.log(`[Routes API] 📊 Computing matrix: ${origins.length} origins × ${destinations.length} destinations`);

    const requestBody = {
      origins: origins.map((o: { latitude: number; longitude: number } | string) => 
        typeof o === 'string' ? { waypoint: { address: o } } : { waypoint: { location: { latLng: o } } }
      ),
      destinations: destinations.map((d: { latitude: number; longitude: number } | string) => 
        typeof d === 'string' ? { waypoint: { address: d } } : { waypoint: { location: { latLng: d } } }
      ),
      travelMode,
      routingPreference: 'TRAFFIC_AWARE',
    };

    const response = await fetch('https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': GOOGLE_API_KEY,
        'X-Goog-FieldMask': 'originIndex,destinationIndex,duration,distanceMeters,status,condition',
      },
      body: JSON.stringify(requestBody),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[Routes API] ❌ Google API error: ${response.status}`, errorText);
      return res.status(response.status).json({ error: 'Google Routes API error', details: errorText });
    }

    const data = await response.json();
    console.log(`[Routes API] ✅ Matrix computed successfully`);
    return res.json(data);

  } catch (error) {
    console.error('[Routes API] ❌ Error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;

