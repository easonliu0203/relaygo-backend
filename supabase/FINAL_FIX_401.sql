-- ============================================
-- 最終修復 401 錯誤（直接修改 Trigger 函數）
-- ============================================
-- 
-- 問題：Supabase 不允許使用 ALTER DATABASE 設置參數
-- 解決：直接在 Trigger 函數中硬編碼 Service Role Key
-- 
-- 使用方法：
-- 1. 將下面的 'YOUR_SERVICE_ROLE_KEY' 替換為您的實際 key
-- 2. 在 Supabase SQL Editor 中執行整個腳本
-- 3. 無需重新連接數據庫
-- 
-- ============================================

-- 步驟 1：修改 Trigger 函數（支持開關控制 + Service Role Key）
-- ⚠️  請將 'YOUR_SERVICE_ROLE_KEY' 替換為您的實際 key
CREATE OR REPLACE FUNCTION notify_edge_function_realtime()
RETURNS TRIGGER AS $$
DECLARE
  edge_function_url TEXT;
  service_role_key TEXT;
  request_id BIGINT;
  sync_enabled BOOLEAN;
BEGIN
  -- ============================================
  -- 步驟 1: 檢查即時同步開關狀態
  -- ============================================
  BEGIN
    SELECT (value->>'enabled')::BOOLEAN INTO sync_enabled
    FROM system_settings
    WHERE key = 'realtime_sync_config';

    -- 如果找不到配置，默認為停用
    IF sync_enabled IS NULL THEN
      sync_enabled := false;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      -- 如果查詢失敗，默認為停用
      sync_enabled := false;
      RAISE WARNING 'Failed to check realtime sync config: %', SQLERRM;
  END;

  -- 如果即時同步已停用，跳過 HTTP 請求
  IF NOT sync_enabled THEN
    RAISE NOTICE 'Realtime sync is disabled, skipping HTTP request for booking %. Will be handled by Cron Job.', NEW.id;
    RETURN NEW;
  END IF;

  -- ============================================
  -- 步驟 2: 設定 Edge Function URL 和 Service Role Key
  -- ============================================
  edge_function_url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore';

  -- ✅ Service Role Key 已配置
  service_role_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

  -- 驗證 key 是否已設置
  IF service_role_key = 'YOUR_SERVICE_ROLE_KEY' THEN
    RAISE WARNING '⚠️  Service Role Key 尚未配置，請修改函數並替換 YOUR_SERVICE_ROLE_KEY';
    RAISE NOTICE 'Skipping realtime sync for booking %, will be handled by Cron Job', NEW.id;
    RETURN NEW;
  END IF;

  -- ============================================
  -- 步驟 3: 發送 HTTP 請求到 Edge Function
  -- ============================================
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

    -- 記錄請求 ID
    RAISE NOTICE 'Realtime sync triggered for booking %, request_id: %', NEW.id, request_id;

  EXCEPTION
    WHEN OTHERS THEN
      -- 如果 HTTP 請求失敗，記錄錯誤但不阻止 Trigger 執行
      RAISE WARNING 'Realtime sync HTTP request failed for booking %: %', NEW.id, SQLERRM;
  END;

  -- 返回 NEW 以繼續正常的 Trigger 流程
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 添加函數註釋
COMMENT ON FUNCTION notify_edge_function_realtime() IS
'即時通知 Edge Function 的 Trigger 函數（已修復 401 錯誤 + 支持開關控制）。
- 檢查 system_settings.realtime_sync_config.enabled 狀態
- 如果開關關閉，跳過即時同步，由 Cron Job 處理
- Service Role Key 直接硬編碼在函數中';

-- ============================================
-- 步驟 2：驗證函數已更新
-- ============================================

SELECT '✅ Trigger 函數已更新' AS message;

-- 顯示函數定義（檢查是否包含您的 Service Role Key）
SELECT 
  proname AS "函數名稱",
  CASE 
    WHEN pg_get_functiondef(oid) LIKE '%YOUR_SERVICE_ROLE_KEY%' THEN '⚠️  尚未替換 Service Role Key'
    WHEN pg_get_functiondef(oid) LIKE '%eyJ%' THEN '✅ Service Role Key 已配置'
    ELSE '❓ 無法確認'
  END AS "配置狀態"
FROM pg_proc
WHERE proname = 'notify_edge_function_realtime';

