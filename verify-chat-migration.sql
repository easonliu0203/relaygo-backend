-- 驗證聊天訊息表和 trigger 是否成功創建
-- 執行此腳本以檢查 migration 是否成功

-- ============================================
-- Step 1: 檢查 chat_messages 表是否存在
-- ============================================

SELECT 
  'chat_messages 表' as check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_name = 'chat_messages'
    ) THEN '✅ 存在'
    ELSE '❌ 不存在'
  END as status;

-- ============================================
-- Step 2: 檢查表結構
-- ============================================

SELECT 
  'chat_messages 表結構' as check_item,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'chat_messages'
ORDER BY ordinal_position;

-- ============================================
-- Step 3: 檢查索引
-- ============================================

SELECT 
  'chat_messages 索引' as check_item,
  indexname as index_name,
  indexdef as index_definition
FROM pg_indexes
WHERE schemaname = 'public' 
  AND tablename = 'chat_messages'
ORDER BY indexname;

-- ============================================
-- Step 4: 檢查外鍵約束
-- ============================================

SELECT 
  'chat_messages 外鍵約束' as check_item,
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.chat_messages'::regclass
  AND contype = 'f'
ORDER BY conname;

-- ============================================
-- Step 5: 檢查 RLS 是否啟用
-- ============================================

SELECT 
  'RLS 狀態' as check_item,
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ 已啟用'
    ELSE '❌ 未啟用'
  END as status
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename = 'chat_messages';

-- ============================================
-- Step 6: 檢查 RLS 策略
-- ============================================

SELECT 
  'RLS 策略' as check_item,
  policyname as policy_name,
  cmd as command,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'chat_messages'
ORDER BY policyname;

-- ============================================
-- Step 7: 檢查 trigger 函數
-- ============================================

SELECT 
  'Trigger 函數' as check_item,
  proname as function_name,
  CASE 
    WHEN proname = 'chat_messages_to_outbox' THEN '✅ 存在'
    ELSE '❌ 不存在'
  END as status
FROM pg_proc
WHERE proname = 'chat_messages_to_outbox';

-- ============================================
-- Step 8: 檢查 trigger
-- ============================================

SELECT 
  'Trigger' as check_item,
  tgname as trigger_name,
  tgtype as trigger_type,
  proname as function_name,
  CASE 
    WHEN tgname = 'chat_messages_outbox_trigger' THEN '✅ 存在'
    ELSE '❌ 不存在'
  END as status
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'public.chat_messages'::regclass;

-- ============================================
-- Step 9: 總結
-- ============================================

SELECT 
  '========================================' as separator,
  '總結' as title,
  '========================================' as separator2;

SELECT 
  CASE 
    WHEN (
      SELECT COUNT(*) FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'chat_messages'
    ) = 1 
    AND (
      SELECT COUNT(*) FROM pg_indexes 
      WHERE schemaname = 'public' AND tablename = 'chat_messages'
    ) >= 5
    AND (
      SELECT COUNT(*) FROM pg_policies 
      WHERE schemaname = 'public' AND tablename = 'chat_messages'
    ) >= 3
    AND (
      SELECT COUNT(*) FROM pg_trigger 
      WHERE tgrelid = 'public.chat_messages'::regclass
    ) >= 1
    THEN '✅ Migration 成功！所有組件都已創建。'
    ELSE '❌ Migration 不完整，請檢查上述輸出。'
  END as migration_status;

