-- 快速檢查 bookings 表的 status 約束

-- 1. 查看 status 的 CHECK 約束定義
SELECT 
  conname AS "約束名稱",
  pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND conname LIKE '%status%';

-- 2. 查看現有訂單使用的 status 值
SELECT DISTINCT 
  status AS "現有的 status 值",
  COUNT(*) AS "數量"
FROM bookings
GROUP BY status
ORDER BY COUNT(*) DESC;

-- 3. 嘗試查看表定義
SELECT 
  column_name,
  data_type,
  character_maximum_length,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'bookings'
  AND column_name = 'status';

