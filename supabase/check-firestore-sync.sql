-- ============================================
-- 檢查 Firestore 同步狀態
-- ============================================
-- 
-- 用途：診斷為什麼 Edge Function 顯示成功但 Firestore 沒有資料
-- 
-- ============================================

-- 檢查 1: 最近創建的訂單和對應的 outbox 事件
SELECT 
  '=== 最近的訂單和 Outbox 事件 ===' as 檢查項目;

SELECT 
  b.id as 訂單ID,
  b.booking_number as 訂單編號,
  b.created_at as 訂單創建時間,
  o.id as 事件ID,
  o.event_type as 事件類型,
  o.created_at as 事件創建時間,
  o.processed_at as 處理時間,
  o.retry_count as 重試次數,
  o.error_message as 錯誤訊息,
  CASE 
    WHEN o.processed_at IS NOT NULL THEN '✅ 已處理'
    WHEN o.retry_count >= 3 THEN '❌ 已達最大重試次數'
    ELSE '⏳ 待處理'
  END as 狀態
FROM bookings b
LEFT JOIN outbox o ON o.aggregate_id = b.id::TEXT AND o.aggregate_type = 'booking'
WHERE b.created_at >= NOW() - INTERVAL '1 hour'
ORDER BY b.created_at DESC
LIMIT 10;

-- 檢查 2: Outbox 事件統計
SELECT 
  '=== Outbox 事件統計（最近 1 小時）===' as 檢查項目;

SELECT 
  COUNT(*) as 總事件數,
  COUNT(*) FILTER (WHERE processed_at IS NOT NULL) as 已處理,
  COUNT(*) FILTER (WHERE processed_at IS NULL AND retry_count = 0) as 未處理_首次,
  COUNT(*) FILTER (WHERE processed_at IS NULL AND retry_count > 0 AND retry_count < 3) as 未處理_重試中,
  COUNT(*) FILTER (WHERE processed_at IS NULL AND retry_count >= 3) as 未處理_已達上限,
  COUNT(*) FILTER (WHERE error_message IS NOT NULL) as 有錯誤訊息
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour';

-- 檢查 3: 最近的錯誤訊息
SELECT 
  '=== 最近的錯誤訊息 ===' as 檢查項目;

SELECT 
  id as 事件ID,
  aggregate_id as 訂單ID,
  payload->>'bookingNumber' as 訂單編號,
  error_message as 錯誤訊息,
  retry_count as 重試次數,
  created_at as 創建時間,
  processed_at as 處理時間
FROM outbox
WHERE error_message IS NOT NULL
  AND created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;

-- 檢查 4: Cron Job 配置
SELECT 
  '=== Cron Job 配置 ===' as 檢查項目;

SELECT 
  jobid as 任務ID,
  jobname as 任務名稱,
  schedule as 執行頻率,
  active as 是否啟用,
  command as 執行命令
FROM cron.job
WHERE jobname LIKE '%sync%' OR jobname LIKE '%firestore%'
ORDER BY jobname;

-- 檢查 5: 最近的 Cron Job 執行記錄
SELECT 
  '=== Cron Job 執行記錄（最近 10 次）===' as 檢查項目;

SELECT 
  runid as 執行ID,
  jobid as 任務ID,
  job_pid as 進程ID,
  database as 資料庫,
  username as 用戶,
  command as 命令,
  status as 狀態,
  return_message as 返回訊息,
  start_time as 開始時間,
  end_time as 結束時間
FROM cron.job_run_details
WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname LIKE '%sync%' OR jobname LIKE '%firestore%')
ORDER BY start_time DESC
LIMIT 10;

-- 診斷建議
SELECT 
  '=== 診斷建議 ===' as 檢查項目;

DO $$
DECLARE
  total_events INTEGER;
  processed_events INTEGER;
  error_events INTEGER;
  cron_count INTEGER;
BEGIN
  -- 統計事件
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE processed_at IS NOT NULL),
    COUNT(*) FILTER (WHERE error_message IS NOT NULL)
  INTO total_events, processed_events, error_events
  FROM outbox
  WHERE created_at >= NOW() - INTERVAL '1 hour';

  -- 統計 Cron Job
  SELECT COUNT(*) INTO cron_count
  FROM cron.job
  WHERE jobname LIKE '%sync%' OR jobname LIKE '%firestore%';

  RAISE NOTICE '';
  RAISE NOTICE '📊 診斷結果：';
  RAISE NOTICE '  - 最近 1 小時事件總數: %', total_events;
  RAISE NOTICE '  - 已處理事件: %', processed_events;
  RAISE NOTICE '  - 有錯誤的事件: %', error_events;
  RAISE NOTICE '  - Cron Job 數量: %', cron_count;
  RAISE NOTICE '';

  IF total_events = 0 THEN
    RAISE NOTICE '⚠️ 沒有找到最近的事件';
    RAISE NOTICE '   建議: 創建新訂單測試';
  ELSIF processed_events = total_events AND error_events = 0 THEN
    RAISE NOTICE '✅ 所有事件都已成功處理';
    RAISE NOTICE '   但如果 Firestore 沒有資料，可能是：';
    RAISE NOTICE '   1. FIREBASE_SERVICE_ACCOUNT 環境變數未設置';
    RAISE NOTICE '   2. Service Account 權限不足';
    RAISE NOTICE '   3. Edge Function 日誌中有錯誤但未記錄到 outbox';
    RAISE NOTICE '';
    RAISE NOTICE '🔍 下一步診斷：';
    RAISE NOTICE '   1. 查看 Edge Function 日誌';
    RAISE NOTICE '   2. 檢查環境變數設置';
    RAISE NOTICE '   3. 手動觸發 Edge Function 並查看日誌';
  ELSIF error_events > 0 THEN
    RAISE NOTICE '❌ 有 % 個事件處理失敗', error_events;
    RAISE NOTICE '   請查看上方的錯誤訊息';
  ELSIF processed_events < total_events THEN
    RAISE NOTICE '⏳ 有 % 個事件待處理', total_events - processed_events;
    IF cron_count = 0 THEN
      RAISE NOTICE '   ❌ 未找到 Cron Job';
      RAISE NOTICE '   建議: 執行 setup_cron_jobs.sql 設置 Cron Job';
    ELSE
      RAISE NOTICE '   ✅ Cron Job 已設置';
      RAISE NOTICE '   建議: 等待 30 秒或手動觸發 Edge Function';
    END IF;
  END IF;

  RAISE NOTICE '';
END $$;

