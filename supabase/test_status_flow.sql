-- ============================================
-- 測試完整的訂單狀態流轉
-- ============================================
-- 
-- 功能：測試從 pending_payment 到 completed 的完整流程
-- 執行方式：在 Supabase Dashboard SQL Editor 中執行此腳本
-- 
-- ============================================

SELECT '
============================================
🧪 測試訂單狀態流轉
============================================
' AS "測試開始";

-- ============================================
-- 步驟 1: 創建測試訂單（pending_payment）
-- ============================================
SELECT '=== 步驟 1: 創建測試訂單 ===' AS "測試步驟";

DO $$
DECLARE
  test_booking_id UUID;
  test_customer_id UUID;
  test_booking_number VARCHAR(20);
BEGIN
  -- 獲取測試客戶
  SELECT id INTO test_customer_id
  FROM users
  WHERE role = 'customer'
  LIMIT 1;
  
  IF test_customer_id IS NULL THEN
    RAISE EXCEPTION '❌ 沒有可用的測試客戶';
  END IF;
  
  -- 生成訂單編號（縮短前綴以符合 VARCHAR(20) 限制）
  -- 'FLOW_' (5 字符) + timestamp (10 字符) = 15 字符 < 20 ✓
  test_booking_number := 'FLOW_' || EXTRACT(EPOCH FROM NOW())::BIGINT;
  
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
    '測試地點 A - 狀態流轉測試',
    '測試地點 B - 狀態流轉測試',
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
  RAISE NOTICE '   狀態: pending_payment (待配對)';
END $$;

-- 等待 2 秒
SELECT pg_sleep(2);

-- ============================================
-- 步驟 2: 支付訂金（paid_deposit）
-- ============================================
SELECT '=== 步驟 2: 支付訂金 ===' AS "測試步驟";

DO $$
DECLARE
  test_booking_id UUID;
BEGIN
  SELECT id INTO test_booking_id
  FROM bookings
  WHERE pickup_location LIKE '%狀態流轉測試%'
  ORDER BY created_at DESC
  LIMIT 1;
  
  UPDATE bookings
  SET status = 'paid_deposit',
      updated_at = NOW()
  WHERE id = test_booking_id;
  
  RAISE NOTICE '✅ 訂金已支付';
  RAISE NOTICE '   狀態: paid_deposit (待配對)';
END $$;

SELECT pg_sleep(2);

-- ============================================
-- 步驟 3: 派單（matched）
-- ============================================
SELECT '=== 步驟 3: 派單 ===' AS "測試步驟";

DO $$
DECLARE
  test_booking_id UUID;
BEGIN
  SELECT id INTO test_booking_id
  FROM bookings
  WHERE pickup_location LIKE '%狀態流轉測試%'
  ORDER BY created_at DESC
  LIMIT 1;
  
  UPDATE bookings
  SET status = 'matched',
      updated_at = NOW()
  WHERE id = test_booking_id;
  
  RAISE NOTICE '✅ 已派單';
  RAISE NOTICE '   狀態: matched (待司機確認)';
END $$;

SELECT pg_sleep(2);

-- ============================================
-- 步驟 4: 司機確認（driver_confirmed）
-- ============================================
SELECT '=== 步驟 4: 司機確認 ===' AS "測試步驟";

DO $$
DECLARE
  test_booking_id UUID;
BEGIN
  SELECT id INTO test_booking_id
  FROM bookings
  WHERE pickup_location LIKE '%狀態流轉測試%'
  ORDER BY created_at DESC
  LIMIT 1;
  
  UPDATE bookings
  SET status = 'driver_confirmed',
      updated_at = NOW()
  WHERE id = test_booking_id;
  
  RAISE NOTICE '✅ 司機已確認';
  RAISE NOTICE '   狀態: driver_confirmed (已配對)';
END $$;

SELECT pg_sleep(2);

-- ============================================
-- 步驟 5: 司機出發（driver_departed）
-- ============================================
SELECT '=== 步驟 5: 司機出發 ===' AS "測試步驟";

DO $$
DECLARE
  test_booking_id UUID;
BEGIN
  SELECT id INTO test_booking_id
  FROM bookings
  WHERE pickup_location LIKE '%狀態流轉測試%'
  ORDER BY created_at DESC
  LIMIT 1;
  
  UPDATE bookings
  SET status = 'driver_departed',
      updated_at = NOW()
  WHERE id = test_booking_id;
  
  RAISE NOTICE '✅ 司機已出發';
  RAISE NOTICE '   狀態: driver_departed (進行中)';
END $$;

SELECT pg_sleep(2);

-- ============================================
-- 步驟 6: 司機抵達（driver_arrived）
-- ============================================
SELECT '=== 步驟 6: 司機抵達 ===' AS "測試步驟";

DO $$
DECLARE
  test_booking_id UUID;
