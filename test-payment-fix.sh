#!/bin/bash

# 支付訂金修復測試腳本
# 用於測試修復後的支付訂金 API

echo "========================================="
echo "支付訂金修復測試腳本"
echo "========================================="
echo ""

# 設置變數
BASE_URL="http://localhost:3001/api"
BOOKING_ID="5b340e07-b169-4003-b81a-c984641d4828"  # 使用錯誤日誌中的訂單 ID
CUSTOMER_UID="test_customer_uid"  # 需要替換為實際的 Firebase UID

echo "📋 測試配置:"
echo "  Base URL: $BASE_URL"
echo "  Booking ID: $BOOKING_ID"
echo "  Customer UID: $CUSTOMER_UID"
echo ""

# 測試 1: 檢查訂單是否存在
echo "========================================="
echo "測試 1: 檢查訂單是否存在"
echo "========================================="
echo ""

echo "發送請求: GET $BASE_URL/bookings/$BOOKING_ID"
echo ""

curl -X GET "$BASE_URL/bookings/$BOOKING_ID" \
  -H "Content-Type: application/json" \
  -w "\n\nHTTP Status: %{http_code}\n" \
  -s

echo ""
echo ""

# 測試 2: 支付訂金
echo "========================================="
echo "測試 2: 支付訂金"
echo "========================================="
echo ""

echo "發送請求: POST $BASE_URL/bookings/$BOOKING_ID/pay-deposit"
echo ""

PAYMENT_REQUEST='{
  "paymentMethod": "credit_card",
  "customerUid": "'$CUSTOMER_UID'"
}'

echo "請求內容:"
echo "$PAYMENT_REQUEST"
echo ""

curl -X POST "$BASE_URL/bookings/$BOOKING_ID/pay-deposit" \
  -H "Content-Type: application/json" \
  -d "$PAYMENT_REQUEST" \
  -w "\n\nHTTP Status: %{http_code}\n" \
  -s

echo ""
echo ""

# 測試 3: 檢查支付記錄
echo "========================================="
echo "測試 3: 檢查支付記錄（需要在 Supabase Dashboard 中手動檢查）"
echo "========================================="
echo ""

echo "請在 Supabase Dashboard 中執行以下 SQL:"
echo ""
echo "SELECT * FROM payments WHERE booking_id = '$BOOKING_ID' ORDER BY created_at DESC LIMIT 1;"
echo ""

echo "========================================="
echo "測試完成"
echo "========================================="
echo ""

echo "💡 提示:"
echo "  1. 如果測試 2 返回 HTTP 200 和 success: true，表示修復成功"
echo "  2. 如果仍然出現錯誤，請檢查:"
echo "     - 訂單 ID 是否正確"
echo "     - Customer UID 是否與訂單的客戶匹配"
echo "     - Supabase 資料庫連接是否正常"
echo "  3. 檢查管理後台終端的日誌輸出"
echo ""

