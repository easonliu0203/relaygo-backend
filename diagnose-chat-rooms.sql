-- 診斷聊天室列表顯示問題

-- 1. 檢查 Supabase bookings 表中的訂單
SELECT 
  id,
  customer_id,
  driver_id,
  status,
  pickup_time,
  created_at,
  updated_at
FROM bookings
WHERE driver_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 2. 檢查特定訂單的詳細資訊（替換為實際的訂單 ID）
-- SELECT * FROM bookings WHERE id = 'YOUR_BOOKING_ID';

-- 3. 檢查 chat_messages 表是否有資料
SELECT 
  COUNT(*) as total_messages,
  booking_id
FROM chat_messages
GROUP BY booking_id;

-- 4. 檢查 users 表中的用戶資訊
SELECT 
  id,
  firebase_uid,
  full_name,
  role,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- 5. 檢查訂單和用戶的關聯
SELECT 
  b.id as booking_id,
  b.status,
  b.pickup_time,
  c.firebase_uid as customer_firebase_uid,
  c.full_name as customer_name,
  d.firebase_uid as driver_firebase_uid,
  d.full_name as driver_name
FROM bookings b
LEFT JOIN users c ON b.customer_id = c.id
LEFT JOIN users d ON b.driver_id = d.id
WHERE b.driver_id IS NOT NULL
ORDER BY b.created_at DESC
LIMIT 10;

