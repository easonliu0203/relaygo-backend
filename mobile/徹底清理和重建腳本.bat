@echo off
REM 徹底清理和重建 Flutter App 腳本
REM 日期：2025-10-08
REM 用途：解決 TextEditingController 錯誤持續出現的問題

echo ========================================
echo Flutter App 徹底清理和重建腳本
echo ========================================
echo.

REM 檢查是否在正確的目錄
if not exist "mobile" (
    echo [錯誤] 請在專案根目錄執行此腳本
    echo 當前目錄：%CD%
    pause
    exit /b 1
)

echo [步驟 1/8] 進入 mobile 目錄...
cd mobile
echo ✓ 完成
echo.

echo [步驟 2/8] 執行 flutter clean...
flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo [錯誤] flutter clean 失敗
    pause
    exit /b 1
)
echo ✓ 完成
echo.

echo [步驟 3/8] 清理 Pub 緩存...
flutter pub cache repair
if %ERRORLEVEL% NEQ 0 (
    echo [錯誤] flutter pub cache repair 失敗
    pause
    exit /b 1
)
echo ✓ 完成
echo.

echo [步驟 4/8] 刪除 build 目錄...
if exist build (
    rmdir /s /q build
    echo ✓ build 目錄已刪除
) else (
    echo ✓ build 目錄不存在，跳過
)
echo.

echo [步驟 5/8] 刪除 .dart_tool 目錄...
if exist .dart_tool (
    rmdir /s /q .dart_tool
    echo ✓ .dart_tool 目錄已刪除
) else (
    echo ✓ .dart_tool 目錄不存在，跳過
)
echo.

echo [步驟 6/8] 重新獲取依賴...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [錯誤] flutter pub get 失敗
    pause
    exit /b 1
)
echo ✓ 完成
echo.

echo [步驟 7/8] 卸載舊的 App（Android）...
echo 正在檢查連接的設備...
adb devices
echo.
echo 正在卸載 com.example.mobile.customer...
adb uninstall com.example.mobile.customer
if %ERRORLEVEL% EQU 0 (
    echo ✓ App 已卸載
) else (
    echo ⚠ App 可能未安裝或設備未連接，繼續...
)
echo.

echo [步驟 8/8] 準備重新運行 App...
echo.
echo ========================================
echo 清理完成！
echo ========================================
echo.
echo 下一步：
echo 1. 確認 Android 設備已連接
echo 2. 執行以下命令重新運行 App：
echo.
echo    flutter run --flavor customer --target lib/apps/customer/main_customer.dart
echo.
echo 重要提示：
echo - 不要使用 Hot Reload（按 r）
echo - 不要使用 Hot Restart（按 R）
echo - 完全停止並重新運行
echo.
pause

