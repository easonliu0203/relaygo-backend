-- ============================================
-- 測試 sync-to-firestore 函數
-- ============================================
-- 
-- 使用方式：
-- 1. 前往 Supabase Dashboard SQL Editor
-- 2. 複製此檔案的內容並執行
-- 3. 查看函數日誌以確認執行結果
-- 
-- ============================================

-- 手動觸發 sync-to-firestore 函數
SELECT
  net.http_post(
    url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    )
  ) as request_id;

-- ============================================
-- 預期結果：
-- ============================================
-- 應該返回一個 request_id (UUID 格式)
-- 例如：a1b2c3d4-e5f6-7890-abcd-ef1234567890
-- 
-- ============================================
-- 查看執行結果：
-- ============================================
-- 
-- 1. 前往 Edge Functions 頁面：
--    https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
-- 
-- 2. 點擊 sync-to-firestore 函數
-- 
-- 3. 點擊 Logs 分頁
-- 
-- 4. 查看最新的日誌：
--    - 如果配置正確：應該看到「找到 X 個待處理事件」或「沒有待處理的事件」
--    - 如果配置錯誤：會看到錯誤訊息（例如 401 或 403）
-- 
-- ============================================

