export interface FestivalSurcharge {
    name: string;
    nameEn: string;
    startDate: string;
    endDate: string;
    surcharge: number;
}
export interface RegionSettings {
    code: string;
    name: string;
    nameEn: string;
    country: string;
    timezone: string;
    utcOffset: number;
    currency: string;
    nightStartHour: number;
    nightEndHour: number;
    nightSurcharge: number;
    festivals: FestivalSurcharge[];
    bounds: {
        minLat: number;
        maxLat: number;
        minLng: number;
        maxLng: number;
    };
}
export declare const REGION_SETTINGS: Record<string, RegionSettings>;
export declare const DEFAULT_REGION_CODE = "taipei";
export declare function determineRegionFromCoords(lat: number, lng: number): string;
export declare function getRegionSettings(regionCode: string): RegionSettings;
export interface RegionTimeInfo {
    regionCode: string;
    timezone: string;
    hour: number;
    dateString: string;
    localTime: Date;
}
export declare function getLocalTime(lat: number, lng: number, date?: Date): RegionTimeInfo;
export declare function isNightTime(hour: number, regionSettings: RegionSettings): boolean;
export declare function getActiveFestival(dateString: string, regionSettings: RegionSettings): FestivalSurcharge | null;
export declare function calculateSurcharges(lat: number, lng: number, date?: Date): {
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
};
//# sourceMappingURL=region_settings.d.ts.map