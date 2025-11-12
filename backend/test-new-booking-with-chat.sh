#!/bin/bash

# 測試完整流程：創建訂單 → 支付訂金 → 手動派單 → 司機確認接單 → 檢查聊天室

echo "========================================="
echo "測試聊天室自動創建功能"
echo "========================================="
echo ""

BACKEND_URL="http://localhost:3000"
DRIVER_UID="CMfTxhJFlUVDkosJPyUoJvKjCQk1"
CUSTOMER_UID="hUu4fH5dTlW9VUYm6GojXvRLdni2"

# 步驟 1: 創建訂單
echo "步驟 1: 創建訂單..."
CREATE_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/bookings" \
  -H "Content-Type: application/json" \
  -d '{
    "customerUid": "'$CUSTOMER_UID'",
    "pickupAddress": "測試地點",
    "bookingTime": "2025-10-15T10:00:00.000",
    "passengerCount": 1
  }')

BOOKING_ID=$(echo "$CREATE_RESPONSE" | python -c "import sys, json; print(json.load(sys.stdin)['data']['bookingId'])" 2>/dev/null)

if [ -z "$BOOKING_ID" ]; then
  echo "❌ 創建訂單失敗"
  echo "$CREATE_RESPONSE"
  exit 1
fi

echo "✅ 訂單創建成功: $BOOKING_ID"
echo ""

# 步驟 2: 支付訂金
echo "步驟 2: 支付訂金..."
PAY_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/bookings/$BOOKING_ID/pay-deposit" \
  -H "Content-Type: application/json" \
  -d '{
    "paymentMethod": "credit_card",
    "customerUid": "'$CUSTOMER_UID'"
  }')

echo "$PAY_RESPONSE" | grep -q '"success":true'
if [ $? -ne 0 ]; then
  echo "❌ 支付訂金失敗"
  echo "$PAY_RESPONSE"
  exit 1
fi

echo "✅ 訂金支付成功"
echo ""

# 步驟 3: 手動派單（需要手動操作）
echo "步驟 3: 手動派單..."
echo "⚠️  請手動在 Supabase Table Editor 中："
echo "   1. 打開 bookings 表"
echo "   2. 找到訂單 ID: $BOOKING_ID"
echo "   3. 設置 driver_id = 416556f9-adbf-4c2e-920f-164d80f5307a"
echo "   4. 設置 status = 'matched'"
echo ""
echo "完成後按 Enter 繼續..."
read

# 步驟 4: 司機確認接單
echo "步驟 4: 司機確認接單..."
ACCEPT_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/booking-flow/bookings/$BOOKING_ID/accept" \
  -H "Content-Type: application/json" \
  -d "{\"driverUid\":\"$DRIVER_UID\"}")

echo "$ACCEPT_RESPONSE" | python -m json.tool 2>/dev/null || echo "$ACCEPT_RESPONSE"
echo ""

echo "$ACCEPT_RESPONSE" | grep -q '"success":true'
if [ $? -ne 0 ]; then
  echo "❌ 司機確認接單失敗"
  exit 1
fi

echo "✅ 司機確認接單成功"
echo ""

# 步驟 5: 檢查聊天室
echo "步驟 5: 檢查聊天室..."
echo "請手動檢查 Firestore Console："
echo "   1. 打開 Firebase Console: https://console.firebase.google.com/"
echo "   2. 選擇專案: ride-platform-f1676"
echo "   3. 進入 Firestore Database"
echo "   4. 檢查 chat_rooms 集合"
echo "   5. 查找文檔 ID: $BOOKING_ID"
echo ""
echo "預期結果："
echo "   - 文檔存在"
echo "   - customerId: $CUSTOMER_UID (Firebase UID，不是 Supabase UUID)"
echo "   - driverId: $DRIVER_UID"
echo "   - messages 子集合中有系統歡迎訊息"
echo ""

echo "========================================="
echo "測試完成"
echo "========================================="
echo ""
echo "訂單 ID: $BOOKING_ID"
echo "客戶 Firebase UID: $CUSTOMER_UID"
echo "司機 Firebase UID: $DRIVER_UID"
echo ""

