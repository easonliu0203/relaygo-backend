#!/bin/bash

# 測試司機確認接單 API
# 使用方法: bash backend/test-driver-accept-api.sh

echo "========================================="
echo "測試司機確認接單 API"
echo "========================================="
echo ""

# 測試參數
BOOKING_ID="d5352b9e-050d-42b6-8c9a-dd80a425864f"
DRIVER_UID="CMfTxhJFlUVDkosJPyUoJvKjCQk1"
API_URL="http://localhost:3000/api/booking-flow/bookings/${BOOKING_ID}/accept"

echo "📋 測試資訊:"
echo "  訂單 ID: ${BOOKING_ID}"
echo "  司機 UID: ${DRIVER_UID}"
echo "  API URL: ${API_URL}"
echo ""

echo "🔍 步驟 1: 檢查 Backend 健康狀態..."
HEALTH_CHECK=$(curl -s http://localhost:3000/health)
if [ $? -eq 0 ]; then
  echo "✅ Backend 正常運行"
  echo "${HEALTH_CHECK}" | python -m json.tool
else
  echo "❌ Backend 未運行，請先啟動 Backend"
  exit 1
fi
echo ""

echo "🔍 步驟 2: 測試 Booking Flow API..."
TEST_API=$(curl -s http://localhost:3000/api/booking-flow/test)
if [ $? -eq 0 ]; then
  echo "✅ Booking Flow API 正常"
  echo "${TEST_API}" | python -m json.tool
else
  echo "❌ Booking Flow API 異常"
  exit 1
fi
echo ""

echo "🚀 步驟 3: 調用司機確認接單 API..."
echo "請求體: {\"driverUid\": \"${DRIVER_UID}\"}"
echo ""

RESPONSE=$(curl -s -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -d "{\"driverUid\": \"${DRIVER_UID}\"}")

echo "📥 響應:"
echo "${RESPONSE}" | python -m json.tool
echo ""

# 檢查響應是否成功
if echo "${RESPONSE}" | grep -q '"success": true'; then
  echo "✅ 測試成功！司機確認接單 API 正常工作"
else
  echo "❌ 測試失敗！請檢查錯誤訊息"
  exit 1
fi

echo ""
echo "========================================="
echo "測試完成"
echo "========================================="

