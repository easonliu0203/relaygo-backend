-- Fix Duplicate Triggers Script
-- Execute this ONLY if you confirmed duplicate triggers exist

-- ============================================
-- IMPORTANT: Read Before Executing
-- ============================================
-- This script will:
-- 1. Drop ALL existing bookings_outbox_trigger triggers
-- 2. Recreate a single, correct trigger
-- 3. Verify the fix
--
-- This is safe because:
-- - Dropping and recreating triggers does not affect existing data
-- - The trigger function (bookings_to_outbox) remains intact
-- - Only the trigger itself is recreated
-- ============================================

-- ============================================
-- Step 1: Drop all existing triggers
-- ============================================

DROP TRIGGER IF EXISTS bookings_outbox_trigger ON bookings;

-- ============================================
-- Step 2: Recreate the trigger correctly
-- ============================================

CREATE TRIGGER bookings_outbox_trigger
AFTER INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION bookings_to_outbox();

-- ============================================
-- Step 3: Verify the fix
-- ============================================

-- Check trigger count (should be 1)
SELECT 
  'Trigger Count Check' as test,
  COUNT(*) as trigger_count,
  CASE 
    WHEN COUNT(*) = 1 THEN '✅ CORRECT (1 trigger)'
    WHEN COUNT(*) = 2 THEN '❌ STILL DUPLICATE (2 triggers)'
    ELSE '⚠️ UNEXPECTED COUNT'
  END as status
FROM information_schema.triggers
WHERE trigger_name = 'bookings_outbox_trigger';

-- Check trigger details
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_orientation
FROM information_schema.triggers
WHERE trigger_name = 'bookings_outbox_trigger'
ORDER BY event_manipulation;

-- ============================================
-- Step 4: Test the trigger
-- ============================================

-- Create a test booking to verify trigger fires correctly
WITH test_user AS (
  INSERT INTO users (firebase_uid, email, role)
  VALUES ('trigger_test_user', 'trigger_test@example.com', 'customer')
  ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email
  RETURNING id
)
INSERT INTO bookings (
  customer_id, 
  booking_number, 
  start_date, 
  start_time,
  duration_hours, 
  vehicle_type, 
  pickup_location,
  base_price, 
  total_amount, 
  deposit_amount
)
SELECT 
  id,
  'TRIGGER_TEST_001',
  CURRENT_DATE + INTERVAL '7 days',
  '10:00:00',
  6,
  'A',
  'Trigger Test Location',
  1000.00,
  1000.00,
  300.00
FROM test_user
RETURNING booking_number, created_at;

-- Check how many events were created (should be exactly 1)
SELECT 
  'Outbox Event Count' as test,
  COUNT(*) as event_count,
  CASE 
    WHEN COUNT(*) = 1 THEN '✅ CORRECT (1 event created)'
    WHEN COUNT(*) = 2 THEN '❌ DUPLICATE TRIGGER ISSUE (2 events created)'
    ELSE '⚠️ UNEXPECTED COUNT'
  END as status
FROM outbox
WHERE payload->>'bookingNumber' = 'TRIGGER_TEST_001';

-- View the event(s) created
SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at
FROM outbox
WHERE payload->>'bookingNumber' = 'TRIGGER_TEST_001'
ORDER BY created_at;

-- ============================================
-- Step 5: Clean up test data
-- ============================================

DELETE FROM bookings WHERE booking_number = 'TRIGGER_TEST_001';
DELETE FROM users WHERE firebase_uid = 'trigger_test_user';
DELETE FROM outbox WHERE payload->>'bookingNumber' = 'TRIGGER_TEST_001';

-- ============================================
-- Final Verification
-- ============================================

SELECT 
  'Final Trigger Count' as check_item,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) = 1 THEN '✅ SUCCESS - Trigger fixed'
    ELSE '❌ ISSUE REMAINS - Please contact support'
  END as status
FROM information_schema.triggers
WHERE trigger_name = 'bookings_outbox_trigger';

-- ============================================
-- Summary
-- ============================================
-- If all checks show ✅, the duplicate trigger issue is resolved.
-- The trigger will now fire only once per booking change.

