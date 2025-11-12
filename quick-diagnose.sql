-- 快速診斷聊天室問題
-- 修正版：使用正確的欄位名稱

-- 1. 檢查最新的訂單（包含司機的訂單）
SELECT
  id,
  customer_id,
  driver_id,
  status,
  pickup_location,
  pickup_time,
  created_at,
  updated_at
FROM bookings
WHERE driver_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 5;

-- 2. 檢查訂單狀態的所有可能值
SELECT DISTINCT status, COUNT(*) as count
FROM bookings
GROUP BY status
ORDER BY count DESC;

-- 3. 檢查最新訂單的詳細資訊（包含用戶資訊）
-- 注意：users 表沒有 full_name 欄位，需要從 user_profiles 表獲取
SELECT
  b.id as booking_id,
  b.status,
  b.pickup_location,
  b.pickup_time,
  b.created_at,
  c.id as customer_id,
  c.firebase_uid as customer_firebase_uid,
  c.email as customer_email,
  c.phone as customer_phone,
  cp.first_name as customer_first_name,
  cp.last_name as customer_last_name,
  d.id as driver_id,
  d.firebase_uid as driver_firebase_uid,
  d.email as driver_email,
  d.phone as driver_phone,
  dp.first_name as driver_first_name,
  dp.last_name as driver_last_name
FROM bookings b
LEFT JOIN users c ON b.customer_id = c.id
LEFT JOIN user_profiles cp ON c.id = cp.user_id
LEFT JOIN users d ON b.driver_id = d.id
LEFT JOIN user_profiles dp ON d.id = dp.user_id
WHERE b.driver_id IS NOT NULL
ORDER BY b.created_at DESC
LIMIT 3;

-- 4. 檢查是否有聊天訊息
SELECT
  booking_id,
  COUNT(*) as message_count,
  MAX(created_at) as last_message_time
FROM chat_messages
GROUP BY booking_id
ORDER BY last_message_time DESC
LIMIT 5;

