-- ============================================
-- 診斷同步問題
-- 檢查訂單是否成功同步到 Firestore
-- ============================================

-- 檢查 1: 最近的訂單和對應的 Outbox 事件
-- ============================================
SELECT '=== 檢查 1: 最近的訂單和同步狀態 ===' as info;

SELECT 
  b.id as booking_id,
  b.booking_number,
  b.status as booking_status,
  b.created_at as booking_created,
  o.id as event_id,
  o.event_type,
  o.created_at as event_created,
  o.processed_at as event_processed,
  CASE 
    WHEN o.processed_at IS NOT NULL THEN '✅ 已同步'
    WHEN o.processed_at IS NULL AND EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 60 THEN '⏳ 等待中 (< 1分鐘)'
    WHEN o.processed_at IS NULL AND EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 120 THEN '⚠️ 延遲 (1-2分鐘)'
    WHEN o.processed_at IS NULL THEN '❌ 卡住了 (> 2分鐘)'
    ELSE '❓ 未知狀態'
  END as sync_status,
  EXTRACT(EPOCH FROM (NOW() - o.created_at))::INTEGER as seconds_since_event,
  o.error_message
FROM bookings b
LEFT JOIN outbox o ON o.payload->>'id' = b.id::TEXT
WHERE b.created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY b.created_at DESC;

-- 檢查 2: Outbox 事件詳情
-- ============================================
SELECT '=== 檢查 2: Outbox 事件詳情 ===' as info;

SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'id' as booking_id,
  payload->>'bookingNumber' as booking_number,
  payload->>'customerId' as customer_id,
  payload->>'status' as status,
  created_at,
  processed_at,
  error_message,
  retry_count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC;

-- 檢查 3: Cron Job 執行記錄
-- ============================================
SELECT '=== 檢查 3: Cron Job 最近執行記錄 ===' as info;

SELECT 
  jobname,
  runid,
  job_pid,
  database,
  username,
  command,
  status,
  return_message,
  start_time,
  end_time,
  EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER as duration_seconds
FROM cron.job_run_details
WHERE jobname = 'sync-orders-to-firestore'
ORDER BY start_time DESC
LIMIT 10;

-- 檢查 4: Cron Job 配置
-- ============================================
SELECT '=== 檢查 4: Cron Job 配置 ===' as info;

SELECT 
  jobid,
  jobname,
  schedule,
  command,
  nodename,
  nodeport,
  database,
  username,
  active,
  jobname
FROM cron.job
WHERE jobname = 'sync-orders-to-firestore';

-- 檢查 5: 未處理的事件統計
-- ============================================
SELECT '=== 檢查 5: 未處理事件統計 ===' as info;

SELECT 
  COUNT(*) as total_unprocessed,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 minute') as last_1min,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '5 minutes' AND created_at < NOW() - INTERVAL '1 minute') as last_1_5min,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '10 minutes' AND created_at < NOW() - INTERVAL '5 minutes') as last_5_10min,
  COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '10 minutes') as older_than_10min,
  MIN(created_at) as oldest_unprocessed,
  MAX(created_at) as newest_unprocessed
FROM outbox
WHERE processed_at IS NULL;

-- 檢查 6: 錯誤事件
-- ============================================
SELECT '=== 檢查 6: 有錯誤的事件 ===' as info;

SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  error_message,
  retry_count,
  EXTRACT(EPOCH FROM (NOW() - created_at))::INTEGER as seconds_ago
FROM outbox
WHERE error_message IS NOT NULL
  AND created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- ============================================
-- 診斷結果解讀
-- ============================================

/*
結果解讀指南：

檢查 1: 最近的訂單和同步狀態
- 如果 sync_status = '✅ 已同步' → 同步成功，問題在客戶端
- 如果 sync_status = '⏳ 等待中' → 正常，等待 Cron Job 執行
- 如果 sync_status = '⚠️ 延遲' → Cron Job 可能有問題
- 如果 sync_status = '❌ 卡住了' → Cron Job 或 Edge Function 有問題

檢查 2: Outbox 事件詳情
- 檢查 payload 是否包含所有必要欄位
- 檢查 error_message 是否有錯誤
- 檢查 retry_count 是否過高

檢查 3: Cron Job 執行記錄
- 如果沒有記錄 → Cron Job 沒有執行
- 如果 status = 'failed' → 檢查 return_message
- 如果 duration_seconds 很長 → 可能有性能問題

檢查 4: Cron Job 配置
- 檢查 active = true
- 檢查 schedule 是否正確（應該是每 30 秒）
- 檢查 command 是否正確

檢查 5: 未處理事件統計
- 如果 total_unprocessed > 0 且 older_than_10min > 0 → 有積壓
- 如果 last_1min > 0 → 正常，剛創建的事件

檢查 6: 錯誤事件
- 如果有錯誤 → 檢查 error_message
- 常見錯誤：
  * 權限問題
  * Firestore 連接問題
  * 資料格式問題
  * Edge Function 錯誤

常見問題和解決方案：

問題 A: processed_at 是 NULL，Cron Job 沒有執行記錄
→ Cron Job 沒有設置或被禁用
→ 解決：執行 setup-cron-jobs.sql

問題 B: processed_at 是 NULL，Cron Job 有執行但 status = 'failed'
→ Edge Function 有錯誤
→ 解決：檢查 Edge Function 日誌，修復錯誤

問題 C: processed_at 有值，但客戶端顯示「訂單不存在」
→ 客戶端使用錯誤的 ID 或 Firestore 讀取有問題
→ 解決：檢查客戶端代碼和 Firestore 權限

問題 D: error_message 顯示權限錯誤
→ Edge Function 沒有 Firestore 寫入權限
→ 解決：檢查 Firebase Service Account 配置

問題 E: 事件積壓（older_than_10min > 0）
→ Cron Job 執行頻率不夠或 Edge Function 太慢
→ 解決：增加執行頻率或優化 Edge Function
*/

