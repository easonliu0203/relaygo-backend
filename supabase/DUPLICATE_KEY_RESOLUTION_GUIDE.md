# Duplicate Key Error Resolution Guide

**Issue**: `duplicate key value violates unique constraint`  
**Status**: ✅ This is actually GOOD NEWS!

---

## Understanding the Error

### What Happened

**Error 1**:
```
ERROR: 23505: duplicate key value violates unique constraint "users_firebase_uid_key"
DETAIL: Key (firebase_uid)=(test_user_001) already exists.
```

**Error 2**:
```
ERROR: 23505: duplicate key value violates unique constraint "bookings_booking_number_key"
DETAIL: Key (booking_number)=(DUP_TEST) already exists.
```

### Why This is Good News ✅

1. ✅ **Previous tests ran successfully**
   - Test users were created
   - Test bookings were created
   - Database constraints are working correctly

2. ✅ **Trigger likely fired**
   - Bookings were created
   - Trigger should have created outbox events
   - Need to verify event count

3. ✅ **Database integrity is maintained**
   - Unique constraints are working
   - Prevents duplicate data
   - System is functioning as designed

---

## Step-by-Step Resolution

### Step 1: Check Existing Test Data

**File**: `supabase/check-existing-test-data.sql`

**Purpose**: See what test data already exists and verify trigger behavior

**Execute**:
1. Open `check-existing-test-data.sql`
2. Copy all content
3. Paste in SQL Editor
4. Click "Run"

**What to Look For**:
- How many test users exist?
- How many test bookings exist?
- **CRITICAL**: How many outbox events per booking?
  - 1 event = ✅ Trigger working correctly
  - 2 events = ❌ Duplicate trigger issue

**Expected Results**:
```
Test Users: 1-3 users
Test Bookings: 1-3 bookings
Outbox Events: 1 event per booking (IMPORTANT!)
Event Count per Booking: Should show "✅ CORRECT (1 event)"
```

---

### Step 2: Verify Trigger Behavior

Based on Step 1 results:

#### If Event Count = 1 per Booking ✅

**Status**: 🎉 **TRIGGER IS WORKING CORRECTLY!**

**What This Means**:
- No duplicate trigger issue
- Each booking creates exactly 1 event
- System is functioning properly

**Next Action**: Proceed to Step 3 (cleanup and fresh test)

#### If Event Count = 2 per Booking ❌

**Status**: ⚠️ **DUPLICATE TRIGGER ISSUE CONFIRMED**

**What This Means**:
- Trigger is firing twice per booking change
- Need to fix duplicate trigger

**Next Action**: 
1. Run `fix-duplicate-triggers.sql` first
2. Then proceed to Step 3

---

### Step 3: Clean Up Test Data

**File**: `supabase/cleanup-test-data.sql`

**Purpose**: Remove all existing test data to start fresh

**Execute**:
1. Open `cleanup-test-data.sql`
2. Copy all content
3. Paste in SQL Editor
4. Click "Run"

**What It Does**:
- Deletes test users (test_user_001, dup_test, trigger_test_user)
- Deletes test bookings (BK001, DUP_TEST, TRIGGER_TEST_001)
- Deletes related outbox events

**Expected Result**:
```
✅ CLEANUP SUCCESSFUL
remaining_users: 0
remaining_bookings: 0
remaining_events: 0
```

---

### Step 4: Run Fresh Test

**Choose ONE of the following methods**:

#### Method A: Idempotent Script (Recommended) ⭐

**File**: `supabase/test-booking-flow-idempotent.sql`

**Benefits**:
- ✅ Can be run multiple times
- ✅ Automatically cleans up before creating
- ✅ Uses consistent test data
- ✅ Easy to verify results

**Execute**:
1. Open `test-booking-flow-idempotent.sql`
2. Copy all content
3. Paste in SQL Editor
4. Click "Run"

**Expected Results**:
- Booking created: BK_TEST_001
- Event count: 1
- Status: ✅ CORRECT

#### Method B: Unique Values Script

**File**: `supabase/test-booking-flow-unique.sql`

**Benefits**:
- ✅ Never conflicts with existing data
- ✅ Generates unique IDs each time
- ✅ No cleanup needed before running
- ✅ Good for repeated testing

**Execute**:
1. Open `test-booking-flow-unique.sql`
2. Copy all content
3. Paste in SQL Editor
4. Click "Run"

**Expected Results**:
- Booking created: BK_YYYYMMDD_HHMMSS (unique timestamp)
- Event count: 1
- Status: ✅ CORRECT

---

