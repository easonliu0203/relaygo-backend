-- ========================================
-- 修復所有資料表的 vehicle_type CHECK 約束
-- ========================================

-- 步驟 1：檢查 drivers 資料表的 CHECK 約束
SELECT 
    '步驟 1：檢查 drivers 資料表的 CHECK 約束' AS "診斷步驟";

SELECT 
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'drivers'::regclass
  AND contype = 'c'
  AND conname LIKE '%vehicle_type%';

-- 步驟 2：檢查 bookings 資料表的 CHECK 約束
SELECT 
    '步驟 2：檢查 bookings 資料表的 CHECK 約束' AS "診斷步驟";

SELECT 
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND contype = 'c'
  AND conname LIKE '%vehicle_type%';

-- 步驟 3：刪除 drivers 資料表的舊 CHECK 約束
SELECT
    '步驟 3：刪除 drivers 資料表的舊 CHECK 約束' AS "診斷步驟";

ALTER TABLE drivers DROP CONSTRAINT IF EXISTS drivers_vehicle_type_check;

-- 步驟 4：刪除 bookings 資料表的舊 CHECK 約束
SELECT
    '步驟 4：刪除 bookings 資料表的舊 CHECK 約束' AS "診斷步驟";

ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_vehicle_type_check;

-- 步驟 5：更新 bookings 資料表的 vehicle_type（在添加約束之前）
SELECT
    '步驟 5：更新 bookings 資料表的 vehicle_type' AS "診斷步驟";

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

-- 步驟 6：更新 drivers 資料表的 vehicle_type（在添加約束之前）
SELECT
    '步驟 6：更新 drivers 資料表的 vehicle_type' AS "診斷步驟";

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

-- 步驟 7：驗證資料更新結果 - bookings
SELECT
    '步驟 7：驗證資料更新結果 - bookings' AS "診斷步驟";

SELECT 
    id AS "訂單 ID",
    booking_number AS "訂單編號",
    vehicle_type AS "車型",
    status AS "狀態",
    CASE 
        WHEN vehicle_type IN ('small', 'large') THEN '✅ 車型正確'
        WHEN vehicle_type IN ('A', 'B', 'C', 'D') THEN '⚠️ 舊格式（需要更新）'
        ELSE '❌ 車型錯誤'
    END AS "檢查結果"
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

-- 步驟 8：驗證資料更新結果 - drivers
SELECT
    '步驟 8：驗證資料更新結果 - drivers' AS "診斷步驟";

SELECT 
    u.email AS "Email",
    d.vehicle_type AS "車型",
    d.vehicle_plate AS "車牌號",
    d.is_available AS "是否可用",
    CASE 
        WHEN d.vehicle_type IN ('small', 'large') THEN '✅ 車型正確'
        WHEN d.vehicle_type IN ('A', 'B', 'C', 'D') THEN '⚠️ 舊格式（需要更新）'
        ELSE '❌ 車型錯誤'
    END AS "檢查結果"
FROM users u
INNER JOIN drivers d ON u.id = d.user_id
WHERE u.role = 'driver';

-- 步驟 9：添加 drivers 資料表的新 CHECK 約束
SELECT
    '步驟 9：添加 drivers 資料表的新 CHECK 約束' AS "診斷步驟";

ALTER TABLE drivers ADD CONSTRAINT drivers_vehicle_type_check
CHECK (vehicle_type IN ('A', 'B', 'C', 'D', 'small', 'large'));

-- 步驟 10：添加 bookings 資料表的新 CHECK 約束
SELECT
    '步驟 10：添加 bookings 資料表的新 CHECK 約束' AS "診斷步驟";

ALTER TABLE bookings ADD CONSTRAINT bookings_vehicle_type_check
CHECK (vehicle_type IN ('A', 'B', 'C', 'D', 'small', 'large'));

-- 步驟 11：驗證新的 CHECK 約束
SELECT
    '步驟 11：驗證新的 CHECK 約束' AS "診斷步驟";

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

-- 步驟 12：檢查是否還有其他 vehicle_type 相關的約束
SELECT
    '步驟 12：檢查是否還有其他 vehicle_type 相關的約束' AS "診斷步驟";

SELECT 
    t.table_name AS "資料表",
    c.column_name AS "欄位",
    c.data_type AS "資料類型",
    c.character_maximum_length AS "最大長度",
    c.is_nullable AS "可為空"
FROM information_schema.columns c
JOIN information_schema.tables t ON c.table_name = t.table_name
WHERE c.column_name = 'vehicle_type'
  AND t.table_schema = 'public'
ORDER BY t.table_name;

-- ========================================
-- 完成
-- ========================================

SELECT 
    '🎉 所有資料表的 vehicle_type CHECK 約束已修復！' AS "狀態",
    '所有訂單和司機的 vehicle_type 已更新為 small 或 large。' AS "結果",
    '請重新測試手動派單功能。' AS "下一步";

