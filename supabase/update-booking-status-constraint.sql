-- ========================================
-- 更新 bookings 資料表的狀態 CHECK 約束
-- 添加 'matched' 狀態支援
-- ========================================

-- 問題：
-- 當前的 CHECK 約束缺少 'matched' 狀態
-- 需要添加此狀態以支援公司端手動派單功能

-- 步驟 1：檢查當前的 CHECK 約束
SELECT 
    '步驟 1：檢查當前的 CHECK 約束' AS "診斷步驟";

SELECT 
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND contype = 'c'
  AND conname LIKE '%status%';

-- 步驟 2：刪除舊的 CHECK 約束
SELECT 
    '步驟 2：刪除舊的 CHECK 約束' AS "診斷步驟";

ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;

-- 步驟 3：添加新的 CHECK 約束（包含 matched 狀態）
SELECT 
    '步驟 3：添加新的 CHECK 約束' AS "診斷步驟";

ALTER TABLE bookings ADD CONSTRAINT bookings_status_check 
CHECK (status IN (
    'pending_payment',    -- 待付訂金
    'paid_deposit',       -- 已付訂金
    'matched',            -- 已配對（公司端手動派單）
    'assigned',           -- 已分配司機（保留向後兼容）
    'driver_confirmed',   -- 司機已確認
    'driver_departed',    -- 司機已出發
    'driver_arrived',     -- 司機已到達
    'in_progress',        -- 進行中
    'trip_started',       -- 行程開始
    'trip_ended',         -- 行程結束
    'pending_balance',    -- 待付尾款
    'completed',          -- 已完成
    'cancelled',          -- 已取消
    'refunded'            -- 已退款
));

-- 步驟 4：驗證新的 CHECK 約束
SELECT 
    '步驟 4：驗證新的 CHECK 約束' AS "診斷步驟";

SELECT 
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND contype = 'c'
  AND conname LIKE '%status%';

-- 步驟 5：檢查現有訂單的狀態
SELECT 
    '步驟 5：檢查現有訂單的狀態' AS "診斷步驟";

SELECT 
    status AS "訂單狀態",
    COUNT(*) AS "訂單數量"
FROM bookings
GROUP BY status
ORDER BY COUNT(*) DESC;

-- ========================================
-- 完成
-- ========================================

SELECT 
    '🎉 更新完成！' AS "狀態",
    'bookings 資料表的狀態 CHECK 約束已更新，現在支援 matched 狀態。' AS "說明";

SELECT 
    '支援的狀態：' AS "提示",
    'pending_payment, paid_deposit, matched, assigned, driver_confirmed, driver_departed, driver_arrived, in_progress, trip_started, trip_ended, pending_balance, completed, cancelled, refunded' AS "狀態列表";

