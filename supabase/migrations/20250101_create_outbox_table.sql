-- 創建 outbox 表用於事件佇列（Outbox Pattern）
-- 用於將 Supabase 的訂單變更推送到 Firestore

CREATE TABLE IF NOT EXISTS outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_type VARCHAR(50) NOT NULL,  -- 聚合類型（例如：'order'）
  aggregate_id VARCHAR(255) NOT NULL,   -- 聚合 ID（例如：訂單 ID）
  event_type VARCHAR(50) NOT NULL,      -- 事件類型（'created', 'updated', 'deleted'）
  payload JSONB NOT NULL,                -- 事件資料（JSON 格式）
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,  -- 處理時間（NULL 表示未處理）
  retry_count INTEGER DEFAULT 0,         -- 重試次數
  error_message TEXT                     -- 錯誤訊息
);

-- 創建索引以提高查詢效能
CREATE INDEX idx_outbox_processed ON outbox(processed_at) WHERE processed_at IS NULL;
CREATE INDEX idx_outbox_created_at ON outbox(created_at);
CREATE INDEX idx_outbox_aggregate ON outbox(aggregate_type, aggregate_id);

-- 創建 trigger function 監聽 bookings 表變更
CREATE OR REPLACE FUNCTION bookings_to_outbox()
RETURNS TRIGGER AS $$
BEGIN
  -- 只鏡像前端需要即時展示的欄位
  INSERT INTO outbox (
    aggregate_type,
    aggregate_id,
    event_type,
    payload
  ) VALUES (
    'booking',
    NEW.id::TEXT,
    CASE
      WHEN TG_OP = 'INSERT' THEN 'created'
      WHEN TG_OP = 'UPDATE' THEN 'updated'
      WHEN TG_OP = 'DELETE' THEN 'deleted'
    END,
    jsonb_build_object(
      'id', NEW.id,
      'bookingNumber', NEW.booking_number,
      'customerId', (SELECT firebase_uid FROM users WHERE id = NEW.customer_id),
      'status', NEW.status,
      'pickupAddress', NEW.pickup_location,
      'destination', NEW.destination,
      'startDate', NEW.start_date,
      'startTime', NEW.start_time,
      'durationHours', NEW.duration_hours,
      'vehicleType', NEW.vehicle_type,
      'specialRequirements', NEW.special_requirements,
      'requiresForeignLanguage', NEW.requires_foreign_language,
      'basePrice', NEW.base_price,
      'foreignLanguageSurcharge', NEW.foreign_language_surcharge,
      'overtimeFee', NEW.overtime_fee,
      'tipAmount', NEW.tip_amount,
      'totalAmount', NEW.total_amount,
      'depositAmount', NEW.deposit_amount,
      'createdAt', NEW.created_at,
      'updatedAt', NEW.updated_at,
      'pickupLocation', jsonb_build_object(
        'latitude', NEW.pickup_latitude,
        'longitude', NEW.pickup_longitude
      ),
      -- 司機資訊（如果已配對）
      'driverId', CASE
        WHEN NEW.driver_id IS NOT NULL
        THEN (SELECT firebase_uid FROM users WHERE id = NEW.driver_id)
        ELSE NULL
      END,
      -- 時間記錄
      'actualStartTime', NEW.actual_start_time,
      'actualEndTime', NEW.actual_end_time
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 創建 trigger 監聽 bookings 表的 INSERT 和 UPDATE
CREATE TRIGGER bookings_outbox_trigger
AFTER INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION bookings_to_outbox();

-- 創建清理舊事件的函數（保留最近 7 天的已處理事件）
CREATE OR REPLACE FUNCTION cleanup_old_outbox_events()
RETURNS void AS $$
BEGIN
  DELETE FROM outbox
  WHERE processed_at IS NOT NULL
    AND processed_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- 註解說明
COMMENT ON TABLE outbox IS 'Outbox Pattern 事件佇列，用於將 Supabase 預約訂單變更推送到 Firestore';
COMMENT ON COLUMN outbox.aggregate_type IS '聚合類型（例如：booking）';
COMMENT ON COLUMN outbox.aggregate_id IS '聚合 ID（例如：預約訂單 ID）';
COMMENT ON COLUMN outbox.event_type IS '事件類型（created, updated, deleted）';
COMMENT ON COLUMN outbox.payload IS '事件資料（只包含前端需要即時展示的欄位）';
COMMENT ON COLUMN outbox.processed_at IS '處理時間（NULL 表示未處理）';
COMMENT ON COLUMN outbox.retry_count IS '重試次數';
COMMENT ON COLUMN outbox.error_message IS '錯誤訊息';

