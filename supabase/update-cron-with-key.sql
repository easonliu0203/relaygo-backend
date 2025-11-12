-- ============================================
-- 更新 Cron Job 執行頻率（直接使用 Service Role Key）
-- ============================================
-- 
-- ⚠️ 重要：執行前請先替換 YOUR_SERVICE_ROLE_KEY
-- 
-- 如何獲取 Service Role Key：
-- 1. 前往：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/settings/api
-- 2. 找到 "service_role secret" 區域
-- 3. 點擊 "Reveal" 按鈕
-- 4. 複製顯示的完整 key（以 eyJ 開頭的長字串）
-- 5. 替換下面兩處的 YOUR_SERVICE_ROLE_KEY（第 24 行和第 42 行）
-- 
-- ============================================

-- ============================================
-- 步驟 1: 刪除舊的 Cron Jobs
-- ============================================

SELECT cron.unschedule('sync-orders-to-firestore');
SELECT cron.unschedule('cleanup-old-outbox-events');

-- ============================================
-- 步驟 2: 創建同步任務（每 1 分鐘）
-- ============================================

-- ⚠️ 重要：Supabase pg_cron 不支援秒級調度，只支援分鐘級（5 欄位）
-- 原本想設定每 5 秒，但改為每 1 分鐘（這是 Supabase 支援的最小間隔）
SELECT cron.schedule(
  'sync-orders-to-firestore',
  '* * * * *',  -- 每 1 分鐘（5 欄位格式：分/時/日/月/週）
  $$
  SELECT
    net.http_post(
      url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
      headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo", "Content-Type": "application/json"}'::jsonb
    ) as request_id;
  $$
);

-- ============================================
-- 步驟 3: 創建清理任務（每周一凌晨 2 點）
-- ============================================

-- ⚠️ 請將下面的 YOUR_SERVICE_ROLE_KEY 替換為你的 service_role key
SELECT cron.schedule(
  'cleanup-old-outbox-events',
  '0 2 * * 1',
  $$
  SELECT
    net.http_post(
      url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/cleanup-outbox',
      headers := '{"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo", "Content-Type": "application/json"}'::jsonb
    ) as request_id;
  $$
);

-- ============================================
-- 步驟 4: 驗證配置
-- ============================================

SELECT
  jobname,
  schedule,
  active,
  CASE
    WHEN jobname = 'sync-orders-to-firestore' AND schedule = '* * * * *'
      THEN '✅ 同步任務已更新為每 1 分鐘'
    WHEN jobname = 'cleanup-old-outbox-events' AND schedule = '0 2 * * 1'
      THEN '✅ 清理任務已更新為每周一凌晨 2 點'
    ELSE '❌ 配置異常'
  END as 配置狀態
FROM cron.job
WHERE jobname IN ('sync-orders-to-firestore', 'cleanup-old-outbox-events')
ORDER BY jobname;

-- ============================================
-- 完成提示
-- ============================================

SELECT '
✅ Cron Job 已更新！

⚠️ 重要說明：
- Supabase pg_cron 不支援秒級調度（6 欄位）
- 已改為每 1 分鐘執行（這是 Supabase 支援的最小間隔）
- 同步延遲：最多 1 分鐘（而不是原本期望的 5 秒）

下一步：
1. 等待 1-2 分鐘
2. 執行以下查詢驗證執行狀態：

SELECT
  COUNT(*) as 執行次數,
  MAX(start_time) as 最後執行時間
FROM cron.job_run_details
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = ''sync-orders-to-firestore'')
  AND start_time >= NOW() - INTERVAL ''5 minutes'';

預期結果：執行次數約 5 次（5 分鐘內）
' as 下一步;

