import express, { Request, Response } from 'express';

const router = express.Router();

interface FlightResult {
  airportCode: string;
  airportName: string;
  flightNo: string;
  scheduledTime: string | null;
  estimatedTime: string | null;
  terminal: string | null;
  status: string | null;
  route: string | null;
}

// 快取：3 分鐘 TTL
const cache = new Map<string, { data: FlightResult[]; ts: number }>();
const CACHE_TTL = 3 * 60 * 1000;

function getCached(key: string): FlightResult[] | null {
  const entry = cache.get(key);
  if (entry && Date.now() - entry.ts < CACHE_TTL) return entry.data;
  return null;
}

// ─── TSA 松山機場 URL ───────────────────────────────────
const TSA_URLS: Record<string, string> = {
  domestic_arrival: 'https://www.tsa.gov.tw/api/publicDataArea/GetFormaterData?id=3057d52f-7a71-49e1-a0d4-87ffa3449a6a',
  domestic_departure: 'https://www.tsa.gov.tw/api/publicDataArea/GetFormaterData?id=c0f7d5b4-ba73-46d2-8485-6595c64c4e17',
  international_arrival: 'https://www.tsa.gov.tw/api/publicDataArea/GetFormaterData?id=7dc1379a-9485-4491-866d-fc4f9590ffcf',
  international_departure: 'https://www.tsa.gov.tw/api/publicDataArea/GetFormaterData?id=42879f51-f47f-4d26-8b2b-5535c652cbde',
};

// ─── TPE 桃園機場 URL ──────────────────────────────────
const TPE_URL = 'https://odp.taoyuan-airport.com/dataset/2025102001?format=csv';

// ─── KHH 高雄機場 URL ──────────────────────────────────
const KHH_URLS: Record<string, string> = {
  domestic_arrival: 'https://www.kia.gov.tw/Announce/NewsArea/InstantSchedule_DOMARR.json',
  domestic_departure: 'https://www.kia.gov.tw/Announce/NewsArea/InstantSchedule_DOMDEP.json',
  international_arrival: 'https://www.kia.gov.tw/Announce/NewsArea/InstantSchedule_INTARR.json',
  international_departure: 'https://www.kia.gov.tw/Announce/NewsArea/InstantSchedule_INTDEP.json',
};

// ─── RMQ 台中機場 URL ──────────────────────────────────
const RMQ_URLS: Record<string, string> = {
  domestic_arrival: 'https://www.tca.gov.tw/cht/index.php?act=fids&code=domestic_a',
  domestic_departure: 'https://www.tca.gov.tw/cht/index.php?act=fids&code=domestic_l',
  international_arrival: 'https://www.tca.gov.tw/cht/index.php?act=fids&code=international_a',
  international_departure: 'https://www.tca.gov.tw/cht/index.php?act=fids&code=international_l',
};

function formatHHMM(s: string): string {
  if (!s) return '';
  const clean = s.replace(/[^0-9:]/g, '');
  if (clean.includes(':')) return clean.substring(0, 5);
  if (clean.length === 4) return `${clean.substring(0, 2)}:${clean.substring(2, 4)}`;
  return clean;
}

function str(v: unknown): string {
  return typeof v === 'string' ? v.trim() : '';
}

// ─── TSA parser ─────────────────────────────────────────
async function fetchTSA(direction: 'arrival' | 'departure'): Promise<FlightResult[]> {
  const keys = direction === 'arrival'
    ? ['domestic_arrival', 'international_arrival']
    : ['domestic_departure', 'international_departure'];

  const flights: FlightResult[] = [];
  for (const key of keys) {
    try {
      const r = await fetch(TSA_URLS[key], { signal: AbortSignal.timeout(10000) });
      if (!r.ok) continue;
      const data = await r.json() as Record<string, unknown>[];
      for (const item of data) {
        const icao = str(item.AirLineCode);
        const iata = str(item.AirLineIATA);
        const num = str(item.AirLineNum);
        if (!num) continue;
        const code = iata || icao;
        if (!code) continue;
        const scheduled = direction === 'arrival'
          ? formatHHMM(str(item.ExpectArrivalTime))
          : formatHHMM(str(item.ExpectDepartureTime));
        flights.push({
          airportCode: 'TSA', airportName: '松山',
          flightNo: `${code}${num}`,
          scheduledTime: scheduled || null,
          estimatedTime: null,
          terminal: null,
          status: str(item.AirFlyStatus) || null,
          route: str(item.UpAirportName || item.GoalAirportName) || null,
        });
      }
    } catch { /* skip */ }
  }
  return flights;
}

