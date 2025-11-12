#!/bin/bash

# 包車/接送叫車 APP 專案設定腳本
# 用於快速設定本地開發環境

set -e

echo "🚗 包車/接送叫車 APP 專案設定開始..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 檢查必要工具
check_requirements() {
    echo -e "${BLUE}📋 檢查系統需求...${NC}"
    
    # 檢查 Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js 未安裝，請先安裝 Node.js 18+${NC}"
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "${RED}❌ Node.js 版本過舊，需要 18+，當前版本: $(node -v)${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Node.js $(node -v)${NC}"
    
    # 檢查 Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${YELLOW}⚠️  Flutter 未安裝，請先安裝 Flutter 3.16+${NC}"
        echo "   下載地址: https://flutter.dev/docs/get-started/install"
    else
        echo -e "${GREEN}✅ Flutter $(flutter --version | head -n1 | cut -d' ' -f2)${NC}"
    fi
    
    # 檢查 Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠️  Docker 未安裝，建議安裝以使用本地開發環境${NC}"
        echo "   下載地址: https://www.docker.com/get-started"
    else
        echo -e "${GREEN}✅ Docker $(docker --version | cut -d' ' -f3 | cut -d',' -f1)${NC}"
    fi
    
    # 檢查 Git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git 未安裝${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Git $(git --version | cut -d' ' -f3)${NC}"
}

# 設定環境變數
setup_env() {
    echo -e "${BLUE}🔧 設定環境變數...${NC}"
    
    if [ ! -f .env ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ 已建立 .env 檔案${NC}"
        echo -e "${YELLOW}⚠️  請編輯 .env 檔案，填入正確的環境變數${NC}"
    else
        echo -e "${YELLOW}⚠️  .env 檔案已存在，跳過建立${NC}"
    fi
}

# 安裝後端依賴
setup_backend() {
    echo -e "${BLUE}🔧 設定後端服務...${NC}"
    
    cd backend
    
    if [ ! -d node_modules ]; then
        echo "📦 安裝後端依賴..."
        npm install
        echo -e "${GREEN}✅ 後端依賴安裝完成${NC}"
    else
        echo -e "${YELLOW}⚠️  後端依賴已安裝，跳過${NC}"
    fi
    
    cd ..
}

# 安裝前端依賴
setup_frontend() {
    echo -e "${BLUE}🔧 設定前端後台...${NC}"
    
    cd web-admin
    
    if [ ! -d node_modules ]; then
        echo "📦 安裝前端依賴..."
        npm install
        echo -e "${GREEN}✅ 前端依賴安裝完成${NC}"
    else
        echo -e "${YELLOW}⚠️  前端依賴已安裝，跳過${NC}"
    fi
    
    cd ..
}

# 設定 Flutter
setup_flutter() {
    if command -v flutter &> /dev/null; then
        echo -e "${BLUE}🔧 設定 Flutter 應用...${NC}"
        
        cd mobile
        
        echo "📦 獲取 Flutter 依賴..."
        flutter pub get
        
        echo "🔧 生成代碼..."
        flutter pub run build_runner build --delete-conflicting-outputs
        
        echo -e "${GREEN}✅ Flutter 設定完成${NC}"
        
        cd ..
    else
        echo -e "${YELLOW}⚠️  Flutter 未安裝，跳過 Flutter 設定${NC}"
    fi
}

# 設定資料庫
setup_database() {
    echo -e "${BLUE}🔧 設定資料庫...${NC}"
    
    if command -v docker &> /dev/null; then
        echo "🐳 啟動 Docker 服務..."
        docker-compose up -d postgres redis
        
        # 等待資料庫啟動
        echo "⏳ 等待資料庫啟動..."
        sleep 10
        
        echo -e "${GREEN}✅ 資料庫服務已啟動${NC}"
    else
        echo -e "${YELLOW}⚠️  Docker 未安裝，請手動設定 PostgreSQL 和 Redis${NC}"
    fi
}

# 驗證設定
verify_setup() {
    echo -e "${BLUE}🔍 驗證設定...${NC}"
    
    # 檢查後端
    cd backend
    if npm run lint > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 後端代碼檢查通過${NC}"
    else
        echo -e "${YELLOW}⚠️  後端代碼檢查有警告${NC}"
    fi
    cd ..
    
    # 檢查前端
    cd web-admin
    if npm run lint > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 前端代碼檢查通過${NC}"
    else
        echo -e "${YELLOW}⚠️  前端代碼檢查有警告${NC}"
    fi
    cd ..
    
    # 檢查 Flutter
    if command -v flutter &> /dev/null; then
        cd mobile
        if flutter analyze > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Flutter 代碼檢查通過${NC}"
        else
            echo -e "${YELLOW}⚠️  Flutter 代碼檢查有警告${NC}"
        fi
        cd ..
    fi
}

# 顯示後續步驟
show_next_steps() {
    echo -e "${GREEN}🎉 專案設定完成！${NC}"
    echo ""
    echo -e "${BLUE}📋 後續步驟:${NC}"
    echo "1. 編輯 .env 檔案，填入正確的環境變數"
    echo "2. 設定 Firebase 專案和 Supabase 專案"
    echo "3. 啟動開發服務:"
    echo "   - 後端: cd backend && npm run dev"
    echo "   - 前端: cd web-admin && npm run dev"
    echo "   - Flutter: cd mobile && flutter run"
    echo "4. 或使用 Docker: docker-compose up"
    echo ""
    echo -e "${BLUE}📚 文檔位置:${NC}"
    echo "   - API 文檔: docs/api/"
    echo "   - 資料庫文檔: docs/database/"
    echo "   - 開發歷程: docs/development/"
    echo ""
    echo -e "${BLUE}🔗 常用連結:${NC}"
    echo "   - 後端 API: http://localhost:3000"
    echo "   - 前端後台: http://localhost:3001"
    echo "   - 資料庫管理: http://localhost:5050 (pgAdmin)"
    echo "   - 郵件測試: http://localhost:8025 (MailHog)"
}

# 主函數
main() {
    echo -e "${GREEN}🚗 包車/接送叫車 APP 專案設定${NC}"
    echo "=================================="
    
    check_requirements
    setup_env
    setup_backend
    setup_frontend
    setup_flutter
    setup_database
    verify_setup
    show_next_steps
}

# 執行主函數
main "$@"
