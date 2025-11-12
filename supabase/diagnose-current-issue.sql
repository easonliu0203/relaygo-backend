-- ============================================
-- 診斷當前同步問題
-- 執行時間：2025-10-05
-- ============================================

\echo '=== 檢查 1: 最近 30 分鐘的 Outbox 事件 ==='
\echo ''

SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'id' as booking_id,
  payload->>'bookingNumber' as booking_number,
  created_at,
  processed_at,
  error_message,
  retry_count,
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已同步'
    WHEN processed_at IS NULL AND EXTRACT(EPOCH FROM (NOW() - created_at)) < 60 THEN '⏳ 等待中 (< 1分鐘)'
    WHEN processed_at IS NULL AND EXTRACT(EPOCH FROM (NOW() - created_at)) < 120 THEN '⚠️ 延遲 (1-2分鐘)'
    WHEN processed_at IS NULL THEN '❌ 卡住了 (> 2分鐘)'
  END as sync_status,
  EXTRACT(EPOCH FROM (NOW() - created_at))::INTEGER as seconds_since_created
FROM outbox
WHERE created_at >= NOW() - INTERVAL '30 minutes'
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo '=== 檢查 2: 最近的訂單記錄 ==='
\echo ''

SELECT 
  b.id,
  b.booking_number,
  b.status,
  b.customer_id,
  b.total_amount,
  b.created_at,
  CASE 
    WHEN o.id IS NOT NULL THEN '✅ 有事件'
    ELSE '❌ 無事件'
  END as has_event,
  o.processed_at,
  CASE 
    WHEN o.processed_at IS NOT NULL THEN '✅ 已同步'
    WHEN o.processed_at IS NULL AND o.id IS NOT NULL THEN '❌ 未同步'
    ELSE '❓ 無事件'
  END as sync_status
FROM bookings b
LEFT JOIN outbox o ON o.payload->>'id' = b.id::TEXT
WHERE b.created_at >= NOW() - INTERVAL '30 minutes'
ORDER BY b.created_at DESC
LIMIT 10;

\echo ''
\echo '=== 檢查 3: Cron Job 執行記錄 ==='
\echo ''

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
LIMIT 10;

\echo ''
\echo '=== 檢查 4: Cron Job 配置 ==='
\echo ''

SELECT 
  jobid,
  jobname,
  schedule,
  active,
  database,
  username
FROM cron.job
WHERE jobname = 'sync-orders-to-firestore';

\echo ''
\echo '=== 檢查 5: 未處理事件統計 ==='
\echo ''

SELECT 
  aggregate_type,
  COUNT(*) as total_events,
  COUNT(*) FILTER (WHERE processed_at IS NOT NULL) as processed,
  COUNT(*) FILTER (WHERE processed_at IS NULL) as pending,
  COUNT(*) FILTER (WHERE error_message IS NOT NULL) as errors,
  MIN(created_at) as oldest_pending,
  MAX(created_at) as newest_pending
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour'
GROUP BY aggregate_type;

\echo ''
\echo '=== 檢查 6: 錯誤事件詳情 ==='
\echo ''

SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  error_message,
  retry_count
FROM outbox
WHERE error_message IS NOT NULL
  AND created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;

\echo ''
\echo '=== 診斷總結 ==='
\echo ''

DO $$
DECLARE
  total_bookings INTEGER;
  total_events INTEGER;
  processed_events INTEGER;
  pending_events INTEGER;
  error_events INTEGER;
  has_cron_job BOOLEAN;
  cron_last_run TIMESTAMP;
  cron_status TEXT;
