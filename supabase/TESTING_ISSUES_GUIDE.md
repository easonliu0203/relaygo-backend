# Testing Issues Resolution Guide

**Date**: 2025-10-03  
**Issues**: UUID Error & Duplicate Triggers

---

## Issue 1: UUID Error When Creating Test Booking

### Problem Description

**Error Message**:
```
ERROR: 22P02: invalid input syntax for type uuid: "<user_id>"
```

**Root Cause**:
The test script used `<user_id>` as a placeholder, but SQL cannot automatically replace placeholders. You need to either:
1. Use a single query with a WITH clause (recommended)
2. Execute queries separately and manually copy the UUID

### Solution: Use the Complete Test Script

**File**: `supabase/test-booking-flow.sql`

**How to Use**:
1. Open the file `supabase/test-booking-flow.sql`
2. Copy the entire content
3. Paste into Supabase SQL Editor
4. Click "Run" (or press Ctrl+Enter)

**What This Script Does**:
```sql
WITH new_user AS (
  INSERT INTO users (firebase_uid, email, role)
  VALUES ('test_user_001', 'test001@example.com', 'customer')
  RETURNING id
)
INSERT INTO bookings (...)
SELECT id, ... FROM new_user
RETURNING *;
```

**Key Points**:
- Uses `WITH` clause to create user first
- Automatically passes the user ID to the booking insert
- All happens in a single transaction
- No need to manually copy/paste UUIDs

### Alternative: Step-by-Step Method

If you prefer to execute queries separately:

**Step 1**: Create user and note the UUID
```sql
INSERT INTO users (firebase_uid, email, role)
VALUES ('test_user_002', 'test002@example.com', 'customer')
RETURNING id;
```

**Result**: Copy the UUID from the result (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)

**Step 2**: Create booking using the copied UUID
```sql
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
) VALUES (
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',  -- Paste the UUID here
  'BK002',
  '2025-10-15',
  '09:00:00',
  6,
  'A',
  'Test Location',
  1000.00,
  1000.00,
  300.00
);
```

**Step 3**: Check outbox
```sql
SELECT * FROM outbox ORDER BY created_at DESC LIMIT 1;
```

---

## Issue 2: Duplicate Triggers (trigger_exists = 2)

### Problem Description

**Observation**: 
```sql
SELECT COUNT(*) FROM information_schema.triggers 
WHERE trigger_name = 'bookings_outbox_trigger';
-- Result: 2 (expected 1)
```

### Root Cause Analysis

**Possible Causes**:

1. **Scenario A: Separate Triggers for INSERT and UPDATE**
   - PostgreSQL may create separate trigger entries for each event type
   - One trigger for INSERT, one for UPDATE
   - This is actually NORMAL in some PostgreSQL versions
   - Both point to the same function

2. **Scenario B: Duplicate Creation**
   - Setup script was run multiple times
   - Trigger was created twice
   - This WILL cause duplicate events in outbox

3. **Scenario C: PostgreSQL Internal Representation**
   - Some PostgreSQL versions show one trigger per event type in information_schema
   - But it's actually a single trigger definition
   - This is a display quirk, not a real problem

### Diagnosis Steps

**Step 1**: Run the diagnosis script

**File**: `supabase/diagnose-triggers.sql`

Execute this script to see detailed trigger information.

**Step 2**: Interpret the results

**If you see**:
```
trigger_name              | event_manipulation
--------------------------|-------------------
bookings_outbox_trigger   | INSERT
bookings_outbox_trigger   | UPDATE
```

**This means**: PostgreSQL is showing the trigger twice because it handles both INSERT and UPDATE events. This is **NORMAL** and **NOT A PROBLEM**.

**If you see**:
```
trigger_name              | event_manipulation | action_statement
--------------------------|-------------------|------------------
bookings_outbox_trigger   | INSERT, UPDATE    | EXECUTE FUNCTION bookings_to_outbox()
bookings_outbox_trigger   | INSERT, UPDATE    | EXECUTE FUNCTION bookings_to_outbox()
```

**This means**: The trigger was created twice. This **IS A PROBLEM** and needs to be fixed.

### How to Determine if It's a Problem

**Test Method**: Create a test booking and check how many events are created

```sql
-- Create test booking
WITH test_user AS (
  INSERT INTO users (firebase_uid, email, role)
  VALUES ('duplicate_test', 'dup_test@example.com', 'customer')
  ON CONFLICT (firebase_uid) DO UPDATE SET email = EXCLUDED.email
  RETURNING id
)
INSERT INTO bookings (
  customer_id, booking_number, start_date, start_time,
  duration_hours, vehicle_type, pickup_location,
  base_price, total_amount, deposit_amount
)
SELECT id, 'DUP_TEST', CURRENT_DATE, '10:00', 6, 'A', 'Test', 1000, 1000, 300
FROM test_user;

-- Check how many events were created
SELECT COUNT(*) FROM outbox WHERE payload->>'bookingNumber' = 'DUP_TEST';
```

