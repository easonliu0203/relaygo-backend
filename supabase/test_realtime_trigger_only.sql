-- ============================================
-- 測試即時 Trigger 是否工作
-- ============================================
-- 
-- 功能：創建單個訂單，立即檢查 HTTP 請求
-- 目的：驗證 Trigger 是否在 1-3 秒內發送 HTTP 請求
-- 
-- ============================================

SELECT '
============================================
🧪 測試即時 Trigger
============================================
' AS "測試開始";

-- 記錄測試開始時間
DO $$
DECLARE
  test_start_time TIMESTAMP WITH TIME ZONE;
  test_booking_id UUID;
  test_customer_id UUID;
  test_booking_number VARCHAR(20);
BEGIN
  test_start_time := NOW();
  
  RAISE NOTICE '⏱️  測試開始時間: %', test_start_time;
  
  -- 獲取測試客戶
  SELECT id INTO test_customer_id
  FROM users
  WHERE role = 'customer'
  LIMIT 1;
  
  IF test_customer_id IS NULL THEN
    RAISE EXCEPTION '❌ 沒有可用的測試客戶';
  END IF;
  
  -- 生成訂單編號（縮短前綴以符合 VARCHAR(20) 限制）
  -- 'TRG_' (4 字符) + timestamp (10 字符) = 14 字符 < 20 ✓
  test_booking_number := 'TRG_' || EXTRACT(EPOCH FROM NOW())::BIGINT;
  
  -- 創建訂單
  INSERT INTO bookings (
    customer_id,
    booking_number,
    status,
    pickup_location,
    destination,
    start_date,
    start_time,
    duration_hours,
    vehicle_type,
    base_price,
    total_amount,
    deposit_amount
  ) VALUES (
    test_customer_id,
    test_booking_number,
    'pending_payment',
    '測試地點 A - Trigger 測試',
    '測試地點 B - Trigger 測試',
    CURRENT_DATE + INTERVAL '1 day',
    '14:00:00',
    8,
    'A',
    1500.00,
    1500.00,
    450.00
  ) RETURNING id INTO test_booking_id;
  
  RAISE NOTICE '✅ 訂單已創建';
  RAISE NOTICE '   訂單 ID: %', test_booking_id;
  RAISE NOTICE '   訂單編號: %', test_booking_number;
  RAISE NOTICE '   創建時間: %', NOW();
END $$;

-- 等待 3 秒
SELECT '⏳ 等待 3 秒...' AS "等待";
SELECT pg_sleep(3);

-- 檢查 HTTP 請求記錄
SELECT '
============================================
📊 檢查 HTTP 請求記錄
============================================
' AS "檢查開始";

SELECT 
  id,
  created AS "請求時間",
  status_code AS "狀態碼",
  EXTRACT(EPOCH FROM (created - (
    SELECT created_at 
    FROM bookings 
    WHERE pickup_location LIKE '%Trigger 測試%' 
    ORDER BY created_at DESC 
    LIMIT 1
  ))) AS "延遲（秒）",
  CASE
    WHEN status_code = 200 THEN '✅ 成功'
    WHEN status_code IS NULL THEN '⏳ 處理中'
    ELSE '❌ 失敗'
  END AS "狀態"
FROM net._http_response
WHERE created >= NOW() - INTERVAL '1 minute'
ORDER BY created DESC
LIMIT 5;

-- 檢查 outbox 事件
SELECT '
============================================
📊 檢查 Outbox 事件
============================================
' AS "檢查開始";

SELECT 
  id,
  event_type AS "事件類型",
  created_at AS "創建時間",
  processed_at AS "處理時間",
  EXTRACT(EPOCH FROM (processed_at - created_at)) AS "延遲（秒）",
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已處理'
    ELSE '⏳ 待處理'
  END AS "狀態"
FROM outbox
WHERE created_at >= NOW() - INTERVAL '1 minute'
ORDER BY created_at DESC
LIMIT 5;

-- 分析結果
SELECT '
============================================
📊 測試結果分析
============================================

如果延遲 < 3 秒：
  ✅ 即時 Trigger 正常工作
  ✅ pg_net HTTP 請求成功發送
  ✅ Edge Function 成功處理

如果延遲 > 10 秒：
  ⚠️ 即時 Trigger 可能未觸發
  ⚠️ 可能是 Cron Job 在處理
  ⚠️ 需要檢查 Trigger 配置

如果沒有 HTTP 請求記錄：
  ❌ Trigger 未觸發
  ❌ 需要檢查 Trigger 是否啟用
  ❌ 需要檢查 Edge Function URL

============================================
' AS "分析";

-- 清理測試數據
SELECT '
============================================
🧹 清理測試數據
============================================
' AS "清理開始";

DELETE FROM bookings
WHERE pickup_location LIKE '%Trigger 測試%';

SELECT '✅ 測試數據已清理' AS "清理完成";

