@echo off
echo ========================================
echo Relay GO 認證系統測試腳本
echo ========================================
echo.

echo 📱 測試客戶端和司機端應用程式的認證功能
echo.

echo 🔍 檢查 Flutter 環境...
flutter --version
if %errorlevel% neq 0 (
    echo ❌ Flutter 未安裝或未加入 PATH
    pause
    exit /b 1
)
echo.

echo 🔍 檢查專案依賴...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ 依賴安裝失敗
    pause
    exit /b 1
)
echo.

echo 🔍 執行程式碼分析...
flutter analyze
echo.

echo 🏗️ 建置客戶端應用程式...
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --debug
if %errorlevel% neq 0 (
    echo ❌ 客戶端建置失敗
    pause
    exit /b 1
)
echo ✅ 客戶端建置成功
echo.

echo 🏗️ 建置司機端應用程式...
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --debug
if %errorlevel% neq 0 (
    echo ❌ 司機端建置失敗
    pause
    exit /b 1
)
echo ✅ 司機端建置成功
echo.

echo 📋 建置結果摘要:
echo ✅ 客戶端 APK: build\app\outputs\flutter-apk\app-customer-debug.apk
echo ✅ 司機端 APK: build\app\outputs\flutter-apk\app-driver-debug.apk
echo.

echo 🧪 測試帳號資訊:
echo 📧 客戶端測試帳號: customer.test@relaygo.com
echo 🔑 密碼: RelayGO2024!Customer
echo.
echo 📧 司機端測試帳號: driver.test@relaygo.com  
echo 🔑 密碼: RelayGO2024!Driver
echo.

echo 📱 手動測試步驟:
echo 1. 安裝客戶端 APK 到 Android 設備
echo 2. 安裝司機端 APK 到 Android 設備（或另一台設備）
echo 3. 開啟客戶端應用程式，點擊「使用測試帳號」
echo 4. 驗證自動填入的測試帳號資訊
echo 5. 點擊「登入」測試認證流程
echo 6. 驗證三個分頁導覽功能
echo 7. 重複步驟 3-6 測試司機端應用程式
echo.

echo 🎉 所有建置測試完成！
echo 現在可以開始手動測試認證功能。
echo.

pause
