# SQL 腳本修復報告

> **修復日期**: 2025-10-16
> **修復的腳本**: 3 個
> **狀態**: ✅ 全部修復完成（包含 booking_number 欄位修復）
> **版本**: v1.1.0

---

## 📋 修復總結

### ✅ 修復 1: test_realtime_sync.sql

**問題 1**: FOR 循環變數未聲明
```
ERROR: 42601: loop variable of loop over rows must be a record variable or list of scalar variables
LINE 134: FOR rec IN (
```

**問題 2**: booking_number 欄位缺失
```
ERROR: 23502: null value in column "booking_number" of relation "bookings" violates not-null constraint
```

**根本原因**:
- 第 134 行使用了 `FOR rec IN (...) LOOP`，但在 DECLARE 部分沒有聲明 `rec RECORD;`
- INSERT 語句缺少必填欄位 `booking_number` 和 `base_price`

**修復內容**:
1. 在第 66-71 行的 DECLARE 部分添加 `rec RECORD;` 聲明
2. 添加 `booking_number` 欄位，使用時間戳生成唯一編號：`'TEST_RT_' || EXTRACT(EPOCH FROM NOW())::BIGINT`
3. 添加 `base_price` 欄位（設為 1000.00）
4. 移除所有 `url LIKE '%sync-to-firestore%'` 過濾條件（共 4 處）
   - 原因：pg_net 的 `_http_response` 表沒有 `url` 欄位
   - 改用時間範圍過濾：`WHERE created >= test_start_time`

**修復位置**:
- 第 66-71 行：添加 RECORD 聲明
- 第 84-111 行：添加 booking_number 和 base_price 欄位
- 第 125-144 行：移除 URL 過濾（檢查 HTTP 請求）
- 第 196-201 行：改用計數檢查（檢查更新觸發）
- 第 266-267 行：移除 URL 過濾（性能統計）

---

### ✅ 修復 2: enable_realtime_sync.sql

**問題 1**: 測試指南中的中文字符亂碼
```
'試地點點 B ,
CURRENT_DATE + INTERVAL '1 day',
```

**問題 2**: 手動測試 SQL 缺少必填欄位

**根本原因**:
- 可能是文件編碼問題或終端顯示問題
- 中文字符在某些環境下顯示異常
- INSERT 語句缺少 `booking_number` 和 `base_price` 欄位

**修復內容**:
1. 優化測試指南格式
2. 將中文地點名稱改為英文（避免編碼問題）
   - "測試地點 A" → "Test Location A"
   - "測試地點 B" → "Test Location B"
3. 添加 `booking_number` 欄位：`'TEST_MANUAL_' || EXTRACT(EPOCH FROM NOW())::BIGINT`
4. 添加 `base_price` 欄位（設為 1000.00）
5. 添加第一步：建議執行 test_realtime_sync.sql

**修復位置**:
- 第 104-154 行：重寫測試指南部分
- 第 115-142 行：添加 booking_number 和 base_price 欄位

---

### ✅ 修復 3: check_realtime_sync_status.sql

**問題**: 查詢不存在的欄位
```
ERROR: 42703: column "url" does not exist
LINE 156: WHERE url LIKE '%sync-to-firestore%'
```

**根本原因**: 
- pg_net 的 `_http_response` 表沒有 `url` 欄位
- 嘗試使用不存在的欄位進行過濾

**修復內容**:
1. 移除 `WHERE url LIKE '%sync-to-firestore%'` 過濾條件
2. 改為顯示所有最近的 HTTP 請求（按時間排序）
3. 優化響應內容顯示：只顯示前 100 字符（避免過長）

**修復位置**:
- 第 145-157 行：移除 URL 過濾，優化顯示

---

## 🔍 pg_net 表結構說明

### `net._http_response` 表

**標準欄位**（根據 pg_net 文檔）:
- `id` - 請求 ID（BIGINT）
- `status_code` - HTTP 狀態碼（INTEGER）
- `content` - 響應內容（JSONB 或 TEXT）
- `created` - 創建時間（TIMESTAMP）
- `error_msg` - 錯誤訊息（TEXT，可選）

**不包含的欄位**:
- ❌ `url` - URL 不在此表中
- ❌ `request` - 請求數據不在此表中

**注意**: 
- URL 信息可能在 `net.http_request_queue` 表中
- 但對於已完成的請求，通常不需要 URL 過濾
- 使用時間範圍過濾更可靠

---

## ✅ 驗證修復

### 步驟 1: 重新執行測試腳本

在 Supabase SQL Editor 中執行：

