-- 診斷 user_profiles 保存失敗問題
-- 執行此腳本在 Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/sql

-- ============================================
-- 第一部分: 檢查 RLS 狀態
-- ============================================

DO $$
DECLARE
  rls_enabled BOOLEAN;
  policy_count INTEGER;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '第一部分: 檢查 RLS 狀態';
  RAISE NOTICE '========================================';
  
  -- 檢查 RLS 是否啟用
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'user_profiles';
  
  -- 檢查政策數量
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'user_profiles';
  
  IF rls_enabled THEN
    RAISE NOTICE '✅ RLS 已啟用';
  ELSE
    RAISE NOTICE '❌ RLS 未啟用';
  END IF;
  
  RAISE NOTICE '政策數量: %', policy_count;
  
  IF policy_count = 0 THEN
    RAISE NOTICE '❌ 沒有任何 RLS 政策！';
  ELSIF policy_count < 6 THEN
    RAISE NOTICE '⚠️ 政策數量不足（預期: 6，實際: %）', policy_count;
  ELSE
    RAISE NOTICE '✅ 政策數量正確';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

-- 顯示所有政策
SELECT 
  policyname AS "政策名稱",
  cmd AS "操作",
  CASE 
    WHEN permissive = 'PERMISSIVE' THEN '允許'
    ELSE '限制'
  END AS "類型"
FROM pg_policies
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- ============================================
-- 第二部分: 檢查測試帳號
-- ============================================

DO $$
DECLARE
  customer_exists BOOLEAN;
  driver_exists BOOLEAN;
  customer_uid TEXT;
  driver_uid TEXT;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '第二部分: 檢查測試帳號';
  RAISE NOTICE '========================================';
  
  -- 檢查客戶測試帳號
  SELECT EXISTS (
    SELECT 1 FROM users WHERE email = 'customer.test@relaygo.com'
  ) INTO customer_exists;
  
  -- 檢查司機測試帳號
  SELECT EXISTS (
    SELECT 1 FROM users WHERE email = 'driver.test@relaygo.com'
  ) INTO driver_exists;
  
  IF customer_exists THEN
    SELECT firebase_uid INTO customer_uid FROM users WHERE email = 'customer.test@relaygo.com';
    RAISE NOTICE '✅ 客戶測試帳號存在';
    RAISE NOTICE '   Firebase UID: %', customer_uid;
  ELSE
    RAISE NOTICE '❌ 客戶測試帳號不存在';
  END IF;
  
  IF driver_exists THEN
    SELECT firebase_uid INTO driver_uid FROM users WHERE email = 'driver.test@relaygo.com';
    RAISE NOTICE '✅ 司機測試帳號存在';
    RAISE NOTICE '   Firebase UID: %', driver_uid;
  ELSE
    RAISE NOTICE '❌ 司機測試帳號不存在';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

-- 顯示測試帳號詳情
SELECT 
  id,
  firebase_uid,
  email,
  role,
  status,
  created_at
FROM users
WHERE email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')
ORDER BY email;

-- ============================================
-- 第三部分: 檢查 user_profiles 記錄
-- ============================================

DO $$
DECLARE
  customer_profile_exists BOOLEAN;
  driver_profile_exists BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '第三部分: 檢查 user_profiles 記錄';
  RAISE NOTICE '========================================';
  
  -- 檢查客戶 profile
  SELECT EXISTS (
    SELECT 1 FROM user_profiles up
    JOIN users u ON up.user_id = u.id
    WHERE u.email = 'customer.test@relaygo.com'
  ) INTO customer_profile_exists;
  
  -- 檢查司機 profile
  SELECT EXISTS (
    SELECT 1 FROM user_profiles up
    JOIN users u ON up.user_id = u.id
    WHERE u.email = 'driver.test@relaygo.com'
  ) INTO driver_profile_exists;
  
  IF customer_profile_exists THEN
    RAISE NOTICE '✅ 客戶 profile 記錄存在';
  ELSE
    RAISE NOTICE '⚠️ 客戶 profile 記錄不存在（這是正常的，第一次保存時會創建）';
  END IF;
  
  IF driver_profile_exists THEN
    RAISE NOTICE '✅ 司機 profile 記錄存在';
  ELSE
    RAISE NOTICE '⚠️ 司機 profile 記錄不存在（這是正常的，第一次保存時會創建）';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

-- 顯示 user_profiles 記錄
SELECT 
  up.id,
  u.email,
  up.first_name,
  up.last_name,
  up.phone,
  up.created_at,
  up.updated_at
FROM user_profiles up
JOIN users u ON up.user_id = u.id
WHERE u.email IN ('customer.test@relaygo.com', 'driver.test@relaygo.com')
ORDER BY u.email;

-- ============================================
-- 第四部分: 測試 RLS 政策
-- ============================================

