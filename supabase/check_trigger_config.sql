-- ============================================
-- 檢查 Trigger 配置
-- ============================================
-- 
-- 功能：詳細檢查 Trigger 和即時同步配置
-- 
-- ============================================

SELECT '
============================================
🔍 檢查 Trigger 配置
============================================
' AS "檢查開始";

-- ============================================
-- 1. 檢查 Trigger 是否存在
-- ============================================
SELECT '=== 1. Trigger 狀態 ===' AS "檢查項目";

SELECT 
  tgname AS "Trigger 名稱",
  tgrelid::regclass AS "關聯表",
  CASE tgtype & 2
    WHEN 2 THEN 'BEFORE'
    ELSE 'AFTER'
  END AS "觸發時機",
  CASE 
    WHEN tgtype & 4 = 4 THEN 'INSERT'
    WHEN tgtype & 8 = 8 THEN 'DELETE'
    WHEN tgtype & 16 = 16 THEN 'UPDATE'
    ELSE 'OTHER'
  END AS "觸發事件",
  CASE tgenabled
    WHEN 'O' THEN '✅ 已啟用'
    WHEN 'D' THEN '❌ 已停用'
    WHEN 'R' THEN '⚠️ 僅在副本上啟用'
    WHEN 'A' THEN '⚠️ 僅在副本上停用'
    ELSE '❓ 未知'
  END AS "狀態",
  pg_get_triggerdef(oid) AS "Trigger 定義"
FROM pg_trigger
WHERE tgname = 'bookings_realtime_notify_trigger';

-- ============================================
-- 2. 檢查 Trigger Function 是否存在
-- ============================================
SELECT '=== 2. Trigger Function 狀態 ===' AS "檢查項目";

SELECT 
  proname AS "函數名稱",
  pg_get_functiondef(oid) AS "函數定義"
FROM pg_proc
WHERE proname = 'notify_edge_function_realtime';

-- ============================================
-- 3. 檢查即時同步配置
-- ============================================
SELECT '=== 3. 即時同步配置 ===' AS "檢查項目";

SELECT 
  key AS "配置鍵",
  value AS "配置值",
  value->>'enabled' AS "是否啟用",
  value->>'edge_function_url' AS "Edge Function URL",
  CASE 
    WHEN value->>'enabled' = 'true' THEN '✅ 已啟用'
    ELSE '❌ 未啟用'
  END AS "狀態"
FROM system_settings
WHERE key = 'realtime_sync_config';

-- ============================================
-- 4. 檢查 pg_net 擴展
-- ============================================
SELECT '=== 4. pg_net 擴展狀態 ===' AS "檢查項目";

SELECT 
  extname AS "擴展名稱",
  extversion AS "版本",
  '✅ 已啟用' AS "狀態"
FROM pg_extension
WHERE extname = 'pg_net';

-- ============================================
-- 5. 測試 Trigger Function（不實際執行）
-- ============================================
SELECT '=== 5. Trigger Function 測試 ===' AS "檢查項目";

SELECT '
測試方法：
1. 創建一個測試訂單
2. 觀察是否立即有 HTTP 請求記錄
3. 檢查延遲時間

執行測試腳本：
  test_realtime_trigger_only.sql
' AS "測試說明";

-- ============================================
-- 6. 檢查最近的 HTTP 請求
-- ============================================
SELECT '=== 6. 最近的 HTTP 請求 ===' AS "檢查項目";

SELECT 
  id,
  created AS "請求時間",
  status_code AS "狀態碼",
  CASE
    WHEN status_code = 200 THEN '✅ 成功'
    WHEN status_code IS NULL THEN '⏳ 處理中'
    ELSE '❌ 失敗'
  END AS "狀態",
  SUBSTRING(content::TEXT, 1, 100) AS "響應內容（前100字符）"
FROM net._http_response
ORDER BY created DESC
LIMIT 5;

-- ============================================
-- 7. 檢查 Trigger 觸發次數
-- ============================================
SELECT '=== 7. Trigger 統計 ===' AS "檢查項目";

SELECT
  schemaname AS "Schema",
  relname AS "表名",
  n_tup_ins AS "INSERT 次數",
  n_tup_upd AS "UPDATE 次數",
  n_tup_del AS "DELETE 次數",
  last_vacuum AS "最後 VACUUM",
  last_autovacuum AS "最後 Auto VACUUM"
FROM pg_stat_user_tables
WHERE relname = 'bookings';

-- ============================================
-- 總結
-- ============================================
SELECT '
============================================
📊 檢查總結
============================================

請確認以下項目：

1. ✅ Trigger 狀態為「已啟用」
2. ✅ Trigger Function 存在且定義正確
3. ✅ 即時同步配置 enabled = true
4. ✅ Edge Function URL 正確
5. ✅ pg_net 擴展已啟用
6. ✅ 有 HTTP 請求記錄

如果以上都正確，但延遲仍然很高：
  → 執行 test_realtime_trigger_only.sql 進行詳細測試
  → 檢查 Edge Function 日誌
  → 檢查網路連接

如果 Trigger 未啟用：
  → 執行 enable_realtime_sync.sql 重新啟用

============================================
' AS "總結";

