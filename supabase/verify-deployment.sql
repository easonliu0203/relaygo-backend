-- ============================================
-- 部署驗證 SQL 腳本
-- ============================================
-- 
-- 使用方式：
-- 1. 前往 Supabase Dashboard SQL Editor
-- 2. 複製此檔案的內容並執行
-- 3. 查看執行結果
-- 
-- ============================================

-- ============================================
-- 驗證 1：檢查 outbox 表是否存在
-- ============================================

SELECT 
  'outbox 表' as 檢查項目,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'outbox'
    ) THEN '✅ 存在'
    ELSE '❌ 不存在'
  END as 狀態;

-- ============================================
-- 驗證 2：檢查 outbox 表結構
-- ============================================

SELECT 
  column_name as 欄位名稱,
  data_type as 資料類型,
  is_nullable as 可為空
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'outbox'
ORDER BY ordinal_position;

-- ============================================
-- 驗證 3：檢查 Trigger 是否存在
-- ============================================

SELECT
  'bookings_outbox_trigger' as 檢查項目,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM information_schema.triggers
      WHERE trigger_schema = 'public'
      AND trigger_name = 'bookings_outbox_trigger'
    ) THEN '✅ 存在'
    ELSE '❌ 不存在'
  END as 狀態;

-- ============================================
-- 驗證 4：檢查 Cron Jobs 是否存在
-- ============================================

SELECT 
  jobname as 任務名稱,
  schedule as 執行頻率,
  active as 是否啟用,
  CASE 
    WHEN active THEN '✅ 已啟用'
    ELSE '❌ 未啟用'
  END as 狀態
FROM cron.job
WHERE jobname IN ('sync-orders-to-firestore', 'cleanup-old-outbox-events')
ORDER BY jobname;

-- ============================================
-- 驗證 5：檢查 outbox 表中的事件數量
-- ============================================

SELECT 
  '總事件數' as 統計項目,
  COUNT(*) as 數量
FROM outbox
UNION ALL
SELECT 
  '未處理事件數' as 統計項目,
  COUNT(*) as 數量
FROM outbox
WHERE processed_at IS NULL
UNION ALL
SELECT 
  '已處理事件數' as 統計項目,
  COUNT(*) as 數量
FROM outbox
WHERE processed_at IS NOT NULL
UNION ALL
SELECT 
  '失敗事件數 (重試 >= 3 次)' as 統計項目,
  COUNT(*) as 數量
FROM outbox
WHERE retry_count >= 3;

-- ============================================
-- 驗證 6：查看最近的 outbox 事件
-- ============================================

SELECT 
  id,
  aggregate_type as 聚合類型,
  aggregate_id as 聚合ID,
  event_type as 事件類型,
  created_at as 創建時間,
  processed_at as 處理時間,
  retry_count as 重試次數,
  error_message as 錯誤訊息
FROM outbox
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 驗證 7：查看 Cron Job 執行歷史
-- ============================================

SELECT 
  j.jobname as 任務名稱,
  d.status as 執行狀態,
  d.start_time as 開始時間,
  d.end_time as 結束時間,
  EXTRACT(EPOCH FROM (d.end_time - d.start_time)) as 執行時間_秒
FROM cron.job_run_details d
JOIN cron.job j ON d.jobid = j.jobid
WHERE j.jobname IN ('sync-orders-to-firestore', 'cleanup-old-outbox-events')
ORDER BY d.start_time DESC
LIMIT 10;

-- ============================================
-- 驗證 8：手動觸發同步函數
-- ============================================

SELECT
  net.http_post(
    url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    )
  ) as request_id;

-- ============================================
-- 預期結果總結
-- ============================================
-- 
-- 驗證 1：應該顯示「✅ 存在」
-- 驗證 2：應該顯示 outbox 表的所有欄位
-- 驗證 3：應該顯示「✅ 存在」
-- 驗證 4：應該顯示兩個任務，都是「✅ 已啟用」
-- 驗證 5：顯示事件統計（可能都是 0）
-- 驗證 6：顯示最近的事件（可能沒有）
-- 驗證 7：顯示 Cron Job 執行歷史
-- 驗證 8：返回一個 UUID
-- 
-- ============================================

