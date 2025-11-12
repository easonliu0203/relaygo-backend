@echo off
chcp 65001 >nul
echo ========================================
echo 支付尾款功能測試腳本
echo ========================================
echo.

echo [1/3] 檢查 Backend 服務狀態...
curl -s http://localhost:3000/health >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Backend 服務未運行！
    echo.
    echo 請先啟動 Backend 服務：
    echo   cd backend
    echo   npm run dev
    echo.
    pause
    exit /b 1
) else (
    echo ✅ Backend 服務運行中
)
echo.

echo [2/3] 檢查 Supabase Edge Function 部署狀態...
echo.
echo 請手動確認以下事項：
echo   1. Edge Function 'sync-to-firestore' 已部署
echo   2. 部署時間：2025-10-16 11:05 或更新
echo   3. 查看方式：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
echo.
set /p confirm="已確認 Edge Function 部署？(Y/N): "
if /i not "%confirm%"=="Y" (
    echo.
    echo ❌ 請先部署 Edge Function
    echo.
    echo 部署命令：
    echo   npx supabase functions deploy sync-to-firestore
    echo.
    pause
    exit /b 1
)
echo ✅ Edge Function 已確認
echo.

echo [3/3] 準備測試環境...
echo.
echo 測試帳號資訊：
echo ─────────────────────────────────────
echo 客戶端：
echo   Email: customer.test@relaygo.com
echo   Password: RelayGO2024!Customer
echo.
echo 司機端：
echo   Email: driver.test@relaygo.com
echo   Password: RelayGO2024!Driver
echo ─────────────────────────────────────
echo.

echo ✅ 環境檢查完成！
echo.
echo 📋 測試流程：
echo   1. 創建訂單並支付訂金（客戶端）
echo   2. 確認接單 → 出發 → 到達（司機端）
echo   3. 開始行程（客戶端）
echo   4. 結束行程（客戶端）
echo   5. ⭐ 自動跳轉到支付尾款頁面
echo   6. ⭐ 支付尾款 NT$ 45
echo   7. ⭐ 自動跳轉到訂單完成頁面
echo.
echo 📚 詳細測試指南：
echo   docs/支付尾款功能測試指南.md
echo.

set /p start="是否打開測試指南文檔？(Y/N): "
if /i "%start%"=="Y" (
    start docs\支付尾款功能測試指南.md
)

echo.
echo 🚀 準備開始測試！
echo.
pause

