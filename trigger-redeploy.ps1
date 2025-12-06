# Railway 重新部署觸發腳本
# 用途：當 Railway 部署卡住時，推送空 commit 強制觸發新的部署

Write-Host "🔄 準備觸發 Railway 重新部署..." -ForegroundColor Cyan
Write-Host ""

# 確認當前在 backend 目錄
if (-not (Test-Path "package.json")) {
    Write-Host "❌ 錯誤：請在 backend 目錄執行此腳本" -ForegroundColor Red
    exit 1
}

# 檢查 git 狀態
Write-Host "📊 檢查 Git 狀態..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "⚠️  即將推送空 commit 以觸發 Railway 重新部署" -ForegroundColor Yellow
$confirmation = Read-Host "確定要繼續嗎？(y/n)"

if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "❌ 已取消" -ForegroundColor Red
    exit 1
}

# 創建空 commit
Write-Host ""
Write-Host "📝 創建空 commit..." -ForegroundColor Yellow
git commit --allow-empty -m "Trigger Railway redeploy - builder scheduling issue

Previous deployment stuck at 'scheduling build on Metal builder'.
This empty commit forces Railway to start a fresh deployment.

Commit fc80e62 (remove nixpacks.toml) is still valid.
This is just to trigger a new build process."

# 推送到 GitHub
Write-Host ""
Write-Host "🚀 推送到 GitHub..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "✅ 完成！Railway 應該會開始新的部署" -ForegroundColor Green
Write-Host "📊 請在 Railway Dashboard 查看部署狀態：" -ForegroundColor Cyan
Write-Host "   https://railway.app" -ForegroundColor Cyan

