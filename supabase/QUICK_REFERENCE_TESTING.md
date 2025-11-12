# Quick Reference - Testing Issues

## Issue 1: UUID Error ❌ → ✅

**Error**: `invalid input syntax for type uuid: "<user_id>"`

**Solution**: Use `test-booking-flow.sql`

**Steps**:
1. Open `supabase/test-booking-flow.sql`
2. Copy all
3. Paste in SQL Editor
4. Run
5. ✅ Done!

---

## Issue 2: Trigger Count = 2 ⚠️

**Question**: Is this a problem?

**Answer**: Maybe. Need to test.

### Quick Test

```sql
-- Create test booking
WITH test_user AS (
  INSERT INTO users (firebase_uid, email, role)
  VALUES ('dup_test', 'dup@test.com', 'customer')
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

-- Count events
SELECT COUNT(*) FROM outbox WHERE payload->>'bookingNumber' = 'DUP_TEST';
```

**Result = 1**: ✅ No problem (PostgreSQL display quirk)  
**Result = 2**: ❌ Problem! Run `fix-duplicate-triggers.sql`

---

## Files Quick Reference

| Issue | File | Purpose |
|-------|------|---------|
| UUID Error | `test-booking-flow.sql` | Complete test script |
| Trigger Count | `diagnose-triggers.sql` | Diagnose issue |
| Trigger Count | `fix-duplicate-triggers.sql` | Fix if needed |
| Both | `TESTING_ISSUES_GUIDE.md` | Full guide |

---

## Decision Tree

```
UUID Error?
└─ Use test-booking-flow.sql ✅

Trigger Count = 2?
├─ Run quick test above
│  ├─ 1 event → ✅ OK (no action)
│  └─ 2 events → ❌ Run fix-duplicate-triggers.sql
```

---

## Expected Results

### After test-booking-flow.sql

- ✅ Booking created
- ✅ 1 event in outbox
- ✅ Event has booking data

### After fix-duplicate-triggers.sql

- ✅ Trigger count: 1 or 2 (both OK)
- ✅ Test creates only 1 event
- ✅ All checks pass

---

## Need Help?

See: `TESTING_ISSUES_GUIDE.md` for complete guide

