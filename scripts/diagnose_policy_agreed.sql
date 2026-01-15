-- ============================================
-- 診斷 policy_agreed 欄位問題
-- ============================================
-- 創建日期: 2026-01-15
-- 用途: 檢查 policy_agreed 和 policy_agreed_at 欄位是否存在及其資料狀態
-- ============================================

-- 1. 檢查欄位是否存在
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'bookings' 
  AND column_name IN ('policy_agreed', 'policy_agreed_at')
ORDER BY column_name;

-- 2. 檢查最近 10 筆訂單的 policy_agreed 狀態
SELECT 
    id,
    booking_number,
    customer_id,
    status,
    policy_agreed,
    policy_agreed_at,
    created_at,
    updated_at
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

-- 3. 統計 policy_agreed 的分佈情況
SELECT 
    policy_agreed,
    COUNT(*) as count,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM bookings) as percentage
FROM bookings
GROUP BY policy_agreed
ORDER BY policy_agreed;

-- 4. 檢查有 policy_agreed_at 但 policy_agreed 為 false 的異常資料
SELECT 
    id,
    booking_number,
    policy_agreed,
    policy_agreed_at,
    created_at
FROM bookings
WHERE policy_agreed_at IS NOT NULL 
  AND (policy_agreed IS NULL OR policy_agreed = false)
ORDER BY created_at DESC
LIMIT 10;

-- 5. 檢查最近創建的訂單（過去 24 小時）
SELECT 
    id,
    booking_number,
    customer_id,
    status,
    policy_agreed,
    policy_agreed_at,
    deposit_paid,
    created_at
FROM bookings
WHERE created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

