-- ============================================
-- 快速修復 401 錯誤
-- ============================================
-- 
-- 使用方法：
-- 1. 前往 Supabase Dashboard → Settings → API
-- 2. 複製 "service_role" key（點擊 Reveal 按鈕）
-- 3. 將下面的 'YOUR_SERVICE_ROLE_KEY' 替換為您的 key
-- 4. 在 Supabase SQL Editor 中執行整個腳本
-- 
-- ============================================

-- 步驟 1：配置 Service Role Key
-- ⚠️  請替換 'YOUR_SERVICE_ROLE_KEY' 為您的實際 key
ALTER DATABASE postgres SET app.settings.service_role_key TO 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

-- 步驟 2：驗證配置
SELECT 
  '✅ Service Role Key 已配置' AS message,
  LENGTH(current_setting('app.settings.service_role_key', true)) AS key_length,
  SUBSTRING(current_setting('app.settings.service_role_key', true), 1, 10) AS key_prefix;

-- 步驟 3：重要提示
SELECT '
⚠️  重要：請重新連接數據庫
1. 點擊 SQL Editor 右上角的 "Disconnect"
2. 然後點擊 "Connect" 重新連接
3. 或者直接刷新頁面

完成後，繼續執行下面的測試腳本。
' AS 提示;

-- ============================================
-- 以下是測試腳本（重新連接後執行）
-- ============================================

-- 步驟 4：創建測試訂單
DO $$
DECLARE
  test_booking_id UUID;
  test_customer_id UUID;
BEGIN
  -- 獲取測試客戶
  SELECT id INTO test_customer_id
  FROM users
  WHERE role = 'customer'
  LIMIT 1;

  IF test_customer_id IS NULL THEN
    RAISE NOTICE '⚠️  沒有找到測試客戶，請先創建客戶';
    RETURN;
  END IF;

  -- 創建測試訂單
  INSERT INTO bookings (
    customer_id,
    booking_number,
    status,
    start_date,
    start_time,
    duration_hours,
    vehicle_type,
    pickup_location,
    pickup_latitude,
    pickup_longitude,
    destination,
    base_price,
    total_amount,
    deposit_amount
  ) VALUES (
    test_customer_id,
    'QUICK_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    'pending_payment',
    CURRENT_DATE + INTERVAL '1 day',
    '10:00:00',
    8,
    'small',
    '測試地點 - 快速修復',
    25.0330,
    121.5654,
    '測試目的地',
    1500.00,
    1500.00,
    450.00
  )
  RETURNING id INTO test_booking_id;

  RAISE NOTICE '✅ 測試訂單已創建: %', test_booking_id;
  
  -- 等待 1 秒
  PERFORM pg_sleep(1);
  
  -- 更新訂單狀態以觸發 Trigger
  UPDATE bookings
  SET status = 'paid_deposit',
      updated_at = NOW()
  WHERE id = test_booking_id;

  RAISE NOTICE '✅ 訂單狀態已更新，應該觸發即時同步';
  
  -- 等待 2 秒讓 HTTP 請求完成
  PERFORM pg_sleep(2);
END $$;

-- 步驟 5：檢查結果
SELECT 
  '檢查 HTTP 請求記錄（應該看到 200 狀態碼）' AS message;

SELECT 
  id,
  status_code,
  CASE 
    WHEN status_code = 200 THEN '✅ 成功 - 修復完成！'
    WHEN status_code = 401 THEN '❌ 認證失敗 - 請檢查 Service Role Key'
    ELSE '⚠️  其他錯誤'
  END AS status,
  content,
  created_at
FROM net._http_response
WHERE created_at > NOW() - INTERVAL '1 minute'
ORDER BY created_at DESC
LIMIT 3;

-- 步驟 6：檢查 Outbox 事件
SELECT 
  '檢查 Outbox 事件（應該已處理）' AS message;

SELECT 
  id,
  aggregate_type,
  event_type,
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已處理'
    ELSE '⏳ 待處理'
  END AS status,
  processed_at,
  created_at
FROM outbox
WHERE created_at > NOW() - INTERVAL '1 minute'
ORDER BY created_at DESC
LIMIT 3;

-- 完成
SELECT '
============================================
✅ 快速修復完成
============================================

如果看到：
- HTTP 狀態碼 = 200 → ✅ 修復成功！
- HTTP 狀態碼 = 401 → ❌ 請檢查 Service Role Key 是否正確

下一步：
1. 前往 Firestore Console 檢查數據是否已同步
2. 執行完整的狀態流轉測試（test_status_flow.sql）
3. 在管理後台啟用「即時同步開關」

============================================
' AS 完成訊息;

