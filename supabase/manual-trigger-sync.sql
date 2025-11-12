-- ============================================
-- 手動觸發同步測試腳本
-- ============================================
-- 
-- 用途：手動觸發 Edge Function 進行同步測試
-- 使用時機：
-- 1. 測試 Edge Function 是否正常工作
-- 2. Cron Job 未設置時手動同步
-- 3. 診斷同步問題
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

-- 啟用 http 擴展（如果尚未啟用）
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- 手動觸發同步
-- ⚠️ 重要：請將 YOUR_SERVICE_ROLE_KEY 替換為實際的 service_role_key
SELECT extensions.http_post(
  url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
  headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY", "Content-Type": "application/json"}'::jsonb,
  body := '{}'::jsonb
) as response;

-- ============================================
-- 預期結果：
-- ============================================
-- 
-- 如果成功，應該看到類似：
-- 
-- | response                                                                 |
-- |--------------------------------------------------------------------------|
-- | (200,OK,"{""message"":""事件處理完成"",""success"":1,""failure"":0}") |
-- 
-- 如果失敗，會看到錯誤訊息，例如：
-- - 401: 認證失敗（service_role_key 錯誤）
-- - 500: Edge Function 執行錯誤
-- 
-- ============================================
-- 驗證同步結果：
-- ============================================

-- 檢查 outbox 事件是否已處理
SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  processed_at,
  error_message,
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已同步'
    ELSE '❌ 未同步'
  END as sync_status
FROM outbox
WHERE created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC
LIMIT 5;

-- ============================================
-- 故障排除：
-- ============================================

-- 如果返回 401 錯誤：
-- → service_role_key 不正確，請重新獲取並替換

-- 如果返回 500 錯誤：
-- → Edge Function 執行失敗，檢查：
--   1. Edge Function 是否已部署
--   2. 環境變數是否已設置（FIREBASE_PROJECT_ID, FIREBASE_API_KEY）
--   3. 查看 Edge Function 日誌

-- 如果 processed_at 仍是 NULL：
-- → 檢查 error_message 欄位
-- → 查看 Edge Function 日誌

-- 查看 Edge Function 日誌：
-- 1. 前往：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
-- 2. 點擊 sync-to-firestore
-- 3. 點擊「Logs」標籤

