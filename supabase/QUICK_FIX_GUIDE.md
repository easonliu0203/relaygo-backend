# Quick Fix Guide - Outbox Table Deployment

## Problem
The `outbox` table does not exist in your Supabase database, causing the verification script to fail.

## Root Cause
The base database schema was never deployed to your remote Supabase instance.

## Solution (5 minutes)

### Step 1: Open Supabase SQL Editor

1. Go to: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql
2. Click "New query" button

### Step 2: Execute Setup Script

1. Open the file: `supabase/manual-setup-schema.sql` in your project
2. Copy the entire content (Ctrl+A, Ctrl+C)
3. Paste into the SQL Editor
4. Click "Run" button (or press Ctrl+Enter)

### Step 3: Verify Success

You should see at the bottom of the results:

```
Setup completed successfully!
Tables created: 3
Trigger created: 1
```

### Step 4: Run Verification Script

1. Open the file: `supabase/verify-deployment.sql`
2. Copy the entire content
3. Paste into a new SQL Editor query
4. Click "Run"

All checks should now pass! ✅

---

## What This Script Does

1. Creates `users` table (for customer, driver, admin accounts)
2. Creates `bookings` table (for ride bookings)
3. Creates `outbox` table (for event queue)
4. Creates trigger function to automatically populate outbox when bookings change
5. Creates cleanup function for old events

---

## Troubleshooting

### If you get "table already exists" errors
This is OK! The script uses `IF NOT EXISTS` so it won't break existing tables.

### If you get permission errors
Make sure you're logged in as the project owner or have admin access.

### If verification still fails
Check the error message and contact support with:
- The exact error message
- Screenshot of the SQL Editor results

---

## Next Steps After Success

1. ✅ Setup Cron Jobs (see `MANUAL_STEPS_GUIDE.md` Step 4)
2. ✅ Deploy Edge Functions (already done)
3. ✅ Test the complete flow

---

## Need Help?

Refer to the detailed development log: `docs/20251003_1107_01_Outbox_Table_Migration_Fix.md`

