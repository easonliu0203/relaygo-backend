-- Verify Production Flow
-- Run this after creating an order from the mobile app

-- ============================================
-- Step 1: Check Recent Bookings (Last 1 hour)
-- ============================================

SELECT 
  '=== Step 1: Recent Bookings (Last 1 hour) ===' as info;

SELECT 
  id,
  booking_number,
  status,
  pickup_location,
  destination,
  total_amount,
  deposit_amount,
  created_at,
  EXTRACT(EPOCH FROM (NOW() - created_at))/60 as minutes_ago
FROM bookings
WHERE created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;

-- Expected: Should see your newly created booking

-- ============================================
-- Step 2: Check Outbox Events for Recent Bookings
-- ============================================

SELECT 
  '=== Step 2: Outbox Events for Recent Bookings ===' as info;

WITH recent_bookings AS (
  SELECT id, booking_number
  FROM bookings
  WHERE created_at >= NOW() - INTERVAL '1 hour'
)
SELECT 
  o.id as event_id,
  o.aggregate_type,
  o.event_type,
  o.payload->>'bookingNumber' as booking_number,
  o.payload->>'status' as booking_status,
  o.created_at as event_created,
  o.processed_at,
  o.retry_count,
  o.error_message,
  CASE 
    WHEN o.processed_at IS NOT NULL THEN '✅ Synced to Firestore'
    WHEN o.error_message IS NOT NULL THEN '❌ Sync Failed'
    ELSE '⏳ Waiting for Sync'
  END as sync_status,
  EXTRACT(EPOCH FROM (NOW() - o.created_at))/60 as minutes_since_created
FROM outbox o
INNER JOIN recent_bookings rb ON o.payload->>'bookingNumber' = rb.booking_number
ORDER BY o.created_at DESC;

-- Expected: 
-- - Should see 1 event per booking
-- - If processed_at is NULL and < 1 minute old: Normal (waiting for cron)
-- - If processed_at is NULL and > 1 minute old: Issue (cron not running)
-- - If processed_at has value: ✅ Successfully synced
-- - If error_message has value: ❌ Sync failed

-- ============================================
-- Step 3: Check Sync Status Summary
-- ============================================

SELECT 
  '=== Step 3: Sync Status Summary ===' as info;

WITH recent_bookings AS (
  SELECT id, booking_number, created_at
  FROM bookings
  WHERE created_at >= NOW() - INTERVAL '1 hour'
)
SELECT 
  rb.booking_number,
  rb.created_at as booking_created,
  COUNT(o.id) as event_count,
  MAX(o.processed_at) as last_synced_at,
  MAX(o.error_message) as last_error,
  CASE 
    WHEN COUNT(o.id) = 0 THEN '❌ NO EVENT - Trigger not firing!'
    WHEN COUNT(o.id) > 1 THEN '⚠️ DUPLICATE EVENTS - Multiple triggers!'
    WHEN MAX(o.processed_at) IS NOT NULL THEN '✅ SYNCED - Data in Firestore'
    WHEN MAX(o.error_message) IS NOT NULL THEN '❌ FAILED - Check error message'
    WHEN EXTRACT(EPOCH FROM (NOW() - rb.created_at)) < 60 THEN '⏳ PENDING - Wait for cron (< 1 min)'
    ELSE '⚠️ STUCK - Cron may not be running (> 1 min)'
  END as status
FROM recent_bookings rb
LEFT JOIN outbox o ON o.payload->>'bookingNumber' = rb.booking_number
GROUP BY rb.booking_number, rb.created_at
ORDER BY rb.created_at DESC;

-- ============================================
-- Step 4: Check Cron Job Recent Executions
-- ============================================

SELECT 
  '=== Step 4: Cron Job Recent Executions ===' as info;

SELECT 
  jobname,
  status,
  return_message,
  start_time,
  end_time,
  EXTRACT(EPOCH FROM (end_time - start_time)) as duration_seconds
FROM cron.job_run_details
WHERE start_time >= NOW() - INTERVAL '10 minutes'
ORDER BY start_time DESC
LIMIT 10;

-- Expected:
-- - Should see recent executions of 'sync-orders-to-firestore'
-- - Status should be 'succeeded'
-- - If no recent executions: Cron job not running

-- ============================================
-- Step 5: Check for Stuck Events
-- ============================================

SELECT 
  '=== Step 5: Stuck Events (Unprocessed > 2 minutes) ===' as info;

SELECT 
  id as event_id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  retry_count,
  error_message,
  EXTRACT(EPOCH FROM (NOW() - created_at))/60 as minutes_stuck
FROM outbox
WHERE processed_at IS NULL
  AND created_at < NOW() - INTERVAL '2 minutes'
ORDER BY created_at DESC
LIMIT 10;

-- Expected:
-- - Should be empty or very few
-- - If many stuck events: Cron job or sync function issue

-- ============================================
-- Step 6: Diagnostic Summary
-- ============================================

SELECT 
  '=== Step 6: Diagnostic Summary ===' as info;

SELECT 
  'Total Bookings (1h)' as metric,
  COUNT(*) as count
FROM bookings
WHERE created_at >= NOW() - INTERVAL '1 hour'

UNION ALL

SELECT 
  'Total Events (1h)' as metric,
  COUNT(*) as count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour'

UNION ALL

SELECT 
  'Synced Events (1h)' as metric,
  COUNT(*) as count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour'
  AND processed_at IS NOT NULL

UNION ALL

SELECT 
  'Pending Events (1h)' as metric,
  COUNT(*) as count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour'
  AND processed_at IS NULL
  AND error_message IS NULL

UNION ALL

SELECT 
  'Failed Events (1h)' as metric,
  COUNT(*) as count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour'
  AND error_message IS NOT NULL

UNION ALL

SELECT 
  'Cron Executions (10min)' as metric,
  COUNT(*) as count
FROM cron.job_run_details
WHERE start_time >= NOW() - INTERVAL '10 minutes';

-- ============================================
-- Interpretation Guide:
-- ============================================
--
-- SCENARIO A: Everything Working ✅
-- - Step 1: Shows your booking
-- - Step 2: Shows 1 event with processed_at filled
-- - Step 3: Status = "✅ SYNCED"
-- - Step 4: Shows recent cron executions
-- - Step 5: Empty (no stuck events)
-- - Issue: Client reading from wrong ID or collection
--
-- SCENARIO B: Waiting for Sync ⏳
-- - Step 1: Shows your booking
-- - Step 2: Shows 1 event with processed_at = NULL
-- - Step 3: Status = "⏳ PENDING" (if < 1 min) or "⚠️ STUCK" (if > 1 min)
-- - Step 4: May or may not show recent executions
-- - Issue: Wait 30 seconds for cron, or cron not running
--
-- SCENARIO C: Sync Failed ❌
-- - Step 1: Shows your booking
-- - Step 2: Shows 1 event with error_message
-- - Step 3: Status = "❌ FAILED"
-- - Step 4: May show executions
-- - Issue: Check error_message for details
--
-- SCENARIO D: Trigger Not Firing ❌
-- - Step 1: Shows your booking
-- - Step 2: Empty (no events)
-- - Step 3: Status = "❌ NO EVENT"
-- - Issue: Trigger not working (but tests showed it works!)
--
-- SCENARIO E: Cron Not Running ⚠️
-- - Step 1: Shows your booking
-- - Step 2: Shows events but all processed_at = NULL
-- - Step 3: Status = "⚠️ STUCK"
-- - Step 4: Empty (no recent executions)
-- - Issue: Cron job not running or disabled

