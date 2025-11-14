@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo 🔥 Firebase 測試帳號創建工具
echo ================================
echo.

cd /d "%~dp0.."

echo 📋 檢查環境...
echo.

REM 檢查 Flutter 是否安裝
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter 未安裝或未加入 PATH
    echo 請先安裝 Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter 環境正常
echo.

REM 檢查 Firebase 配置檔案
if not exist "lib\core\config\firebase_options.dart" (
    echo ❌ Firebase 配置檔案不存在
    echo 請先執行 flutterfire configure 配置 Firebase
    pause
    exit /b 1
)

echo ✅ Firebase 配置檔案存在
echo.

echo 🔄 安裝依賴套件...
call flutter pub get
if errorlevel 1 (
    echo ❌ 依賴套件安裝失敗
    pause
    exit /b 1
)

echo ✅ 依賴套件安裝完成
echo.

echo 🚀 執行測試帳號創建腳本...
echo.

REM 執行 Dart 腳本
dart run scripts/create-test-accounts.dart
if errorlevel 1 (
    echo.
    echo ❌ 測試帳號創建失敗
    echo.
    echo 🔧 可能的解決方案:
    echo 1. 檢查網路連接
    echo 2. 確認 Firebase 專案配置正確
    echo 3. 確認 Firebase Authentication 已啟用
    echo 4. 檢查 Firebase 專案權限
    echo.
    pause
    exit /b 1
)

echo.
echo 🎉 測試帳號創建完成！
echo.
echo 📱 下一步:
echo 1. 啟動 Android 模擬器或連接實體設備
echo 2. 執行客戶端應用程式: flutter run --flavor customer --target lib/apps/customer/main_customer.dart
echo 3. 執行司機端應用程式: flutter run --flavor driver --target lib/apps/driver/main_driver.dart
echo 4. 在登入頁面點擊「使用測試帳號」按鈕測試認證功能
echo.

pause
