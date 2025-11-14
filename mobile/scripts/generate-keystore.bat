@echo off
setlocal enabledelayedexpansion

echo 🔐 Relay GO Keystore 生成腳本
echo =============================

:: 檢查 Java keytool 是否可用
keytool -help >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 錯誤: 找不到 keytool 命令
    echo 請確保已安裝 Java JDK 並將其添加到 PATH 環境變數中
    pause
    exit /b 1
)

:: 檢查是否在正確的目錄
if not exist "pubspec.yaml" (
    echo ❌ 錯誤: 請在 Flutter 專案根目錄執行此腳本
    pause
    exit /b 1
)

echo.
echo 此腳本將為 Relay GO 客戶端和司機端應用程式生成 keystore 檔案
echo.

:: 建立 keystore 目錄
if not exist "android\app\keystore\customer" mkdir "android\app\keystore\customer"
if not exist "android\app\keystore\driver" mkdir "android\app\keystore\driver"

echo 📱 生成客戶端 Keystore
echo =====================

set /p CUSTOMER_STORE_PASSWORD=請輸入客戶端 keystore 密碼: 
set /p CUSTOMER_KEY_PASSWORD=請輸入客戶端 key 密碼: 
set /p CUSTOMER_ALIAS=請輸入客戶端 key alias (預設: customer-release): 
if "%CUSTOMER_ALIAS%"=="" set CUSTOMER_ALIAS=customer-release

set /p CUSTOMER_VALIDITY=請輸入有效期 (天數，預設: 10000): 
if "%CUSTOMER_VALIDITY%"=="" set CUSTOMER_VALIDITY=10000

echo.
echo 請輸入客戶端憑證資訊:
set /p CUSTOMER_CN=Common Name (CN) - 您的姓名或組織名稱: 
set /p CUSTOMER_OU=Organizational Unit (OU) - 部門名稱: 
set /p CUSTOMER_O=Organization (O) - 組織名稱: 
set /p CUSTOMER_L=Locality (L) - 城市: 
set /p CUSTOMER_ST=State (ST) - 省份/州: 
set /p CUSTOMER_C=Country (C) - 國家代碼 (如: TW): 

echo.
echo 正在生成客戶端 keystore...

keytool -genkey -v -keystore "android\app\keystore\customer\customer-release.keystore" ^
    -alias "%CUSTOMER_ALIAS%" ^
    -keyalg RSA ^
    -keysize 2048 ^
    -validity %CUSTOMER_VALIDITY% ^
    -storepass "%CUSTOMER_STORE_PASSWORD%" ^
    -keypass "%CUSTOMER_KEY_PASSWORD%" ^
    -dname "CN=%CUSTOMER_CN%, OU=%CUSTOMER_OU%, O=%CUSTOMER_O%, L=%CUSTOMER_L%, ST=%CUSTOMER_ST%, C=%CUSTOMER_C%"

if %errorlevel% equ 0 (
    echo ✅ 客戶端 keystore 生成成功
) else (
    echo ❌ 客戶端 keystore 生成失敗
    pause
    exit /b 1
)

:: 更新客戶端 key.properties
echo storePassword=%CUSTOMER_STORE_PASSWORD% > "android\app\keystore\customer\key.properties"
echo keyPassword=%CUSTOMER_KEY_PASSWORD% >> "android\app\keystore\customer\key.properties"
echo keyAlias=%CUSTOMER_ALIAS% >> "android\app\keystore\customer\key.properties"
echo storeFile=customer-release.keystore >> "android\app\keystore\customer\key.properties"

echo.
echo 🚛 生成司機端 Keystore
echo ====================

set /p DRIVER_STORE_PASSWORD=請輸入司機端 keystore 密碼: 
set /p DRIVER_KEY_PASSWORD=請輸入司機端 key 密碼: 
set /p DRIVER_ALIAS=請輸入司機端 key alias (預設: driver-release): 
if "%DRIVER_ALIAS%"=="" set DRIVER_ALIAS=driver-release

set /p DRIVER_VALIDITY=請輸入有效期 (天數，預設: 10000): 
if "%DRIVER_VALIDITY%"=="" set DRIVER_VALIDITY=10000

echo.
echo 請輸入司機端憑證資訊:
set /p DRIVER_CN=Common Name (CN) - 您的姓名或組織名稱: 
set /p DRIVER_OU=Organizational Unit (OU) - 部門名稱: 
set /p DRIVER_O=Organization (O) - 組織名稱: 
set /p DRIVER_L=Locality (L) - 城市: 
set /p DRIVER_ST=State (ST) - 省份/州: 
set /p DRIVER_C=Country (C) - 國家代碼 (如: TW): 

echo.
echo 正在生成司機端 keystore...

keytool -genkey -v -keystore "android\app\keystore\driver\driver-release.keystore" ^
    -alias "%DRIVER_ALIAS%" ^
    -keyalg RSA ^
    -keysize 2048 ^
    -validity %DRIVER_VALIDITY% ^
    -storepass "%DRIVER_STORE_PASSWORD%" ^
    -keypass "%DRIVER_KEY_PASSWORD%" ^
    -dname "CN=%DRIVER_CN%, OU=%DRIVER_OU%, O=%DRIVER_O%, L=%DRIVER_L%, ST=%DRIVER_ST%, C=%DRIVER_C%"

if %errorlevel% equ 0 (
    echo ✅ 司機端 keystore 生成成功
) else (
    echo ❌ 司機端 keystore 生成失敗
    pause
    exit /b 1
)

:: 更新司機端 key.properties
echo storePassword=%DRIVER_STORE_PASSWORD% > "android\app\keystore\driver\key.properties"
echo keyPassword=%DRIVER_KEY_PASSWORD% >> "android\app\keystore\driver\key.properties"
echo keyAlias=%DRIVER_ALIAS% >> "android\app\keystore\driver\key.properties"
echo storeFile=driver-release.keystore >> "android\app\keystore\driver\key.properties"

echo.
echo 🎉 所有 Keystore 檔案生成完成！
echo ===============================

echo.
echo 📁 生成的檔案:
echo 客戶端:
echo   - android\app\keystore\customer\customer-release.keystore
echo   - android\app\keystore\customer\key.properties
echo.
echo 司機端:
echo   - android\app\keystore\driver\driver-release.keystore
echo   - android\app\keystore\driver\key.properties
echo.

echo ⚠️  重要提醒:
echo 1. 請妥善保管 keystore 檔案和密碼
echo 2. 建議將 keystore 檔案備份到安全位置
echo 3. 不要將 keystore 檔案提交到版本控制系統
echo 4. 記錄所有密碼和 alias 資訊
echo.

echo 🚀 現在您可以建置 Release 版本:
echo flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart --release
echo flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart --release

pause
