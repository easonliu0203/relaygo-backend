-- 應用 service_role RLS 政策到 user_profiles 表
-- 執行此腳本在 Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/sql

-- ============================================
-- 清理現有政策
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '步驟 1: 清理現有政策';
  RAISE NOTICE '========================================';
END $$;

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
DROP POLICY IF EXISTS "service_role_full_access" ON user_profiles;

DO $$
BEGIN
  RAISE NOTICE '✅ 已清理所有現有政策';
END $$;

-- ============================================
-- 啟用 RLS
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '步驟 2: 啟用 RLS';
  RAISE NOTICE '========================================';
END $$;

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  RAISE NOTICE '✅ RLS 已啟用';
END $$;

-- ============================================
-- 創建 service_role 專用政策
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '步驟 3: 創建 service_role 政策';
  RAISE NOTICE '========================================';
END $$;

CREATE POLICY "service_role_full_access"
ON user_profiles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

DO $$
BEGIN
  RAISE NOTICE '✅ service_role 政策已創建';
END $$;

-- ============================================
-- 驗證配置
-- ============================================

DO $$
DECLARE
  rls_enabled BOOLEAN;
  policy_count INTEGER;
  service_role_policy_exists BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '步驟 4: 驗證配置';
  RAISE NOTICE '========================================';
  
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
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '配置完成！';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE '安全說明:';
  RAISE NOTICE '- ✅ RLS 已啟用，保護資料安全';
  RAISE NOTICE '- ✅ 只有 service_role 可以訪問';
  RAISE NOTICE '- ✅ 客戶端（anon key）無法直接訪問';
  RAISE NOTICE '- ✅ 所有操作必須通過中台 API';
  RAISE NOTICE '';
  RAISE NOTICE '架構:';
  RAISE NOTICE '  客戶端/司機端 App (Firebase Auth)';
  RAISE NOTICE '      ↓ 發送 Firebase UID';
  RAISE NOTICE '  中台 API (Next.js)';
  RAISE NOTICE '      ↓ 使用 Service Role Key';
  RAISE NOTICE '  Supabase (RLS 啟用)';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 顯示所有政策
-- ============================================

SELECT 
  policyname AS "政策名稱",
  cmd AS "操作",
  CASE 
    WHEN permissive = 'PERMISSIVE' THEN '允許'
    ELSE '限制'
  END AS "類型",
  roles AS "角色"
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
  RAISE NOTICE '測試步驟';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE '1. 測試客戶端直接訪問（應該失敗）:';
  RAISE NOTICE '   - 在 Flutter 應用中嘗試直接訪問 user_profiles';
  RAISE NOTICE '   - 預期結果: permission denied';
  RAISE NOTICE '';
  RAISE NOTICE '2. 測試中台 API（應該成功）:';
  RAISE NOTICE '   - 啟動 web-admin: cd web-admin && npm run dev';
  RAISE NOTICE '   - 在 Flutter 應用中調用 /api/profile/upsert';
  RAISE NOTICE '   - 預期結果: 可以正常保存';
  RAISE NOTICE '';
  RAISE NOTICE '3. 驗證資料:';
  RAISE NOTICE '   - 在 Supabase Dashboard 中查看 user_profiles 表';
  RAISE NOTICE '   - 確認資料已正確保存';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
END $$;

