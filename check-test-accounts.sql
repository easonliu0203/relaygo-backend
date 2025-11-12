-- 檢查測試帳號是否存在於 Supabase
-- 執行此腳本在 Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/sql

-- ============================================
-- 檢查 users 表中的測試帳號
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '檢查測試帳號';
  RAISE NOTICE '========================================';
END $$;

-- 查詢所有測試帳號
SELECT 
  id,
  firebase_uid,
  email,
  phone,
  role,
  status,
  created_at,
  updated_at
FROM users
WHERE email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')
ORDER BY email;

-- 統計結果
DO $$
DECLARE
  customer_exists BOOLEAN;
  driver_exists BOOLEAN;
  customer_uid TEXT;
  driver_uid TEXT;
  customer_role TEXT;
  driver_role TEXT;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '診斷結果';
  RAISE NOTICE '========================================';
  
  -- 檢查客戶測試帳號
  SELECT EXISTS (
    SELECT 1 FROM users WHERE email = 'customer.test@relaygo.com'
  ) INTO customer_exists;
  
  IF customer_exists THEN
    SELECT firebase_uid, role INTO customer_uid, customer_role
    FROM users WHERE email = 'customer.test@relaygo.com';
    
    RAISE NOTICE '✅ 客戶測試帳號存在';
    RAISE NOTICE '   Email: customer.test@relaygo.com';
    RAISE NOTICE '   Firebase UID: %', customer_uid;
    RAISE NOTICE '   Role: %', customer_role;
    
    IF customer_role != 'customer' THEN
      RAISE NOTICE '   ⚠️ 警告: Role 不正確（應該是 customer）';
    END IF;
  ELSE
    RAISE NOTICE '❌ 客戶測試帳號不存在';
  END IF;
  
  RAISE NOTICE '';
  
  -- 檢查司機測試帳號
  SELECT EXISTS (
    SELECT 1 FROM users WHERE email = 'driver.test@relaygo.com'
  ) INTO driver_exists;
  
  IF driver_exists THEN
    SELECT firebase_uid, role INTO driver_uid, driver_role
    FROM users WHERE email = 'driver.test@relaygo.com';
    
    RAISE NOTICE '✅ 司機測試帳號存在';
    RAISE NOTICE '   Email: driver.test@relaygo.com';
    RAISE NOTICE '   Firebase UID: %', driver_uid;
    RAISE NOTICE '   Role: %', driver_role;
    
    IF driver_role != 'driver' THEN
      RAISE NOTICE '   ⚠️ 警告: Role 不正確（應該是 driver）';
    END IF;
  ELSE
    RAISE NOTICE '❌ 司機測試帳號不存在';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  
  -- 提供修復建議
  IF NOT customer_exists OR NOT driver_exists THEN
    RAISE NOTICE '修復建議:';
    RAISE NOTICE '1. 執行 fix-test-accounts.js 腳本';
    RAISE NOTICE '2. 或手動創建測試帳號';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 檢查 user_profiles 表
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '檢查 user_profiles 表';
  RAISE NOTICE '========================================';
END $$;

SELECT 
  up.id,
  u.email,
  up.first_name,
  up.last_name,
  up.phone,
  up.created_at
FROM user_profiles up
JOIN users u ON up.user_id = u.id
WHERE u.email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')
ORDER BY u.email;

-- ============================================
-- 檢查所有用戶（用於對比）
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '所有用戶列表（前 10 個）';
  RAISE NOTICE '========================================';
END $$;

SELECT 
  id,
  email,
  role,
  status,
  created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

