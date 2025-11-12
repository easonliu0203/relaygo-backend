# 測試司機帳號創建 - 快速指南

## 📋 問題描述

在測試司機配對功能時，發現「手動派單」對話框中顯示「沒有可用司機」。

**原因**: 資料庫中沒有測試司機帳號。

---

## 🚀 快速修復

### 方法 1: 使用自動化腳本（推薦）

**步驟**:
```bash
# 1. 進入 web-admin 目錄
cd web-admin

# 2. 執行創建腳本
node ../supabase/scripts/create-test-driver.js
```

**預期輸出**:
```
=== 檢查現有用戶 ===
找到 3 位用戶:
   1. test_idempotent@example.com (customer)
   2. hUu4fH5dTlW9VUYm6GojXvRLdni2@temp.com (customer)
   3. driver.test@gelaygo.com (driver)

=== 創建測試司機帳號 ===
1️⃣ 檢查用戶是否已存在...
✅ 用戶已存在

2️⃣ 處理 user_profiles...
✅ 已更新 user_profile

3️⃣ 處理 drivers...
✅ 已創建 driver 記錄

=== 驗證測試司機帳號 ===
✅ 測試司機帳號已完全設置！
```

### 方法 2: 使用 SQL 腳本

**步驟**:
1. 連接到 Supabase 資料庫
2. 執行 `supabase/scripts/fix_driver_test_account.sql`

---

## 📊 測試司機帳號資訊

創建成功後，系統中會有以下測試司機帳號：

| 項目 | 值 |
|------|-----|
| **Email** | driver.test@gelaygo.com |
| **Password** | Test123456! |
| **姓名** | 測試 司機 |
| **電話** | 0912345678 |
| **車型** | A (豪華9人座) |
| **車牌** | TEST-001 |
| **車款** | Toyota Alphard |
| **駕照號碼** | TEST-LICENSE-001 |
| **駕照到期** | 一年後 |
| **可用狀態** | true ✅ |
| **評分** | 5.0 ⭐ |
| **總趟次** | 0 |

---

## ✅ 驗證步驟

### 1. 驗證資料庫記錄

**SQL 查詢**:
```sql
SELECT 
  u.email,
  u.role,
  up.first_name,
  up.last_name,
  up.phone,
  d.vehicle_type,
  d.vehicle_plate,
  d.is_available
FROM users u
LEFT JOIN user_profiles up ON up.user_id = u.id
LEFT JOIN drivers d ON d.user_id = u.id
WHERE u.email = 'driver.test@gelaygo.com';
```

**預期結果**:
| email | role | first_name | last_name | phone | vehicle_type | vehicle_plate | is_available |
|-------|------|------------|-----------|-------|--------------|---------------|--------------|
| driver.test@gelaygo.com | driver | 測試 | 司機 | 0912345678 | A | TEST-001 | true |

### 2. 測試 API 查詢

**請求**:
```bash
curl "http://localhost:3001/api/admin/drivers/available?vehicleType=A"
```

**預期響應**:
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "name": "測試 司機",
      "phone": "0912345678",
      "email": "driver.test@gelaygo.com",
      "vehicleType": "A",
      "vehiclePlate": "TEST-001",
      "vehicleModel": "Toyota Alphard",
      "isAvailable": true,
      "rating": 5,
      "totalTrips": 0,
      "currentBookings": 0,
      "hasConflict": false
    }
  ],
  "total": 1,
  "availableCount": 1
}
```

### 3. 測試手動派單功能

**步驟**:
1. 訪問 http://localhost:3001/orders/pending
2. 點擊訂單的「手動派單」按鈕（👤 圖標）
3. 查看司機選擇對話框

**預期結果**:
- ✅ 對話框顯示司機列表
- ✅ 列表中包含「測試 司機」
- ✅ 司機狀態顯示為「可用」（綠色 Tag）
- ✅ 可以點擊「選擇」按鈕進行派單

---

## 🐛 常見問題

### 問題 1: 腳本執行失敗

**錯誤**:
```
Error: Cannot find module '@supabase/supabase-js'
```

**解決**:
```bash
# 確保在 web-admin 目錄執行
cd web-admin
node ../supabase/scripts/create-test-driver.js
```

### 問題 2: 用戶已存在但沒有 driver 記錄

**現象**: 腳本顯示用戶已存在，但創建 driver 失敗

**解決**:
1. 重新執行腳本（腳本會自動更新現有記錄）
2. 或手動刪除用戶後重新執行

**刪除用戶**:
```sql
DELETE FROM users WHERE email = 'driver.test@gelaygo.com';
```

### 問題 3: 司機列表仍然顯示「沒有可用司機」

**檢查清單**:
- [ ] 確認 `users.role = 'driver'`
- [ ] 確認 `drivers.is_available = true`
- [ ] 確認 `drivers.vehicle_type` 已設定
- [ ] 確認 `user_profiles` 記錄存在
- [ ] 重新整理瀏覽器頁面

**診斷命令**:
```bash
cd web-admin
node ../supabase/scripts/diagnose-and-fix-driver.js
```

---

## 📁 相關文件

### 腳本文件

- `supabase/scripts/create-test-driver.js` - 創建測試司機帳號（推薦）
- `supabase/scripts/diagnose-and-fix-driver.js` - 診斷並修復
- `supabase/scripts/diagnose_driver_test_account.sql` - SQL 診斷腳本
- `supabase/scripts/fix_driver_test_account.sql` - SQL 修復腳本

### 文檔

- `docs/20251010_0346_26_測試司機帳號創建問題修復.md` - 詳細開發歷程

---

## 💡 使用建議

### 開發環境初始化

**建議**: 在新的開發環境中，首先執行創建測試司機腳本

**步驟**:
```bash
# 1. 克隆專案
git clone <repository>