// ─── TPE parser (CSV) ──────────────────────────────────
function parseCsvLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') { inQuotes = !inQuotes; continue; }
    if (ch === ',' && !inQuotes) { result.push(current); current = ''; continue; }
    current += ch;
  }
  result.push(current);
  return result;
}

function findCol(headers: string[], names: string[]): number {
  return headers.findIndex(h => names.some(n => h.includes(n)));
}

async function fetchTPE(direction: 'arrival' | 'departure'): Promise<FlightResult[]> {
  try {
    const r = await fetch(TPE_URL, { signal: AbortSignal.timeout(10000) });
    if (!r.ok) return [];
    const body = await r.text();
    const lines = body.split('\n');
    if (lines.length < 2) return [];

    const headers = parseCsvLine(lines[0]);
    const dirIdx = findCol(headers, ['方向', 'Direction']);
    const codeIdx = findCol(headers, ['航空公司代碼', 'Airline Code']);
    const numIdx = findCol(headers, ['班次', 'Flight Number']);
    const schIdx = findCol(headers, ['表訂時間', 'Scheduled Time']);
    const estIdx = findCol(headers, ['預計時間', 'Estimated Time']);
    const destIdx = findCol(headers, ['往來地點中文', 'Destination Chinese']);
    const statusIdx = findCol(headers, ['航班動態中文', 'Status Chinese']);
    const termIdx = findCol(headers, ['航廈', 'Terminal']);

    if (dirIdx < 0 || codeIdx < 0 || numIdx < 0) return [];

    const dirFilter = direction === 'arrival' ? 'A' : 'D';
    const flights: FlightResult[] = [];

    for (let i = 1; i < lines.length; i++) {
      if (!lines[i].trim()) continue;
      const cols = parseCsvLine(lines[i]);
      if (cols.length <= dirIdx || cols[dirIdx].trim() !== dirFilter) continue;
      const airline = cols[codeIdx]?.trim() || '';
      const num = cols[numIdx]?.trim() || '';
      if (!airline || !num) continue;
      const sch = cols[schIdx]?.trim() || '';
      const est = cols[estIdx]?.trim() || '';
      flights.push({
        airportCode: 'TPE', airportName: '桃園',
        flightNo: `${airline}${num}`,
        scheduledTime: sch.length >= 5 ? sch.substring(0, 5) : sch || null,
        estimatedTime: est && est.length >= 5 ? est.substring(0, 5) : null,
        terminal: cols[termIdx]?.trim() || null,
        status: cols[statusIdx]?.trim() || null,
        route: cols[destIdx]?.trim() || null,
      });
    }
    return flights;
  } catch { return []; }
}

// ─── KHH parser ─────────────────────────────────────────
async function fetchKHH(direction: 'arrival' | 'departure'): Promise<FlightResult[]> {
  const keys = direction === 'arrival'
    ? ['domestic_arrival', 'international_arrival']
    : ['domestic_departure', 'international_departure'];

  const flights: FlightResult[] = [];
  for (const key of keys) {
    try {
      const r = await fetch(KHH_URLS[key], { signal: AbortSignal.timeout(10000) });
      if (!r.ok) continue;
      const data = await r.json() as Record<string, unknown>[];
      for (const item of data) {
        const icao = str(item.airLineCode || item.AirLineCode);
        const iata = str(item.airLineIATA || item.AirLineIATA);
        const num = str(item.airLineNum || item.AirLineNum);
        if (!num) continue;
        const code = iata || icao;
        if (!code) continue;
        const scheduled = formatHHMM(str(item.expectTime || item.ExpectTime));
        flights.push({
          airportCode: 'KHH', airportName: '高雄',
          flightNo: `${code}${num}`,
          scheduledTime: scheduled || null,
          estimatedTime: null,
          terminal: null,
          status: str(item.airFlyStatus || item.AirFlyStatus) || null,
          route: str(item.airRouteNameCht || item.goalAirport) || null,
        });
      }
    } catch { /* skip */ }
  }
  return flights;
}

