#!/bin/bash

# 測試聊天室姓名顯示功能
# 驗證是否優先使用真實姓名，並提供降級策略

echo "========================================="
echo "測試聊天室姓名顯示功能"
echo "========================================="
echo ""

BACKEND_URL="http://localhost:3000"
DRIVER_UID="CMfTxhJFlUVDkosJPyUoJvKjCQk1"
CUSTOMER_UID="hUu4fH5dTlW9VUYm6GojXvRLdni2"

echo "測試場景："
echo "1. 如果用戶已填寫個人資料（first_name, last_name）"
echo "   → 顯示真實姓名（例如：張三）"
echo ""
echo "2. 如果用戶未填寫個人資料"
echo "   → 降級到 Email 截取（例如：customer.test）"
echo ""

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

# 步驟 3: 手動派單
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

# 步驟 5: 檢查聊天室姓名
echo "步驟 5: 檢查聊天室姓名..."
echo ""
echo "請檢查以下內容："
echo ""
echo "1. Backend 日誌中的用戶姓名："
echo "   查看 Terminal 16 的輸出，找到："
echo "   [API] 用戶姓名: { customerName: '...', driverName: '...' }"
echo ""
echo "2. Firestore Console 中的聊天室資料："
echo "   - 打開 Firebase Console: https://console.firebase.google.com/"
echo "   - 選擇專案: ride-platform-f1676"
echo "   - 進入 Firestore Database"
echo "   - 檢查 chat_rooms/$BOOKING_ID"
echo "   - 查看 customerName 和 driverName 欄位"
echo ""
echo "3. Flutter APP 中的聊天頁面："
echo "   - 客戶端和司機端都進入聊天頁面"
echo "   - 檢查顯示的對方姓名"
echo ""

echo "========================================="
echo "預期結果"
echo "========================================="
echo ""
echo "如果用戶已填寫個人資料："
echo "  - customerName: 真實姓名（例如：張三、San Zhang）"
echo "  - driverName: 真實姓名（例如：李四、Si Li）"
echo ""
echo "如果用戶未填寫個人資料："
echo "  - customerName: customer.test（從 Email 截取）"
echo "  - driverName: driver.test（從 Email 截取）"
echo ""

echo "========================================="
echo "測試完成"
echo "========================================="
echo ""
echo "訂單 ID: $BOOKING_ID"
echo ""
echo "下一步："
echo "1. 檢查 Backend 日誌中的用戶姓名"
echo "2. 檢查 Firestore 中的聊天室資料"
echo "3. 檢查 Flutter APP 中的顯示"
echo ""

