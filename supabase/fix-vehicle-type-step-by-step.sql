-- ========================================
-- 修復 vehicle_type 問題 - 分步執行版本
-- ========================================
-- 
-- 重要：請按順序執行每個步驟！
-- 
-- 執行順序：
-- 1. 刪除舊的 CHECK 約束
-- 2. 更新資料
-- 3. 添加新的 CHECK 約束
-- 
-- ========================================

-- ========================================
-- 第一部分：刪除舊的 CHECK 約束
-- ========================================

SELECT '========================================' AS "步驟";
SELECT '第一部分：刪除舊的 CHECK 約束' AS "步驟";
SELECT '========================================' AS "步驟";

-- 刪除 drivers 資料表的舊 CHECK 約束
ALTER TABLE drivers DROP CONSTRAINT IF EXISTS drivers_vehicle_type_check;

-- 刪除 bookings 資料表的舊 CHECK 約束
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_vehicle_type_check;

SELECT '✅ 舊的 CHECK 約束已刪除' AS "結果";

-- ========================================
-- 第二部分：更新資料
-- ========================================

SELECT '========================================' AS "步驟";
SELECT '第二部分：更新資料' AS "步驟";
SELECT '========================================' AS "步驟";

-- 更新 bookings 資料表
-- 將中文車型名稱改為 'small'
UPDATE bookings
SET 
    vehicle_type = 'small',
    updated_at = NOW()
WHERE vehicle_type NOT IN ('A', 'B', 'C', 'D', 'small', 'large');

-- 將 'A' 改為 'small'
UPDATE bookings
SET 
    vehicle_type = 'small',
    updated_at = NOW()
WHERE vehicle_type = 'A';

-- 將 'B', 'C', 'D' 改為 'large'
UPDATE bookings
SET 
    vehicle_type = 'large',
    updated_at = NOW()
WHERE vehicle_type IN ('B', 'C', 'D');

SELECT '✅ bookings 資料表已更新' AS "結果";

-- 更新 drivers 資料表
-- 將 'A' 改為 'small'
UPDATE drivers
SET 
    vehicle_type = 'small',
    updated_at = NOW()
WHERE vehicle_type = 'A';

-- 將 'B', 'C', 'D' 改為 'large'
UPDATE drivers
SET 
    vehicle_type = 'large',
    updated_at = NOW()
WHERE vehicle_type IN ('B', 'C', 'D');

SELECT '✅ drivers 資料表已更新' AS "結果";

-- 驗證更新結果
SELECT 
    '驗證 bookings 資料表' AS "檢查項目",
    COUNT(*) AS "總訂單數",
    COUNT(CASE WHEN vehicle_type IN ('small', 'large') THEN 1 END) AS "正確的訂單數",
    COUNT(CASE WHEN vehicle_type NOT IN ('small', 'large') THEN 1 END) AS "錯誤的訂單數"
FROM bookings;

SELECT 
    '驗證 drivers 資料表' AS "檢查項目",
    COUNT(*) AS "總司機數",
    COUNT(CASE WHEN vehicle_type IN ('small', 'large') THEN 1 END) AS "正確的司機數",
    COUNT(CASE WHEN vehicle_type NOT IN ('small', 'large') THEN 1 END) AS "錯誤的司機數"
FROM drivers;

-- ========================================
-- 第三部分：添加新的 CHECK 約束
-- ========================================

SELECT '========================================' AS "步驟";
SELECT '第三部分：添加新的 CHECK 約束' AS "步驟";
SELECT '========================================' AS "步驟";

-- 添加 drivers 資料表的新 CHECK 約束
ALTER TABLE drivers ADD CONSTRAINT drivers_vehicle_type_check 
CHECK (vehicle_type IN ('A', 'B', 'C', 'D', 'small', 'large'));

-- 添加 bookings 資料表的新 CHECK 約束
ALTER TABLE bookings ADD CONSTRAINT bookings_vehicle_type_check 
CHECK (vehicle_type IN ('A', 'B', 'C', 'D', 'small', 'large'));

SELECT '✅ 新的 CHECK 約束已添加' AS "結果";

-- 驗證新的 CHECK 約束
SELECT 
    'drivers' AS "資料表",
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'drivers'::regclass
  AND contype = 'c'
  AND conname = 'drivers_vehicle_type_check'

UNION ALL

SELECT 
    'bookings' AS "資料表",
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND contype = 'c'
  AND conname = 'bookings_vehicle_type_check';

-- ========================================
-- 完成
-- ========================================

SELECT '========================================' AS "步驟";
SELECT '🎉 修復完成！' AS "步驟";
SELECT '========================================' AS "步驟";

SELECT 
    '所有 vehicle_type 已更新為 small 或 large' AS "結果",
    'CHECK 約束已更新，支援 small 和 large' AS "結果2",
    '請重新測試手動派單功能' AS "下一步";

-- 最終驗證：顯示所有訂單和司機的 vehicle_type
SELECT 
    '最終驗證 - bookings' AS "檢查項目";

SELECT 
    id AS "訂單 ID",
    booking_number AS "訂單編號",
    vehicle_type AS "車型",
    status AS "狀態",
    CASE 
        WHEN vehicle_type IN ('small', 'large') THEN '✅ 正確'
        ELSE '❌ 錯誤'
    END AS "檢查結果"
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

SELECT 
    '最終驗證 - drivers' AS "檢查項目";

SELECT 
    u.email AS "Email",
    d.vehicle_type AS "車型",
    d.vehicle_plate AS "車牌號",
    d.is_available AS "是否可用",
    CASE 
        WHEN d.vehicle_type IN ('small', 'large') THEN '✅ 正確'
        ELSE '❌ 錯誤'
    END AS "檢查結果"
FROM users u
INNER JOIN drivers d ON u.id = d.user_id
WHERE u.role = 'driver';

