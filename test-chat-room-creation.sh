#!/bin/bash

# 測試聊天室創建功能
# 此腳本測試司機確認接單後自動創建聊天室

echo "========================================="
echo "測試聊天室創建功能"
echo "========================================="
echo ""

# 配置
BACKEND_URL="http://localhost:3000"
BOOKING_ID="679dd766-91fe-4628-9564-1250b86efb82"
DRIVER_UID="CMfTxhJFlUVDkosJPyUoJvKjCQk1"

echo "📋 測試配置："
echo "   Backend URL: $BACKEND_URL"
echo "   Booking ID: $BOOKING_ID"
echo "   Driver UID: $DRIVER_UID"
echo ""

# 步驟 1: 檢查 Backend 是否運行
echo "步驟 1: 檢查 Backend 是否運行..."
HEALTH_CHECK=$(curl -s "$BACKEND_URL/health" 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "❌ Backend 未運行！"
  echo "   請先啟動 Backend："
  echo "   cd backend && npm run dev"
  exit 1
fi

echo "✅ Backend 正在運行"
echo ""

# 步驟 2: 調用司機確認接單 API
echo "步驟 2: 調用司機確認接單 API..."
echo "   POST $BACKEND_URL/api/booking-flow/bookings/$BOOKING_ID/accept"
echo ""

RESPONSE=$(curl -s -X POST \
  "$BACKEND_URL/api/booking-flow/bookings/$BOOKING_ID/accept" \
  -H "Content-Type: application/json" \
  -d "{\"driverUid\":\"$DRIVER_UID\"}")

echo "📥 API 響應："
echo "$RESPONSE" | python -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# 檢查響應是否成功
SUCCESS=$(echo "$RESPONSE" | grep -o '"success"[[:space:]]*:[[:space:]]*true' | wc -l)

if [ "$SUCCESS" -eq 0 ]; then
  echo "❌ API 調用失敗"
  exit 1
fi

echo "✅ API 調用成功"
echo ""

# 步驟 3: 檢查聊天室資訊
echo "步驟 3: 檢查聊天室資訊..."
CHAT_ROOM=$(echo "$RESPONSE" | grep -o '"chatRoom"[[:space:]]*:[[:space:]]*{[^}]*}')

if [ -z "$CHAT_ROOM" ]; then
  echo "❌ 響應中沒有聊天室資訊"
  exit 1
fi

echo "✅ 聊天室資訊已返回"
echo ""

# 步驟 4: 提示檢查 Firestore
echo "步驟 4: 檢查 Firestore..."
echo ""
echo "請手動檢查 Firestore Console："
echo "   1. 打開 Firebase Console: https://console.firebase.google.com/"
echo "   2. 選擇專案: ride-platform-f1676"
echo "   3. 進入 Firestore Database"
echo "   4. 檢查 chat_rooms 集合"
echo "   5. 查找文檔 ID: $BOOKING_ID"
echo ""
echo "預期結果："
echo "   - 文檔存在"
echo "   - customerId 和 driverId 正確"
echo "   - customerName 和 driverName 正確"
echo "   - 有系統歡迎訊息在 messages 子集合中"
echo ""

# 總結
echo "========================================="
echo "測試完成"
echo "========================================="
echo ""
echo "✅ Backend API 調用成功"
echo "✅ 聊天室資訊已返回"
echo "⏳ 請手動檢查 Firestore 確認聊天室已創建"
echo ""

