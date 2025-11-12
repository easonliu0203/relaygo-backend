-- 查詢異常訂單詳情
-- 訂單 ID: 9452ee79-8e43-492e-a89d-8eb4d7d3ae90
-- 訂單編號: FINAL_1760637491

-- 查詢訂單基本信息
SELECT 
  '訂單基本信息' AS section;

SELECT 
  id,
  booking_number,
  status,
  customer_id,
  driver_id,
  created_at,
  updated_at,
  cancelled_at,
  cancellation_reason,
  pickup_location,
  destination,
  start_date,
  start_time
FROM bookings
WHERE booking_number = 'FINAL_1760637491'
   OR id = '9452ee79-8e43-492e-a89d-8eb4d7d3ae90';

-- 查詢相關的 Outbox 事件
SELECT 
  '相關的 Outbox 事件' AS section;

SELECT 
  id,
  aggregate_type,
  aggregate_id,
  event_type,
  payload,
  processed_at,
  retry_count,
  created_at
FROM outbox
WHERE aggregate_id = '9452ee79-8e43-492e-a89d-8eb4d7d3ae90'
ORDER BY created_at ASC;

-- 查詢相關的 HTTP 請求記錄
SELECT 
  '相關的 HTTP 請求記錄' AS section;

SELECT 
  id,
  status_code,
  content,
  created
FROM net._http_response
WHERE created > '2025-10-16 17:58:00'::timestamp
  AND created < '2025-10-16 18:01:00'::timestamp
ORDER BY created ASC;

-- 查詢所有 FINAL_ 開頭的測試訂單
SELECT 
  '所有 FINAL_ 測試訂單' AS section;

SELECT 
  id,
  booking_number,
  status,
  created_at,
  updated_at,
  cancelled_at,
  cancellation_reason
FROM bookings
WHERE booking_number LIKE 'FINAL_%'
ORDER BY created_at DESC;

