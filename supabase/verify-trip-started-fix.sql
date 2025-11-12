-- ========================================
-- 驗證 trip_started 狀態修復
-- ========================================
-- 
-- 用途：驗證 Edge Function 部署後，trip_started 事件是否正確同步到 Firestore
-- 執行時機：Edge Function 部署後
-- 執行位置：Supabase SQL Editor
--
-- ========================================

-- 步驟 1: 查看最近的 trip_started 訂單
-- ========================================

SELECT 
    id,
    booking_number,
    status,
    actual_start_time,
    updated_at,
    CASE 
        WHEN status = 'trip_started' THEN '✅ 狀態正確'
        ELSE '❌ 狀態錯誤'
    END as status_check
FROM bookings
WHERE status = 'trip_started'
ORDER BY updated_at DESC
LIMIT 5;

-- 預期結果：
-- - 應該看到 status = 'trip_started' 的訂單
-- - status_check 應該是 '✅ 狀態正確'


-- 步驟 2: 查看對應的 Outbox 事件
-- ========================================

SELECT 
    id,
    aggregate_id,
    event_type,
    payload->>'status' as status,
    created_at,
    processed_at,
    CASE 
        WHEN processed_at IS NOT NULL THEN '✅ 已處理'
        ELSE '⏳ 未處理'
    END as processing_status,
    error_message
FROM outbox
WHERE payload->>'status' = 'trip_started'
ORDER BY created_at DESC
LIMIT 10;

-- 預期結果：
-- - 應該看到 status = 'trip_started' 的事件
-- - processing_status 應該是 '✅ 已處理'
-- - error_message 應該是 NULL


-- 步驟 3: 檢查是否有未處理的 trip_started 事件
-- ========================================

SELECT 
    COUNT(*) as unprocessed_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 沒有未處理事件'
        ELSE '⚠️ 有未處理事件，等待 Edge Function 處理'
    END as status
FROM outbox
WHERE payload->>'status' = 'trip_started'
  AND processed_at IS NULL;

-- 預期結果：
-- - unprocessed_count 應該是 0
-- - status 應該是 '✅ 沒有未處理事件'


-- 步驟 4: 查看最近處理的事件（所有狀態）
-- ========================================

SELECT 
    id,
    aggregate_id,
    event_type,
    payload->>'status' as status,
    created_at,
    processed_at,
    EXTRACT(EPOCH FROM (processed_at - created_at)) as processing_time_seconds,
    error_message
FROM outbox
WHERE processed_at IS NOT NULL
ORDER BY processed_at DESC
LIMIT 20;

-- 預期結果：
-- - 應該看到各種狀態的事件都被處理了
-- - processing_time_seconds 應該在 60 秒左右（Cron Job 每分鐘執行一次）
-- - error_message 應該是 NULL


-- 步驟 5: 統計各狀態的處理情況
-- ========================================

SELECT 
    payload->>'status' as status,
    COUNT(*) as total_events,
    COUNT(CASE WHEN processed_at IS NOT NULL THEN 1 END) as processed_events,
    COUNT(CASE WHEN processed_at IS NULL THEN 1 END) as unprocessed_events,
    COUNT(CASE WHEN error_message IS NOT NULL THEN 1 END) as error_events,
    ROUND(
        COUNT(CASE WHEN processed_at IS NOT NULL THEN 1 END)::numeric / 
        COUNT(*)::numeric * 100, 
        2
    ) as processing_rate_percent
FROM outbox
GROUP BY payload->>'status'
ORDER BY total_events DESC;

-- 預期結果：
-- - trip_started 的 processing_rate_percent 應該接近 100%
-- - error_events 應該是 0


-- ========================================
-- 手動觸發測試（可選）
-- ========================================

-- 如果需要手動測試，可以將某個 trip_started 事件標記為未處理
-- 然後等待 Edge Function 重新處理

-- ⚠️ 警告：只在測試環境執行！

-- 取消註釋以下代碼來手動測試：

/*
-- 1. 找出一個 trip_started 訂單
SELECT id, booking_number, status
FROM bookings
WHERE status = 'trip_started'
ORDER BY updated_at DESC
LIMIT 1;

-- 2. 將對應的 Outbox 事件標記為未處理
-- 替換 'YOUR_BOOKING_ID' 為實際的訂單 ID
UPDATE outbox
SET processed_at = NULL
WHERE aggregate_id = 'YOUR_BOOKING_ID'
  AND payload->>'status' = 'trip_started';

-- 3. 等待 1-2 分鐘，讓 Edge Function 重新處理

-- 4. 檢查處理結果
SELECT 
    id,
    aggregate_id,
    payload->>'status' as status,
    created_at,
    processed_at,
    error_message
FROM outbox
WHERE aggregate_id = 'YOUR_BOOKING_ID'
  AND payload->>'status' = 'trip_started';

-- 5. 檢查 Firestore 狀態
-- 在 Firebase Console 中查看 bookings/{bookingId} 的 status 欄位
-- 應該是：inProgress（不是 pending）
*/


-- ========================================
-- 診斷問題（如果修復失敗）
-- ========================================

-- 如果 Firestore 狀態仍然是 pending，執行以下診斷：

-- 1. 檢查 Edge Function 是否有錯誤
SELECT 
    id,
    aggregate_id,
    payload->>'status' as status,
    error_message,
    retry_count,
    processed_at
FROM outbox
WHERE payload->>'status' = 'trip_started'
  AND error_message IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- 2. 檢查是否有重複的事件
SELECT 
    aggregate_id,
    payload->>'status' as status,
    COUNT(*) as event_count,
    CASE 
        WHEN COUNT(*) > 1 THEN '⚠️ 有重複事件'
        ELSE '✅ 沒有重複'
    END as duplicate_check
FROM outbox
WHERE payload->>'status' = 'trip_started'
GROUP BY aggregate_id, payload->>'status'
HAVING COUNT(*) > 1;

-- 3. 檢查 Edge Function 部署時間
-- 需要在 Supabase Dashboard 中查看：
-- https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
-- 查看 sync-to-firestore 的最後部署時間
-- 應該是最近的時間（幾分鐘內）


-- ========================================
-- 總結
-- ========================================

-- ✅ 如果所有檢查都通過：
--    - trip_started 事件被正確處理
--    - 沒有錯誤訊息
--    - Firestore 狀態是 inProgress
--    → 修復成功！

-- ❌ 如果仍有問題：
--    1. 檢查 Edge Function 日誌
--    2. 確認部署時間是最近的
--    3. 查看是否有錯誤訊息
--    4. 聯繫開發團隊

-- ========================================

