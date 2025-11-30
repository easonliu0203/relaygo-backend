-- ============================================
-- 添加旅遊方案欄位到 bookings 表
-- ============================================
-- 創建日期: 2025-11-30
-- 用途: 添加 tour_package_id 和 tour_package_name 欄位
-- ============================================

-- 1. 添加 tour_package_id 欄位（旅遊方案 ID）
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS tour_package_id UUID;

-- 2. 添加 tour_package_name 欄位（旅遊方案名稱）
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS tour_package_name VARCHAR(100);

-- 3. 添加外鍵約束（可選，如果需要強制關聯）
-- ALTER TABLE bookings 
-- ADD CONSTRAINT fk_tour_package 
-- FOREIGN KEY (tour_package_id) 
-- REFERENCES tour_packages(id) 
-- ON DELETE SET NULL;

-- 4. 添加註釋
COMMENT ON COLUMN bookings.tour_package_id IS '旅遊方案 ID（關聯 tour_packages 表）';
COMMENT ON COLUMN bookings.tour_package_name IS '旅遊方案名稱（例如：台北一日遊）';

-- 5. 創建索引以提高查詢效能
CREATE INDEX IF NOT EXISTS idx_bookings_tour_package_id ON bookings(tour_package_id) WHERE tour_package_id IS NOT NULL;

-- 6. 驗證欄位已添加
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'bookings'
  AND column_name IN ('tour_package_id', 'tour_package_name')
ORDER BY column_name;

