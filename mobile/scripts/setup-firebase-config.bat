@echo off
setlocal enabledelayedexpansion

:: Relay GO Firebase 配置設定腳本 (Windows)
:: 使用方法: scripts\setup-firebase-config.bat

echo.
echo 🔥 Relay GO Firebase 配置設定腳本
echo ==================================

:: 檢查是否在正確的目錄
if not exist "pubspec.yaml" (
    echo ❌ 錯誤: 請在 Flutter 專案根目錄執行此腳本
    pause
    exit /b 1
)

echo 📁 步驟 1: 建立目錄結構

:: 建立 Android 配置目錄
if not exist "android\app\src\customer" mkdir "android\app\src\customer"
if not exist "android\app\src\driver" mkdir "android\app\src\driver"

:: 建立 iOS 配置目錄
if not exist "ios\Runner\Customer" mkdir "ios\Runner\Customer"
if not exist "ios\Runner\Driver" mkdir "ios\Runner\Driver"

echo ✅ 目錄結構建立完成
echo.

echo 🔍 步驟 2: 檢查配置檔案

set ANDROID_CUSTOMER_CONFIG=android\app\src\customer\google-services.json
set ANDROID_DRIVER_CONFIG=android\app\src\driver\google-services.json
set IOS_CUSTOMER_CONFIG=ios\Runner\Customer\GoogleService-Info.plist
set IOS_DRIVER_CONFIG=ios\Runner\Driver\GoogleService-Info.plist

set EXISTING_CONFIGS=0

:: 檢查 Android 配置檔案
if exist "%ANDROID_CUSTOMER_CONFIG%" (
    echo ✅ Android 客戶端配置檔案已存在
    set /a EXISTING_CONFIGS+=1
) else (
    echo ⚠️  Android 客戶端配置檔案不存在: %ANDROID_CUSTOMER_CONFIG%
    echo    請從 Firebase Console 下載 com.relaygo.customer 的 google-services.json
)

if exist "%ANDROID_DRIVER_CONFIG%" (
    echo ✅ Android 司機端配置檔案已存在
    set /a EXISTING_CONFIGS+=1
) else (
    echo ⚠️  Android 司機端配置檔案不存在: %ANDROID_DRIVER_CONFIG%
    echo    請從 Firebase Console 下載 com.relaygo.driver 的 google-services.json
)

:: 檢查 iOS 配置檔案
if exist "%IOS_CUSTOMER_CONFIG%" (
    echo ✅ iOS 客戶端配置檔案已存在
    set /a EXISTING_CONFIGS+=1
) else (
    echo ⚠️  iOS 客戶端配置檔案不存在: %IOS_CUSTOMER_CONFIG%
    echo    請從 Firebase Console 下載 com.relaygo.customer.ios 的 GoogleService-Info.plist
)

if exist "%IOS_DRIVER_CONFIG%" (
    echo ✅ iOS 司機端配置檔案已存在
    set /a EXISTING_CONFIGS+=1
) else (
    echo ⚠️  iOS 司機端配置檔案不存在: %IOS_DRIVER_CONFIG%
    echo    請從 Firebase Console 下載 com.relaygo.driver.ios 的 GoogleService-Info.plist
)

echo.
echo 🧪 步驟 3: 測試建置

echo 正在測試 Android 客戶端建置...
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --debug >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Android 客戶端建置成功
) else (
    echo ❌ Android 客戶端建置失敗
)

echo 正在測試 Android 司機端建置...
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --debug >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Android 司機端建置成功
) else (
    echo ❌ Android 司機端建置失敗
)

echo.
echo 📊 配置完成總結
echo ==================================

set TOTAL_CONFIGS=4
echo 配置檔案狀態: !EXISTING_CONFIGS!/!TOTAL_CONFIGS! 完成

if !EXISTING_CONFIGS! equ !TOTAL_CONFIGS! (
    echo.
    echo 🎉 所有 Firebase 配置檔案已正確設定！
    echo 您現在可以開始開發 Relay GO 應用程式了！
    echo.
    echo 📱 執行應用程式:
    echo 客戶端: flutter run --flavor customer --target lib/apps/customer/main_customer.dart
    echo 司機端: flutter run --flavor driver --target lib/apps/driver/main_driver.dart
) else (
    set /a REMAINING_CONFIGS=!TOTAL_CONFIGS!-!EXISTING_CONFIGS!
    echo.
    echo ⚠️  還有 !REMAINING_CONFIGS! 個配置檔案需要設定
    echo 請參考 firebase-config-guide.md 完成剩餘配置
)

echo.
echo 🔗 需要幫助？
echo 📖 查看完整指南: type firebase-config-guide.md
echo 🔥 Firebase Console: https://console.firebase.google.com/
echo 📱 Flutter 文檔: https://flutter.dev/docs

echo.
pause
