-- 快速驗證查詢 - 檢查最近的訂單和同步狀態

-- 檢查最近的訂單和同步狀態
SELECT 
  b.id as booking_id,
  b.booking_number,
  b.status,
  b.created_at as booking_created,
  o.id as event_id,
  o.aggregate_type,
  o.event_type,
  o.created_at as event_created,
  o.processed_at,
  CASE 
    WHEN o.processed_at IS NOT NULL THEN '✅ 已同步'
    WHEN o.processed_at IS NULL AND EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 60 THEN '⏳ 等待中'
    WHEN o.processed_at IS NULL THEN '❌ 未同步'
  END as sync_status,
  o.error_message
FROM bookings b
LEFT JOIN outbox o ON o.payload->>'id' = b.id::TEXT
WHERE b.created_at >= NOW() - INTERVAL '1 hour'
ORDER BY b.created_at DESC
LIMIT 10;

