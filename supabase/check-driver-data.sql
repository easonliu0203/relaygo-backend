-- ========================================
-- 檢查司機資料和可用性
-- ========================================

-- 步驟 1：檢查所有司機用戶
SELECT 
    '步驟 1：檢查所有司機用戶' AS "診斷步驟";

SELECT 
    u.id AS "用戶 ID",
    u.email AS "Email",
    u.firebase_uid AS "Firebase UID",
    u.role AS "角色",
    u.status AS "狀態",
    u.phone AS "電話"
FROM users u
WHERE u.role = 'driver';

-- 步驟 2：檢查所有 drivers 記錄
SELECT 
    '步驟 2：檢查所有 drivers 記錄' AS "診斷步驟";

SELECT 
    d.id AS "司機 ID",
    d.user_id AS "用戶 ID",
    d.is_available AS "是否可用",
    d.vehicle_type AS "車型",
    d.vehicle_plate AS "車牌號",
    d.license_number AS "駕照號碼"
FROM drivers d;

-- 步驟 3：檢查司機的完整資料（JOIN 查詢）
SELECT 
    '步驟 3：檢查司機的完整資料' AS "診斷步驟";

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
        THEN '✅ 應該可用'
        ELSE '❌ 不可用'
    END AS "可用性"
FROM users u
LEFT JOIN drivers d ON u.id = d.user_id
WHERE u.role = 'driver';

-- 步驟 4：模擬 API 查詢（獲取可用司機）
SELECT 
    '步驟 4：模擬 API 查詢' AS "診斷步驟";

SELECT 
    u.id,
    u.firebase_uid,
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

-- 步驟 5：檢查 user_profiles 記錄
SELECT 
    '步驟 5：檢查 user_profiles 記錄' AS "診斷步驟";

SELECT 
    up.user_id AS "用戶 ID",
    CONCAT(up.first_name, ' ', up.last_name) AS "姓名",
    u.email AS "Email"
FROM user_profiles up
INNER JOIN users u ON up.user_id = u.id
WHERE u.role = 'driver';

-- 步驟 6：檢查訂單資料
SELECT 
    '步驟 6：檢查訂單資料' AS "診斷步驟";

SELECT 
    id AS "訂單 ID",
    booking_number AS "訂單編號",
    status AS "狀態",
    start_date AS "開始日期",
    start_time AS "開始時間",
    duration_hours AS "時長",
    vehicle_type AS "車型",
    created_at AS "創建時間"
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

-- 步驟 7：檢查 outbox 資料表
SELECT 
    '步驟 7：檢查 outbox 資料表' AS "診斷步驟";

SELECT 
    id AS "Outbox ID",
    table_name AS "資料表",
    record_id AS "記錄 ID",
    operation AS "操作",
    created_at AS "創建時間",
    processed_at AS "處理時間"
FROM outbox
ORDER BY created_at DESC
LIMIT 20;

-- 步驟 8：檢查是否有重複的 outbox 記錄
SELECT 
    '步驟 8：檢查重複的 outbox 記錄' AS "診斷步驟";

SELECT 
    table_name AS "資料表",
    record_id AS "記錄 ID",
    operation AS "操作",
    COUNT(*) AS "記錄數量"
FROM outbox
GROUP BY table_name, record_id, operation
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- ========================================
-- 完成
-- ========================================

SELECT 
    '🎉 檢查完成！' AS "狀態",
    '請查看上述查詢結果，找出問題所在。' AS "下一步";

