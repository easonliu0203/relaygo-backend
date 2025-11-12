-- ============================================
-- 驗證 Cron Job 狀態和自動觸發機制
-- ============================================
-- 
-- 使用方式：
-- 1. 前往 Supabase Dashboard SQL Editor
-- 2. 複製此檔案的內容並執行
-- 3. 查看結果以診斷問題
-- 
-- ============================================

-- ============================================
-- 檢查 1: Cron Job 是否存在
-- ============================================
SELECT 
  '=== 檢查 1: Cron Job 配置 ===' as 檢查項目;

SELECT 
  jobid as 任務ID,
  jobname as 任務名稱,
  schedule as 執行頻率,
  active as 是否啟用,
  CASE 
    WHEN active THEN '✅ 已啟用'
    ELSE '❌ 未啟用'
  END as 狀態,
  command as 執行命令
FROM cron.job
WHERE jobname = 'sync-orders-to-firestore';

-- 如果沒有結果，表示 Cron Job 未創建
-- 解決方法：執行 supabase/setup_cron_jobs_fixed.sql

-- ============================================
-- 檢查 2: Cron Job 執行記錄（最近 10 次）
-- ============================================
SELECT 
  '=== 檢查 2: Cron Job 執行記錄 ===' as 檢查項目;

SELECT 
  runid as 執行ID,
  status as 狀態,
  return_message as 返回訊息,
  start_time as 開始時間,
  end_time as 結束時間,
  (end_time - start_time) as 執行時長,
  CASE 
    WHEN status = 'succeeded' THEN '✅ 成功'
    WHEN status = 'failed' THEN '❌ 失敗'
    ELSE '⏳ 執行中'
  END as 執行結果
FROM cron.job_run_details
WHERE jobid = (
  SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore'
)
ORDER BY start_time DESC
LIMIT 10;

-- 如果沒有結果，表示 Cron Job 從未執行
-- 可能原因：
-- 1. Cron Job 未啟用
-- 2. Cron Job 剛創建，還未到執行時間

-- ============================================
-- 檢查 3: Outbox 事件統計（最近 1 小時）
-- ============================================
SELECT 
  '=== 檢查 3: Outbox 事件統計 ===' as 檢查項目;

SELECT 
  COUNT(*) as 總事件數,
  COUNT(*) FILTER (WHERE processed_at IS NULL) as 未處理,
  COUNT(*) FILTER (WHERE processed_at IS NOT NULL) as 已處理,
  COUNT(*) FILTER (WHERE error_message IS NOT NULL) as 有錯誤,
  COUNT(*) FILTER (WHERE retry_count >= 3) as 已達最大重試,
  CASE 
    WHEN COUNT(*) FILTER (WHERE processed_at IS NULL) = 0 THEN '✅ 所有事件已處理'
    WHEN COUNT(*) FILTER (WHERE processed_at IS NULL) > 100 THEN '❌ 大量未處理事件（可能 Cron Job 停止）'
    WHEN COUNT(*) FILTER (WHERE processed_at IS NULL) > 10 THEN '⚠️ 有未處理事件（可能執行緩慢）'
    ELSE '✅ 正常'
  END as 診斷結果
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour';

-- ============================================
-- 檢查 4: 最近的 Outbox 事件詳情
-- ============================================
SELECT 
  '=== 檢查 4: 最近的 Outbox 事件 ===' as 檢查項目;

SELECT 
  id as 事件ID,
  aggregate_type as 聚合類型,
  event_type as 事件類型,
  payload->>'bookingNumber' as 訂單編號,
  created_at as 創建時間,
  processed_at as 處理時間,
  retry_count as 重試次數,
  error_message as 錯誤訊息,
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已處理'
    WHEN retry_count >= 3 THEN '❌ 已達最大重試次數'
    WHEN error_message IS NOT NULL THEN '⚠️ 有錯誤'
    ELSE '⏳ 待處理'
  END as 狀態,
  CASE 
    WHEN processed_at IS NOT NULL THEN 
      EXTRACT(EPOCH FROM (processed_at - created_at)) || ' 秒'
    ELSE 
      EXTRACT(EPOCH FROM (NOW() - created_at)) || ' 秒（未處理）'
  END as 處理時長
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 檢查 5: 有錯誤的事件
-- ============================================
SELECT 
  '=== 檢查 5: 有錯誤的事件 ===' as 檢查項目;

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
LIMIT 10;

