@echo off
setlocal enabledelayedexpansion

echo 🧪 Relay GO Keystore 配置測試
echo =============================

:: 檢查是否在正確的目錄
if not exist "pubspec.yaml" (
    echo ❌ 錯誤: 請在 Flutter 專案根目錄執行此腳本
    pause
    exit /b 1
)

echo 📁 檢查 Keystore 檔案存在性
echo ============================

set CUSTOMER_KEYSTORE=android\app\keystore\customer\Relay-GO.jks
set CUSTOMER_PROPERTIES=android\app\keystore\customer\key.properties
set DRIVER_KEYSTORE=android\app\keystore\driver\Relay-GO-driver.jks
set DRIVER_PROPERTIES=android\app\keystore\driver\key.properties

:: 檢查客戶端檔案
if exist "%CUSTOMER_KEYSTORE%" (
    echo ✅ 客戶端 keystore 檔案存在: %CUSTOMER_KEYSTORE%
) else (
    echo ❌ 客戶端 keystore 檔案不存在: %CUSTOMER_KEYSTORE%
)

if exist "%CUSTOMER_PROPERTIES%" (
    echo ✅ 客戶端 key.properties 檔案存在: %CUSTOMER_PROPERTIES%
) else (
    echo ❌ 客戶端 key.properties 檔案不存在: %CUSTOMER_PROPERTIES%
)

:: 檢查司機端檔案
if exist "%DRIVER_KEYSTORE%" (
    echo ✅ 司機端 keystore 檔案存在: %DRIVER_KEYSTORE%
) else (
    echo ❌ 司機端 keystore 檔案不存在: %DRIVER_KEYSTORE%
)

if exist "%DRIVER_PROPERTIES%" (
    echo ✅ 司機端 key.properties 檔案存在: %DRIVER_PROPERTIES%
) else (
    echo ❌ 司機端 key.properties 檔案不存在: %DRIVER_PROPERTIES%
)

echo.
echo 🔍 檢查 Keystore 內容
echo ===================

if exist "%CUSTOMER_KEYSTORE%" (
    echo 客戶端 Keystore 資訊:
    keytool -list -keystore "%CUSTOMER_KEYSTORE%" -storepass gfhyhjjfhjytjjhukkn 2>nul
    if !errorlevel! equ 0 (
        echo ✅ 客戶端 keystore 可以正常讀取
    ) else (
        echo ❌ 客戶端 keystore 讀取失敗 (可能是密碼錯誤)
    )
    echo.
)

if exist "%DRIVER_KEYSTORE%" (
    echo 司機端 Keystore 資訊:
    keytool -list -keystore "%DRIVER_KEYSTORE%" -storepass isdipjmlbpijoaqef 2>nul
    if !errorlevel! equ 0 (
        echo ✅ 司機端 keystore 可以正常讀取
    ) else (
        echo ❌ 司機端 keystore 讀取失敗 (可能是密碼錯誤)
    )
    echo.
)

echo 🏗️ 測試建置配置
echo ================

echo 正在測試客戶端 Release 建置...
flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --release --verbose >build_customer.log 2>&1
if !errorlevel! equ 0 (
    echo ✅ 客戶端 Release 建置成功
) else (
    echo ❌ 客戶端 Release 建置失敗
    echo 詳細錯誤請查看: build_customer.log
)

echo 正在測試司機端 Release 建置...
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --release --verbose >build_driver.log 2>&1
if !errorlevel! equ 0 (
    echo ✅ 司機端 Release 建置成功
) else (
    echo ❌ 司機端 Release 建置失敗
    echo 詳細錯誤請查看: build_driver.log
)

echo.
echo 📊 測試結果總結
echo ==============

if exist "build\app\outputs\flutter-apk\app-customer-release.apk" (
    echo ✅ 客戶端 APK 已生成: build\app\outputs\flutter-apk\app-customer-release.apk
    
    :: 檢查 APK 簽名
    echo 檢查客戶端 APK 簽名...
    keytool -printcert -jarfile "build\app\outputs\flutter-apk\app-customer-release.apk" >customer_apk_cert.txt 2>&1
    if !errorlevel! equ 0 (
        echo ✅ 客戶端 APK 簽名驗證成功
    ) else (
        echo ❌ 客戶端 APK 簽名驗證失敗
    )
) else (
    echo ❌ 客戶端 APK 未生成
)

if exist "build\app\outputs\flutter-apk\app-driver-release.apk" (
    echo ✅ 司機端 APK 已生成: build\app\outputs\flutter-apk\app-driver-release.apk
    
    :: 檢查 APK 簽名
    echo 檢查司機端 APK 簽名...
    keytool -printcert -jarfile "build\app\outputs\flutter-apk\app-driver-release.apk" >driver_apk_cert.txt 2>&1
    if !errorlevel! equ 0 (
        echo ✅ 司機端 APK 簽名驗證成功
    ) else (
        echo ❌ 司機端 APK 簽名驗證失敗
    )
) else (
    echo ❌ 司機端 APK 未生成
)

echo.
echo 🎯 配置狀態
echo ==========

echo 檔案位置檢查:
echo   客戶端 keystore: %CUSTOMER_KEYSTORE%
echo   客戶端 properties: %CUSTOMER_PROPERTIES%
echo   司機端 keystore: %DRIVER_KEYSTORE%
echo   司機端 properties: %DRIVER_PROPERTIES%
echo.

echo 生成的檔案:
if exist "build_customer.log" echo   客戶端建置日誌: build_customer.log
if exist "build_driver.log" echo   司機端建置日誌: build_driver.log
if exist "customer_apk_cert.txt" echo   客戶端簽名資訊: customer_apk_cert.txt
if exist "driver_apk_cert.txt" echo   司機端簽名資訊: driver_apk_cert.txt

echo.
echo 🚀 如果所有測試都通過，您的 keystore 配置已準備就緒！
echo 現在可以開始開發 Relay GO 的具體功能了。

pause
