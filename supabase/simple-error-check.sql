-- ============================================
-- 簡單錯誤檢查（最快速版本）
-- ============================================
-- 
-- 用途：快速查看錯誤訊息
-- 使用方式：複製全部內容，貼到 Supabase SQL Editor，點擊 Run
-- 
-- ============================================

-- 查看最近的錯誤事件
SELECT 
  '最近的錯誤事件' as 檢查項目,
  id as 事件ID,
  payload->>'bookingNumber' as 訂單編號,
  error_message as 錯誤訊息,
  retry_count as 重試次數,
  created_at as 創建時間,
  EXTRACT(EPOCH FROM (NOW() - created_at))::INTEGER as 秒數前
FROM outbox
WHERE error_message IS NOT NULL
  AND created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;

-- 統計未處理事件
SELECT 
  '未處理事件統計' as 檢查項目,
  COUNT(*) as 總數,
  COUNT(*) FILTER (WHERE retry_count >= 3) as 已達最大重試次數,
  COUNT(*) FILTER (WHERE retry_count < 3) as 仍可重試
FROM outbox
WHERE processed_at IS NULL
  AND created_at >= NOW() - INTERVAL '1 hour';

-- 查看所有待處理事件
SELECT 
  '所有待處理事件' as 檢查項目,
  id as 事件ID,
  aggregate_type as 類型,
  payload->>'bookingNumber' as 訂單編號,
  retry_count as 重試次數,
  error_message as 錯誤訊息,
  created_at as 創建時間
FROM outbox
WHERE processed_at IS NULL
  AND created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

