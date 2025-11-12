-- Diagnose Booking Creation Error
-- Run this to check if any bookings were created despite the error

-- ============================================
-- Check 1: Recent Booking Attempts (Last 10 minutes)
-- ============================================

SELECT 
  '=== Recent Bookings (Last 10 minutes) ===' as info;

SELECT 
  id,
  booking_number,
  customer_id,
  status,
  pickup_location,
  destination,
  start_date,
  start_time,
  duration_hours,
  vehicle_type,
  base_price,
  total_amount,
  deposit_amount,
  created_at,
  EXTRACT(EPOCH FROM (NOW() - created_at))/60 as minutes_ago
FROM bookings
WHERE created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC;

-- ============================================
-- Check 2: Recent Users Created (Last 10 minutes)
-- ============================================

SELECT 
  '=== Recent Users (Last 10 minutes) ===' as info;

SELECT 
  id,
  firebase_uid,
  email,
  role,
  created_at,
  EXTRACT(EPOCH FROM (NOW() - created_at))/60 as minutes_ago
FROM users
WHERE created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC;

-- ============================================
-- Check 3: Bookings Table Schema
-- ============================================

SELECT 
  '=== Bookings Table Columns ===' as info;

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'bookings'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================
-- Check 4: Required Fields Check
-- ============================================

SELECT 
  '=== Required Fields (NOT NULL) ===' as info;

SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'bookings'
  AND table_schema = 'public'
  AND is_nullable = 'NO'
  AND column_default IS NULL
ORDER BY ordinal_position;

-- ============================================
-- Check 5: Test Insert (Minimal Data)
-- ============================================

SELECT 
  '=== Test Insert (Will be rolled back) ===' as info;

-- This will show what fields are actually required
-- Uncomment to test:

-- BEGIN;
-- 
-- INSERT INTO bookings (
--   customer_id,
--   booking_number,
--   status,
--   start_date,
--   start_time,
--   duration_hours,
--   vehicle_type,
--   pickup_location,
--   base_price,
--   total_amount,
--   deposit_amount
-- ) VALUES (
--   (SELECT id FROM users LIMIT 1),  -- Use any existing user
--   'TEST_' || EXTRACT(EPOCH FROM NOW())::TEXT,
--   'pending',
--   CURRENT_DATE,
--   '09:00:00',
--   6,
--   'A',
--   'Test Location',
--   1000.00,
--   1000.00,
--   300.00
-- );
-- 
-- ROLLBACK;

-- ============================================
-- Expected Results:
-- ============================================
--
-- SCENARIO A: Booking Created Successfully
-- - Check 1: Shows booking with your data
-- - Check 2: Shows user (if new)
-- - Issue: Error happened after booking creation (payment step?)
--
-- SCENARIO B: Booking Not Created
-- - Check 1: Empty
-- - Check 2: May show user (if user creation succeeded)
-- - Issue: Error during booking creation
--
-- SCENARIO C: Schema Mismatch
-- - Check 3: Shows all columns
-- - Check 4: Shows required fields
-- - Issue: API trying to insert non-existent columns or missing required fields

