@echo off
REM 重新編譯司機端 APP - 修復「確認接單」按鈕顯示問題
REM 日期: 2025-10-13

echo ========================================
echo 重新編譯司機端 APP
echo ========================================
echo.

echo [1/5] 清理舊的編譯文件...
call flutter clean
if errorlevel 1 (
    echo ❌ 清理失敗
    pause
    exit /b 1
)
echo ✅ 清理完成
echo.

echo [2/5] 重新獲取依賴...
call flutter pub get
if errorlevel 1 (
    echo ❌ 獲取依賴失敗
    pause
    exit /b 1
)
echo ✅ 依賴獲取完成
echo.

echo [3/5] 檢查 Android 模擬器...
call adb devices
echo.

echo [4/5] 編譯並運行司機端 APP...
echo 提示：請確保 Android 模擬器已啟動
echo.
call flutter run -t lib/apps/driver/main_driver.dart
if errorlevel 1 (
    echo ❌ 編譯失敗
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ 司機端 APP 已成功啟動
echo ========================================
echo.
echo 測試步驟：
echo 1. 在 Web Admin 手動派單給測試司機
echo 2. 在司機端 APP 進入「我的訂單」^>「進行中」
echo 3. 點擊訂單查看詳情
echo 4. 確認顯示「確認接單」按鈕（綠色）
echo 5. 點擊按鈕測試功能
echo.
pause

