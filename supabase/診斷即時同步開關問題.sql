-- ============================================
-- 診斷即時同步開關問題
-- ============================================
-- 
-- 用途：診斷為什麼開關無法控制即時同步
-- 執行：在 Supabase SQL Editor 中執行
-- 
-- ============================================

-- ============================================
-- 診斷 1: 檢查 system_settings 配置
-- ============================================

SELECT '=== 診斷 1: 檢查 system_settings 配置 ===' AS "診斷項目";

SELECT 
  key AS "配置鍵",
  value AS "完整配置",
  value->>'enabled' AS "開關狀態",
  CASE 
    WHEN (value->>'enabled')::BOOLEAN THEN '✅ 已啟用'
    ELSE '❌ 已停用'
  END AS "狀態說明",
  value->>'edge_function_url' AS "Edge Function URL",
  value->>'trigger_name' AS "Trigger 名稱",
  updated_at AS "最後更新時間"
FROM system_settings
WHERE key = 'realtime_sync_config';

-- ============================================
-- 診斷 2: 檢查 Trigger 是否存在
-- ============================================

SELECT '=== 診斷 2: 檢查 Trigger 是否存在 ===' AS "診斷項目";

SELECT 
  tgname AS "Trigger 名稱",
  tgenabled AS "啟用狀態代碼",
  CASE 
    WHEN tgenabled = 'O' THEN '✅ 已啟用'
    WHEN tgenabled = 'D' THEN '❌ 已禁用'
    ELSE '❓ 未知狀態'
  END AS "狀態說明",
  tgrelid::regclass AS "關聯表"
FROM pg_trigger
WHERE tgname = 'bookings_realtime_notify_trigger';

-- ============================================
-- 診斷 3: 檢查 Trigger 函數定義
-- ============================================

SELECT '=== 診斷 3: 檢查 Trigger 函數是否包含開關檢查邏輯 ===' AS "診斷項目";

SELECT 
  proname AS "函數名稱",
  CASE 
    WHEN pg_get_functiondef(oid) LIKE '%realtime_sync_config%' THEN '✅ 包含開關檢查邏輯'
    ELSE '❌ 不包含開關檢查邏輯'
  END AS "開關檢查",
  CASE 
    WHEN pg_get_functiondef(oid) LIKE '%eyJ%' THEN '✅ Service Role Key 已配置'
    WHEN pg_get_functiondef(oid) LIKE '%YOUR_SERVICE_ROLE_KEY%' THEN '⚠️  尚未替換 Service Role Key'
    ELSE '❓ 無法確認'
  END AS "Service Role Key 狀態"
FROM pg_proc
WHERE proname = 'notify_edge_function_realtime';

-- ============================================
-- 診斷 4: 檢查最近的 HTTP 請求記錄
-- ============================================

SELECT '=== 診斷 4: 檢查最近的 HTTP 請求記錄（最近 1 小時）===' AS "診斷項目";

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

-- 統計 HTTP 請求狀態碼分佈
SELECT 
  '最近 1 小時的 HTTP 請求統計' AS message;

SELECT 
  status_code,
  COUNT(*) AS count,
  MIN(created) AS first_request,
  MAX(created) AS last_request
FROM net._http_response
WHERE created > NOW() - INTERVAL '1 hour'
GROUP BY status_code
ORDER BY status_code;

-- ============================================
-- 診斷 5: 檢查 Outbox 事件處理狀態
-- ============================================

SELECT '=== 診斷 5: 檢查 Outbox 事件處理狀態（最近 1 小時）===' AS "診斷項目";

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
  created_at,
  EXTRACT(EPOCH FROM (processed_at - created_at)) AS delay_seconds
FROM outbox
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 診斷 6: 檢查 Cron Job 狀態
-- ============================================

SELECT '=== 診斷 6: 檢查 Cron Job 狀態 ===' AS "診斷項目";

SELECT 
  jobname AS "Cron Job 名稱",
  schedule AS "執行頻率",
  active AS "是否啟用",
  CASE 
    WHEN active THEN '✅ 正常運行'
    ELSE '❌ 未啟用'
  END AS "狀態"
FROM cron.job
WHERE jobname = 'sync-orders-to-firestore';

-- ============================================
-- 診斷結果總結
-- ============================================

SELECT '
============================================
📊 診斷結果總結
============================================

請檢查以上診斷結果：

1. system_settings 配置：
   - ✅ enabled = true → 開關已開啟
   - ❌ enabled = false → 開關已關閉

2. Trigger 狀態：
   - ✅ 已啟用 → Trigger 正常運作
   - ❌ 已禁用 → Trigger 被禁用

3. Trigger 函數開關檢查：
   - ✅ 包含開關檢查邏輯 → 函數已更新
   - ❌ 不包含開關檢查邏輯 → 需要執行 FINAL_FIX_401.sql

4. HTTP 請求記錄：
   - 如果開關關閉但仍有 HTTP 請求 → 函數未檢查開關
   - 如果開關關閉且無 HTTP 請求 → 開關正常運作

5. Outbox 事件處理：
   - 檢查 delay_seconds（延遲秒數）
   - 開關開啟：應該 < 5 秒
   - 開關關閉：應該 0-60 秒

6. Cron Job 狀態：
   - ✅ 正常運行 → 補償機制正常
   - ❌ 未啟用 → 需要啟用 Cron Job

============================================

🔧 修復方案：

如果診斷 3 顯示「❌ 不包含開關檢查邏輯」：
→ 執行 FINAL_FIX_401.sql 更新 Trigger 函數

如果診斷 4 顯示開關關閉但仍有 HTTP 請求：
→ 執行 FINAL_FIX_401.sql 更新 Trigger 函數

如果所有診斷都正常：
→ 在管理後台測試開關功能

============================================
' AS 診斷總結;

