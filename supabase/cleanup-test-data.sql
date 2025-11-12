-- Cleanup Test Data
-- Execute this to remove all test data and start fresh

-- ============================================
-- IMPORTANT: Read Before Executing
-- ============================================
-- This script will DELETE all test data:
-- - Test users (test_user_001, dup_test, trigger_test_user)
-- - Test bookings (BK001, DUP_TEST, TRIGGER_TEST_001)
-- - Related outbox events
--
-- This is SAFE because:
-- - Only removes test data (identified by specific IDs)
-- - Does not affect production data
-- - Can be re-run multiple times safely
-- ============================================

-- ============================================
-- Step 1: Show what will be deleted
-- ============================================

SELECT 'Users to be deleted:' as info, COUNT(*) as count
FROM users
WHERE firebase_uid IN ('test_user_001', 'dup_test', 'trigger_test_user');

SELECT 'Bookings to be deleted:' as info, COUNT(*) as count
FROM bookings
WHERE booking_number IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001');

SELECT 'Outbox events to be deleted:' as info, COUNT(*) as count
FROM outbox
WHERE payload->>'bookingNumber' IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001');

-- ============================================
-- Step 2: Delete test data (in correct order)
-- ============================================

-- Delete bookings first (due to foreign key constraints)
DELETE FROM bookings
WHERE booking_number IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001');

-- Delete test users
DELETE FROM users
WHERE firebase_uid IN ('test_user_001', 'dup_test', 'trigger_test_user');

-- Delete related outbox events
DELETE FROM outbox
WHERE payload->>'bookingNumber' IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001');

-- ============================================
-- Step 3: Verify cleanup
-- ============================================

SELECT 
  'Cleanup Verification' as check_item,
  (SELECT COUNT(*) FROM users WHERE firebase_uid IN ('test_user_001', 'dup_test', 'trigger_test_user')) as remaining_users,
  (SELECT COUNT(*) FROM bookings WHERE booking_number IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001')) as remaining_bookings,
  (SELECT COUNT(*) FROM outbox WHERE payload->>'bookingNumber' IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001')) as remaining_events,
  CASE 
    WHEN (SELECT COUNT(*) FROM users WHERE firebase_uid IN ('test_user_001', 'dup_test', 'trigger_test_user')) = 0
     AND (SELECT COUNT(*) FROM bookings WHERE booking_number IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001')) = 0
     AND (SELECT COUNT(*) FROM outbox WHERE payload->>'bookingNumber' IN ('BK001', 'DUP_TEST', 'TRIGGER_TEST_001')) = 0
    THEN '✅ CLEANUP SUCCESSFUL'
    ELSE '⚠️ SOME DATA REMAINS'
  END as status;

-- ============================================
-- Expected Result:
-- ============================================
-- All counts should be 0
-- Status should show: ✅ CLEANUP SUCCESSFUL

