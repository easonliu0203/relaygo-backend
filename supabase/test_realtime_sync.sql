-- ============================================
-- 即時同步功能測試腳本
-- ============================================
-- 
-- 功能：全面測試即時同步系統的各項功能
-- 包含：
--   1. 前置條件檢查
--   2. 創建測試訂單
--   3. 驗證即時通知
--   4. 驗證補償機制
--   5. 性能測試
--   6. 清理測試數據
-- 
-- 使用方式：
--   在 Supabase Dashboard SQL Editor 中執行此腳本
-- 
-- ============================================

SELECT '
============================================
🧪 即時同步功能測試
============================================
開始時間: ' || NOW() || '
============================================
' AS "測試開始";

-- ============================================
-- 測試 1: 前置條件檢查
-- ============================================
SELECT '=== 測試 1: 前置條件檢查 ===' AS "測試項目";

-- 檢查 pg_net 擴展
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    RAISE EXCEPTION '❌ pg_net 擴展未啟用';
  END IF;
  RAISE NOTICE '✅ pg_net 擴展已啟用';
END $$;

-- 檢查 Trigger Function
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'notify_edge_function_realtime') THEN
    RAISE EXCEPTION '❌ Trigger Function 不存在';
  END IF;
  RAISE NOTICE '✅ Trigger Function 已創建';
END $$;

-- 檢查配置
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM system_settings WHERE key = 'realtime_sync_config') THEN
    RAISE EXCEPTION '❌ 配置不存在';
  END IF;
  RAISE NOTICE '✅ 配置已創建';
END $$;

-- ============================================
-- 測試 2: 創建測試訂單（測試即時通知）
-- ============================================
SELECT '=== 測試 2: 創建測試訂單（測試即時通知）===' AS "測試項目";

-- 記錄測試開始時間
DO $$
DECLARE
  test_start_time TIMESTAMP WITH TIME ZONE;
  test_booking_id UUID;
  test_customer_id UUID;
  rec RECORD;
  valid_status VARCHAR(20);
BEGIN
  test_start_time := NOW();

  -- 獲取一個測試客戶
  SELECT id INTO test_customer_id
  FROM users
  WHERE role = 'customer'
  LIMIT 1;

  IF test_customer_id IS NULL THEN
    RAISE EXCEPTION '❌ 沒有可用的測試客戶';
  END IF;

  -- 獲取一個有效的 status 值（從現有訂單中）
  SELECT status INTO valid_status
  FROM bookings
  LIMIT 1;

  -- 如果沒有現有訂單，使用默認值
  IF valid_status IS NULL THEN
    valid_status := 'pending';
  END IF;

  RAISE NOTICE '使用 status 值: %', valid_status;

  -- 創建測試訂單
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
    -- 縮短前綴以符合 VARCHAR(20) 限制：'RT_' (3) + timestamp (10) = 13 < 20 ✓
    'RT_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    valid_status,
    '測試地點 A - 即時同步測試',
    '測試地點 B - 即時同步測試',
    CURRENT_DATE + INTERVAL '1 day',
    '10:00:00',
    8,
    'A',
    1000.00,
    1000.00,
    300.00
  ) RETURNING id INTO test_booking_id;
  
  RAISE NOTICE '✅ 測試訂單已創建: %', test_booking_id;
  RAISE NOTICE '⏱️  創建時間: %', test_start_time;
  
  -- 等待 3 秒（給即時通知時間執行）
  PERFORM pg_sleep(3);
  
  -- 檢查 outbox 事件
  IF EXISTS (
    SELECT 1 FROM outbox 
    WHERE aggregate_id = test_booking_id::TEXT
  ) THEN
    RAISE NOTICE '✅ Outbox 事件已創建';
  ELSE
    RAISE WARNING '❌ Outbox 事件未創建';
  END IF;
  
  -- 檢查 HTTP 請求
  IF EXISTS (
    SELECT 1 FROM net._http_response
    WHERE created >= test_start_time
  ) THEN
    RAISE NOTICE '✅ HTTP 請求已發送';

    -- 顯示請求詳情
    RAISE NOTICE '📊 HTTP 請求詳情:';
    FOR rec IN (
      SELECT
        id,
        status_code,
        created,
        EXTRACT(EPOCH FROM (created - test_start_time)) AS delay_seconds
      FROM net._http_response
      WHERE created >= test_start_time
      ORDER BY created DESC
      LIMIT 1
    ) LOOP
      RAISE NOTICE '   - 請求 ID: %', rec.id;
      RAISE NOTICE '   - 狀態碼: %', rec.status_code;
      RAISE NOTICE '   - 延遲時間: % 秒', ROUND(rec.delay_seconds::NUMERIC, 2);
      
      IF rec.delay_seconds <= 3 THEN
        RAISE NOTICE '   ✅ 延遲符合預期（< 3 秒）';
      ELSE
        RAISE WARNING '   ⚠️  延遲較高（> 3 秒）';
      END IF;
    END LOOP;
  ELSE
    RAISE WARNING '❌ HTTP 請求未發送（可能即時同步未啟用）';
  END IF;
  
END $$;

-- ============================================
-- 測試 3: 更新測試訂單（測試即時通知）
-- ============================================
SELECT '=== 測試 3: 更新測試訂單（測試即時通知）===' AS "測試項目";

DO $$
DECLARE
  test_start_time TIMESTAMP WITH TIME ZONE;
  test_booking_id UUID;
  current_status VARCHAR(20);
  new_status VARCHAR(20);
