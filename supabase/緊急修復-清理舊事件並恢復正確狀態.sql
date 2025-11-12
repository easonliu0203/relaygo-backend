-- ========================================
-- 緊急修復：清理舊事件並恢復正確狀態
-- ========================================
-- 問題：Firestore 狀態從 inProgress 倒退回 pending
-- 原因：Edge Function 處理了舊的 outbox 事件
-- 解決：清理舊事件，只保留最新事件
-- ========================================
-- ⚠️  警告：執行前請先備份數據
-- ⚠️  建議先在測試環境執行
-- ========================================

-- ========================================
-- 步驟 1: 查看當前問題的嚴重程度
-- ========================================
SELECT 
  '步驟 1：查看當前問題的嚴重程度' AS "步驟";

-- 統計有多個未處理事件的訂單
SELECT 
  COUNT(DISTINCT aggregate_id) AS "受影響的訂單數量",
  SUM(event_count) AS "總未處理事件數量",
  SUM(event_count) - COUNT(DISTINCT aggregate_id) AS "需要清理的事件數量"
FROM (
  SELECT 
    aggregate_id,
    COUNT(*) AS event_count
  FROM outbox
  WHERE processed_at IS NULL
    AND aggregate_type = 'booking'
  GROUP BY aggregate_id
  HAVING COUNT(*) > 1
) AS duplicate_events;

-- ========================================
-- 步驟 2: 查看具體的重複事件
-- ========================================
SELECT 
  '步驟 2：查看具體的重複事件（前 20 個訂單）' AS "步驟";

SELECT 
  aggregate_id AS "訂單ID",
  COUNT(*) AS "未處理事件數量",
  STRING_AGG(DISTINCT payload->>'status', ' → ' ORDER BY payload->>'status') AS "狀態列表",
  MIN(created_at) AS "最早事件時間",
  MAX(created_at) AS "最新事件時間"
FROM outbox
WHERE processed_at IS NULL
  AND aggregate_type = 'booking'
GROUP BY aggregate_id
HAVING COUNT(*) > 1
ORDER BY MAX(created_at) DESC
LIMIT 20;

-- ========================================
-- 步驟 3: 備份即將清理的事件（可選）
-- ========================================
-- 取消註釋以下代碼以創建備份表：

/*
-- 創建備份表
CREATE TABLE IF NOT EXISTS outbox_backup_20251015 AS
SELECT * FROM outbox WHERE 1=0;  -- 只複製結構

-- 備份即將清理的事件
INSERT INTO outbox_backup_20251015
SELECT o.*
FROM outbox o
WHERE o.processed_at IS NULL
  AND o.aggregate_type = 'booking'
  AND o.id NOT IN (
    -- 排除每個訂單的最新事件
    SELECT DISTINCT ON (aggregate_id) id
    FROM outbox
    WHERE processed_at IS NULL
      AND aggregate_type = 'booking'
    ORDER BY aggregate_id, created_at DESC
  );

-- 顯示備份結果
SELECT 
  '✅ 備份完成' AS "狀態",
  COUNT(*) AS "備份的事件數量"
FROM outbox_backup_20251015;
*/

-- ========================================
-- 步驟 4: 清理舊事件（標記為已處理）
-- ========================================
-- ⚠️  警告：此操作會修改數據，請確認後再執行
-- 取消註釋以下代碼以執行清理：

/*
-- 方案 A：標記舊事件為已處理（推薦，可以保留歷史記錄）
WITH latest_events AS (
  -- 找出每個訂單的最新未處理事件
  SELECT DISTINCT ON (aggregate_id) 
    id,
    aggregate_id,
    created_at
  FROM outbox
  WHERE processed_at IS NULL
    AND aggregate_type = 'booking'
  ORDER BY aggregate_id, created_at DESC
)
UPDATE outbox o
SET 
  processed_at = NOW(),
  error_message = '自動清理：舊事件（' || o.created_at || '），最新事件時間：' || le.created_at
FROM latest_events le
WHERE o.aggregate_id = le.aggregate_id
  AND o.id != le.id  -- 不是最新事件
  AND o.processed_at IS NULL
  AND o.aggregate_type = 'booking';

-- 顯示清理結果
SELECT 
  '✅ 舊事件已標記為已處理' AS "狀態",
  COUNT(*) AS "標記的事件數量"
FROM outbox
WHERE error_message LIKE '自動清理：舊事件%';
*/

