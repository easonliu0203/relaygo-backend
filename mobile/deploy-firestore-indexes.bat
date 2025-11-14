@echo off
REM 部署 Firestore 索引
REM 用途: 創建必要的複合索引以支持訂單排序查詢

echo =========================================
echo 部署 Firestore 索引
echo =========================================
echo.

REM 檢查 Firebase CLI 是否安裝
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI 未安裝
    echo.
    echo 請先安裝 Firebase CLI:
    echo   npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

REM 檢查是否已登入
echo 📋 檢查 Firebase 登入狀態...
firebase projects:list >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 未登入 Firebase
    echo.
    echo 請先登入:
    echo   firebase login
    echo.
    pause
    exit /b 1
)

echo ✅ Firebase CLI 已就緒
echo.

REM 顯示索引配置
echo 📋 索引配置:
echo ----------------------------------------
type firestore.indexes.json
echo.

REM 確認部署
set /p CONFIRM="是否要部署這些索引? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo ❌ 取消部署
    pause
    exit /b 0
)

REM 部署索引
echo.
echo 🚀 開始部署索引...
echo ----------------------------------------

firebase deploy --only firestore:indexes

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =========================================
    echo ✅ 索引部署成功！
    echo =========================================
    echo.
    echo 📝 注意事項:
    echo    1. 索引創建可能需要幾分鐘時間
    echo    2. 在 Firebase Console 中查看索引狀態:
    echo       https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/indexes
    echo    3. 等待所有索引狀態變為「已啟用」
    echo    4. 索引啟用後，訂單排序功能將正常工作
    echo.
) else (
    echo.
    echo =========================================
    echo ❌ 索引部署失敗
    echo =========================================
    echo.
    echo 請檢查:
    echo    1. Firebase 專案是否正確設置
    echo    2. 是否有足夠的權限
    echo    3. firestore.indexes.json 格式是否正確
    echo.
)

pause

