-- Idempotent Test Booking Flow
-- This script can be executed multiple times without errors
-- It automatically handles existing test data

-- ============================================
-- Method 1: Clean and Create (Recommended)
-- ============================================
-- This method deletes existing test data first, then creates fresh data

-- Step 1: Clean up any existing test data
DELETE FROM bookings WHERE booking_number = 'BK_TEST_001';
DELETE FROM users WHERE firebase_uid = 'test_user_idempotent';
DELETE FROM outbox WHERE payload->>'bookingNumber' = 'BK_TEST_001';

-- Step 2: Create fresh test data
WITH new_user AS (
  INSERT INTO users (firebase_uid, email, role)
  VALUES ('test_user_idempotent', 'test_idempotent@example.com', 'customer')
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
  'BK_TEST_001',
  CURRENT_DATE + INTERVAL '7 days',
  '09:00:00',
  6,
  'A',
  'Idempotent Test - Taipei Main Station',
  1000.00,
  1000.00,
  300.00
FROM new_user
RETURNING 
  booking_number,
  status,
  pickup_location,
  total_amount,
  created_at;

-- ============================================
-- Verification: Check the booking
-- ============================================

SELECT 
  'Booking Details' as info,
  b.booking_number,
  b.status,
  u.email as customer_email,
  b.pickup_location,
  b.start_date,
  b.total_amount,
  b.created_at
FROM bookings b
JOIN users u ON b.customer_id = u.id
WHERE b.booking_number = 'BK_TEST_001';

-- ============================================
-- Verification: Check outbox events
-- ============================================

SELECT 
  'Outbox Events' as info,
  id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  payload->>'status' as status,
  created_at,
  processed_at,
  retry_count
FROM outbox 
WHERE payload->>'bookingNumber' = 'BK_TEST_001'
ORDER BY created_at DESC;

-- ============================================
-- Critical Check: Event Count
-- ============================================

SELECT 
  'Event Count Check' as test,
  COUNT(*) as event_count,
  CASE 
    WHEN COUNT(*) = 1 THEN '✅ CORRECT - Trigger working properly (1 event)'
    WHEN COUNT(*) = 2 THEN '❌ DUPLICATE - Trigger issue detected (2 events)'
    WHEN COUNT(*) = 0 THEN '❌ NO EVENT - Trigger not firing'
    ELSE '⚠️ UNEXPECTED COUNT'
  END as status
FROM outbox
WHERE payload->>'bookingNumber' = 'BK_TEST_001';

-- ============================================
-- Expected Results:
-- ============================================
-- 1. Booking created successfully
-- 2. Exactly 1 event in outbox
-- 3. Event has event_type = 'created'
-- 4. Event has processed_at = NULL
-- 5. Status shows: ✅ CORRECT

-- ============================================
-- Optional: Clean up after test
-- ============================================
-- Uncomment the following lines to clean up test data

-- DELETE FROM bookings WHERE booking_number = 'BK_TEST_001';
-- DELETE FROM users WHERE firebase_uid = 'test_user_idempotent';
-- DELETE FROM outbox WHERE payload->>'bookingNumber' = 'BK_TEST_001';

