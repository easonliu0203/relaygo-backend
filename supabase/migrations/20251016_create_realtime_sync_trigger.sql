-- ============================================
-- 即時同步 Trigger 創建腳本
-- ============================================
-- 
-- 功能：當 bookings 表變更時，立即通過 pg_net 發送 HTTP 請求到 Edge Function
-- 目的：實現 1-3 秒的即時同步，配合 Cron Job 形成雙保險機制
-- 
-- 創建日期：2025-10-16
-- 作者：AI Assistant
-- 
-- ============================================

-- 步驟 1：確保 pg_net 擴展已啟用
-- ============================================
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 步驟 2：創建即時通知 Trigger Function
-- ============================================
CREATE OR REPLACE FUNCTION notify_edge_function_realtime()
RETURNS TRIGGER AS $$
DECLARE
  edge_function_url TEXT;
  service_role_key TEXT;
  request_id BIGINT;
BEGIN
  -- 設定 Edge Function URL
  edge_function_url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore';
  
  -- 從環境變數獲取 Service Role Key
  -- 注意：這需要在 Supabase Dashboard 中配置 app.settings.service_role_key
  BEGIN
    service_role_key := current_setting('app.settings.service_role_key', true);
  EXCEPTION
    WHEN OTHERS THEN
      -- 如果無法獲取 key，記錄錯誤但不阻止 Trigger 執行
      RAISE WARNING 'Unable to get service_role_key: %', SQLERRM;
      RETURN NEW;
  END;
  
  -- 發送異步 HTTP POST 請求到 Edge Function
  -- 使用 PERFORM 而不是 SELECT，因為我們不需要返回值
  BEGIN
    SELECT net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || service_role_key,
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'trigger', 'realtime',
        'booking_id', NEW.id,
        'event_type', CASE
          WHEN TG_OP = 'INSERT' THEN 'created'
          WHEN TG_OP = 'UPDATE' THEN 'updated'
          ELSE 'unknown'
        END
      )
    ) INTO request_id;
    
    -- 記錄請求 ID（可選，用於調試）
    RAISE NOTICE 'Realtime sync triggered for booking %, request_id: %', NEW.id, request_id;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- 如果 HTTP 請求失敗，記錄錯誤但不阻止 Trigger 執行
      -- Cron Job 會作為補償機制處理這個事件
      RAISE WARNING 'Realtime sync HTTP request failed for booking %: %', NEW.id, SQLERRM;
  END;
  
  -- 返回 NEW 以繼續正常的 Trigger 流程
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 步驟 3：添加函數註釋
-- ============================================
COMMENT ON FUNCTION notify_edge_function_realtime() IS 
'即時通知 Edge Function 的 Trigger 函數。
當 bookings 表發生 INSERT 或 UPDATE 時，立即發送 HTTP 請求到 sync-to-firestore Edge Function。
如果 HTTP 請求失敗，不會阻止 Trigger 執行，Cron Job 會作為補償機制處理。';

-- 步驟 4：創建狀態記錄表（用於監控）
-- ============================================
CREATE TABLE IF NOT EXISTS realtime_sync_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  realtime_count INTEGER DEFAULT 0,
  cron_count INTEGER DEFAULT 0,
  error_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(date)
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_realtime_sync_stats_date ON realtime_sync_stats(date);

-- 添加表註釋
COMMENT ON TABLE realtime_sync_stats IS '即時同步統計表，記錄每日的同步次數和錯誤次數';

-- 步驟 5：在 system_settings 中添加配置
-- ============================================
INSERT INTO system_settings (key, value, description)
VALUES (
  'realtime_sync_config',
  jsonb_build_object(
    'enabled', false,  -- 默認停用，需要手動啟用
    'trigger_name', 'bookings_realtime_notify_trigger',
    'edge_function_url', 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
    'created_at', NOW(),
    'updated_at', NOW()
  ),
  '即時同步配置：控制 Trigger 是否啟用'
)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    updated_at = NOW();

-- 步驟 6：創建啟用/停用狀態查詢函數
-- ============================================
CREATE OR REPLACE FUNCTION get_realtime_sync_status()
RETURNS TABLE (
  trigger_exists BOOLEAN,
  trigger_enabled BOOLEAN,
  config_enabled BOOLEAN,
  last_updated TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    EXISTS(
      SELECT 1 FROM pg_trigger 
      WHERE tgname = 'bookings_realtime_notify_trigger'
    ) AS trigger_exists,
    EXISTS(
      SELECT 1 FROM pg_trigger 
      WHERE tgname = 'bookings_realtime_notify_trigger' 
      AND tgenabled = 'O'
    ) AS trigger_enabled,
    (
      SELECT (value->>'enabled')::BOOLEAN 
      FROM system_settings 
      WHERE key = 'realtime_sync_config'
    ) AS config_enabled,
    (
      SELECT updated_at 
      FROM system_settings 
      WHERE key = 'realtime_sync_config'
    ) AS last_updated;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_realtime_sync_status() IS '獲取即時同步的當前狀態';

-- ============================================
-- 驗證安裝
-- ============================================
SELECT '✅ 即時同步 Trigger Function 已創建' AS message;

SELECT 
  proname AS "函數名稱",
  pg_get_functiondef(oid) AS "函數定義預覽"
FROM pg_proc
WHERE proname = 'notify_edge_function_realtime';

SELECT '✅ 狀態查詢函數已創建' AS message;

SELECT * FROM get_realtime_sync_status();

SELECT '✅ 配置已添加到 system_settings' AS message;

SELECT key, value, description 
FROM system_settings 
WHERE key = 'realtime_sync_config';

-- ============================================
-- 重要提示
-- ============================================
SELECT '
⚠️  重要提示：
1. Trigger 尚未創建，需要手動啟用
2. 請執行 enable_realtime_sync.sql 來啟用即時同步
3. 或者通過管理後台的派單設定頁面啟用
4. 確保已在 Supabase Dashboard 配置 app.settings.service_role_key
' AS "安裝完成";

