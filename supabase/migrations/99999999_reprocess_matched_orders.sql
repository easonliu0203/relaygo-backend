-- 重新處理 status = 'matched' 的訂單
-- 用途：修復 Edge Function 部署前已處理的訂單，讓它們使用新的狀態映射邏輯
-- 
-- 使用方法：
-- 1. 在 Supabase SQL Editor 中執行此腳本
-- 2. 或者使用命令：npx supabase db push
--
-- 注意：此腳本是一次性的修復腳本，執行後可以刪除

-- 步驟 1：查看當前需要重新處理的記錄
DO $$
DECLARE
  matched_count INTEGER;
  trip_ended_count INTEGER;
BEGIN
  -- 統計 status = 'matched' 的記錄數量
  SELECT COUNT(*) INTO matched_count
  FROM outbox
  WHERE payload->>'status' = 'matched'
    AND processed = true;
  
  -- 統計 status = 'trip_ended' 的記錄數量
  SELECT COUNT(*) INTO trip_ended_count
  FROM outbox
  WHERE payload->>'status' = 'trip_ended'
    AND processed = true;
  
  RAISE NOTICE '找到 % 筆 status = ''matched'' 的已處理記錄', matched_count;
  RAISE NOTICE '找到 % 筆 status = ''trip_ended'' 的已處理記錄', trip_ended_count;
END $$;

-- 步驟 2：重新觸發 status = 'matched' 的記錄
-- 這些記錄應該映射為 Firestore 的 'awaitingDriver' 狀態
UPDATE outbox
SET 
  processed = false,
  processed_at = NULL
WHERE payload->>'status' = 'matched'
  AND processed = true;

-- 步驟 3：重新觸發 status = 'trip_ended' 的記錄
-- 這些記錄應該映射為 Firestore 的 'awaitingBalance' 狀態
UPDATE outbox
SET 
  processed = false,
  processed_at = NULL
WHERE payload->>'status' = 'trip_ended'
  AND processed = true;

-- 步驟 4：驗證更新結果
DO $$
DECLARE
  matched_reprocess_count INTEGER;
  trip_ended_reprocess_count INTEGER;
BEGIN
  -- 統計待重新處理的 status = 'matched' 記錄
  SELECT COUNT(*) INTO matched_reprocess_count
  FROM outbox
  WHERE payload->>'status' = 'matched'
    AND processed = false;
  
  -- 統計待重新處理的 status = 'trip_ended' 記錄
  SELECT COUNT(*) INTO trip_ended_reprocess_count
  FROM outbox
  WHERE payload->>'status' = 'trip_ended'
    AND processed = false;
  
  RAISE NOTICE '已標記 % 筆 status = ''matched'' 的記錄待重新處理', matched_reprocess_count;
  RAISE NOTICE '已標記 % 筆 status = ''trip_ended'' 的記錄待重新處理', trip_ended_reprocess_count;
  RAISE NOTICE 'Edge Function 將在接下來的幾秒內自動處理這些記錄';
END $$;

-- 步驟 5：顯示待重新處理的記錄詳情（用於驗證）
SELECT 
  id,
  aggregate_id,
  event_type,
  payload->>'status' as status,
  payload->>'driver_id' as driver_id,
  processed,
  created_at,
  processed_at
FROM outbox
WHERE (payload->>'status' = 'matched' OR payload->>'status' = 'trip_ended')
  AND processed = false
ORDER BY created_at DESC
LIMIT 20;

-- 注意事項：
-- 1. 此腳本會將 processed = true 的記錄重新設為 processed = false
-- 2. Edge Function 會自動檢測並處理這些記錄
-- 3. 處理時間通常在 5-10 秒內
-- 4. 如果 Edge Function 沒有自動處理，請檢查：
--    - Edge Function 是否正在運行
--    - Edge Function 的日誌是否有錯誤
--    - Supabase 的 Database Webhooks 是否已啟用

