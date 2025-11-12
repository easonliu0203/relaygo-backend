#!/bin/bash
# ============================================
# 啟動後端服務器
# ============================================

echo ""
echo "============================================"
echo "🚀 啟動後端服務器"
echo "============================================"
echo ""

cd backend

echo "📦 檢查依賴..."
if [ ! -d "node_modules" ]; then
    echo "⚠️  node_modules 不存在，正在安裝依賴..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ 依賴安裝失敗"
        exit 1
    fi
    echo "✅ 依賴安裝成功"
fi

echo ""
echo "🔧 檢查環境變數..."
if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在"
    echo "請創建 .env 文件並配置必要的環境變數"
    exit 1
fi
echo "✅ .env 文件存在"

echo ""
echo "🚀 啟動服務器..."
echo ""
npm run dev

