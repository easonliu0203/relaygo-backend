-- ============================================
-- 自動化驗證腳本 - 檢查同步狀態
-- 執行此腳本以驗證 Edge Function 修復是否成功
-- ============================================

-- 設置輸出格式
\timing on

-- ============================================
-- 檢查 1: 最近的訂單和同步狀態
-- ============================================
\echo '=== 檢查 1: 最近的訂單和同步狀態 ==='

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
WHERE b.created_at >= NOW() - INTERVAL '1 hour'
ORDER BY b.created_at DESC
LIMIT 5;

\echo ''
\echo '解讀：'
\echo '- 如果 sync_status = ✅ 已同步 → 成功！'
\echo '- 如果 sync_status = ⏳ 等待中 → 正常，等待 Cron Job'
\echo '- 如果 sync_status = ❌ 卡住了 → 有問題，檢查錯誤'
\echo ''

-- ============================================
-- 檢查 2: 同步統計
-- ============================================
\echo '=== 檢查 2: 同步統計（最近 1 小時）==='

SELECT 
  COUNT(*) as total_events,
  COUNT(*) FILTER (WHERE processed_at IS NOT NULL) as synced_count,
  COUNT(*) FILTER (WHERE processed_at IS NULL) as pending_count,
  COUNT(*) FILTER (WHERE error_message IS NOT NULL) as error_count,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE processed_at IS NOT NULL) / NULLIF(COUNT(*), 0),
    2
  ) as sync_percentage
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour';

\echo ''
\echo '解讀：'
\echo '- sync_percentage = 100% → 完美！'
\echo '- sync_percentage > 80% → 良好'
\echo '- sync_percentage < 80% → 需要檢查'
\echo '- error_count > 0 → 有錯誤，需要處理'
\echo ''

-- ============================================
-- 檢查 3: 錯誤事件詳情
-- ============================================
\echo '=== 檢查 3: 錯誤事件（如果有）==='

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
ORDER BY created_at DESC
LIMIT 5;

\echo ''
\echo '解讀：'
\echo '- 如果沒有結果 → 太好了！沒有錯誤'
\echo '- 如果有結果 → 檢查 error_message 欄位'
\echo ''

-- ============================================
-- 檢查 4: Cron Job 最近執行
-- ============================================
\echo '=== 檢查 4: Cron Job 最近執行記錄 ==='

SELECT 
  jobname,
  start_time,
  end_time,
  status,
  return_message,
  EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER as duration_seconds
FROM cron.job_run_details
WHERE jobname = 'sync-orders-to-firestore'
ORDER BY start_time DESC
LIMIT 5;

\echo ''
\echo '解讀：'
\echo '- status = succeeded → Cron Job 正常執行'
\echo '- status = failed → 檢查 return_message'
\echo '- 如果沒有記錄 → Cron Job 可能未設置'
\echo ''

-- ============================================
-- 檢查 5: 最近未處理的事件
-- ============================================
\echo '=== 檢查 5: 未處理事件（如果有）==='

SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  EXTRACT(EPOCH FROM (NOW() - created_at))::INTEGER as seconds_waiting,
  retry_count
FROM outbox
WHERE processed_at IS NULL
  AND created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at ASC
LIMIT 5;

\echo ''
\echo '解讀：'
\echo '- 如果沒有結果 → 太好了！所有事件都已處理'
\echo '- 如果 seconds_waiting < 60 → 正常，等待 Cron Job'
\echo '- 如果 seconds_waiting > 120 → 有問題，需要檢查'
\echo ''

-- ============================================
-- 總結和建議
-- ============================================
\echo '=== 總結 ==='

DO $$
DECLARE
  total_events INTEGER;
  synced_count INTEGER;
  pending_count INTEGER;
  error_count INTEGER;
  sync_percentage NUMERIC;
  oldest_pending_seconds INTEGER;
