-- Step-by-Step Verification Script
-- Execute each section separately to see clear results

-- ============================================
-- CHECK 1: Verify outbox table exists
-- ============================================
-- Expected: Should show "✅ 存在"

SELECT 
  'outbox table' as check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'outbox'
    ) THEN '✅ EXISTS'
    ELSE '❌ NOT EXISTS'
  END as status;

-- ============================================
-- CHECK 2: Verify users table exists
-- ============================================
-- Expected: Should show "✅ EXISTS"

SELECT 
  'users table' as check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'users'
    ) THEN '✅ EXISTS'
    ELSE '❌ NOT EXISTS'
  END as status;

-- ============================================
-- CHECK 3: Verify bookings table exists
-- ============================================
-- Expected: Should show "✅ EXISTS"

SELECT 
  'bookings table' as check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'bookings'
    ) THEN '✅ EXISTS'
    ELSE '❌ NOT EXISTS'
  END as status;

-- ============================================
-- CHECK 4: Verify trigger exists
-- ============================================
-- Expected: Should show "✅ EXISTS"
-- Note: Trigger name is "bookings_outbox_trigger" (not "orders_outbox_trigger")

SELECT 
  'bookings_outbox_trigger' as check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.triggers 
      WHERE trigger_schema = 'public' 
      AND trigger_name = 'bookings_outbox_trigger'
    ) THEN '✅ EXISTS'
    ELSE '❌ NOT EXISTS'
  END as status;

-- ============================================
-- CHECK 5: View outbox table structure
-- ============================================
-- Expected: Should show 8 columns

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'outbox'
ORDER BY ordinal_position;

-- ============================================
-- CHECK 6: Count records in each table
-- ============================================
-- Expected: All counts should be 0 (no data yet)

SELECT 'users' as table_name, COUNT(*) as record_count FROM users
UNION ALL
SELECT 'bookings' as table_name, COUNT(*) as record_count FROM bookings
UNION ALL
SELECT 'outbox' as table_name, COUNT(*) as record_count FROM outbox;

-- ============================================
-- SUMMARY
-- ============================================
-- If all checks show "✅ EXISTS" and tables have correct structure,
-- then the deployment was SUCCESSFUL!

