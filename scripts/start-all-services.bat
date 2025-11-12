@echo off
chcp 65001 >nul
echo ========================================
echo 🚀 啟動所有服務
echo ========================================
echo.

REM 檢查是否在正確的目錄
if not exist "backend" (
    echo ❌ 錯誤：請在項目根目錄執行此腳本
    echo 當前目錄：%CD%
    pause
    exit /b 1
)

echo [1/3] 檢查 Backend 依賴...
cd backend
if not exist "node_modules" (
    echo ⚠️  Backend 依賴未安裝，正在安裝...
    call npm install
    if errorlevel 1 (
        echo ❌ Backend 依賴安裝失敗
        cd ..
        pause
        exit /b 1
    )
)
cd ..

echo.
echo [2/3] 啟動 Backend 服務...
start "Backend API (Port 3000)" cmd /k "cd backend && npm run dev"

echo.
echo [3/3] 等待 Backend 啟動...
timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo ✅ 所有服務已啟動
echo ========================================
echo.
echo 📡 服務地址：
echo   - Backend API: http://localhost:3000
echo   - Health Check: http://localhost:3000/health
echo.
echo 📱 Android 模擬器訪問地址：
echo   - Backend API: http://10.0.2.2:3000
echo   - Health Check: http://10.0.2.2:3000/health
echo.
echo 🧪 測試 Backend：
echo   curl http://localhost:3000/health
echo.
echo 💡 提示：
echo   - Backend 運行在獨立的 Terminal 窗口中
echo   - 關閉 Terminal 窗口將停止對應的服務
echo   - 按 Ctrl+C 可以停止服務
echo.
pause