# 2. 安裝依賴
cd web-admin
npm install

# 3. 創建測試司機
node ../supabase/scripts/create-test-driver.js

# 4. 啟動服務
npm run dev
```

### 測試資料管理

**建議**: 定期檢查測試資料的完整性

**檢查命令**:
```bash
cd web-admin
node ../supabase/scripts/diagnose-and-fix-driver.js
```

### 多個測試司機

**需求**: 如果需要創建多個測試司機

**方法**: 修改腳本中的 `TEST_DRIVER_EMAIL` 變數

**示例**:
```javascript
// 創建第二個測試司機
const TEST_DRIVER_EMAIL = 'driver.test2@gelaygo.com';
const TEST_DRIVER_DATA = {
  first_name: '測試2',
  last_name: '司機',
  phone: '0923456789',
  vehicle_type: 'B',  // 標準8人座
  vehicle_plate: 'TEST-002'
};
```

---

## 🎯 測試場景

### 場景 1: 手動派單（無衝突）

**前置條件**:
- ✅ 測試司機帳號已創建
- ✅ 測試司機狀態為可用
- ✅ 有未分配司機的訂單

**測試步驟**:
1. 訪問待處理訂單頁面
2. 點擊「手動派單」按鈕
3. 選擇「測試 司機」
4. 點擊「選擇」按鈕

**預期結果**:
- ✅ 成功分配司機
- ✅ 顯示成功訊息
- ✅ 訂單列表更新

### 場景 2: 自動派單

**前置條件**:
- ✅ 測試司機帳號已創建
- ✅ 有多個未分配司機的訂單

**測試步驟**:
1. 訪問待處理訂單頁面
2. 點擊「自動派單」按鈕
3. 確認對話框

**預期結果**:
- ✅ 自動分配訂單給測試司機
- ✅ 顯示分配結果統計
- ✅ 訂單列表更新

### 場景 3: 時間衝突檢查

**前置條件**:
- ✅ 測試司機已有一個訂單
- ✅ 新訂單時間與現有訂單重疊

**測試步驟**:
1. 點擊新訂單的「手動派單」按鈕
2. 查看測試司機的狀態

**預期結果**:
- ✅ 測試司機標記為「時間衝突」（紅色）
- ✅ 選擇按鈕被禁用
- ✅ 無法選擇該司機

---

## 📝 注意事項

### 1. 測試資料隔離

**重要**: 測試司機帳號僅用於開發和測試環境

**建議**:
- ❌ 不要在生產環境使用測試帳號
- ✅ 使用明確的測試標識（如 TEST- 前綴）
- ✅ 定期清理測試資料

### 2. 資料完整性

**重要**: 確保所有關聯表都有對應記錄

**檢查清單**:
- [ ] `users` 表有記錄
- [ ] `user_profiles` 表有記錄
- [ ] `drivers` 表有記錄
- [ ] 所有必填欄位都已填寫

### 3. 權限管理

**重要**: 測試帳號應該有適當的權限

**建議**:
- ✅ 確保 `role = 'driver'`
- ✅ 確保 `is_available = true`
- ✅ 確保 `background_check_status = 'approved'`

---

## 🎉 總結

### 快速開始

```bash
# 一鍵創建測試司機
cd web-admin && node ../supabase/scripts/create-test-driver.js
```

### 測試帳號

- **Email**: driver.test@gelaygo.com
- **Password**: Test123456!

### 驗證

訪問 http://localhost:3001/orders/pending 並點擊「手動派單」

---

**需要幫助?**
- 詳細文檔: `docs/20251010_0346_26_測試司機帳號創建問題修復.md`
- 問題回報: 請聯繫開發團隊

**創建時間**: 2025-10-10 03:46  
**版本**: 1.0.0

