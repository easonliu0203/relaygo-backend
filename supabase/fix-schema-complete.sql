-- ============================================
-- 完整修復 Supabase Schema
-- 日期: 2025-10-08
-- 問題: 缺少 cancellation_reason, cancelled_at 欄位和 payments 表
-- ============================================

-- ============================================
-- 第一部分: 修復 bookings 表
-- ============================================

-- 1. 添加 cancellation_reason 欄位
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'cancellation_reason'
    ) THEN
        ALTER TABLE bookings ADD COLUMN cancellation_reason TEXT;
        RAISE NOTICE '✅ Added cancellation_reason column to bookings table';
    ELSE
        RAISE NOTICE 'ℹ️  cancellation_reason column already exists in bookings table';
    END IF;
END $$;

-- 2. 添加 cancelled_at 欄位
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'cancelled_at'
    ) THEN
        ALTER TABLE bookings ADD COLUMN cancelled_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Added cancelled_at column to bookings table';
    ELSE
        RAISE NOTICE 'ℹ️  cancelled_at column already exists in bookings table';
    END IF;
END $$;

-- 3. 添加註釋
COMMENT ON COLUMN bookings.cancellation_reason IS '取消訂單的原因（由客戶提供）';
COMMENT ON COLUMN bookings.cancelled_at IS '訂單取消的時間';

-- 4. 創建索引以提高查詢效能
CREATE INDEX IF NOT EXISTS idx_bookings_cancelled_at ON bookings(cancelled_at) WHERE cancelled_at IS NOT NULL;

-- ============================================
-- 第二部分: 創建 payments 表
-- ============================================

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id VARCHAR(100) UNIQUE NOT NULL,
  booking_id UUID REFERENCES bookings(id) NOT NULL,
  customer_id UUID REFERENCES users(id) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('deposit', 'balance', 'refund')),
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'TWD',
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending', 'processing', 'completed', 'failed', 'cancelled', 'expired', 'refunded'
  )),
  payment_provider VARCHAR(50) NOT NULL,
  payment_method VARCHAR(50),
  is_test_mode BOOLEAN DEFAULT false,
  external_transaction_id VARCHAR(255),
  payment_url TEXT,
  instructions TEXT,
  confirmed_by UUID REFERENCES users(id),
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

-- 創建 payments 表的索引
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON payments(transaction_id);

-- 添加註釋
COMMENT ON TABLE payments IS '支付記錄表';
COMMENT ON COLUMN payments.type IS '支付類型: deposit(訂金), balance(尾款), refund(退款)';
COMMENT ON COLUMN payments.status IS '支付狀態';
COMMENT ON COLUMN payments.is_test_mode IS '是否為測試模式';

-- ============================================
-- 第三部分: 驗證修復結果
-- ============================================

DO $$
DECLARE
    has_cancellation_reason BOOLEAN;
    has_cancelled_at BOOLEAN;
    has_payments_table BOOLEAN;
BEGIN
    -- 檢查 bookings 表的欄位
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'cancellation_reason'
    ) INTO has_cancellation_reason;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'cancelled_at'
    ) INTO has_cancelled_at;
    
    -- 檢查 payments 表
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'payments'
    ) INTO has_payments_table;
    
    -- 輸出驗證結果
    RAISE NOTICE '========================================';
    RAISE NOTICE '驗證結果:';
    RAISE NOTICE '========================================';
    
    IF has_cancellation_reason THEN
        RAISE NOTICE '✅ bookings.cancellation_reason 欄位存在';
    ELSE
        RAISE WARNING '❌ bookings.cancellation_reason 欄位缺失';
    END IF;
    
    IF has_cancelled_at THEN
        RAISE NOTICE '✅ bookings.cancelled_at 欄位存在';
    ELSE
        RAISE WARNING '❌ bookings.cancelled_at 欄位缺失';
    END IF;
    
    IF has_payments_table THEN
        RAISE NOTICE '✅ payments 表存在';
    ELSE
        RAISE WARNING '❌ payments 表缺失';
    END IF;
    
    IF has_cancellation_reason AND has_cancelled_at AND has_payments_table THEN
        RAISE NOTICE '========================================';
        RAISE NOTICE '🎉 所有修復已完成!';
        RAISE NOTICE '========================================';
    ELSE
        RAISE WARNING '========================================';
        RAISE WARNING '⚠️  部分修復失敗，請檢查錯誤訊息';
        RAISE WARNING '========================================';
    END IF;
END $$;

-- ============================================
-- 第四部分: 顯示表結構（用於驗證）
-- ============================================

-- 顯示 bookings 表的所有欄位
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'bookings'
ORDER BY ordinal_position;

-- 顯示 payments 表的所有欄位
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'payments'
ORDER BY ordinal_position;

