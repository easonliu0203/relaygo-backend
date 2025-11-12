-- ============================================
-- 驗證所有修復
-- ============================================
-- 
-- 功能：快速驗證所有 SQL 腳本修復是否成功
-- 執行方式：在 Supabase Dashboard SQL Editor 中執行此腳本
-- 
-- ============================================

SELECT '
============================================
🔍 驗證所有修復
============================================
' AS "驗證開始";

-- ============================================
-- 驗證 1: Trigger Function 是否存在
-- ============================================
SELECT '=== 驗證 1: Trigger Function ===' AS "驗證項目";

SELECT 
  proname AS "函數名稱",
  CASE 
    WHEN proname = 'notify_edge_function_realtime' THEN '✅ 存在'
    ELSE '❌ 不存在'
  END AS "狀態"
FROM pg_proc 
WHERE proname = 'notify_edge_function_realtime';

-- ============================================
-- 驗證 2: Trigger 是否已創建
-- ============================================
SELECT '=== 驗證 2: Trigger 狀態 ===' AS "驗證項目";

SELECT 
  tgname AS "Trigger 名稱",
  CASE 
    WHEN tgenabled = 'O' THEN '✅ 已啟用'
    WHEN tgenabled = 'D' THEN '⚠️ 已停用'
    ELSE '❌ 未知狀態'
  END AS "狀態"
FROM pg_trigger 
WHERE tgname = 'bookings_realtime_notify_trigger';

-- ============================================
-- 驗證 3: 配置是否正確
-- ============================================
SELECT '=== 驗證 3: 配置狀態 ===' AS "驗證項目";

SELECT 
  key AS "配置鍵",
  value->>'enabled' AS "即時同步啟用",
  value->>'edge_function_url' AS "Edge Function URL",
  CASE 
    WHEN value->>'enabled' = 'true' THEN '✅ 已啟用'
    ELSE '❌ 未啟用'
  END AS "狀態"
FROM system_settings
WHERE key = 'realtime_sync_config';

-- ============================================
-- 驗證 4: pg_net 擴展是否啟用
-- ============================================
SELECT '=== 驗證 4: pg_net 擴展 ===' AS "驗證項目";

SELECT 
  extname AS "擴展名稱",
  '✅ 已啟用' AS "狀態"
FROM pg_extension 
WHERE extname = 'pg_net';

-- ============================================
-- 驗證 5: bookings 表結構
-- ============================================
SELECT '=== 驗證 5: bookings 表必填欄位 ===' AS "驗證項目";

SELECT 
  column_name AS "欄位名稱",
  data_type AS "數據類型",
  is_nullable AS "可為空",
  CASE 
    WHEN is_nullable = 'NO' THEN '✅ NOT NULL'
    ELSE '⚠️ 可為空'
  END AS "約束"
FROM information_schema.columns
WHERE table_name = 'bookings'
  AND column_name IN ('booking_number', 'base_price', 'total_amount', 'deposit_amount')
ORDER BY column_name;

-- ============================================
-- 驗證 6: 測試訂單（如果存在）
-- ============================================
SELECT '=== 驗證 6: 最近的測試訂單 ===' AS "驗證項目";

SELECT 
  id,
  booking_number,
  status,
  pickup_location,
  base_price,
  total_amount,
  deposit_amount,
  created_at,
  CASE 
    WHEN booking_number IS NOT NULL THEN '✅ 有訂單編號'
    ELSE '❌ 缺少訂單編號'
  END AS "驗證結果"
FROM bookings
WHERE booking_number LIKE 'TEST_%'
ORDER BY created_at DESC
LIMIT 5;

-- ============================================
-- 驗證 7: HTTP 請求記錄（如果存在）
-- ============================================
SELECT '=== 驗證 7: 最近的 HTTP 請求 ===' AS "驗證項目";

SELECT 
  id AS "請求 ID",
  status_code AS "狀態碼",
  created AS "請求時間",
  CASE 
    WHEN status_code = 200 THEN '✅ 成功'
    WHEN status_code IS NULL THEN '⏳ 處理中'
    ELSE '❌ 失敗'
  END AS "狀態"
FROM net._http_response
ORDER BY created DESC
LIMIT 5;

-- ============================================
-- 驗證總結
-- ============================================
SELECT '
============================================
📊 驗證總結
============================================

如果以上所有驗證項目都顯示 ✅，則表示：

1. ✅ Migration 已成功執行
2. ✅ Trigger Function 已創建
3. ✅ Trigger 已啟用
4. ✅ 配置已正確設置
5. ✅ pg_net 擴展已啟用
6. ✅ bookings 表結構正確
7. ✅ 所有修復已生效

現在可以安全執行測試腳本了！

============================================
' AS "驗證完成";

