# Quick Start - Testing Guide

## Got Duplicate Key Error? ✅ Good News!

This means your previous tests **worked successfully**!

---

## 3-Step Quick Fix

### Step 1: Check What Exists (2 minutes)

**File**: `check-existing-test-data.sql`

**Run this to see**:
- What test data exists
- **IMPORTANT**: How many events per booking (should be 1)

**Look for**: "Event Count per Booking"
- ✅ Shows "1 event" → Trigger working correctly!
- ❌ Shows "2 events" → Need to fix trigger first

---

### Step 2: Clean Up (1 minute)

**File**: `cleanup-test-data.sql`

**What it does**:
- Removes all test data
- Safe (only test data, not production)

**Expected**: "✅ CLEANUP SUCCESSFUL"

---

### Step 3: Fresh Test (2 minutes)

**File**: `test-booking-flow-idempotent.sql` ⭐ RECOMMENDED

**Why this one**:
- ✅ Can run multiple times
- ✅ Auto-cleanup before creating
- ✅ Easy to verify

**Expected Results**:
- Booking created: BK_TEST_001
- Event count: 1
- Status: ✅ CORRECT

---

## Alternative: No Cleanup Needed

**File**: `test-booking-flow-unique.sql`

**Use this if**:
- Don't want to clean up
- Want to keep test history
- Testing repeatedly

**How it works**:
- Generates unique IDs each time
- Never conflicts
- No cleanup needed

---

## Quick Verification

After running test, check:

```sql
-- Should show exactly 1
SELECT COUNT(*) FROM outbox 
WHERE payload->>'bookingNumber' = 'BK_TEST_001';
```

**Result = 1**: ✅ Perfect!  
**Result = 2**: ❌ Run `fix-duplicate-triggers.sql`

---

## Files at a Glance

| Step | File | Time |
|------|------|------|
| 1. Check | `check-existing-test-data.sql` | 2 min |
| 2. Clean | `cleanup-test-data.sql` | 1 min |
| 3. Test | `test-booking-flow-idempotent.sql` | 2 min |

**Total**: 5 minutes

---

## Need More Help?

See: `DUPLICATE_KEY_RESOLUTION_GUIDE.md` for complete guide

---

## Summary

1. ✅ Duplicate key error = Previous tests worked!
2. ✅ Check existing data first
3. ✅ Clean up test data
4. ✅ Run idempotent test script
5. ✅ Verify 1 event per booking

**You're almost done!** 🎉

