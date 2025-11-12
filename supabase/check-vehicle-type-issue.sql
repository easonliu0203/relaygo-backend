-- ========================================
-- 檢查車型不匹配問題
-- ========================================

-- 步驟 1：檢查訂單的 vehicle_type
SELECT 
    '步驟 1：檢查訂單的 vehicle_type' AS "診斷步驟";

SELECT 
    id AS "訂單 ID",
    booking_number AS "訂單編號",
    status AS "狀態",
    vehicle_type AS "車型",
    start_date AS "開始日期",
    start_time AS "開始時間",
    duration_hours AS "時長",
    created_at AS "創建時間"
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

-- 步驟 2：檢查司機的 vehicle_type
SELECT 
    '步驟 2：檢查司機的 vehicle_type' AS "診斷步驟";

SELECT 
    u.email AS "Email",
    d.vehicle_type AS "車型",
    d.vehicle_plate AS "車牌號",
    d.is_available AS "是否可用"
FROM users u
INNER JOIN drivers d ON u.id = d.user_id
WHERE u.role = 'driver';

-- 步驟 3：檢查 vehicle_type 的所有可能值
SELECT 
    '步驟 3：檢查 vehicle_type 的所有可能值' AS "診斷步驟";

SELECT DISTINCT 
    vehicle_type AS "訂單中的車型"
FROM bookings
WHERE vehicle_type IS NOT NULL;

-- 步驟 4：修復訂單的 vehicle_type（將中文車型名稱改為代碼）
SELECT 
    '步驟 4：修復訂單的 vehicle_type' AS "診斷步驟";

-- 將 '標準車型' 改為 'small'
UPDATE bookings
SET 
    vehicle_type = 'small',
    updated_at = NOW()
WHERE vehicle_type = '標準車型';

-- 將其他中文車型名稱改為代碼
UPDATE bookings
SET 
    vehicle_type = 'large',
    updated_at = NOW()
WHERE vehicle_type LIKE '%8人%' OR vehicle_type LIKE '%9人%';

-- 步驟 5：修復司機的 vehicle_type（將 'A' 改為 'small'）
SELECT 
    '步驟 5：修復司機的 vehicle_type' AS "診斷步驟";

UPDATE drivers
SET 
    vehicle_type = 'small',
    updated_at = NOW()
WHERE vehicle_type = 'A';

UPDATE drivers
SET 
    vehicle_type = 'large',
    updated_at = NOW()
WHERE vehicle_type IN ('B', 'C', 'D');

-- 步驟 6：驗證修復結果
SELECT 
    '步驟 6：驗證修復結果' AS "診斷步驟";

SELECT 
    id AS "訂單 ID",
    booking_number AS "訂單編號",
    vehicle_type AS "車型",
    CASE 
        WHEN vehicle_type IN ('small', 'large') THEN '✅ 車型正確'
        ELSE '❌ 車型錯誤'
    END AS "檢查結果"
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

SELECT 
    u.email AS "Email",
    d.vehicle_type AS "車型",
    CASE 
        WHEN d.vehicle_type IN ('small', 'large') THEN '✅ 車型正確'
        ELSE '❌ 車型錯誤'
    END AS "檢查結果"
FROM users u
INNER JOIN drivers d ON u.id = d.user_id
WHERE u.role = 'driver';

-- ========================================
-- 完成
-- ========================================

SELECT 
    '🎉 車型檢查和修復完成！' AS "狀態",
    '請重新測試手動派單功能。' AS "下一步";

