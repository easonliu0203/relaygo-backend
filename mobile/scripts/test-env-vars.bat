@echo off
REM 測試環境變量是否正確設置

set DEV_IP=192.168.0.152

echo ========================================
echo 測試環境變量
echo ========================================
echo.
echo DEV_IP = %DEV_IP%
echo.
echo 完整的 API URL:
echo http://%DEV_IP%:3001/api
echo.
echo Flutter 命令:
echo flutter run --dart-define=DEV_API_URL=http://%DEV_IP%:3001/api
echo.
pause

