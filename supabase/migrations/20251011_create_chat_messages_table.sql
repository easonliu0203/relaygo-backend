-- 創建聊天訊息表
-- 修復日期：2025-10-11
-- 目的：實作客戶端與司機端即時聊天功能

-- ============================================
-- Step 1: 創建 chat_messages 表
-- ============================================

CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  receiver_id UUID NOT NULL,
  message_text TEXT NOT NULL,
  translated_text TEXT,  -- 翻譯後的文字（預留，之後串接 ChatGPT 4o mini）
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE,  -- 已讀時間
  
  -- 外鍵約束
  CONSTRAINT fk_booking FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  CONSTRAINT fk_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_receiver FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================
-- Step 2: 創建索引
-- ============================================

-- 按訂單 ID 查詢訊息
CREATE INDEX idx_chat_messages_booking_id ON chat_messages(booking_id);

-- 按創建時間排序
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);

-- 按發送者查詢
CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);

-- 按接收者查詢未讀訊息
CREATE INDEX idx_chat_messages_receiver_read ON chat_messages(receiver_id, read_at);

-- 複合索引：訂單 + 創建時間（用於分頁查詢）
CREATE INDEX idx_chat_messages_booking_created ON chat_messages(booking_id, created_at DESC);

-- ============================================
-- Step 3: 創建 RLS 策略
-- ============================================

-- 啟用 RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- 策略 1: 用戶可以查看自己發送或接收的訊息
CREATE POLICY "Users can view their own messages"
  ON chat_messages
  FOR SELECT
  USING (
    sender_id IN (
      SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
    )
    OR
    receiver_id IN (
      SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
    )
  );

-- 策略 2: 用戶可以插入訊息（發送者必須是自己）
CREATE POLICY "Users can send messages"
  ON chat_messages
  FOR INSERT
  WITH CHECK (
    sender_id IN (
      SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
    )
  );

-- 策略 3: 用戶可以更新自己接收的訊息（標記為已讀）
CREATE POLICY "Users can mark messages as read"
  ON chat_messages
  FOR UPDATE
  USING (
    receiver_id IN (
      SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
    )
  )
  WITH CHECK (
    receiver_id IN (
      SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
    )
  );

-- ============================================
-- Step 4: 創建 trigger 函數（同步到 Firestore）
-- ============================================

CREATE OR REPLACE FUNCTION chat_messages_to_outbox()
RETURNS TRIGGER AS $$
DECLARE
  sender_firebase_uid VARCHAR(128);
  receiver_firebase_uid VARCHAR(128);
  sender_name VARCHAR(200);
  receiver_name VARCHAR(200);
  booking_data JSONB;
BEGIN
  -- 獲取發送者資訊
  SELECT 
    u.firebase_uid,
    TRIM(CONCAT(up.first_name, ' ', up.last_name))
  INTO 
    sender_firebase_uid,
    sender_name
  FROM users u
  LEFT JOIN user_profiles up ON u.id = up.user_id
  WHERE u.id = NEW.sender_id;

  -- 獲取接收者資訊
  SELECT 
    u.firebase_uid,
    TRIM(CONCAT(up.first_name, ' ', up.last_name))
  INTO 
    receiver_firebase_uid,
    receiver_name
  FROM users u
  LEFT JOIN user_profiles up ON u.id = up.user_id
  WHERE u.id = NEW.receiver_id;

  -- 獲取訂單資訊
  SELECT jsonb_build_object(
    'bookingId', b.id::TEXT,
    'customerId', (SELECT firebase_uid FROM users WHERE id = b.customer_id),
    'driverId', (SELECT firebase_uid FROM users WHERE id = b.driver_id),
    'customerName', (
      SELECT TRIM(CONCAT(up.first_name, ' ', up.last_name))
      FROM user_profiles up
      WHERE up.user_id = b.customer_id
    ),
    'driverName', (
      SELECT TRIM(CONCAT(up.first_name, ' ', up.last_name))
      FROM user_profiles up
      WHERE up.user_id = b.driver_id
    ),
    'pickupAddress', b.pickup_location,
    'bookingTime', b.start_date || 'T' || b.start_time
  )
  INTO booking_data
  FROM bookings b
  WHERE b.id = NEW.booking_id;

  -- 插入 outbox 事件
  INSERT INTO outbox (
    aggregate_type,
    aggregate_id,
    event_type,
    payload
  ) VALUES (
    'chat_message',
    NEW.id::TEXT,
    CASE
      WHEN TG_OP = 'INSERT' THEN 'created'
      WHEN TG_OP = 'UPDATE' THEN 'updated'
      WHEN TG_OP = 'DELETE' THEN 'deleted'
    END,
    jsonb_build_object(
      'id', NEW.id::TEXT,
      'bookingId', NEW.booking_id::TEXT,
      'senderId', sender_firebase_uid,
      'receiverId', receiver_firebase_uid,
      'senderName', sender_name,
      'receiverName', receiver_name,
      'messageText', NEW.message_text,
      'translatedText', NEW.translated_text,
      'createdAt', NEW.created_at,
      'readAt', NEW.read_at,
      'bookingData', booking_data
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Step 5: 創建 trigger
-- ============================================

DROP TRIGGER IF EXISTS chat_messages_outbox_trigger ON chat_messages;

CREATE TRIGGER chat_messages_outbox_trigger
AFTER INSERT OR UPDATE ON chat_messages
FOR EACH ROW
EXECUTE FUNCTION chat_messages_to_outbox();

-- ============================================
-- Step 6: 驗證
-- ============================================

SELECT 
  'Chat messages table created successfully!' as message,
  COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'chat_messages';

SELECT 
  'Trigger created successfully!' as message,
  COUNT(*) as trigger_count
FROM information_schema.triggers 
WHERE trigger_name = 'chat_messages_outbox_trigger';

