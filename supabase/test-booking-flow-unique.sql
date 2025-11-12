-- Test Booking Flow with Unique Values
-- This script generates unique IDs each time it runs
-- No cleanup needed - each execution creates new test data

-- ============================================
-- Method 2: Generate Unique Values
-- ============================================
-- Uses timestamp to ensure unique values every time

-- Generate unique identifiers based on current timestamp
WITH unique_ids AS (
  SELECT 
    'test_user_' || EXTRACT(EPOCH FROM NOW())::TEXT as firebase_uid,
    'test_' || EXTRACT(EPOCH FROM NOW())::TEXT || '@example.com' as email,
    'BK_' || TO_CHAR(NOW(), 'YYYYMMDD_HH24MISS') as booking_number
),
new_user AS (
  INSERT INTO users (firebase_uid, email, role)
  SELECT firebase_uid, email, 'customer'
  FROM unique_ids
  RETURNING id, firebase_uid, email
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
  nu.id,
  ui.booking_number,
  CURRENT_DATE + INTERVAL '7 days',
  '09:00:00',
  6,
  'A',
  'Unique Test - Taipei Main Station',
  1000.00,
  1000.00,
  300.00
FROM new_user nu
CROSS JOIN unique_ids ui
RETURNING 
  booking_number,
  status,
  pickup_location,
  total_amount,
  created_at;

-- ============================================
-- Note: Save the booking_number from above
-- ============================================
-- You'll need it for the verification queries below
-- Example: BK_20251003_233045

-- ============================================
-- Verification: Check the latest booking
-- ============================================

SELECT 
  'Latest Test Booking' as info,
  b.booking_number,
  b.status,
  u.email as customer_email,
  u.firebase_uid,
  b.pickup_location,
  b.start_date,
  b.total_amount,
  b.created_at
FROM bookings b
JOIN users u ON b.customer_id = u.id
WHERE b.booking_number LIKE 'BK_%'
ORDER BY b.created_at DESC
LIMIT 1;

-- ============================================
-- Verification: Check outbox for latest booking
-- ============================================

WITH latest_booking AS (
  SELECT booking_number
  FROM bookings
  WHERE booking_number LIKE 'BK_%'
  ORDER BY created_at DESC
  LIMIT 1
)
SELECT 
  'Outbox Events for Latest Booking' as info,
  o.id,
  o.aggregate_type,
  o.event_type,
  o.payload->>'bookingNumber' as booking_number,
  o.payload->>'status' as status,
  o.created_at,
  o.processed_at,
  o.retry_count
FROM outbox o
WHERE o.payload->>'bookingNumber' = (SELECT booking_number FROM latest_booking)
ORDER BY o.created_at DESC;

-- ============================================
-- Critical Check: Event Count for Latest Booking
-- ============================================

WITH latest_booking AS (
  SELECT booking_number
  FROM bookings
  WHERE booking_number LIKE 'BK_%'
  ORDER BY created_at DESC
  LIMIT 1
)
SELECT 
  'Event Count Check' as test,
  (SELECT booking_number FROM latest_booking) as booking_number,
  COUNT(*) as event_count,
  CASE 
    WHEN COUNT(*) = 1 THEN '✅ CORRECT - Trigger working properly (1 event)'
    WHEN COUNT(*) = 2 THEN '❌ DUPLICATE - Trigger issue detected (2 events)'
    WHEN COUNT(*) = 0 THEN '❌ NO EVENT - Trigger not firing'
    ELSE '⚠️ UNEXPECTED COUNT'
  END as status
FROM outbox
WHERE payload->>'bookingNumber' = (SELECT booking_number FROM latest_booking);

-- ============================================
-- Summary: All Test Bookings
-- ============================================

SELECT 
  'All Test Bookings Summary' as info,
  COUNT(*) as total_test_bookings,
  COUNT(DISTINCT booking_number) as unique_bookings
FROM bookings
WHERE booking_number LIKE 'BK_%';

-- ============================================
-- Optional: Clean up ALL test data
-- ============================================
-- Uncomment to remove all test bookings created by this script

-- DELETE FROM bookings WHERE booking_number LIKE 'BK_%';
-- DELETE FROM users WHERE firebase_uid LIKE 'test_user_%';
-- DELETE FROM outbox WHERE payload->>'bookingNumber' LIKE 'BK_%';

-- ============================================
-- Expected Results:
-- ============================================
-- 1. New booking created with unique booking_number
-- 2. Exactly 1 event in outbox for this booking
-- 3. Event has event_type = 'created'
-- 4. Status shows: ✅ CORRECT
-- 5. Can be run multiple times without errors

