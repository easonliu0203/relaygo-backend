# Testing Checklist

Use this checklist to verify your deployment step by step.

---

## Pre-Test Checklist

Before running tests, ensure:

- [ ] Connected to Supabase project (Project Ref: vlyhwegpvpnjyocqmfqc)
- [ ] Opened Supabase Dashboard SQL Editor
- [ ] Have test scripts ready in `supabase/` folder

---

## Step 1: Check Existing Data

**File**: `check-existing-test-data.sql`

### Actions
- [ ] Open the file
- [ ] Copy all content
- [ ] Paste into SQL Editor
- [ ] Click "Run"

### Expected Results
- [ ] See list of test users (if any)
- [ ] See list of test bookings (if any)
- [ ] See list of outbox events (if any)
- [ ] **CRITICAL**: See "Event Count per Booking" results

### Verification
- [ ] If event_count = 1 per booking → ✅ Trigger OK
- [ ] If event_count = 2 per booking → ⚠️ Need to fix trigger
- [ ] If no data → ✅ Clean slate, proceed to Step 3

### Decision Point
```
Event count = 1? → ✅ Go to Step 2 (cleanup)
Event count = 2? → ⚠️ Go to Fix Trigger section first
No data?        → ✅ Skip to Step 3 (test)
```

---

## Fix Trigger (Only if event_count = 2)

**File**: `fix-duplicate-triggers.sql`

### Actions
- [ ] Open the file
- [ ] Copy all content
- [ ] Paste into SQL Editor
- [ ] Click "Run"

### Expected Results
- [ ] Trigger dropped successfully
- [ ] Trigger recreated successfully
- [ ] Test booking created
- [ ] Verification shows: "✅ SUCCESS - Trigger fixed"

### Verification
- [ ] Trigger count = 1 (or 2 if PostgreSQL shows INSERT/UPDATE separately)
- [ ] Test creates only 1 event
- [ ] All checks show ✅

---

## Step 2: Clean Up Test Data

**File**: `cleanup-test-data.sql`

### Actions
- [ ] Open the file
- [ ] Copy all content
- [ ] Paste into SQL Editor
- [ ] Click "Run"

### Expected Results
- [ ] Shows count of data to be deleted
- [ ] Deletes bookings
- [ ] Deletes users
- [ ] Deletes outbox events
- [ ] Shows: "✅ CLEANUP SUCCESSFUL"

### Verification
- [ ] remaining_users = 0
- [ ] remaining_bookings = 0
- [ ] remaining_events = 0
- [ ] Status = "✅ CLEANUP SUCCESSFUL"

---

## Step 3: Run Fresh Test

**File**: `test-booking-flow-idempotent.sql` (Recommended)

### Actions
- [ ] Open the file
- [ ] Copy all content
- [ ] Paste into SQL Editor
- [ ] Click "Run"

### Expected Results (4 tabs)

#### Tab 1: Booking Creation
- [ ] 1 row returned
- [ ] booking_number = 'BK_TEST_001'
- [ ] status = 'pending'
- [ ] total_amount = 1000.00
- [ ] created_at has timestamp

#### Tab 2: Booking Details
- [ ] 1 row returned
- [ ] customer_email = 'test_idempotent@example.com'
- [ ] All booking fields populated
- [ ] JOIN with users table works

#### Tab 3: Outbox Events
- [ ] 1 row returned (IMPORTANT!)
- [ ] aggregate_type = 'booking'
- [ ] event_type = 'created'
- [ ] booking_number = 'BK_TEST_001'
- [ ] processed_at = NULL
- [ ] retry_count = 0

#### Tab 4: Event Count Check ⭐ MOST IMPORTANT
- [ ] event_count = 1
- [ ] status = '✅ CORRECT - Trigger working properly (1 event)'

### Verification
- [ ] All 4 tabs show expected results
- [ ] **Event count = 1** (critical!)
- [ ] No errors in SQL Editor
- [ ] Status shows ✅ CORRECT

---

## Alternative: Unique Values Test

**File**: `test-booking-flow-unique.sql`

Use this if you want to keep test history or run multiple tests.

### Actions
- [ ] Open the file
- [ ] Copy all content
- [ ] Paste into SQL Editor
- [ ] Click "Run"

