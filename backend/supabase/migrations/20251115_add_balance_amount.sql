-- 添加 balance_amount 欄位到 bookings 表
-- 用於儲存尾款金額（包含超時費用）

ALTER TABLE bookings
ADD COLUMN IF NOT EXISTS balance_amount DECIMAL(10,2);

-- 為現有訂單計算並設置 balance_amount
-- balance_amount = total_amount - deposit_amount + overtime_fee
UPDATE bookings
SET balance_amount = total_amount - deposit_amount + COALESCE(overtime_fee, 0)
WHERE balance_amount IS NULL;

-- 添加註釋
COMMENT ON COLUMN bookings.balance_amount IS '尾款金額（包含超時費用）';

