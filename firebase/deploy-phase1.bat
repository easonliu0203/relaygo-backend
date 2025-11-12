@echo off
REM ============================================================================
REM 階段 1: 部署與測試腳本 (Windows)
REM ============================================================================
REM 此腳本會依序執行以下步驟：
REM 1. 部署 Firestore 安全規則
REM 2. 執行資料遷移腳本
REM 3. 運行測試用例
REM ============================================================================

echo.
echo ============================================================================
echo 階段 1: 部署與測試腳本
echo ============================================================================
echo.

REM 檢查是否在 firebase 目錄
if not exist "firebase.json" (
    echo [錯誤] 請在 firebase 目錄中執行此腳本
    exit /b 1
)

REM ============================================================================
REM 步驟 1: 部署 Firestore 安全規則
REM ============================================================================
echo.
echo [步驟 1/4] 部署 Firestore 安全規則...
echo.

firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo [錯誤] Firestore 安全規則部署失敗
    exit /b 1
)

echo.
echo [成功] Firestore 安全規則部署完成
echo.

REM ============================================================================
REM 步驟 2: 執行資料遷移腳本
REM ============================================================================
echo.
echo [步驟 2/4] 執行資料遷移腳本...
echo.

REM 檢查是否設置了 Service Account Key
if not exist "service-account-key.json" (
    echo [警告] 未找到 service-account-key.json
    echo [提示] 請參考 migrations/README.md 設置 Service Account Key
    echo.
    set /p continue="是否繼續執行遷移腳本？(y/n): "
    if /i not "%continue%"=="y" (
        echo [取消] 跳過資料遷移
        goto :skip_migration
    )
)

echo.
echo [2.1] 遷移用戶語言偏好...
node migrations/add-user-language-preferences.js
if %errorlevel% neq 0 (
    echo [錯誤] 用戶語言偏好遷移失敗
    exit /b 1
)

echo.
echo [2.2] 遷移聊天室成員列表...
node migrations/add-chat-room-member-ids.js
if %errorlevel% neq 0 (
    echo [錯誤] 聊天室成員列表遷移失敗
    exit /b 1
)

echo.
echo [2.3] (可選) 遷移訊息語言偵測...
set /p migrate_messages="是否執行訊息語言偵測遷移？(y/n): "
if /i "%migrate_messages%"=="y" (
    node migrations/add-message-detected-lang.js
    if %errorlevel% neq 0 (
        echo [警告] 訊息語言偵測遷移失敗（可選步驟）
    )
)

:skip_migration
echo.
echo [成功] 資料遷移完成
echo.

REM ============================================================================
REM 步驟 3: 安裝測試依賴
REM ============================================================================
echo.
echo [步驟 3/4] 安裝測試依賴...
echo.

if not exist "node_modules" (
    echo [提示] 首次運行，正在安裝依賴...
    npm install
    if %errorlevel% neq 0 (
        echo [錯誤] 依賴安裝失敗
        exit /b 1
    )
)

REM ============================================================================
REM 步驟 4: 運行測試用例
REM ============================================================================
echo.
echo [步驟 4/4] 運行測試用例...
echo.

echo [4.1] 運行 Firestore 安全規則測試...
npm run test:rules
if %errorlevel% neq 0 (
    echo [警告] Firestore 安全規則測試失敗
    echo [提示] 請檢查測試結果並修復問題
)

echo.
echo [4.2] 運行 Flutter 資料模型測試...
cd ..\mobile
call flutter test test/models/phase1_data_model_test.dart
if %errorlevel% neq 0 (
    echo [警告] Flutter 資料模型測試失敗
    echo [提示] 請檢查測試結果並修復問題
)
cd ..\firebase

REM ============================================================================
REM 完成
REM ============================================================================
echo.
echo ============================================================================
echo 階段 1: 部署與測試完成！
echo ============================================================================
echo.
echo [總結]
echo - Firestore 安全規則已部署
echo - 資料遷移已執行
echo - 測試用例已運行
echo.
echo [下一步]
echo 1. 檢查測試結果
echo 2. 驗證 Firestore 資料
echo 3. 準備開始階段 2
echo.
echo ============================================================================
echo.

pause

