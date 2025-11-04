#!/bin/bash

# =====================================================
# 司機評價管理功能 - API 測試腳本
# 創建日期: 2025-01-24
# 說明: 測試評價相關的 API 端點
# =====================================================

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API 基礎 URL
BACKEND_API="http://localhost:3000/api"
ADMIN_API="http://localhost:3001/api/admin"

# 測試數據
CUSTOMER_UID="test_customer_uid_123"
DRIVER_UID="test_driver_uid_456"
BOOKING_ID="test_booking_id_789"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}司機評價管理功能 - API 測試${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# =====================================================
# 測試 1: 客戶提交評價
# =====================================================
echo -e "${YELLOW}測試 1: 客戶提交評價${NC}"
echo -e "POST ${BACKEND_API}/reviews"
echo ""

RESPONSE=$(curl -s -X POST "${BACKEND_API}/reviews" \
  -H "Content-Type: application/json" \
  -d "{
    \"customerUid\": \"${CUSTOMER_UID}\",
    \"bookingId\": \"${BOOKING_ID}\",
    \"rating\": 5,
    \"comment\": \"司機服務很好，準時到達！\",
    \"isAnonymous\": false
  }")

echo "響應: $RESPONSE"
echo ""

# 檢查響應是否包含 success
if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✅ 測試 1 通過${NC}"
  REVIEW_ID=$(echo "$RESPONSE" | grep -o '"reviewId":"[^"]*"' | cut -d'"' -f4)
  echo -e "評價 ID: ${REVIEW_ID}"
else
  echo -e "${RED}❌ 測試 1 失敗${NC}"
fi
echo ""
echo "---"
echo ""

# =====================================================
# 測試 2: 司機查看評價列表
# =====================================================
echo -e "${YELLOW}測試 2: 司機查看評價列表${NC}"
echo -e "GET ${BACKEND_API}/reviews/driver?driverUid=${DRIVER_UID}"
echo ""

RESPONSE=$(curl -s -X GET "${BACKEND_API}/reviews/driver?driverUid=${DRIVER_UID}&page=1&limit=20&status=approved")

echo "響應: $RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✅ 測試 2 通過${NC}"
  TOTAL=$(echo "$RESPONSE" | grep -o '"total":[0-9]*' | cut -d':' -f2)
  echo -e "總評價數: ${TOTAL}"
else
  echo -e "${RED}❌ 測試 2 失敗${NC}"
fi
echo ""
echo "---"
echo ""

# =====================================================
# 測試 3: 司機查看評價統計
# =====================================================
echo -e "${YELLOW}測試 3: 司機查看評價統計${NC}"
echo -e "GET ${BACKEND_API}/reviews/driver/statistics?driverUid=${DRIVER_UID}"
echo ""

RESPONSE=$(curl -s -X GET "${BACKEND_API}/reviews/driver/statistics?driverUid=${DRIVER_UID}")

echo "響應: $RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✅ 測試 3 通過${NC}"
  AVG_RATING=$(echo "$RESPONSE" | grep -o '"averageRating":[0-9.]*' | cut -d':' -f2)
  echo -e "平均評分: ${AVG_RATING}"
else
  echo -e "${RED}❌ 測試 3 失敗${NC}"
fi
echo ""
echo "---"
echo ""

# =====================================================
# 測試 4: 管理員查看評價列表
# =====================================================
echo -e "${YELLOW}測試 4: 管理員查看評價列表${NC}"
echo -e "GET ${ADMIN_API}/reviews?status=pending"
echo ""

RESPONSE=$(curl -s -X GET "${ADMIN_API}/reviews?status=pending&page=1&limit=20")

echo "響應: $RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✅ 測試 4 通過${NC}"
  PENDING_COUNT=$(echo "$RESPONSE" | grep -o '"total":[0-9]*' | cut -d':' -f2)
  echo -e "待審核評價數: ${PENDING_COUNT}"
else
  echo -e "${RED}❌ 測試 4 失敗${NC}"
fi
echo ""
echo "---"
echo ""

# =====================================================
# 測試 5: 管理員審核評價（需要有效的 reviewId）
# =====================================================
if [ -n "$REVIEW_ID" ]; then
  echo -e "${YELLOW}測試 5: 管理員審核評價${NC}"
  echo -e "POST ${ADMIN_API}/reviews/${REVIEW_ID}/review"
  echo ""

  RESPONSE=$(curl -s -X POST "${ADMIN_API}/reviews/${REVIEW_ID}/review" \
    -H "Content-Type: application/json" \
    -d "{
      \"status\": \"approved\",
      \"adminNotes\": \"內容符合規範，批准通過\"
    }")

  echo "響應: $RESPONSE"
  echo ""

  if echo "$RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ 測試 5 通過${NC}"
  else
    echo -e "${RED}❌ 測試 5 失敗${NC}"
  fi
  echo ""
  echo "---"
  echo ""
else
  echo -e "${YELLOW}測試 5: 跳過（沒有有效的 reviewId）${NC}"
  echo ""
fi

# =====================================================
# 測試 6: 管理員查看統計報表
# =====================================================
echo -e "${YELLOW}測試 6: 管理員查看統計報表${NC}"
echo -e "GET ${ADMIN_API}/reviews/statistics"
echo ""

RESPONSE=$(curl -s -X GET "${ADMIN_API}/reviews/statistics")

echo "響應: $RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo -e "${GREEN}✅ 測試 6 通過${NC}"
  TOTAL_REVIEWS=$(echo "$RESPONSE" | grep -o '"totalReviews":[0-9]*' | cut -d':' -f2)
  echo -e "總評價數: ${TOTAL_REVIEWS}"
else
  echo -e "${RED}❌ 測試 6 失敗${NC}"
fi
echo ""
echo "---"
echo ""

# =====================================================
# 測試總結
# =====================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}測試完成${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}注意事項：${NC}"
echo "1. 確保 Backend API (port 3000) 正在運行"
echo "2. 確保 Web Admin (port 3001) 正在運行"
echo "3. 確保數據庫遷移已執行"
echo "4. 測試數據需要在數據庫中存在對應的用戶和訂單"
echo ""
echo -e "${YELLOW}如果測試失敗，請檢查：${NC}"
echo "- 數據庫連接是否正常"
echo "- 環境變數是否正確設置"
echo "- 測試數據是否存在"
echo "- API 路由是否正確註冊"
echo ""

