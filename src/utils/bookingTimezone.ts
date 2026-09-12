/**
 * 訂單時區與聊天室開放時間（2026-09-12）
 *
 * bookings.start_date + start_time 是「目的地當地時間」（欄位本身沒有時區），
 * 例如預約台灣 2026-09-15 10:00 上車，存的就是 2026-09-15 / 10:00:00。
 *
 * 時區從上下車地點判斷：上車座標 → 下車座標 → 機場代碼 → bookings.country → 預設台灣。
 *
 * 司機與客戶的聊天室：
 * - 上車前 24 小時開放（chat_rooms.chatOpensAt，由這裡算好寫入）
 * - 訂單完成（尾款付完）或取消後關閉（Firestore rules 與 App 讀 orders_rt.status 判斷）
 */

/** 聊天室在上車前多久開放 */
export const CHAT_OPENS_BEFORE_PICKUP_MS = 24 * 60 * 60 * 1000;

const DEFAULT_TIMEZONE = 'Asia/Taipei';

/** 服務國家的範圍（依座標判斷時區；新增服務國家時加一行） */
const DESTINATION_AREAS = [
  // 台灣本島、澎湖、金門、馬祖、蘭嶼
  { country: 'TW', minLat: 21.8, maxLat: 26.4, minLng: 118.1, maxLng: 122.1 },
];

/** 國家代碼 → 時區 */
const COUNTRY_TIMEZONES: Record<string, string> = {
  TW: 'Asia/Taipei',
  JP: 'Asia/Tokyo',
  KR: 'Asia/Seoul',
  HK: 'Asia/Hong_Kong',
  MO: 'Asia/Macau',
  TH: 'Asia/Bangkok',
  VN: 'Asia/Ho_Chi_Minh',
  MY: 'Asia/Kuala_Lumpur',
  SG: 'Asia/Singapore',
  PH: 'Asia/Manila',
};

/** 機場代碼 → 國家（機場接送的機場那一端沒有座標） */
const AIRPORT_COUNTRIES: Record<string, string> = {
  TPE: 'TW', TSA: 'TW', RMQ: 'TW', KHH: 'TW', TNN: 'TW',
  HUN: 'TW', TTT: 'TW', KNH: 'TW', MZG: 'TW', LZN: 'TW',
};

/** 判斷時區需要的訂單欄位（Supabase numeric 可能是數字或字串） */
export interface BookingTimeFields {
  start_date?: string | null;
  start_time?: string | null;
  pickup_latitude?: number | string | null;
  pickup_longitude?: number | string | null;
  dropoff_latitude?: number | string | null;
  dropoff_longitude?: number | string | null;
  pickup_airport_code?: string | null;
  dropoff_airport_code?: string | null;
  country?: string | null;
}

export interface ChatWindow {
  /** 上車時間（真正的時間點） */
  pickupAt: Date;
  /** 聊天室開放時間 = 上車前 24 小時 */
  chatOpensAt: Date;
  /** 目的地時區，例如 Asia/Taipei */
  timezone: string;
  /** 目的地與 UTC 的差（分鐘），App 用來以當地時間顯示 */
  utcOffsetMinutes: number;
}

function toCoordinate(value: number | string | null | undefined): number | null {
  if (value === null || value === undefined || value === '') return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function countryFromCoordinates(
  lat: number | string | null | undefined,
  lng: number | string | null | undefined
): string | null {
  const la = toCoordinate(lat);
  const ln = toCoordinate(lng);
  if (la === null || ln === null) return null;
  const area = DESTINATION_AREAS.find(
    (a) => la >= a.minLat && la <= a.maxLat && ln >= a.minLng && ln <= a.maxLng
  );
  return area ? area.country : null;
}

/** 依上下車地點判斷訂單目的地的時區 */
export function resolveBookingTimezone(booking: BookingTimeFields): string {
  const country =
    countryFromCoordinates(booking.pickup_latitude, booking.pickup_longitude) ??
    countryFromCoordinates(booking.dropoff_latitude, booking.dropoff_longitude) ??
    AIRPORT_COUNTRIES[(booking.pickup_airport_code || '').toUpperCase()] ??
    AIRPORT_COUNTRIES[(booking.dropoff_airport_code || '').toUpperCase()] ??
    (booking.country || '').toUpperCase();
  return COUNTRY_TIMEZONES[country] || DEFAULT_TIMEZONE;
}

/** 某個時間點在指定時區與 UTC 的差（分鐘），例如 Asia/Taipei = 480 */
export function getUtcOffsetMinutes(at: Date, timeZone: string): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).formatToParts(at);
  const get = (type: string) => Number(parts.find((p) => p.type === type)?.value);
  const wallAsUtc = Date.UTC(get('year'), get('month') - 1, get('day'), get('hour'), get('minute'), get('second'));
  return Math.round((wallAsUtc - at.getTime()) / 60000);
}

/** 當地日期 + 時間（YYYY-MM-DD、HH:MM[:SS]）→ 真正的時間點 */
export function zonedTimeToUtc(date: string, time: string, timeZone: string): Date {
  const [y, mo, d] = date.split('-').map(Number);
  const [h, mi, s = 0] = time.split(':').map(Number);
  const wallAsUtc = Date.UTC(y, mo - 1, d, h, mi, s);
  // 先用當地時間猜一次偏移，再用猜到的時間點重算一次（有日光節約時間的地區才會不同）
  let utc = wallAsUtc - getUtcOffsetMinutes(new Date(wallAsUtc), timeZone) * 60000;
  utc = wallAsUtc - getUtcOffsetMinutes(new Date(utc), timeZone) * 60000;
  return new Date(utc);
}

/** 算出聊天室開放時間；訂單沒有預約日期時間回傳 null */
export function getChatWindow(booking: BookingTimeFields): ChatWindow | null {
  if (!booking.start_date || !booking.start_time) return null;
  const timezone = resolveBookingTimezone(booking);
  const pickupAt = zonedTimeToUtc(booking.start_date, booking.start_time, timezone);
  if (Number.isNaN(pickupAt.getTime())) return null;
  return {
    pickupAt,
    chatOpensAt: new Date(pickupAt.getTime() - CHAT_OPENS_BEFORE_PICKUP_MS),
    timezone,
    utcOffsetMinutes: getUtcOffsetMinutes(pickupAt, timezone),
  };
}