**Expected Result**: 1 event  
**If you see**: 2 events → **PROBLEM CONFIRMED** - Duplicate trigger issue

### Solution: Fix Duplicate Triggers

**File**: `supabase/fix-duplicate-triggers.sql`

**When to Use**: Only if the test above shows 2 events created

**What It Does**:
1. Drops all existing `bookings_outbox_trigger` triggers
2. Recreates a single, correct trigger
3. Tests the fix
4. Verifies only 1 event is created per booking change

**How to Use**:
1. Open `supabase/fix-duplicate-triggers.sql`
2. Copy entire content
3. Paste into Supabase SQL Editor
4. Click "Run"
5. Check the verification results

**Expected Results After Fix**:
- Trigger count: 1 (or 2 if PostgreSQL shows INSERT/UPDATE separately - this is OK)
- Test booking creates exactly 1 event in outbox
- All verification checks show ✅

### Understanding PostgreSQL Trigger Behavior

**Important Note**: 

In PostgreSQL, when you create a trigger like this:
```sql
CREATE TRIGGER my_trigger
AFTER INSERT OR UPDATE ON my_table
FOR EACH ROW
EXECUTE FUNCTION my_function();
```

The `information_schema.triggers` view may show:
- **Option A**: 1 row with `event_manipulation = 'INSERT, UPDATE'`
- **Option B**: 2 rows, one with `INSERT`, one with `UPDATE`

**Both are correct representations of the same trigger!**

The key is to test if it creates duplicate events. If it doesn't, then seeing 2 rows is just how PostgreSQL represents the trigger internally.

---

## Quick Decision Tree

### For Issue 1 (UUID Error):

```
Do you want to execute in one go?
├─ YES → Use test-booking-flow.sql
└─ NO  → Use step-by-step method (copy UUID manually)
```

### For Issue 2 (Duplicate Triggers):

```
Run diagnose-triggers.sql
│
├─ See 2 rows with same event_manipulation?
│  └─ YES → Run fix-duplicate-triggers.sql
│
└─ See 2 rows with different events (INSERT, UPDATE)?
   └─ Run test: Create booking, check event count
      ├─ 1 event created → ✅ NO PROBLEM (PostgreSQL display quirk)
      └─ 2 events created → ❌ PROBLEM → Run fix-duplicate-triggers.sql
```

---

## Verification Checklist

After applying fixes, verify:

- [ ] Can create test booking without UUID error
- [ ] Booking appears in `bookings` table
- [ ] Exactly 1 event created in `outbox` table per booking
- [ ] Event has correct data (booking_number, status, etc.)
- [ ] Trigger count is 1 or 2 (both acceptable depending on PostgreSQL version)
- [ ] Creating/updating booking creates only 1 new event

---

## Files Reference

| File | Purpose | When to Use |
|------|---------|-------------|
| `test-booking-flow.sql` | Complete test script | Testing booking creation |
| `diagnose-triggers.sql` | Diagnose trigger issues | Understanding trigger count |
| `fix-duplicate-triggers.sql` | Fix duplicate triggers | Only if duplicates confirmed |

---

## Expected Behavior Summary

### Normal Behavior ✅

1. **Trigger Count**: 1 or 2 (depending on PostgreSQL version)
2. **Events Created**: Exactly 1 per booking INSERT/UPDATE
3. **Event Data**: Contains all booking fields in payload
4. **processed_at**: NULL (until sync function runs)

### Problem Behavior ❌

1. **Trigger Count**: 2+ identical triggers
2. **Events Created**: 2+ per booking INSERT/UPDATE
3. **Duplicate Events**: Same booking creates multiple outbox entries

---

## Next Steps After Resolution

1. ✅ Test booking creation with `test-booking-flow.sql`
2. ✅ Verify 1 event per booking in outbox
3. ✅ Setup Cron Jobs for automatic sync
4. ✅ Test complete flow: Create booking → Check Firestore

---

## Need More Help?

If issues persist:
1. Run `diagnose-triggers.sql` and share the output
2. Run the test booking script and share the event count
3. Check for any error messages in the SQL Editor
4. Refer to the development log for detailed troubleshooting

---

**Last Updated**: 2025-10-03  
**Status**: Solutions Ready for Testing

