-- ========================================
-- 檢查並修復重複 Trigger 問題
-- ========================================
-- 問題：可能有多個相同的 Trigger 導致重複寫入 outbox
-- 創建時間：2025-10-15
-- ========================================

-- ========================================
-- 步驟 1: 檢查 bookings 表上的所有 Trigger
-- ========================================
SELECT 
  '步驟 1：檢查 bookings 表上的所有 Trigger' AS "診斷步驟";

SELECT 
  tgname AS "Trigger 名稱",
  proname AS "函數名稱",
  CASE tgtype & 2
    WHEN 2 THEN 'BEFORE'
    ELSE 'AFTER'
  END AS "觸發時機",
  CASE 
    WHEN tgtype & 4 = 4 THEN 'INSERT'
    WHEN tgtype & 8 = 8 THEN 'DELETE'
    WHEN tgtype & 16 = 16 THEN 'UPDATE'
    ELSE 'UNKNOWN'
  END AS "觸發事件",
  CASE tgenabled
    WHEN 'O' THEN '啟用'
    WHEN 'D' THEN '停用'
    WHEN 'R' THEN '僅副本啟用'
    WHEN 'A' THEN '總是啟用'
  END AS "狀態",
  tgrelid::regclass AS "表名"
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'bookings'::regclass
  AND NOT tgisinternal  -- 排除內部 Trigger
ORDER BY tgname;

-- ========================================
-- 步驟 2: 檢查是否有重複的 bookings_outbox_trigger
-- ========================================
SELECT 
  '步驟 2：檢查是否有重複的 bookings_outbox_trigger' AS "診斷步驟";

SELECT 
  COUNT(*) AS "Trigger 數量",
  CASE 
    WHEN COUNT(*) > 1 THEN '❌ 發現重複 Trigger！'
    WHEN COUNT(*) = 1 THEN '✅ 正常，只有一個 Trigger'
    ELSE '⚠️  未找到 Trigger'
  END AS "狀態"
FROM pg_trigger
WHERE tgname = 'bookings_outbox_trigger'
  AND tgrelid = 'bookings'::regclass
  AND NOT tgisinternal;

-- ========================================
-- 步驟 3: 檢查 bookings_to_outbox 函數
-- ========================================
SELECT 
  '步驟 3：檢查 bookings_to_outbox 函數' AS "診斷步驟";

SELECT 
  proname AS "函數名稱",
  pg_get_functiondef(oid) AS "函數定義"
FROM pg_proc
WHERE proname = 'bookings_to_outbox';

-- ========================================
-- 修復方案：刪除重複的 Trigger
-- ========================================
-- ⚠️  警告：只有在確認有重複 Trigger 時才執行此步驟
-- ⚠️  執行前請先備份數據

-- 取消註釋以下代碼以執行修復：

/*
-- 刪除所有 bookings_outbox_trigger
DROP TRIGGER IF EXISTS bookings_outbox_trigger ON bookings;

-- 重新創建 Trigger（確保只有一個）
CREATE TRIGGER bookings_outbox_trigger
AFTER INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION bookings_to_outbox();

-- 驗證 Trigger 已正確創建
SELECT 
  '✅ Trigger 已重新創建' AS "狀態",
  tgname AS "Trigger 名稱",
  proname AS "函數名稱"
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgname = 'bookings_outbox_trigger'
  AND tgrelid = 'bookings'::regclass;
*/

-- ========================================
-- 步驟 4: 檢查最近是否有重複的 outbox 事件
-- ========================================
SELECT 
  '步驟 4：檢查最近是否有重複的 outbox 事件' AS "診斷步驟";

-- 查找在同一秒內創建的多個事件
SELECT 
  aggregate_id AS "訂單ID",
  DATE_TRUNC('second', created_at) AS "創建時間(秒)",
  COUNT(*) AS "事件數量",
  STRING_AGG(id::TEXT, ', ') AS "事件ID列表",
  STRING_AGG(DISTINCT payload->>'status', ', ') AS "狀態列表"
FROM outbox
WHERE aggregate_type = 'booking'
  AND created_at > NOW() - INTERVAL '1 hour'  -- 最近 1 小時
GROUP BY aggregate_id, DATE_TRUNC('second', created_at)
HAVING COUNT(*) > 1
ORDER BY DATE_TRUNC('second', created_at) DESC
LIMIT 20;

-- ========================================
-- 步驟 5: 清理重複的未處理事件
-- ========================================
-- ⚠️  警告：此操作會刪除重複的事件，請謹慎執行
-- ⚠️  執行前請先備份數據

-- 取消註釋以下代碼以執行清理：

/*
-- 對於每個訂單，只保留最新的未處理事件，刪除舊的
WITH duplicate_events AS (
  SELECT 
    id,
    aggregate_id,
    created_at,
    ROW_NUMBER() OVER (
      PARTITION BY aggregate_id 
      ORDER BY created_at DESC
    ) AS rn
  FROM outbox
  WHERE processed_at IS NULL
    AND aggregate_type = 'booking'
)
DELETE FROM outbox
WHERE id IN (
  SELECT id 
  FROM duplicate_events 
  WHERE rn > 1  -- 刪除除了最新事件之外的所有事件
);

-- 顯示清理結果
SELECT 
  '✅ 重複事件已清理' AS "狀態",
  COUNT(*) AS "剩餘未處理事件數量"
FROM outbox
WHERE processed_at IS NULL
  AND aggregate_type = 'booking';
*/

-- ========================================
-- 步驟 6: 手動標記舊事件為已處理
-- ========================================
-- ⚠️  警告：此操作會標記舊事件為已處理
-- ⚠️  執行前請確認這些事件確實不需要處理

-- 取消註釋以下代碼以執行標記：

/*
-- 標記所有創建時間早於最新事件的未處理事件
WITH latest_events AS (
  SELECT 
    aggregate_id,
    MAX(created_at) AS latest_created_at
  FROM outbox
  WHERE aggregate_type = 'booking'
  GROUP BY aggregate_id
)
UPDATE outbox o
SET 
  processed_at = NOW(),
  error_message = '手動標記為已處理（舊事件）'
FROM latest_events le
WHERE o.aggregate_id = le.aggregate_id
  AND o.created_at < le.latest_created_at
  AND o.processed_at IS NULL
  AND o.aggregate_type = 'booking';

-- 顯示標記結果
SELECT 
  '✅ 舊事件已標記為已處理' AS "狀態",
  COUNT(*) AS "標記的事件數量"
FROM outbox
WHERE error_message = '手動標記為已處理（舊事件）';
*/

-- ========================================
-- 完成
-- ========================================
SELECT 
  '✅ 檢查完成' AS "狀態",
  '請根據診斷結果決定是否執行修復操作' AS "下一步";

