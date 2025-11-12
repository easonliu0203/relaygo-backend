-- ============================================
-- Supabase Cron Jobs 設置腳本（修復版）
-- ============================================
-- 
-- 修復日期：2025-10-05
-- 修復內容：解決 service_role_key 認證問題
-- 
-- 使用方式：
-- 1. 前往 Supabase Dashboard → SQL Editor
-- 2. 點擊 "New query"
-- 3. 複製此檔案的內容並貼上
-- 4. **重要**：將下方的 YOUR_SERVICE_ROLE_KEY 替換為實際的 key
-- 5. 點擊 "Run" 執行
-- 
-- 如何獲取 service_role_key：
-- 1. 前往：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/settings/api
-- 2. 找到「service_role」section
-- 3. 點擊「Reveal」顯示 key
-- 4. 複製 key 並替換下方的 YOUR_SERVICE_ROLE_KEY
-- 
-- ============================================

-- 1. 啟用必要的擴展
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- 2. 刪除舊的 Cron Jobs（如果存在）
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'sync-orders-to-firestore') THEN
    PERFORM cron.unschedule('sync-orders-to-firestore');
  END IF;
  
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-outbox-events') THEN
    PERFORM cron.unschedule('cleanup-old-outbox-events');
  END IF;
END $$;

-- 3. 創建同步任務（每 30 秒執行一次）
-- 
-- ⚠️ 重要：請將 YOUR_SERVICE_ROLE_KEY 替換為實際的 service_role_key
-- 
SELECT cron.schedule(
  'sync-orders-to-firestore',
  '*/30 * * * * *',
  $$
  SELECT extensions.http_post(
    url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  ) as request_id;
  $$
);

-- 4. 創建清理任務（每天凌晨 2 點執行）
-- 
-- ⚠️ 重要：請將 YOUR_SERVICE_ROLE_KEY 替換為實際的 service_role_key
-- 
SELECT cron.schedule(
  'cleanup-old-outbox-events',
  '0 2 * * *',
  $$
  SELECT extensions.http_post(
    url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/cleanup-outbox',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  ) as request_id;
  $$
);

-- 5. 驗證 Cron Jobs 已創建
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  LEFT(command, 100) || '...' as command_preview
FROM cron.job
WHERE jobname IN ('sync-orders-to-firestore', 'cleanup-old-outbox-events')
ORDER BY jobname;

-- ============================================
-- 預期結果：
-- ============================================
-- 應該看到兩個任務：
-- 
-- | jobid | jobname                      | schedule        | active |
-- |-------|------------------------------|-----------------|--------|
-- | X     | cleanup-old-outbox-events    | 0 2 * * *       | true   |
-- | Y     | sync-orders-to-firestore     | */30 * * * * *  | true   |
-- 
-- ============================================
-- 驗證和測試命令：
-- ============================================

-- 查看所有 Cron Jobs
-- SELECT * FROM cron.job;

-- 查看 Cron Job 執行歷史
-- SELECT 
--   jobname,
--   status,
--   return_message,
--   start_time,
--   end_time
-- FROM cron.job_run_details
-- WHERE jobname = 'sync-orders-to-firestore'
-- ORDER BY start_time DESC
-- LIMIT 10;

-- 手動觸發同步（用於測試）
-- ⚠️ 重要：請將 YOUR_SERVICE_ROLE_KEY 替換為實際的 service_role_key
-- 
-- SELECT extensions.http_post(
--   url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
--   headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}'::jsonb,
--   body := '{}'::jsonb
-- );

-- 停用 Cron Job
-- SELECT cron.unschedule('sync-orders-to-firestore');

-- ============================================
-- 故障排除：
-- ============================================

-- 如果 Cron Job 執行失敗，檢查：
-- 1. service_role_key 是否正確
-- 2. Edge Function 是否已部署
-- 3. 環境變數是否已設置（FIREBASE_PROJECT_ID, FIREBASE_API_KEY）

-- 查看最近的錯誤：
-- SELECT 
--   jobname,
--   status,
--   return_message,
--   start_time
-- FROM cron.job_run_details
-- WHERE jobname = 'sync-orders-to-firestore'
--   AND status = 'failed'
-- ORDER BY start_time DESC
-- LIMIT 5;

