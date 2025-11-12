-- ============================================
-- 停用即時同步腳本
-- ============================================
-- 
-- 功能：停用即時通知 Trigger，退回到只使用 Cron Job 的模式
-- 使用場景：
--   1. Edge Function 維護期間
--   2. 遇到 Rate 限制或服務異常
--   3. 需要降低系統負載
--   4. 測試 Cron 補償機制
-- 
-- 執行方式：
--   在 Supabase Dashboard SQL Editor 中執行此腳本
--   或通過管理後台 API 調用
-- 
-- 注意：停用後，Cron Job 仍會繼續運行，確保數據同步
-- 
-- ============================================

-- 步驟 1：檢查當前狀態
-- ============================================
DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  -- 檢查 Trigger 是否存在
  SELECT EXISTS(
    SELECT 1 FROM pg_trigger WHERE tgname = 'bookings_realtime_notify_trigger'
  ) INTO trigger_exists;
  
  IF NOT trigger_exists THEN
    RAISE NOTICE '⚠️  Trigger 不存在，可能已經停用';
  ELSE
    RAISE NOTICE '✅ 找到 Trigger，準備停用';
  END IF;
END $$;

-- 步驟 2：刪除 Trigger
-- ============================================
DROP TRIGGER IF EXISTS bookings_realtime_notify_trigger ON bookings;

-- 步驟 3：更新配置狀態
-- ============================================
UPDATE system_settings
SET value = jsonb_set(
  value,
  '{enabled}',
  'false'::jsonb
),
updated_at = NOW()
WHERE key = 'realtime_sync_config';

-- 步驟 4：記錄停用時間
-- ============================================
UPDATE system_settings
SET value = jsonb_set(
  value,
  '{disabled_at}',
  to_jsonb(NOW()::TEXT)
)
WHERE key = 'realtime_sync_config';

-- ============================================
-- 驗證停用結果
-- ============================================
SELECT '
============================================
✅ 即時同步已停用
============================================

系統已退回到 Cron Job 模式：
- Cron Job 仍在運行（每 5 秒或 30 秒）
- 數據同步不會中斷
- 延遲時間：最多 5-30 秒

如需重新啟用，請執行 enable_realtime_sync.sql
或通過管理後台的派單設定頁面啟用

============================================
' AS message;

-- 檢查 Trigger 狀態（應該不存在）
SELECT 
  CASE 
    WHEN COUNT(*) = 0 THEN '✅ Trigger 已成功刪除'
    ELSE '❌ Trigger 仍然存在'
  END AS "Trigger 狀態"
FROM pg_trigger
WHERE tgname = 'bookings_realtime_notify_trigger';

-- 檢查配置狀態
SELECT 
  key AS "配置鍵",
  value->>'enabled' AS "配置狀態",
  value->>'disabled_at' AS "停用時間",
  updated_at AS "更新時間"
FROM system_settings
WHERE key = 'realtime_sync_config';

-- 顯示完整狀態
SELECT * FROM get_realtime_sync_status();

-- 檢查 Cron Job 狀態（確保仍在運行）
SELECT 
  jobname AS "Cron Job 名稱",
  schedule AS "執行頻率",
  active AS "是否啟用",
  CASE 
    WHEN active THEN '✅ 正常運行'
    ELSE '❌ 未啟用'
  END AS "狀態"
FROM cron.job
WHERE jobname = 'sync-orders-to-firestore';

-- ============================================
-- 補償機制說明
-- ============================================
SELECT '
============================================
📝 補償機制說明
============================================

即使停用即時同步，系統仍然可靠：

1. Cron Job 補償機制：
   - 每 5 秒（測試）或 30 秒（正式）執行一次
   - 自動處理所有未同步的事件
   - 確保數據最終一致性

2. 數據不會丟失：
   - 所有變更都寫入 outbox 表
   - Cron Job 會處理所有 processed_at IS NULL 的事件
   - 最多延遲 5-30 秒

3. 重新啟用：
   - 執行 enable_realtime_sync.sql
   - 或通過管理後台啟用
   - 立即恢復 1-3 秒的即時同步

4. 監控建議：
   - 檢查 outbox 表的未處理事件數量
   - 監控 Cron Job 執行記錄
   - 查看 Edge Function 日誌

============================================
' AS "補償機制";

-- 顯示最近的 outbox 事件（確認 Cron 會處理）
SELECT 
  COUNT(*) AS "未處理事件數",
  MIN(created_at) AS "最早事件時間",
  MAX(created_at) AS "最新事件時間"
FROM outbox
WHERE processed_at IS NULL;

