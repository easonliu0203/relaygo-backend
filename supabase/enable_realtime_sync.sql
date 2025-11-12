-- ============================================
-- 啟用即時同步腳本
-- ============================================
-- 
-- 功能：創建並啟用即時通知 Trigger
-- 使用場景：
--   1. 首次啟用即時同步功能
--   2. 從停用狀態恢復到啟用狀態
-- 
-- 執行方式：
--   在 Supabase Dashboard SQL Editor 中執行此腳本
--   或通過管理後台 API 調用
-- 
-- ============================================

-- 步驟 1：檢查前置條件
-- ============================================
DO $$
DECLARE
  function_exists BOOLEAN;
  pg_net_exists BOOLEAN;
BEGIN
  -- 檢查 Trigger Function 是否存在
  SELECT EXISTS(
    SELECT 1 FROM pg_proc WHERE proname = 'notify_edge_function_realtime'
  ) INTO function_exists;
  
  IF NOT function_exists THEN
    RAISE EXCEPTION '❌ Trigger Function 不存在，請先執行 migration 腳本';
  END IF;
  
  -- 檢查 pg_net 擴展是否啟用
  SELECT EXISTS(
    SELECT 1 FROM pg_extension WHERE extname = 'pg_net'
  ) INTO pg_net_exists;
  
  IF NOT pg_net_exists THEN
    RAISE EXCEPTION '❌ pg_net 擴展未啟用，請先啟用該擴展';
  END IF;
  
  RAISE NOTICE '✅ 前置條件檢查通過';
END $$;

-- 步驟 2：刪除舊的 Trigger（如果存在）
-- ============================================
DROP TRIGGER IF EXISTS bookings_realtime_notify_trigger ON bookings;

-- 步驟 3：創建新的 Trigger
-- ============================================
CREATE TRIGGER bookings_realtime_notify_trigger
AFTER INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION notify_edge_function_realtime();

-- 步驟 4：更新配置狀態
-- ============================================
UPDATE system_settings
SET value = jsonb_set(
  value,
  '{enabled}',
  'true'::jsonb
),
updated_at = NOW()
WHERE key = 'realtime_sync_config';

-- 步驟 5：記錄啟用日誌
-- ============================================
INSERT INTO realtime_sync_stats (date, realtime_count, cron_count, error_count)
VALUES (CURRENT_DATE, 0, 0, 0)
ON CONFLICT (date) DO NOTHING;

-- ============================================
-- 驗證啟用結果
-- ============================================
SELECT '
============================================
✅ 即時同步已啟用
============================================
' AS message;

-- 檢查 Trigger 狀態
SELECT 
  tgname AS "Trigger 名稱",
  tgenabled AS "啟用狀態",
  CASE tgenabled
    WHEN 'O' THEN '✅ 已啟用'
    WHEN 'D' THEN '❌ 已停用'
    ELSE '⚠️  未知狀態'
  END AS "狀態說明"
FROM pg_trigger
WHERE tgname = 'bookings_realtime_notify_trigger';

-- 檢查配置狀態
SELECT 
  key AS "配置鍵",
  value->>'enabled' AS "配置狀態",
  updated_at AS "更新時間"
FROM system_settings
WHERE key = 'realtime_sync_config';

-- 顯示完整狀態
SELECT * FROM get_realtime_sync_status();

-- ============================================
-- 測試建議
-- ============================================
SELECT '
============================================
測試建議
============================================

1. 執行測試腳本：
   在 SQL Editor 中執行 test_realtime_sync.sql

2. 或手動創建測試訂單：
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
     (SELECT id FROM users WHERE role = ''customer'' LIMIT 1),
     ''TEST_MANUAL_'' || EXTRACT(EPOCH FROM NOW())::BIGINT,
     ''pending_payment'',
     ''Test Location A'',
     ''Test Location B'',
     CURRENT_DATE + INTERVAL ''1 day'',
     ''10:00:00'',
     8,
     ''A'',
     1000.00,
     1000.00,
     300.00
   );

3. 檢查 HTTP 請求記錄：
   SELECT * FROM net._http_response
   ORDER BY created DESC
   LIMIT 5;

4. 檢查 outbox 事件：
   SELECT * FROM outbox
   WHERE created_at > NOW() - INTERVAL ''5 minutes''
   ORDER BY created_at DESC;

5. 檢查 Firestore 同步結果：
   前往 Firebase Console 查看 orders_rt 集合

============================================
' AS "測試指南";

