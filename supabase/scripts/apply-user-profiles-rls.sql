-- 應用 user_profiles 表的 RLS 政策
-- 執行此腳本在 Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/sql

-- ============================================
-- 檢查當前狀態
-- ============================================

DO $$
DECLARE
  rls_enabled BOOLEAN;
  policy_count INTEGER;
BEGIN
  -- 檢查 RLS 是否啟用
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'user_profiles';
  
  -- 檢查政策數量
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'user_profiles';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '當前狀態:';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RLS 啟用: %', rls_enabled;
  RAISE NOTICE '政策數量: %', policy_count;
  RAISE NOTICE '========================================';
END $$;

-- ============================================
-- 刪除現有政策（如果存在）
-- ============================================

DROP POLICY IF EXISTS "用戶可以查看自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "用戶可以插入自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "用戶可以更新自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "用戶可以刪除自己的資料" ON user_profiles;
DROP POLICY IF EXISTS "管理員可以查看所有資料" ON user_profiles;
DROP POLICY IF EXISTS "管理員可以修改所有資料" ON user_profiles;

-- ============================================
-- 啟用 RLS
-- ============================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 創建 RLS 政策
-- ============================================

-- 政策 1: 用戶可以查看自己的資料
CREATE POLICY "用戶可以查看自己的資料"
ON user_profiles
FOR SELECT
USING (
  user_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
);

-- 政策 2: 用戶可以插入自己的資料
CREATE POLICY "用戶可以插入自己的資料"
ON user_profiles
FOR INSERT
WITH CHECK (
  user_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
);

-- 政策 3: 用戶可以更新自己的資料
CREATE POLICY "用戶可以更新自己的資料"
ON user_profiles
FOR UPDATE
USING (
  user_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
)
WITH CHECK (
  user_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
);

-- 政策 4: 用戶可以刪除自己的資料
CREATE POLICY "用戶可以刪除自己的資料"
ON user_profiles
FOR DELETE
USING (
  user_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
);

-- 政策 5: 管理員可以查看所有資料
CREATE POLICY "管理員可以查看所有資料"
ON user_profiles
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE firebase_uid = auth.jwt() ->> 'sub' 
    AND role = 'admin'
  )
);

-- 政策 6: 管理員可以修改所有資料
CREATE POLICY "管理員可以修改所有資料"
ON user_profiles
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE firebase_uid = auth.jwt() ->> 'sub' 
    AND role = 'admin'
  )
);

-- ============================================
-- 創建輔助函數
-- ============================================

-- 函數：根據 Firebase UID 獲取 Supabase user_id
CREATE OR REPLACE FUNCTION get_user_id_by_firebase_uid(firebase_uid_param TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_id_result UUID;
BEGIN
  SELECT id INTO user_id_result
  FROM users
  WHERE firebase_uid = firebase_uid_param;
  
  RETURN user_id_result;
END;
$$;

COMMENT ON FUNCTION get_user_id_by_firebase_uid IS '根據 Firebase UID 獲取 Supabase user_id';

-- ============================================
-- 驗證結果
-- ============================================

DO $$
DECLARE
  rls_enabled BOOLEAN;
  policy_count INTEGER;
BEGIN
  -- 檢查 RLS 是否啟用
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'user_profiles';
  
  -- 檢查政策數量
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE tablename = 'user_profiles';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '應用結果:';
  RAISE NOTICE '========================================';
  
  IF rls_enabled THEN
    RAISE NOTICE '✅ user_profiles 表的 RLS 已啟用';
  ELSE
    RAISE NOTICE '❌ user_profiles 表的 RLS 未啟用';
  END IF;
  
  RAISE NOTICE '✅ 已創建 % 個 RLS 政策', policy_count;
  RAISE NOTICE '========================================';
  
  -- 如果 RLS 未啟用，拋出錯誤
  IF NOT rls_enabled THEN
    RAISE EXCEPTION 'RLS 啟用失敗，請檢查錯誤訊息';
  END IF;
  
  -- 如果政策數量不正確，發出警告
  IF policy_count < 6 THEN
    RAISE WARNING '政策數量少於預期（預期: 6，實際: %）', policy_count;
  END IF;
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
  END AS "類型"
FROM pg_policies
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- ============================================
-- 測試查詢（可選）
-- ============================================

-- 測試：查看當前用戶的資料
-- SELECT * FROM user_profiles WHERE user_id IN (
--   SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
-- );

