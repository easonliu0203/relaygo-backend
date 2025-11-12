-- 診斷測試司機帳號問題
-- 檢查 driver.test@gelaygo.com 的資料狀態

-- 1. 檢查用戶是否存在
SELECT 
  '=== 1. 檢查用戶是否存在 ===' as step,
  id,
  email,
  role,
  created_at
FROM users
WHERE email = 'driver.test@gelaygo.com';

-- 2. 檢查 user_profiles 資料
SELECT 
  '=== 2. 檢查 user_profiles 資料 ===' as step,
  up.id,
  up.user_id,
  up.first_name,
  up.last_name,
  up.phone,
  u.email
FROM user_profiles up
JOIN users u ON up.user_id = u.id
WHERE u.email = 'driver.test@gelaygo.com';

-- 3. 檢查 drivers 資料
SELECT 
  '=== 3. 檢查 drivers 資料 ===' as step,
  d.id,
  d.user_id,
  d.license_number,
  d.vehicle_type,
  d.vehicle_plate,
  d.vehicle_model,
  d.is_available,
  d.rating,
  d.total_trips,
  u.email
FROM drivers d
JOIN users u ON d.user_id = u.id
WHERE u.email = 'driver.test@gelaygo.com';

-- 4. 檢查所有司機角色的用戶
SELECT 
  '=== 4. 檢查所有司機角色的用戶 ===' as step,
  u.id,
  u.email,
  u.role,
  up.first_name,
  up.last_name,
  d.vehicle_type,
  d.is_available
FROM users u
LEFT JOIN user_profiles up ON up.user_id = u.id
LEFT JOIN drivers d ON d.user_id = u.id
WHERE u.role = 'driver';

-- 5. 檢查是否有任何可用司機
SELECT 
  '=== 5. 檢查是否有任何可用司機 ===' as step,
  COUNT(*) as total_drivers,
  COUNT(CASE WHEN d.is_available = true THEN 1 END) as available_drivers
FROM users u
LEFT JOIN drivers d ON d.user_id = u.id
WHERE u.role = 'driver';

