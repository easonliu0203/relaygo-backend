-- ============================================
-- Supabase Cron Jobs 設置腳本
-- ============================================
-- 
-- 功能：設置定時任務以自動同步訂單到 Firestore
-- 
-- 使用方式：
-- 1. 前往 Supabase Dashboard → SQL Editor
-- 2. 點擊 "New query"
-- 3. 複製此檔案的內容並貼上
-- 4. 點擊 "Run" 執行
-- 
-- ============================================

-- 1. 啟用 pg_cron 擴展（如果尚未啟用）
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. 刪除舊的 Cron Jobs（如果存在）
SELECT cron.unschedule('sync-orders-to-firestore') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'sync-orders-to-firestore'
);

SELECT cron.unschedule('cleanup-old-outbox-events') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-outbox-events'
);

-- 3. 創建同步任務（每 30 秒執行一次）
-- 注意：pg_cron 的 cron 表達式格式為：秒 分 時 日 月 星期
-- */30 * * * * * 表示每 30 秒執行一次
SELECT cron.schedule(
  'sync-orders-to-firestore',           -- 任務名稱
  '*/30 * * * * *',                     -- Cron 表達式（每 30 秒）
  $$
  SELECT
    net.http_post(
      url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      )
    ) as request_id;
  $$
);

-- 4. 創建清理任務（每天凌晨 2 點執行）
-- 0 2 * * * 表示每天凌晨 2:00 執行
SELECT cron.schedule(
  'cleanup-old-outbox-events',          -- 任務名稱
  '0 2 * * *',                          -- Cron 表達式（每天凌晨 2 點）
  $$
  SELECT
    net.http_post(
      url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/cleanup-outbox',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      )
    ) as request_id;
  $$
);

-- 5. 驗證 Cron Jobs 已創建
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  command
FROM cron.job
WHERE jobname IN ('sync-orders-to-firestore', 'cleanup-old-outbox-events')
ORDER BY jobname;

-- ============================================
-- 預期結果：
-- ============================================
-- 應該看到兩個任務：
-- 
-- | jobid | jobname                      | schedule        | active | command                    |
-- |-------|------------------------------|-----------------|--------|----------------------------|
-- | 1     | sync-orders-to-firestore     | */30 * * * * *  | true   | SELECT net.http_post(...)  |
-- | 2     | cleanup-old-outbox-events    | 0 2 * * *       | true   | SELECT net.http_post(...)  |
-- 
-- ============================================
-- 常用管理命令：
-- ============================================

-- 查看所有 Cron Jobs
-- SELECT * FROM cron.job;

-- 查看 Cron Job 執行歷史
-- SELECT * FROM cron.job_run_details 
-- WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore')
-- ORDER BY start_time DESC
-- LIMIT 10;

-- 停用 Cron Job
-- SELECT cron.unschedule('sync-orders-to-firestore');

-- 重新啟用 Cron Job（重新執行上面的 cron.schedule 命令）

-- 手動觸發同步（用於測試）
-- SELECT
--   net.http_post(
--     url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
--     headers := jsonb_build_object(
--       'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
--     )
--   ) as request_id;

