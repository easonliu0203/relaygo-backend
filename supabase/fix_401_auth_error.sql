-- ============================================
-- 修復 401 認證錯誤
-- ============================================
-- 
-- 問題：Database Trigger 調用 Edge Function 時返回 401 Unauthorized
-- 原因：無法獲取 service_role_key 環境變數
-- 解決：配置 app.settings.service_role_key
-- 
-- 執行日期：2025-10-16
-- 作者：AI Assistant
-- 
-- ============================================

-- 步驟 1：配置 Service Role Key
-- ============================================
-- 
-- 重要：請將 'YOUR_SERVICE_ROLE_KEY' 替換為您的實際 Service Role Key
-- 
-- 獲取方式：
-- 1. 前往 Supabase Dashboard
-- 2. Settings → API
-- 3. 複製 "service_role" key（secret）
-- 
-- ============================================

-- 設置 service_role_key
ALTER DATABASE postgres SET app.settings.service_role_key TO 'YOUR_SERVICE_ROLE_KEY';

-- 驗證設置
SELECT current_setting('app.settings.service_role_key', true) AS service_role_key_configured;

-- ============================================
-- 步驟 2：測試 Trigger 函數
-- ============================================

-- 創建測試訂單（如果需要）
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
    'TEST_AUTH_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    'pending_payment',
    CURRENT_DATE + INTERVAL '1 day',
    '10:00:00',
    8,
    'small',
    '測試地點 - 認證修復',
    25.0330,
    121.5654,
    '測試目的地 - 認證修復',
    1500.00,
    1500.00,
    450.00
  )
  RETURNING id INTO test_booking_id;

  RAISE NOTICE '✅ 測試訂單已創建: %', test_booking_id;
  
  -- 更新訂單狀態以觸發 Trigger
  UPDATE bookings
  SET status = 'paid_deposit',
      updated_at = NOW()
  WHERE id = test_booking_id;

  RAISE NOTICE '✅ 訂單狀態已更新，應該觸發即時同步';
END $$;

-- ============================================
-- 步驟 3：檢查 HTTP 請求記錄
-- ============================================

SELECT 
  '檢查最近的 HTTP 請求（應該看到 200 狀態碼）' AS message;

-- 查詢最近的 HTTP 請求
SELECT 
  id,
  status_code,
  content,
  created_at
FROM net._http_response
WHERE created_at > NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC
LIMIT 5;

-- ============================================
-- 步驟 4：檢查 Outbox 事件
-- ============================================

SELECT 
  '檢查最近的 Outbox 事件' AS message;

SELECT 
  id,
  aggregate_type,
  event_type,
  aggregate_id,
  processed_at,
  retry_count,
  created_at
FROM outbox
WHERE created_at > NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC
LIMIT 5;

-- ============================================
-- 完成
-- ============================================

SELECT '
✅ 修復腳本執行完成

下一步：
1. 檢查 HTTP 請求記錄，確認狀態碼為 200（不是 401）
2. 檢查 Outbox 事件，確認 processed_at 不為 NULL
3. 檢查 Firestore Console，確認數據已同步

如果仍然看到 401 錯誤：
1. 確認 service_role_key 已正確配置
2. 重新連接數據庫（斷開並重新連接）
3. 執行 SELECT current_setting(''app.settings.service_role_key'', true) 驗證

如果需要重新配置：
ALTER DATABASE postgres SET app.settings.service_role_key TO ''YOUR_NEW_KEY'';

' AS 完成訊息;