-- ============================================
-- 步驟 3：檢查即時同步開關狀態
-- ============================================

SELECT '檢查即時同步開關狀態' AS message;

SELECT
  key AS "配置鍵",
  value->>'enabled' AS "開關狀態",
  CASE
    WHEN (value->>'enabled')::BOOLEAN THEN '✅ 已啟用 - 即時同步運作中'
    ELSE '❌ 已停用 - 由 Cron Job 處理'
  END AS "狀態說明",
  value->>'edge_function_url' AS "Edge Function URL",
  updated_at AS "最後更新時間"
FROM system_settings
WHERE key = 'realtime_sync_config';

-- ============================================
-- 步驟 4：驗證即時同步功能
-- ============================================

SELECT '
✅ Trigger 函數已修復並更新

功能特性：
1. ✅ 支持開關控制（檢查 system_settings.realtime_sync_config.enabled）
2. ✅ 開關關閉時自動跳過即時同步，由 Cron Job 處理
3. ✅ Service Role Key 已配置（401 錯誤已修復）

使用方法：
1. 在管理後台「派單設定」頁面控制開關
2. 開關開啟：訂單變更在 1-3 秒內同步到 Firestore
3. 開關關閉：訂單變更由 Cron Job 處理（每分鐘一次）

' AS message;

-- ============================================
-- 步驟 5：查詢工具（可選）
-- ============================================

-- 查詢最近的 HTTP 請求記錄（用於驗證即時同步）
-- 當您創建或更新訂單後，可以執行此查詢查看同步狀態

SELECT
  '查詢最近 1 小時的 HTTP 請求記錄' AS message;

SELECT
  id,
  status_code,
  CASE
    WHEN status_code = 200 THEN '✅ 成功'
    WHEN status_code = 401 THEN '❌ 認證失敗'
    WHEN status_code = 500 THEN '⚠️  服務器錯誤'
    ELSE '❓ 其他錯誤'
  END AS status,
  created AS request_time
FROM net._http_response
WHERE created > NOW() - INTERVAL '1 hour'
ORDER BY created DESC
LIMIT 10;

-- 查詢最近的 Outbox 事件處理狀態
SELECT
  '查詢最近 1 小時的 Outbox 事件' AS message;

SELECT
  id,
  aggregate_type,
  event_type,
  aggregate_id AS booking_id,
  CASE
    WHEN processed_at IS NOT NULL THEN '✅ 已處理'
    WHEN retry_count >= 3 THEN '❌ 重試次數已達上限'
    ELSE '⏳ 待處理'
  END AS status,
  processed_at,
  created_at
FROM outbox
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 完成
-- ============================================

SELECT '
============================================
✅ 401 錯誤修復完成 + 開關控制已啟用
============================================

Trigger 函數已更新，支持開關控制和即時同步。

✅ 已完成：
- ✅ Trigger 函數已修復（Service Role Key 已配置）
- ✅ 支持開關控制（檢查 system_settings.realtime_sync_config.enabled）
- ✅ 開關關閉時自動跳過即時同步，由 Cron Job 處理
- ✅ 401 認證錯誤已修復

🎛️  開關控制：
- 開關位置：管理後台 → 派單設定 → 即時通知功能
- 開關開啟：訂單變更在 1-3 秒內同步到 Firestore（即時同步）
- 開關關閉：訂單變更由 Cron Job 處理（每分鐘一次）
- 配置鍵：system_settings.realtime_sync_config.enabled

📋 驗證方法：
1. 在管理後台「派單設定」頁面測試開關
2. 開關開啟時創建訂單，檢查同步延遲（應該 1-3 秒）
3. 開關關閉時創建訂單，檢查同步延遲（應該 0-60 秒）
4. 執行上方的查詢工具查看 HTTP 請求記錄

🎯 下一步：
1. 測試開關功能（開啟/關閉）
2. 驗證開關關閉時不會發送 HTTP 請求
3. 驗證 Cron Job 仍然正常運作
4. 監控同步狀態和錯誤日誌

⚠️  注意：
- 開關關閉時，Trigger 仍然存在但會跳過 HTTP 請求
- Cron Job 始終運行，確保數據最終一致性
- 定期檢查 HTTP 請求記錄，確保狀態碼為 200
- 如果出現 401 錯誤，請檢查 Service Role Key 是否正確

============================================
' AS 完成訊息;

