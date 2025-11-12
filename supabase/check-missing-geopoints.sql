-- Supabase 缺失 GeoPoint 檢查腳本
-- 
-- 功能: 檢查 Supabase bookings 表中有多少訂單缺少地理位置座標
-- 
-- 使用方法:
-- 1. 在 Supabase SQL Editor 中執行此腳本
-- 2. 或使用 psql: psql -h <host> -U postgres -d postgres -f supabase/check-missing-geopoints.sql

-- ========================================
-- 檢查 bookings 表的 GeoPoint 欄位
-- ========================================

SELECT 
  '📊 總訂單數' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings

UNION ALL

SELECT 
  '✅ 有 pickup 座標' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE pickup_latitude IS NOT NULL AND pickup_longitude IS NOT NULL

UNION ALL

SELECT 
  '❌ 缺少 pickup 座標' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE pickup_latitude IS NULL OR pickup_longitude IS NULL

UNION ALL

SELECT 
  '✅ 有 dropoff 座標' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE destination IS NOT NULL  -- 注意: schema 中沒有 dropoff_latitude/dropoff_longitude

UNION ALL

SELECT 
  '❌ 缺少 dropoff 地址' AS "統計項目",
  COUNT(*) AS "數量"
FROM bookings
WHERE destination IS NULL;

-- ========================================
-- 列出缺少 pickup 座標的訂單 (前 10 個)
-- ========================================

SELECT 
  '⚠️  缺少 pickup 座標的訂單 (前 10 個):' AS "說明";

SELECT 
  id,
  booking_number AS "訂單編號",
  pickup_location AS "上車地點",
  pickup_latitude AS "緯度",
  pickup_longitude AS "經度",
  status AS "狀態",
  created_at AS "建立時間"
FROM bookings
WHERE pickup_latitude IS NULL OR pickup_longitude IS NULL
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- 按狀態統計缺少座標的訂單
-- ========================================

SELECT 
  '📊 按狀態統計缺少 pickup 座標的訂單:' AS "說明";

SELECT 
  status AS "訂單狀態",
  COUNT(*) AS "缺少座標的數量"
FROM bookings
WHERE pickup_latitude IS NULL OR pickup_longitude IS NULL
GROUP BY status
ORDER BY COUNT(*) DESC;

-- ========================================
-- 檢查是否有地址但沒有座標的訂單
-- ========================================

SELECT 
  '⚠️  有地址但沒有座標的訂單 (可能是地址解析失敗):' AS "說明";

SELECT 
  id,
  booking_number AS "訂單編號",
  pickup_location AS "上車地點",
  pickup_latitude AS "緯度",
  pickup_longitude AS "經度",
  status AS "狀態",
  created_at AS "建立時間"
FROM bookings
WHERE pickup_location IS NOT NULL 
  AND pickup_location != ''
  AND (pickup_latitude IS NULL OR pickup_longitude IS NULL)
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- 建議
-- ========================================

SELECT 
  '💡 建議:' AS "說明",
  CASE 
    WHEN (SELECT COUNT(*) FROM bookings WHERE pickup_latitude IS NULL OR pickup_longitude IS NULL) = 0 
    THEN '✅ 所有訂單都有完整的地理位置座標!'
    WHEN (SELECT COUNT(*) FROM bookings WHERE pickup_latitude IS NULL OR pickup_longitude IS NULL) < 10
    THEN '⚠️  少數訂單缺少座標,可能是測試資料或早期訂單。Flutter 代碼已修改為支持缺少座標的訂單。'
    ELSE '❌ 大量訂單缺少座標,需要檢查資料來源和地址解析邏輯!'
  END AS "建議內容";

