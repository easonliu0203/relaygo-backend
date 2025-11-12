# Production Testing Guide

**After API Fix - Complete Flow Testing**

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Restart Development Server (1 minute)

```bash
cd web-admin
npm run dev
```

**Wait for**: "Ready on http://localhost:3000"

---

### Step 2: Create Order from Mobile App (2 minutes)

1. Open mobile app
2. Login as customer
3. Create new booking:
   - Select pickup location
   - Select destination
   - Choose date/time
   - Confirm booking
4. Complete payment (mock payment)
5. **Note the order ID** from success page

---

### Step 3: Verify in Database (2 minutes)

**Run**: `supabase/verify-production-flow.sql`

**Check Results**:

#### Result 1: Recent Bookings
```
Should see your booking with:
- Real UUID (not mock_booking_xxx)
- Your pickup location
- Status: pending or confirmed
- Created within last few minutes
```

#### Result 2: Outbox Events
```
Should see 1 event with:
- booking_number matching your order
- processed_at: NULL (if < 30 sec) or timestamp (if > 30 sec)
- sync_status: "⏳ Waiting" or "✅ Synced"
```

#### Result 3: Sync Status
```
Should show:
- event_count: 1
- status: "✅ SYNCED" (after 30 sec) or "⏳ PENDING" (before 30 sec)
```

---

## ✅ Success Criteria

### Immediate (< 30 seconds)

- [ ] ✅ Order created in Supabase `bookings` table
- [ ] ✅ Real UUID returned (not mock ID)
- [ ] ✅ Event created in `outbox` table
- [ ] ✅ Client shows "Booking Successful"
- [ ] ✅ Can navigate to order details page

### After 30 Seconds

- [ ] ✅ Event `processed_at` is filled
- [ ] ✅ Sync status shows "✅ SYNCED"
- [ ] ✅ Order visible in Firestore `orders_rt` collection
- [ ] ✅ Client can view order details (not "Order Not Found")
- [ ] ✅ Order status updates in real-time

---

## 🔍 Troubleshooting

### Issue 1: Still Shows "Order Not Found"

**Possible Causes**:
1. Development server not restarted
2. Sync not completed yet (< 30 seconds)
3. Cron job not running

**Diagnosis**:
```sql
-- Check if booking exists
SELECT * FROM bookings ORDER BY created_at DESC LIMIT 1;

-- Check if event exists
SELECT * FROM outbox ORDER BY created_at DESC LIMIT 1;

-- Check if synced
SELECT processed_at FROM outbox ORDER BY created_at DESC LIMIT 1;
```

**Solutions**:
- If booking doesn't exist → API still using mock data (restart server)
- If event doesn't exist → Trigger not firing (check trigger)
- If processed_at is NULL → Wait 30 seconds or check cron job

---

### Issue 2: Event Not Syncing

**Symptoms**:
- Event created but `processed_at` stays NULL after 2+ minutes

**Diagnosis**:
```sql
-- Check cron job executions
SELECT * FROM cron.job_run_details 
WHERE jobname = 'sync-orders-to-firestore'
ORDER BY start_time DESC LIMIT 5;

-- Check for errors
SELECT error_message FROM outbox 
WHERE error_message IS NOT NULL 
ORDER BY created_at DESC LIMIT 5;
```

**Solutions**:
- If no cron executions → Cron job not running (check setup)
- If error_message exists → Check Edge Function logs
- If cron running but not processing → Check Edge Function code

---

### Issue 3: Multiple Events Created

**Symptoms**:
- 2 or more events for same booking

**Diagnosis**:
```sql
-- Check event count per booking
SELECT 
  payload->>'bookingNumber' as booking_number,
  COUNT(*) as event_count
FROM outbox
GROUP BY payload->>'bookingNumber'
HAVING COUNT(*) > 1;
```

**Solution**:
- Run `fix-duplicate-triggers.sql`
- Verify trigger count = 1

---

## 📊 Monitoring Queries

### Quick Health Check

