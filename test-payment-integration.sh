#!/bin/bash

# GoMyPay 整合測試腳本
# 用於快速診斷 Railway 部署和 API 端點

echo "=========================================="
echo "GoMyPay 整合測試腳本"
echo "=========================================="
echo ""

# 設置 API 基礎 URL
API_BASE_URL="https://api.relaygo.pro"

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 測試結果統計
PASSED=0
FAILED=0

# 測試函數
test_endpoint() {
    local name=$1
    local url=$2
    local method=${3:-GET}
    local data=$4
    
    echo "----------------------------------------"
    echo "測試: $name"
    echo "URL: $url"
    echo "方法: $method"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$url")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "HTTP 狀態碼: $http_code"
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✅ 測試通過${NC}"
        echo "響應內容:"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ 測試失敗${NC}"
        echo "響應內容:"
        echo "$body"
        FAILED=$((FAILED + 1))
    fi
    
    echo ""
}

# 1. 測試健康檢查
echo "=========================================="
echo "1. 測試 API 健康狀態"
echo "=========================================="
test_endpoint "健康檢查" "$API_BASE_URL/health"

# 2. 測試 Pricing API
echo "=========================================="
echo "2. 測試 Pricing API"
echo "=========================================="
test_endpoint "獲取價格方案" "$API_BASE_URL/api/pricing/packages"

# 3. 測試 GoMyPay Return URL
echo "=========================================="
echo "3. 測試 GoMyPay Return URL"
echo "=========================================="
test_endpoint "GoMyPay Return URL" "$API_BASE_URL/api/payment/gomypay/return"

# 4. 測試 GoMyPay Callback URL（模擬）
echo "=========================================="
echo "4. 測試 GoMyPay Callback URL"
echo "=========================================="
echo -e "${YELLOW}⚠️  注意: 這個測試會失敗，因為需要正確的 MD5 簽名${NC}"
echo -e "${YELLOW}   這是正常的，只是確認端點存在${NC}"
echo ""

callback_data='{
  "Send_Type": "1",
  "Pay_Mode_No": "2",
  "CustomerId": "478A0C2370B2C364AACB347DE0754E14",
  "Order_No": "TEST_ORDER_123",
  "Amount": "1250",
  "Tr_No": "TEST_TRANSACTION_123",
  "Datetime": "2025-01-12 10:00:00",
  "ChkValue": "invalid_signature_for_testing"
}'

response=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "Send_Type=1&Pay_Mode_No=2&CustomerId=478A0C2370B2C364AACB347DE0754E14&Order_No=TEST_ORDER_123&Amount=1250&Tr_No=TEST_TRANSACTION_123&Datetime=2025-01-12+10:00:00&ChkValue=invalid_signature" \
  "$API_BASE_URL/api/payment/gomypay/callback")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo "HTTP 狀態碼: $http_code"
echo "響應內容: $body"

if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 400 ]; then
    echo -e "${GREEN}✅ 端點存在且可訪問${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}❌ 端點不可訪問${NC}"
    FAILED=$((FAILED + 1))
fi

echo ""

# 5. 測試支付訂金端點（需要真實訂單 ID）
echo "=========================================="
echo "5. 測試支付訂金端點"
echo "=========================================="
echo -e "${YELLOW}⚠️  注意: 這個測試需要真實的訂單 ID 和客戶 UID${NC}"
echo -e "${YELLOW}   請在 Flutter 應用中創建訂單後，手動測試此端點${NC}"
echo ""
echo "測試命令範例:"
echo ""
echo "curl -X POST $API_BASE_URL/api/bookings/{BOOKING_ID}/pay-deposit \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"paymentMethod\": \"credit_card\","
echo "    \"customerUid\": \"YOUR_FIREBASE_UID\""
echo "  }'"
echo ""

# 總結
echo "=========================================="
echo "測試總結"
echo "=========================================="
echo -e "${GREEN}通過: $PASSED${NC}"
echo -e "${RED}失敗: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 所有基礎測試通過！${NC}"
    echo ""
    echo "下一步:"
    echo "1. 在 Railway Dashboard 中確認環境變數 PAYMENT_PROVIDER=gomypay"
    echo "2. 在 Flutter 應用中創建測試訂單"
    echo "3. 測試完整的支付流程"
else
    echo -e "${RED}⚠️  部分測試失敗，請檢查 Railway 部署狀態${NC}"
    echo ""
    echo "診斷步驟:"
    echo "1. 檢查 Railway 部署日誌"
    echo "2. 確認 Railway Root Directory = /backend"
    echo "3. 確認最新代碼已部署（commit 63c9ec1）"
    echo "4. 檢查環境變數設置"
fi

echo ""
echo "=========================================="
echo "詳細測試指南: GOMYPAY-INTEGRATION-TEST-GUIDE.md"
echo "=========================================="

