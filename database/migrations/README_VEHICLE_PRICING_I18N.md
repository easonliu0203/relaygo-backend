# 車型方案多語言 Migration 執行指南

## 📋 概述

本 Migration 為 `vehicle_pricing` 表添加多語言支援，允許車型描述和內容描述支援 8 種語言。

**支援語言**：
- 🇹🇼 zh-TW (繁體中文) - 預設語言
- 🇺🇸 en (English)
- 🇯🇵 ja (日本語)
- 🇰🇷 ko (한국어)
- 🇻🇳 vi (Tiếng Việt)
- 🇹🇭 th (ไทย)
- 🇲🇾 ms (Bahasa Melayu)
- 🇮🇩 id (Bahasa Indonesia)

---

## 🎯 Migration 內容

### 1. 新增欄位

| 欄位名稱 | 資料類型 | 說明 |
|---------|---------|------|
| `vehicle_description_i18n` | JSONB | 車型描述的多語言翻譯 |
| `capacity_info_i18n` | JSONB | 內容描述的多語言翻譯 |

### 2. 資料結構範例

```json
{
  "zh-TW": "CAMRY 等車型",
  "en": "CAMRY and similar models",
  "ja": "CAMRYなどの車種"
}
```

---

## 🚀 執行步驟

### 步驟 1：登入 Supabase Dashboard

1. 前往 [Supabase Dashboard](https://supabase.com/dashboard)
2. 選擇專案：`vlyhwegpvpnjyocqmfqc`
3. 點擊左側選單的 **SQL Editor**

### 步驟 2：執行 Migration SQL

1. 點擊 **New Query** 按鈕
2. 複製 `20251220_add_i18n_to_vehicle_pricing.sql` 的完整內容
3. 貼上到 SQL Editor
4. 點擊 **Run** 按鈕執行

### 步驟 3：驗證執行結果

執行成功後，您會看到類似以下的輸出：

```
========================================
Vehicle Pricing i18n Migration 驗證結果
========================================
vehicle_description_i18n 欄位存在: true
capacity_info_i18n 欄位存在: true
vehicle_pricing 表總記錄數: 8
已遷移多語言資料的記錄數: 8
✅ 所有記錄已成功遷移到多語言格式
========================================
```

### 步驟 4：檢查範例資料

Migration 會自動顯示前 3 筆記錄，確認資料遷移正確：

```
id | vehicle_type | vehicle_description | vehicle_description_i18n | capacity_info | capacity_info_i18n
```

---

## ✅ 驗證清單

執行完成後，請確認以下項目：

- [ ] `vehicle_description_i18n` 欄位已成功添加
- [ ] `capacity_info_i18n` 欄位已成功添加
- [ ] GIN 索引已成功創建
- [ ] 所有現有記錄的 `vehicle_description` 已遷移到 `vehicle_description_i18n['zh-TW']`
- [ ] 所有現有記錄的 `capacity_info` 已遷移到 `capacity_info_i18n['zh-TW']`
- [ ] 驗證輸出顯示「✅ 所有記錄已成功遷移到多語言格式」

---

## 🔄 回滾 (Rollback)

如果需要回滾此 Migration，執行以下 SQL：

```sql
-- 移除多語言欄位
ALTER TABLE vehicle_pricing DROP COLUMN IF EXISTS vehicle_description_i18n;
ALTER TABLE vehicle_pricing DROP COLUMN IF EXISTS capacity_info_i18n;

-- 移除索引
DROP INDEX IF EXISTS idx_vehicle_pricing_vehicle_description_i18n;
DROP INDEX IF EXISTS idx_vehicle_pricing_capacity_info_i18n;
```

---

## 📝 後續步驟

Migration 執行成功後：

1. **部署後端 API**：Railway 會自動部署新版本
2. **測試 API**：使用不同語言參數測試 `/api/pricing/packages?lang=en`
3. **更新 Web Admin**：在編輯對話框中添加多語言翻譯
4. **測試 Mobile App**：切換手機系統語言驗證功能

---

## 🆘 常見問題

### Q1: Migration 執行失敗怎麼辦？

**A**: 檢查錯誤訊息，常見原因：
- 欄位已存在：可能已執行過 Migration
- 權限不足：確認使用 Service Role Key
- 語法錯誤：確認複製完整 SQL 內容

### Q2: 如何確認 Migration 是否已執行？

**A**: 執行以下 SQL 查詢：

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'vehicle_pricing' 
  AND column_name IN ('vehicle_description_i18n', 'capacity_info_i18n');
```

如果返回 2 筆記錄，表示 Migration 已執行。

### Q3: 現有資料會遺失嗎？

**A**: 不會。Migration 會保留原始的 `vehicle_description` 和 `capacity_info` 欄位，並將其複製到多語言欄位的 `zh-TW` 鍵中。

---

## 📞 需要協助？

如果遇到問題，請：
1. 檢查 Supabase SQL Editor 的錯誤訊息
2. 確認資料庫連線正常
3. 聯繫開發團隊

---

**執行時間**：約 1-2 分鐘  
**影響範圍**：`vehicle_pricing` 表  
**向後兼容**：是（保留原始欄位）

