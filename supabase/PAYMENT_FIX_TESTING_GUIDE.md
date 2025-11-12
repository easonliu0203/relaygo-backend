# Payment Fix Testing Guide

**After Schema Mismatch Fix**

---

## 🔍 Problem Summary

**Error**: "支付失敗 - Exception: 創建預約失敗: Exception: 創建訂單失敗"

**Root Cause**: API tried to insert `destination_latitude` and `destination_longitude` columns that don't exist in database schema.

**Fix**: Removed non-existent columns from API insert statement.

---

## 🚀 Quick Test (5 Minutes)

### Step 1: Restart Development Server (1 minute)

**IMPORTANT**: Must restart to load the fixed code!

```bash
# Stop the current server (Ctrl+C)
cd web-admin
npm run dev
```

**Wait for**: "Ready on http://localhost:3000"

---

### Step 2: Test Order Creation (3 minutes)

1. **Open Mobile App**
2. **Login** as customer
3. **Create New Booking**:
   - Select pickup location (e.g., "台北車站")
   - Select destination (e.g., "台北101")
   - Choose date/time
   - Select vehicle type
   - Confirm booking

4. **Complete Payment**:
   - Select payment method
   - Click "確認支付"
   - **Watch for success message**

**Expected Results**:
- ✅ No "創建訂單失敗" error
- ✅ No "支付失敗" error
- ✅ Shows "預約成功" message
- ✅ Can view order details

---

### Step 3: Verify in Database (1 minute)

**Run**: `supabase/diagnose-booking-creation-error.sql`

**Check Results**:

#### Result 1: Recent Bookings
```
Should see your booking:
- Real UUID
- Your pickup location
- Your destination
- Status: pending or confirmed
- Created within last few minutes
```

#### Result 2: Recent Users
```
May see your user if newly created:
- Firebase UID
- Email
- Role: customer
```

---

## ✅ Success Criteria

### Order Creation Phase

- [ ] ✅ No "創建訂單失敗" error
- [ ] ✅ Booking created in database
- [ ] ✅ Real UUID returned
- [ ] ✅ Proceeds to payment page

### Payment Phase

- [ ] ✅ No "支付失敗" error
- [ ] ✅ Payment record created
- [ ] ✅ Booking status updated
- [ ] ✅ Shows "預約成功" message

### After Payment

- [ ] ✅ Can view order details
- [ ] ✅ No "訂單不存在" error
- [ ] ✅ Order syncs to Firestore (within 30 seconds)
- [ ] ✅ Order status updates in real-time

---

## 🔧 Troubleshooting

### Issue 1: Still Shows "創建訂單失敗"

**Possible Causes**:
1. Development server not restarted
2. Different error (not schema mismatch)
3. Missing required fields

**Diagnosis**:
```sql
-- Check if booking was created
SELECT * FROM bookings 
WHERE created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC LIMIT 1;

-- Check table schema
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'bookings'
ORDER BY ordinal_position;
```

**Solutions**:
- If server not restarted → Restart server
- If booking not created → Check API logs for error
- If schema issue → Verify fix was applied

---

### Issue 2: Different Error Message

**If you see a different error**, check:

1. **API Logs** (in terminal where `npm run dev` is running):
   ```
   Look for:
   - "收到預約請求:" (shows request received)
   - "找到現有用戶:" or "創建新用戶:" (user handling)
   - "準備創建訂單:" (booking data)
   - "訂單創建成功:" (success)
   - Any error messages
   ```

2. **Database Constraints**:
   ```sql
   -- Check for constraint violations
   SELECT 
     conname as constraint_name,
     contype as constraint_type
   FROM pg_constraint
   WHERE conrelid = 'bookings'::regclass;
   ```

3. **Required Fields**:
   ```sql
   -- Check which fields are required
   SELECT column_name
   FROM information_schema.columns
   WHERE table_name = 'bookings'
     AND is_nullable = 'NO'
     AND column_default IS NULL;
   ```

---

