-- ========================================
-- 診斷：Firestore 訂單狀態異常跳轉問題
-- ========================================
-- 問題：訂單狀態從 inProgress 倒退回 pending
-- 創建時間：2025-10-15
-- ========================================

-- 🔍 請先填寫你的訂單 ID
-- 將下面的 'YOUR_BOOKING_ID' 替換為實際的訂單 ID
\set booking_id 'YOUR_BOOKING_ID'

-- ========================================
-- 步驟 1: 檢查 Supabase 訂單當前狀態
-- ========================================
SELECT 
  '步驟 1：檢查 Supabase 訂單當前狀態' AS "診斷步驟";

SELECT 
  id,
  booking_number,
  status AS "當前狀態",
  actual_start_time AS "行程開始時間",
  actual_end_time AS "行程結束時間",
  created_at AS "創建時間",
  updated_at AS "最後更新時間"
FROM bookings
WHERE id = :'booking_id';

-- ========================================
-- 步驟 2: 檢查該訂單的所有 Outbox 事件
-- ========================================
SELECT 
  '步驟 2：檢查該訂單的所有 Outbox 事件' AS "診斷步驟";

SELECT 
  id AS "事件ID",
  event_type AS "事件類型",
  payload->>'status' AS "Payload中的狀態",
  payload->>'bookingNumber' AS "訂單編號",
  created_at AS "事件創建時間",
  processed_at AS "事件處理時間",
  retry_count AS "重試次數",
  error_message AS "錯誤訊息"
FROM outbox
WHERE aggregate_id = :'booking_id'
ORDER BY created_at DESC;

-- ========================================
-- 步驟 3: 統計該訂單的事件數量
-- ========================================
SELECT 
  '步驟 3：統計該訂單的事件數量' AS "診斷步驟";

SELECT 
  event_type AS "事件類型",
  payload->>'status' AS "狀態",
  COUNT(*) AS "事件數量",
  MIN(created_at) AS "最早時間",
  MAX(created_at) AS "最晚時間"
FROM outbox
WHERE aggregate_id = :'booking_id'
GROUP BY event_type, payload->>'status'
ORDER BY MAX(created_at) DESC;

-- ========================================
-- 步驟 4: 檢查未處理的事件
-- ========================================
SELECT 
  '步驟 4：檢查未處理的事件' AS "診斷步驟";

SELECT 
  id AS "事件ID",
  event_type AS "事件類型",
  payload->>'status' AS "狀態",
  created_at AS "創建時間",
  retry_count AS "重試次數"
FROM outbox
WHERE aggregate_id = :'booking_id'
  AND processed_at IS NULL
ORDER BY created_at DESC;

-- ========================================
-- 步驟 5: 檢查最近處理的事件
-- ========================================
SELECT 
  '步驟 5：檢查最近處理的事件（最近 10 個）' AS "診斷步驟";

SELECT 
  id AS "事件ID",
  event_type AS "事件類型",
  payload->>'status' AS "狀態",
  created_at AS "創建時間",
  processed_at AS "處理時間",
  EXTRACT(EPOCH FROM (processed_at - created_at)) AS "處理延遲(秒)"
FROM outbox
WHERE aggregate_id = :'booking_id'
  AND processed_at IS NOT NULL
ORDER BY processed_at DESC
LIMIT 10;

-- ========================================
-- 步驟 6: 檢查是否有重複的 Trigger 執行
-- ========================================
SELECT 
  '步驟 6：檢查是否有重複的 Trigger 執行' AS "診斷步驟";

-- 查找在同一秒內創建的多個事件（可能是重複觸發）
SELECT 
  DATE_TRUNC('second', created_at) AS "創建時間(秒)",
  COUNT(*) AS "事件數量",
  STRING_AGG(DISTINCT payload->>'status', ', ') AS "狀態列表"
FROM outbox
WHERE aggregate_id = :'booking_id'
GROUP BY DATE_TRUNC('second', created_at)
HAVING COUNT(*) > 1
ORDER BY DATE_TRUNC('second', created_at) DESC;

-- ========================================
-- 步驟 7: 檢查訂單的更新歷史
-- ========================================
SELECT 
  '步驟 7：檢查訂單的更新歷史' AS "診斷步驟";

