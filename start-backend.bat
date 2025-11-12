@echo off
REM ============================================
REM 啟動後端服務器
REM ============================================

echo.
echo ============================================
echo 🚀 啟動後端服務器
echo ============================================
echo.

cd backend

echo 📦 檢查依賴...
if not exist "node_modules" (
    echo ⚠️  node_modules 不存在，正在安裝依賴...
    call npm install
    if errorlevel 1 (
        echo ❌ 依賴安裝失敗
        pause
        exit /b 1
    )
    echo ✅ 依賴安裝成功
)

echo.
echo 🔧 檢查環境變數...
if not exist ".env" (
    echo ❌ .env 文件不存在
    echo 請創建 .env 文件並配置必要的環境變數
    pause
    exit /b 1
)
echo ✅ .env 文件存在

echo.
echo 🚀 啟動服務器...
echo.
call npm run dev

pause

