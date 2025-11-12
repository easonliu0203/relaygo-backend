#!/bin/bash

# Secret Manager 快速設定腳本
# 用途：自動化設定 Google Cloud Secret Manager

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║     Google Cloud Secret Manager 設定腳本               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 專案 ID
PROJECT_ID="ride-platform-f1676"

echo "專案 ID: ${PROJECT_ID}"
echo ""

# 步驟 1: 檢查 Firebase CLI
echo "步驟 1: 檢查 Firebase CLI..."
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI 未安裝${NC}"
    echo "請執行: npm install -g firebase-tools"
    exit 1
fi
echo -e "${GREEN}✅ Firebase CLI 已安裝${NC}"
echo ""

# 步驟 2: 檢查 gcloud CLI
echo "步驟 2: 檢查 gcloud CLI..."
if ! command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}⚠️  gcloud CLI 未安裝（選用）${NC}"
    echo "如需安裝，請參考: https://cloud.google.com/sdk/docs/install"
    USE_GCLOUD=false
else
    echo -e "${GREEN}✅ gcloud CLI 已安裝${NC}"
    USE_GCLOUD=true
fi
echo ""

# 步驟 3: 設定專案
echo "步驟 3: 設定 Firebase 專案..."
firebase use ${PROJECT_ID}
echo -e "${GREEN}✅ 專案已設定${NC}"
echo ""

# 步驟 4: 啟用 Secret Manager API
echo "步驟 4: 啟用 Secret Manager API..."
if [ "$USE_GCLOUD" = true ]; then
    gcloud config set project ${PROJECT_ID}
    gcloud services enable secretmanager.googleapis.com
    echo -e "${GREEN}✅ Secret Manager API 已啟用${NC}"
else
    echo -e "${YELLOW}⚠️  請手動啟用 Secret Manager API:${NC}"
    echo "   https://console.cloud.google.com/apis/library/secretmanager.googleapis.com?project=${PROJECT_ID}"
    read -p "按 Enter 繼續..."
fi
echo ""

# 步驟 5: 創建 OPENAI_API_KEY Secret
echo "步驟 5: 創建 OPENAI_API_KEY Secret..."
echo ""
echo -e "${YELLOW}請輸入你的 OpenAI API 金鑰:${NC}"
echo "（格式：sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx）"
read -s OPENAI_KEY

if [ -z "$OPENAI_KEY" ]; then
    echo -e "${RED}❌ API 金鑰不能為空${NC}"
    exit 1
fi

echo ""
echo "正在創建 Secret..."

# 使用 Firebase CLI 創建 Secret
echo -n "${OPENAI_KEY}" | firebase functions:secrets:set OPENAI_API_KEY

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ OPENAI_API_KEY Secret 已創建${NC}"
else
    echo -e "${RED}❌ Secret 創建失敗${NC}"
    exit 1
fi
echo ""

# 步驟 6: 驗證 Secret
echo "步驟 6: 驗證 Secret..."
if [ "$USE_GCLOUD" = true ]; then
    SECRET_EXISTS=$(gcloud secrets list --filter="name:OPENAI_API_KEY" --format="value(name)")
    if [ -n "$SECRET_EXISTS" ]; then
        echo -e "${GREEN}✅ Secret 已成功創建並可在 Secret Manager 中查看${NC}"
    else
        echo -e "${RED}❌ Secret 驗證失敗${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  請手動驗證 Secret:${NC}"
    echo "   https://console.cloud.google.com/security/secret-manager?project=${PROJECT_ID}"
fi
echo ""

# 步驟 7: 設定環境變數
echo "步驟 7: 設定其他環境變數..."
echo ""

# 創建 .env 檔案（用於本地測試）
cat > .env << EOF
# 本地測試用環境變數
# 注意：生產環境的 OPENAI_API_KEY 從 Secret Manager 讀取

# Translation Settings
ENABLE_AUTO_TRANSLATE=true
TARGET_LANGUAGES=zh-TW,en,ja

# OpenAI Model Configuration
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=500
OPENAI_TEMPERATURE=0.3

# Cost Control Settings
MAX_AUTO_TRANSLATE_LENGTH=500
TRANSLATION_CACHE_TTL=600
MAX_CONCURRENT_TRANSLATIONS=2

# Retry Configuration
MAX_RETRY_ATTEMPTS=2
RETRY_DELAY_MS=1000
EOF

echo -e "${GREEN}✅ .env 檔案已創建（用於本地測試）${NC}"
echo ""

# 完成
echo "╔════════════════════════════════════════════════════════╗"
echo "║                  設定完成！                            ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "下一步："
echo "1. 安裝依賴: npm install"
echo "2. 部署 Functions: firebase deploy --only functions"
echo "3. 測試翻譯功能"
echo ""
echo "查看 Secret:"
if [ "$USE_GCLOUD" = true ]; then
    echo "  gcloud secrets list"
    echo "  gcloud secrets versions access latest --secret=OPENAI_API_KEY"
else
    echo "  https://console.cloud.google.com/security/secret-manager?project=${PROJECT_ID}"
fi
echo ""
echo -e "${GREEN}🎉 設定完成！${NC}"

