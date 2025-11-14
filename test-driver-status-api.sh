#!/bin/bash

# ========================================
# 測試司機狀態更新 API
# ========================================

# 顏色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# API 基礎 URL
BASE_URL="http://localhost:3001/api/booking-flow"

# 測試參數（請根據實際情況修改）
BOOKING_ID="your-booking-id-here"
DRIVER_UID="your-driver-firebase-uid-here"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}測試司機狀態更新 API${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 檢查參數
if [ "$BOOKING_ID" = "your-booking-id-here" ] || [ "$DRIVER_UID" = "your-driver-firebase-uid-here" ]; then
    echo -e "${RED}❌ 錯誤：請先修改腳本中的 BOOKING_ID 和 DRIVER_UID${NC}"
    echo ""
    echo "使用方法："
    echo "1. 打開此腳本文件"
    echo "2. 修改 BOOKING_ID 為實際的訂單 ID"
    echo "3. 修改 DRIVER_UID 為實際的司機 Firebase UID"
    echo "4. 重新執行此腳本"
    exit 1
fi

# 測試 1: 測試端點
echo -e "${YELLOW}測試 1: 檢查 API 是否運行${NC}"
echo "GET $BASE_URL/test"
echo ""

response=$(curl -s -w "\n%{http_code}" "$BASE_URL/test")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ API 正在運行${NC}"
    echo "$body" | jq '.'
else
    echo -e "${RED}❌ API 未運行或無法訪問${NC}"
    echo "HTTP 狀態碼: $http_code"
    echo "$body"
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo ""

# 測試 2: 司機出發
echo -e "${YELLOW}測試 2: 司機出發${NC}"
echo "POST $BASE_URL/bookings/$BOOKING_ID/depart"
echo ""

response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/bookings/$BOOKING_ID/depart" \
  -H "Content-Type: application/json" \
  -d "{\"driverUid\": \"$DRIVER_UID\"}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo "HTTP 狀態碼: $http_code"
echo ""

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ 司機出發成功${NC}"
    echo "$body" | jq '.'
else
    echo -e "${RED}❌ 司機出發失敗${NC}"
    echo "$body" | jq '.'
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo ""

# 等待 5 秒（讓用戶有時間查看結果）
echo -e "${YELLOW}等待 5 秒後繼續測試...${NC}"
sleep 5

# 測試 3: 司機到達
echo -e "${YELLOW}測試 3: 司機到達${NC}"
echo "POST $BASE_URL/bookings/$BOOKING_ID/arrive"
echo ""

response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/bookings/$BOOKING_ID/arrive" \
  -H "Content-Type: application/json" \
  -d "{\"driverUid\": \"$DRIVER_UID\"}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo "HTTP 狀態碼: $http_code"
echo ""

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ 司機到達成功${NC}"
    echo "$body" | jq '.'
else
    echo -e "${RED}❌ 司機到達失敗${NC}"
    echo "$body" | jq '.'
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo ""

# 測試總結
echo -e "${BLUE}測試完成！${NC}"
echo ""
echo "下一步："
echo "1. 檢查 Supabase bookings 表，確認訂單狀態已更新"
echo "2. 檢查 Firestore chat_rooms/{bookingId}/messages 集合，確認系統訊息已發送"
echo "3. 檢查 Firestore orders_rt/{bookingId} 文檔，確認訂單狀態已同步"
echo ""

