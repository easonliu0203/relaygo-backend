-- ============================================
-- 檢查錯誤訊息
-- ============================================
-- 
-- 用途：查看 outbox 事件的錯誤訊息，診斷失敗原因
-- 
-- ============================================

\echo '=== 最近的錯誤事件 ==='
\echo ''

SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  processed_at,
  retry_count,
  error_message,
  EXTRACT(EPOCH FROM (NOW() - created_at))::INTEGER as seconds_ago
FROM outbox
WHERE error_message IS NOT NULL
  OR (processed_at IS NULL AND retry_count > 0)
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo '=== 錯誤訊息分析 ==='
\echo ''

DO $$
DECLARE
  error_msg TEXT;
  error_count INTEGER;
BEGIN
  -- 獲取最近的錯誤訊息
  SELECT error_message, COUNT(*)
  INTO error_msg, error_count
  FROM outbox
  WHERE error_message IS NOT NULL
    AND created_at >= NOW() - INTERVAL '1 hour'
  GROUP BY error_message
  ORDER BY COUNT(*) DESC
  LIMIT 1;

  IF error_msg IS NOT NULL THEN
    RAISE NOTICE '最常見的錯誤（最近 1 小時）:';
    RAISE NOTICE '  錯誤次數: %', error_count;
    RAISE NOTICE '  錯誤訊息: %', error_msg;
    RAISE NOTICE '';
    
    -- 診斷錯誤類型
    IF error_msg LIKE '%FIREBASE_PROJECT_ID%' OR error_msg LIKE '%FIREBASE_API_KEY%' THEN
      RAISE NOTICE '❌ 診斷: 環境變數未設置';
      RAISE NOTICE '   問題: Edge Function 無法獲取 Firebase 環境變數';
      RAISE NOTICE '   修復: 在 Supabase Dashboard 設置環境變數';
      RAISE NOTICE '   步驟:';
      RAISE NOTICE '   1. 前往: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/settings/functions';
      RAISE NOTICE '   2. 設置 FIREBASE_PROJECT_ID 和 FIREBASE_API_KEY';
      RAISE NOTICE '   3. 保存並重新測試';
    ELSIF error_msg LIKE '%403%' OR error_msg LIKE '%Forbidden%' THEN
      RAISE NOTICE '❌ 診斷: Firestore 權限問題';
      RAISE NOTICE '   問題: Firebase API Key 沒有權限寫入 Firestore';
      RAISE NOTICE '   修復: 檢查 Firebase API Key 是否正確';
      RAISE NOTICE '   或檢查 Firestore 安全規則';
    ELSIF error_msg LIKE '%401%' OR error_msg LIKE '%Unauthorized%' THEN
      RAISE NOTICE '❌ 診斷: 認證失敗';
      RAISE NOTICE '   問題: Firebase API Key 無效';
      RAISE NOTICE '   修復: 重新獲取 Firebase API Key';
    ELSIF error_msg LIKE '%404%' OR error_msg LIKE '%Not Found%' THEN
      RAISE NOTICE '❌ 診斷: Firestore 專案不存在';
      RAISE NOTICE '   問題: FIREBASE_PROJECT_ID 不正確';
      RAISE NOTICE '   修復: 檢查 FIREBASE_PROJECT_ID 是否正確';
    ELSIF error_msg LIKE '%timeout%' OR error_msg LIKE '%ETIMEDOUT%' THEN
      RAISE NOTICE '❌ 診斷: 網路超時';
      RAISE NOTICE '   問題: 無法連接到 Firestore';
      RAISE NOTICE '   修復: 檢查網路連接或稍後重試';
    ELSE
      RAISE NOTICE '❌ 診斷: 未知錯誤';
      RAISE NOTICE '   建議: 查看 Edge Function 日誌獲取更多資訊';
      RAISE NOTICE '   URL: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions';
    END IF;
  ELSE
    RAISE NOTICE '✅ 沒有錯誤訊息';
    RAISE NOTICE '   說明: 最近 1 小時沒有錯誤事件';
  END IF;
  
  RAISE NOTICE '';
END $$;

\echo '=== 未處理事件統計 ==='
\echo ''

SELECT 
  COUNT(*) as total_pending,
  COUNT(*) FILTER (WHERE retry_count = 0) as first_attempt,
  COUNT(*) FILTER (WHERE retry_count = 1) as second_attempt,
  COUNT(*) FILTER (WHERE retry_count = 2) as third_attempt,
  COUNT(*) FILTER (WHERE retry_count >= 3) as max_retries
FROM outbox
WHERE processed_at IS NULL
  AND created_at >= NOW() - INTERVAL '1 hour';

\echo ''
\echo '解讀：'
\echo '- first_attempt: 第一次嘗試失敗的事件'
\echo '- second_attempt: 第二次嘗試失敗的事件'
\echo '- third_attempt: 第三次嘗試失敗的事件'
\echo '- max_retries: 已達到最大重試次數（不會再處理）'
\echo ''

