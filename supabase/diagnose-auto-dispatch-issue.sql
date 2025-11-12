-- ============================================
-- 診斷 24/7 自動派單問題
-- ============================================
-- 日期: 2025-11-11
-- 問題: Railway 日誌顯示「沒有待派單的訂單（已付訂金）」
--       但實際上有訂單需要 large 車型
-- ============================================

-- 1. 檢查 deposit_paid 欄位是否存在
SELECT 
  '1️⃣ 檢查 deposit_paid 欄位' AS "診斷步驟",
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_name = 'bookings' 
      AND column_name = 'deposit_paid'
    ) THEN '✅ deposit_paid 欄位存在'
    ELSE '❌ deposit_paid 欄位不存在！需要執行 supabase/add-deposit-paid-column.sql'
  END AS "結果";

-- 2. 查看所有待派單訂單（不限制 deposit_paid）
SELECT 
  '2️⃣ 所有待派單訂單（不限制 deposit_paid）' AS "診斷步驟";

SELECT 
  id,
  booking_number AS "訂單編號",
  status AS "狀態",
  vehicle_type AS "車型",
  deposit_paid AS "已付訂金",
  deposit_amount AS "訂金金額",
  driver_id AS "司機 ID",
  created_at AS "建立時間"
FROM bookings
WHERE status = 'pending'
  AND driver_id IS NULL
ORDER BY created_at DESC;

-- 3. 查看已付訂金的待派單訂單
SELECT 
  '3️⃣ 已付訂金的待派單訂單' AS "診斷步驟";

SELECT 
  id,
  booking_number AS "訂單編號",
  status AS "狀態",
  vehicle_type AS "車型",
  deposit_paid AS "已付訂金",
  deposit_amount AS "訂金金額",
  driver_id AS "司機 ID",
  created_at AS "建立時間"
FROM bookings
WHERE status = 'pending'
  AND driver_id IS NULL
  AND deposit_paid = true
ORDER BY created_at DESC;

-- 4. 查看所有訂單的 deposit_paid 狀態分佈
SELECT 
  '4️⃣ 訂單 deposit_paid 狀態分佈' AS "診斷步驟";

SELECT 
  status AS "訂單狀態",
  deposit_paid AS "已付訂金",
  COUNT(*) AS "數量"
FROM bookings
GROUP BY status, deposit_paid
ORDER BY status, deposit_paid;

-- 5. 查看可用司機的車型
SELECT 
  '5️⃣ 可用司機的車型' AS "診斷步驟";

SELECT 
  d.vehicle_type AS "車型",
  COUNT(*) AS "可用司機數量"
FROM drivers d
WHERE d.is_available = true
GROUP BY d.vehicle_type
ORDER BY d.vehicle_type;

-- 6. 查看所有司機的狀態
SELECT 
  '6️⃣ 所有司機的狀態' AS "診斷步驟";

SELECT 
  u.email AS "司機 Email",
  d.vehicle_type AS "車型",
  d.is_available AS "可接單",
  u.status AS "用戶狀態"
FROM drivers d
JOIN users u ON d.user_id = u.id
WHERE u.role = 'driver'
ORDER BY d.vehicle_type, d.is_available DESC;

-- 7. 檢查是否有 pending 狀態但 deposit_paid = false 的訂單
SELECT 
  '7️⃣ pending 狀態但未付訂金的訂單' AS "診斷步驟";

SELECT 
  id,
  booking_number AS "訂單編號",
  status AS "狀態",
  vehicle_type AS "車型",
  deposit_paid AS "已付訂金",
  deposit_amount AS "訂金金額",
  created_at AS "建立時間"
FROM bookings
WHERE status = 'pending'
  AND driver_id IS NULL
  AND (deposit_paid = false OR deposit_paid IS NULL)
ORDER BY created_at DESC;

-- 8. 檢查是否有其他狀態但 deposit_paid = true 的訂單
SELECT 
  '8️⃣ 其他狀態但已付訂金的訂單' AS "診斷步驟";

SELECT 
  id,
  booking_number AS "訂單編號",
  status AS "狀態",
  vehicle_type AS "車型",
  deposit_paid AS "已付訂金",
  driver_id AS "司機 ID",
  created_at AS "建立時間"
FROM bookings
WHERE status != 'pending'
  AND deposit_paid = true
ORDER BY created_at DESC
LIMIT 10;

-- 9. 建議修復方案
SELECT 
  '9️⃣ 建議修復方案' AS "診斷步驟";

SELECT 
  CASE 
    WHEN NOT EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_name = 'bookings' 
      AND column_name = 'deposit_paid'
    ) THEN '❌ 需要執行: supabase/add-deposit-paid-column.sql'
    
    WHEN EXISTS (
      SELECT 1 
      FROM bookings 
      WHERE status = 'pending' 
      AND driver_id IS NULL 
      AND (deposit_paid = false OR deposit_paid IS NULL)
    ) THEN '⚠️ 有 pending 訂單但 deposit_paid = false
    
建議執行以下 SQL 更新訂單狀態:

UPDATE bookings 
SET deposit_paid = true 
WHERE status IN (''paid_deposit'', ''assigned'', ''matched'', ''driver_confirmed'')
  AND deposit_paid = false;
'
    
    WHEN NOT EXISTS (
      SELECT 1 
      FROM bookings 
      WHERE status = 'pending' 
      AND driver_id IS NULL 
      AND deposit_paid = true
    ) THEN '✅ 沒有符合條件的訂單（status = pending, driver_id IS NULL, deposit_paid = true）
    
這是正常的！如果您想測試自動派單，請:
1. 創建一個新訂單
2. 設置 status = ''pending''
3. 設置 deposit_paid = true
4. 設置 driver_id = NULL
'
    
    ELSE '✅ 有符合條件的訂單，請檢查 Railway 日誌'
  END AS "建議";

-- 10. 顯示完整的訂單資訊（用於調試）
SELECT 
  '🔟 最近 5 筆訂單的完整資訊' AS "診斷步驟";

SELECT 
  id,
  booking_number,
  status,
  vehicle_type,
  deposit_paid,
  deposit_amount,
  driver_id,
  pickup_location,
  destination,
  created_at
FROM bookings
ORDER BY created_at DESC
LIMIT 5;

