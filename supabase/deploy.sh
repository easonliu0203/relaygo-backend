#!/bin/bash

# ============================================
# Supabase Outbox Pattern 自動部署腳本
# ============================================
# 
# 功能：自動執行可以自動化的部署步驟
# 
# 使用方式：
#   chmod +x deploy.sh
#   ./deploy.sh
# 
# ============================================

set -e  # 遇到錯誤立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 專案配置
PROJECT_REF="vlyhwegpvpnjyocqmfqc"
PROJECT_URL="https://app.supabase.com/project/${PROJECT_REF}"

# 函數：打印標題
print_header() {
  echo ""
  echo -e "${BLUE}============================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}============================================${NC}"
  echo ""
}

# 函數：打印成功訊息
print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

# 函數：打印警告訊息
print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# 函數：打印錯誤訊息
print_error() {
  echo -e "${RED}✗ $1${NC}"
}

# 函數：打印資訊訊息
print_info() {
  echo -e "${BLUE}ℹ $1${NC}"
}

# 函數：檢查命令是否存在
check_command() {
  if ! command -v $1 &> /dev/null; then
    print_error "$1 未安裝"
    return 1
  else
    print_success "$1 已安裝"
    return 0
  fi
}

# ============================================
# 開始部署
# ============================================

print_header "Supabase Outbox Pattern 部署腳本"

echo "專案資訊："
echo "  Project Ref: ${PROJECT_REF}"
echo "  Dashboard: ${PROJECT_URL}"
echo ""

# ============================================
# 步驟 0：檢查前置條件
# ============================================

print_header "步驟 0：檢查前置條件"

# 檢查 Supabase CLI
if ! check_command "supabase"; then
  print_error "請先安裝 Supabase CLI"
  echo ""
  echo "安裝方式："
  echo "  Windows (Scoop): scoop install supabase"
  echo "  macOS (Homebrew): brew install supabase/tap/supabase"
  echo "  npm: npm install -g supabase"
  exit 1
fi

# 檢查 Firebase CLI（可選）
if check_command "firebase"; then
  FIREBASE_CLI_INSTALLED=true
else
  FIREBASE_CLI_INSTALLED=false
  print_warning "Firebase CLI 未安裝（步驟 5 需要手動部署規則）"
fi

# 檢查是否已登入 Supabase
print_info "檢查 Supabase 登入狀態..."
if supabase projects list &> /dev/null; then
  print_success "已登入 Supabase"
else
  print_warning "尚未登入 Supabase"
  print_info "正在打開登入頁面..."
  supabase login
fi

# ============================================
# 步驟 1：執行資料庫 Migration
# ============================================

print_header "步驟 1：執行資料庫 Migration"

print_info "正在推送 migration 到 Supabase..."
cd "$(dirname "$0")"  # 切換到腳本所在目錄

if supabase db push; then
  print_success "Migration 執行成功"
  print_info "已創建："
  echo "  - outbox 表"
  echo "  - orders_outbox_trigger"
  echo "  - cleanup_old_outbox_events() 函數"
else
  print_error "Migration 執行失敗"
  exit 1
fi

# ============================================
# 步驟 2：配置環境變數（需手動）
# ============================================

print_header "步驟 2：配置環境變數（需手動操作）"

print_warning "此步驟需要手動在 Supabase Dashboard 中完成"
echo ""
echo "請按照以下步驟操作："
echo ""
echo "1. 前往 Firebase Console 獲取憑證："
echo "   URL: https://console.firebase.google.com"
echo ""
echo "2. 獲取 Firebase Project ID："
echo "   - 點擊齒輪圖示 ⚙️ → 專案設定"
echo "   - 複製「專案 ID」"
echo ""
echo "3. 獲取 Firebase API Key："
echo "   - 在專案設定中找到「您的應用程式」"
echo "   - 複製 Web API Key"
echo ""
echo "4. 前往 Supabase Dashboard 設置環境變數："
echo "   URL: ${PROJECT_URL}/settings/functions"
echo ""
echo "5. 添加以下兩個 Secrets："
echo "   - FIREBASE_PROJECT_ID = <您的 Firebase Project ID>"
echo "   - FIREBASE_API_KEY = <您的 Firebase API Key>"
echo ""

