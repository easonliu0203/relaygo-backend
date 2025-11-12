-- ========================================
-- 確保測試司機存在並且資料正確
-- ========================================

-- 步驟 1：檢查測試司機是否存在
SELECT 
    '步驟 1：檢查測試司機是否存在' AS "診斷步驟";

SELECT 
    u.id AS "用戶 ID",
    u.email AS "Email",
    u.firebase_uid AS "Firebase UID",
    u.role AS "角色",
    u.status AS "狀態",
    u.phone AS "電話"
FROM users u
WHERE u.email = 'driver.test@relaygo.com';

-- 步驟 2：如果測試司機不存在，創建一個
SELECT 
    '步驟 2：創建測試司機（如果不存在）' AS "診斷步驟";

-- 注意：這個 INSERT 會失敗，因為需要 firebase_uid
-- 您需要先在 Firebase Auth 中創建這個用戶，然後獲取 firebase_uid
-- 這裡只是示例代碼

-- INSERT INTO users (firebase_uid, email, phone, role, status, created_at, updated_at)
-- VALUES (
--     'FIREBASE_UID_HERE',  -- 需要替換為實際的 Firebase UID
--     'driver.test@relaygo.com',
--     '0912345678',
--     'driver',
--     'active',
--     NOW(),
--     NOW()
-- )
-- ON CONFLICT (email) DO NOTHING;

-- 步驟 3：確保測試司機的 role 和 status 正確
SELECT 
    '步驟 3：確保測試司機的 role 和 status 正確' AS "診斷步驟";

UPDATE users
SET 
    role = 'driver',
    status = 'active',
    updated_at = NOW()
WHERE email = 'driver.test@relaygo.com'
  AND (role != 'driver' OR status != 'active');

-- 步驟 4：檢查測試司機的 drivers 記錄
SELECT 
    '步驟 4：檢查測試司機的 drivers 記錄' AS "診斷步驟";

SELECT 
    d.id AS "司機 ID",
    d.user_id AS "用戶 ID",
    d.is_available AS "是否可用",
    d.vehicle_type AS "車型",
    d.vehicle_plate AS "車牌號",
    d.license_number AS "駕照號碼"
FROM drivers d
WHERE d.user_id = (SELECT id FROM users WHERE email = 'driver.test@relaygo.com');

-- 步驟 5：如果沒有 drivers 記錄，創建一個
SELECT 
    '步驟 5：創建 drivers 記錄（如果不存在）' AS "診斷步驟";

INSERT INTO drivers (
    user_id,
    license_number,
    license_expiry,
    vehicle_type,
    vehicle_model,
    vehicle_year,
    vehicle_plate,
    insurance_number,
    insurance_expiry,
    is_available,
    rating,
    total_trips,
    created_at,
    updated_at
)
SELECT 
    u.id,
    'TEST-LICENSE-001',
    CURRENT_DATE + INTERVAL '1 year',
    'small',  -- 車型：small 或 large
    'Toyota Camry',
    2020,
    'ABC-1234',
    'INS-001',
    CURRENT_DATE + INTERVAL '1 year',
    true,  -- 可用
    5.0,
    0,
    NOW(),
    NOW()
FROM users u
WHERE u.email = 'driver.test@relaygo.com'
  AND NOT EXISTS (
    SELECT 1 FROM drivers d WHERE d.user_id = u.id
  );

-- 步驟 6：確保 drivers 記錄的 is_available 為 true
SELECT 
    '步驟 6：確保 drivers 記錄的 is_available 為 true' AS "診斷步驟";

UPDATE drivers
SET 
    is_available = true,
    updated_at = NOW()
WHERE user_id = (SELECT id FROM users WHERE email = 'driver.test@relaygo.com')
  AND is_available != true;

-- 步驟 7：檢查測試司機的 user_profiles 記錄
SELECT 
    '步驟 7：檢查測試司機的 user_profiles 記錄' AS "診斷步驟";

SELECT 
    up.user_id AS "用戶 ID",
    CONCAT(up.first_name, ' ', up.last_name) AS "姓名",
    up.avatar_url AS "頭像",
    up.address AS "地址"
FROM user_profiles up
WHERE up.user_id = (SELECT id FROM users WHERE email = 'driver.test@relaygo.com');

-- 步驟 8：如果沒有 user_profiles 記錄，創建一個
SELECT 
    '步驟 8：創建 user_profiles 記錄（如果不存在）' AS "診斷步驟";

INSERT INTO user_profiles (
    user_id,
    first_name,
    last_name,
    created_at,
    updated_at
)
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

-- 步驟 9：最終驗證
SELECT 
    '步驟 9：最終驗證 - 測試司機應該可用' AS "診斷步驟";

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
    CASE 
        WHEN u.role = 'driver' 
         AND u.status = 'active' 
         AND d.is_available = true 
         AND d.vehicle_type IS NOT NULL 
        THEN '✅ 應該在可用司機列表中'
        ELSE '❌ 不會在可用司機列表中'
    END AS "最終結果"
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.email = 'driver.test@relaygo.com';

-- ========================================
-- 完成
-- ========================================

SELECT 
    '🎉 測試司機資料檢查和修復完成！' AS "狀態",
    '請重新測試手動派單功能。' AS "下一步";

