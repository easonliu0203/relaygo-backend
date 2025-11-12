-- 檢查 bookings 表的約束
-- 用於確定正確的 status 值

-- 檢查所有 CHECK 約束
SELECT 
  conname AS "約束名稱",
  pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND contype = 'c';

-- 檢查現有訂單的 status 值
SELECT DISTINCT 
  status AS "現有的 status 值",
  COUNT(*) AS "數量"
FROM bookings
GROUP BY status
ORDER BY COUNT(*) DESC;

-- 檢查 duration_hours 約束
SELECT 
  conname AS "約束名稱",
  pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND conname LIKE '%duration%';

-- 檢查 vehicle_type 約束
SELECT 
  conname AS "約束名稱",
  pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND conname LIKE '%vehicle%';

