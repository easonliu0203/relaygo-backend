# Relay GO Keystore 管理指南

## 🔐 **Keystore 檔案位置**

### **目錄結構**
```
mobile/
└── android/
    └── app/
        └── keystore/
            ├── customer/
            │   ├── customer-release.keystore
            │   └── key.properties
            └── driver/
                ├── driver-release.keystore
                └── key.properties
```

### **具體位置**
- **客戶端 Keystore**: `android/app/keystore/customer/customer-release.keystore`
- **客戶端配置**: `android/app/keystore/customer/key.properties`
- **司機端 Keystore**: `android/app/keystore/driver/driver-release.keystore`
- **司機端配置**: `android/app/keystore/driver/key.properties`

## 🛠️ **生成 Keystore**

### **自動生成 (推薦)**
```bash
# 執行自動生成腳本
scripts\generate-keystore.bat
```

### **手動生成**

#### **客戶端 Keystore**
```bash
keytool -genkey -v -keystore android/app/keystore/customer/customer-release.keystore \
    -alias customer-release \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000
```

#### **司機端 Keystore**
```bash
keytool -genkey -v -keystore android/app/keystore/driver/driver-release.keystore \
    -alias driver-release \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000
```

## 📝 **Key.properties 配置**

### **客戶端配置範例**
```properties
storePassword=your_customer_store_password
keyPassword=your_customer_key_password
keyAlias=customer-release
storeFile=customer-release.keystore
```

### **司機端配置範例**
```properties
storePassword=your_driver_store_password
keyPassword=your_driver_key_password
keyAlias=driver-release
storeFile=driver-release.keystore
```

## 🏗️ **建置配置**

### **build.gradle.kts 配置**
系統已自動配置以下功能：
- 自動載入不同 flavor 的 keystore 配置
- 為每個應用程式使用獨立的簽名配置
- Release 建置時自動應用正確的 keystore

### **建置命令**
```bash
# 建置客戶端 Release APK
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --release

# 建置司機端 Release APK
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --release

# 建置 App Bundle (Google Play)
flutter build appbundle --flavor customer --target lib/apps/customer/main_customer.dart --release
flutter build appbundle --flavor driver --target lib/apps/driver/main_driver.dart --release
```

## 🔍 **驗證 Keystore**

### **檢查 Keystore 資訊**
```bash
# 檢查客戶端 keystore
keytool -list -v -keystore android/app/keystore/customer/customer-release.keystore

# 檢查司機端 keystore
keytool -list -v -keystore android/app/keystore/driver/driver-release.keystore
```

### **驗證 APK 簽名**
```bash
# 檢查 APK 簽名
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-customer-release.apk
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-driver-release.apk
```

## ⚠️ **安全注意事項**

### **重要提醒**
1. **絕對不要**將 keystore 檔案提交到版本控制系統
2. **絕對不要**在程式碼中硬編碼密碼
3. **務必**備份 keystore 檔案到安全位置
4. **務必**記錄所有密碼和 alias 資訊
5. **建議**使用強密碼 (至少 8 個字符，包含大小寫字母、數字和特殊字符)

### **備份建議**
- 將 keystore 檔案複製到多個安全位置
- 使用加密的雲端儲存服務備份
- 建立密碼管理記錄
- 定期檢查備份檔案的完整性

### **團隊協作**
- 只有發布管理員應該擁有 keystore 檔案
- 使用安全的方式分享 keystore (如加密的檔案傳輸)
- 建立 keystore 使用的標準作業程序
- 記錄 keystore 的使用歷史

## 🚨 **遺失 Keystore 的後果**

如果遺失 keystore 檔案：
- **無法更新**已發布到 Google Play 的應用程式
- **必須建立**新的應用程式列表
- **失去**所有現有用戶和評價
- **需要重新**進行應用程式審核

## 🔄 **Keystore 輪換**

### **何時需要輪換**
- Keystore 即將過期
- 懷疑 keystore 被洩露
- 組織安全政策要求

### **輪換步驟**
1. 生成新的 keystore
2. 使用 Google Play App Signing 進行遷移
3. 更新建置配置
4. 測試新的簽名配置

## 📋 **檢查清單**

### **設定完成檢查**
- [ ] 客戶端 keystore 檔案已生成
- [ ] 司機端 keystore 檔案已生成
- [ ] key.properties 檔案配置正確
- [ ] .gitignore 已更新以排除 keystore 檔案
- [ ] keystore 檔案已備份到安全位置
- [ ] 密碼和 alias 資訊已記錄
- [ ] Release 建置測試成功
- [ ] APK 簽名驗證通過

### **發布前檢查**
- [ ] 確認使用正確的 keystore
- [ ] 驗證應用程式簽名
- [ ] 檢查應用程式版本號
- [ ] 確認 Bundle ID 正確
- [ ] 測試安裝和運行

---

**保護好您的 keystore 檔案，它們是您應用程式的數位身份證！** 🔐
