#!/bin/bash

# 測試公司端網路連接修復
# 用途: 驗證 API 路由是否正確調用

echo "========================================="
echo "測試公司端網路連接修復"
echo "========================================="
echo ""

# 測試 Next.js 內部 API 路由
echo "📋 測試 1: 測試內部 API - 訂單列表"
echo "----------------------------------------"
echo "URL: http://localhost:3001/api/admin/bookings"
curl -X GET "http://localhost:3001/api/admin/bookings" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'
echo ""

echo "📋 測試 2: 測試內部 API - 儀表板統計"
echo "----------------------------------------"
echo "URL: http://localhost:3001/api/admin/dashboard/stats"
curl -X GET "http://localhost:3001/api/admin/dashboard/stats" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mock_token" \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'
echo ""

echo "📋 測試 3: 測試內部 API - 價格套餐"
echo "----------------------------------------"
echo "URL: http://localhost:3001/api/pricing/packages"
curl -X GET "http://localhost:3001/api/pricing/packages" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'
echo ""

echo "========================================="
echo "測試完成"
echo "========================================="
echo ""
echo "✅ 如果所有測試都返回 HTTP 200 且有資料，表示修復成功"
echo "❌ 如果出現錯誤，請檢查:"
echo "   1. web-admin 是否正在運行 (npm run dev)"
echo "   2. 端口 3001 是否被佔用"
echo "   3. Supabase 連接是否正常"
echo ""
echo "📝 下一步:"
echo "   1. 在瀏覽器中訪問 http://localhost:3001/orders"
echo "   2. 檢查是否能正常顯示訂單"
echo "   3. 檢查瀏覽器開發者工具的 Network 標籤"
echo "   4. 確認請求發送到 http://localhost:3001/api/admin/bookings"
echo ""

