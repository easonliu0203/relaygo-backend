-- 檢查測試司機的訂單配對狀態
-- 
-- 用途：診斷司機端訂單配對問題
-- 
-- 執行方式：
--   在 Supabase SQL Editor 中執行此腳本

-- 測試司機的 Firebase UID
-- driver.test@relaygo.com = CMfTxhJFlUVDkosJPyUoJvKjCQk1

SELECT '========================================' AS separator;
SELECT '檢查測試司機的訂單配對狀態' AS title;
SELECT '========================================' AS separator;

-- 1. 檢查測試司機是否存在
SELECT '1. 檢查測試司機是否存在' AS step;
SELECT 
  id,
  email,
  role,
  created_at
FROM auth.users
WHERE email = 'driver.test@relaygo.com';

-- 2. 檢查 drivers 表中的司機資料
SELECT '2. 檢查 drivers 表中的司機資料' AS step;
SELECT 
  id,
  user_id,
  first_name,
  last_name,
  phone,
  status,
  created_at
FROM drivers
WHERE user_id = 'CMfTxhJFlUVDkosJPyUoJvKjCQk1';

-- 3. 檢查配對給該司機的訂單（Supabase）
SELECT '3. 檢查配對給該司機的訂單（Supabase）' AS step;
SELECT 
  id,
  status,
  driver_id,
  customer_id,
  pickup_address,
  dropoff_address,
  created_at,
  updated_at
FROM bookings
WHERE driver_id = 'CMfTxhJFlUVDkosJPyUoJvKjCQk1'
ORDER BY created_at DESC
LIMIT 5;

-- 4. 檢查最近的所有訂單
SELECT '4. 檢查最近的所有訂單' AS step;
SELECT 
  id,
  status,
  driver_id,
  customer_id,
  pickup_address,
  dropoff_address,
  created_at,
  updated_at
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

-- 5. 檢查 outbox 表中的同步事件
SELECT '5. 檢查 outbox 表中的同步事件' AS step;
SELECT 
  id,
  aggregate_type,
  aggregate_id,
  event_type,
  payload->>'driverId' AS driver_id_in_payload,
  payload->>'status' AS status_in_payload,
  processed,
  created_at
FROM outbox
WHERE aggregate_type = 'booking'
  AND (payload->>'driverId' = 'CMfTxhJFlUVDkosJPyUoJvKjCQk1'
       OR aggregate_id IN (
         SELECT id::text FROM bookings WHERE driver_id = 'CMfTxhJFlUVDkosJPyUoJvKjCQk1'
       ))
ORDER BY created_at DESC
LIMIT 10;

-- 6. 檢查未處理的 outbox 事件
SELECT '6. 檢查未處理的 outbox 事件' AS step;
SELECT 
  id,
  aggregate_type,
  aggregate_id,
  event_type,
  payload->>'driverId' AS driver_id_in_payload,
  payload->>'status' AS status_in_payload,
  created_at
FROM outbox
WHERE processed = false
ORDER BY created_at DESC
LIMIT 10;

-- 7. 統計訂單狀態
SELECT '7. 統計訂單狀態' AS step;
SELECT 
  status,
  COUNT(*) AS count,
  COUNT(CASE WHEN driver_id IS NOT NULL THEN 1 END) AS with_driver,
  COUNT(CASE WHEN driver_id IS NULL THEN 1 END) AS without_driver
FROM bookings
GROUP BY status
ORDER BY count DESC;

SELECT '========================================' AS separator;
SELECT '檢查完成' AS title;
SELECT '========================================' AS separator;

