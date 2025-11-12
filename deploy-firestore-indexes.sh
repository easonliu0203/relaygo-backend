#!/bin/bash
# ========================================
# Firestore 索引部署腳本 (Linux/Mac)
# ========================================
# 
# 用途：部署 Firestore 索引到 Firebase 專案
# 
# 使用方法：
#   1. 確保已安裝 Firebase CLI: npm install -g firebase-tools
#   2. 確保已登入 Firebase: firebase login
#   3. 賦予執行權限: chmod +x deploy-firestore-indexes.sh
#   4. 執行此腳本: ./deploy-firestore-indexes.sh
# 
# ========================================

echo ""
echo "========================================"
echo "Firestore 索引部署腳本"
echo "========================================"
echo ""

# 檢查 Firebase CLI 是否已安裝
if ! command -v firebase &> /dev/null; then
    echo "[錯誤] 找不到 Firebase CLI"
    echo ""
    echo "請先安裝 Firebase CLI:"
    echo "  npm install -g firebase-tools"
    echo ""
    exit 1
fi

echo "[1/5] 檢查 Firebase CLI 版本..."
firebase --version
echo ""

echo "[2/5] 檢查當前 Firebase 專案..."
firebase projects:list
echo ""

echo "[3/5] 部署 Firestore 索引..."
echo ""
echo "正在部署索引文件: firebase/firestore.indexes.json"
echo ""
echo "新增的索引："
echo "  - orders_rt: driverId + createdAt"
echo "  - orders_rt: driverId + status + createdAt"
echo ""

firebase deploy --only firestore:indexes

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "[成功] Firestore 索引部署完成！"
    echo "========================================"
    echo ""
    echo "修復內容："
    echo "  - 添加 driverId + createdAt 索引（司機訂單列表）"
    echo "  - 添加 driverId + status + createdAt 索引（司機進行中訂單）"
    echo ""
    echo "⚠️  重要提示："
    echo "  索引建立需要時間（通常 2-5 分鐘）"
    echo "  在索引建立完成前，查詢可能仍會失敗"
    echo ""
    echo "檢查索引狀態："
    echo "  https://console.firebase.google.com/project/ride-platform-f1676/firestore/indexes"
    echo ""
    echo "下一步："
    echo "  1. 等待索引建立完成（查看 Firebase 控制台）"
    echo "  2. 重新啟動司機端應用"
    echo "  3. 測試訂單列表功能"
    echo "  4. 驗證索引錯誤已修復"
    echo ""
else
    echo ""
    echo "========================================"
    echo "[失敗] Firestore 索引部署失敗"
    echo "========================================"
    echo ""
    echo "可能的原因："
    echo "  1. 未登入 Firebase: 執行 firebase login"
    echo "  2. 未選擇專案: 執行 firebase use --add"
    echo "  3. 權限不足: 確認您有專案的部署權限"
    echo "  4. 索引配置錯誤: 檢查 firebase/firestore.indexes.json"
    echo ""
    exit 1
fi

echo "[4/5] 檢查索引狀態..."
echo ""
echo "請訪問 Firebase 控制台查看索引建立進度："
echo "https://console.firebase.google.com/project/ride-platform-f1676/firestore/indexes"
echo ""

echo "[5/5] 完成"
echo ""

