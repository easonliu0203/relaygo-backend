-- Check Existing Test Data
-- Execute this to see what test data already exists

-- ============================================
-- Check 1: Test Users
-- ============================================

SELECT 
  'Test Users' as category,
  firebase_uid,
  email,
  role,
  created_at
FROM users
WHERE firebase_uid IN ('test_user_001', 'dup_test', 'trigger_test_user')
ORDER BY created_at DESC;

-- ============================================
-- Check 2: Test Bookings
-- ============================================

SELECT 
  'Test Bookings' as category,
  booking_number,
  status,
  pickup_location,
  total_amount,
  created_at
FROM bookings
WHERE booking_number IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001')
ORDER BY created_at DESC;

-- ============================================
-- Check 3: Outbox Events for Test Bookings
-- ============================================

SELECT 
  'Outbox Events' as category,
  id,
  event_type,
  payload->>'bookingNumber' as booking_number,
  payload->>'status' as status,
  created_at,
  processed_at,
  retry_count
FROM outbox
WHERE payload->>'bookingNumber' IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001')
ORDER BY created_at DESC;

-- ============================================
-- Check 4: Count Events per Booking
-- ============================================
-- This tells us if trigger is creating duplicate events

SELECT 
  'Event Count per Booking' as category,
  payload->>'bookingNumber' as booking_number,
  COUNT(*) as event_count,
  CASE 
    WHEN COUNT(*) = 1 THEN '✅ CORRECT (1 event)'
    WHEN COUNT(*) = 2 THEN '❌ DUPLICATE (2 events)'
    ELSE '⚠️ UNEXPECTED COUNT'
  END as status
FROM outbox
WHERE payload->>'bookingNumber' IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001')
GROUP BY payload->>'bookingNumber'
ORDER BY booking_number;

-- ============================================
-- Summary
-- ============================================

SELECT 
  'Summary' as category,
  (SELECT COUNT(*) FROM users WHERE firebase_uid IN ('test_user_001', 'dup_test', 'trigger_test_user')) as test_users_count,
  (SELECT COUNT(*) FROM bookings WHERE booking_number IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001')) as test_bookings_count,
  (SELECT COUNT(*) FROM outbox WHERE payload->>'bookingNumber' IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001')) as test_events_count;

-- ============================================
-- Expected Results:
-- ============================================
-- If you see test data:
-- - This confirms previous tests ran successfully
-- - Check event_count: should be 1 per booking
-- - If event_count = 2, trigger duplication issue confirmed
-- - If event_count = 1, trigger is working correctly!

