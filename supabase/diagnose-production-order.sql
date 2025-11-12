-- Diagnose Production Order Issue
-- This script checks for recent orders and their sync status

-- ============================================
-- Check 1: Recent Bookings (Last 24 hours)
-- ============================================

SELECT 
  '=== Recent Bookings (Last 24 hours) ===' as info;

SELECT 
  id,
  booking_number,
  customer_id,
  status,
  pickup_location,
  destination,
  start_date,
  total_amount,
  created_at,
  updated_at
FROM bookings
WHERE created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- Check 2: Outbox Events for Recent Bookings
-- ============================================

SELECT 
  '=== Outbox Events for Recent Bookings ===' as info;

WITH recent_bookings AS (
  SELECT id, booking_number
  FROM bookings
  WHERE created_at >= NOW() - INTERVAL '24 hours'
)
SELECT 
  o.id as event_id,
  o.aggregate_type,
  o.aggregate_id,
  o.event_type,
  o.payload->>'bookingNumber' as booking_number,
  o.payload->>'status' as booking_status,
  o.created_at as event_created_at,
  o.processed_at,
  o.retry_count,
  o.error_message,
  CASE 
    WHEN o.processed_at IS NOT NULL THEN '✅ Synced'
    WHEN o.error_message IS NOT NULL THEN '❌ Error'
    ELSE '⏳ Pending'
  END as sync_status
FROM outbox o
WHERE o.aggregate_type = 'booking'
  AND o.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY o.created_at DESC
LIMIT 20;

-- ============================================
-- Check 3: Event Count per Recent Booking
-- ============================================

SELECT 
  '=== Event Count per Recent Booking ===' as info;

WITH recent_bookings AS (
  SELECT id, booking_number, created_at
  FROM bookings
  WHERE created_at >= NOW() - INTERVAL '24 hours'
)
SELECT 
  rb.booking_number,
  rb.created_at as booking_created_at,
  COUNT(o.id) as event_count,
  COUNT(CASE WHEN o.processed_at IS NOT NULL THEN 1 END) as synced_count,
  COUNT(CASE WHEN o.error_message IS NOT NULL THEN 1 END) as error_count,
  CASE 
    WHEN COUNT(o.id) = 0 THEN '❌ NO EVENTS - Trigger not firing'
    WHEN COUNT(o.id) > 1 THEN '⚠️ DUPLICATE EVENTS'
    WHEN COUNT(CASE WHEN o.processed_at IS NOT NULL THEN 1 END) = 1 THEN '✅ SYNCED'
    WHEN COUNT(CASE WHEN o.error_message IS NOT NULL THEN 1 END) > 0 THEN '❌ SYNC ERROR'
    ELSE '⏳ PENDING SYNC'
  END as status
FROM recent_bookings rb
LEFT JOIN outbox o ON o.payload->>'bookingNumber' = rb.booking_number
GROUP BY rb.booking_number, rb.created_at
ORDER BY rb.created_at DESC;

-- ============================================
-- Check 4: Cron Job Execution History
-- ============================================

SELECT 
  '=== Cron Job Execution History (Last 10) ===' as info;

SELECT 
  jobid,
  jobname,
  runid,
  job_pid,
  database,
  username,
  command,
  status,
  return_message,
  start_time,
  end_time
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 10;

-- ============================================
-- Check 5: Unprocessed Events (Stuck Events)
-- ============================================

SELECT 
  '=== Unprocessed Events (Older than 5 minutes) ===' as info;

SELECT 
  id as event_id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  retry_count,
  error_message,
  EXTRACT(EPOCH FROM (NOW() - created_at))/60 as minutes_old
FROM outbox
WHERE processed_at IS NULL
  AND created_at < NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- Check 6: Recent Errors in Outbox
-- ============================================

SELECT 
  '=== Recent Errors in Outbox ===' as info;

SELECT 
  id as event_id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  retry_count,
  error_message,
  last_error_at
FROM outbox
WHERE error_message IS NOT NULL
  AND created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- Check 7: Customer's Recent Bookings
-- ============================================
-- Note: You'll need to replace 'CUSTOMER_FIREBASE_UID' with actual UID

SELECT 
  '=== Customer Recent Bookings (Replace UID below) ===' as info;

-- Uncomment and replace with actual customer Firebase UID:
-- SELECT 
--   b.id,
--   b.booking_number,
--   b.status,
--   b.pickup_location,
--   b.created_at,
--   u.firebase_uid,
--   u.email
-- FROM bookings b
-- JOIN users u ON b.customer_id = u.id
-- WHERE u.firebase_uid = 'CUSTOMER_FIREBASE_UID'
-- ORDER BY b.created_at DESC
-- LIMIT 5;

-- ============================================
-- Check 8: Summary Statistics
-- ============================================

SELECT 
  '=== Summary Statistics ===' as info;

SELECT 
  'Total Bookings (24h)' as metric,
  COUNT(*) as count
FROM bookings
WHERE created_at >= NOW() - INTERVAL '24 hours'

UNION ALL

SELECT 
  'Total Events (24h)' as metric,
  COUNT(*) as count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '24 hours'

UNION ALL

SELECT 
  'Synced Events (24h)' as metric,
  COUNT(*) as count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '24 hours'
  AND processed_at IS NOT NULL

UNION ALL

SELECT 
  'Pending Events (24h)' as metric,
  COUNT(*) as count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '24 hours'
  AND processed_at IS NULL
  AND error_message IS NULL

UNION ALL

SELECT 
  'Failed Events (24h)' as metric,
  COUNT(*) as count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '24 hours'
  AND error_message IS NOT NULL;

-- ============================================
-- Expected Results Analysis:
-- ============================================
-- 
-- SCENARIO A: Order Created, Event Synced ✅
-- - Recent Bookings: Shows your order
-- - Outbox Events: Shows 1 event with processed_at filled
-- - Event Count: Shows "✅ SYNCED"
-- - Issue: Client reading from wrong location or wrong ID
--
-- SCENARIO B: Order Created, Event Pending ⏳
-- - Recent Bookings: Shows your order
-- - Outbox Events: Shows 1 event with processed_at = NULL
-- - Event Count: Shows "⏳ PENDING SYNC"
-- - Issue: Cron job not running or sync function slow
--
-- SCENARIO C: Order Created, Event Failed ❌
-- - Recent Bookings: Shows your order
-- - Outbox Events: Shows 1 event with error_message
-- - Event Count: Shows "❌ SYNC ERROR"
-- - Issue: Sync function has error, check error_message
--
-- SCENARIO D: Order Not Created ❌
-- - Recent Bookings: Empty or doesn't show your order
-- - Issue: Client not writing to Supabase correctly
--
-- SCENARIO E: No Event Created ❌
-- - Recent Bookings: Shows your order
-- - Outbox Events: Empty
-- - Event Count: Shows "❌ NO EVENTS"
-- - Issue: Trigger not firing (but tests showed it works!)