read -p "完成後按 Enter 繼續..."

# ============================================
# 步驟 3：部署 Edge Functions
# ============================================

print_header "步驟 3：部署 Edge Functions"

# 部署 sync-to-firestore
print_info "正在部署 sync-to-firestore 函數..."
if supabase functions deploy sync-to-firestore; then
  print_success "sync-to-firestore 部署成功"
else
  print_error "sync-to-firestore 部署失敗"
  exit 1
fi

# 部署 cleanup-outbox
print_info "正在部署 cleanup-outbox 函數..."
if supabase functions deploy cleanup-outbox; then
  print_success "cleanup-outbox 部署成功"
else
  print_error "cleanup-outbox 部署失敗"
  exit 1
fi

print_success "所有 Edge Functions 部署完成"

# ============================================
# 步驟 4：設置 Cron Job（需手動）
# ============================================

print_header "步驟 4：設置 Cron Job（需手動操作）"

print_warning "此步驟需要手動在 Supabase Dashboard 中完成"
echo ""
echo "請按照以下步驟操作："
echo ""
echo "1. 前往 Supabase Dashboard SQL Editor："
echo "   URL: ${PROJECT_URL}/sql"
echo ""
echo "2. 點擊 'New query'"
echo ""
echo "3. 複製並執行 setup_cron_jobs.sql 的內容"
echo "   檔案位置: $(pwd)/setup_cron_jobs.sql"
echo ""
echo "4. 驗證 Cron Jobs 已創建："
echo "   應該看到兩個任務："
echo "   - sync-orders-to-firestore (每 30 秒)"
echo "   - cleanup-old-outbox-events (每天凌晨 2 點)"
echo ""

read -p "完成後按 Enter 繼續..."

# ============================================
# 步驟 5：更新 Firestore 安全規則
# ============================================

print_header "步驟 5：更新 Firestore 安全規則"

print_info "Firestore 規則已自動更新（添加 orders_rt 規則）"

if [ "$FIREBASE_CLI_INSTALLED" = true ]; then
  print_info "正在部署 Firestore 規則到 Firebase..."
  cd ../firebase
  
  if firebase deploy --only firestore:rules; then
    print_success "Firestore 規則部署成功"
  else
    print_error "Firestore 規則部署失敗"
    print_warning "請手動執行: cd firebase && firebase deploy --only firestore:rules"
  fi
else
  print_warning "Firebase CLI 未安裝，請手動部署規則"
  echo ""
  echo "手動部署步驟："
  echo "1. 安裝 Firebase CLI: npm install -g firebase-tools"
  echo "2. 登入 Firebase: firebase login"
  echo "3. 部署規則: cd firebase && firebase deploy --only firestore:rules"
  echo ""
fi

# ============================================
# 部署完成
# ============================================

print_header "部署完成！"

print_success "自動化步驟已完成"
echo ""
echo "部署摘要："
echo "  ✅ 步驟 1：資料庫 Migration"
echo "  ⚠️  步驟 2：環境變數（需手動驗證）"
echo "  ✅ 步驟 3：Edge Functions"
echo "  ⚠️  步驟 4：Cron Job（需手動驗證）"
echo "  ✅ 步驟 5：Firestore 規則"
echo ""

print_info "接下來的步驟："
echo ""
echo "1. 驗證環境變數已設置："
echo "   ${PROJECT_URL}/settings/functions"
echo ""
echo "2. 驗證 Cron Jobs 已創建："
echo "   執行 SQL: SELECT * FROM cron.job;"
echo ""
echo "3. 測試同步功能："
echo "   - 在應用中創建訂單"
echo "   - 檢查 Supabase outbox 表"
echo "   - 等待 30 秒"
echo "   - 檢查 Firestore orders_rt 集合"
echo ""

print_info "詳細文檔請參考: DEPLOYMENT_GUIDE.md"

echo ""
print_success "祝部署順利！🚀"
echo ""

