-- 添加取消訂單相關欄位
-- 用於記錄訂單取消的原因和時間

-- 添加取消原因欄位
ALTER TABLE bookings
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;

-- 添加取消時間欄位
ALTER TABLE bookings
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;

-- 添加註釋
COMMENT ON COLUMN bookings.cancellation_reason IS '取消訂單的原因（由客戶提供）';
COMMENT ON COLUMN bookings.cancelled_at IS '訂單取消的時間';

-- 創建索引以提高查詢效能
CREATE INDEX IF NOT EXISTS idx_bookings_cancelled_at ON bookings(cancelled_at) WHERE cancelled_at IS NOT NULL;

