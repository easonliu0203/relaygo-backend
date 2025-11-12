#!/bin/bash

# 開發環境啟動腳本
# 用於同時啟動所有開發服務

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 檢查是否在專案根目錄
if [ ! -f "package.json" ] && [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ 請在專案根目錄執行此腳本${NC}"
    exit 1
fi

# 顯示幫助資訊
show_help() {
    echo -e "${GREEN}🚗 包車/接送叫車 APP 開發環境啟動腳本${NC}"
    echo ""
    echo "用法: $0 [選項]"
    echo ""
    echo "選項:"
    echo "  -h, --help     顯示此幫助資訊"
    echo "  -d, --docker   使用 Docker 啟動所有服務"
    echo "  -b, --backend  只啟動後端服務"
    echo "  -f, --frontend 只啟動前端服務"
    echo "  -m, --mobile   只啟動 Flutter 應用"
    echo "  -a, --all      啟動所有服務 (預設)"
    echo "  --stop         停止所有服務"
    echo "  --logs         查看服務日誌"
    echo ""
    echo "範例:"
    echo "  $0              # 啟動所有服務"
    echo "  $0 -d           # 使用 Docker 啟動"
    echo "  $0 -b           # 只啟動後端"
    echo "  $0 --stop       # 停止所有服務"
}

# 檢查服務狀態
check_service_status() {
    local service=$1
    local port=$2
    
    if curl -s "http://localhost:$port" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service 正在運行 (Port: $port)${NC}"
        return 0
    else
        echo -e "${RED}❌ $service 未運行 (Port: $port)${NC}"
        return 1
    fi
}

# 啟動後端服務
start_backend() {
    echo -e "${BLUE}🔧 啟動後端服務...${NC}"
    
    if [ ! -d "backend/node_modules" ]; then
        echo "📦 安裝後端依賴..."
        cd backend && npm install && cd ..
    fi
    
    cd backend
    npm run dev &
    BACKEND_PID=$!
    cd ..
    
    echo -e "${GREEN}✅ 後端服務已啟動 (PID: $BACKEND_PID)${NC}"
    echo "   URL: http://localhost:3000"
}

# 啟動前端服務
start_frontend() {
    echo -e "${BLUE}🔧 啟動前端服務...${NC}"
    
    if [ ! -d "web-admin/node_modules" ]; then
        echo "📦 安裝前端依賴..."
        cd web-admin && npm install && cd ..
    fi
    
    cd web-admin
    npm run dev &
    FRONTEND_PID=$!
    cd ..
    
    echo -e "${GREEN}✅ 前端服務已啟動 (PID: $FRONTEND_PID)${NC}"
    echo "   URL: http://localhost:3001"
}

# 啟動 Flutter 應用
start_mobile() {
    if command -v flutter &> /dev/null; then
        echo -e "${BLUE}🔧 啟動 Flutter 應用...${NC}"
        
        cd mobile
        flutter pub get
        flutter run &
        MOBILE_PID=$!
        cd ..
        
        echo -e "${GREEN}✅ Flutter 應用已啟動 (PID: $MOBILE_PID)${NC}"
    else
        echo -e "${YELLOW}⚠️  Flutter 未安裝，跳過 Flutter 應用啟動${NC}"
    fi
}

# 使用 Docker 啟動所有服務
start_docker() {
    echo -e "${BLUE}🐳 使用 Docker 啟動所有服務...${NC}"
    
    # 檢查 Docker 是否運行
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker 未運行，請先啟動 Docker${NC}"
        exit 1
    fi
    
    # 啟動服務
    docker-compose up -d
    
    echo -e "${GREEN}✅ Docker 服務已啟動${NC}"
    echo ""
    echo "服務狀態:"
    docker-compose ps
    
    echo ""
    echo "服務 URL:"
    echo "   - 後端 API: http://localhost:3000"
    echo "   - 前端後台: http://localhost:3001"
    echo "   - 資料庫管理: http://localhost:5050"
    echo "   - 郵件測試: http://localhost:8025"
}

# 停止所有服務
stop_services() {
    echo -e "${BLUE}🛑 停止所有服務...${NC}"
    
    # 停止 Docker 服務
    if [ -f "docker-compose.yml" ]; then
        docker-compose down
        echo -e "${GREEN}✅ Docker 服務已停止${NC}"
    fi
    
    # 停止 Node.js 進程
    pkill -f "npm run dev" || true
    pkill -f "next dev" || true
    pkill -f "nodemon" || true
    
    # 停止 Flutter 進程
    pkill -f "flutter run" || true
    
    echo -e "${GREEN}✅ 所有服務已停止${NC}"
}

# 查看服務日誌
show_logs() {
    echo -e "${BLUE}📋 查看服務日誌...${NC}"
    
    if [ -f "docker-compose.yml" ]; then
        docker-compose logs -f
    else
        echo -e "${YELLOW}⚠️  請使用 Docker 模式查看日誌${NC}"
    fi
}

# 等待服務啟動
wait_for_services() {
    echo -e "${BLUE}⏳ 等待服務啟動...${NC}"
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if check_service_status "後端" 3000 > /dev/null 2>&1; then
            break
        fi
        
        attempt=$((attempt + 1))
        sleep 2
        echo -n "."
    done
    
    echo ""
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${YELLOW}⚠️  服務啟動時間較長，請稍後檢查${NC}"
    else
        echo -e "${GREEN}✅ 服務已就緒${NC}"
    fi
}

# 顯示服務狀態
show_status() {
    echo -e "${BLUE}📊 服務狀態檢查...${NC}"
    echo ""
    
    check_service_status "後端 API" 3000
    check_service_status "前端後台" 3001
    check_service_status "PostgreSQL" 5432
    check_service_status "Redis" 6379
    check_service_status "pgAdmin" 5050
    check_service_status "MailHog" 8025
}

# 清理函數
cleanup() {
    echo ""
    echo -e "${YELLOW}🧹 清理進程...${NC}"
    
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$MOBILE_PID" ]; then
        kill $MOBILE_PID 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ 清理完成${NC}"
}

# 設定信號處理
trap cleanup EXIT INT TERM

# 主函數
main() {
    local use_docker=false
    local backend_only=false
    local frontend_only=false
    local mobile_only=false
    local stop_services=false
    local show_logs_only=false
    
    # 解析參數
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--docker)
                use_docker=true
                shift
                ;;
            -b|--backend)
                backend_only=true
                shift
                ;;
            -f|--frontend)
                frontend_only=true
                shift
                ;;
            -m|--mobile)
                mobile_only=true
                shift
                ;;
            -a|--all)
                # 預設行為，不需要特別處理
                shift
                ;;
            --stop)
                stop_services=true
                shift
                ;;
            --logs)
                show_logs_only=true
                shift
                ;;
            --status)
                show_status
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 未知選項: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 執行對應操作
    if [ "$stop_services" = true ]; then
        stop_services
        exit 0
    fi
    
    if [ "$show_logs_only" = true ]; then
        show_logs
        exit 0
    fi
    
    if [ "$use_docker" = true ]; then
        start_docker
        exit 0
    fi
    
    echo -e "${GREEN}🚗 包車/接送叫車 APP 開發環境啟動${NC}"
    echo "=================================="
    
    # 根據參數啟動對應服務
    if [ "$backend_only" = true ]; then
        start_backend
    elif [ "$frontend_only" = true ]; then
        start_frontend
    elif [ "$mobile_only" = true ]; then
        start_mobile
    else
        # 啟動所有服務
        start_backend
        sleep 2
        start_frontend
        sleep 2
        start_mobile
    fi
    
    wait_for_services
    show_status
    
    echo ""
    echo -e "${GREEN}🎉 開發環境已啟動！${NC}"
    echo "按 Ctrl+C 停止所有服務"
    
    # 保持腳本運行
    wait
}

# 執行主函數
main "$@"
