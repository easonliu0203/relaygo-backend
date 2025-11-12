-- 獲取最新訂單資訊以創建聊天室
-- 這個查詢會返回創建聊天室所需的所有資訊

SELECT 
  b.id as booking_id,
  b.status as booking_status,
  b.pickup_location,
  b.pickup_time,
  b.created_at,
  
  -- 客戶資訊
  c.firebase_uid as customer_firebase_uid,
  COALESCE(
    CONCAT(cp.first_name, ' ', cp.last_name),
    c.email,
    '客戶'
  ) as customer_name,
  
  -- 司機資訊
  d.firebase_uid as driver_firebase_uid,
  COALESCE(
    CONCAT(dp.first_name, ' ', dp.last_name),
    d.email,
    '司機'
  ) as driver_name

FROM bookings b
LEFT JOIN users c ON b.customer_id = c.id
LEFT JOIN user_profiles cp ON c.id = cp.user_id
LEFT JOIN users d ON b.driver_id = d.id
LEFT JOIN user_profiles dp ON d.id = dp.user_id

WHERE b.driver_id IS NOT NULL
ORDER BY b.created_at DESC
LIMIT 1;

