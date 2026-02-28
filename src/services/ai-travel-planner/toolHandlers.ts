import dotenv from 'dotenv';
import { searchFlights, searchHotels } from './serpApiService';

dotenv.config();

const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY || process.env.GOOGLE_PLACES_API_KEY || '';

// ============================================
// Google Maps API 內部呼叫（複用現有路由邏輯）
// ============================================

async function handleSearchPlaces(args: Record<string, unknown>): Promise<unknown> {
  const input = args.query as string;
  const languageCode = (args.languageCode as string) || 'zh-TW';
  const regionCode = (args.regionCode as string) || 'TW';
  const includedPrimaryTypes = args.includedPrimaryTypes as string[] | undefined;

  console.log(`[ToolHandler] 🔍 searchPlaces: "${input}"`);

  const requestBody: Record<string, unknown> = { input, languageCode, regionCode };
  if (includedPrimaryTypes) requestBody.includedPrimaryTypes = includedPrimaryTypes;

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
    return { error: `Places API error: ${response.status}` };
  }
  return response.json();
}

async function handleGetPlaceDetails(args: Record<string, unknown>): Promise<unknown> {
  const placeId = args.placeId as string;
  const languageCode = (args.languageCode as string) || 'zh-TW';

  console.log(`[ToolHandler] 📍 getPlaceDetails: ${placeId}`);

  const response = await fetch(
    `https://places.googleapis.com/v1/places/${placeId}?languageCode=${languageCode}`,
    {
      headers: {
        'X-Goog-Api-Key': GOOGLE_API_KEY,
        'X-Goog-FieldMask': 'id,displayName,formattedAddress,location,rating,userRatingCount,types,regularOpeningHours,editorialSummary,photos',
      },
    }
  );

  if (!response.ok) {
    return { error: `Places API error: ${response.status}` };
  }
  return response.json();
}

async function handleGetRouteDirections(args: Record<string, unknown>): Promise<unknown> {
  const origin = args.origin as string;
  const destination = args.destination as string;
  const travelMode = (args.travelMode as string) || 'DRIVE';
  const languageCode = (args.languageCode as string) || 'zh-TW';

  console.log(`[ToolHandler] 🚗 getRouteDirections: ${origin} → ${destination}`);

  const requestBody = {
    origin: { address: origin },
    destination: { address: destination },
    travelMode,
    languageCode,
    routingPreference: travelMode === 'DRIVE' ? 'TRAFFIC_AWARE' : undefined,
    computeAlternativeRoutes: false,
  };

  const response = await fetch('https://routes.googleapis.com/directions/v2:computeRoutes', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': GOOGLE_API_KEY,
      'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.legs.duration,routes.legs.distanceMeters',
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    return { error: `Routes API error: ${response.status}` };
  }
  return response.json();
}

async function handleGetDistanceMatrix(args: Record<string, unknown>): Promise<unknown> {
  const origins = args.origins as string[];
  const destinations = args.destinations as string[];
  const travelMode = (args.travelMode as string) || 'DRIVE';

  console.log(`[ToolHandler] 📊 getDistanceMatrix: ${origins.length} × ${destinations.length}`);

  const requestBody = {
    origins: origins.map(o => ({ waypoint: { address: o } })),
    destinations: destinations.map(d => ({ waypoint: { address: d } })),
    travelMode,
    routingPreference: travelMode === 'DRIVE' ? 'TRAFFIC_AWARE' : undefined,
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
    return { error: `Routes Matrix API error: ${response.status}` };
  }
  return response.json();
}

async function handleGetTimeZone(args: Record<string, unknown>): Promise<unknown> {
  const latitude = args.latitude as number;
  const longitude = args.longitude as number;
  const timestamp = Math.floor(Date.now() / 1000);

  console.log(`[ToolHandler] 🕐 getTimeZone: ${latitude}, ${longitude}`);

  const url = `https://maps.googleapis.com/maps/api/timezone/json?location=${latitude},${longitude}&timestamp=${timestamp}&key=${GOOGLE_API_KEY}`;
  const response = await fetch(url);

  if (!response.ok) {
    return { error: `TimeZone API error: ${response.status}` };
  }
  return response.json();
}

async function handleSearchFlights(args: Record<string, unknown>): Promise<unknown> {
  return searchFlights({
    departure_id: args.departure_id as string,
    arrival_id: args.arrival_id as string,
    outbound_date: args.outbound_date as string,
    return_date: args.return_date as string | undefined,
    currency: args.currency as string | undefined,
    adults: args.adults as number | undefined,
  });
}

async function handleSearchHotels(args: Record<string, unknown>): Promise<unknown> {
  return searchHotels({
    q: args.q as string,
    check_in_date: args.check_in_date as string,
    check_out_date: args.check_out_date as string,
    currency: args.currency as string | undefined,
    adults: args.adults as number | undefined,
  });
}

// ============================================
// 統一分派入口
// ============================================

export async function executeTool(
  functionName: string,
  args: Record<string, unknown>
): Promise<unknown> {
  console.log(`[ToolHandler] 🔧 Executing: ${functionName}`);

  switch (functionName) {
    case 'searchPlaces':
      return handleSearchPlaces(args);
    case 'getPlaceDetails':
      return handleGetPlaceDetails(args);
    case 'getRouteDirections':
      return handleGetRouteDirections(args);
    case 'getDistanceMatrix':
      return handleGetDistanceMatrix(args);
    case 'getTimeZone':
      return handleGetTimeZone(args);
    case 'searchFlights':
      return handleSearchFlights(args);
    case 'searchHotels':
      return handleSearchHotels(args);
    default:
      return { error: `Unknown tool: ${functionName}` };
  }
}
