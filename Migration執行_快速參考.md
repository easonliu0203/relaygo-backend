# Migration 執行 - 快速參考卡片

## 🎯 目標
執行 Migration 腳本以創建所有必要的數據庫對象

---

## 📍 執行位置
**Supabase Dashboard SQL Editor**  
https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql

---

## 📝 執行步驟（3 步驟）

### 1️⃣ 打開 SQL Editor
- 訪問上面的 URL
- 點擊 "New query"

### 2️⃣ 複製並執行 Migration 腳本
- 打開文件: `d:\repo\supabase\migrations\20251016_create_realtime_sync_trigger.sql`
- 全選（Ctrl+A）並複製（Ctrl+C）
- 貼到 SQL Editor
- 點擊 "Run"（或 Ctrl+Enter）

### 3️⃣ 驗證執行結果
執行以下 SQL 確認所有對象已創建：

```sql
SELECT 
  'Trigger Function' AS check_item,
  CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'notify_edge_function_realtime')
    THEN '✅ 存在' ELSE '❌ 不存在' END AS status
UNION ALL
SELECT 'Configuration',
  CASE WHEN EXISTS (SELECT 1 FROM system_settings WHERE key = 'realtime_sync_config')
    THEN '✅ 已創建' ELSE '❌ 未創建' END
UNION ALL
SELECT 'Status Function',
  CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_realtime_sync_status')
    THEN '✅ 存在' ELSE '❌ 不存在' END
UNION ALL
SELECT 'pg_net Extension',
  CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net')
    THEN '✅ 已啟用' ELSE '❌ 未啟用' END
UNION ALL
SELECT 'Stats Table',
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'realtime_sync_stats')
    THEN '✅ 已創建' ELSE '❌ 未創建' END;
```

---

## ✅ 預期結果

所有項目都應該顯示 "✅":

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

## 🎯 成功後的下一步

1. **執行測試腳本**: `supabase/test_realtime_sync.sql`
2. **啟用即時同步**: `supabase/enable_realtime_sync.sql`
3. **監控狀態**: `supabase/check_realtime_sync_status.sql`

---

## ❌ 常見錯誤

### 錯誤: system_settings 表不存在

**解決方法**: 先創建表
```sql
CREATE TABLE IF NOT EXISTS system_settings (
  key TEXT PRIMARY KEY,
  value JSONB,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 錯誤: pg_net 擴展不可用

**解決方法**: 
1. 前往 Database > Extensions
2. 搜尋 "pg_net"
3. 點擊 "Enable"

---

## 📚 詳細文檔

查看完整的執行指南：
```
d:\repo\執行Migration_詳細步驟.md
```

---

**快速參考版本**: v1.0.0  
**創建日期**: 2025-10-16

