@echo off
REM ============================================
REM Supabase Edge Functions 部署腳本 (Windows)
REM ============================================

echo.
echo ============================================
echo Supabase Edge Functions 部署腳本
echo ============================================
echo.

REM 設定專案資訊
set PROJECT_REF=vlyhwegpvpnjyocqmfqc
set PROJECT_URL=https://app.supabase.com/project/%PROJECT_REF%

echo 專案資訊：
echo   Project Ref: %PROJECT_REF%
echo   Dashboard: %PROJECT_URL%
echo.

REM ============================================
REM 步驟 1：檢查 Node.js 和 npm
REM ============================================

echo ============================================
echo 步驟 1：檢查前置條件
echo ============================================
echo.

echo 檢查 Node.js...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [錯誤] Node.js 未安裝
    echo 請先安裝 Node.js: https://nodejs.org
    pause
    exit /b 1
)
echo [成功] Node.js 已安裝

echo 檢查 npm...
npm --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [錯誤] npm 未安裝
    pause
    exit /b 1
)
echo [成功] npm 已安裝
echo.

REM ============================================
REM 步驟 2：登入 Supabase
REM ============================================

echo ============================================
echo 步驟 2：登入 Supabase
echo ============================================
echo.

echo 檢查登入狀態...
npx supabase projects list >nul 2>&1
if %errorlevel% neq 0 (
    echo [警告] 尚未登入 Supabase
    echo.
    echo 即將打開瀏覽器進行登入...
    echo 請在瀏覽器中完成登入後返回此視窗。
    echo.
    pause
    
    npx supabase login
    if %errorlevel% neq 0 (
        echo [錯誤] 登入失敗
        pause
        exit /b 1
    )
) else (
    echo [成功] 已登入 Supabase
)
echo.

REM ============================================
REM 步驟 3：連接到專案
REM ============================================

echo ============================================
echo 步驟 3：連接到專案
echo ============================================
echo.

echo 正在連接到專案 %PROJECT_REF%...
npx supabase link --project-ref %PROJECT_REF%
if %errorlevel% neq 0 (
    echo [警告] 連接失敗，可能已經連接過
    echo 繼續執行部署...
)
echo.

REM ============================================
REM 步驟 4：部署 Edge Functions
REM ============================================

echo ============================================
echo 步驟 4：部署 Edge Functions
echo ============================================
echo.

REM 切換到 supabase 目錄
cd /d "%~dp0"

echo 正在部署 sync-to-firestore 函數...
npx supabase functions deploy sync-to-firestore
if %errorlevel% neq 0 (
    echo [錯誤] sync-to-firestore 部署失敗
    echo.
    echo 請檢查錯誤訊息並重試。
    pause
    exit /b 1
)
echo [成功] sync-to-firestore 部署成功
echo.

echo 正在部署 cleanup-outbox 函數...
npx supabase functions deploy cleanup-outbox
if %errorlevel% neq 0 (
    echo [錯誤] cleanup-outbox 部署失敗
    echo.
    echo 請檢查錯誤訊息並重試。
    pause
    exit /b 1
)
echo [成功] cleanup-outbox 部署成功
echo.

REM ============================================
REM 部署完成
REM ============================================

echo ============================================
echo 部署完成！
echo ============================================
echo.

echo 已成功部署以下 Edge Functions：
echo   [✓] sync-to-firestore
echo   [✓] cleanup-outbox
echo.

echo 接下來的步驟：
echo.
echo 1. 驗證函數已部署：
echo    前往：%PROJECT_URL%/functions
echo.
echo 2. 查看函數日誌：
echo    點擊函數名稱 -^> Logs 分頁
echo.
echo 3. 測試同步功能：
echo    - 在應用中創建訂單
echo    - 檢查 outbox 表
echo    - 等待 30 秒
echo    - 檢查 Firestore orders_rt 集合
echo.

pause

