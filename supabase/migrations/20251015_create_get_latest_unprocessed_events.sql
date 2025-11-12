-- ========================================
-- 創建 RPC 函數：獲取每個訂單的最新未處理事件
-- ========================================
-- 目的：防止 Edge Function 處理舊事件導致狀態倒退
-- 創建時間：2025-10-15
-- ========================================

-- 刪除舊函數（如果存在）
DROP FUNCTION IF EXISTS get_latest_unprocessed_events(INT);

-- 創建新函數
CREATE OR REPLACE FUNCTION get_latest_unprocessed_events(event_limit INT DEFAULT 10)
RETURNS SETOF outbox AS $$
BEGIN
  -- 使用 DISTINCT ON 只選擇每個訂單的最新未處理事件
  -- 這樣可以確保每個訂單只處理最新的狀態，避免舊事件覆蓋新狀態
  RETURN QUERY
  SELECT DISTINCT ON (aggregate_id) *
  FROM outbox
  WHERE processed_at IS NULL  -- 未處理的事件
    AND retry_count < 3       -- 重試次數少於 3 次
    AND aggregate_type = 'booking'  -- 只處理訂單事件
  ORDER BY aggregate_id, created_at DESC  -- 每個訂單按創建時間降序，取最新的
  LIMIT event_limit;
END;
$$ LANGUAGE plpgsql;

-- 添加函數註釋
COMMENT ON FUNCTION get_latest_unprocessed_events(INT) IS 
'獲取每個訂單的最新未處理事件，用於 Edge Function 同步到 Firestore。
使用 DISTINCT ON 確保每個訂單只返回最新的事件，防止舊事件覆蓋新狀態。';

-- ========================================
-- 測試函數
-- ========================================

-- 測試 1：查看函數返回的事件
SELECT 
  '測試 1：查看函數返回的事件' AS "測試項目";

SELECT 
  id AS "事件ID",
  aggregate_id AS "訂單ID",
  event_type AS "事件類型",
  payload->>'status' AS "狀態",
  created_at AS "創建時間"
FROM get_latest_unprocessed_events(10)
ORDER BY created_at DESC;

-- 測試 2：比較新舊查詢方式的差異
SELECT 
  '測試 2：比較新舊查詢方式的差異' AS "測試項目";

-- 舊方式：可能返回多個同一訂單的事件
WITH old_way AS (
  SELECT 
    aggregate_id,
    COUNT(*) AS event_count
  FROM outbox
  WHERE processed_at IS NULL
    AND retry_count < 3
    AND aggregate_type = 'booking'
  GROUP BY aggregate_id
  HAVING COUNT(*) > 1
)
SELECT 
  '舊方式：有 ' || COUNT(*) || ' 個訂單有多個未處理事件' AS "結果"
FROM old_way;

-- 新方式：每個訂單只返回一個事件
WITH new_way AS (
  SELECT 
    aggregate_id,
    COUNT(*) AS event_count
  FROM get_latest_unprocessed_events(100)
  GROUP BY aggregate_id
  HAVING COUNT(*) > 1
)
SELECT 
  '新方式：有 ' || COALESCE(COUNT(*), 0) || ' 個訂單有多個事件（應該是 0）' AS "結果"
FROM new_way;

-- ========================================
-- 驗證函數正確性
-- ========================================

-- 驗證 1：確認每個訂單只返回一個事件
SELECT 
  '驗證 1：確認每個訂單只返回一個事件' AS "驗證項目";

SELECT 
  aggregate_id AS "訂單ID",
  COUNT(*) AS "事件數量",
  CASE 
    WHEN COUNT(*) = 1 THEN '✅ 正確'
    ELSE '❌ 錯誤：有多個事件'
  END AS "驗證結果"
FROM get_latest_unprocessed_events(100)
GROUP BY aggregate_id
ORDER BY COUNT(*) DESC;

-- 驗證 2：確認返回的是最新事件
SELECT 
  '驗證 2：確認返回的是最新事件' AS "驗證項目";

WITH function_results AS (
  SELECT 
    aggregate_id,
    created_at AS function_created_at
  FROM get_latest_unprocessed_events(100)
),
latest_events AS (
  SELECT 
    aggregate_id,
    MAX(created_at) AS latest_created_at
  FROM outbox
  WHERE processed_at IS NULL
    AND retry_count < 3
    AND aggregate_type = 'booking'
  GROUP BY aggregate_id
)
SELECT 
  fr.aggregate_id AS "訂單ID",
  fr.function_created_at AS "函數返回的事件時間",
  le.latest_created_at AS "實際最新事件時間",
  CASE 
    WHEN fr.function_created_at = le.latest_created_at THEN '✅ 正確'
    ELSE '❌ 錯誤：不是最新事件'
  END AS "驗證結果"
FROM function_results fr
JOIN latest_events le ON fr.aggregate_id = le.aggregate_id
ORDER BY fr.aggregate_id;

-- ========================================
-- 完成
-- ========================================
SELECT 
  '✅ RPC 函數創建完成' AS "狀態",
  'get_latest_unprocessed_events' AS "函數名稱",
  '可以在 Edge Function 中使用此函數' AS "下一步";