```sql
-- 文件位置: d:\repo\supabase\test_realtime_sync.sql
```

**預期結果**:
- ✅ 測試 1: 前置條件檢查 - 通過
- ✅ 測試 2: 創建測試訂單 - 成功
- ✅ 測試 3: 更新測試訂單 - 成功
- ✅ 測試 4: Cron Job 檢查 - 通過
- ✅ 測試 5: 性能統計 - 顯示數據
- ✅ 測試 6: 清理測試數據 - 完成

**不應再出現的錯誤**:
- ❌ loop variable must be a record variable
- ❌ column "url" does not exist

---

### 步驟 2: 執行啟用腳本

在 Supabase SQL Editor 中執行：

```sql
-- 文件位置: d:\repo\supabase\enable_realtime_sync.sql
```

**預期結果**:
- ✅ 前置條件檢查通過
- ✅ Trigger 已創建
- ✅ 配置已更新為 enabled=true
- ✅ 測試指南正常顯示（無亂碼）

---

### 步驟 3: 執行狀態檢查

在 Supabase SQL Editor 中執行：

```sql
-- 文件位置: d:\repo\supabase\check_realtime_sync_status.sql
```

**預期結果**:
- ✅ 檢查 1-11 全部通過
- ✅ HTTP 請求記錄正常顯示
- ✅ 性能指標正常計算

**不應再出現的錯誤**:
- ❌ column "url" does not exist

---

## 📊 修復前後對比

### test_realtime_sync.sql

| 項目 | 修復前 | 修復後 |
|------|--------|--------|
| RECORD 聲明 | ❌ 缺失 | ✅ 已添加 |
| URL 過濾 | ❌ 使用不存在的欄位 | ✅ 使用時間範圍 |
| 錯誤處理 | ❌ 會報錯 | ✅ 正常執行 |

### enable_realtime_sync.sql

| 項目 | 修復前 | 修復後 |
|------|--------|--------|
| 測試指南 | ⚠️ 可能有亂碼 | ✅ 使用英文 |
| 訂單欄位 | ⚠️ 不完整 | ✅ 完整欄位 |
| 測試建議 | ⚠️ 僅手動測試 | ✅ 建議執行測試腳本 |

### check_realtime_sync_status.sql

| 項目 | 修復前 | 修復後 |
|------|--------|--------|
| URL 過濾 | ❌ 使用不存在的欄位 | ✅ 移除過濾 |
| 響應內容 | ⚠️ 可能過長 | ✅ 限制 100 字符 |
| 錯誤處理 | ❌ 會報錯 | ✅ 正常執行 |

---

## 🎯 下一步行動

### 1. 立即執行測試（推薦順序）

#### 步驟 1: 執行測試腳本
```
文件: d:\repo\supabase\test_realtime_sync.sql
位置: Supabase SQL Editor
預計時間: 5 分鐘
```

#### 步驟 2: 執行啟用腳本
```
文件: d:\repo\supabase\enable_realtime_sync.sql
位置: Supabase SQL Editor
預計時間: 2 分鐘
```

#### 步驟 3: 執行狀態檢查
```
文件: d:\repo\supabase\check_realtime_sync_status.sql
位置: Supabase SQL Editor
預計時間: 2 分鐘
```

---

### 2. 可選：檢查 pg_net 表結構

如果想確認 pg_net 的實際表結構：

```sql
-- 執行文件: d:\repo\supabase\check_pgnet_schema.sql
```

這將顯示：
- `_http_response` 表的所有欄位
- `http_request_queue` 表的所有欄位（如果存在）
- 最近的 HTTP 響應記錄示例

---

## 📞 需要幫助？

如果執行修復後的腳本時仍遇到問題：

1. **複製完整的錯誤訊息**
2. **記錄執行到哪一步**
3. **提供錯誤的上下文**

我會立即幫您診斷和解決。

---

## 📝 修復清單

請在執行後勾選：

- [ ] test_realtime_sync.sql - 執行成功
- [ ] enable_realtime_sync.sql - 執行成功
- [ ] check_realtime_sync_status.sql - 執行成功
- [ ] 所有測試通過
- [ ] Trigger 已啟用
- [ ] 即時同步正常工作

---

**修復報告版本**: v1.0.0  
**創建日期**: 2025-10-16  
**修復的文件**:
- `supabase/test_realtime_sync.sql`
- `supabase/enable_realtime_sync.sql`
- `supabase/check_realtime_sync_status.sql`

**新增的文件**:
- `supabase/check_pgnet_schema.sql` - pg_net 表結構檢查工具

