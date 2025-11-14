# Firebase 配置檔案放置指南 - Relay GO

## 📱 **Android 配置檔案放置**

### **客戶端應用程式 (Relay GO)**
- **套件名稱**: `com.relaygo.customer`
- **應用程式暱稱**: Relay GO
1. 從 Firebase Console 下載客戶端應用程式的 `google-services.json`
2. 將檔案放置到：
   ```
   mobile/android/app/src/customer/google-services.json
   ```

### **司機端應用程式 (Relay GO Driver)**
- **套件名稱**: `com.relaygo.driver`
- **應用程式暱稱**: Relay GO D
1. 從 Firebase Console 下載司機端應用程式的 `google-services.json`
2. 將檔案放置到：
   ```
   mobile/android/app/src/driver/google-services.json
   ```

## 🍎 **iOS 配置檔案放置**

### **客戶端應用程式 (Relay GO)**
- **軟體包 ID**: `com.relaygo.customer.ios`
- **應用程式暱稱**: Relay GO I
1. 從 Firebase Console 下載客戶端應用程式的 `GoogleService-Info.plist`
2. 將檔案放置到：
   ```
   mobile/ios/Runner/Customer/GoogleService-Info.plist
   ```

### **司機端應用程式 (Relay GO Driver)**
- **軟體包 ID**: `com.relaygo.driver.ios`
- **應用程式暱稱**: Relay GO D I
1. 從 Firebase Console 下載司機端應用程式的 `GoogleService-Info.plist`
2. 將檔案放置到：
   ```
   mobile/ios/Runner/Driver/GoogleService-Info.plist
   ```

## 🔧 **建置命令**

### **開發環境執行**
```bash
# 客戶端
flutter run --flavor customer --target lib/apps/customer/main_customer.dart

# 司機端
flutter run --flavor driver --target lib/apps/driver/main_driver.dart
```

### **建置 APK**
```bash
# 客戶端
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart

# 司機端
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart
```

## 📋 **應用程式識別**

### **Android**
- **客戶端**: `com.relaygo.customer` (Relay GO)
- **司機端**: `com.relaygo.driver` (Relay GO Driver)

### **iOS**
- **客戶端**: `com.relaygo.customer.ios` (Relay GO)
- **司機端**: `com.relaygo.driver.ios` (Relay GO Driver)

## ⚠️ **注意事項**

1. **Bundle ID 一致性**: 確保 Firebase Console 中的應用程式 Bundle ID 與 Flavors 配置完全一致
2. **獨立配置檔案**: 每個應用程式需要獨立的 Firebase 配置檔案，不可共用
3. **路徑準確性**: 配置檔案放置路徑必須完全正確，否則建置會失敗
4. **檔案名稱**: 配置檔案名稱必須保持原始名稱，不可重新命名
5. **iOS Schemes**: iOS 需要在 Xcode 中額外配置 Schemes（下方有詳細步驟）

## 📋 **詳細配置步驟**

### **步驟 1: 從 Firebase Console 下載配置檔案**

