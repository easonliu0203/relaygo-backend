#!/bin/bash

# 測試 Supabase Schema 修復
# 用途: 驗證 user_profiles 和 drivers 表是否正確創建

echo "========================================="
echo "測試 Supabase Schema 修復"
echo "========================================="
echo ""

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Supabase 配置（從環境變數讀取）
SUPABASE_URL="${NEXT_PUBLIC_SUPABASE_URL}"
SUPABASE_KEY="${NEXT_PUBLIC_SUPABASE_ANON_KEY}"

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
    echo -e "${YELLOW}⚠️  未找到 Supabase 環境變數${NC}"
    echo "請設置以下環境變數:"
    echo "  export NEXT_PUBLIC_SUPABASE_URL='your_supabase_url'"
    echo "  export NEXT_PUBLIC_SUPABASE_ANON_KEY='your_supabase_key'"
    echo ""
    echo "或者在 web-admin/.env.local 中設置"
    exit 1
fi

echo "📋 測試 1: 檢查 user_profiles 表"
echo "----------------------------------------"
RESPONSE=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/user_profiles?select=count" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: count=exact")

if echo "$RESPONSE" | grep -q "error"; then
    echo -e "${RED}❌ user_profiles 表不存在或無法訪問${NC}"
    echo "錯誤: $RESPONSE"
else
    echo -e "${GREEN}✅ user_profiles 表存在${NC}"
    echo "回應: $RESPONSE"
fi
echo ""

echo "📋 測試 2: 檢查 drivers 表"
echo "----------------------------------------"
RESPONSE=$(curl -s -X GET "${SUPABASE_URL}/rest/v1/drivers?select=count" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_KEY}" \
  -H "Content-Type: application/json" \
  -H "Prefer: count=exact")

if echo "$RESPONSE" | grep -q "error"; then
    echo -e "${RED}❌ drivers 表不存在或無法訪問${NC}"
    echo "錯誤: $RESPONSE"
else
    echo -e "${GREEN}✅ drivers 表存在${NC}"
    echo "回應: $RESPONSE"
fi
echo ""

echo "📋 測試 3: 測試訂單 API（含關聯查詢）"
echo "----------------------------------------"
echo "URL: http://localhost:3001/api/admin/bookings?limit=1"
RESPONSE=$(curl -s -X GET "http://localhost:3001/api/admin/bookings?limit=1" \
  -H "Content-Type: application/json")

if echo "$RESPONSE" | grep -q "success.*true"; then
    echo -e "${GREEN}✅ 訂單 API 查詢成功${NC}"
    echo "$RESPONSE" | jq '.'
elif echo "$RESPONSE" | grep -q "PGRST200"; then
    echo -e "${RED}❌ 仍然出現外鍵關聯錯誤${NC}"
    echo "$RESPONSE" | jq '.'
else
    echo -e "${YELLOW}⚠️  API 返回異常${NC}"
    echo "$RESPONSE" | jq '.'
fi
echo ""

echo "========================================="
echo "測試完成"
echo "========================================="
echo ""
echo "📝 下一步:"
echo "   1. 如果 user_profiles 或 drivers 表不存在:"
echo "      - 執行 migration: supabase/migrations/20250104_create_user_profiles_and_drivers.sql"
echo "      - 或在 Supabase Dashboard 中手動執行"
echo ""
echo "   2. 如果表存在但 API 仍然失敗:"
echo "      - 檢查 Supabase schema cache"
echo "      - 重新啟動 web-admin 服務"
echo "      - 檢查 API 查詢語法"
echo ""
echo "   3. 如果一切正常:"
echo "      - 訪問 http://localhost:3001/orders 驗證頁面"
echo "      - 確認訂單資料正常顯示"
echo ""

