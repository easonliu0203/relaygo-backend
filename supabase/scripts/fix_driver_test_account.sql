-- 修復測試司機帳號
-- 確保 driver.test@gelaygo.com 能夠在司機列表中顯示

-- 開始事務
BEGIN;

-- 1. 確保用戶存在且角色為 driver
DO $$
DECLARE
  v_user_id UUID;
BEGIN
  -- 檢查用戶是否存在
  SELECT id INTO v_user_id
  FROM users
  WHERE email = 'driver.test@gelaygo.com';

  IF v_user_id IS NULL THEN
    RAISE NOTICE '❌ 用戶不存在: driver.test@gelaygo.com';
    RAISE EXCEPTION '用戶不存在，請先創建用戶';
  ELSE
    RAISE NOTICE '✅ 用戶存在: %', v_user_id;
    
    -- 確保角色為 driver
    UPDATE users
    SET role = 'driver'
    WHERE id = v_user_id AND role != 'driver';
    
    IF FOUND THEN
      RAISE NOTICE '✅ 已更新用戶角色為 driver';
    ELSE
      RAISE NOTICE '✅ 用戶角色已經是 driver';
    END IF;
  END IF;
END $$;

-- 2. 確保 user_profiles 資料存在
DO $$
DECLARE
  v_user_id UUID;
  v_profile_id UUID;
BEGIN
  -- 獲取用戶 ID
  SELECT id INTO v_user_id
  FROM users
  WHERE email = 'driver.test@gelaygo.com';

  -- 檢查 profile 是否存在
  SELECT id INTO v_profile_id
  FROM user_profiles
  WHERE user_id = v_user_id;

  IF v_profile_id IS NULL THEN
    -- 創建 profile
    INSERT INTO user_profiles (user_id, first_name, last_name, phone)
    VALUES (
      v_user_id,
      '測試',
      '司機',
      '0912345678'
    )
    RETURNING id INTO v_profile_id;
    
    RAISE NOTICE '✅ 已創建 user_profile: %', v_profile_id;
  ELSE
    -- 更新 profile（確保有姓名和電話）
    UPDATE user_profiles
    SET 
      first_name = COALESCE(NULLIF(first_name, ''), '測試'),
      last_name = COALESCE(NULLIF(last_name, ''), '司機'),
      phone = COALESCE(NULLIF(phone, ''), '0912345678')
    WHERE id = v_profile_id;
    
    RAISE NOTICE '✅ 已更新 user_profile: %', v_profile_id;
  END IF;
END $$;

-- 3. 確保 drivers 資料存在且可用
DO $$
DECLARE
  v_user_id UUID;
  v_driver_id UUID;
BEGIN
  -- 獲取用戶 ID
  SELECT id INTO v_user_id
  FROM users
  WHERE email = 'driver.test@gelaygo.com';

  -- 檢查 driver 是否存在
  SELECT id INTO v_driver_id
  FROM drivers
  WHERE user_id = v_user_id;

  IF v_driver_id IS NULL THEN
    -- 創建 driver 記錄
    INSERT INTO drivers (
      user_id,
      license_number,
      vehicle_type,
      vehicle_plate,
      vehicle_model,
      is_available,
      rating,
      total_trips
    )
    VALUES (
      v_user_id,
      'TEST-LICENSE-001',
      'A',  -- 豪華9人座
      'TEST-001',
      'Toyota Alphard',
      true,  -- 設為可用
      5.0,
      0
    )
    RETURNING id INTO v_driver_id;
    
    RAISE NOTICE '✅ 已創建 driver 記錄: %', v_driver_id;
  ELSE
    -- 更新 driver 記錄（確保可用且有車型）
    UPDATE drivers
    SET 
      license_number = COALESCE(NULLIF(license_number, ''), 'TEST-LICENSE-001'),
      vehicle_type = COALESCE(vehicle_type, 'A'),
      vehicle_plate = COALESCE(NULLIF(vehicle_plate, ''), 'TEST-001'),
      vehicle_model = COALESCE(NULLIF(vehicle_model, ''), 'Toyota Alphard'),
      is_available = true,  -- 強制設為可用
      rating = COALESCE(rating, 5.0),
      total_trips = COALESCE(total_trips, 0)
    WHERE id = v_driver_id;
    
    RAISE NOTICE '✅ 已更新 driver 記錄: %', v_driver_id;
  END IF;
END $$;

-- 4. 驗證修復結果
DO $$
DECLARE
  v_user_id UUID;
  v_role VARCHAR(20);
  v_has_profile BOOLEAN;
  v_has_driver BOOLEAN;
  v_is_available BOOLEAN;
  v_vehicle_type VARCHAR(10);
BEGIN
  -- 獲取用戶資訊
  SELECT id, role INTO v_user_id, v_role
  FROM users
  WHERE email = 'driver.test@gelaygo.com';

  -- 檢查 profile
  SELECT EXISTS(SELECT 1 FROM user_profiles WHERE user_id = v_user_id) INTO v_has_profile;

  -- 檢查 driver
  SELECT 
    EXISTS(SELECT 1 FROM drivers WHERE user_id = v_user_id),
    d.is_available,
    d.vehicle_type
  INTO v_has_driver, v_is_available, v_vehicle_type
  FROM drivers d
  WHERE d.user_id = v_user_id;

  RAISE NOTICE '=== 驗證結果 ===';
  RAISE NOTICE '用戶 ID: %', v_user_id;
  RAISE NOTICE '角色: %', v_role;
  RAISE NOTICE '有 Profile: %', v_has_profile;
  RAISE NOTICE '有 Driver: %', v_has_driver;
  RAISE NOTICE '可用狀態: %', v_is_available;
  RAISE NOTICE '車型: %', v_vehicle_type;

  -- 檢查是否全部正確
  IF v_role = 'driver' AND v_has_profile AND v_has_driver AND v_is_available AND v_vehicle_type IS NOT NULL THEN
    RAISE NOTICE '✅ 測試司機帳號已完全修復！';
  ELSE
    RAISE NOTICE '❌ 修復可能不完整，請檢查上述資訊';
  END IF;
END $$;

-- 提交事務
COMMIT;

-- 5. 顯示最終結果
SELECT 
  '=== 最終結果 ===' as step,
  u.id as user_id,
  u.email,
  u.role,
  up.first_name,
  up.last_name,
  up.phone,
  d.vehicle_type,
  d.vehicle_plate,
  d.vehicle_model,
  d.is_available,
  d.rating,
  d.total_trips
FROM users u
LEFT JOIN user_profiles up ON up.user_id = u.id
LEFT JOIN drivers d ON d.user_id = u.id
WHERE u.email = 'driver.test@gelaygo.com';