```sql
-- Should all be 0 or very low
SELECT 
  COUNT(*) FILTER (WHERE processed_at IS NULL AND created_at < NOW() - INTERVAL '2 minutes') as stuck_events,
  COUNT(*) FILTER (WHERE error_message IS NOT NULL) as failed_events,
  COUNT(*) FILTER (WHERE retry_count > 3) as high_retry_events
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 hour';
```

**Expected**: All counts = 0

---

### Sync Performance

```sql
-- Average sync time
SELECT 
  AVG(EXTRACT(EPOCH FROM (processed_at - created_at))) as avg_sync_seconds,
  MAX(EXTRACT(EPOCH FROM (processed_at - created_at))) as max_sync_seconds,
  COUNT(*) as total_synced
FROM outbox
WHERE processed_at IS NOT NULL
  AND created_at >= NOW() - INTERVAL '1 hour';
```

**Expected**: 
- avg_sync_seconds: 15-45 (depends on cron frequency)
- max_sync_seconds: < 60

---

### Cron Job Health

```sql
-- Recent cron executions
SELECT 
  jobname,
  status,
  start_time,
  EXTRACT(EPOCH FROM (end_time - start_time)) as duration_seconds
FROM cron.job_run_details
WHERE start_time >= NOW() - INTERVAL '10 minutes'
ORDER BY start_time DESC;
```

**Expected**:
- At least 1 execution in last 10 minutes
- Status: 'succeeded'
- Duration: < 5 seconds

---

## 🎯 Complete Test Checklist

### Pre-Test

- [ ] Development server restarted
- [ ] Mobile app updated
- [ ] Supabase connection working
- [ ] Cron jobs enabled

### During Test

- [ ] Create order from mobile app
- [ ] Note order ID
- [ ] Check "Booking Successful" message
- [ ] Wait 30 seconds

### Post-Test

- [ ] Run `verify-production-flow.sql`
- [ ] Check all 6 steps pass
- [ ] Verify order in Firestore
- [ ] Open order details in app
- [ ] Confirm no "Order Not Found" error

### Cleanup (Optional)

- [ ] Delete test order from Supabase
- [ ] Delete test event from outbox
- [ ] Delete test order from Firestore

---

## 📈 Expected Timeline

```
T+0s:  Order created in Supabase
T+0s:  Event created in outbox
T+0s:  Client shows "Booking Successful"
T+0s:  Client navigates to order details
T+0-30s: Client shows loading or "Syncing..."
T+30s: Cron job runs
T+30s: Event synced to Firestore
T+30s: processed_at filled
T+30s: Client shows order details
```

---

## 🔧 Advanced Diagnostics

### Check Firestore Directly

**Firebase Console**:
1. Go to Firestore Database
2. Navigate to `orders_rt` collection
3. Search for your order ID
4. Should see document with all booking data

### Check Edge Function Logs

**Supabase Dashboard**:
1. Go to Edge Functions
2. Select `sync-to-firestore`
3. View logs
4. Look for recent executions and errors

### Manual Sync Trigger

```sql
-- Manually trigger sync for specific event
SELECT 
  net.http_post(
    url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
    body := '{}'::jsonb
  );
```

---

## 📚 Related Documentation

- **Problem Analysis**: `docs/20251004_0042_03_Production_Order_Not_Found_Fix.md`
- **Diagnostic Script**: `supabase/diagnose-production-order.sql`
- **Verification Script**: `supabase/verify-production-flow.sql`
- **Cron Setup**: `supabase/MANUAL_STEPS_GUIDE.md` Step 4

---

## 🎉 Success Indicators

### You're successful when:

1. ✅ Order created with real UUID (not mock_xxx)
2. ✅ Event created in outbox
3. ✅ Event synced within 30-60 seconds
4. ✅ Order visible in Firestore
5. ✅ Client can view order details
6. ✅ No "Order Not Found" errors
7. ✅ Order status updates in real-time

### If all above are true:

🎉 **CONGRATULATIONS! Your production flow is working!**

---

**Last Updated**: 2025-10-04  
**Status**: Ready for Testing  
**Estimated Time**: 5 minutes

