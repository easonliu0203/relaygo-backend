# Automated Fix Verification

**Quick Reference - What to Do Next**

---

## 🎯 Current Status

✅ **Fix Applied**: Removed non-existent database columns from API
✅ **Documentation Updated**: Development log updated with fix details
✅ **Diagnostic Tools Created**: Ready for verification

---

## 🚀 Next Steps (In Order)

### Step 1: Restart Development Server ⚠️ CRITICAL

**Why**: The fix is in the code, but the running server has the old code in memory.

**How**:
1. Go to the terminal running `npm run dev`
2. Press `Ctrl+C` to stop the server
3. Run `npm run dev` again
4. Wait for "Ready on http://localhost:3000"

**Command**:
```bash
cd web-admin
npm run dev
```

---

### Step 2: Test from Mobile App

**Create a New Order**:
1. Open mobile app
2. Login as customer
3. Select pickup: "台北車站" (or any location)
4. Select destination: "台北101" (or any location)
5. Choose date/time
6. Click "確認預約"
7. Click "確認支付"

**Watch For**:
- ❌ OLD: "支付失敗 - Exception: 創建訂單失敗"
- ✅ NEW: "預約成功" (no error)

---

### Step 3: Verify in Database

**Open Supabase Dashboard SQL Editor**:
1. Go to: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql
2. Copy and paste the query below
3. Click "Run"

**Quick Verification Query**:
```sql
-- Check if booking was created in last 5 minutes
SELECT 
  id,
  booking_number,
  status,
  pickup_location,
  destination,
  total_amount,
  created_at,
  EXTRACT(EPOCH FROM (NOW() - created_at))/60 as minutes_ago
FROM bookings
WHERE created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Result**:
- Should see 1 row with your booking
- `booking_number`: Real booking number (e.g., BK20251004001)
- `status`: 'pending' or 'confirmed'
- `pickup_location`: Your selected location
- `destination`: Your selected destination
- `minutes_ago`: < 5

---

### Step 4: Check Sync Status

**Run This Query**:
```sql
-- Check if event was created and synced
WITH latest_booking AS (
  SELECT id, booking_number
  FROM bookings
  WHERE created_at >= NOW() - INTERVAL '5 minutes'
  ORDER BY created_at DESC
  LIMIT 1
)
SELECT 
  o.id as event_id,
  o.event_type,
  o.payload->>'bookingNumber' as booking_number,
  o.created_at as event_created,
  o.processed_at,
  CASE 
    WHEN o.processed_at IS NOT NULL THEN '✅ Synced to Firestore'
    WHEN EXTRACT(EPOCH FROM (NOW() - o.created_at)) < 60 THEN '⏳ Waiting for sync (< 1 min)'
    ELSE '⚠️ Stuck - Check cron job'
  END as sync_status
FROM outbox o
INNER JOIN latest_booking lb ON o.payload->>'bookingNumber' = lb.booking_number
ORDER BY o.created_at DESC;
```

**Expected Result**:
- Should see 1 event
- `event_type`: 'created'
- `sync_status`: '⏳ Waiting' (if < 30 sec) or '✅ Synced' (if > 30 sec)

---

## ✅ Success Checklist

### Immediate Success (< 30 seconds)

- [ ] Server restarted successfully
- [ ] Created order from mobile app
- [ ] **No "創建訂單失敗" error** ⭐
- [ ] **No "支付失敗" error** ⭐
- [ ] Saw "預約成功" message
- [ ] Booking appears in database query
- [ ] Event created in outbox

### After 30 Seconds

- [ ] Event `processed_at` is filled
- [ ] Sync status shows "✅ Synced"
- [ ] Can view order details in app
- [ ] No "訂單不存在" error

---

## 🔍 Troubleshooting

### Issue: Still Getting "創建訂單失敗"

**Check 1: Server Restarted?**
```bash
# In the terminal, you should see:
# ✓ Ready in XXXms
# ○ Compiling / ...
# ✓ Compiled / in XXXms
```

If not, restart the server.

**Check 2: Fix Applied?**
```bash
# Check the file content
cat web-admin/src/app/api/bookings/route.ts | grep -A 5 "destination:"
```

Should NOT see `destination_latitude` or `destination_longitude`.

**Check 3: Database Error?**

Run the diagnostic script:
```sql
-- File: supabase/diagnose-booking-creation-error.sql
-- Check "Required Fields" section
```

---

### Issue: Different Error Message

**Check API Logs**:

In the terminal where `npm run dev` is running, look for:
```
收到預約請求: { ... }
找到現有用戶: <user_id>
準備創建訂單: { ... }
訂單創建成功: { ... }
```

Or error messages like:
```
創建訂單失敗: <error details>
```

**Common Errors**:

1. **"column does not exist"**
   - Fix not applied or server not restarted
   - Solution: Restart server

2. **"null value in column violates not-null constraint"**
   - Missing required field
   - Solution: Check which field is required

3. **"foreign key constraint"**
   - User not found
   - Solution: Check user creation logic

---

### Issue: Booking Created but "訂單不存在"

This is the **original issue** - sync not working.

**Check**:
1. Wait 30 seconds
2. Run sync status query (Step 4 above)
3. Check if `processed_at` is filled

**If still NULL after 2 minutes**:
```sql
-- Check cron job
SELECT * FROM cron.job_run_details 
WHERE jobname = 'sync-orders-to-firestore'
ORDER BY start_time DESC LIMIT 5;
```

---

## 📊 Complete Verification Script

**Run All Checks at Once**:

```sql
-- ============================================
-- Complete Verification (Run after creating order)
-- ============================================

