@echo off
chcp 65001 >nul
echo ========================================
echo 個人資料保存失敗 - 自動化修復工具
echo ========================================
echo.

echo 此工具將幫助您修復個人資料保存失敗的問題
echo.
echo 問題原因：
echo - RLS 政策使用 Supabase Auth
echo - 但應用使用 Firebase Auth
echo - 導致 RLS 檢查失敗
echo.
echo 修復方案：
echo - 禁用 user_profiles 表的 RLS
echo.

echo ========================================
echo 步驟 1: 檢查 Supabase 連接
echo ========================================
echo.

echo 請確認您已經：
echo [1] 登入 Supabase Dashboard
echo [2] 選擇了正確的專案 (vlyhwegpvpnjyocqmfqc)
echo.

pause

echo.
echo ========================================
echo 步驟 2: 執行診斷
echo ========================================
echo.

echo 請執行以下操作：
echo.
echo 1. 訪問 Supabase SQL Editor:
echo    https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/sql
echo.
echo 2. 創建新查詢
echo.
echo 3. 複製以下文件的內容：
echo    %~dp0diagnose-user-profiles-issue.sql
echo.
echo 4. 貼上並執行
echo.
echo 5. 查看診斷結果
echo.

echo 正在打開診斷腳本文件...
start notepad "%~dp0diagnose-user-profiles-issue.sql"

echo.
echo 正在打開 Supabase SQL Editor...
start https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/sql

echo.
pause

echo.
echo ========================================
echo 步驟 3: 執行修復
echo ========================================
echo.

echo 請執行以下操作：
echo.
echo 1. 在 Supabase SQL Editor 中創建新查詢
echo.
echo 2. 複製以下文件的內容：
echo    %~dp0fix-user-profiles-rls-for-firebase-auth.sql
echo.
echo 3. 貼上並執行
echo.
echo 4. 確認輸出顯示：
echo    ✅ RLS 已禁用
echo.

echo 正在打開修復腳本文件...
start notepad "%~dp0fix-user-profiles-rls-for-firebase-auth.sql"

echo.
pause

echo.
echo ========================================
echo 步驟 4: 測試修復
echo ========================================
echo.

echo 修復完成後，請測試應用：
echo.
echo 客戶端測試：
echo 1. 啟動客戶端應用
echo 2. 登入: customer.test@relaygo.com / RelayGO2024!Customer
echo 3. 編輯並保存個人資料
echo 4. 確認顯示「個人資料已更新」
echo.
echo 司機端測試：
echo 1. 啟動司機端應用
echo 2. 登入: driver.test@relaygo.com / RelayGO2024!Driver
echo 3. 編輯並保存個人資料
echo 4. 確認顯示「個人資料已更新」
echo.

echo 是否要啟動客戶端應用進行測試？(Y/N)
set /p start_customer=

if /i "%start_customer%"=="Y" (
    echo.
    echo 正在啟動客戶端應用...
    cd /d "%~dp0..\..\mobile"
    start cmd /k "scripts\run-customer.bat"
)

echo.
echo 是否要啟動司機端應用進行測試？(Y/N)
set /p start_driver=

if /i "%start_driver%"=="Y" (
    echo.
    echo 正在啟動司機端應用...
    cd /d "%~dp0..\..\mobile"
    start cmd /k "scripts\run-driver.bat"
)

echo.
echo ========================================
echo 修復完成！
echo ========================================
echo.

echo 如果仍然遇到問題，請查看：
echo - 診斷結果
echo - Flutter 控制台的錯誤訊息
echo - Supabase Dashboard 的日誌
echo.

echo 相關文檔：
echo - 個人資料保存失敗-自動化修復指南.md
echo - docs\20251010_1100_42_個人資料編輯保存失敗修復.md
echo.

pause

