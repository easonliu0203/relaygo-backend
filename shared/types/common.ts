// 共用類型定義

// 用戶角色
export type UserRole = 'customer' | 'driver' | 'admin';

// 用戶狀態
export type UserStatus = 'active' | 'inactive' | 'suspended' | 'pending';

// 車型
export type VehicleType = 'A' | 'B' | 'C' | 'D';

// 預約時數
export type BookingDuration = 6 | 8;

// 訂單狀態
export type BookingStatus = 
  | 'pending'      // 待確認
  | 'confirmed'    // 已確認
  | 'assigned'     // 已派單
  | 'in_progress'  // 進行中
  | 'completed'    // 已完成
  | 'cancelled';   // 已取消

// 支付類型
export type PaymentType = 'deposit' | 'balance' | 'tip' | 'refund';

// 支付狀態
export type PaymentStatus = 'pending' | 'processing' | 'completed' | 'failed' | 'refunded';

// 支付方式
export type PaymentMethod = 'credit_card' | 'bank_transfer' | 'cash' | 'digital_wallet';

// 聊天訊息類型
export type MessageType = 'text' | 'image' | 'location' | 'system';

// 推薦碼類型
export type ReferralCodeType = 'D-code' | 'F-code';

// 語言代碼
export type LanguageCode = 'zh-TW' | 'en' | 'ja' | 'ko' | 'vi' | 'th' | 'ms' | 'id';

// 基礎實體介面
export interface BaseEntity {
  id: string;
  created_at: string;
  updated_at: string;
}

// 用戶介面
export interface User extends BaseEntity {
  firebase_uid: string;
  email: string;
  phone?: string;
  role: UserRole;
  status: UserStatus;
  preferred_language: LanguageCode;
}

// 用戶資料介面
export interface UserProfile extends BaseEntity {
  user_id: string;
  first_name?: string;
  last_name?: string;
  avatar_url?: string;
  date_of_birth?: string;
  gender?: 'male' | 'female' | 'other';
  address?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
}

// 司機介面
export interface Driver extends BaseEntity {
  user_id: string;
  license_number: string;
  license_expiry: string;
  vehicle_type: VehicleType;
  vehicle_model?: string;
  vehicle_year?: number;
  vehicle_plate: string;
  insurance_number?: string;
  insurance_expiry?: string;
  background_check_status: 'pending' | 'approved' | 'rejected';
  background_check_date?: string;
  rating: number;
  total_trips: number;
  is_available: boolean;
  languages?: string[];
  deposit_amount: number;
  current_balance: number;
}

// 車型價格介面
export interface VehiclePricing extends BaseEntity {
  vehicle_type: VehicleType;
  duration_hours: BookingDuration;
  base_price: number;
  overtime_rate: number;
  is_active: boolean;
  effective_from: string;
  effective_until?: string;
}

// 預約訂單介面
export interface Booking extends BaseEntity {
  customer_id: string;
  driver_id?: string;
  booking_number: string;
  status: BookingStatus;
  
  // 預約詳情
  start_date: string;
  start_time: string;
  duration_hours: BookingDuration;
  vehicle_type: VehicleType;
  pickup_location: string;
  pickup_latitude?: number;
  pickup_longitude?: number;
  destination?: string;
  special_requirements?: string;
  requires_foreign_language: boolean;
  
  // 價格計算
  base_price: number;
  foreign_language_surcharge: number;
  overtime_fee: number;
  tip_amount: number;
  total_amount: number;
  deposit_amount: number;
  
  // 時間記錄
  actual_start_time?: string;
  actual_end_time?: string;
}

// 多日行程介面
export interface MultiDayTrip extends BaseEntity {
  booking_id: string;
  day_number: number;
  trip_date: string;
  status: 'pending' | 'in_progress' | 'completed' | 'cancelled';
  daily_amount: number;
  daily_deposit: number;
  actual_start_time?: string;
  actual_end_time?: string;
  overtime_minutes: number;
  overtime_fee: number;
  tip_amount: number;
}

// 支付記錄介面
export interface Payment extends BaseEntity {
  booking_id: string;
  trip_day_id?: string;
  payment_type: PaymentType;
  amount: number;
  status: PaymentStatus;
  payment_method?: PaymentMethod;
  transaction_id?: string;
  gateway_response?: Record<string, any>;
  processed_at?: string;
}

// 司機位置介面
export interface DriverLocation extends BaseEntity {
  driver_id: string;
  booking_id?: string;
  latitude: number;
  longitude: number;
  accuracy?: number;
  speed?: number;
  heading?: number;
  recorded_at: string;
}

// 聊天室介面
export interface ChatRoom extends BaseEntity {
  booking_id: string;
  customer_id: string;
  driver_id: string;
  status: 'active' | 'closed';
  opened_at: string;
  closed_at?: string;
}

// 聊天訊息介面
export interface ChatMessage extends BaseEntity {
  room_id: string;
  sender_id: string;
  message_type: MessageType;
  content: string;
  translated_content?: Record<LanguageCode, string>;
  is_read: boolean;
  sent_at: string;
}

// 推薦碼介面
export interface ReferralCode extends BaseEntity {
  user_id: string;
  code: string;
  code_type: ReferralCodeType;
  is_active: boolean;
  usage_count: number;
  max_usage?: number;
  expires_at?: string;
}

// 推薦記錄介面
export interface Referral extends BaseEntity {
  referrer_id: string;
  referee_id: string;
  referral_code_id: string;
  status: 'pending' | 'qualified' | 'rewarded';
  reward_amount?: number;
  qualified_at?: string;
  rewarded_at?: string;
}

// 評價介面
export interface Review extends BaseEntity {
  booking_id: string;
  reviewer_id: string;
  reviewee_id: string;
  rating: number;
  comment?: string;
  is_anonymous: boolean;
}

// 系統設定介面
export interface SystemSetting extends BaseEntity {
  key: string;
  value: any;
  description?: string;
  is_active: boolean;
}

// API 回應介面
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  errors?: Record<string, string[]>;
}

// 分頁介面
export interface PaginationParams {
  page: number;
  limit: number;
  sort?: string;
  order?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

// 座標介面
export interface Coordinates {
  latitude: number;
  longitude: number;
}

// 地址介面
export interface Address {
  formatted_address: string;
  coordinates?: Coordinates;
  components?: {
    country?: string;
    city?: string;
    district?: string;
    street?: string;
    number?: string;
  };
}
