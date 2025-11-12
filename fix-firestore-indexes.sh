#!/bin/bash

# Firestore 索引修復腳本
# 日期: 2025-10-08

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo -e "${BLUE}Firestore 索引修復腳本${NC}"
echo "=========================================="
echo ""

# ============================================
# 步驟 1: 檢查索引文件
# ============================================

echo -e "${YELLOW}步驟 1: 檢查索引文件...${NC}"
echo ""

if [ ! -f "firebase/firestore.indexes.json" ]; then
    echo -e "${RED}❌ 找不到 firebase/firestore.indexes.json${NC}"
    exit 1
fi

# 檢查是否包含新的複合索引
if grep -q '"customerId".*"status".*"createdAt"' firebase/firestore.indexes.json; then
    echo -e "${GREEN}✅ 找到複合索引配置 (customerId + status + createdAt)${NC}"
else
    echo -e "${RED}❌ 未找到複合索引配置${NC}"
    echo "請確認 firebase/firestore.indexes.json 已更新"
    exit 1
fi

echo ""
echo -e "${GREEN}索引文件檢查通過!${NC}"
echo ""

# ============================================
# 步驟 2: 顯示索引配置
# ============================================

echo "=========================================="
echo -e "${YELLOW}步驟 2: 索引配置預覽${NC}"
echo "=========================================="
echo ""

echo "需要創建的索引:"
echo ""
echo "Collection: orders_rt"
echo "Fields:"
echo "  1. customerId  (Ascending)"
echo "  2. status      (Ascending)"
echo "  3. createdAt   (Descending)"
echo ""

# ============================================
# 步驟 3: 提供修復選項
# ============================================

echo "=========================================="
echo -e "${YELLOW}步驟 3: 選擇修復方式${NC}"
echo "=========================================="
echo ""
echo "請選擇以下其中一種方式創建索引:"
echo ""
echo -e "${BLUE}方式 1: 點擊錯誤連結 (最簡單)${NC}"
echo "  - 複製應用中的錯誤 URL"
echo "  - 在瀏覽器中打開"
echo "  - Firebase Console 會自動預填索引配置"
echo "  - 點擊 'Create Index' 按鈕"
echo ""
echo -e "${BLUE}方式 2: 使用 Firebase CLI (推薦)${NC}"
echo "  - 需要安裝 Firebase CLI"
echo "  - 自動部署索引配置"
echo ""
echo -e "${BLUE}方式 3: 手動在 Firebase Console 創建${NC}"
echo "  - 手動輸入索引配置"
echo "  - 適合不熟悉 CLI 的用戶"
echo ""

read -p "是否使用 Firebase CLI 部署索引? (y/n): " use_cli

if [ "$use_cli" = "y" ] || [ "$use_cli" = "Y" ]; then
    echo ""
    echo -e "${YELLOW}使用 Firebase CLI 部署索引...${NC}"
    echo ""
    
    # 檢查 Firebase CLI 是否安裝
    if ! command -v firebase &> /dev/null; then
        echo -e "${RED}❌ Firebase CLI 未安裝${NC}"
        echo ""
        echo "請先安裝 Firebase CLI:"
        echo "  npm install -g firebase-tools"
        echo ""
        exit 1
    fi
    
    echo -e "${GREEN}✅ Firebase CLI 已安裝${NC}"
    echo ""
    
    # 檢查是否已登入
    echo "檢查 Firebase 登入狀態..."
    if ! firebase projects:list &> /dev/null; then
        echo -e "${YELLOW}需要登入 Firebase${NC}"
        firebase login
    else
        echo -e "${GREEN}✅ 已登入 Firebase${NC}"
    fi
    
    echo ""
    echo "部署索引到 Firestore..."
    echo ""
    
    # 部署索引
    firebase deploy --only firestore:indexes
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ 索引部署成功!${NC}"
        echo ""
        echo "索引正在建立中,請等待幾分鐘..."
        echo ""
        echo "查看索引狀態:"
        echo "  firebase firestore:indexes"
        echo ""
    else
        echo ""
        echo -e "${RED}❌ 索引部署失敗${NC}"
        echo "請檢查錯誤訊息並重試"
        exit 1
    fi
else
    echo ""
    echo -e "${YELLOW}手動創建索引${NC}"
    echo ""
    echo "請按照以下步驟操作:"
    echo ""
    echo "1. 打開 Firebase Console:"
    echo "   https://console.firebase.google.com/project/ride-platform-f1676/firestore/indexes"
    echo ""
    echo "2. 點擊 'Create Index'"
    echo ""
    echo "3. 填寫以下資訊:"
    echo "   Collection ID: orders_rt"
    echo "   Fields:"
    echo "     - customerId  (Ascending)"
    echo "     - status      (Ascending)"
    echo "     - createdAt   (Descending)"
    echo "   Query scope: Collection"
    echo ""
    echo "4. 點擊 'Create'"
    echo ""
    echo "5. 等待索引建立完成 (狀態變為 'Enabled')"
    echo ""
fi

# ============================================
# 步驟 4: 驗證指南
# ============================================

echo "=========================================="
echo -e "${YELLOW}步驟 4: 驗證修復${NC}"
echo "=========================================="
echo ""
echo "索引建立完成後,請測試以下功能:"
echo ""
echo "1. 客戶端「我的訂單 > 進行中」頁面"
echo "   - 應該正常載入"
echo "   - 顯示進行中的訂單"
echo ""
echo "2. 客戶端「我的訂單 > 歷史訂單」頁面"
echo "   - 應該正常載入"
echo "   - 顯示已完成和已取消的訂單"
echo ""
echo "3. 管理後台訂單頁面"
echo "   - 應該正常顯示訂單列表"
echo ""
echo -e "${GREEN}預期結果:${NC}"
echo "  ✅ 所有頁面正常載入"
echo "  ✅ 不出現索引錯誤"
echo "  ✅ 訂單列表正確顯示"
echo ""

# ============================================
# 完成
# ============================================

echo "=========================================="
echo -e "${GREEN}修復腳本執行完成!${NC}"
echo "=========================================="
echo ""
echo "接下來:"
echo ""
echo "1. 等待索引建立完成 (幾分鐘到幾小時)"
echo "2. 在 Firebase Console 確認索引狀態為 'Enabled'"
echo "3. 測試應用功能"
echo ""
echo "詳細說明請查看: ${BLUE}Firestore索引修復指南.md${NC}"
echo ""

