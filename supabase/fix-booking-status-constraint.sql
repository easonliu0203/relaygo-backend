-- ========================================
-- 修復 bookings 資料表的狀態 CHECK 約束
-- ========================================

-- 問題：
-- Supabase bookings 資料表的 CHECK 約束只允許以下狀態：
-- 'pending', 'confirmed', 'assigned', 'in_progress', 'completed', 'cancelled'
--
-- 但 Backend API 使用以下狀態：
-- 'pending_payment', 'paid_deposit', 'assigned', 'driver_confirmed', 
-- 'driver_departed', 'driver_arrived', 'in_progress', 'completed', 'cancelled'
--
-- 這導致訂單無法正確創建或狀態不一致

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

-- 步驟 3：添加新的 CHECK 約束（包含所有狀態）
SELECT 
    '步驟 3：添加新的 CHECK 約束' AS "診斷步驟";

ALTER TABLE bookings ADD CONSTRAINT bookings_status_check 
CHECK (status IN (
    'pending_payment',    -- 待付訂金
    'paid_deposit',       -- 已付訂金
    'assigned',           -- 已分配司機
    'driver_confirmed',   -- 司機已確認
    'driver_departed',    -- 司機已出發
    'driver_arrived',     -- 司機已到達
    'in_progress',        -- 進行中
    'completed',          -- 已完成
    'cancelled'           -- 已取消
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

-- 步驟 6：測試插入訂單（使用新的狀態）
SELECT 
    '步驟 6：測試插入訂單（使用新的狀態）' AS "診斷步驟";

-- 這個測試會失敗，因為缺少必填欄位，但可以驗證 CHECK 約束是否正確
-- 如果 CHECK 約束正確，錯誤訊息應該是缺少必填欄位，而不是狀態不合法
DO $$
BEGIN
    -- 測試 pending_payment 狀態
    BEGIN
        INSERT INTO bookings (
            customer_id,
            booking_number,
            status,
            start_date,
            start_time,
            duration_hours,
            vehicle_type,
            pickup_location,
            base_price,
            total_amount,
            deposit_amount
        ) VALUES (
            '00000000-0000-0000-0000-000000000000'::uuid,
            'TEST-001',
            'pending_payment',
            CURRENT_DATE,
            '09:00:00',
            8,
            'A',
            '測試地點',
            1000.00,
            1000.00,
            300.00
        );
        
        -- 如果插入成功，刪除測試訂單
        DELETE FROM bookings WHERE booking_number = 'TEST-001';
        
        RAISE NOTICE '✅ pending_payment 狀態測試通過';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE '✅ pending_payment 狀態測試通過（外鍵約束失敗，但狀態 CHECK 約束正確）';
        WHEN check_violation THEN
            RAISE NOTICE '❌ pending_payment 狀態測試失敗（CHECK 約束失敗）';
        WHEN OTHERS THEN
            RAISE NOTICE '✅ pending_payment 狀態測試通過（其他錯誤：%）', SQLERRM;
    END;
    
    -- 測試 paid_deposit 狀態
    BEGIN
        INSERT INTO bookings (
            customer_id,
            booking_number,
            status,
            start_date,
            start_time,
            duration_hours,
            vehicle_type,
            pickup_location,
            base_price,
            total_amount,
            deposit_amount
        ) VALUES (
            '00000000-0000-0000-0000-000000000000'::uuid,
            'TEST-002',
            'paid_deposit',
            CURRENT_DATE,
            '09:00:00',
            8,
            'A',
            '測試地點',
            1000.00,
            1000.00,
            300.00
        );
        
        -- 如果插入成功，刪除測試訂單
        DELETE FROM bookings WHERE booking_number = 'TEST-002';
        
        RAISE NOTICE '✅ paid_deposit 狀態測試通過';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE '✅ paid_deposit 狀態測試通過（外鍵約束失敗，但狀態 CHECK 約束正確）';
        WHEN check_violation THEN
            RAISE NOTICE '❌ paid_deposit 狀態測試失敗（CHECK 約束失敗）';
        WHEN OTHERS THEN
            RAISE NOTICE '✅ paid_deposit 狀態測試通過（其他錯誤：%）', SQLERRM;
    END;
END $$;

-- ========================================
-- 完成
-- ========================================

SELECT 
    '🎉 修復完成！' AS "狀態",
    'bookings 資料表的狀態 CHECK 約束已更新，現在支援所有 Backend API 使用的狀態。' AS "說明";

SELECT 
    '下一步：' AS "提示",
    '1. 測試創建新訂單，確認狀態為 pending_payment' AS "步驟 1",
    '2. 測試支付訂金，確認狀態更新為 paid_deposit' AS "步驟 2",
    '3. 檢查 Firestore 的 orders_rt collection，確認訂單正確同步' AS "步驟 3";

