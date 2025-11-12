-- 手動應用 user_profiles 和 drivers 表 Migration
-- 在 Supabase Dashboard SQL Editor 中執行此腳本
-- URL: https://app.supabase.com/project/YOUR_PROJECT_ID/sql

-- ============================================
-- 檢查當前狀態
-- ============================================

DO $$
DECLARE
    has_user_profiles BOOLEAN;
    has_drivers BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles'
    ) INTO has_user_profiles;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'drivers'
    ) INTO has_drivers;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '當前狀態檢查:';
    RAISE NOTICE '========================================';
    
    IF has_user_profiles THEN
        RAISE NOTICE '✅ user_profiles 表已存在';
    ELSE
        RAISE NOTICE '❌ user_profiles 表不存在（將創建）';
    END IF;
    
    IF has_drivers THEN
        RAISE NOTICE '✅ drivers 表已存在';
    ELSE
        RAISE NOTICE '❌ drivers 表不存在（將創建）';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 創建 user_profiles 表
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

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);

COMMENT ON TABLE user_profiles IS '用戶詳細資料表';
COMMENT ON COLUMN user_profiles.user_id IS '關聯到 users 表的 id';

-- ============================================
-- 創建 drivers 表
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

CREATE INDEX IF NOT EXISTS idx_drivers_user_id ON drivers(user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_vehicle_type ON drivers(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_drivers_is_available ON drivers(is_available);
CREATE INDEX IF NOT EXISTS idx_drivers_license_number ON drivers(license_number);
CREATE INDEX IF NOT EXISTS idx_drivers_vehicle_plate ON drivers(vehicle_plate);

COMMENT ON TABLE drivers IS '司機專用資料表';
COMMENT ON COLUMN drivers.user_id IS '關聯到 users 表的 id';
COMMENT ON COLUMN drivers.vehicle_type IS '車型: A(4人座), B(7人座), C(9人座), D(20人座)';

-- ============================================
-- 驗證創建結果
-- ============================================

DO $$
DECLARE
    has_user_profiles BOOLEAN;
    has_drivers BOOLEAN;
    user_profiles_count INTEGER;
    drivers_count INTEGER;
    users_count INTEGER;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles'
    ) INTO has_user_profiles;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'drivers'
    ) INTO has_drivers;
    
    SELECT COUNT(*) INTO users_count FROM users;
    
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
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '驗證結果:';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'users 表記錄數: %', users_count;
    
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
    RAISE NOTICE '下一步:';
    RAISE NOTICE '========================================';
    RAISE NOTICE '1. 如果 users 表有記錄但 user_profiles 為空:';
    RAISE NOTICE '   - 這是正常的，user_profiles 會在用戶更新資料時創建';
    RAISE NOTICE '2. 測試 API 查詢:';
    RAISE NOTICE '   - 訪問 http://localhost:3001/api/admin/bookings';
    RAISE NOTICE '   - 確認不再出現 PGRST200 錯誤';
    RAISE NOTICE '3. 測試訂單管理頁面:';
    RAISE NOTICE '   - 訪問 http://localhost:3001/orders';
    RAISE NOTICE '   - 確認訂單正常顯示';
    RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 測試關聯查詢
-- ============================================

-- 測試從 users 關聯到 user_profiles
SELECT 
    u.id,
    u.email,
    up.first_name,
    up.last_name,
    up.phone
FROM users u
LEFT JOIN user_profiles up ON up.user_id = u.id
LIMIT 5;

-- 測試從 users 關聯到 drivers
SELECT 
    u.id,
    u.email,
    d.vehicle_type,
    d.vehicle_plate
FROM users u
LEFT JOIN drivers d ON d.user_id = u.id
WHERE u.role = 'driver'
LIMIT 5;

