@echo off
chcp 65001 >nul
echo ========================================
echo 即時同步 - 自動化部署助手
echo ========================================
echo.
echo 此腳本將幫助您快速打開所有需要的文件和 URL
echo.
echo 按任意鍵開始...
pause >nul

echo.
echo [1/6] 打開 Supabase SQL Editor...
start https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql
timeout /t 2 >nul

echo [2/6] 打開 Supabase Extensions 頁面...
start https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/database/extensions
timeout /t 2 >nul

echo [3/6] 打開 Supabase Edge Functions 頁面...
start https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions
timeout /t 2 >nul

echo [4/6] 打開執行指南...
start "" "%~dp0即時同步_自動化部署執行指南.md"
timeout /t 1 >nul

echo [5/6] 打開快速檢查清單...
start "" "%~dp0即時同步_快速執行檢查清單.md"
timeout /t 1 >nul

echo [6/6] 打開 SQL 腳本目錄...
start "" "%~dp0supabase"
timeout /t 1 >nul

echo.
echo ========================================
echo ✅ 所有文件和頁面已打開！
echo ========================================
echo.
echo 📋 接下來的步驟：
echo.
echo 1. 查看「即時同步_自動化部署執行指南.md」
echo 2. 按照指南逐步執行
echo 3. 使用「即時同步_快速執行檢查清單.md」追蹤進度
echo.
echo 📁 SQL 腳本位置：
echo    - Migration: supabase\migrations\20251016_create_realtime_sync_trigger.sql
echo    - 啟用: supabase\enable_realtime_sync.sql
echo    - 測試: supabase\test_realtime_sync.sql
echo    - 狀態檢查: supabase\check_realtime_sync_status.sql
echo.
echo 🌐 Supabase Dashboard 已在瀏覽器中打開：
echo    - SQL Editor（執行 SQL 腳本）
echo    - Extensions（啟用 pg_net）
echo    - Edge Functions（檢查函數狀態）
echo.
echo ========================================
echo.
echo 按任意鍵關閉此視窗...
pause >nul