BEGIN
  -- 統計訂單
  SELECT COUNT(*) INTO total_bookings
  FROM bookings
  WHERE created_at >= NOW() - INTERVAL '30 minutes';

  -- 統計事件
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE processed_at IS NOT NULL),
    COUNT(*) FILTER (WHERE processed_at IS NULL),
    COUNT(*) FILTER (WHERE error_message IS NOT NULL)
  INTO total_events, processed_events, pending_events, error_events
  FROM outbox
  WHERE created_at >= NOW() - INTERVAL '30 minutes';

  -- 檢查 Cron Job
  SELECT EXISTS(
    SELECT 1 FROM cron.job WHERE jobname = 'sync-orders-to-firestore'
  ) INTO has_cron_job;

  -- 最近執行時間
  SELECT MAX(start_time), MAX(status)
  INTO cron_last_run, cron_status
  FROM cron.job_run_details
  WHERE jobname = 'sync-orders-to-firestore';

  -- 輸出診斷結果
  RAISE NOTICE '';
  RAISE NOTICE '📊 診斷結果摘要:';
  RAISE NOTICE '================';
  RAISE NOTICE '';
  RAISE NOTICE '訂單統計（最近 30 分鐘）:';
  RAISE NOTICE '  總訂單數: %', total_bookings;
  RAISE NOTICE '';
  RAISE NOTICE '事件統計（最近 30 分鐘）:';
  RAISE NOTICE '  總事件數: %', total_events;
  RAISE NOTICE '  已處理: %', processed_events;
  RAISE NOTICE '  待處理: %', pending_events;
  RAISE NOTICE '  錯誤: %', error_events;
  RAISE NOTICE '';
  RAISE NOTICE 'Cron Job 狀態:';
  RAISE NOTICE '  已配置: %', CASE WHEN has_cron_job THEN '✅ 是' ELSE '❌ 否' END;
  IF cron_last_run IS NOT NULL THEN
    RAISE NOTICE '  最近執行: % (% 前)', cron_last_run, 
      EXTRACT(EPOCH FROM (NOW() - cron_last_run))::INTEGER || ' 秒';
    RAISE NOTICE '  執行狀態: %', cron_status;
  ELSE
    RAISE NOTICE '  最近執行: ❌ 無記錄';
  END IF;
  RAISE NOTICE '';

  -- 診斷建議
  IF total_bookings = 0 THEN
    RAISE NOTICE '⚠️  診斷: 最近 30 分鐘沒有新訂單';
    RAISE NOTICE '   建議: 創建新訂單測試完整流程';
  ELSIF total_events = 0 THEN
    RAISE NOTICE '❌ 診斷: 有訂單但沒有事件！';
    RAISE NOTICE '   問題: Trigger 可能沒有正常工作';
    RAISE NOTICE '   建議: 檢查 Trigger 是否存在並啟用';
  ELSIF pending_events > 0 AND error_events = 0 THEN
    IF NOT has_cron_job THEN
      RAISE NOTICE '❌ 診斷: Cron Job 未配置！';
      RAISE NOTICE '   問題: 沒有自動同步機制';
      RAISE NOTICE '   建議: 設置 Cron Job 或手動觸發 Edge Function';
    ELSIF cron_last_run IS NULL THEN
      RAISE NOTICE '❌ 診斷: Cron Job 從未執行！';
      RAISE NOTICE '   問題: Cron Job 可能未啟用或配置錯誤';
      RAISE NOTICE '   建議: 檢查 Cron Job 配置並手動觸發測試';
    ELSIF EXTRACT(EPOCH FROM (NOW() - cron_last_run)) > 120 THEN
      RAISE NOTICE '⚠️  診斷: Cron Job 超過 2 分鐘未執行';
      RAISE NOTICE '   問題: Cron Job 可能停止工作';
      RAISE NOTICE '   建議: 檢查 Cron Job 狀態並手動觸發測試';
    ELSE
      RAISE NOTICE '⏳ 診斷: 事件等待處理中';
      RAISE NOTICE '   說明: Cron Job 正常，等待下次執行';
      RAISE NOTICE '   建議: 等待 30 秒或手動觸發 Edge Function';
    END IF;
  ELSIF error_events > 0 THEN
    RAISE NOTICE '❌ 診斷: 有錯誤事件！';
    RAISE NOTICE '   問題: Edge Function 執行失敗';
    RAISE NOTICE '   建議: 查看「檢查 6」的錯誤訊息';
    RAISE NOTICE '   建議: 檢查 Edge Function 日誌';
    RAISE NOTICE '   建議: 檢查環境變數（FIREBASE_PROJECT_ID, FIREBASE_API_KEY）';
  ELSIF processed_events = total_events THEN
    RAISE NOTICE '✅ 診斷: 所有事件都已處理！';
    RAISE NOTICE '   說明: 同步流程正常工作';
    RAISE NOTICE '   建議: 檢查 Firestore 是否有資料';
    RAISE NOTICE '   建議: 檢查 App 是否使用正確的訂單 ID';
  END IF;

  RAISE NOTICE '';
END $$;