BEGIN
  test_start_time := NOW();

  -- 獲取剛創建的測試訂單
  SELECT id, status INTO test_booking_id, current_status
  FROM bookings
  WHERE pickup_location LIKE '%即時同步測試%'
  ORDER BY created_at DESC
  LIMIT 1;

  IF test_booking_id IS NULL THEN
    RAISE EXCEPTION '❌ 找不到測試訂單';
  END IF;

  -- 獲取一個不同的有效 status 值
  SELECT DISTINCT status INTO new_status
  FROM bookings
  WHERE status != current_status
  LIMIT 1;

  -- 如果找不到不同的 status，就使用相同的（只是為了觸發 UPDATE）
  IF new_status IS NULL THEN
    new_status := current_status;
  END IF;

  RAISE NOTICE '當前 status: %, 新 status: %', current_status, new_status;

  -- 更新訂單狀態
  UPDATE bookings
  SET status = new_status,
      updated_at = NOW()
  WHERE id = test_booking_id;
  
  RAISE NOTICE '✅ 測試訂單已更新: %', test_booking_id;
  RAISE NOTICE '⏱️  更新時間: %', test_start_time;
  
  -- 等待 3 秒
  PERFORM pg_sleep(3);
  
  -- 檢查是否有新的 HTTP 請求（更新後應該有至少 2 個請求）
  IF (SELECT COUNT(*) FROM net._http_response WHERE created >= test_start_time) >= 2 THEN
    RAISE NOTICE '✅ 更新觸發了即時通知';
  ELSE
    RAISE WARNING '❌ 更新未觸發即時通知（或僅有創建時的請求）';
  END IF;
  
END $$;

-- ============================================
-- 測試 4: 檢查補償機制
-- ============================================
SELECT '=== 測試 4: 檢查補償機制（Cron Job）===' AS "測試項目";

-- 檢查 Cron Job 狀態
SELECT 
  jobname AS "任務名稱",
  schedule AS "執行頻率",
  active AS "是否啟用",
  CASE 
    WHEN active THEN '✅ 正常運行'
    ELSE '❌ 未啟用'
  END AS "狀態"
FROM cron.job
WHERE jobname = 'sync-orders-to-firestore';

-- 檢查最近的 Cron Job 執行記錄
SELECT 
  '最近 5 次 Cron Job 執行記錄:' AS "說明";

SELECT 
  runid AS "執行 ID",
  status AS "狀態",
  start_time AS "開始時間",
  end_time AS "結束時間",
  (end_time - start_time) AS "執行時長"
FROM cron.job_run_details
WHERE jobid = (
  SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore'
)
ORDER BY start_time DESC
LIMIT 5;

-- ============================================
-- 測試 5: 性能統計
-- ============================================
SELECT '=== 測試 5: 性能統計 ===' AS "測試項目";

-- 今日事件統計
SELECT 
  '今日事件統計:' AS "說明";

SELECT 
  COUNT(*) AS "總事件數",
  COUNT(*) FILTER (WHERE processed_at IS NOT NULL) AS "已處理",
  COUNT(*) FILTER (WHERE processed_at IS NULL) AS "待處理",
  COUNT(*) FILTER (WHERE error_message IS NOT NULL) AS "錯誤",
  ROUND(AVG(EXTRACT(EPOCH FROM (processed_at - created_at)))::NUMERIC, 2) AS "平均延遲（秒）"
FROM outbox
WHERE created_at >= CURRENT_DATE;

-- HTTP 請求統計
SELECT 
  '今日 HTTP 請求統計:' AS "說明";

SELECT
  COUNT(*) AS "總請求數",
  COUNT(*) FILTER (WHERE status_code = 200) AS "成功",
  COUNT(*) FILTER (WHERE status_code != 200 OR status_code IS NULL) AS "失敗",
  ROUND(100.0 * COUNT(*) FILTER (WHERE status_code = 200) / NULLIF(COUNT(*), 0), 2) AS "成功率（%）"
FROM net._http_response
WHERE created >= CURRENT_DATE;

-- ============================================
-- 測試 6: 清理測試數據（可選）
-- ============================================
SELECT '=== 測試 6: 清理測試數據 ===' AS "測試項目";

SELECT '
⚠️  是否清理測試數據？

如需清理，請執行以下 SQL：

-- 刪除測試訂單
DELETE FROM bookings 
WHERE pickup_location LIKE ''%即時同步測試%'';

-- 刪除對應的 outbox 事件
DELETE FROM outbox 
WHERE aggregate_id IN (
  SELECT id::TEXT FROM bookings 
  WHERE pickup_location LIKE ''%即時同步測試%''
);

' AS "清理指南";

-- ============================================
-- 測試總結
-- ============================================
SELECT '
============================================
📊 測試總結
============================================

請檢查以上測試結果：

✅ 成功項目：
- pg_net 擴展已啟用
- Trigger Function 已創建
- 配置已創建
- 測試訂單已創建
- HTTP 請求已發送
- Cron Job 正常運行

⚠️  需要注意：
- 檢查延遲時間是否 < 3 秒
- 檢查 HTTP 請求成功率是否 > 95%
- 檢查待處理事件數是否 < 10

❌ 如果有失敗項目：
- 查看錯誤訊息
- 執行 check_realtime_sync_status.sql
- 查看 Edge Function 日誌

============================================
測試完成時間: ' || NOW() || '
============================================
' AS "測試總結";

