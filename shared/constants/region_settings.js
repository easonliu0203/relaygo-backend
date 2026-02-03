"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_REGION_CODE = exports.REGION_SETTINGS = void 0;
exports.determineRegionFromCoords = determineRegionFromCoords;
exports.getRegionSettings = getRegionSettings;
exports.getLocalTime = getLocalTime;
exports.isNightTime = isNightTime;
exports.getActiveFestival = getActiveFestival;
exports.calculateSurcharges = calculateSurcharges;
exports.REGION_SETTINGS = {
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
exports.DEFAULT_REGION_CODE = 'taipei';
function determineRegionFromCoords(lat, lng) {
    for (const [regionCode, region] of Object.entries(exports.REGION_SETTINGS)) {
        const { bounds } = region;
        if (lat >= bounds.minLat && lat <= bounds.maxLat &&
            lng >= bounds.minLng && lng <= bounds.maxLng) {
            return regionCode;
        }
    }
    return exports.DEFAULT_REGION_CODE;
}
function getRegionSettings(regionCode) {
    return exports.REGION_SETTINGS[regionCode] || exports.REGION_SETTINGS[exports.DEFAULT_REGION_CODE];
}
function getLocalTime(lat, lng, date) {
    const now = date || new Date();
    const regionCode = determineRegionFromCoords(lat, lng);
    const regionSettings = getRegionSettings(regionCode);
    const utcTime = now.getTime() + (now.getTimezoneOffset() * 60 * 1000);
    const localTime = new Date(utcTime + (regionSettings.utcOffset * 60 * 60 * 1000));
    const hour = localTime.getHours();
    const year = localTime.getFullYear();
    const month = String(localTime.getMonth() + 1).padStart(2, '0');
    const day = String(localTime.getDate()).padStart(2, '0');
    const dateString = `${year}-${month}-${day}`;
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
function isNightTime(hour, regionSettings) {
    const { nightStartHour, nightEndHour } = regionSettings;
    if (nightStartHour > nightEndHour) {
        return hour >= nightStartHour || hour < nightEndHour;
    }
    return hour >= nightStartHour && hour < nightEndHour;
}
function getActiveFestival(dateString, regionSettings) {
    for (const festival of regionSettings.festivals) {
        if (dateString >= festival.startDate && dateString <= festival.endDate) {
            console.log(`[getActiveFestival] 節日匹配: ${festival.name} (${festival.startDate} - ${festival.endDate})`);
            return festival;
        }
    }
    return null;
}
function calculateSurcharges(lat, lng, date) {
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
//# sourceMappingURL=region_settings.js.map