#### **Android 配置檔案**
1. 登入 [Firebase Console](https://console.firebase.google.com/)
2. 選擇您的專案
3. 點擊左側選單的 ⚙️ **專案設定**
4. 滾動到 **您的應用程式** 區域
5. 找到 **Android 應用程式 (com.relaygo.customer)**
6. 點擊 **下載 google-services.json**
7. 重複步驟 5-6 下載 **Android 應用程式 (com.relaygo.driver)** 的配置檔案

#### **iOS 配置檔案**
1. 在同一個 Firebase Console 頁面
2. 找到 **iOS 應用程式 (com.relaygo.customer.ios)**
3. 點擊 **下載 GoogleService-Info.plist**
4. 重複步驟 2-3 下載 **iOS 應用程式 (com.relaygo.driver.ios)** 的配置檔案

### **步驟 2: 放置 Android 配置檔案**

```bash
# 確保目錄存在
mkdir -p android/app/src/customer
mkdir -p android/app/src/driver

# 將下載的檔案複製到正確位置
# 客戶端配置檔案
cp ~/Downloads/google-services.json android/app/src/customer/

# 司機端配置檔案（重新命名下載的第二個檔案）
cp ~/Downloads/google-services(1).json android/app/src/driver/google-services.json
```

### **步驟 3: 放置 iOS 配置檔案**

```bash
# 確保目錄存在
mkdir -p ios/Runner/Customer
mkdir -p ios/Runner/Driver

# 將下載的檔案複製到正確位置
# 客戶端配置檔案
cp ~/Downloads/GoogleService-Info.plist ios/Runner/Customer/

# 司機端配置檔案（重新命名下載的第二個檔案）
cp ~/Downloads/GoogleService-Info(1).plist ios/Runner/Driver/GoogleService-Info.plist
```

### **步驟 4: iOS Xcode 配置**

#### **建立 iOS Schemes**
1. 打開 Xcode: `open ios/Runner.xcworkspace`
2. 在 Xcode 中，點擊頂部的 **Runner** scheme
3. 選擇 **Edit Scheme...**
4. 點擊左下角的 **+** 按鈕
5. 選擇 **Duplicate Scheme**
6. 將新 scheme 命名為 **Runner-Customer**
7. 重複步驟 4-6，建立 **Runner-Driver** scheme

#### **配置 Build Settings**
1. 選擇 **Runner** 專案
2. 選擇 **Runner** target
3. 點擊 **Build Settings** 標籤
4. 搜尋 **Product Bundle Identifier**
5. 為不同的 Configuration 設定不同的 Bundle ID：
   - Debug-Customer: `com.relaygo.customer.ios`
   - Debug-Driver: `com.relaygo.driver.ios`
   - Release-Customer: `com.relaygo.customer.ios`
   - Release-Driver: `com.relaygo.driver.ios`

## 🧪 **測試配置**

### **驗證 Android 配置**
```bash
# 測試客戶端建置
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --debug

# 測試司機端建置
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --debug
```

### **驗證 iOS 配置**
```bash
# 測試客戶端建置
flutter build ios --flavor customer --target lib/apps/customer/main_customer.dart --debug --no-codesign

# 測試司機端建置
flutter build ios --flavor driver --target lib/apps/driver/main_driver.dart --debug --no-codesign
```

## 🔍 **常見問題排除**

### **問題 1: "google-services.json not found"**
**解決方案**:
- 檢查檔案路徑是否正確
- 確認檔案名稱為 `google-services.json`
- 確認檔案在正確的 flavor 目錄中

### **問題 2: "GoogleService-Info.plist not found"**
**解決方案**:
- 檢查 iOS 配置檔案路徑
- 確認在 Xcode 中正確添加了檔案
- 確認檔案名稱為 `GoogleService-Info.plist`

### **問題 3: "Bundle identifier mismatch"**
**解決方案**:
- 檢查 Firebase Console 中的 Bundle ID
- 確認 `build.gradle.kts` 中的 applicationId 設定
- 確認 iOS Info.plist 中的 Bundle ID 設定

### **問題 4: Firebase 初始化失敗**
**解決方案**:
- 確認配置檔案內容正確
- 檢查網路連線
- 確認 Firebase 專案狀態正常

## 📱 **建置和發布**

### **Android 發布建置**
```bash
# 客戶端 Release APK
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --release

# 司機端 Release APK
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --release

# Android App Bundle (推薦用於 Google Play)
flutter build appbundle --flavor customer --target lib/apps/customer/main_customer.dart --release
flutter build appbundle --flavor driver --target lib/apps/driver/main_driver.dart --release
```

### **iOS 發布建置**
```bash
# 客戶端 Release IPA
flutter build ios --flavor customer --target lib/apps/customer/main_customer.dart --release

# 司機端 Release IPA
flutter build ios --flavor driver --target lib/apps/driver/main_driver.dart --release
```

## 🎯 **配置完成檢查清單**

- [ ] 從 Firebase Console 下載 4 個配置檔案
- [ ] Android 客戶端配置檔案放置正確
- [ ] Android 司機端配置檔案放置正確
- [ ] iOS 客戶端配置檔案放置正確
- [ ] iOS 司機端配置檔案放置正確
- [ ] 測試 Android 客戶端建置成功
- [ ] 測試 Android 司機端建置成功
- [ ] 測試 iOS 客戶端建置成功
- [ ] 測試 iOS 司機端建置成功
- [ ] Firebase 服務正常初始化
- [ ] 應用程式可以正常啟動

---

**配置完成後，您就可以開始開發 Relay GO 的具體功能了！** 🚀
