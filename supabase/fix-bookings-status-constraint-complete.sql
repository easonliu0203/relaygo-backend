-- ========================================
-- 修復 bookings_status_check 約束問題
-- ========================================
--
-- 問題：手動派單時，Backend API 將訂單狀態更新為 'matched'
-- 但 bookings_status_check 約束不允許 'matched' 這個值
--
-- 解決方案：更新 CHECK 約束，包含所有 Backend API 和 Flutter APP 使用的狀態值
--
-- ========================================

-- 步驟 1：檢查當前的 bookings_status_check 約束
SELECT 
    '步驟 1：檢查當前的 bookings_status_check 約束' AS "診斷步驟";

SELECT 
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND contype = 'c'
  AND conname = 'bookings_status_check';

-- 步驟 2：檢查當前訂單使用的所有狀態值
SELECT 
    '步驟 2：檢查當前訂單使用的所有狀態值' AS "診斷步驟";

SELECT DISTINCT 
    status AS "訂單狀態",
    COUNT(*) AS "訂單數量"
FROM bookings
GROUP BY status
ORDER BY status;

-- 步驟 3：刪除舊的 CHECK 約束
SELECT 
    '步驟 3：刪除舊的 CHECK 約束' AS "診斷步驟";

ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;

SELECT '✅ 舊的 CHECK 約束已刪除' AS "結果";

-- 步驟 4：添加新的 CHECK 約束（包含所有狀態）
SELECT 
    '步驟 4：添加新的 CHECK 約束' AS "診斷步驟";

-- 包含所有可能的狀態值：
-- Backend API 使用的狀態：
--   - pending_payment (待付訂金)
--   - paid_deposit (已付訂金)
--   - assigned (已分配司機)
--   - driver_confirmed (司機已確認)
--   - driver_departed (司機已出發)
--   - driver_arrived (司機已到達)
--   - in_progress (進行中)
--   - completed (已完成)
--   - cancelled (已取消)
--
-- Flutter APP 使用的狀態：
--   - pending (待配對)
--   - matched (已配對) ← 這個狀態導致錯誤
--   - inProgress (進行中)
--   - completed (已完成)
--   - cancelled (已取消)
--
-- 舊的狀態（向後兼容）：
--   - pending, confirmed, assigned, in_progress, completed, cancelled

ALTER TABLE bookings ADD CONSTRAINT bookings_status_check 
CHECK (status IN (
    -- Backend API 狀態
    'pending_payment',
    'paid_deposit',
    'assigned',
    'driver_confirmed',
    'driver_departed',
    'driver_arrived',
    'in_progress',
    'completed',
    'cancelled',
    -- Flutter APP 狀態
    'pending',
    'matched',
    'inProgress',
    -- 舊的狀態（向後兼容）
    'confirmed'
));

SELECT '✅ 新的 CHECK 約束已添加' AS "結果";

-- 步驟 5：驗證新的 CHECK 約束
SELECT 
    '步驟 5：驗證新的 CHECK 約束' AS "診斷步驟";

SELECT 
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND contype = 'c'
  AND conname = 'bookings_status_check';

-- 步驟 6：測試更新訂單狀態為 'matched'
SELECT 
    '步驟 6：測試更新訂單狀態為 matched' AS "診斷步驟";

-- 這個測試會嘗試將一個訂單的狀態更新為 'matched'
-- 如果 CHECK 約束正確，這個更新應該成功

-- 注意：這只是一個測試，不會實際更新訂單
-- 如果您想測試，請取消註釋以下 SQL：

-- UPDATE bookings
-- SET status = 'matched', updated_at = NOW()
-- WHERE id = (SELECT id FROM bookings ORDER BY created_at DESC LIMIT 1)
-- RETURNING id, booking_number, status;

SELECT '⚠️ 測試 SQL 已註釋，如需測試請取消註釋' AS "提示";

-- 步驟 7：檢查所有訂單的狀態是否符合新約束
SELECT 
    '步驟 7：檢查所有訂單的狀態是否符合新約束' AS "診斷步驟";

SELECT 
    id AS "訂單 ID",
    booking_number AS "訂單編號",
    status AS "狀態",
    CASE 
        WHEN status IN (
            'pending_payment', 'paid_deposit', 'assigned', 'driver_confirmed',
            'driver_departed', 'driver_arrived', 'in_progress', 'completed', 'cancelled',
            'pending', 'matched', 'inProgress', 'confirmed'
        ) THEN '✅ 符合約束'
        ELSE '❌ 不符合約束'
    END AS "檢查結果"
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

-- 步驟 8：統計各狀態的訂單數量
SELECT 
    '步驟 8：統計各狀態的訂單數量' AS "診斷步驟";

SELECT 
    status AS "訂單狀態",
    COUNT(*) AS "訂單數量",
    CASE 
        WHEN status IN (
            'pending_payment', 'paid_deposit', 'assigned', 'driver_confirmed',
            'driver_departed', 'driver_arrived', 'in_progress', 'completed', 'cancelled',
            'pending', 'matched', 'inProgress', 'confirmed'
        ) THEN '✅ 符合約束'
        ELSE '❌ 不符合約束'
    END AS "檢查結果"
FROM bookings
GROUP BY status
ORDER BY status;

-- ========================================
-- 完成
-- ========================================

SELECT '========================================' AS "步驟";
SELECT '🎉 修復完成！' AS "步驟";
SELECT '========================================' AS "步驟";

SELECT 
    'bookings_status_check 約束已更新' AS "結果",
    '現在支援所有 Backend API 和 Flutter APP 使用的狀態值' AS "結果2",
    '包括: pending_payment, paid_deposit, assigned, matched, inProgress 等' AS "結果3",
    '請重新測試手動派單功能' AS "下一步";