BEGIN
  SELECT id INTO test_booking_id
  FROM bookings
  WHERE pickup_location LIKE '%狀態流轉測試%'
  ORDER BY created_at DESC
  LIMIT 1;
  
  UPDATE bookings
  SET status = 'driver_arrived',
      updated_at = NOW()
  WHERE id = test_booking_id;
  
  RAISE NOTICE '✅ 司機已抵達';
  RAISE NOTICE '   狀態: driver_arrived (進行中)';
END $$;

SELECT pg_sleep(2);

-- ============================================
-- 步驟 7: 開始行程（trip_started）
-- ============================================
SELECT '=== 步驟 7: 開始行程 ===' AS "測試步驟";

DO $$
DECLARE
  test_booking_id UUID;
BEGIN
  SELECT id INTO test_booking_id
  FROM bookings
  WHERE pickup_location LIKE '%狀態流轉測試%'
  ORDER BY created_at DESC
  LIMIT 1;
  
  UPDATE bookings
  SET status = 'trip_started',
      updated_at = NOW()
  WHERE id = test_booking_id;
  
  RAISE NOTICE '✅ 行程已開始';
  RAISE NOTICE '   狀態: trip_started (進行中)';
END $$;

SELECT pg_sleep(2);

-- ============================================
-- 步驟 8: 結束行程（trip_ended）
-- ============================================
SELECT '=== 步驟 8: 結束行程 ===' AS "測試步驟";

DO $$
DECLARE
  test_booking_id UUID;
BEGIN
  SELECT id INTO test_booking_id
  FROM bookings
  WHERE pickup_location LIKE '%狀態流轉測試%'
  ORDER BY created_at DESC
  LIMIT 1;
  
  UPDATE bookings
  SET status = 'trip_ended',
      updated_at = NOW()
  WHERE id = test_booking_id;
  
  RAISE NOTICE '✅ 行程已結束';
  RAISE NOTICE '   狀態: trip_ended (待付尾款)';
END $$;

SELECT pg_sleep(2);

-- ============================================
-- 步驟 9: 支付尾款（completed）
-- ============================================
SELECT '=== 步驟 9: 支付尾款 ===' AS "測試步驟";

DO $$
DECLARE
  test_booking_id UUID;
BEGIN
  SELECT id INTO test_booking_id
  FROM bookings
  WHERE pickup_location LIKE '%狀態流轉測試%'
  ORDER BY created_at DESC
  LIMIT 1;
  
  UPDATE bookings
  SET status = 'completed',
      updated_at = NOW()
  WHERE id = test_booking_id;
  
  RAISE NOTICE '✅ 訂單已完成';
  RAISE NOTICE '   狀態: completed (已完成)';
END $$;

-- ============================================
-- 測試總結
-- ============================================
SELECT '
============================================
📊 測試總結
============================================
' AS "測試總結";

SELECT 
  booking_number AS "訂單編號",
  status AS "最終狀態",
  created_at AS "創建時間",
  updated_at AS "更新時間",
  EXTRACT(EPOCH FROM (updated_at - created_at)) AS "總耗時（秒）"
FROM bookings
WHERE pickup_location LIKE '%狀態流轉測試%'
ORDER BY created_at DESC
LIMIT 1;

-- 檢查 HTTP 請求記錄
SELECT '=== HTTP 請求記錄 ===' AS "檢查項目";

SELECT 
  id,
  created,
  status_code,
  CASE
    WHEN status_code = 200 THEN '✅ 成功'
    WHEN status_code IS NULL THEN '⏳ 處理中'
    ELSE '❌ 失敗'
  END AS "狀態"
FROM net._http_response
WHERE created >= NOW() - INTERVAL '5 minutes'
ORDER BY created DESC
LIMIT 10;

-- 檢查 outbox 事件
SELECT '=== Outbox 事件記錄 ===' AS "檢查項目";

SELECT 
  event_type AS "事件類型",
  created_at AS "創建時間",
  processed_at AS "處理時間",
  EXTRACT(EPOCH FROM (processed_at - created_at)) AS "延遲（秒）",
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已處理'
    ELSE '⏳ 待處理'
  END AS "狀態"
FROM outbox
WHERE created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC
LIMIT 10;

SELECT '
============================================
✅ 測試完成
============================================

測試了完整的訂單狀態流轉：
1. pending_payment → 2. paid_deposit → 3. matched → 
4. driver_confirmed → 5. driver_departed → 6. driver_arrived → 
7. trip_started → 8. trip_ended → 9. completed

每次狀態變更都應該觸發即時同步到 Firestore。

請檢查：
1. HTTP 請求記錄 - 應該有 9 次成功的請求
2. Outbox 事件 - 應該有 9 個已處理的事件
3. Firestore - orders_rt 和 bookings 集合應該有對應的更新

============================================
' AS "測試完成";

