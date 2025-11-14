@echo off
echo ========================================
echo 安裝 Flutter 依賴
echo ========================================
echo.

cd /d "%~dp0.."

echo [1/2] 獲取依賴...
flutter pub get

echo.
echo [2/2] 生成代碼...
call scripts\generate-code.bat

echo.
echo ========================================
echo 依賴安裝完成！
echo ========================================
echo.

pause

