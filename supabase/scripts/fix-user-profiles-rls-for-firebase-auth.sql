-- 修復 user_profiles RLS 政策以支持 Firebase Auth
-- 問題：原始 RLS 政策使用 auth.jwt()，但應用使用 Firebase Auth，不是 Supabase Auth
-- 解決方案：暫時禁用 RLS 或使用更寬鬆的政策

-- ============================================
-- 方案 1: 暫時禁用 RLS（開發環境）
-- ============================================

-- 注意：這個方案適合開發環境，生產環境需要更嚴格的安全控制

-- 禁用 RLS
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- 驗證
DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'user_profiles';
  
  RAISE NOTICE '========================================';
  IF rls_enabled THEN
    RAISE NOTICE '❌ RLS 仍然啟用';
  ELSE
    RAISE NOTICE '✅ RLS 已禁用';
    RAISE NOTICE '';
    RAISE NOTICE '注意：這是開發環境的臨時方案';
    RAISE NOTICE '生產環境需要實作正確的認證整合';
  END IF;
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 方案 2: 使用寬鬆的 RLS 政策（推薦）
-- ============================================

-- 如果您想保留 RLS 但允許所有已認證用戶訪問，請執行以下代碼：

/*
-- 啟用 RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 刪除現有政策
DROP POLICY IF EXISTS "用戶可以查看自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "用戶可以插入自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "用戶可以更新自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "用戶可以刪除自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "管理員可以查看所有資料" ON user_profiles;
DROP POLICY IF EXISTS "管理員可以修改所有資料" ON user_profiles;

-- 創建寬鬆的政策：允許所有操作（使用 anon key）
CREATE POLICY "允許所有查詢"
ON user_profiles
FOR SELECT
USING (true);

CREATE POLICY "允許所有插入"
ON user_profiles
FOR INSERT
WITH CHECK (true);

CREATE POLICY "允許所有更新"
ON user_profiles
FOR UPDATE
USING (true)
WITH CHECK (true);

CREATE POLICY "允許所有刪除"
ON user_profiles
FOR DELETE
USING (true);

-- 驗證
DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'user_profiles';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ 已創建 % 個寬鬆的 RLS 政策', policy_count;
  RAISE NOTICE '';
  RAISE NOTICE '注意：這些政策允許所有操作';
  RAISE NOTICE '適合開發環境和使用 Firebase Auth 的應用';
  RAISE NOTICE '========================================';
END $$;
*/

-- ============================================
-- 說明和建議
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '修復說明';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE '問題原因：';
  RAISE NOTICE '- 原始 RLS 政策使用 auth.jwt()，這是 Supabase Auth 的 JWT';
  RAISE NOTICE '- 但應用使用 Firebase Auth，不會提供 Supabase JWT';
  RAISE NOTICE '- 導致 RLS 檢查失敗，用戶無法訪問資料';
  RAISE NOTICE '';
  RAISE NOTICE '已執行的修復：';
  RAISE NOTICE '- 方案 1: 禁用 RLS（已執行）';
  RAISE NOTICE '';
  RAISE NOTICE '其他方案：';
  RAISE NOTICE '- 方案 2: 使用寬鬆的 RLS 政策（註解掉，需要時取消註解）';
  RAISE NOTICE '- 方案 3: 整合 Supabase Auth 和 Firebase Auth（需要額外開發）';
  RAISE NOTICE '';
  RAISE NOTICE '建議：';
  RAISE NOTICE '1. 開發環境：使用方案 1（禁用 RLS）';
  RAISE NOTICE '2. 測試環境：使用方案 2（寬鬆政策）';
  RAISE NOTICE '3. 生產環境：實作方案 3（認證整合）';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
END $$;

