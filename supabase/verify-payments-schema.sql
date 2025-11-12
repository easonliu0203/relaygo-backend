-- 驗證 payments 表的 schema
-- 用於確認欄位名稱和結構是否正確

-- ========================================
-- 檢查 payments 表的欄位
-- ========================================

SELECT 
  '📊 payments 表的欄位列表:' AS "說明";

SELECT 
  column_name AS "欄位名稱",
  data_type AS "資料類型",
  is_nullable AS "允許 NULL",
  column_default AS "預設值"
FROM information_schema.columns
WHERE table_name = 'payments'
ORDER BY ordinal_position;

-- ========================================
-- 檢查是否有 payment_type 欄位
-- ========================================

SELECT 
  '⚠️  檢查是否有 payment_type 欄位:' AS "說明";

SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_name = 'payments' 
      AND column_name = 'payment_type'
    ) THEN '❌ 發現 payment_type 欄位（不應該存在）'
    ELSE '✅ 沒有 payment_type 欄位（正確）'
  END AS "檢查結果";

-- ========================================
-- 檢查是否有 type 欄位
-- ========================================

SELECT 
  '✅ 檢查是否有 type 欄位:' AS "說明";

SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_name = 'payments' 
      AND column_name = 'type'
    ) THEN '✅ 發現 type 欄位（正確）'
    ELSE '❌ 沒有 type 欄位（錯誤）'
  END AS "檢查結果";

-- ========================================
-- 檢查 type 欄位的約束
-- ========================================

SELECT 
  '📋 type 欄位的約束:' AS "說明";

SELECT 
  constraint_name AS "約束名稱",
  constraint_type AS "約束類型"
FROM information_schema.table_constraints
WHERE table_name = 'payments'
AND constraint_name LIKE '%type%';

-- ========================================
-- 檢查必填欄位
-- ========================================

SELECT 
  '📋 必填欄位（NOT NULL）:' AS "說明";

SELECT 
  column_name AS "欄位名稱",
  data_type AS "資料類型"
FROM information_schema.columns
WHERE table_name = 'payments'
AND is_nullable = 'NO'
ORDER BY ordinal_position;

-- ========================================
-- 檢查現有的支付記錄
-- ========================================

SELECT 
  '📊 現有的支付記錄數量:' AS "說明";

SELECT 
  COUNT(*) AS "支付記錄數量"
FROM payments;

-- ========================================
-- 檢查最近的支付記錄（如果有）
-- ========================================

SELECT 
  '📋 最近的支付記錄（前 5 筆）:' AS "說明";

SELECT 
  id,
  transaction_id AS "交易 ID",
  booking_id AS "訂單 ID",
  type AS "支付類型",
  amount AS "金額",
  status AS "狀態",
  created_at AS "建立時間"
FROM payments
ORDER BY created_at DESC
LIMIT 5;

-- ========================================
-- 檢查特定訂單的支付記錄
-- ========================================

SELECT 
  '📋 訂單 5b340e07-b169-4003-b81a-c984641d4828 的支付記錄:' AS "說明";

SELECT 
  id,
  transaction_id AS "交易 ID",
  type AS "支付類型",
  amount AS "金額",
  status AS "狀態",
  payment_provider AS "支付提供者",
  payment_method AS "支付方式",
  created_at AS "建立時間"
FROM payments
WHERE booking_id = '5b340e07-b169-4003-b81a-c984641d4828'
ORDER BY created_at DESC;

-- ========================================
-- 建議
-- ========================================

SELECT 
  '💡 建議:' AS "說明",
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_name = 'payments' 
      AND column_name = 'type'
    ) THEN '✅ payments 表的 schema 正確，使用 type 欄位。
    
後端 API 代碼已修復:
- 第 98 行: .eq(''type'', ''deposit'')
- 第 133 行: type: ''deposit''

請重新啟動管理後台並測試支付訂金功能。'
    ELSE '❌ payments 表缺少 type 欄位！
    
請執行以下 SQL 修復 schema:

ALTER TABLE payments 
ADD COLUMN type VARCHAR(20) NOT NULL 
CHECK (type IN (''deposit'', ''balance'', ''refund''));

或者重新執行 supabase/fix-schema-complete.sql'
  END AS "建議內容";

