#!/bin/bash
# ============================================
# 測試後端 API 端點
# ============================================

echo ""
echo "============================================"
echo "🧪 測試後端 API 端點"
echo "============================================"
echo ""

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 測試健康檢查
echo "1️⃣  測試健康檢查端點"
echo "   GET http://localhost:3000/health"
echo ""
response=$(curl -s -w "\n%{http_code}" http://localhost:3000/health)
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ 健康檢查成功${NC}"
    echo "   響應: $body"
else
    echo -e "${RED}❌ 健康檢查失敗 (HTTP $http_code)${NC}"
fi

echo ""
echo "============================================"
echo ""

# 測試創建訂單（需要有效的客戶 UID）
echo "2️⃣  測試創建訂單端點"
echo "   POST http://localhost:3000/api/bookings"
echo ""
echo -e "${YELLOW}⚠️  注意：此測試需要有效的客戶 UID${NC}"
echo "   如果失敗，請先在數據庫中創建測試客戶"
echo ""

# 獲取測試客戶 UID（從 Supabase）
# 這裡使用示例 UID，實際使用時需要替換
TEST_CUSTOMER_UID="test-customer-uid"

response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:3000/api/bookings \
  -H "Content-Type: application/json" \
  -d "{
    \"customerUid\": \"$TEST_CUSTOMER_UID\",
    \"pickupAddress\": \"測試地點 A\",
    \"pickupLatitude\": 25.0330,
    \"pickupLongitude\": 121.5654,
    \"dropoffAddress\": \"測試地點 B\",
    \"bookingTime\": \"2025-10-17T10:00:00Z\",
    \"passengerCount\": 2,
    \"packageName\": \"8小時包車\",
    \"estimatedFare\": 1500
  }")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ 創建訂單成功${NC}"
    echo "   響應: $body"
elif [ "$http_code" = "404" ]; then
    echo -e "${YELLOW}⚠️  客戶不存在 (HTTP $http_code)${NC}"
    echo "   請先創建測試客戶"
elif [ "$http_code" = "400" ]; then
    echo -e "${YELLOW}⚠️  請求參數錯誤 (HTTP $http_code)${NC}"
    echo "   響應: $body"
else
    echo -e "${RED}❌ 創建訂單失敗 (HTTP $http_code)${NC}"
    echo "   響應: $body"
fi

echo ""
echo "============================================"
echo ""

# 總結
echo "📊 測試總結"
echo ""
echo "如果所有測試都通過："
echo "  ✅ 後端服務器運行正常"
echo "  ✅ API 端點可用"
echo "  ✅ 客戶端應該能夠正常連接"
echo ""
echo "如果測試失敗："
echo "  1. 檢查後端服務器是否運行"
echo "  2. 檢查數據庫連接"
echo "  3. 檢查環境變數配置"
echo "  4. 查看服務器日誌"
echo ""

