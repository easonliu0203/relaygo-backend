-- ============================================
-- 即時同步狀態檢查腳本
-- ============================================
-- 
-- 功能：全面檢查即時同步系統的運行狀態
-- 包含：
--   1. Trigger 狀態
--   2. Cron Job 狀態
--   3. 配置狀態
--   4. 統計數據
--   5. 最近的同步記錄
-- 
-- 執行方式：
--   在 Supabase Dashboard SQL Editor 中執行此腳本
-- 
-- ============================================

SELECT '
============================================
📊 即時同步系統狀態檢查
============================================
執行時間: ' || NOW() || '
============================================
' AS "系統狀態檢查";

-- ============================================
-- 檢查 1: Trigger 狀態
-- ============================================
SELECT '=== 檢查 1: Trigger 狀態 ===' AS "檢查項目";

SELECT 
  COALESCE(tgname, '不存在') AS "Trigger 名稱",
  CASE 
    WHEN tgname IS NULL THEN '❌ 未創建'
    WHEN tgenabled = 'O' THEN '✅ 已啟用'
    WHEN tgenabled = 'D' THEN '⚠️  已停用'
    ELSE '⚠️  未知狀態'
  END AS "狀態",
  COALESCE(pg_get_triggerdef(oid), '無') AS "定義"
FROM pg_trigger
WHERE tgname = 'bookings_realtime_notify_trigger'
UNION ALL
SELECT 
  'bookings_realtime_notify_trigger' AS "Trigger 名稱",
  '❌ 未創建' AS "狀態",
  '請執行 enable_realtime_sync.sql 創建' AS "定義"
WHERE NOT EXISTS (
  SELECT 1 FROM pg_trigger WHERE tgname = 'bookings_realtime_notify_trigger'
);

-- ============================================
-- 檢查 2: Trigger Function 狀態
-- ============================================
SELECT '=== 檢查 2: Trigger Function 狀態 ===' AS "檢查項目";

SELECT 
  proname AS "函數名稱",
  CASE 
    WHEN proname IS NOT NULL THEN '✅ 已創建'
    ELSE '❌ 不存在'
  END AS "狀態",
  pg_get_functiondef(oid) AS "函數定義"
FROM pg_proc
WHERE proname = 'notify_edge_function_realtime';

-- ============================================
-- 檢查 3: pg_net 擴展狀態
-- ============================================
SELECT '=== 檢查 3: pg_net 擴展狀態 ===' AS "檢查項目";

SELECT 
  extname AS "擴展名稱",
  extversion AS "版本",
  CASE 
    WHEN extname IS NOT NULL THEN '✅ 已啟用'
    ELSE '❌ 未啟用'
  END AS "狀態"
FROM pg_extension
WHERE extname = 'pg_net'
UNION ALL
SELECT 
  'pg_net' AS "擴展名稱",
  '未知' AS "版本",
  '❌ 未啟用，請在 Supabase Dashboard 啟用' AS "狀態"
WHERE NOT EXISTS (
  SELECT 1 FROM pg_extension WHERE extname = 'pg_net'
);

-- ============================================
-- 檢查 4: Cron Job 狀態
-- ============================================
SELECT '=== 檢查 4: Cron Job 狀態 ===' AS "檢查項目";

SELECT 
  jobname AS "任務名稱",
  schedule AS "執行頻率",
  active AS "是否啟用",
  CASE 
    WHEN active THEN '✅ 正常運行'
    ELSE '❌ 未啟用'
  END AS "狀態"
FROM cron.job
WHERE jobname = 'sync-orders-to-firestore';

-- ============================================
-- 檢查 5: 配置狀態
-- ============================================
SELECT '=== 檢查 5: 配置狀態 ===' AS "檢查項目";

SELECT 
  key AS "配置鍵",
  value->>'enabled' AS "即時同步啟用",
  value->>'edge_function_url' AS "Edge Function URL",
  updated_at AS "最後更新時間"
FROM system_settings
WHERE key = 'realtime_sync_config';

-- ============================================
-- 檢查 6: 綜合狀態
-- ============================================
SELECT '=== 檢查 6: 綜合狀態 ===' AS "檢查項目";

SELECT * FROM get_realtime_sync_status();

-- ============================================
-- 檢查 7: 今日統計數據
-- ============================================
SELECT '=== 檢查 7: 今日統計數據 ===' AS "檢查項目";

