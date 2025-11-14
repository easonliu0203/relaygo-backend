@echo off
echo ========================================
echo 生成 Freezed 和 JSON 序列化代碼
echo ========================================
echo.

cd /d "%~dp0.."

echo [1/3] 清理舊的生成文件...
flutter packages pub run build_runner clean

echo.
echo [2/3] 生成代碼...
flutter packages pub run build_runner build --delete-conflicting-outputs

echo.
echo [3/3] 完成！
echo ========================================
echo.

pause