-- 如果有錯誤事件，檢查 error_message 欄位
-- 常見錯誤：
-- 1. "401 Unauthorized": Service Role Key 錯誤
-- 2. "500 Internal Server Error": Edge Function 執行失敗
-- 3. "Timeout": 處理時間過長

-- ============================================
-- 檢查 6: 測試手動觸發 Edge Function
-- ============================================
SELECT 
  '=== 檢查 6: 手動觸發測試 ===' as 檢查項目;

-- ⚠️ 重要：請將 YOUR_SERVICE_ROLE_KEY 替換為實際的 service_role_key
-- 獲取方法：Supabase Dashboard > Settings > API > service_role key (secret)

-- 取消註解以下代碼以執行手動觸發測試：
/*
SELECT extensions.http_post(
  url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
  headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}'::jsonb,
  body := '{}'::jsonb
) as response;
*/

SELECT '⚠️ 手動觸發測試已註解，請取消註解並替換 Service Role Key 後執行' as 提示;

-- ============================================
-- 診斷總結
-- ============================================
SELECT 
  '=== 診斷總結 ===' as 檢查項目;

DO $$
DECLARE
  cron_exists BOOLEAN;
  cron_active BOOLEAN;
  total_events INTEGER;
  unprocessed_events INTEGER;
  error_events INTEGER;
  recent_runs INTEGER;
