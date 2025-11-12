# 即時同步 - 自動化部署助手 (PowerShell)
# 編碼: UTF-8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "即時同步 - 自動化部署助手" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "此腳本將幫助您快速打開所有需要的文件和 URL" -ForegroundColor Yellow
Write-Host ""
Write-Host "按任意鍵開始..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host ""
Write-Host "[1/6] 打開 Supabase SQL Editor..." -ForegroundColor Green
Start-Process "https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql"
Start-Sleep -Seconds 2

Write-Host "[2/6] 打開 Supabase Extensions 頁面..." -ForegroundColor Green
Start-Process "https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/database/extensions"
Start-Sleep -Seconds 2

Write-Host "[3/6] 打開 Supabase Edge Functions 頁面..." -ForegroundColor Green
Start-Process "https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions"
Start-Sleep -Seconds 2

Write-Host "[4/6] 打開執行指南..." -ForegroundColor Green
$guidePath = Join-Path $PSScriptRoot "即時同步_自動化部署執行指南.md"
if (Test-Path $guidePath) {
    Start-Process $guidePath
} else {
    Write-Host "   ⚠️  找不到執行指南文件" -ForegroundColor Yellow
}
Start-Sleep -Seconds 1

Write-Host "[5/6] 打開快速檢查清單..." -ForegroundColor Green
$checklistPath = Join-Path $PSScriptRoot "即時同步_快速執行檢查清單.md"
if (Test-Path $checklistPath) {
    Start-Process $checklistPath
} else {
    Write-Host "   ⚠️  找不到檢查清單文件" -ForegroundColor Yellow
}
Start-Sleep -Seconds 1

Write-Host "[6/6] 打開 SQL 腳本目錄..." -ForegroundColor Green
$supabasePath = Join-Path $PSScriptRoot "supabase"
if (Test-Path $supabasePath) {
    Start-Process $supabasePath
} else {
    Write-Host "   ⚠️  找不到 supabase 目錄" -ForegroundColor Yellow
}
Start-Sleep -Seconds 1

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 所有文件和頁面已打開！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 接下來的步驟：" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. 查看「即時同步_自動化部署執行指南.md」" -ForegroundColor White
Write-Host "2. 按照指南逐步執行" -ForegroundColor White
Write-Host "3. 使用「即時同步_快速執行檢查清單.md」追蹤進度" -ForegroundColor White
Write-Host ""
Write-Host "📁 SQL 腳本位置：" -ForegroundColor Yellow
Write-Host "   - Migration: supabase\migrations\20251016_create_realtime_sync_trigger.sql" -ForegroundColor White
Write-Host "   - 啟用: supabase\enable_realtime_sync.sql" -ForegroundColor White
Write-Host "   - 測試: supabase\test_realtime_sync.sql" -ForegroundColor White
Write-Host "   - 狀態檢查: supabase\check_realtime_sync_status.sql" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Supabase Dashboard 已在瀏覽器中打開：" -ForegroundColor Yellow
Write-Host "   - SQL Editor（執行 SQL 腳本）" -ForegroundColor White
Write-Host "   - Extensions（啟用 pg_net）" -ForegroundColor White
Write-Host "   - Edge Functions（檢查函數狀態）" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "按任意鍵關閉此視窗..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

