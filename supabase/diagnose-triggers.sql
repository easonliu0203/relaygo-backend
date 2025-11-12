-- Trigger Diagnosis Script
-- This script helps identify duplicate or problematic triggers

-- ============================================
-- Step 1: List all triggers on bookings table
-- ============================================

SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement,
  action_timing,
  action_orientation
FROM information_schema.triggers
WHERE event_object_table = 'bookings'
ORDER BY trigger_name;

-- ============================================
-- Step 2: Count triggers by name
-- ============================================

SELECT 
  trigger_name,
  COUNT(*) as count
FROM information_schema.triggers
WHERE event_object_table = 'bookings'
GROUP BY trigger_name
HAVING COUNT(*) > 1;

-- ============================================
-- Step 3: Check for duplicate triggers with different events
-- ============================================

SELECT 
  trigger_name,
  STRING_AGG(event_manipulation, ', ' ORDER BY event_manipulation) as events
FROM information_schema.triggers
WHERE trigger_name = 'bookings_outbox_trigger'
GROUP BY trigger_name;

-- ============================================
-- Expected Results Analysis:
-- ============================================
-- 
-- SCENARIO A: Normal (1 trigger)
-- - trigger_name: bookings_outbox_trigger
-- - events: INSERT, UPDATE (combined in one trigger)
-- - count: 1
--
-- SCENARIO B: Duplicate (2 triggers)
-- - Two separate triggers with same name
-- - One for INSERT, one for UPDATE
-- - count: 2
--
-- SCENARIO C: Multiple executions
-- - Same trigger created multiple times
-- - All have identical configuration
-- - count: 2 or more
--
-- ============================================

-- ============================================
-- Step 4: Detailed trigger information
-- ============================================

SELECT 
  t.trigger_name,
  t.event_manipulation,
  t.action_timing,
  t.action_statement,
  p.proname as function_name
FROM information_schema.triggers t
LEFT JOIN pg_trigger pt ON pt.tgname = t.trigger_name
LEFT JOIN pg_proc p ON p.oid = pt.tgfoid
WHERE t.event_object_table = 'bookings'
ORDER BY t.trigger_name, t.event_manipulation;

-- ============================================
-- Step 5: Check if trigger fires multiple times
-- ============================================
-- This will be tested after we understand the trigger structure

