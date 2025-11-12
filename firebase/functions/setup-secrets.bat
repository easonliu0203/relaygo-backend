@echo off
REM Secret Manager 快速設定腳本 (Windows)
REM 用途：自動化設定 Google Cloud Secret Manager

setlocal enabledelayedexpansion

echo ╔════════════════════════════════════════════════════════╗
echo ║     Google Cloud Secret Manager 設定腳本               ║
echo ╚════════════════════════════════════════════════════════╝
echo.

REM 專案 ID
set PROJECT_ID=ride-platform-f1676

echo 專案 ID: %PROJECT_ID%
echo.

REM 步驟 1: 檢查 Firebase CLI
echo 步驟 1: 檢查 Firebase CLI...
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI 未安裝
    echo 請執行: npm install -g firebase-tools
    pause
    exit /b 1
)
echo ✅ Firebase CLI 已安裝
echo.

REM 步驟 2: 設定專案
echo 步驟 2: 設定 Firebase 專案...
firebase use %PROJECT_ID%
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 專案設定失敗
    pause
    exit /b 1
)
echo ✅ 專案已設定
echo.

REM 步驟 3: 啟用 Secret Manager API
echo 步驟 3: 啟用 Secret Manager API...
echo ⚠️  請手動啟用 Secret Manager API:
echo    https://console.cloud.google.com/apis/library/secretmanager.googleapis.com?project=%PROJECT_ID%
echo.
pause

REM 步驟 4: 創建 OPENAI_API_KEY Secret
echo.
echo 步驟 4: 創建 OPENAI_API_KEY Secret...
echo.
echo 請輸入你的 OpenAI API 金鑰:
echo （格式：sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx）
set /p OPENAI_KEY=

if "%OPENAI_KEY%"=="" (
    echo ❌ API 金鑰不能為空
    pause
    exit /b 1
)

echo.
echo 正在創建 Secret...

REM 使用 Firebase CLI 創建 Secret
echo %OPENAI_KEY% | firebase functions:secrets:set OPENAI_API_KEY

if %ERRORLEVEL% EQU 0 (
    echo ✅ OPENAI_API_KEY Secret 已創建
) else (
    echo ❌ Secret 創建失敗
    pause
    exit /b 1
)
echo.

REM 步驟 5: 創建 .env 檔案
echo 步驟 5: 創建 .env 檔案（用於本地測試）...

(
echo # 本地測試用環境變數
echo # 注意：生產環境的 OPENAI_API_KEY 從 Secret Manager 讀取
echo.
echo # Translation Settings
echo ENABLE_AUTO_TRANSLATE=true
echo TARGET_LANGUAGES=zh-TW,en,ja
echo.
echo # OpenAI Model Configuration
echo OPENAI_MODEL=gpt-4o-mini
echo OPENAI_MAX_TOKENS=500
echo OPENAI_TEMPERATURE=0.3
echo.
echo # Cost Control Settings
echo MAX_AUTO_TRANSLATE_LENGTH=500
echo TRANSLATION_CACHE_TTL=600
echo MAX_CONCURRENT_TRANSLATIONS=2
echo.
echo # Retry Configuration
echo MAX_RETRY_ATTEMPTS=2
echo RETRY_DELAY_MS=1000
) > .env

echo ✅ .env 檔案已創建
echo.

REM 完成
echo ╔════════════════════════════════════════════════════════╗
echo ║                  設定完成！                            ║
echo ╚════════════════════════════════════════════════════════╝
echo.
echo 下一步：
echo 1. 安裝依賴: npm install
echo 2. 部署 Functions: firebase deploy --only functions
echo 3. 測試翻譯功能
echo.
echo 查看 Secret:
echo   https://console.cloud.google.com/security/secret-manager?project=%PROJECT_ID%
echo.
echo 🎉 設定完成！
echo.
pause

