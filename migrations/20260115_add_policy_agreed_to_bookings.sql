-- ============================================
-- 添加取消政策同意欄位到 bookings 表
-- ============================================
-- 創建日期: 2026-01-15
-- 用途: 記錄客戶是否已同意取消政策，用於法律合規和爭議處理
-- ============================================

-- 1. 添加 policy_agreed 欄位（取消政策同意狀態）
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS policy_agreed BOOLEAN DEFAULT false;

-- 2. 添加 policy_agreed_at 欄位（同意時間戳記）
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS policy_agreed_at TIMESTAMP WITH TIME ZONE;

-- 3. 添加註釋
COMMENT ON COLUMN bookings.policy_agreed IS '客戶是否已同意取消政策（用於法律合規）';
COMMENT ON COLUMN bookings.policy_agreed_at IS '客戶同意取消政策的時間戳記';

-- 4. 創建索引（用於查詢未同意政策的訂單）
CREATE INDEX IF NOT EXISTS idx_bookings_policy_agreed ON bookings(policy_agreed);

-- ============================================
-- 驗證腳本
-- ============================================

-- 查詢新增的欄位
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'bookings' 
  AND column_name IN ('policy_agreed', 'policy_agreed_at')
ORDER BY column_name;

-- 查詢索引
SELECT 
    indexname, 
    indexdef
FROM pg_indexes
WHERE tablename = 'bookings' 
  AND indexname = 'idx_bookings_policy_agreed';

