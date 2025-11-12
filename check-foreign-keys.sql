-- 檢查外鍵關係
-- 執行此腳本在 Supabase SQL Editor

-- 檢查 user_profiles 表的外鍵
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'user_profiles';

-- 檢查 drivers 表的外鍵
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'drivers';

-- 測試 JOIN 查詢
SELECT
  u.id,
  u.email,
  u.role,
  up.first_name,
  up.last_name,
  up.phone
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE u.email = 'customer.test@relaygo.com';

-- 測試司機 JOIN 查詢
SELECT
  u.id,
  u.email,
  u.role,
  up.first_name,
  up.last_name,
  up.phone,
  d.license_number,
  d.vehicle_type,
  d.vehicle_plate
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.email = 'driver.test@relaygo.com';

