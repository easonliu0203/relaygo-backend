@echo off
REM ============================================
REM 檢查後端服務器健康狀態
REM ============================================

echo.
echo ============================================
echo 🏥 檢查後端服務器健康狀態
echo ============================================
echo.

echo 📡 正在連接 http://localhost:3000/health ...
echo.

curl -s http://localhost:3000/health

if errorlevel 1 (
    echo.
    echo ❌ 後端服務器未運行或無法連接
    echo.
    echo 💡 建議：
    echo    1. 執行 start-backend.bat 啟動服務器
    echo    2. 檢查防火牆設置
    echo    3. 確認端口 3000 未被占用
    echo.
) else (
    echo.
    echo ✅ 後端服務器運行正常
    echo.
)

pause

