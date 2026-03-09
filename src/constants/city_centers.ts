/**
 * 城市中心座標（靜態維護）
 *
 * 用於計算包車旅遊的跨區費（pickup→城市 + 城市→dropoff 距離）。
 *
 * 備註：目前為後端靜態維護。
 * 若未來擴展至多國多城市（>50 個城市），建議遷移至 DB 管理。
 */

export interface CityCenter {
  lat: number;
  lng: number;
  region: 'north' | 'central' | 'south' | 'east'; // 對應 vehicle_pricing.region
}

/** 台灣各縣市中心座標 */
export const TW_CITY_CENTERS: Record<string, CityCenter> = {
  // ── 北部 ──────────────────────────────────────
  '台北': { lat: 25.0330, lng: 121.5654, region: 'north' },
  '新北': { lat: 25.0169, lng: 121.4627, region: 'north' },
  '基隆': { lat: 25.1276, lng: 121.7392, region: 'north' },
  '桃園': { lat: 24.9937, lng: 121.3010, region: 'north' },
  '新竹': { lat: 24.8138, lng: 120.9675, region: 'north' },
  '苗栗': { lat: 24.5602, lng: 120.8214, region: 'north' },

  // ── 中部 ──────────────────────────────────────
  '台中': { lat: 24.1477, lng: 120.6736, region: 'central' },
  '彰化': { lat: 24.0769, lng: 120.5333, region: 'central' },
  '南投': { lat: 23.9600, lng: 120.9718, region: 'central' },
  '雲林': { lat: 23.7092, lng: 120.4313, region: 'central' },
  '嘉義': { lat: 23.4801, lng: 120.4491, region: 'central' },

  // ── 南部 ──────────────────────────────────────
  '台南': { lat: 22.9999, lng: 120.2269, region: 'south' },
  '高雄': { lat: 22.6273, lng: 120.3014, region: 'south' },
  '屏東': { lat: 22.6761, lng: 120.4882, region: 'south' },

  // ── 東部 ──────────────────────────────────────
  '宜蘭': { lat: 24.7021, lng: 121.7378, region: 'east' },
  '花蓮': { lat: 23.9871, lng: 121.6015, region: 'east' },
  '台東': { lat: 22.7583, lng: 121.1444, region: 'east' },
};

/** 城市所屬地區對應（依縣市名稱） */
export const CITY_TO_REGION: Record<string, string> = Object.fromEntries(
  Object.entries(TW_CITY_CENTERS).map(([city, info]) => [city, info.region])
);

/**
 * Haversine 距離計算（公里）
 */
export function haversineKm(
  lat1: number, lng1: number,
  lat2: number, lng2: number
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
    Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
