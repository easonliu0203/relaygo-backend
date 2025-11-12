-- Complete Test Flow for Booking Creation
-- This script can be executed all at once in Supabase SQL Editor

-- ============================================
-- Method 1: Using WITH clause (Recommended)
-- ============================================
-- This method creates user and booking in a single transaction

WITH new_user AS (
  INSERT INTO users (firebase_uid, email, role)
  VALUES ('test_user_001', 'test001@example.com', 'customer')
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
  'BK001',
  '2025-10-15',
  '09:00:00',
  6,
  'A',
  'Test Pickup Location - Taipei Main Station',
  1000.00,
  1000.00,
  300.00
FROM new_user
RETURNING *;

-- ============================================
-- Verify the booking was created
-- ============================================

SELECT 
  b.id,
  b.booking_number,
  b.status,
  u.email as customer_email,
  b.pickup_location,
  b.start_date,
  b.total_amount,
  b.created_at
FROM bookings b
JOIN users u ON b.customer_id = u.id
WHERE b.booking_number = 'BK001';

-- ============================================
-- Check the outbox table for the event
-- ============================================

SELECT 
  id,
  aggregate_type,
  aggregate_id,
  event_type,
  payload->>'bookingNumber' as booking_number,
  payload->>'status' as status,
  created_at,
  processed_at,
  retry_count
FROM outbox 
WHERE aggregate_type = 'booking'
ORDER BY created_at DESC 
LIMIT 1;

-- ============================================
-- Expected Results:
-- ============================================
-- 1. First query: Should return the newly created booking with all details
-- 2. Second query: Should show the booking with customer email
-- 3. Third query: Should show 1 event in outbox with:
--    - aggregate_type = 'booking'
--    - event_type = 'created'
--    - processed_at = NULL (not processed yet)
--    - retry_count = 0

-- ============================================
-- Clean up test data (optional)
-- ============================================
-- Uncomment the following lines to delete test data

-- DELETE FROM bookings WHERE booking_number = 'BK001';
-- DELETE FROM users WHERE firebase_uid = 'test_user_001';
-- DELETE FROM outbox WHERE aggregate_type = 'booking' AND payload->>'bookingNumber' = 'BK001';

