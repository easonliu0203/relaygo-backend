@echo off
setlocal

echo 🏗️ 建置 Relay GO Release 版本
echo ===============================

echo.
echo 📱 建置 Android APK...

echo 正在建置客戶端 APK...
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --release
if %errorlevel% neq 0 (
    echo ❌ 客戶端 APK 建置失敗
    pause
    exit /b 1
)

echo 正在建置司機端 APK...
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --release
if %errorlevel% neq 0 (
    echo ❌ 司機端 APK 建置失敗
    pause
    exit /b 1
)

echo.
echo 📦 建置 Android App Bundle...

echo 正在建置客戶端 AAB...
flutter build appbundle --flavor customer --target lib/apps/customer/main_customer.dart --release
if %errorlevel% neq 0 (
    echo ❌ 客戶端 AAB 建置失敗
    pause
    exit /b 1
)

echo 正在建置司機端 AAB...
flutter build appbundle --flavor driver --target lib/apps/driver/main_driver.dart --release
if %errorlevel% neq 0 (
    echo ❌ 司機端 AAB 建置失敗
    pause
    exit /b 1
)

echo.
echo 🎉 所有 Release 版本建置完成！
echo.
echo 📁 輸出檔案位置:
echo APK 檔案: build\app\outputs\flutter-apk\
echo AAB 檔案: build\app\outputs\bundle\
echo.

pause