### Issue 3: Payment Succeeds but Order Not Found

**This is the original issue** - means sync not working.

**Check**:
```sql
-- Check if event was created
SELECT * FROM outbox 
WHERE created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC LIMIT 1;

-- Check if synced
SELECT processed_at FROM outbox 
WHERE created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC LIMIT 1;
```

**Solution**: Wait 30 seconds for sync, or check cron job.

---

## 📊 Verification Queries

### Quick Health Check

```sql
-- Check recent activity
SELECT 
  'Bookings (5min)' as metric,
  COUNT(*) as count
FROM bookings
WHERE created_at >= NOW() - INTERVAL '5 minutes'

UNION ALL

SELECT 
  'Users (5min)' as metric,
  COUNT(*) as count
FROM users
WHERE created_at >= NOW() - INTERVAL '5 minutes'

UNION ALL

SELECT 
  'Outbox Events (5min)' as metric,
  COUNT(*) as count
FROM outbox
WHERE created_at >= NOW() - INTERVAL '5 minutes';
```

**Expected**: At least 1 booking, possibly 1 user, 1 outbox event

---

### Detailed Booking Check

```sql
-- Get latest booking with all details
SELECT 
  b.id,
  b.booking_number,
  b.status,
  b.pickup_location,
  b.destination,
  b.start_date,
  b.start_time,
  b.vehicle_type,
  b.total_amount,
  b.deposit_amount,
  b.created_at,
  u.firebase_uid,
  u.email
FROM bookings b
JOIN users u ON b.customer_id = u.id
ORDER BY b.created_at DESC
LIMIT 1;
```

---

## 🎯 Complete Test Checklist

### Pre-Test

- [ ] Development server restarted
- [ ] Mobile app ready
- [ ] Test user logged in

### During Test

- [ ] Create booking
- [ ] No "創建訂單失敗" error
- [ ] Proceed to payment
- [ ] Complete payment
- [ ] No "支付失敗" error
- [ ] See "預約成功" message

### Post-Test

- [ ] Run diagnostic queries
- [ ] Verify booking in database
- [ ] Verify outbox event created
- [ ] Wait 30 seconds
- [ ] Verify event synced (processed_at filled)
- [ ] Open order details in app
- [ ] Confirm no "訂單不存在" error

---

## 📈 Expected Timeline

```
T+0s:  User clicks "確認支付"
T+0s:  API receives request
T+0s:  User created/found
T+0s:  Booking created in Supabase ✅ (Fixed!)
T+0s:  Real UUID returned
T+0s:  Payment record created
T+0s:  Booking status updated
T+0s:  Trigger fires
T+0s:  Event created in outbox
T+0s:  Client shows "預約成功"
T+0-30s: Client shows loading
T+30s: Cron job syncs to Firestore
T+30s: Client shows order details
```

---

## 🎉 Success Indicators

### You're successful when:

1. ✅ No "創建訂單失敗" error
2. ✅ No "支付失敗" error
3. ✅ Booking created with real UUID
4. ✅ Payment record created
5. ✅ Event created in outbox
6. ✅ Event synced to Firestore (within 30 seconds)
7. ✅ Can view order details in app
8. ✅ No "訂單不存在" error

### If all above are true:

🎉 **CONGRATULATIONS! Complete flow is working!**

---

## 📚 Related Documentation

- **Problem Analysis**: `docs/20251004_0042_03_Production_Order_Not_Found_Fix.md`
- **Diagnostic Script**: `supabase/diagnose-booking-creation-error.sql`
- **Production Testing**: `supabase/PRODUCTION_TESTING_GUIDE.md`

---

## 🔑 Key Differences from Previous Test

### Before Fix

```
User clicks payment → API error → "創建訂單失敗" ❌
```

### After Fix

```
User clicks payment → Booking created → Payment processed → Success ✅
```

---

**Last Updated**: 2025-10-04  
**Status**: Ready for Re-Testing  
**Estimated Time**: 5 minutes

