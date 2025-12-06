#!/bin/bash

# Railway 重新部署觸發腳本
# 用途：當 Railway 部署卡住時，推送空 commit 強制觸發新的部署

echo "🔄 準備觸發 Railway 重新部署..."
echo ""

# 確認當前在 backend 目錄
if [ ! -f "package.json" ]; then
    echo "❌ 錯誤：請在 backend 目錄執行此腳本"
    exit 1
fi

# 檢查 git 狀態
echo "📊 檢查 Git 狀態..."
git status

echo ""
echo "⚠️  即將推送空 commit 以觸發 Railway 重新部署"
read -p "確定要繼續嗎？(y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 已取消"
    exit 1
fi

# 創建空 commit
echo ""
echo "📝 創建空 commit..."
git commit --allow-empty -m "Trigger Railway redeploy - builder scheduling issue

Previous deployment stuck at 'scheduling build on Metal builder'.
This empty commit forces Railway to start a fresh deployment.

Commit fc80e62 (remove nixpacks.toml) is still valid.
This is just to trigger a new build process."

# 推送到 GitHub
echo ""
echo "🚀 推送到 GitHub..."
git push origin main

echo ""
echo "✅ 完成！Railway 應該會開始新的部署"
echo "📊 請在 Railway Dashboard 查看部署狀態："
echo "   https://railway.app"

