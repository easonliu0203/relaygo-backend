# Quick Test Guide - Payment Fix

**⚠️ MUST DO FIRST: Restart Development Server**

```bash
cd web-admin
npm run dev
```

Wait for: "Ready on http://localhost:3000"

---

## Test Steps

### 1. Create Order from Mobile App (2 min)
- Open app
- Login
- Create booking
- Complete payment

### 2. Check Results

**✅ Success if you see**:
- "預約成功" message
- Can view order details
- No errors

**❌ Problem if you see**:
- "創建訂單失敗"
- "支付失敗"
- "訂單不存在"

### 3. Check Terminal Logs

**Look for**:
```
✅ 訂單創建成功
✅ 支付記錄創建成功
✅ 模擬支付完成
```

**If you see ❌**:
- Read the error message
- Check `supabase/FINAL_FIX_SUMMARY.md` for troubleshooting

### 4. Verify Database

**Run in Supabase SQL Editor**:
```sql
SELECT * FROM bookings 
WHERE created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC LIMIT 1;
```

**Expected**: 1 row with your booking

---

## Quick Decision Tree

```
Server restarted? 
├─ NO → Restart now!
└─ YES → Continue

Got "創建訂單失敗"?
├─ YES → Check terminal logs, see FINAL_FIX_SUMMARY.md
└─ NO → ✅ Success!

Got "支付失敗"?
├─ YES → Check terminal logs, see FINAL_FIX_SUMMARY.md
└─ NO → ✅ Success!

Can view order details?
├─ NO → Wait 30 seconds, check sync
└─ YES → 🎉 Complete Success!
```

---

## Files to Reference

| Issue | File |
|-------|------|
| Overview | `supabase/FINAL_FIX_SUMMARY.md` |
| Detailed Testing | `supabase/PAYMENT_FIX_TESTING_GUIDE.md` |
| Verification | `supabase/AUTOMATED_FIX_VERIFICATION.md` |
| Diagnosis | `supabase/diagnose-booking-creation-error.sql` |

---

**Estimated Time**: 5 minutes  
**Status**: Ready to test!

