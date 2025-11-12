-- 修復缺少的資料庫欄位和表
-- 日期：2025-10-08
-- 問題：bookings 表缺少 cancellation_reason 和 cancelled_at 欄位

-- 1. 檢查並添加 cancellation_reason 欄位
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'cancellation_reason'
    ) THEN
        ALTER TABLE bookings ADD COLUMN cancellation_reason TEXT;
        RAISE NOTICE 'Added cancellation_reason column to bookings table';
    ELSE
        RAISE NOTICE 'cancellation_reason column already exists in bookings table';
    END IF;
END $$;

-- 2. 檢查並添加 cancelled_at 欄位
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'cancelled_at'
    ) THEN
        ALTER TABLE bookings ADD COLUMN cancelled_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added cancelled_at column to bookings table';
    ELSE
        RAISE NOTICE 'cancelled_at column already exists in bookings table';
    END IF;
END $$;

-- 3. 添加註釋
COMMENT ON COLUMN bookings.cancellation_reason IS '取消訂單的原因（由客戶提供）';
COMMENT ON COLUMN bookings.cancelled_at IS '訂單取消的時間';

-- 4. 創建索引以提高查詢效能
CREATE INDEX IF NOT EXISTS idx_bookings_cancelled_at ON bookings(cancelled_at) WHERE cancelled_at IS NOT NULL;

-- 5. 驗證欄位已添加
DO $$
DECLARE
    has_cancellation_reason BOOLEAN;
    has_cancelled_at BOOLEAN;
BEGIN
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
    
    IF has_cancellation_reason AND has_cancelled_at THEN
        RAISE NOTICE '✅ All required columns exist in bookings table';
    ELSE
        RAISE WARNING '❌ Some columns are still missing!';
        IF NOT has_cancellation_reason THEN
            RAISE WARNING '  - cancellation_reason is missing';
        END IF;
        IF NOT has_cancelled_at THEN
            RAISE WARNING '  - cancelled_at is missing';
        END IF;
    END IF;
END $$;