/*
-- 方案 B：直接刪除舊事件（不推薦，會丟失歷史記錄）
WITH latest_events AS (
  SELECT DISTINCT ON (aggregate_id) id
  FROM outbox
  WHERE processed_at IS NULL
    AND aggregate_type = 'booking'
  ORDER BY aggregate_id, created_at DESC
)
DELETE FROM outbox
WHERE processed_at IS NULL
  AND aggregate_type = 'booking'
  AND id NOT IN (SELECT id FROM latest_events);

-- 顯示刪除結果
SELECT 
  '✅ 舊事件已刪除' AS "狀態";
*/

-- ========================================
-- 步驟 5: 驗證清理結果
-- ========================================
SELECT 
  '步驟 5：驗證清理結果' AS "步驟";

-- 確認每個訂單只有一個未處理事件
SELECT 
  aggregate_id AS "訂單ID",
  COUNT(*) AS "未處理事件數量",
  CASE 
    WHEN COUNT(*) = 1 THEN '✅ 正常'
    ELSE '❌ 仍有多個事件'
  END AS "狀態"
FROM outbox
WHERE processed_at IS NULL
  AND aggregate_type = 'booking'
GROUP BY aggregate_id
HAVING COUNT(*) > 1;

-- 如果上面的查詢沒有返回任何結果，說明清理成功
SELECT 
  CASE 
    WHEN NOT EXISTS (
      SELECT 1
      FROM outbox
      WHERE processed_at IS NULL
        AND aggregate_type = 'booking'
      GROUP BY aggregate_id
      HAVING COUNT(*) > 1
    ) THEN '✅ 清理成功！每個訂單只有一個未處理事件'
    ELSE '⚠️  仍有訂單有多個未處理事件，請檢查'
  END AS "驗證結果";

-- ========================================
-- 步驟 6: 手動觸發 Edge Function 同步
-- ========================================
SELECT 
  '步驟 6：手動觸發 Edge Function 同步' AS "步驟";

-- 更新所有有未處理事件的訂單，觸發 Edge Function 同步
-- 取消註釋以下代碼以執行：

/*
UPDATE bookings
SET updated_at = NOW()
WHERE id IN (
  SELECT DISTINCT aggregate_id
  FROM outbox
  WHERE processed_at IS NULL
    AND aggregate_type = 'booking'
);

SELECT 
  '✅ 已觸發同步' AS "狀態",
  COUNT(*) AS "觸發的訂單數量"
FROM bookings
WHERE id IN (
  SELECT DISTINCT aggregate_id
  FROM outbox
  WHERE processed_at IS NULL
    AND aggregate_type = 'booking'
);
*/

-- ========================================
-- 步驟 7: 檢查特定訂單的狀態
-- ========================================
-- 如果你知道具體的訂單 ID，可以檢查其狀態

-- 取消註釋並填寫訂單 ID：
/*
\set booking_id 'YOUR_BOOKING_ID'

SELECT 
  '步驟 7：檢查特定訂單的狀態' AS "步驟";

-- Supabase 訂單狀態
SELECT 
  'Supabase 訂單狀態' AS "來源",
  id AS "訂單ID",
  status AS "狀態",
  actual_start_time AS "行程開始時間",
  updated_at AS "最後更新時間"
FROM bookings
WHERE id = :'booking_id';

-- Outbox 事件
SELECT 
  'Outbox 事件' AS "來源",
  id AS "事件ID",
  event_type AS "事件類型",
  payload->>'status' AS "狀態",
  created_at AS "創建時間",
  processed_at AS "處理時間"
FROM outbox
WHERE aggregate_id = :'booking_id'
ORDER BY created_at DESC
LIMIT 5;
*/

-- ========================================
-- 完成
-- ========================================
SELECT 
  '✅ 緊急修復腳本執行完成' AS "狀態",
  '請檢查驗證結果，確認問題已解決' AS "下一步",
  '如果問題仍然存在，請查看 Edge Function 日誌' AS "提示";

-- ========================================
-- 後續建議
-- ========================================
SELECT 
  '📋 後續建議' AS "標題";

SELECT 
  '1. 創建 RPC 函數 get_latest_unprocessed_events' AS "建議 1",
  '2. 修改 Edge Function 使用新的 RPC 函數' AS "建議 2",
  '3. 重新部署 Edge Function' AS "建議 3",
  '4. 檢查是否有重複的 Trigger' AS "建議 4",
  '5. 設置定時任務定期清理舊事件' AS "建議 5";

