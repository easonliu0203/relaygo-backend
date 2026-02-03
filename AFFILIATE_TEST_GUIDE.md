# 客戶推廣人系統測試指南

## 📋 測試帳號資訊

- **Email**: `customer.test@relaygo.com`
- **Firebase UID**: `hUu4fH5dTlW9VUYm6GojXvRLdni2`
- **PostgreSQL UUID**: `c03f0310-d3c8-44ab-8aec-1a4a858c52cb`

---

## 🧹 完整資料清理步驟

### 1. 清理推廣人記錄

```sql
-- 刪除推廣人記錄
DELETE FROM influencers 
WHERE user_id = 'c03f0310-d3c8-44ab-8aec-1a4a858c52cb' 
AND affiliate_type = 'customer_affiliate';
```

### 2. 清理推薦記錄（如果有）

```sql
-- 刪除推薦記錄
DELETE FROM referrals 
WHERE referrer_id = 'c03f0310-d3c8-44ab-8aec-1a4a858c52cb';
```

### 3. 清理推薦碼使用記錄（如果有）

```sql
-- 刪除推薦碼使用記錄
DELETE FROM promo_code_usage 
WHERE influencer_id IN (
  SELECT id FROM influencers 
  WHERE user_id = 'c03f0310-d3c8-44ab-8aec-1a4a858c52cb'
);
```

### 4. 驗證清理結果

```sql
-- 檢查推廣人記錄
SELECT * FROM influencers 
WHERE user_id = 'c03f0310-d3c8-44ab-8aec-1a4a858c52cb';

-- 應該返回空結果
```

---

## 🧪 完整測試流程

### 階段 1：申請推廣人

1. **在 Flutter 客戶端**：
   - 登入 `customer.test@relaygo.com`
   - 前往「個人檔案 → 申請成為推廣人」
   - ✅ 應該顯示申請表單（不是狀態視圖）

2. **填寫申請表單**：
   - 輸入推薦碼：`TEST123ABC`（或其他符合格式的代碼）
   - 點擊「提交申請」

3. **驗證申請成功**：
   - ✅ 顯示成功訊息
   - ✅ 頁面自動切換到狀態視圖
   - ✅ 顯示「待審核」狀態（橙色）

4. **驗證資料庫**：
   ```sql
   SELECT id, promo_code, affiliate_status, is_active 
   FROM influencers 
   WHERE user_id = 'c03f0310-d3c8-44ab-8aec-1a4a858c52cb';
   ```
   預期結果：
   - `affiliate_status`: `pending`
   - `is_active`: `false`

---

### 階段 2：審核申請

1. **在 Web Admin 管理後台**：
   - 前往「廣告與行銷 → 客戶推廣人管理」
   - ✅ 應該看到 `customer.test@relaygo.com` 的申請記錄
   - 狀態：待審核

2. **審核通過**：
   - 點擊「審核」按鈕
   - 選擇「✅ 通過申請」
   - 填寫審核備註（選填）
   - 點擊「確定」

3. **驗證審核成功**：
   - ✅ 顯示「審核成功」訊息
   - ✅ 狀態變為「已啟用」

4. **驗證資料庫**：
   ```sql
   SELECT affiliate_status, is_active, reviewed_at 
   FROM influencers 
   WHERE user_id = 'c03f0310-d3c8-44ab-8aec-1a4a858c52cb';
   ```
   預期結果：
   - `affiliate_status`: `active`
   - `is_active`: `true`
   - `reviewed_at`: 當前時間

---

### 階段 3：測試狀態同步

1. **在 Flutter 客戶端**：
   - 重新進入「申請成為推廣人」頁面
   - ✅ 應該顯示「已啟用」狀態（綠色）
   - ✅ 顯示推薦碼
   - ✅ 顯示統計數據（推薦人數、總收益）
   - ✅ 顯示推廣說明

2. **在 Web Admin 停用推廣人**：
   - 點擊「編輯」按鈕
   - 將「啟用狀態」設為「停用」
   - 點擊「確定」

3. **在 Flutter 客戶端驗證**：
   - 重新進入「申請成為推廣人」頁面
   - ✅ 應該顯示「已停用」狀態（灰色）
   - ❌ 不顯示統計數據
   - ❌ 不顯示推廣說明

4. **在 Web Admin 重新啟用**：
   - 將「啟用狀態」設為「啟用」
   - 點擊「確定」

5. **在 Flutter 客戶端驗證**：
   - 重新進入頁面
   - ✅ 應該顯示「已啟用」狀態（綠色）

---

## 🔍 API 測試腳本

### 測試狀態 API

```bash
node test-status-api.js
```

預期輸出（未申請時）：
```json
{
  "success": true,
  "data": {
    "is_affiliate": false,
    "status": null
  }
}
```

預期輸出（已申請時）：
```json
{
  "success": true,
  "data": {
    "is_affiliate": true,
    "affiliate_status": "active",
    "is_active": true,
    "promo_code": "TEST123ABC",
    "total_referrals": 0,
    "total_earnings": 0
  }
}
```

---

## 📊 狀態對照表

| affiliate_status | is_active | 客戶端顯示 | 顏色 | 圖示 |
|-----------------|-----------|-----------|------|------|
| `pending` | `false` | 待審核 | 橙色 | ⏳ |
| `active` | `true` | 已啟用 | 綠色 | ✅ |
| `active` | `false` | 已停用 | 灰色 | 🚫 |
| `rejected` | `false` | 已拒絕 | 紅色 | ❌ |

---

## ⚠️ 常見問題

### Q1: 刪除資料後，客戶端仍顯示「待審核」狀態？

**原因**: Flutter 應用可能有緩存

**解決方案**:
1. 完全關閉並重新啟動 Flutter 應用
2. 或者清除應用數據（設定 → 應用 → RelayGo → 清除數據）

### Q2: API 返回 `is_affiliate: false`，但客戶端仍顯示狀態視圖？

**原因**: 舊版本代碼的 bug（已修復）

**解決方案**: 重新編譯 Flutter 應用

### Q3: 推薦碼格式要求？

**格式**: 6-20 個字符，必須包含至少一個字母和一個數字

**有效範例**:
- `TEST123ABC` ✅
- `PROMO2024` ✅
- `ABC123` ✅

**無效範例**:
- `TEST` ❌ (太短)
- `123456` ❌ (沒有字母)
- `ABCDEF` ❌ (沒有數字)

---

## 🎯 測試檢查清單

- [ ] 資料庫已清理乾淨
- [ ] API 返回 `is_affiliate: false`
- [ ] 客戶端顯示申請表單
- [ ] 可以成功提交申請
- [ ] 管理後台可以看到申請記錄
- [ ] 可以審核通過申請
- [ ] 客戶端狀態同步為「已啟用」
- [ ] 可以停用推廣人
- [ ] 客戶端狀態同步為「已停用」
- [ ] 可以重新啟用推廣人
- [ ] 客戶端狀態同步為「已啟用」