-- Check 1: Recent Booking
SELECT '=== 1. Recent Booking ===' as check;
SELECT 
  id, booking_number, status, pickup_location, destination,
  total_amount, created_at
FROM bookings
WHERE created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC LIMIT 1;

-- Check 2: Outbox Event
SELECT '=== 2. Outbox Event ===' as check;
WITH latest_booking AS (
  SELECT booking_number FROM bookings
  WHERE created_at >= NOW() - INTERVAL '5 minutes'
  ORDER BY created_at DESC LIMIT 1
)
SELECT 
  o.event_type,
  o.payload->>'bookingNumber' as booking_number,
  o.created_at,
  o.processed_at,
  CASE 
    WHEN o.processed_at IS NOT NULL THEN '✅ Synced'
    ELSE '⏳ Pending'
  END as status
FROM outbox o
INNER JOIN latest_booking lb ON o.payload->>'bookingNumber' = lb.booking_number;

-- Check 3: Sync Summary
SELECT '=== 3. Summary ===' as check;
SELECT 
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '5 minutes') as bookings_5min,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '5 minutes' AND processed_at IS NOT NULL) as synced_5min,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '5 minutes' AND processed_at IS NULL) as pending_5min
FROM (
  SELECT b.created_at, o.processed_at
  FROM bookings b
  LEFT JOIN outbox o ON o.payload->>'bookingNumber' = b.booking_number
) as combined;
```

**Expected Results**:
- Check 1: 1 booking
- Check 2: 1 event, status '✅ Synced' or '⏳ Pending'
- Check 3: bookings_5min=1, synced_5min=1 (after 30 sec), pending_5min=0

---

## 🎯 Quick Decision Tree

```
Did you restart the server?
├─ NO → Restart now! (Critical)
└─ YES → Continue

Created order from app?
├─ NO → Create order now
└─ YES → Continue

Got "創建訂單失敗" error?
├─ YES → Check API logs, verify fix applied
└─ NO → ✅ Success! Continue

Got "支付失敗" error?
├─ YES → Check payment API logs
└─ NO → ✅ Success! Continue

Saw "預約成功" message?
├─ NO → Check previous steps
└─ YES → ✅ Success! Continue

Can view order details?
├─ NO → Wait 30 seconds, check sync
└─ YES → 🎉 Complete Success!
```

---

## 📈 Timeline Expectations

```
T+0s:   Restart server
T+0s:   Create order from app
T+0s:   API receives request
T+0s:   User found/created
T+0s:   Booking created ✅ (Should work now!)
T+0s:   Payment processed
T+0s:   "預約成功" shown
T+0s:   Trigger fires
T+0s:   Event created
T+0-30s: Waiting for sync
T+30s:  Cron job runs
T+30s:  Event synced
T+30s:  Can view order details
```

---

## 🎉 Final Success Criteria

### You're done when ALL of these are true:

1. ✅ Server restarted
2. ✅ Order created from app
3. ✅ No "創建訂單失敗" error
4. ✅ No "支付失敗" error
5. ✅ "預約成功" message shown
6. ✅ Booking in database
7. ✅ Event in outbox
8. ✅ Event synced (after 30 sec)
9. ✅ Can view order details
10. ✅ No "訂單不存在" error

### If ALL checked:

🎉 **COMPLETE SUCCESS! System fully operational!**

---

## 📞 Need Help?

### If stuck, provide these details:

1. **Server Status**: Restarted? (Yes/No)
2. **Error Message**: Exact text from app
3. **API Logs**: Copy from terminal
4. **Database Query Results**: From verification queries
5. **Timeline**: How long since order creation?

---

**Last Updated**: 2025-10-04  
**Status**: Ready for Verification  
**Estimated Time**: 5 minutes total