BEGIN
  -- 統計數據
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE processed_at IS NOT NULL),
    COUNT(*) FILTER (WHERE processed_at IS NULL),
    COUNT(*) FILTER (WHERE error_message IS NOT NULL)
  INTO total_events, synced_count, pending_count, error_count
  FROM outbox
  WHERE created_at >= NOW() - INTERVAL '1 hour';

  -- 計算同步百分比
  IF total_events > 0 THEN
    sync_percentage := ROUND(100.0 * synced_count / total_events, 2);
  ELSE
    sync_percentage := 0;
  END IF;

  -- 最舊的未處理事件
  SELECT EXTRACT(EPOCH FROM (NOW() - MIN(created_at)))::INTEGER
  INTO oldest_pending_seconds
  FROM outbox
  WHERE processed_at IS NULL
    AND created_at >= NOW() - INTERVAL '1 hour';

  -- 輸出總結
  RAISE NOTICE '';
  RAISE NOTICE '📊 統計摘要（最近 1 小時）:';
  RAISE NOTICE '   總事件數: %', total_events;
  RAISE NOTICE '   已同步: %', synced_count;
  RAISE NOTICE '   待處理: %', pending_count;
  RAISE NOTICE '   錯誤: %', error_count;
  RAISE NOTICE '   同步率: %％', sync_percentage;
  RAISE NOTICE '';

  -- 判斷狀態
  IF total_events = 0 THEN
    RAISE NOTICE '⚠️  狀態: 最近 1 小時沒有新事件';
    RAISE NOTICE '   建議: 創建新訂單測試完整流程';
  ELSIF sync_percentage = 100 AND error_count = 0 THEN
    RAISE NOTICE '✅ 狀態: 完美！所有事件都已成功同步';
    RAISE NOTICE '   建議: 在 Firebase Console 檢查 Firestore';
    RAISE NOTICE '   建議: 在手機 App 測試訂單查看';
  ELSIF sync_percentage >= 80 AND error_count = 0 THEN
    RAISE NOTICE '✅ 狀態: 良好！大部分事件已同步';
    IF oldest_pending_seconds IS NOT NULL AND oldest_pending_seconds < 60 THEN
      RAISE NOTICE '   說明: 有 % 個事件等待處理（< 1 分鐘）', pending_count;
      RAISE NOTICE '   建議: 等待 30 秒後重新檢查';
    ELSE
      RAISE NOTICE '   建議: 檢查未處理事件';
    END IF;
  ELSIF error_count > 0 THEN
    RAISE NOTICE '❌ 狀態: 有錯誤！';
    RAISE NOTICE '   錯誤數: %', error_count;
    RAISE NOTICE '   建議: 檢查「檢查 3」的錯誤訊息';
    RAISE NOTICE '   建議: 查看 Edge Function 日誌';
  ELSE
    RAISE NOTICE '⚠️  狀態: 同步率較低';
    RAISE NOTICE '   同步率: %％', sync_percentage;
    RAISE NOTICE '   建議: 檢查 Cron Job 是否正常執行';
    RAISE NOTICE '   建議: 手動觸發 Edge Function 測試';
  END IF;

  RAISE NOTICE '';
END $$;

-- ============================================
-- 下一步建議
-- ============================================
\echo '=== 下一步建議 ==='
\echo ''
\echo '如果同步成功（✅）：'
\echo '1. 在 Firebase Console 檢查 Firestore orders_rt 集合'
\echo '2. 在手機 App 測試查看訂單詳情'
\echo '3. 創建新訂單測試完整流程'
\echo ''
\echo '如果有錯誤（❌）：'
\echo '1. 查看「檢查 3」的 error_message'
\echo '2. 在 Supabase Dashboard 查看 Edge Function 日誌'
\echo '3. 確認環境變數設置正確'
\echo '4. 參考 supabase/SYNC_FIX_TESTING_GUIDE.md 故障排除'
\echo ''
\echo '如果待處理（⏳）：'
\echo '1. 等待 30 秒（Cron Job 執行週期）'
\echo '2. 重新執行此驗證腳本'
\echo '3. 或手動觸發 Edge Function'
\echo ''

