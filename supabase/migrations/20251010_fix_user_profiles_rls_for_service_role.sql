-- 修復 user_profiles RLS 政策 - 只允許 service_role 訪問
-- 日期: 2025-10-10
-- 目的: 保留 RLS 安全機制，但只允許後端 API（使用 service_role key）訪問
-- 架構: 客戶端 → 中台 API (驗證 Firebase Token) → Supabase (service_role)

-- ============================================
-- 清理現有政策
-- ============================================

-- 刪除所有現有的 RLS 政策
DROP POLICY IF EXISTS "用戶可以查看自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "用戶可以插入自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "用戶可以更新自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "用戶可以刪除自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "管理員可以查看所有資料" ON user_profiles;
DROP POLICY IF EXISTS "管理員可以修改所有資料" ON user_profiles;
DROP POLICY IF EXISTS "允許所有查詢" ON user_profiles;
DROP POLICY IF EXISTS "允許所有插入" ON user_profiles;
DROP POLICY IF EXISTS "允許所有更新" ON user_profiles;
DROP POLICY IF EXISTS "允許所有刪除" ON user_profiles;
DROP POLICY IF EXISTS "service_role_all_access" ON user_profiles;

-- ============================================
-- 啟用 RLS
-- ============================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 創建 service_role 專用政策
-- ============================================

-- 政策：只允許 service_role 完全訪問
-- 說明：
-- - service_role 是 Supabase 的特殊角色，擁有繞過 RLS 的權限
-- - 但我們仍然創建明確的政策以提高安全性和可維護性
-- - 客戶端使用 anon key 將無法直接訪問此表
-- - 所有訪問必須通過中台 API（使用 service_role key）

CREATE POLICY "service_role_full_access"
ON user_profiles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================
-- 驗證配置
-- ============================================

DO $$
DECLARE
  rls_enabled BOOLEAN;
  policy_count INTEGER;
  service_role_policy_exists BOOLEAN;
BEGIN
  -- 檢查 RLS 是否啟用
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'user_profiles';
  
  -- 檢查政策數量
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'user_profiles';
  
  -- 檢查 service_role 政策是否存在
  SELECT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'user_profiles' 
    AND policyname = 'service_role_full_access'
  ) INTO service_role_policy_exists;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '配置驗證結果';
  RAISE NOTICE '========================================';
  
  IF rls_enabled THEN
    RAISE NOTICE '✅ RLS 已啟用';
  ELSE
    RAISE NOTICE '❌ RLS 未啟用';
    RAISE EXCEPTION 'RLS 必須啟用';
  END IF;
  
  RAISE NOTICE '政策數量: %', policy_count;
  
  IF service_role_policy_exists THEN
    RAISE NOTICE '✅ service_role 政策已創建';
  ELSE
    RAISE NOTICE '❌ service_role 政策不存在';
    RAISE EXCEPTION 'service_role 政策必須存在';
  END IF;
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '配置說明';
  RAISE NOTICE '========================================';
  RAISE NOTICE '- RLS 已啟用，保護資料安全';
  RAISE NOTICE '- 只有 service_role 可以訪問';
  RAISE NOTICE '- 客戶端（anon key）無法直接訪問';
  RAISE NOTICE '- 所有操作必須通過中台 API';
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 顯示所有政策
-- ============================================

SELECT 
  schemaname AS "Schema",
  tablename AS "表名",
  policyname AS "政策名稱",
  permissive AS "類型",
  roles AS "角色",
  cmd AS "操作",
  qual AS "USING 條件",
  with_check AS "WITH CHECK 條件"
FROM pg_policies
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- ============================================
-- 測試說明
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '測試說明';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE '1. 使用 anon key 測試（應該失敗）:';
  RAISE NOTICE '   - 在客戶端嘗試直接訪問 user_profiles';
  RAISE NOTICE '   - 預期結果: permission denied';
  RAISE NOTICE '';
  RAISE NOTICE '2. 使用 service_role key 測試（應該成功）:';
  RAISE NOTICE '   - 在後端 API 中使用 service_role key';
  RAISE NOTICE '   - 預期結果: 可以正常讀寫';
  RAISE NOTICE '';
  RAISE NOTICE '3. 通過中台 API 測試（應該成功）:';
  RAISE NOTICE '   - 客戶端調用 /api/profile/upsert';
  RAISE NOTICE '   - API 驗證 Firebase Token';
  RAISE NOTICE '   - API 使用 service_role key 訪問 Supabase';
  RAISE NOTICE '   - 預期結果: 可以正常保存';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 安全檢查
-- ============================================

DO $$
DECLARE
  anon_can_select BOOLEAN;
  anon_can_insert BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '安全檢查';
  RAISE NOTICE '========================================';
  
  -- 檢查 anon 角色是否有權限
  -- 注意：這個檢查在 SQL 層面無法完全模擬，需要在應用層測試
  
  RAISE NOTICE '';
  RAISE NOTICE '⚠️ 重要安全提醒:';
  RAISE NOTICE '- 確保客戶端只使用 anon key';
  RAISE NOTICE '- 確保 service_role key 只存在於後端';
  RAISE NOTICE '- 確保 service_role key 不會暴露給客戶端';
  RAISE NOTICE '- 確保中台 API 驗證 Firebase Token';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
END $$;