## Quick Decision Tree

```
Got duplicate key error?
│
├─ Step 1: Check existing data
│  └─ Run: check-existing-test-data.sql
│     │
│     ├─ Event count = 1 per booking?
│     │  └─ ✅ Trigger OK → Go to Step 3
│     │
│     └─ Event count = 2 per booking?
│        └─ ❌ Fix trigger → Run fix-duplicate-triggers.sql → Go to Step 3
│
├─ Step 2: Clean up
│  └─ Run: cleanup-test-data.sql
│
└─ Step 3: Fresh test
   ├─ Option A: test-booking-flow-idempotent.sql (recommended)
   └─ Option B: test-booking-flow-unique.sql
```

---

## Verification Checklist

After running fresh test, verify:

- [ ] ✅ Booking created successfully
- [ ] ✅ Booking appears in bookings table
- [ ] ✅ Exactly 1 event in outbox for this booking
- [ ] ✅ Event has event_type = 'created'
- [ ] ✅ Event has processed_at = NULL
- [ ] ✅ Event payload contains booking data
- [ ] ✅ Status shows "✅ CORRECT"

---

## Understanding the Scripts

### check-existing-test-data.sql
**Purpose**: Diagnostic  
**Safe to run**: Yes (read-only)  
**When to use**: First step to understand current state

### cleanup-test-data.sql
**Purpose**: Remove test data  
**Safe to run**: Yes (only deletes test data)  
**When to use**: Before running fresh tests

### test-booking-flow-idempotent.sql
**Purpose**: Repeatable test  
**Safe to run**: Yes (cleans up first)  
**When to use**: Regular testing, can run multiple times

### test-booking-flow-unique.sql
**Purpose**: Non-conflicting test  
**Safe to run**: Yes (generates unique IDs)  
**When to use**: When you want to keep test history

---

## Common Questions

### Q1: Why did I get duplicate key errors?

**A**: Your previous tests ran successfully and created test data. The error occurs because you're trying to create the same test data again.

**This is GOOD** - it means:
- ✅ Tests worked before
- ✅ Database constraints are working
- ✅ Data integrity is maintained

### Q2: Do I need to clean up before every test?

**A**: Depends on which script you use:
- **Idempotent script**: No - it cleans up automatically
- **Unique values script**: No - generates unique IDs
- **Original script**: Yes - or you'll get duplicate key errors

### Q3: How do I know if trigger is working correctly?

**A**: Check the event count per booking:
- **1 event** = ✅ Trigger working correctly
- **2 events** = ❌ Duplicate trigger issue
- **0 events** = ❌ Trigger not firing

Run `check-existing-test-data.sql` to see the count.

### Q4: Can I just ignore the duplicate key errors?

**A**: Not recommended. Instead:
1. Check if previous test data shows trigger is working
2. Clean up test data
3. Use idempotent or unique values script for future tests

### Q5: Will cleaning up test data affect production?

**A**: No! The cleanup script only removes:
- Test users (with specific test IDs)
- Test bookings (with specific test booking numbers)
- Related test events

Production data is not affected.

---

## Best Practices

### For Development/Testing

1. **Use idempotent scripts**
   - Can run multiple times
   - Automatic cleanup
   - Consistent results

2. **Check before cleaning**
   - Run `check-existing-test-data.sql` first
   - Verify trigger behavior
   - Understand current state

3. **Clean up after testing**
   - Remove test data when done
   - Keeps database clean
   - Prevents confusion

### For Production

1. **Never use test IDs**
   - Use real, unique identifiers
   - Follow naming conventions
   - Avoid conflicts

2. **Monitor outbox table**
   - Check for unprocessed events
   - Monitor retry counts
   - Watch for errors

---

## Files Reference

| File | Purpose | When to Use |
|------|---------|-------------|
| `check-existing-test-data.sql` | Check current state | First step, diagnostic |
| `cleanup-test-data.sql` | Remove test data | Before fresh tests |
| `test-booking-flow-idempotent.sql` ⭐ | Repeatable test | Regular testing |
| `test-booking-flow-unique.sql` | Unique ID test | Keep test history |

---

## Next Steps

1. ✅ Run `check-existing-test-data.sql` to verify trigger behavior
2. ✅ If trigger OK, run `cleanup-test-data.sql`
3. ✅ Run `test-booking-flow-idempotent.sql` for fresh test
4. ✅ Verify results show 1 event per booking
5. ✅ If all checks pass, proceed to Cron Job setup

---

**Last Updated**: 2025-10-03  
**Status**: Solutions Ready for Testing