// ─── RMQ parser ─────────────────────────────────────────
async function fetchRMQ(direction: 'arrival' | 'departure'): Promise<FlightResult[]> {
  const keys = direction === 'arrival'
    ? ['domestic_arrival', 'international_arrival']
    : ['domestic_departure', 'international_departure'];

  const flights: FlightResult[] = [];
  for (const key of keys) {
    try {
      const r = await fetch(RMQ_URLS[key], { signal: AbortSignal.timeout(10000) });
      if (!r.ok) continue;
      const decoded = await r.json();
      const data: Record<string, unknown>[] = Array.isArray(decoded)
        ? decoded
        : (decoded as Record<string, unknown>).InstantSchedule as Record<string, unknown>[] || [];
      for (const item of data) {
        const icao = str(item.airLineCode || item.AirLineCode);
        const iata = str(item.airLineIATA || item.AirLineIATA);
        const num = str(item.airLineNum || item.AirLineNum);
        if (!num) continue;
        const code = iata || icao;
        if (!code) continue;
        const timeField = direction === 'arrival'
          ? str(item.expectArrivalTime || item.ExpectArrivalTime)
          : str(item.expectDepartureTime || item.ExpectDepartureTime);
        const scheduled = formatHHMM(timeField);
        flights.push({
          airportCode: 'RMQ', airportName: '台中',
          flightNo: `${code}${num}`,
          scheduledTime: scheduled || null,
          estimatedTime: null,
          terminal: null,
          status: str(item.airFlyStatus || item.AirFlyStatus) || null,
          route: str(item.goalAirport || item.GoalAirport) || null,
        });
      }
    } catch { /* skip */ }
  }
  return flights;
}

// ══════════════════════════════════════════════════════════
// GET /api/flights/search?q=CI&direction=arrival&airport=TPE
// ══════════════════════════════════════════════════════════
router.get('/search', async (req: Request, res: Response) => {
  try {
    const query = ((req.query.q as string) || '').toUpperCase().trim();
    const direction = (req.query.direction as string) === 'departure' ? 'departure' : 'arrival';
    const airportFilter = ((req.query.airport as string) || '').toUpperCase().trim();

    if (query.length < 2) {
      return res.json({ success: true, data: [] });
    }

    const cacheKey = `${direction}_${airportFilter || 'ALL'}`;
    let allFlights = getCached(cacheKey);

    if (!allFlights) {
      // Fetch from selected airport(s) in parallel
      const fetchers: Promise<FlightResult[]>[] = [];
      if (!airportFilter || airportFilter === 'TSA') fetchers.push(fetchTSA(direction).catch(() => []));
      if (!airportFilter || airportFilter === 'TPE') fetchers.push(fetchTPE(direction).catch(() => []));
      if (!airportFilter || airportFilter === 'RMQ') fetchers.push(fetchRMQ(direction).catch(() => []));
      if (!airportFilter || airportFilter === 'KHH') fetchers.push(fetchKHH(direction).catch(() => []));

      const results = await Promise.all(fetchers);
      allFlights = results.flat().sort((a, b) => (a.scheduledTime || '').localeCompare(b.scheduledTime || ''));
      cache.set(cacheKey, { data: allFlights, ts: Date.now() });
    }

    // Filter by query (match flight number prefix)
    const filtered = allFlights
      .filter(f => f.flightNo.toUpperCase().includes(query))
      .slice(0, 20);

    return res.json({ success: true, data: filtered });
  } catch (error) {
    console.error('[Flights] ❌ Search error:', error);
    return res.status(500).json({ success: false, error: 'Flight search failed' });
  }
});

export default router;
