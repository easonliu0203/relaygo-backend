@echo off
REM ========================================
REM Firestore 安全規則部署腳本 (Windows)
REM ========================================
REM 
REM 用途：部署 Firestore 安全規則到 Firebase 專案
REM 
REM 使用方法：
REM   1. 確保已安裝 Firebase CLI: npm install -g firebase-tools
REM   2. 確保已登入 Firebase: firebase login
REM   3. 執行此腳本: deploy-firestore-rules.bat
REM 
REM ========================================

echo.
echo ========================================
echo Firestore 安全規則部署腳本
echo ========================================
echo.

REM 檢查 Firebase CLI 是否已安裝
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [錯誤] 找不到 Firebase CLI
    echo.
    echo 請先安裝 Firebase CLI:
    echo   npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

echo [1/4] 檢查 Firebase CLI 版本...
firebase --version
echo.

echo [2/4] 檢查當前 Firebase 專案...
firebase projects:list
echo.

echo [3/4] 部署 Firestore 安全規則...
echo.
echo 正在部署規則文件: firebase/firestore.rules
echo.

firebase deploy --only firestore:rules

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo [成功] Firestore 安全規則部署完成！
    echo ========================================
    echo.
    echo 修復內容：
    echo   - 允許司機讀取自己的訂單 (driverId == request.auth.uid^)
    echo   - 允許客戶讀取自己的訂單 (customerId == request.auth.uid^)
    echo   - 禁止直接寫入 (所有寫入通過 Supabase API^)
    echo.
    echo 下一步：
    echo   1. 重新啟動司機端應用
    echo   2. 測試訂單列表功能
    echo   3. 驗證權限錯誤已修復
    echo.
) else (
    echo.
    echo ========================================
    echo [失敗] Firestore 安全規則部署失敗
    echo ========================================
    echo.
    echo 可能的原因：
    echo   1. 未登入 Firebase: 執行 firebase login
    echo   2. 未選擇專案: 執行 firebase use --add
    echo   3. 權限不足: 確認您有專案的部署權限
    echo.
)

echo [4/4] 完成
echo.
pause

