@echo off
echo ========================================
echo Relay GO 應用程式測試腳本
echo ========================================
echo.

echo 1. 檢查 Flutter 環境...
flutter doctor --verbose
echo.

echo 2. 清理專案...
flutter clean
echo.

echo 3. 獲取依賴...
flutter pub get
echo.

echo 4. 分析程式碼...
flutter analyze
echo.

echo 5. 測試客戶端應用程式建置...
echo 建置客戶端 Debug APK...
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --debug
if %errorlevel% neq 0 (
    echo 客戶端建置失敗！
    pause
    exit /b 1
)
echo 客戶端建置成功！
echo.

echo 6. 測試司機端應用程式建置...
echo 建置司機端 Debug APK...
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --debug
if %errorlevel% neq 0 (
    echo 司機端建置失敗！
    pause
    exit /b 1
)
echo 司機端建置成功！
echo.

echo ========================================
echo 所有測試完成！
echo ========================================
echo.
echo 建置檔案位置：
echo 客戶端：build\app\outputs\flutter-apk\app-customer-debug.apk
echo 司機端：build\app\outputs\flutter-apk\app-driver-debug.apk
echo.

pause
