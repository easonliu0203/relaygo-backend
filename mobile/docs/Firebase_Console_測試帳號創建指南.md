# Firebase Console 測試帳號創建指南

## 🎯 **目標**
在 Firebase Console 中手動創建 Relay GO 應用程式的測試帳號，解決自動創建功能被 Firebase 安全機制阻止的問題。

## 📋 **需要創建的測試帳號**

### **客戶端測試帳號**
- **Email**: `customer.test@relaygo.com`
- **Password**: `RelayGO2024!Customer`
- **顯示名稱**: `測試客戶`

### **司機端測試帳號**
- **Email**: `driver.test@relaygo.com`
- **Password**: `RelayGO2024!Driver`
- **顯示名稱**: `測試司機`

## 🔧 **操作步驟**

### **步驟 1: 登入 Firebase Console**
1. 開啟瀏覽器，前往 [Firebase Console](https://console.firebase.google.com/)
2. 使用您的 Google 帳號登入
3. 選擇專案：`ride-platform-f1676`

### **步驟 2: 進入 Authentication 設定**
1. 在左側選單中點擊 **"Authentication"**
2. 點擊頂部的 **"Users"** 分頁
3. 您會看到目前的用戶列表（可能為空）

### **步驟 3: 創建客戶端測試帳號**
1. 點擊 **"Add user"** 按鈕
2. 在彈出的對話框中填入：
   - **Email**: `customer.test@relaygo.com`
   - **Password**: `RelayGO2024!Customer`
3. 點擊 **"Add user"** 確認創建
4. 創建成功後，您會在用戶列表中看到新帳號

### **步驟 4: 設定客戶端帳號顯示名稱**
1. 點擊剛創建的 `customer.test@relaygo.com` 帳號
2. 在用戶詳情頁面中，找到 **"Display name"** 欄位
3. 點擊編輯按鈕，輸入：`測試客戶`
4. 點擊儲存

### **步驟 5: 創建司機端測試帳號**
1. 回到 Users 列表頁面
2. 再次點擊 **"Add user"** 按鈕
3. 在彈出的對話框中填入：
   - **Email**: `driver.test@relaygo.com`
   - **Password**: `RelayGO2024!Driver`
4. 點擊 **"Add user"** 確認創建

### **步驟 6: 設定司機端帳號顯示名稱**
1. 點擊剛創建的 `driver.test@relaygo.com` 帳號
2. 在用戶詳情頁面中，找到 **"Display name"** 欄位
3. 點擊編輯按鈕，輸入：`測試司機`
4. 點擊儲存

## ✅ **驗證創建結果**

### **檢查用戶列表**
創建完成後，您應該在 Authentication > Users 頁面看到：

```
📧 customer.test@relaygo.com
   👤 測試客戶
   🔐 Email/Password
   📅 [創建日期]

📧 driver.test@relaygo.com
   👤 測試司機
   🔐 Email/Password
   📅 [創建日期]
```

### **測試登入功能**
1. 啟動 Relay GO 客戶端應用程式
2. 點擊「使用測試帳號」按鈕
3. 點擊「登入」按鈕
4. 應該能成功登入並進入主頁面

## 🔧 **可能遇到的問題**

### **問題 1: 密碼強度不足**
**錯誤**: "Password should be at least 6 characters"
**解決**: 確保密碼符合 Firebase 要求（至少 6 個字符）

### **問題 2: Email 格式錯誤**
**錯誤**: "The email address is badly formatted"
**解決**: 檢查 Email 格式是否正確

### **問題 3: 帳號已存在**
**錯誤**: "The email address is already in use"
**解決**: 該帳號已存在，可以直接使用或刪除後重新創建

### **問題 4: 權限不足**
**錯誤**: "Permission denied"
**解決**: 確保您有 Firebase 專案的管理員權限

## 🚀 **測試流程**

### **客戶端應用程式測試**
```bash
# 啟動客戶端應用程式
flutter run --flavor customer --target lib/apps/customer/main_customer.dart

# 測試步驟：
# 1. 點擊「使用測試帳號」
# 2. 驗證自動填入：customer.test@relaygo.com
# 3. 點擊「登入」
# 4. 確認成功進入主頁面
```

### **司機端應用程式測試**
```bash
# 啟動司機端應用程式
flutter run --flavor driver --target lib/apps/driver/main_driver.dart

# 測試步驟：
# 1. 點擊「使用測試帳號」
# 2. 驗證自動填入：driver.test@relaygo.com
# 3. 點擊「登入」
# 4. 確認成功進入主頁面
```

## 📱 **預期結果**

### **成功登入後應該看到**
- **客戶端**: 藍色主題的三分頁導覽（預約叫車、聊天、個人檔案）
- **司機端**: 綠色主題的三分頁導覽（接單管理、聊天、個人檔案）

### **登入失敗的可能原因**
1. 帳號創建不成功
2. 密碼輸入錯誤
3. Firebase 仍在封鎖請求
4. 網路連接問題

## 🔄 **後續維護**

### **定期檢查**
- 確保測試帳號狀態正常
- 檢查是否有異常登入活動
- 更新密碼（如需要）

### **安全考量**
- 測試帳號僅用於開發環境
- 生產環境中應禁用測試帳號
- 定期審查測試帳號權限

## 📞 **技術支援**

如果在創建過程中遇到問題：
1. 檢查 Firebase 專案權限
2. 確認網路連接正常
3. 查看 Firebase Console 錯誤訊息
4. 參考 Firebase Authentication 官方文檔

---

**創建指南版本**: v1.0  
**適用專案**: ride-platform-f1676  
**最後更新**: 2025-09-30 20:00
