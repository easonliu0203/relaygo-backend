# 執行 Migration - 詳細步驟指南

> **目的**: 手動執行 Migration 腳本以創建所有必要的數據庫對象  
> **文件**: `supabase/migrations/20251016_create_realtime_sync_trigger.sql`  
> **執行位置**: Supabase Dashboard SQL Editor

---

## 📋 執行前確認

您已確認：
- ✅ pg_net 擴展已啟用
- ❌ Trigger Function 不存在（需要創建）
- ❌ Configuration 未創建（需要創建）
- ❌ Status Function 不存在（需要創建）
- ❌ Stats Table 未創建（需要創建）

---

## 🚀 執行步驟

### 步驟 1: 打開 SQL Editor

1. 訪問 Supabase Dashboard SQL Editor:
   ```
   https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql
   ```

2. 點擊 **"New query"** 創建新查詢

---

### 步驟 2: 複製 Migration 腳本

**方式 1: 從文件複製**

1. 打開文件: `d:\repo\supabase\migrations\20251016_create_realtime_sync_trigger.sql`
2. 全選（Ctrl+A）
3. 複製（Ctrl+C）

**方式 2: 使用下面的完整腳本**

直接複製以下完整的 SQL 腳本：

```sql
-- ============================================
-- 即時同步 Trigger 創建腳本
-- ============================================

-- 步驟 1：確保 pg_net 擴展已啟用
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 步驟 2：創建即時通知 Trigger Function
CREATE OR REPLACE FUNCTION notify_edge_function_realtime()
RETURNS TRIGGER AS $$
DECLARE
  edge_function_url TEXT;
  service_role_key TEXT;
  request_id BIGINT;
BEGIN
  -- 設定 Edge Function URL
  edge_function_url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore';
  
  -- 從環境變數獲取 Service Role Key
  BEGIN
    service_role_key := current_setting('app.settings.service_role_key', true);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'Unable to get service_role_key: %', SQLERRM;
      RETURN NEW;
  END;
  
  -- 發送異步 HTTP POST 請求到 Edge Function
  BEGIN
    SELECT net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || service_role_key,
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'trigger', 'realtime',
        'booking_id', NEW.id,
        'event_type', CASE
          WHEN TG_OP = 'INSERT' THEN 'created'
          WHEN TG_OP = 'UPDATE' THEN 'updated'
          ELSE 'unknown'
        END
      )
    ) INTO request_id;
    
    RAISE NOTICE 'Realtime sync triggered for booking %, request_id: %', NEW.id, request_id;
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'Realtime sync HTTP request failed for booking %: %', NEW.id, SQLERRM;
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 步驟 3：添加函數註釋
COMMENT ON FUNCTION notify_edge_function_realtime() IS 
'即時通知 Edge Function 的 Trigger 函數。
當 bookings 表發生 INSERT 或 UPDATE 時，立即發送 HTTP 請求到 sync-to-firestore Edge Function。
如果 HTTP 請求失敗，不會阻止 Trigger 執行，Cron Job 會作為補償機制處理。';

-- 步驟 4：創建狀態記錄表（用於監控）
CREATE TABLE IF NOT EXISTS realtime_sync_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  realtime_count INTEGER DEFAULT 0,
  cron_count INTEGER DEFAULT 0,
  error_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(date)
);

CREATE INDEX IF NOT EXISTS idx_realtime_sync_stats_date ON realtime_sync_stats(date);

COMMENT ON TABLE realtime_sync_stats IS '即時同步統計表，記錄每日的同步次數和錯誤次數';

-- 步驟 5：在 system_settings 中添加配置
INSERT INTO system_settings (key, value, description)
VALUES (
  'realtime_sync_config',
  jsonb_build_object(
    'enabled', false,
    'trigger_name', 'bookings_realtime_notify_trigger',
    'edge_function_url', 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
    'created_at', NOW(),
    'updated_at', NOW()
  ),
  '即時同步配置：控制 Trigger 是否啟用'
)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    updated_at = NOW();

-- 步驟 6：創建狀態查詢函數
CREATE OR REPLACE FUNCTION get_realtime_sync_status()
RETURNS TABLE (
  trigger_exists BOOLEAN,
  trigger_enabled BOOLEAN,
  config_enabled BOOLEAN,
  last_updated TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    EXISTS(
      SELECT 1 FROM pg_trigger 
      WHERE tgname = 'bookings_realtime_notify_trigger'
    ) AS trigger_exists,
    EXISTS(
      SELECT 1 FROM pg_trigger 
      WHERE tgname = 'bookings_realtime_notify_trigger' 
      AND tgenabled = 'O'
    ) AS trigger_enabled,
    (
      SELECT (value->>'enabled')::BOOLEAN 
      FROM system_settings 
      WHERE key = 'realtime_sync_config'
    ) AS config_enabled,
    (
      SELECT updated_at 
      FROM system_settings 
      WHERE key = 'realtime_sync_config'
    ) AS last_updated;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_realtime_sync_status() IS '獲取即時同步的當前狀態';

-- 驗證安裝
SELECT '✅ 即時同步 Trigger Function 已創建' AS message;

SELECT * FROM get_realtime_sync_status();

SELECT '✅ 配置已添加到 system_settings' AS message;

SELECT key, value, description 
FROM system_settings 
WHERE key = 'realtime_sync_config';
```

