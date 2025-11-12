-- 修復測試帳號資料
-- 
-- 用途：為測試帳號創建缺失的 user_profiles 和 drivers 記錄
-- 
-- 執行方式：
--   在 Supabase SQL Editor 中執行此腳本

SELECT '========================================' AS separator;
SELECT '修復測試帳號資料' AS title;
SELECT '========================================' AS separator;

-- 1. 檢查並創建客戶測試帳號的 users 記錄
SELECT '1. 檢查並創建客戶測試帳號的 users 記錄' AS step;

-- 如果客戶測試帳號不存在，創建它
INSERT INTO users (firebase_uid, email, role, status, created_at, updated_at)
SELECT 
  'customer_test_uid_' || gen_random_uuid()::text,
  'customer.test@relaygo.com',
  'customer',
  'active',
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE email = 'customer.test@relaygo.com'
);

-- 顯示客戶測試帳號
SELECT 
  id,
  firebase_uid,
  email,
  role,
  status,
  created_at
FROM users
WHERE email = 'customer.test@relaygo.com';

-- 2. 檢查並創建客戶測試帳號的 user_profiles 記錄
SELECT '2. 檢查並創建客戶測試帳號的 user_profiles 記錄' AS step;

-- 為客戶測試帳號創建 user_profiles
INSERT INTO user_profiles (user_id, first_name, last_name, phone, created_at, updated_at)
SELECT 
  u.id,
  '測試',
  '客戶',
  '0912345678',
  NOW(),
  NOW()
FROM users u
WHERE u.email = 'customer.test@relaygo.com'
  AND NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE user_id = u.id
  );

-- 顯示客戶測試帳號的 user_profiles
SELECT 
  up.user_id,
  u.email,
  up.first_name,
  up.last_name,
  up.phone,
  up.created_at
FROM user_profiles up
JOIN users u ON up.user_id = u.id
WHERE u.email = 'customer.test@relaygo.com';

-- 3. 檢查並創建司機測試帳號的 users 記錄
SELECT '3. 檢查並創建司機測試帳號的 users 記錄' AS step;

-- 如果司機測試帳號不存在，創建它
INSERT INTO users (firebase_uid, email, role, status, created_at, updated_at)
SELECT 
  'CMfTxhJFlUVDkosJPyUoJvKjCQk1',
  'driver.test@relaygo.com',
  'driver',
  'active',
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE email = 'driver.test@relaygo.com'
);

-- 如果 firebase_uid 不正確，更新它
UPDATE users
SET firebase_uid = 'CMfTxhJFlUVDkosJPyUoJvKjCQk1',
    updated_at = NOW()
WHERE email = 'driver.test@relaygo.com'
  AND firebase_uid != 'CMfTxhJFlUVDkosJPyUoJvKjCQk1';

-- 顯示司機測試帳號
SELECT 
  id,
  firebase_uid,
  email,
  role,
  status,
  created_at
FROM users
WHERE email = 'driver.test@relaygo.com';

-- 4. 檢查並創建司機測試帳號的 user_profiles 記錄
SELECT '4. 檢查並創建司機測試帳號的 user_profiles 記錄' AS step;

-- 為司機測試帳號創建 user_profiles
INSERT INTO user_profiles (user_id, first_name, last_name, phone, created_at, updated_at)
SELECT 
  u.id,
  '測試',
  '司機',
  '0987654321',
  NOW(),
  NOW()
FROM users u
WHERE u.email = 'driver.test@relaygo.com'
  AND NOT EXISTS (
    SELECT 1 FROM user_profiles WHERE user_id = u.id
  );

-- 顯示司機測試帳號的 user_profiles
SELECT 
  up.user_id,
  u.email,
  up.first_name,
  up.last_name,
  up.phone,
  up.created_at
FROM user_profiles up
JOIN users u ON up.user_id = u.id
WHERE u.email = 'driver.test@relaygo.com';

-- 5. 檢查並創建司機測試帳號的 drivers 記錄
SELECT '5. 檢查並創建司機測試帳號的 drivers 記錄' AS step;

-- 為司機測試帳號創建 drivers 記錄
INSERT INTO drivers (
  user_id,
  license_number,
  license_expiry,
  vehicle_type,
  vehicle_plate,
  vehicle_model,
  vehicle_year,
  is_available,
  background_check_status,
  rating,
  total_trips,
  created_at,
  updated_at
)
SELECT
  u.id,
  'TEST123456',
  '2025-12-31'::DATE,
  'A',
  'TEST-001',
  'Toyota Alphard',
  2023,
  true,
  'approved',
  5.0,
  0,
  NOW(),
  NOW()
FROM users u
WHERE u.email = 'driver.test@relaygo.com'
  AND NOT EXISTS (
    SELECT 1 FROM drivers WHERE user_id = u.id
  );

-- 顯示司機測試帳號的 drivers 記錄
SELECT
  d.id,
  d.user_id,
  u.email,
  d.license_number,
  d.vehicle_type,
  d.vehicle_plate,
  d.vehicle_model,
  d.is_available,
  d.background_check_status,
  d.rating,
  d.total_trips,
  d.created_at
FROM drivers d
JOIN users u ON d.user_id = u.id
WHERE u.email = 'driver.test@relaygo.com';

-- 6. 驗證修復結果
SELECT '6. 驗證修復結果' AS step;

-- 檢查客戶測試帳號的完整資訊
SELECT '客戶測試帳號完整資訊:' AS info;
SELECT 
  u.id AS user_id,
  u.firebase_uid,
  u.email,
  u.role,
  u.status AS user_status,
  up.first_name,
  up.last_name,
  up.phone,
  u.created_at
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE u.email = 'customer.test@relaygo.com';

-- 檢查司機測試帳號的完整資訊
SELECT '司機測試帳號完整資訊:' AS info;
SELECT
  u.id AS user_id,
  u.firebase_uid,
  u.email,
  u.role,
  u.status AS user_status,
  up.first_name AS profile_first_name,
  up.last_name AS profile_last_name,
  up.phone AS profile_phone,
  d.id AS driver_id,
  d.license_number,
  d.vehicle_type,
  d.vehicle_plate,
  d.is_available,
  d.background_check_status AS driver_status,
  u.created_at
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.email = 'driver.test@relaygo.com';

SELECT '========================================' AS separator;
SELECT '修復完成' AS title;
SELECT '========================================' AS separator;

-- 顯示修復總結
SELECT 
  '測試帳號修復總結' AS summary,
  (SELECT COUNT(*) FROM users WHERE email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')) AS total_users,
  (SELECT COUNT(*) FROM user_profiles up JOIN users u ON up.user_id = u.id WHERE u.email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')) AS total_profiles,
  (SELECT COUNT(*) FROM drivers d JOIN users u ON d.user_id = u.id WHERE u.email = 'driver.test@relaygo.com') AS total_drivers;

