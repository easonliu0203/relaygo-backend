-- ========================================
-- 修復 drivers 資料表的 vehicle_type CHECK 約束
-- ========================================

-- 步驟 1：檢查當前的 CHECK 約束
SELECT 
    '步驟 1：檢查當前的 CHECK 約束' AS "診斷步驟";

SELECT 
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'drivers'::regclass
  AND contype = 'c';

-- 步驟 2：刪除舊的 CHECK 約束
SELECT 
    '步驟 2：刪除舊的 CHECK 約束' AS "診斷步驟";

ALTER TABLE drivers DROP CONSTRAINT IF EXISTS drivers_vehicle_type_check;

-- 步驟 3：添加新的 CHECK 約束（支援 'small' 和 'large'）
SELECT 
    '步驟 3：添加新的 CHECK 約束' AS "診斷步驟";

ALTER TABLE drivers ADD CONSTRAINT drivers_vehicle_type_check 
CHECK (vehicle_type IN ('A', 'B', 'C', 'D', 'small', 'large'));

-- 步驟 4：驗證新的 CHECK 約束
SELECT 
    '步驟 4：驗證新的 CHECK 約束' AS "診斷步驟";

SELECT 
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'drivers'::regclass
  AND contype = 'c'
  AND conname = 'drivers_vehicle_type_check';

-- 步驟 5：現在可以安全地更新 vehicle_type
SELECT 
    '步驟 5：更新司機的 vehicle_type' AS "診斷步驟";

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

-- 步驟 6：驗證更新結果
SELECT 
    '步驟 6：驗證更新結果' AS "診斷步驟";

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

-- ========================================
-- 完成
-- ========================================

SELECT 
    '🎉 drivers 資料表的 vehicle_type CHECK 約束已修復！' AS "狀態",
    '現在可以執行 check-vehicle-type-issue.sql 的步驟 4 和步驟 5。' AS "下一步";

