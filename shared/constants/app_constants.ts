// 應用程式常數定義

// 車型定義
export const VEHICLE_TYPES = {
  A: {
    name: '豪華轎車',
    description: '高級商務轎車',
    capacity: 4,
    features: ['真皮座椅', '獨立空調', '車載WiFi']
  },
  B: {
    name: '商務轎車',
    description: '舒適商務轎車',
    capacity: 4,
    features: ['舒適座椅', '空調系統']
  },
  C: {
    name: '一般轎車',
    description: '經濟型轎車',
    capacity: 4,
    features: ['基本配備', '空調系統']
  },
  D: {
    name: '小型車',
    description: '經濟實惠小車',
    capacity: 4,
    features: ['基本配備']
  }
} as const;

// 預約時數選項
export const BOOKING_DURATIONS = [6, 8] as const;

// 小費選項 (NT$)
export const TIP_OPTIONS = [500, 1000, 2000] as const;

// 外語司機加價 (NT$/日)
export const FOREIGN_LANGUAGE_SURCHARGE = 2000;

// 平台抽成比例
export const PLATFORM_COMMISSION_RATE = 0.25; // 25%

// 訂金比例
export const DEPOSIT_PERCENTAGE = 0.25; // 25%

// 超時寬限期 (分鐘)
export const OVERTIME_GRACE_PERIOD = 15;

// 最低計費比例 (50% 規則)
export const MINIMUM_BILLING_PERCENTAGE = 0.5;

// 取消政策 (小時)
export const CANCELLATION_POLICY = {
  FULL_REFUND_HOURS: 168,    // 7天前 100% 退款
  HALF_REFUND_HOURS: 24,     // 1天前 50% 退款
  NO_REFUND_HOURS: 0         // 當天不退款
} as const;

// 改期手續費比例
export const RESCHEDULE_FEE_RATE = 0.10; // 10%

// 司機保證金設定
export const DRIVER_SETTINGS = {
  DEPOSIT_AMOUNT: 10000,           // 保證金金額
  LATE_CANCELLATION_PENALTY: 2000, // 遲到取消罰款
  NO_SHOW_PENALTY: 1000,          // 爽約罰款
  ACTIVITY_THRESHOLD: 1            // 月活躍門檻 (完單數)
} as const;

// 定位設定
export const LOCATION_SETTINGS = {
  UPDATE_INTERVAL: 60,        // 更新頻率 (秒)
  TRACKING_START_HOURS: 1,    // 行程前開始追蹤 (小時)
  RETENTION_DAYS: 30          // 資料保存天數
} as const;

// 聊天設定
export const CHAT_SETTINGS = {
  OPEN_HOURS_BEFORE: 24,      // 行程前開啟 (小時)
  OPEN_HOURS_AFTER: 24,       // 行程後關閉 (小時)
  HISTORY_RETENTION_DAYS: 60  // 記錄保存天數
} as const;

// 推薦設定
export const REFERRAL_SETTINGS = {
  COMMISSION_RATE: 0.025,     // 推薦獎金比例 (2.5%)
  CODE_LENGTH: 8,             // 推薦碼長度
  CODE_EXPIRY_DAYS: 365       // 推薦碼有效期
} as const;

// 支援語言
export const SUPPORTED_LANGUAGES = {
  'zh-TW': '繁體中文',
  'en': 'English',
  'ja': '日本語',
  'ko': '한국어',
  'vi': 'Tiếng Việt',
  'th': 'ไทย',
  'ms': 'Bahasa Melayu',
  'id': 'Bahasa Indonesia'
} as const;

// 預設語言
export const DEFAULT_LANGUAGE = 'zh-TW';

// 訂單狀態顯示文字
export const BOOKING_STATUS_TEXT = {
  pending: '待確認',
  confirmed: '已確認',
  assigned: '已派單',
  in_progress: '進行中',
  completed: '已完成',
  cancelled: '已取消'
} as const;

// 支付狀態顯示文字
export const PAYMENT_STATUS_TEXT = {
  pending: '待付款',
  processing: '處理中',
  completed: '已完成',
  failed: '失敗',
  refunded: '已退款'
} as const;

// 用戶角色顯示文字
export const USER_ROLE_TEXT = {
  customer: '乘客',
  driver: '司機',
  admin: '管理員'
} as const;

// API 端點
export const API_ENDPOINTS = {
  AUTH: '/api/auth',
  USERS: '/api/users',
  BOOKINGS: '/api/bookings',
  TRIPS: '/api/trips',
  PAYMENTS: '/api/payments',
  DRIVERS: '/api/drivers',
  ADMIN: '/api/admin',
  CHAT: '/api/chat',
  LOCATION: '/api/location',
  REFERRAL: '/api/referral'
} as const;

// 檔案上傳限制
export const FILE_UPLOAD = {
  MAX_SIZE_MB: 10,
  ALLOWED_IMAGE_TYPES: ['jpg', 'jpeg', 'png', 'webp'],
  ALLOWED_DOCUMENT_TYPES: ['pdf', 'doc', 'docx']
} as const;

// 地圖設定
export const MAP_SETTINGS = {
  DEFAULT_ZOOM: 15,
  SEARCH_RADIUS_KM: 50,
  DEFAULT_CENTER: {
    latitude: 25.0330,  // 台北市
    longitude: 121.5654
  }
} as const;

// 通知類型
export const NOTIFICATION_TYPES = {
  BOOKING_CONFIRMED: 'booking_confirmed',
  DRIVER_ASSIGNED: 'driver_assigned',
  TRIP_STARTED: 'trip_started',
  TRIP_COMPLETED: 'trip_completed',
  PAYMENT_REQUIRED: 'payment_required',
  PAYMENT_COMPLETED: 'payment_completed',
  MESSAGE_RECEIVED: 'message_received',
  REFERRAL_REWARD: 'referral_reward'
} as const;

// 錯誤代碼
export const ERROR_CODES = {
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  BOOKING_CONFLICT: 'BOOKING_CONFLICT',
  PAYMENT_FAILED: 'PAYMENT_FAILED',
  DRIVER_UNAVAILABLE: 'DRIVER_UNAVAILABLE',
  INSUFFICIENT_BALANCE: 'INSUFFICIENT_BALANCE'
} as const;

// 正則表達式
export const REGEX_PATTERNS = {
  PHONE: /^09\d{8}$/,                    // 台灣手機號碼
  EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,   // 電子郵件
  LICENSE_PLATE: /^[A-Z0-9]{2,8}$/,      // 車牌號碼
  REFERRAL_CODE: /^[0-9A-Z]{8}-\d{4}$/   // 推薦碼格式
} as const;

// 時間格式
export const DATE_FORMATS = {
  DATE: 'YYYY-MM-DD',
  TIME: 'HH:mm',
  DATETIME: 'YYYY-MM-DD HH:mm:ss',
  DISPLAY_DATE: 'YYYY年MM月DD日',
  DISPLAY_TIME: 'HH:mm',
  DISPLAY_DATETIME: 'YYYY年MM月DD日 HH:mm'
} as const;

// 快取鍵
export const CACHE_KEYS = {
  USER_PROFILE: 'user_profile',
  DRIVER_LOCATION: 'driver_location',
  VEHICLE_PRICING: 'vehicle_pricing',
  SYSTEM_SETTINGS: 'system_settings'
} as const;

// 快取過期時間 (秒)
export const CACHE_TTL = {
  SHORT: 300,      // 5分鐘
  MEDIUM: 1800,    // 30分鐘
  LONG: 3600,      // 1小時
  VERY_LONG: 86400 // 24小時
} as const;