DO $$
DECLARE
  customer_user_id UUID;
  driver_user_id UUID;
  can_insert BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '第四部分: 測試 RLS 政策';
  RAISE NOTICE '========================================';
  
  -- 獲取測試帳號的 user_id
  SELECT id INTO customer_user_id FROM users WHERE email = 'customer.test@relaygo.com';
  SELECT id INTO driver_user_id FROM users WHERE email = 'driver.test@relaygo.com';
  
  IF customer_user_id IS NOT NULL THEN
    RAISE NOTICE '客戶 user_id: %', customer_user_id;
  END IF;
  
  IF driver_user_id IS NOT NULL THEN
    RAISE NOTICE '司機 user_id: %', driver_user_id;
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '注意: RLS 政策測試需要在應用中執行，因為需要 JWT 令牌';
  RAISE NOTICE '這裡只能檢查政策是否存在，無法測試實際權限';
  
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 第五部分: 檢查輔助函數
-- ============================================

DO $$
DECLARE
  function_exists BOOLEAN;
  customer_uid TEXT;
  customer_user_id UUID;
  test_result UUID;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '第五部分: 檢查輔助函數';
  RAISE NOTICE '========================================';
  
  -- 檢查函數是否存在
  SELECT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'get_user_id_by_firebase_uid'
  ) INTO function_exists;
  
  IF function_exists THEN
    RAISE NOTICE '✅ 輔助函數 get_user_id_by_firebase_uid 存在';
    
    -- 測試函數
    SELECT firebase_uid, id INTO customer_uid, customer_user_id 
    FROM users WHERE email = 'customer.test@relaygo.com';
    
    IF customer_uid IS NOT NULL THEN
      SELECT get_user_id_by_firebase_uid(customer_uid) INTO test_result;
      
      IF test_result = customer_user_id THEN
        RAISE NOTICE '✅ 函數測試通過';
        RAISE NOTICE '   輸入: %', customer_uid;
        RAISE NOTICE '   輸出: %', test_result;
      ELSE
        RAISE NOTICE '❌ 函數測試失敗';
        RAISE NOTICE '   預期: %', customer_user_id;
        RAISE NOTICE '   實際: %', test_result;
      END IF;
    END IF;
  ELSE
    RAISE NOTICE '❌ 輔助函數 get_user_id_by_firebase_uid 不存在';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 第六部分: 診斷總結
-- ============================================

DO $$
DECLARE
  rls_enabled BOOLEAN;
  policy_count INTEGER;
  customer_exists BOOLEAN;
  driver_exists BOOLEAN;
  function_exists BOOLEAN;
  all_ok BOOLEAN := TRUE;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '診斷總結';
  RAISE NOTICE '========================================';
  
  -- 檢查所有項目
  SELECT relrowsecurity INTO rls_enabled FROM pg_class WHERE relname = 'user_profiles';
  SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE tablename = 'user_profiles';
  SELECT EXISTS (SELECT 1 FROM users WHERE email = 'customer.test@relaygo.com') INTO customer_exists;
  SELECT EXISTS (SELECT 1 FROM users WHERE email = 'driver.test@relaygo.com') INTO driver_exists;
  SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_user_id_by_firebase_uid') INTO function_exists;
  
  -- RLS 檢查
  IF NOT rls_enabled THEN
    RAISE NOTICE '❌ 問題: RLS 未啟用';
    RAISE NOTICE '   解決方案: 執行 apply-user-profiles-rls.sql';
    all_ok := FALSE;
  END IF;
  
  IF policy_count < 6 THEN
    RAISE NOTICE '❌ 問題: RLS 政策不足（實際: %，預期: 6）', policy_count;
    RAISE NOTICE '   解決方案: 執行 apply-user-profiles-rls.sql';
    all_ok := FALSE;
  END IF;
  
  -- 測試帳號檢查
  IF NOT customer_exists THEN
    RAISE NOTICE '❌ 問題: 客戶測試帳號不存在';
    RAISE NOTICE '   解決方案: 執行 fix-test-accounts.js';
    all_ok := FALSE;
  END IF;
  
  IF NOT driver_exists THEN
    RAISE NOTICE '❌ 問題: 司機測試帳號不存在';
    RAISE NOTICE '   解決方案: 執行 fix-test-accounts.js';
    all_ok := FALSE;
  END IF;
  
  -- 函數檢查
  IF NOT function_exists THEN
    RAISE NOTICE '❌ 問題: 輔助函數不存在';
    RAISE NOTICE '   解決方案: 執行 apply-user-profiles-rls.sql';
    all_ok := FALSE;
  END IF;
  
  IF all_ok THEN
    RAISE NOTICE '✅ 所有檢查通過！';
    RAISE NOTICE '';
    RAISE NOTICE '如果仍然無法保存，請檢查：';
    RAISE NOTICE '1. Flutter 應用是否已重新編譯';
    RAISE NOTICE '2. 用戶是否已正確登入';
    RAISE NOTICE '3. 查看 Flutter 控制台的完整錯誤訊息';
  END IF;
  
  RAISE NOTICE '========================================';
END $$;