-- 今日 outbox 事件統計
SELECT 
  COUNT(*) AS "今日總事件數",
  COUNT(*) FILTER (WHERE processed_at IS NOT NULL) AS "已處理事件數",
  COUNT(*) FILTER (WHERE processed_at IS NULL) AS "未處理事件數",
  COUNT(*) FILTER (WHERE retry_count > 0) AS "重試事件數",
  COUNT(*) FILTER (WHERE error_message IS NOT NULL) AS "錯誤事件數"
FROM outbox
WHERE created_at >= CURRENT_DATE;

-- ============================================
-- 檢查 8: 最近的 HTTP 請求記錄
-- ============================================
SELECT '=== 檢查 8: 最近的 HTTP 請求記錄（即時通知）===' AS "檢查項目";

SELECT
  id AS "請求 ID",
  created AS "創建時間",
  status_code AS "HTTP 狀態碼",
  CASE
    WHEN status_code = 200 THEN '✅ 成功'
    WHEN status_code IS NULL THEN '⏳ 處理中'
    ELSE '❌ 失敗'
  END AS "狀態",
  SUBSTRING(content::TEXT, 1, 100) AS "響應內容（前100字符）"
FROM net._http_response
ORDER BY created DESC
LIMIT 10;

-- ============================================
-- 檢查 9: 最近的 Cron Job 執行記錄
-- ============================================
SELECT '=== 檢查 9: 最近的 Cron Job 執行記錄（補償機制）===' AS "檢查項目";

SELECT 
  runid AS "執行 ID",
  status AS "狀態",
  start_time AS "開始時間",
  end_time AS "結束時間",
  (end_time - start_time) AS "執行時長",
  CASE 
    WHEN status = 'succeeded' THEN '✅ 成功'
    WHEN status = 'failed' THEN '❌ 失敗'
    ELSE '⏳ 執行中'
  END AS "執行結果"
FROM cron.job_run_details
WHERE jobid = (
  SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore'
)
ORDER BY start_time DESC
LIMIT 10;

-- ============================================
-- 檢查 10: 最近的 outbox 事件
-- ============================================
SELECT '=== 檢查 10: 最近的 outbox 事件 ===' AS "檢查項目";

SELECT 
  id AS "事件 ID",
  aggregate_type AS "類型",
  event_type AS "事件",
  created_at AS "創建時間",
  processed_at AS "處理時間",
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已處理'
    ELSE '⏳ 待處理'
  END AS "狀態",
  retry_count AS "重試次數",
  error_message AS "錯誤訊息"
FROM outbox
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 檢查 11: 性能指標
-- ============================================
SELECT '=== 檢查 11: 性能指標（最近 1 小時）===' AS "檢查項目";

WITH recent_events AS (
  SELECT 
    created_at,
    processed_at,
    EXTRACT(EPOCH FROM (processed_at - created_at)) AS delay_seconds
  FROM outbox
  WHERE created_at >= NOW() - INTERVAL '1 hour'
    AND processed_at IS NOT NULL
)
SELECT 
  COUNT(*) AS "處理事件數",
  ROUND(AVG(delay_seconds)::NUMERIC, 2) AS "平均延遲（秒）",
  ROUND(MIN(delay_seconds)::NUMERIC, 2) AS "最小延遲（秒）",
  ROUND(MAX(delay_seconds)::NUMERIC, 2) AS "最大延遲（秒）",
  CASE 
    WHEN AVG(delay_seconds) <= 3 THEN '✅ 優秀（即時同步）'
    WHEN AVG(delay_seconds) <= 30 THEN '✅ 良好（Cron 補償）'
    WHEN AVG(delay_seconds) <= 60 THEN '⚠️  一般'
    ELSE '❌ 需要優化'
  END AS "性能評級"
FROM recent_events;

-- ============================================
-- 總結和建議
-- ============================================
SELECT '
============================================
📝 狀態總結和建議
============================================

根據以上檢查結果：

1. 如果 Trigger 狀態為「未創建」或「已停用」：
   → 執行 enable_realtime_sync.sql 啟用即時同步

2. 如果 Cron Job 狀態為「未啟用」：
   → 執行 setup_cron_jobs.sql 創建 Cron Job

3. 如果有大量未處理事件：
   → 檢查 Edge Function 是否正常運行
   → 查看 Edge Function 日誌

4. 如果平均延遲過高：
   → 檢查即時同步是否啟用
   → 檢查網路連接和 Edge Function 性能

5. 如果有大量錯誤事件：
   → 查看 error_message 欄位
   → 檢查 Edge Function 日誌
   → 檢查 Firestore 連接

============================================
' AS "總結和建議";

