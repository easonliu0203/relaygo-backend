-- Migration: 添加 deleted_at 欄位到 users 表
-- Date: 2026-01-08
-- Purpose: 支援帳號刪除功能（邏輯刪除）

-- 添加 deleted_at 欄位
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- 添加註解
COMMENT ON COLUMN users.deleted_at IS '帳號刪除時間（邏輯刪除）';

-- 更新 status 欄位的 CHECK 約束，允許 'deleted' 狀態
-- 先刪除舊的約束（如果存在）
DO $$ 
BEGIN
    -- 查找並刪除 status 欄位的 CHECK 約束
    IF EXISTS (
        SELECT 1 
        FROM information_schema.constraint_column_usage 
        WHERE table_name = 'users' 
        AND column_name = 'status'
        AND constraint_name LIKE '%status%check%'
    ) THEN
        EXECUTE (
            SELECT 'ALTER TABLE users DROP CONSTRAINT ' || constraint_name || ';'
            FROM information_schema.constraint_column_usage
            WHERE table_name = 'users' 
            AND column_name = 'status'
            AND constraint_name LIKE '%status%check%'
            LIMIT 1
        );
    END IF;
END $$;

-- 添加新的 CHECK 約束，包含 'deleted' 狀態
ALTER TABLE users 
ADD CONSTRAINT users_status_check 
CHECK (status IN ('active', 'inactive', 'suspended', 'pending', 'deleted'));

-- 創建索引以提升查詢效能
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NOT NULL;

-- 驗證欄位已添加
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'deleted_at';

