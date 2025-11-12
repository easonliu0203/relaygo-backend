-- ========================================
-- 診斷並修復司機資料問題
-- ========================================

-- 步驟 1：檢查司機的完整資料
SELECT
    '步驟 1：檢查司機的完整資料' AS "診斷步驟";

SELECT
    u.id AS "用戶 ID",
    u.email AS "Email",
    u.firebase_uid AS "Firebase UID",
    u.role AS "角色",
    u.status AS "狀態",
    u.phone AS "電話",
    d.is_available AS "是否可用",
    d.vehicle_type AS "車型",
    d.vehicle_plate AS "車牌號",
    d.license_number AS "駕照號碼",
    CONCAT(up.first_name, ' ', up.last_name) AS "姓名"
FROM users u
LEFT JOIN drivers d ON u.id = d.user_id
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE u.email = 'driver.test@relaygo.com';

-- 步驟 2：檢查所有司機用戶
SELECT 
    '步驟 2：檢查所有司機用戶' AS "診斷步驟";

SELECT 
    u.id AS "用戶 ID",
    u.email AS "Email",
    u.role AS "角色",
    u.status AS "狀態",
    d.is_available AS "是否可用",
    d.vehicle_type AS "車型"
FROM users u
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.role = 'driver';

-- 步驟 3：檢查 drivers 資料表中的所有記錄
SELECT 
    '步驟 3：檢查 drivers 資料表中的所有記錄' AS "診斷步驟";

SELECT 
    d.id AS "司機 ID",
    d.user_id AS "用戶 ID",
    u.email AS "Email",
    d.is_available AS "是否可用",
    d.vehicle_type AS "車型",
    d.vehicle_plate AS "車牌號",
    d.license_number AS "駕照號碼"
FROM drivers d
LEFT JOIN users u ON d.user_id = u.id;

-- 步驟 4：修復司機資料（如果需要）
SELECT 
    '步驟 4：修復司機資料' AS "診斷步驟";

-- 4.1 確保 role 是 'driver'
UPDATE users
SET role = 'driver'
WHERE id = '416556f9-adbf-4c2e-920f-164d80f5307a'
  AND role != 'driver';

-- 4.2 確保 status 是 'active'
UPDATE users
SET status = 'active'
WHERE id = '416556f9-adbf-4c2e-920f-164d80f5307a'
  AND status != 'active';

-- 4.3 確保 is_available 是 true
UPDATE drivers
SET is_available = true
WHERE user_id = '416556f9-adbf-4c2e-920f-164d80f5307a'
  AND is_available != true;

-- 4.4 確保 vehicle_type 不為空（如果為空，設為 'small'）
UPDATE drivers
SET vehicle_type = 'small'
WHERE user_id = '416556f9-adbf-4c2e-920f-164d80f5307a'
  AND (vehicle_type IS NULL OR vehicle_type = '');

-- 步驟 5：驗證修復結果
SELECT 
    '步驟 5：驗證修復結果' AS "診斷步驟";

SELECT 
    u.id AS "用戶 ID",
    u.email AS "Email",
    u.role AS "角色",
    u.status AS "狀態",
    d.is_available AS "是否可用",
    d.vehicle_type AS "車型",
    d.vehicle_plate AS "車牌號",
    CASE 
        WHEN u.role = 'driver' AND u.status = 'active' AND d.is_available = true AND d.vehicle_type IS NOT NULL 
        THEN '✅ 司機資料正確'
        ELSE '❌ 司機資料有問題'
    END AS "驗證結果"
FROM users u
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.email = 'driver.test@relaygo.com';

-- 步驟 6：測試 API 查詢邏輯（模擬 API 的查詢）
SELECT 
    '步驟 6：測試 API 查詢邏輯' AS "診斷步驟";

-- 6.1 獲取所有司機用戶（模擬 API 的第一步）
SELECT 
    u.id,
    u.firebase_uid,
    u.email,
    u.role,
    u.status
FROM users u
WHERE u.role = 'driver'
  AND u.status = 'active';

-- 6.2 獲取司機的 drivers 資料（模擬 API 的第二步）
SELECT 
    d.*
FROM drivers d
WHERE d.user_id IN (
    SELECT u.id
    FROM users u
    WHERE u.role = 'driver'
      AND u.status = 'active'
);

-- 6.3 過濾可用司機（模擬 API 的第三步）
SELECT 
    u.id,
    u.email,
    u.role,
    u.status,
    d.is_available,
    d.vehicle_type,
    d.vehicle_plate
FROM users u
INNER JOIN drivers d ON u.id = d.user_id
WHERE u.role = 'driver'
  AND u.status = 'active'
  AND d.is_available = true;

-- 步驟 7：檢查是否有其他問題
SELECT 
    '步驟 7：檢查是否有其他問題' AS "診斷步驟";

-- 7.1 檢查是否有 user_profiles 記錄
SELECT
    up.user_id AS "用戶 ID",
    CONCAT(up.first_name, ' ', up.last_name) AS "姓名",
    u.phone AS "電話",
    CASE
        WHEN up.user_id IS NOT NULL THEN '✅ 有 user_profiles 記錄'
        ELSE '❌ 沒有 user_profiles 記錄'
    END AS "檢查結果"
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
WHERE u.email = 'driver.test@relaygo.com';

-- 7.2 如果沒有 user_profiles 記錄，創建一個
INSERT INTO user_profiles (user_id, first_name, last_name, created_at, updated_at)
SELECT
    u.id,
    '測試',
    '司機',
    NOW(),
    NOW()
FROM users u
WHERE u.email = 'driver.test@relaygo.com'
  AND NOT EXISTS (
    SELECT 1 FROM user_profiles up WHERE up.user_id = u.id
  );

-- 步驟 8：最終驗證
SELECT 
    '步驟 8：最終驗證 - 可用司機列表' AS "診斷步驟";

SELECT
    u.id AS "用戶 ID",
    u.email AS "Email",
    u.firebase_uid AS "Firebase UID",
    u.role AS "角色",
    u.status AS "狀態",
    u.phone AS "電話",
    CONCAT(up.first_name, ' ', up.last_name) AS "姓名",
    d.is_available AS "是否可用",
    d.vehicle_type AS "車型",
    d.vehicle_plate AS "車牌號",
    d.license_number AS "駕照號碼",
    CASE
        WHEN u.role = 'driver'
         AND u.status = 'active'
         AND d.is_available = true
         AND d.vehicle_type IS NOT NULL
         AND up.user_id IS NOT NULL
        THEN '✅ 應該在可用司機列表中'
        ELSE '❌ 不會在可用司機列表中'
    END AS "最終結果"
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.role = 'driver';

-- ========================================
-- 完成
-- ========================================

SELECT 
    '🎉 診斷和修復完成！' AS "狀態",
    '請檢查上述查詢結果，確認司機資料是否正確。' AS "下一步";

