-- Migration: 新增網紅優惠碼系統資料表
-- Date: 2025-12-05
-- Author: System
-- Description: 新增 influencers 和 promo_code_usage 資料表，並修改 bookings 資料表

-- ============================================================
-- 1. 建立 influencers 資料表（網紅管理）
-- ============================================================

CREATE TABLE IF NOT EXISTS influencers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  instagram_url TEXT,
  promo_code TEXT NOT NULL UNIQUE,
  discount_amount_enabled BOOLEAN NOT NULL DEFAULT false,
  discount_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  discount_percentage_enabled BOOLEAN NOT NULL DEFAULT false,
  discount_percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
  account_username TEXT NOT NULL UNIQUE,
  account_password TEXT NOT NULL,
  bank_name TEXT,
  bank_code TEXT,
  bank_account_number TEXT,
  bank_account_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true
);

-- 建立索引
CREATE INDEX IF NOT EXISTS idx_influencers_promo_code ON influencers(promo_code);
CREATE INDEX IF NOT EXISTS idx_influencers_account_username ON influencers(account_username);
CREATE INDEX IF NOT EXISTS idx_influencers_is_active ON influencers(is_active);

-- 新增註解
COMMENT ON TABLE influencers IS '網紅管理資料表';
COMMENT ON COLUMN influencers.id IS '網紅唯一識別碼';
COMMENT ON COLUMN influencers.name IS '網紅名稱';
COMMENT ON COLUMN influencers.instagram_url IS '網紅 IG 連結';
COMMENT ON COLUMN influencers.promo_code IS '優惠代碼（唯一）';
COMMENT ON COLUMN influencers.discount_amount_enabled IS '是否啟用固定金額折扣';
COMMENT ON COLUMN influencers.discount_amount IS '固定折扣金額';
COMMENT ON COLUMN influencers.discount_percentage_enabled IS '是否啟用百分比折扣';
COMMENT ON COLUMN influencers.discount_percentage IS '折扣百分比（例如：5 代表 95 折）';
COMMENT ON COLUMN influencers.account_username IS '登入帳號（唯一）';
COMMENT ON COLUMN influencers.account_password IS '登入密碼（bcrypt 加密）';
COMMENT ON COLUMN influencers.bank_name IS '銀行名稱';
COMMENT ON COLUMN influencers.bank_code IS '銀行代號';
COMMENT ON COLUMN influencers.bank_account_number IS '銀行帳號';
COMMENT ON COLUMN influencers.bank_account_name IS '銀行戶名';
COMMENT ON COLUMN influencers.is_active IS '是否啟用';

-- ============================================================
-- 2. 建立 promo_code_usage 資料表（優惠碼使用記錄）
-- ============================================================

CREATE TABLE IF NOT EXISTS promo_code_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  influencer_id UUID NOT NULL REFERENCES influencers(id) ON DELETE CASCADE,
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  promo_code TEXT NOT NULL,
  original_price NUMERIC(10,2) NOT NULL,
  discount_amount_applied NUMERIC(10,2) NOT NULL,
  discount_percentage_applied NUMERIC(5,2) NOT NULL,
  final_price NUMERIC(10,2) NOT NULL,
  used_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 建立索引
CREATE INDEX IF NOT EXISTS idx_promo_code_usage_influencer_id ON promo_code_usage(influencer_id);
CREATE INDEX IF NOT EXISTS idx_promo_code_usage_booking_id ON promo_code_usage(booking_id);
CREATE INDEX IF NOT EXISTS idx_promo_code_usage_used_at ON promo_code_usage(used_at);

-- 新增註解
COMMENT ON TABLE promo_code_usage IS '優惠碼使用記錄';
COMMENT ON COLUMN promo_code_usage.influencer_id IS '網紅 ID（外鍵）';
COMMENT ON COLUMN promo_code_usage.booking_id IS '訂單 ID（外鍵）';
COMMENT ON COLUMN promo_code_usage.promo_code IS '使用的優惠碼';
COMMENT ON COLUMN promo_code_usage.original_price IS '原始價格';
COMMENT ON COLUMN promo_code_usage.discount_amount_applied IS '實際折扣金額';
COMMENT ON COLUMN promo_code_usage.discount_percentage_applied IS '實際折扣百分比';
COMMENT ON COLUMN promo_code_usage.final_price IS '最終價格';
COMMENT ON COLUMN promo_code_usage.used_at IS '使用時間';

-- ============================================================
-- 3. 修改 bookings 資料表（新增優惠碼欄位）
-- ============================================================

ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS promo_code TEXT,
ADD COLUMN IF NOT EXISTS influencer_id UUID REFERENCES influencers(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS promo_discount_amount NUMERIC(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS promo_discount_percentage NUMERIC(5,2) DEFAULT 0;

-- 建立索引
CREATE INDEX IF NOT EXISTS idx_bookings_promo_code ON bookings(promo_code);
CREATE INDEX IF NOT EXISTS idx_bookings_influencer_id ON bookings(influencer_id);

-- 新增註解
COMMENT ON COLUMN bookings.promo_code IS '使用的優惠碼';
COMMENT ON COLUMN bookings.influencer_id IS '網紅 ID（外鍵）';
COMMENT ON COLUMN bookings.promo_discount_amount IS '優惠碼折扣金額';
COMMENT ON COLUMN bookings.promo_discount_percentage IS '優惠碼折扣百分比';

-- ============================================================
-- 4. 設定 RLS (Row Level Security) 權限
-- ============================================================

-- 啟用 RLS
ALTER TABLE influencers ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_code_usage ENABLE ROW LEVEL SECURITY;

-- 公司端管理員：完整 CRUD 權限
CREATE POLICY "Admin full access to influencers" ON influencers
  FOR ALL
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admin full access to promo_code_usage" ON promo_code_usage
  FOR ALL
  USING (auth.role() = 'authenticated');

-- ============================================================
-- 5. 建立自動更新 updated_at 的觸發器
-- ============================================================

CREATE OR REPLACE FUNCTION update_influencers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_influencers_updated_at
  BEFORE UPDATE ON influencers
  FOR EACH ROW
  EXECUTE FUNCTION update_influencers_updated_at();

-- ============================================================
-- 6. 驗證資料表建立成功
-- ============================================================

-- 查詢 influencers 資料表結構
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'influencers'
ORDER BY ordinal_position;

-- 查詢 promo_code_usage 資料表結構
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'promo_code_usage'
ORDER BY ordinal_position;