-- 查看訂單的所有狀態變更（通過 outbox 事件）
SELECT 
  ROW_NUMBER() OVER (ORDER BY created_at) AS "序號",
  payload->>'status' AS "狀態",
  created_at AS "時間",
  processed_at AS "處理時間",
  CASE 
    WHEN processed_at IS NULL THEN '未處理'
    ELSE '已處理'
  END AS "處理狀態"
FROM outbox
WHERE aggregate_id = :'booking_id'
  AND event_type = 'updated'
ORDER BY created_at;

-- ========================================
-- 步驟 8: 檢查 Trigger 是否正常
-- ========================================
SELECT 
  '步驟 8：檢查 Trigger 是否正常' AS "診斷步驟";

SELECT 
  tgname AS "Trigger 名稱",
  proname AS "函數名稱",
  CASE tgenabled
    WHEN 'O' THEN '啟用'
    WHEN 'D' THEN '停用'
    WHEN 'R' THEN '僅副本啟用'
    WHEN 'A' THEN '總是啟用'
  END AS "狀態"
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgname = 'bookings_outbox_trigger';

-- ========================================
-- 步驟 9: 檢查是否有其他訂單也出現此問題
-- ========================================
SELECT 
  '步驟 9：檢查是否有其他訂單也出現此問題' AS "診斷步驟";

-- 查找有多個 updated 事件的訂單
SELECT 
  aggregate_id AS "訂單ID",
  COUNT(*) AS "更新事件數量",
  STRING_AGG(DISTINCT payload->>'status', ' → ') AS "狀態變化"
FROM outbox
WHERE aggregate_type = 'booking'
  AND event_type = 'updated'
  AND created_at > NOW() - INTERVAL '1 hour'  -- 最近 1 小時
GROUP BY aggregate_id
HAVING COUNT(*) > 2  -- 超過 2 個更新事件
ORDER BY COUNT(*) DESC
LIMIT 10;

-- ========================================
-- 步驟 10: 檢查最近的所有訂單更新
-- ========================================
SELECT 
  '步驟 10：檢查最近的所有訂單更新（最近 20 個）' AS "診斷步驟";

SELECT 
  aggregate_id AS "訂單ID",
  payload->>'bookingNumber' AS "訂單編號",
  payload->>'status' AS "狀態",
  created_at AS "創建時間",
  processed_at AS "處理時間"
FROM outbox
WHERE aggregate_type = 'booking'
  AND event_type = 'updated'
ORDER BY created_at DESC
LIMIT 20;

-- ========================================
-- 診斷總結
-- ========================================
SELECT 
  '🎯 診斷總結' AS "標題";

SELECT 
  '請檢查以下關鍵信息：' AS "提示",
  '1. 步驟 2：該訂單有多少個 outbox 事件？' AS "檢查項目 1",
  '2. 步驟 3：是否有多個相同狀態的事件？' AS "檢查項目 2",
  '3. 步驟 4：是否有未處理的事件？' AS "檢查項目 3",
  '4. 步驟 6：是否有在同一秒內創建的多個事件？' AS "檢查項目 4",
  '5. 步驟 7：狀態變化順序是否正確？' AS "檢查項目 5";

-- ========================================
-- 可能的問題和解決方案
-- ========================================
SELECT 
  '💡 可能的問題和解決方案' AS "標題";

SELECT 
  '問題 1：Trigger 被觸發多次' AS "問題",
  '解決方案：檢查是否有重複的 Trigger，刪除重複的 Trigger' AS "解決方案";

SELECT 
  '問題 2：Edge Function 處理了舊事件' AS "問題",
  '解決方案：確保 Edge Function 按照 created_at 順序處理事件' AS "解決方案";

SELECT 
  '問題 3：Edge Function 未部署最新代碼' AS "問題",
  '解決方案：重新部署 Edge Function' AS "解決方案";

SELECT 
  '問題 4：有未處理的舊事件' AS "問題",
  '解決方案：手動標記舊事件為已處理，或刪除舊事件' AS "解決方案";

-- ========================================
-- 完成
-- ========================================
SELECT 
  '✅ 診斷腳本執行完成' AS "狀態",
  '請將上述診斷結果提供給開發團隊' AS "下一步";

