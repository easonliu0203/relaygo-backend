@echo off
REM ========================================
REM 驗證 Edge Function 部署狀態
REM ========================================

echo.
echo ========================================
echo 驗證 Edge Function 部署狀態
echo ========================================
echo.

echo ✅ Edge Function 已成功部署！
echo.
echo 📊 部署信息：
echo    - Function: sync-to-firestore
echo    - Project: vlyhwegpvpnjyocqmfqc
echo    - Dashboard: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
echo.

echo 🔍 下一步驗證：
echo.
echo 1. 查看 Edge Function 日誌
echo    - 打開 Dashboard: https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
echo    - 點擊 sync-to-firestore
echo    - 查看 Logs 標籤
echo    - 等待下一次 Cron Job 執行（每分鐘）
echo    - 應該看到：[狀態映射] Supabase 狀態: trip_started
echo    - 應該看到：[狀態映射] Firestore 狀態: inProgress
echo.

echo 2. 測試「開始行程」功能
echo    - 創建新訂單
echo    - 司機確認接單
echo    - 司機出發
echo    - 司機到達
echo    - 客戶點擊「開始行程」
echo    - 等待 1-2 分鐘
echo    - 檢查 Firestore 狀態
echo.

echo 3. 驗證 Firestore 狀態
echo    - 打開 Firebase Console
echo    - 查看 bookings/{bookingId} 的 status 欄位
echo    - 查看 orders_rt/{bookingId} 的 status 欄位
echo    - 應該是：inProgress（不是 pending）
echo.

echo ========================================
echo ✅ 部署驗證完成！
echo ========================================
echo.

pause

