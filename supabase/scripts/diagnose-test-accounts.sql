-- 診斷測試帳號問題
-- 
-- 用途：檢查測試帳號是否存在於資料庫中，以及資料完整性
-- 
-- 執行方式：
--   在 Supabase SQL Editor 中執行此腳本

SELECT '========================================' AS separator;
SELECT '診斷測試帳號問題' AS title;
SELECT '========================================' AS separator;

-- 1. 檢查 auth.users 表中的測試帳號
SELECT '1. 檢查 auth.users 表中的測試帳號' AS step;
SELECT 
  id,
  email,
  email_confirmed_at,
  created_at,
  updated_at
FROM auth.users
WHERE email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')
ORDER BY email;

-- 2. 檢查 public.users 表中的測試帳號
SELECT '2. 檢查 public.users 表中的測試帳號' AS step;
SELECT 
  id,
  firebase_uid,
  email,
  phone,
  role,
  status,
  created_at,
  updated_at
FROM users
WHERE email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')
ORDER BY email;

-- 3. 檢查 user_profiles 表中的測試帳號資料
SELECT '3. 檢查 user_profiles 表中的測試帳號資料' AS step;
SELECT 
  up.user_id,
  u.email,
  u.role,
  up.first_name,
  up.last_name,
  up.phone,
  up.created_at
FROM user_profiles up
JOIN users u ON up.user_id = u.id
WHERE u.email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')
ORDER BY u.email;

-- 4. 檢查 drivers 表中的司機測試帳號資料
SELECT '4. 檢查 drivers 表中的司機測試帳號資料' AS step;
SELECT 
  d.id,
  d.user_id,
  u.email,
  d.first_name,
  d.last_name,
  d.phone,
  d.vehicle_type,
  d.vehicle_plate,
  d.vehicle_model,
  d.is_available,
  d.status,
  d.rating,
  d.total_trips,
  d.created_at
FROM drivers d
JOIN users u ON d.user_id = u.id
WHERE u.email = 'driver.test@relaygo.com';

-- 5. 檢查所有用戶的角色分佈
SELECT '5. 檢查所有用戶的角色分佈' AS step;
SELECT 
  role,
  COUNT(*) AS count
FROM users
GROUP BY role
ORDER BY role;

-- 6. 檢查是否有用戶沒有 user_profiles
SELECT '6. 檢查是否有用戶沒有 user_profiles' AS step;
SELECT 
  u.id,
  u.email,
  u.role,
  u.created_at
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE up.user_id IS NULL
ORDER BY u.created_at DESC
LIMIT 10;

-- 7. 檢查是否有司機沒有 drivers 記錄
SELECT '7. 檢查是否有司機沒有 drivers 記錄' AS step;
SELECT 
  u.id,
  u.email,
  u.role,
  u.created_at
FROM users u
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.role = 'driver' AND d.user_id IS NULL
ORDER BY u.created_at DESC
LIMIT 10;

-- 8. 檢查測試帳號的完整資訊（JOIN 所有相關表）
SELECT '8. 檢查測試帳號的完整資訊' AS step;
SELECT 
  u.id AS user_id,
  u.firebase_uid,
  u.email,
  u.role,
  u.status AS user_status,
  up.first_name,
  up.last_name,
  up.phone AS profile_phone,
  d.id AS driver_id,
  d.vehicle_type,
  d.vehicle_plate,
  d.is_available,
  d.status AS driver_status
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')
ORDER BY u.email;

SELECT '========================================' AS separator;
SELECT '診斷完成' AS title;
SELECT '========================================' AS separator;

