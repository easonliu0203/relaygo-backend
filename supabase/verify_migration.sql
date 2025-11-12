-- 驗證 Migration 是否成功執行

-- 檢查 1: Trigger Function 是否存在
SELECT 
  'Trigger Function' AS check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc WHERE proname = 'notify_edge_function_realtime'
    ) THEN '✅ 存在'
    ELSE '❌ 不存在'
  END AS status;

-- 檢查 2: 配置是否創建
SELECT 
  'Configuration' AS check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM system_settings WHERE key = 'realtime_sync_config'
    ) THEN '✅ 已創建'
    ELSE '❌ 未創建'
  END AS status;

-- 檢查 3: 狀態函數是否存在
SELECT 
  'Status Function' AS check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc WHERE proname = 'get_realtime_sync_status'
    ) THEN '✅ 存在'
    ELSE '❌ 不存在'
  END AS status;

-- 檢查 4: pg_net 擴展
SELECT 
  'pg_net Extension' AS check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_extension WHERE extname = 'pg_net'
    ) THEN '✅ 已啟用'
    ELSE '❌ 未啟用'
  END AS status;

-- 檢查 5: realtime_sync_stats 表
SELECT 
  'Stats Table' AS check_item,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_name = 'realtime_sync_stats'
    ) THEN '✅ 已創建'
    ELSE '❌ 未創建'
  END AS status;

