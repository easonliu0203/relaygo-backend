/**
 * 地區設定檔 - 國際化時區和加成設定
 * 
 * 此檔案定義了各地區的時區、夜間時段、節日加成等設定
 * 用於支援多國/多地區的即時派車服務
 */

/**
 * 節日加成設定
 */
export interface FestivalSurcharge {
  name: string;           // 節日名稱
  nameEn: string;         // 英文名稱
  startDate: string;      // 開始日期 (YYYY-MM-DD)
  endDate: string;        // 結束日期 (YYYY-MM-DD)
  surcharge: number;      // 加成金額 (當地貨幣)
}

/**
 * 地區設定介面
 */
export interface RegionSettings {
  code: string;                    // 地區代碼
  name: string;                    // 地區名稱 (中文)
  nameEn: string;                  // 地區名稱 (英文)
  country: string;                 // 國家代碼 (ISO 3166-1 alpha-2)
  timezone: string;                // IANA 時區名稱
  utcOffset: number;               // UTC 偏移量 (小時，用於計算)
  currency: string;                // 貨幣代碼 (ISO 4217)
  nightStartHour: number;          // 夜間時段開始 (0-23)
  nightEndHour: number;            // 夜間時段結束 (0-23)
  nightSurcharge: number;          // 夜間加成金額 (當地貨幣)
  festivals: FestivalSurcharge[];  // 節日加成列表
  bounds: {                        // 地理邊界 (用於座標判斷)
    minLat: number;
    maxLat: number;
    minLng: number;
    maxLng: number;
  };
}

/**
 * 地區設定資料
 * 
 * 鍵值為地區代碼，與現有 TAIWAN_REGIONS 保持一致
 */
export const REGION_SETTINGS: Record<string, RegionSettings> = {
  // 台灣地區
  'taipei': {
    code: 'taipei',
    name: '北北基',
    nameEn: 'Greater Taipei',
    country: 'TW',
    timezone: 'Asia/Taipei',
    utcOffset: 8,
    currency: 'TWD',
    nightStartHour: 23,
    nightEndHour: 6,
    nightSurcharge: 20,
    festivals: [
      {
        name: '2026 農曆春節',
        nameEn: '2026 Lunar New Year',
        startDate: '2026-02-14',
        endDate: '2026-02-23',
        surcharge: 30
      }
    ],
    bounds: { minLat: 24.7, maxLat: 25.3, minLng: 121.3, maxLng: 122.0 }
  },
  'taoyuan': {
    code: 'taoyuan',
    name: '桃園',
    nameEn: 'Taoyuan',
    country: 'TW',
    timezone: 'Asia/Taipei',
    utcOffset: 8,
    currency: 'TWD',
    nightStartHour: 23,
    nightEndHour: 6,
    nightSurcharge: 20,
    festivals: [
      {
        name: '2026 農曆春節',
        nameEn: '2026 Lunar New Year',
        startDate: '2026-02-14',
        endDate: '2026-02-23',
        surcharge: 30
      }
    ],
    bounds: { minLat: 24.7, maxLat: 25.1, minLng: 120.9, maxLng: 121.4 }
  },
  'taichung': {
    code: 'taichung',
    name: '台中',
    nameEn: 'Taichung',
    country: 'TW',
    timezone: 'Asia/Taipei',
    utcOffset: 8,
    currency: 'TWD',
    nightStartHour: 23,
    nightEndHour: 6,
    nightSurcharge: 20,
    festivals: [
      {
        name: '2026 農曆春節',
        nameEn: '2026 Lunar New Year',
        startDate: '2026-02-14',
        endDate: '2026-02-23',
        surcharge: 30
      }
    ],
    bounds: { minLat: 24.0, maxLat: 24.5, minLng: 120.4, maxLng: 121.0 }
  },
  'kaohsiung': {
    code: 'kaohsiung',
    name: '高雄',
    nameEn: 'Kaohsiung',
    country: 'TW',
    timezone: 'Asia/Taipei',
    utcOffset: 8,
    currency: 'TWD',
    nightStartHour: 23,
    nightEndHour: 6,
    nightSurcharge: 20,
    festivals: [
      {
        name: '2026 農曆春節',
        nameEn: '2026 Lunar New Year',
        startDate: '2026-02-14',
        endDate: '2026-02-23',
        surcharge: 30
      }
    ],
    bounds: { minLat: 22.4, maxLat: 23.0, minLng: 120.1, maxLng: 120.8 }
  }
};

/**
 * 預設地區設定（當無法判斷地區時使用）
 */
export const DEFAULT_REGION_CODE = 'taipei';

/**
 * 根據經緯度判定所屬地區
 * @param lat 緯度
 * @param lng 經度
 * @returns 地區代碼
 */
export function determineRegionFromCoords(lat: number, lng: number): string {
  for (const [regionCode, region] of Object.entries(REGION_SETTINGS)) {
    const { bounds } = region;
    if (lat >= bounds.minLat && lat <= bounds.maxLat &&
        lng >= bounds.minLng && lng <= bounds.maxLng) {
      return regionCode;
    }
  }
  return DEFAULT_REGION_CODE;
}

/**
 * 獲取地區設定
 * @param regionCode 地區代碼
 * @returns 地區設定，若不存在則返回預設地區設定
 */
export function getRegionSettings(regionCode: string): RegionSettings {
  return REGION_SETTINGS[regionCode] || REGION_SETTINGS[DEFAULT_REGION_CODE];
}