---

### 步驟 3: 執行腳本

1. 將腳本貼到 SQL Editor 中
2. 點擊 **"Run"** 按鈕（或按 Ctrl+Enter）
3. 等待執行完成（約 2-5 秒）

---

### 步驟 4: 查看執行結果

執行成功後，您應該看到以下輸出：

#### 結果 1: 成功訊息
```
✅ 即時同步 Trigger Function 已創建
```

#### 結果 2: 狀態查詢結果
```
trigger_exists  | trigger_enabled | config_enabled | last_updated
----------------|-----------------|----------------|------------------
false           | false           | false          | 2025-10-16 ...
```

**說明**: 
- `trigger_exists = false`: Trigger 尚未創建（正常，需要手動啟用）
- `config_enabled = false`: 配置默認為停用（正常）

#### 結果 3: 配置確認
```
key                    | value                                  | description
-----------------------|----------------------------------------|------------------
realtime_sync_config   | {"enabled": false, "trigger_name": ... | 即時同步配置...
```

---

### 步驟 5: 驗證所有對象已創建

執行以下驗證 SQL：

```sql
-- 完整驗證
SELECT 
  'Trigger Function' AS check_item,
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'notify_edge_function_realtime')
    THEN '✅ 存在' ELSE '❌ 不存在'
  END AS status
UNION ALL
SELECT 
  'Configuration',
  CASE 
    WHEN EXISTS (SELECT 1 FROM system_settings WHERE key = 'realtime_sync_config')
    THEN '✅ 已創建' ELSE '❌ 未創建'
  END
UNION ALL
SELECT 
  'Status Function',
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_realtime_sync_status')
    THEN '✅ 存在' ELSE '❌ 不存在'
  END
UNION ALL
SELECT 
  'pg_net Extension',
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net')
    THEN '✅ 已啟用' ELSE '❌ 未啟用'
  END
UNION ALL
SELECT 
  'Stats Table',
  CASE 
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'realtime_sync_stats')
    THEN '✅ 已創建' ELSE '❌ 未創建'
  END;
```

**預期結果**: 所有項目都應該顯示 "✅"

```
check_item        | status
------------------|----------
Trigger Function  | ✅ 存在
Configuration     | ✅ 已創建
Status Function   | ✅ 存在
pg_net Extension  | ✅ 已啟用
Stats Table       | ✅ 已創建
```

---

## ✅ 執行成功確認

如果所有驗證都通過，您已成功完成 Migration！

**已創建的對象**:
- ✅ `notify_edge_function_realtime()` - Trigger 函數
- ✅ `get_realtime_sync_status()` - 狀態查詢函數
- ✅ `realtime_sync_stats` - 統計表
- ✅ `realtime_sync_config` - 配置（在 system_settings 中）

---

## 🎯 下一步

Migration 執行成功後，您可以繼續：

### 1. 執行測試腳本

```bash
# 文件位置
d:\repo\supabase\test_realtime_sync.sql
```

現在測試腳本應該可以正常執行了。

### 2. 啟用即時同步

```bash
# 文件位置
d:\repo\supabase\enable_realtime_sync.sql
```

### 3. 監控運行狀態

```bash
# 文件位置
d:\repo\supabase\check_realtime_sync_status.sql
```

---

## ❌ 如果執行失敗

### 常見錯誤 1: system_settings 表不存在

**錯誤訊息**:
```
ERROR: relation "system_settings" does not exist
```

**解決方法**:
1. 檢查 system_settings 表是否存在：
   ```sql
   SELECT * FROM information_schema.tables WHERE table_name = 'system_settings';
   ```

2. 如果不存在，需要先創建：
   ```sql
   CREATE TABLE IF NOT EXISTS system_settings (
     key TEXT PRIMARY KEY,
     value JSONB,
     description TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

3. 重新執行 Migration 腳本

### 常見錯誤 2: 權限不足

**錯誤訊息**:
```
ERROR: permission denied for schema public
```

**解決方法**:
- 確認您使用的是有管理員權限的帳號
- 在 Supabase Dashboard 中，SQL Editor 應該自動使用 Service Role

### 常見錯誤 3: pg_net 擴展問題

**錯誤訊息**:
```
ERROR: extension "pg_net" is not available
```

**解決方法**:
1. 前往 Database > Extensions
2. 搜尋 "pg_net"
3. 點擊 "Enable"
4. 重新執行 Migration

---

## 📞 需要幫助？

如果遇到其他錯誤：

1. **複製完整的錯誤訊息**
2. **記錄執行到哪一步**
3. **提供錯誤的上下文**

我會幫您診斷和解決問題。

---

**執行指南版本**: v1.0.0  
**創建日期**: 2025-10-16  
**適用於**: Supabase 專案 vlyhwegpvpnjyocqmfqc

