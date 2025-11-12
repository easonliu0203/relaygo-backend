@echo off
REM ========================================
REM 部署 sync-to-firestore Edge Function
REM ========================================

echo.
echo ========================================
echo 部署 sync-to-firestore Edge Function
echo ========================================
echo.

REM 檢查 Supabase CLI 是否安裝
where supabase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 錯誤：Supabase CLI 未安裝
    echo.
    echo 請先安裝 Supabase CLI：
    echo npm install -g supabase
    echo.
    pause
    exit /b 1
)

echo ✅ Supabase CLI 已安裝
echo.

REM 部署 Edge Function
echo 📦 部署 sync-to-firestore Edge Function...
echo.

supabase functions deploy sync-to-firestore

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ 部署失敗！
    echo.
    echo 可能的原因：
    echo 1. Supabase CLI 未登入（執行 'supabase login'）
    echo 2. 專案未連結（執行 'supabase link'）
    echo 3. Edge Function 代碼有錯誤
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo ✅ 部署成功！
echo ========================================
echo.
echo 下一步：
echo 1. 測試手動派單功能
echo 2. 測試客戶端「進行中」頁面
echo 3. 檢查 Firestore 中的訂單狀態
echo.
pause

