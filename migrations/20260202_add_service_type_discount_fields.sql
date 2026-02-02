-- ============================================
-- 依服務類型設定折扣欄位 Migration
-- ============================================
-- 創建日期: 2026-02-02
-- 用途: 為 influencers 表新增依服務類型的折扣百分比欄位
-- ============================================

-- ============================================
-- 第一部分：新增折扣類型欄位
-- ============================================

-- 新增折扣模式欄位（統一 或 依服務類型）
ALTER TABLE influencers 
ADD COLUMN IF NOT EXISTS discount_type TEXT 
CHECK (discount_type IN ('unified', 'by_service_type')) 
DEFAULT 'unified';

-- 新增包車旅遊折扣百分比
ALTER TABLE influencers 
ADD COLUMN IF NOT EXISTS discount_percent_charter NUMERIC(5,2) DEFAULT 0;

-- 新增即時派車折扣百分比
ALTER TABLE influencers 
ADD COLUMN IF NOT EXISTS discount_percent_instant_ride NUMERIC(5,2) DEFAULT 0;

-- ============================================
-- 第二部分：建立索引
-- ============================================

CREATE INDEX IF NOT EXISTS idx_influencers_discount_type ON influencers(discount_type);

-- ============================================
-- 第三部分：新增欄位註解
-- ============================================

COMMENT ON COLUMN influencers.discount_type IS '折扣模式：unified（統一比例）或 by_service_type（依服務類型）';
COMMENT ON COLUMN influencers.discount_percent_charter IS '包車旅遊折扣百分比（例如：5 代表 95 折）';
COMMENT ON COLUMN influencers.discount_percent_instant_ride IS '即時派車折扣百分比（例如：3 代表 97 折）';

-- ============================================
-- 第四部分：資料遷移（將現有的 discount_percentage 複製到新欄位）
-- ============================================

-- 將現有的 discount_percentage 值同步到 discount_percent_charter 和 discount_percent_instant_ride
-- 這確保既有數據在切換到新欄位後仍然有效
UPDATE influencers
SET 
  discount_percent_charter = COALESCE(discount_percentage, 0),
  discount_percent_instant_ride = COALESCE(discount_percentage, 0)
WHERE discount_percent_charter = 0 AND discount_percent_instant_ride = 0;

-- ============================================
-- 完成
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ 依服務類型折扣欄位 Migration 完成！';
  RAISE NOTICE '========================================';
  RAISE NOTICE '已完成的操作：';
  RAISE NOTICE '1. ✅ 新增 discount_type 欄位（折扣模式選擇）';
  RAISE NOTICE '2. ✅ 新增 discount_percent_charter 欄位（包車旅遊折扣）';
  RAISE NOTICE '3. ✅ 新增 discount_percent_instant_ride 欄位（即時派車折扣）';
  RAISE NOTICE '4. ✅ 同步現有折扣數據到新欄位';
  RAISE NOTICE '========================================';
END $$;

