# 🔧 資料庫 Migration 執行指南

## 📅 Migration 日期
2024-12-20

## 🎯 Migration 目的
修復旅遊方案管理的兩個 Bug：
1. **Bug 1**：停用方案後從列表消失
2. **Bug 2**：多語言內容無法儲存

## 📋 需要執行的 Migration

### Migration 檔案
`20251220_add_i18n_to_tour_packages.sql`

### 執行內容
1. 添加 `name_i18n` JSONB 欄位（多語言方案名稱）
2. 添加 `description_i18n` JSONB 欄位（多語言方案描述）
3. 創建 GIN 索引以提高 JSONB 查詢效能
4. 遷移現有資料到多語言格式（zh-TW）

## 🚀 執行步驟

### 方法 1：使用 Supabase Dashboard（推薦）

1. **登入 Supabase Dashboard**
   - 前往：https://supabase.com/dashboard
   - 選擇專案：`vlyhwegpvpnjyocqmfqc`

2. **開啟 SQL Editor**
   - 左側選單 → SQL Editor
   - 點擊 "New query"

3. **複製並執行 Migration**
   - 開啟檔案：`database/migrations/20251220_add_i18n_to_tour_packages.sql`
   - 複製全部內容
   - 貼到 SQL Editor
   - 點擊 "Run" 按鈕

4. **驗證執行結果**
   - 查看執行結果訊息
   - 應該看到：
     ```
     ✅ tour_packages 表總記錄數: 8
     ✅ 已遷移多語言資料的記錄數: 8
     ✅ 所有記錄已成功遷移到多語言格式
     ```

5. **檢查資料**
   - 在 SQL Editor 執行：
     ```sql
     SELECT id, name, name_i18n, description_i18n 
     FROM tour_packages 
     LIMIT 3;
     ```
   - 確認 `name_i18n` 和 `description_i18n` 欄位有資料

### 方法 2：使用 psql 命令列

```bash
# 連接到 Supabase 資料庫
psql "postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# 執行 migration
\i database/migrations/20251220_add_i18n_to_tour_packages.sql

# 驗證結果
SELECT id, name, name_i18n FROM tour_packages LIMIT 3;
```

## ✅ 驗證 Migration 成功

執行以下 SQL 確認 Migration 成功：

```sql
-- 1. 檢查欄位是否存在
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'tour_packages' 
  AND column_name IN ('name_i18n', 'description_i18n');

-- 2. 檢查索引是否創建
SELECT indexname 
FROM pg_indexes 
WHERE tablename = 'tour_packages' 
  AND indexname LIKE '%i18n%';

-- 3. 檢查資料是否遷移
SELECT 
  COUNT(*) as total_records,
  COUNT(CASE WHEN name_i18n != '{}'::jsonb THEN 1 END) as migrated_records
FROM tour_packages;
```

預期結果：
- 欄位檢查：應該返回 2 行（name_i18n, description_i18n）
- 索引檢查：應該返回 2 個索引
- 資料檢查：total_records = migrated_records

## 🔄 後端 API 更改

Migration 執行後，後端 API 已自動支援以下功能：

### 1. GET /api/tour-packages
- ✅ 現在返回所有方案（包含停用的）
- ✅ 包含 `name_i18n` 和 `description_i18n` 欄位

### 2. POST /api/tour-packages
- ✅ 支援接收 `name_i18n` 和 `description_i18n` 欄位
- ✅ 自動儲存多語言資料

### 3. PUT /api/tour-packages/:id
- ✅ 支援更新 `name_i18n` 和 `description_i18n` 欄位
- ✅ 保留現有多語言資料

## 📊 影響範圍

### 已修復的 Bug

#### Bug 1：停用方案後從列表消失 ✅
- **修復方式**：移除 GET API 的 `.eq('is_active', true)` 過濾
- **影響**：Web Admin 現在可以看到所有方案（包含停用的）

#### Bug 2：多語言內容無法儲存 ✅
- **修復方式**：
  1. 資料庫添加 JSONB 欄位
  2. 後端 API 支援多語言欄位
  3. 前端已經支援（之前已實現）
- **影響**：現在可以正常儲存和讀取多語言內容

## 🧪 測試步驟

### 1. 測試 Bug 1 修復

1. 登入 Web Admin：https://admin.relaygo.pro
2. 進入「設定 > 旅遊方案管理」
3. 將任一方案狀態切換為「停用」
4. ✅ 確認方案仍然顯示在列表中

### 2. 測試 Bug 2 修復

1. 在 Web Admin 點擊「編輯」任一方案
2. 切換到「English」標籤頁
3. 填寫英文名稱和描述
4. 點擊「儲存」
5. 重新開啟編輯對話框
6. ✅ 確認英文內容已正確儲存

## 📞 需要協助？

如果 Migration 執行遇到問題：
1. 檢查 Supabase 連線是否正常
2. 確認有足夠的權限執行 DDL 語句
3. 查看 Supabase Dashboard 的錯誤訊息
4. 聯繫開發團隊

## 🎉 完成！

Migration 執行成功後，兩個 Bug 都已修復，系統可以正常運作。

