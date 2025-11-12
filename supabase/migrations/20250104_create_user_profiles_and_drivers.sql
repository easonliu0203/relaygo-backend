-- 創建 user_profiles 和 drivers 表
-- 日期：2025-10-09
-- 問題：缺少 user_profiles 和 drivers 表，導致 API 查詢失敗

-- ============================================
-- 第一部分: 創建 user_profiles 表
-- ============================================

CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    phone VARCHAR(20),
    avatar_url TEXT,
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    address TEXT,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);

-- 添加註釋
COMMENT ON TABLE user_profiles IS '用戶詳細資料表';
COMMENT ON COLUMN user_profiles.user_id IS '關聯到 users 表的 id';
COMMENT ON COLUMN user_profiles.first_name IS '名字';
COMMENT ON COLUMN user_profiles.last_name IS '姓氏';
COMMENT ON COLUMN user_profiles.phone IS '電話號碼（可能與 users.phone 不同）';

-- ============================================
-- 第二部分: 創建 drivers 表
-- ============================================

CREATE TABLE IF NOT EXISTS drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    license_expiry DATE NOT NULL,
    vehicle_type VARCHAR(10) NOT NULL CHECK (vehicle_type IN ('A', 'B', 'C', 'D')),
    vehicle_model VARCHAR(100),
    vehicle_year INTEGER,
    vehicle_plate VARCHAR(20) UNIQUE NOT NULL,
    insurance_number VARCHAR(50),
    insurance_expiry DATE,
    background_check_status VARCHAR(20) DEFAULT 'pending' CHECK (background_check_status IN ('pending', 'approved', 'rejected')),
    background_check_date DATE,
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_trips INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT false,
    languages TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_drivers_user_id ON drivers(user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_vehicle_type ON drivers(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_drivers_is_available ON drivers(is_available);
CREATE INDEX IF NOT EXISTS idx_drivers_license_number ON drivers(license_number);
CREATE INDEX IF NOT EXISTS idx_drivers_vehicle_plate ON drivers(vehicle_plate);

-- 添加註釋
COMMENT ON TABLE drivers IS '司機專用資料表';
COMMENT ON COLUMN drivers.user_id IS '關聯到 users 表的 id';
COMMENT ON COLUMN drivers.vehicle_type IS '車型: A(4人座), B(7人座), C(9人座), D(20人座)';
COMMENT ON COLUMN drivers.is_available IS '是否可接單';
COMMENT ON COLUMN drivers.languages IS '支援的語言列表';

-- ============================================
-- 第三部分: 驗證創建結果
-- ============================================

DO $$
DECLARE
    has_user_profiles BOOLEAN;
    has_drivers BOOLEAN;
    user_profiles_count INTEGER;
    drivers_count INTEGER;
BEGIN
    -- 檢查 user_profiles 表是否存在
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles'
    ) INTO has_user_profiles;
    
    -- 檢查 drivers 表是否存在
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'drivers'
    ) INTO has_drivers;
    
    -- 獲取記錄數量
    IF has_user_profiles THEN
        SELECT COUNT(*) INTO user_profiles_count FROM user_profiles;
    ELSE
        user_profiles_count := 0;
    END IF;
    
    IF has_drivers THEN
        SELECT COUNT(*) INTO drivers_count FROM drivers;
    ELSE
        drivers_count := 0;
    END IF;
    
    -- 輸出驗證結果
    RAISE NOTICE '========================================';
    RAISE NOTICE '驗證結果:';
    RAISE NOTICE '========================================';
    
    IF has_user_profiles THEN
        RAISE NOTICE '✅ user_profiles 表已創建 (記錄數: %)', user_profiles_count;
    ELSE
        RAISE NOTICE '❌ user_profiles 表創建失敗';
    END IF;
    
    IF has_drivers THEN
        RAISE NOTICE '✅ drivers 表已創建 (記錄數: %)', drivers_count;
    ELSE
        RAISE NOTICE '❌ drivers 表創建失敗';
    END IF;
    
    RAISE NOTICE '========================================';
    
    -- 如果任何表創建失敗，拋出錯誤
    IF NOT has_user_profiles OR NOT has_drivers THEN
        RAISE EXCEPTION '表創建失敗，請檢查錯誤訊息';
    END IF;
END $$;

