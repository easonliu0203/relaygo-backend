-- Supabase 缺失 Timestamp 檢查腳本
-- 
-- 功能: 檢查 Supabase bookings 表中有多少訂單缺少必填的時間戳欄位
-- 
-- 使用方法:
-- 1. 在 Supabase SQL Editor 中執行此腳本
-- 2. 或使用 psql: psql -h <host> -U postgres -d postgres -f supabase/check-missing-timestamps.sql

-- ========================================
-- 檢查 bookings 表的時間戳欄位
-- ========================================

SELECT 
  '📊 總訂單數' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings

UNION ALL

SELECT 
  '✅ 有 start_date' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE start_date IS NOT NULL

UNION ALL

SELECT 
  '❌ 缺少 start_date' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE start_date IS NULL

UNION ALL

SELECT 
  '✅ 有 start_time' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE start_time IS NOT NULL

UNION ALL

SELECT 
  '❌ 缺少 start_time' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE start_time IS NULL

UNION ALL

SELECT 
  '✅ 有 created_at' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE created_at IS NOT NULL

UNION ALL

SELECT 
  '❌ 缺少 created_at' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE created_at IS NULL;

-- ========================================
-- 列出缺少 start_date 或 start_time 的訂單 (前 10 個)
-- ========================================

SELECT 
  '⚠️  缺少 start_date 或 start_time 的訂單 (前 10 個):' AS "說明";

SELECT 
  id,
  booking_number AS "訂單編號",
  pickup_location AS "上車地點",
  start_date AS "開始日期",
  start_time AS "開始時間",
  status AS "狀態",
  created_at AS "建立時間"
FROM bookings
WHERE start_date IS NULL OR start_time IS NULL
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- 按狀態統計缺少時間戳的訂單
-- ========================================

SELECT 
  '📊 按狀態統計缺少 start_date/start_time 的訂單:' AS "說明";

SELECT 
  status AS "訂單狀態",
  COUNT(*) AS "缺少時間戳的數量"
FROM bookings
WHERE start_date IS NULL OR start_time IS NULL
GROUP BY status
ORDER BY COUNT(*) DESC;

-- ========================================
-- 檢查 created_at 是否有預設值
-- ========================================

SELECT 
  '⚠️  檢查 created_at 欄位 (應該都有預設值):' AS "說明";

SELECT 
  id,
  booking_number AS "訂單編號",
  created_at AS "建立時間",
  status AS "狀態"
FROM bookings
WHERE created_at IS NULL
ORDER BY id DESC
LIMIT 10;

-- ========================================
-- 檢查 start_date 和 start_time 的組合情況
-- ========================================

SELECT 
  '📊 start_date 和 start_time 組合情況:' AS "說明";

SELECT 
  CASE 
    WHEN start_date IS NOT NULL AND start_time IS NOT NULL THEN '✅ 兩者都有'
    WHEN start_date IS NOT NULL AND start_time IS NULL THEN '⚠️  只有 start_date'
    WHEN start_date IS NULL AND start_time IS NOT NULL THEN '⚠️  只有 start_time'
    ELSE '❌ 兩者都沒有'
  END AS "組合情況",
  COUNT(*) AS "數量"
FROM bookings
GROUP BY 
  CASE 
    WHEN start_date IS NOT NULL AND start_time IS NOT NULL THEN '✅ 兩者都有'
    WHEN start_date IS NOT NULL AND start_time IS NULL THEN '⚠️  只有 start_date'
    WHEN start_date IS NULL AND start_time IS NOT NULL THEN '⚠️  只有 start_time'
    ELSE '❌ 兩者都沒有'
  END
ORDER BY COUNT(*) DESC;

-- ========================================
-- 建議
-- ========================================

SELECT 
  '💡 建議:' AS "說明",
  CASE 
    WHEN (SELECT COUNT(*) FROM bookings WHERE start_date IS NULL OR start_time IS NULL) = 0 
    THEN '✅ 所有訂單都有完整的時間戳!'
    WHEN (SELECT COUNT(*) FROM bookings WHERE start_date IS NULL OR start_time IS NULL) < 10
    THEN '⚠️  少數訂單缺少時間戳。Flutter 代碼已修改為使用 createdAt 作為 bookingTime 的後備值。'
    ELSE '❌ 大量訂單缺少時間戳,需要檢查資料來源和 Edge Function 邏輯!'
  END AS "建議內容";

-- ========================================
-- Edge Function 修復建議
-- ========================================

SELECT 
  '🔧 Edge Function 修復建議:' AS "說明",
  '檢查 supabase/functions/sync-to-firestore/index.ts 中的 bookingTime 組合邏輯。
  
當前邏輯:
  if (bookingData.startDate && bookingData.startTime) {
    bookingTimeStr = `${bookingData.startDate}T${bookingData.startTime}`
  } else {
    bookingTimeStr = bookingData.createdAt
  }

建議改進:
  // 確保總是有值
  const bookingTimeStr = bookingData.startDate && bookingData.startTime
    ? `${bookingData.startDate}T${bookingData.startTime}`
    : (bookingData.createdAt || new Date().toISOString())
  
  // 或者拋出錯誤,強制要求 startDate 和 startTime
  if (!bookingData.startDate || !bookingData.startTime) {
    throw new Error(`Missing required fields: startDate=${bookingData.startDate}, startTime=${bookingData.startTime}`)
  }
' AS "修復建議";