BEGIN
  -- 檢查 Cron Job 是否存在
  SELECT EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'sync-orders-to-firestore'
  ) INTO cron_exists;

  -- 檢查 Cron Job 是否啟用
  SELECT active INTO cron_active
  FROM cron.job
  WHERE jobname = 'sync-orders-to-firestore'
  LIMIT 1;

  -- 統計事件
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE processed_at IS NULL),
    COUNT(*) FILTER (WHERE error_message IS NOT NULL)
  INTO total_events, unprocessed_events, error_events
  FROM outbox
  WHERE created_at >= NOW() - INTERVAL '1 hour';

  -- 統計最近執行次數
  SELECT COUNT(*) INTO recent_runs
  FROM cron.job_run_details
  WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore')
    AND start_time >= NOW() - INTERVAL '1 hour';

  RAISE NOTICE '';
  RAISE NOTICE '📊 診斷結果總結：';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  
  -- Cron Job 狀態
  IF cron_exists THEN
    IF cron_active THEN
      RAISE NOTICE '✅ Cron Job 已配置且已啟用';
    ELSE
      RAISE NOTICE '❌ Cron Job 已配置但未啟用';
      RAISE NOTICE '   解決方法：執行以下 SQL 啟用 Cron Job';
      RAISE NOTICE '   UPDATE cron.job SET active = true WHERE jobname = ''sync-orders-to-firestore'';';
    END IF;
  ELSE
    RAISE NOTICE '❌ Cron Job 未配置';
    RAISE NOTICE '   解決方法：執行 supabase/setup_cron_jobs_fixed.sql';
  END IF;
  
  RAISE NOTICE '';
  
  -- 執行記錄
  IF recent_runs > 0 THEN
    RAISE NOTICE '✅ Cron Job 最近 1 小時執行了 % 次', recent_runs;
  ELSE
    RAISE NOTICE '⚠️ Cron Job 最近 1 小時未執行';
    RAISE NOTICE '   可能原因：';
    RAISE NOTICE '   1. Cron Job 剛創建，還未到執行時間';
    RAISE NOTICE '   2. Cron Job 未啟用';
    RAISE NOTICE '   3. Cron Job 配置錯誤';
  END IF;
  
  RAISE NOTICE '';
  
  -- 事件統計
  RAISE NOTICE '📈 Outbox 事件統計（最近 1 小時）：';
  RAISE NOTICE '   - 總事件數: %', total_events;
  RAISE NOTICE '   - 未處理事件: %', unprocessed_events;
  RAISE NOTICE '   - 有錯誤事件: %', error_events;
  
  RAISE NOTICE '';
  
  -- 診斷建議
  IF unprocessed_events = 0 AND total_events > 0 THEN
    RAISE NOTICE '✅ 所有事件已處理，自動觸發機制正常運作！';
  ELSIF unprocessed_events > 0 AND recent_runs = 0 THEN
    RAISE NOTICE '❌ 有未處理事件但 Cron Job 未執行';
    RAISE NOTICE '   建議：';
    RAISE NOTICE '   1. 檢查 Cron Job 是否啟用';
    RAISE NOTICE '   2. 手動觸發測試（執行檢查 6）';
  ELSIF unprocessed_events > 0 AND error_events > 0 THEN
    RAISE NOTICE '⚠️ 有未處理事件且有錯誤';
    RAISE NOTICE '   建議：';
    RAISE NOTICE '   1. 查看檢查 5 的錯誤訊息';
    RAISE NOTICE '   2. 檢查 Edge Function 日誌';
    RAISE NOTICE '   3. 檢查環境變數配置';
  ELSIF unprocessed_events > 100 THEN
    RAISE NOTICE '❌ 大量未處理事件（% 個）', unprocessed_events;
    RAISE NOTICE '   建議：';
    RAISE NOTICE '   1. 檢查 Cron Job 執行記錄（檢查 2）';
    RAISE NOTICE '   2. 檢查 Edge Function 是否執行緩慢';
    RAISE NOTICE '   3. 考慮增加執行頻率或批次大小';
  ELSIF total_events = 0 THEN
    RAISE NOTICE '⚠️ 最近 1 小時沒有新事件';
    RAISE NOTICE '   建議：創建測試訂單以驗證自動觸發機制';
  ELSE
    RAISE NOTICE '⏳ 有少量未處理事件（% 個）', unprocessed_events;
    RAISE NOTICE '   這是正常的，Cron Job 每 30 秒執行一次';
    RAISE NOTICE '   如果 30 秒後仍未處理，請檢查 Cron Job 執行記錄';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
END $$;

-- ============================================
-- 快速修復命令（如果需要）
-- ============================================
SELECT 
  '=== 快速修復命令 ===' as 檢查項目;

SELECT '
-- 如果 Cron Job 未啟用，執行以下命令啟用：
UPDATE cron.job 
SET active = true 
WHERE jobname = ''sync-orders-to-firestore'';

-- 如果 Cron Job 不存在，執行以下命令創建：
-- （請先替換 YOUR_SERVICE_ROLE_KEY）
SELECT cron.schedule(
  ''sync-orders-to-firestore'',
  ''*/30 * * * * *'',
  $$
  SELECT extensions.http_post(
    url := ''https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore'',
    headers := ''{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}''::jsonb,
    body := ''{}''::jsonb
  ) as request_id;
  $$
);

-- 如果需要刪除舊的 Cron Job 重新創建：
SELECT cron.unschedule(''sync-orders-to-firestore'');
' as 修復命令;

-- ============================================
-- 完成
-- ============================================
SELECT 
  '=== 驗證完成 ===' as 檢查項目;

SELECT '
✅ 驗證完成！

請根據上述診斷結果：
1. 如果 Cron Job 未配置，執行 supabase/setup_cron_jobs_fixed.sql
2. 如果 Cron Job 未啟用，執行快速修復命令
3. 如果有錯誤事件，查看錯誤訊息並修復
4. 如果一切正常，創建測試訂單驗證自動觸發

相關文檔：
- docs/20251014_1600_Edge_Function_觸發機制說明.md
- supabase/setup_cron_jobs_fixed.sql
- supabase/check-firestore-sync.sql
' as 下一步;

