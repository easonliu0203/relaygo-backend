# Relay GO 開發者快速指南

## 🚀 **快速開始**

### **1. 設定 Firebase 配置**
```bash
# Windows
scripts\setup-firebase-config.bat

# Linux/Mac
./scripts/setup-firebase-config.sh
```

### **2. 執行應用程式**
```bash
# 客戶端
scripts\run-customer.bat
# 或
flutter run --flavor customer --target lib/apps/customer/main_customer.dart

# 司機端
scripts\run-driver.bat
# 或
flutter run --flavor driver --target lib/apps/driver/main_driver.dart
```

### **3. 建置 Release 版本**
```bash
# 建置所有 Release 版本
scripts\build-release.bat
```

## 📱 **應用程式資訊**

### **客戶端 (Relay GO)**
- **Android Package**: `com.relaygo.customer`
- **iOS Bundle ID**: `com.relaygo.customer.ios`
- **主題色彩**: 藍色 (#2196F3)
- **入口檔案**: `lib/apps/customer/main_customer.dart`

### **司機端 (Relay GO Driver)**
- **Android Package**: `com.relaygo.driver`
- **iOS Bundle ID**: `com.relaygo.driver.ios`
- **主題色彩**: 綠色 (#4CAF50)
- **入口檔案**: `lib/apps/driver/main_driver.dart`

## 🏗️ **專案結構**

```
lib/
├── apps/                    # 應用程式特定程式碼
│   ├── customer/           # 客戶端
│   │   ├── main_customer.dart
│   │   └── presentation/
│   └── driver/             # 司機端
│       ├── main_driver.dart
│       └── presentation/
├── core/                   # 核心功能
│   ├── config/
│   ├── services/
│   ├── theme/
│   └── l10n/
└── shared/                 # 共用程式碼
    ├── providers/
    └── presentation/
```

## 🔧 **開發工具**

### **VS Code 配置**
- 使用 F5 或 Ctrl+F5 啟動除錯
- 選擇 "Customer App (Debug)" 或 "Driver App (Debug)"

### **常用命令**
```bash
# 獲取依賴項
flutter pub get

# 生成程式碼
flutter packages pub run build_runner build

# 清理建置
flutter clean

# 檢查程式碼
flutter analyze

# 執行測試
flutter test

# 測試 keystore 配置
scripts\test-keystore.bat
```

### **Keystore 管理**
```bash
# 生成 keystore 檔案
scripts\generate-keystore.bat

# 檢查 keystore 資訊
keytool -list -keystore android/app/keystore/customer/Relay-GO.jks
keytool -list -keystore android/app/keystore/driver/Relay-GO-driver.jks

# 驗證 APK 簽名
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-customer-release.apk
```

## 🔥 **Firebase 配置檔案位置**

### **Android**
```
android/app/src/customer/google-services.json    # 客戶端
android/app/src/driver/google-services.json      # 司機端
```

### **iOS**
```
ios/Runner/Customer/GoogleService-Info.plist     # 客戶端
ios/Runner/Driver/GoogleService-Info.plist       # 司機端
```

## 📋 **建置命令參考**

### **Debug 建置**
```bash
# Android APK
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --debug
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --debug

# iOS
flutter build ios --flavor customer --target lib/apps/customer/main_customer.dart --debug
flutter build ios --flavor driver --target lib/apps/driver/main_driver.dart --debug
```

### **Release 建置**
```bash
# Android APK
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --release
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --release

# Android App Bundle (Google Play)
flutter build appbundle --flavor customer --target lib/apps/customer/main_customer.dart --release
flutter build appbundle --flavor driver --target lib/apps/driver/main_driver.dart --release

# iOS
flutter build ios --flavor customer --target lib/apps/customer/main_customer.dart --release
flutter build ios --flavor driver --target lib/apps/driver/main_driver.dart --release
```

## 🧪 **測試**

### **單元測試**
```bash
flutter test
```

### **整合測試**
```bash
flutter drive --flavor customer --target test_driver/app.dart
flutter drive --flavor driver --target test_driver/app.dart
```

## 🔍 **除錯技巧**

### **常見問題**
1. **Firebase 配置錯誤**: 檢查配置檔案路徑和內容
2. **建置失敗**: 執行 `flutter clean` 後重新建置
3. **依賴項衝突**: 執行 `flutter pub deps` 檢查依賴關係

### **日誌查看**
```bash
# 查看應用程式日誌
flutter logs

# 查看特定設備日誌
flutter logs -d <device_id>
```

## 📚 **相關文檔**

- [Firebase 配置指南](firebase-config-guide.md)
- [多應用程式架構指南](../docs/20250928_0600_08_多應用程式架構建立指南.md)
- [Flutter 官方文檔](https://flutter.dev/docs)
- [Firebase 官方文檔](https://firebase.google.com/docs)

## 🆘 **獲得幫助**

- 檢查 Firebase Console 設定
- 查看 Flutter Doctor: `flutter doctor`
- 檢查設備連接: `flutter devices`
- 查看詳細錯誤: `flutter run -v`

---

**快樂編程！** 🎉