/**
 * 地區時間資訊
 */
export interface RegionTimeInfo {
  regionCode: string;       // 地區代碼
  timezone: string;         // 時區名稱
  hour: number;             // 當地小時 (0-23)
  dateString: string;       // 當地日期 (YYYY-MM-DD)
  localTime: Date;          // 當地時間 Date 物件
}

/**
 * 根據經緯度獲取當地時間
 *
 * @param lat 緯度
 * @param lng 經度
 * @param date 可選的參考時間，預設為當前時間
 * @returns 地區時間資訊
 */
export function getLocalTime(lat: number, lng: number, date?: Date): RegionTimeInfo {
  const now = date || new Date();
  const regionCode = determineRegionFromCoords(lat, lng);
  const regionSettings = getRegionSettings(regionCode);

  // 計算當地時間
  // 1. 獲取 UTC 時間戳
  const utcTime = now.getTime() + (now.getTimezoneOffset() * 60 * 1000);
  // 2. 加上地區的 UTC 偏移量
  const localTime = new Date(utcTime + (regionSettings.utcOffset * 60 * 60 * 1000));

  const hour = localTime.getHours();
  const year = localTime.getFullYear();
  const month = String(localTime.getMonth() + 1).padStart(2, '0');
  const day = String(localTime.getDate()).padStart(2, '0');
  const dateString = `${year}-${month}-${day}`;

  // Debug 日誌
  console.log(`[getLocalTime] 座標: (${lat}, ${lng})`);
  console.log(`[getLocalTime] 地區: ${regionCode} (${regionSettings.name})`);
  console.log(`[getLocalTime] 時區: ${regionSettings.timezone} (UTC${regionSettings.utcOffset >= 0 ? '+' : ''}${regionSettings.utcOffset})`);
  console.log(`[getLocalTime] 原始時間: ${now.toISOString()}`);
  console.log(`[getLocalTime] 當地時間: ${dateString} ${String(hour).padStart(2, '0')}:${String(localTime.getMinutes()).padStart(2, '0')}`);

  return {
    regionCode,
    timezone: regionSettings.timezone,
    hour,
    dateString,
    localTime
  };
}

/**
 * 判斷是否為夜間時段
 *
 * @param hour 當地小時 (0-23)
 * @param regionSettings 地區設定
 * @returns 是否為夜間時段
 */
export function isNightTime(hour: number, regionSettings: RegionSettings): boolean {
  const { nightStartHour, nightEndHour } = regionSettings;
  // 夜間時段通常跨越午夜，例如 23:00 - 06:00
  if (nightStartHour > nightEndHour) {
    return hour >= nightStartHour || hour < nightEndHour;
  }
  // 不跨越午夜的情況（較少見）
  return hour >= nightStartHour && hour < nightEndHour;
}

/**
 * 檢查日期是否在節日期間
 *
 * @param dateString 日期字串 (YYYY-MM-DD)
 * @param regionSettings 地區設定
 * @returns 匹配的節日設定，若無則返回 null
 */
export function getActiveFestival(
  dateString: string,
  regionSettings: RegionSettings
): FestivalSurcharge | null {
  for (const festival of regionSettings.festivals) {
    if (dateString >= festival.startDate && dateString <= festival.endDate) {
      console.log(`[getActiveFestival] 節日匹配: ${festival.name} (${festival.startDate} - ${festival.endDate})`);
      return festival;
    }
  }
  return null;
}

/**
 * 計算時段加成
 *
 * @param lat 緯度
 * @param lng 經度
 * @param date 可選的參考時間
 * @returns 加成資訊
 */
export function calculateSurcharges(lat: number, lng: number, date?: Date): {
  regionCode: string;
  regionName: string;
  timezone: string;
  isNightTime: boolean;
  nightSurcharge: number;
  isSpringFestival: boolean;
  festivalSurcharge: number;
  festivalName: string | null;
  totalSurcharge: number;
  localTimeInfo: RegionTimeInfo;
} {
  const timeInfo = getLocalTime(lat, lng, date);
  const regionSettings = getRegionSettings(timeInfo.regionCode);

  const nightTime = isNightTime(timeInfo.hour, regionSettings);
  const activeFestival = getActiveFestival(timeInfo.dateString, regionSettings);

  const nightSurcharge = nightTime ? regionSettings.nightSurcharge : 0;
  const festivalSurcharge = activeFestival ? activeFestival.surcharge : 0;

  console.log(`[calculateSurcharges] 結果:`);
  console.log(`[calculateSurcharges]   夜間時段 (${regionSettings.nightStartHour}:00-${regionSettings.nightEndHour}:00): ${nightTime}`);
  console.log(`[calculateSurcharges]   夜間加成: ${nightSurcharge}`);
  console.log(`[calculateSurcharges]   節日: ${activeFestival ? activeFestival.name : '無'}`);
  console.log(`[calculateSurcharges]   節日加成: ${festivalSurcharge}`);
  console.log(`[calculateSurcharges]   總加成: ${nightSurcharge + festivalSurcharge}`);

  return {
    regionCode: timeInfo.regionCode,
    regionName: regionSettings.name,
    timezone: regionSettings.timezone,
    isNightTime: nightTime,
    nightSurcharge,
    isSpringFestival: activeFestival !== null,
    festivalSurcharge,
    festivalName: activeFestival?.name || null,
    totalSurcharge: nightSurcharge + festivalSurcharge,
    localTimeInfo: timeInfo
  };
}

