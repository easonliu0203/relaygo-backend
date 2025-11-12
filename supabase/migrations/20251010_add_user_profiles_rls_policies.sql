-- 添加 user_profiles 表的 RLS 政策
-- 日期：2025-10-10
-- 問題：user_profiles 表缺少 RLS 政策，導致用戶無法更新自己的資料

-- ============================================
-- 第一部分: 啟用 RLS
-- ============================================

-- 啟用 user_profiles 表的 RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 第二部分: 創建 RLS 政策
-- ============================================

-- 政策 1: 用戶可以查看自己的資料
-- 使用 firebase_uid 進行匹配
CREATE POLICY "用戶可以查看自己的資料"
ON user_profiles
FOR SELECT
USING (
  user_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
);

-- 政策 2: 用戶可以插入自己的資料
-- 使用 firebase_uid 進行匹配
CREATE POLICY "用戶可以插入自己的資料"
ON user_profiles
FOR INSERT
WITH CHECK (
  user_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
);

-- 政策 3: 用戶可以更新自己的資料
-- 使用 firebase_uid 進行匹配
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
-- 使用 firebase_uid 進行匹配
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
-- 第三部分: 創建輔助函數
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

-- 添加註釋
COMMENT ON FUNCTION get_user_id_by_firebase_uid IS '根據 Firebase UID 獲取 Supabase user_id';

-- ============================================
-- 第四部分: 驗證 RLS 政策
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
  
  -- 輸出驗證結果
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RLS 政策驗證結果:';
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
END $$;

-- ============================================
-- 第五部分: 顯示所有政策
-- ============================================

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'user_profiles'
ORDER BY policyname;

