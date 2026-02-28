import dotenv from 'dotenv';

dotenv.config();

const SERPAPI_KEY = process.env.SERPAPI_KEY || '';

/**
 * SerpApi 航班查詢
 */
export async function searchFlights(params: {
  departure_id: string;   // IATA code, e.g. "TPE"
  arrival_id: string;     // IATA code, e.g. "NRT"
  outbound_date: string;  // "YYYY-MM-DD"
  return_date?: string | undefined;   // "YYYY-MM-DD"
  currency?: string | undefined;      // "TWD", "USD"
  adults?: number | undefined;
}): Promise<Record<string, unknown>> {
  if (!SERPAPI_KEY) {
    return { error: 'SERPAPI_KEY not configured' };
  }

  const query = new URLSearchParams({
    engine: 'google_flights',
    api_key: SERPAPI_KEY,
    departure_id: params.departure_id,
    arrival_id: params.arrival_id,
    outbound_date: params.outbound_date,
    currency: params.currency || 'TWD',
    hl: 'zh-TW',
    adults: String(params.adults || 1),
    type: params.return_date ? '1' : '2', // 1=round trip, 2=one way
  });

  if (params.return_date) {
    query.set('return_date', params.return_date);
  }

  console.log(`[SerpApi] ✈️ Flights: ${params.departure_id} → ${params.arrival_id} (${params.outbound_date})`);

  try {
    const response = await fetch(`https://serpapi.com/search.json?${query.toString()}`);
    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[SerpApi] ❌ Flights error: ${response.status}`, errorText);
      return { error: `SerpApi error: ${response.status}`, details: errorText };
    }

    const data = await response.json() as Record<string, unknown>;
    console.log(`[SerpApi] ✅ Flights results received`);

    // 只返回關鍵欄位給 Gemini（減少 token 消耗）
    return {
      best_flights: (data as any).best_flights || [],
      other_flights: ((data as any).other_flights || []).slice(0, 5),
      price_insights: (data as any).price_insights || null,
    };
  } catch (error) {
    console.error('[SerpApi] ❌ Flights fetch error:', error);
    return { error: 'Failed to fetch flights' };
  }
}

/**
 * SerpApi 飯店查詢
 */
export async function searchHotels(params: {
  q: string;              // 搜尋地點, e.g. "東京新宿"
  check_in_date: string;  // "YYYY-MM-DD"
  check_out_date: string; // "YYYY-MM-DD"
  currency?: string | undefined;
  adults?: number | undefined;
}): Promise<Record<string, unknown>> {
  if (!SERPAPI_KEY) {
    return { error: 'SERPAPI_KEY not configured' };
  }

  const query = new URLSearchParams({
    engine: 'google_hotels',
    api_key: SERPAPI_KEY,
    q: params.q,
    check_in_date: params.check_in_date,
    check_out_date: params.check_out_date,
    currency: params.currency || 'TWD',
    hl: 'zh-TW',
    adults: String(params.adults || 2),
  });

  console.log(`[SerpApi] 🏨 Hotels: "${params.q}" (${params.check_in_date} ~ ${params.check_out_date})`);

  try {
    const response = await fetch(`https://serpapi.com/search.json?${query.toString()}`);
    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[SerpApi] ❌ Hotels error: ${response.status}`, errorText);
      return { error: `SerpApi error: ${response.status}`, details: errorText };
    }

    const data = await response.json() as Record<string, unknown>;
    console.log(`[SerpApi] ✅ Hotels results received`);

    // 只返回關鍵欄位
    return {
      properties: ((data as any).properties || []).slice(0, 10),
      search_information: (data as any).search_information || null,
    };
  } catch (error) {
    console.error('[SerpApi] ❌ Hotels fetch error:', error);
    return { error: 'Failed to fetch hotels' };
  }
}
