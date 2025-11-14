#!/bin/bash

# 測試支付尾款功能
# 使用方法：./test-balance-payment.sh <bookingId> <customerUid>

BOOKING_ID=$1
CUSTOMER_UID=$2

if [ -z "$BOOKING_ID" ] || [ -z "$CUSTOMER_UID" ]; then
  echo "❌ 使用方法: ./test-balance-payment.sh <bookingId> <customerUid>"
  echo "範例: ./test-balance-payment.sh 123e4567-e89b-12d3-a456-426614174000 abc123xyz"
  exit 1
fi

echo "🧪 測試支付尾款功能"
echo "================================"
echo "訂單 ID: $BOOKING_ID"
echo "客戶 UID: $CUSTOMER_UID"
echo "================================"
echo ""

# 設置 API URL
API_URL="http://localhost:3000/api/booking-flow/bookings/$BOOKING_ID/pay-balance"

echo "📡 調用 API: $API_URL"
echo ""

# 調用 API
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"paymentMethod\": \"credit_card\",
    \"customerUid\": \"$CUSTOMER_UID\"
  }")

echo "📥 API 響應:"
echo "$RESPONSE" | jq '.'
echo ""

# 檢查響應
SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
REQUIRES_REDIRECT=$(echo "$RESPONSE" | jq -r '.data.requiresRedirect')
PAYMENT_URL=$(echo "$RESPONSE" | jq -r '.data.paymentUrl')

if [ "$SUCCESS" = "true" ]; then
  echo "✅ API 調用成功"
  
  if [ "$REQUIRES_REDIRECT" = "true" ]; then
    echo "✅ 需要跳轉到支付頁面"
    echo "🔗 支付 URL: $PAYMENT_URL"
    echo ""
    echo "📱 客戶端應該跳轉到 /payment-webview 並顯示此 URL"
  else
    echo "ℹ️  不需要跳轉（Mock 支付）"
    echo "📱 客戶端應該直接跳轉到 /booking-complete"
  fi
else
  echo "❌ API 調用失敗"
  ERROR=$(echo "$RESPONSE" | jq -r '.error')
  echo "錯誤訊息: $ERROR"
fi

echo ""
echo "================================"
echo "測試完成"
echo "================================"

