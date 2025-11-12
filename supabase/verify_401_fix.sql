-- ============================================
-- 驗證 401 錯誤修復
-- ============================================
-- 
-- 用途：驗證修復是否成功
-- 執行：在 Supabase SQL Editor 中執行
-- 
-- ============================================

-- 步驟 1：檢查 Trigger 函數配置狀態
-- ============================================

SELECT 
  '步驟 1：檢查 Trigger 函數配置狀態' AS message;

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
-- 步驟 2：檢查最近的 HTTP 請求記錄
-- ============================================

SELECT 
  '步驟 2：檢查最近的 HTTP 請求記錄（最近 1 小時）' AS message;

SELECT 
  id,
  status_code,
  CASE 
    WHEN status_code = 200 THEN '✅ 成功'
    WHEN status_code = 401 THEN '❌ 認證失敗'
    WHEN status_code = 500 THEN '⚠️  服務器錯誤'
    ELSE '❓ 其他錯誤'
  END AS status,
  content::text AS response_content,
  created AS created_time
FROM net._http_response
WHERE created > NOW() - INTERVAL '1 hour'
ORDER BY created DESC
LIMIT 10;

-- ============================================
-- 步驟 3：統計 HTTP 請求狀態碼分佈
-- ============================================

SELECT 
  '步驟 3：HTTP 請求狀態碼分佈（最近 1 小時）' AS message;

SELECT 
  status_code,
  CASE 
    WHEN status_code = 200 THEN '✅ 成功'
    WHEN status_code = 401 THEN '❌ 認證失敗'
    WHEN status_code = 500 THEN '⚠️  服務器錯誤'
    ELSE '❓ 其他錯誤'
  END AS status,
  COUNT(*) AS count,
  MIN(created) AS first_occurrence,
  MAX(created) AS last_occurrence
FROM net._http_response
WHERE created > NOW() - INTERVAL '1 hour'
GROUP BY status_code
ORDER BY status_code;

-- ============================================
-- 步驟 4：檢查 Outbox 事件處理狀態
-- ============================================

SELECT 
  '步驟 4：檢查 Outbox 事件處理狀態（最近 1 小時）' AS message;

SELECT 
  id,
  aggregate_type,
  event_type,
  aggregate_id,
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已處理'
    WHEN retry_count >= 3 THEN '❌ 重試次數已達上限'
    ELSE '⏳ 待處理'
  END AS status,
  processed_at,
  retry_count,
  created_at
FROM outbox
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 步驟 5：統計 Outbox 事件處理率
-- ============================================

SELECT 
  '步驟 5：Outbox 事件處理率（最近 1 小時）' AS message;

SELECT 
  COUNT(*) AS total_events,
  COUNT(CASE WHEN processed_at IS NOT NULL THEN 1 END) AS processed_events,
  COUNT(CASE WHEN processed_at IS NULL THEN 1 END) AS pending_events,
  COUNT(CASE WHEN retry_count >= 3 THEN 1 END) AS failed_events,
  ROUND(
    COUNT(CASE WHEN processed_at IS NOT NULL THEN 1 END)::NUMERIC / 
    NULLIF(COUNT(*), 0) * 100, 
    2
  ) AS success_rate_percentage
FROM outbox
WHERE created_at > NOW() - INTERVAL '1 hour';

-- ============================================
-- 步驟 6：檢查 Trigger 是否啟用
-- ============================================

SELECT 
  '步驟 6：檢查 Trigger 是否啟用' AS message;

SELECT 
  tgname AS "Trigger 名稱",
  tgenabled AS "啟用狀態",
  CASE 
    WHEN tgenabled = 'O' THEN '✅ 已啟用'
    WHEN tgenabled = 'D' THEN '❌ 已禁用'
    ELSE '❓ 未知狀態'
  END AS "狀態說明"
FROM pg_trigger
WHERE tgname = 'bookings_realtime_notify_trigger';

-- ============================================
-- 步驟 7：檢查最近創建的測試訂單
-- ============================================

SELECT 
  '步驟 7：檢查最近創建的測試訂單（最近 1 小時）' AS message;

SELECT 
  id,
  booking_number,
  status,
  created_at,
  updated_at
FROM bookings
WHERE booking_number LIKE 'FINAL_%'
  AND created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;

-- ============================================
-- 完成 - 顯示診斷結果
-- ============================================

SELECT '
============================================
✅ 驗證完成
============================================

請檢查以上查詢結果：

1. 配置狀態：
   - ✅ Service Role Key 已配置 → 修復成功
   - ⚠️  尚未替換 Service Role Key → 需要重新執行修復腳本

2. HTTP 請求狀態碼：
   - ✅ 200 → 修復成功
   - ❌ 401 → 認證失敗，請檢查 Service Role Key
   - ⚠️  沒有記錄 → Trigger 可能未觸發

3. Outbox 事件處理率：
   - ✅ 100% → 完美
   - ⚠️  < 100% → 部分事件未處理

4. Trigger 啟用狀態：
   - ✅ 已啟用 → 正常
   - ❌ 已禁用 → 需要啟用 Trigger

============================================

如果所有檢查都通過：
1. ✅ 前往 Firestore Console 檢查數據同步
2. ✅ 執行完整的狀態流轉測試
3. ✅ 在管理後台啟用「即時同步開關」

如果有任何檢查失敗：
1. 查看具體的錯誤訊息
2. 重新執行修復腳本
3. 聯繫技術支持

============================================
' AS 診斷結果;