### Expected Results
- [ ] Booking created with unique timestamp-based ID
- [ ] Example: BK_20251003_234512
- [ ] 1 event in outbox
- [ ] Event count = 1

### Verification
- [ ] Unique booking_number generated
- [ ] Event count = 1 for this booking
- [ ] Can run multiple times without conflicts

---

## Final Verification

After successful test, verify the complete system:

### Database Check
- [ ] Booking exists in `bookings` table
- [ ] User exists in `users` table
- [ ] Event exists in `outbox` table
- [ ] Foreign key relationships correct

### Trigger Check
- [ ] Exactly 1 event per booking
- [ ] Event has correct event_type
- [ ] Event payload contains booking data
- [ ] No duplicate events

### Data Integrity Check
- [ ] Booking data matches input
- [ ] Event payload matches booking
- [ ] Timestamps are consistent
- [ ] No NULL values in required fields

---

## Success Criteria

### ✅ All Tests Pass If:

1. **Booking Creation**
   - [x] Booking created successfully
   - [x] All required fields populated
   - [x] Foreign key to user works

2. **Trigger Functionality**
   - [x] Trigger fires on booking creation
   - [x] Exactly 1 event created per booking
   - [x] Event has correct type and payload

3. **Data Consistency**
   - [x] Event payload matches booking data
   - [x] Timestamps are consistent
   - [x] No errors or warnings

4. **Event Count Check**
   - [x] Shows "✅ CORRECT (1 event)"
   - [x] event_count = 1
   - [x] No duplicate events

### 🎉 If All Checked: DEPLOYMENT SUCCESSFUL!

---

## Troubleshooting Checklist

### Issue: Duplicate Key Error

- [ ] Check if test data already exists
- [ ] Run `check-existing-test-data.sql`
- [ ] Run `cleanup-test-data.sql`
- [ ] Try test again

### Issue: Event Count = 2

- [ ] Duplicate trigger issue confirmed
- [ ] Run `fix-duplicate-triggers.sql`
- [ ] Clean up test data
- [ ] Run test again
- [ ] Verify event_count = 1

### Issue: Event Count = 0

- [ ] Trigger not firing
- [ ] Run `diagnose-triggers.sql`
- [ ] Check if trigger exists
- [ ] Check trigger function
- [ ] May need to recreate trigger

### Issue: No Results

- [ ] Check for SQL errors
- [ ] Verify connection to database
- [ ] Check permissions
- [ ] Try simpler query first

---

## Next Steps After All Tests Pass

### 1. Clean Up Test Data
- [ ] Run cleanup script or
- [ ] Uncomment cleanup lines in test script
- [ ] Verify cleanup successful

### 2. Setup Cron Jobs
- [ ] Follow `MANUAL_STEPS_GUIDE.md` Step 4
- [ ] Enable `pg_cron` extension
- [ ] Run `setup_cron_jobs.sql`
- [ ] Verify cron jobs created

### 3. Test Complete Flow
- [ ] Create real booking
- [ ] Wait 30 seconds
- [ ] Check Firestore for synced data
- [ ] Verify `processed_at` populated

### 4. Monitor System
- [ ] Check outbox table regularly
- [ ] Monitor retry_count
- [ ] Watch for error_message
- [ ] Verify events being processed

---

## Documentation Reference

| Document | Purpose |
|----------|---------|
| `TEST_RESULTS_INTERPRETATION.md` | Understand test results |
| `DUPLICATE_KEY_RESOLUTION_GUIDE.md` | Fix duplicate key errors |
| `TESTING_ISSUES_GUIDE.md` | Resolve testing issues |
| `QUICK_START_TESTING.md` | Quick reference |

---

## Summary

### Minimum Required Tests

1. ✅ Run `check-existing-test-data.sql` (if data exists)
2. ✅ Run `cleanup-test-data.sql` (if needed)
3. ✅ Run `test-booking-flow-idempotent.sql`
4. ✅ Verify event_count = 1

### Success Indicator

**The single most important check**:
```
Event Count Check: event_count = 1, status = '✅ CORRECT'
```

If you see this → 🎉 **Everything is working!**

---

**Last Updated**: 2025-10-03  
**Status**: Ready for Testing  
**Estimated Time**: 10 minutes for complete testing

