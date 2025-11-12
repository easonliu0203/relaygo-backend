#!/bin/bash

# 測試公司端訂單管理 API
# 用途: 驗證 /api/admin/bookings 端點是否正常工作

echo "========================================="
echo "測試公司端訂單管理 API"
echo "========================================="
echo ""

# API 基礎 URL
BASE_URL="http://localhost:3001"
API_ENDPOINT="${BASE_URL}/api/admin/bookings"

echo "📋 測試 1: 獲取所有訂單"
echo "----------------------------------------"
curl -X GET "${API_ENDPOINT}" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'
echo ""

echo "📋 測試 2: 獲取待處理訂單 (status=pending)"
echo "----------------------------------------"
curl -X GET "${API_ENDPOINT}?status=pending" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'
echo ""

echo "📋 測試 3: 獲取已確認訂單 (status=confirmed)"
echo "----------------------------------------"
curl -X GET "${API_ENDPOINT}?status=confirmed" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'
echo ""

echo "📋 測試 4: 獲取已完成訂單 (status=completed)"
echo "----------------------------------------"
curl -X GET "${API_ENDPOINT}?status=completed" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'
echo ""

echo "📋 測試 5: 搜尋訂單 (search=BK)"
echo "----------------------------------------"
curl -X GET "${API_ENDPOINT}?search=BK" \
  -H "Content-Type: application/json" \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'
echo ""

echo "========================================="
echo "測試完成"
echo "========================================="
echo ""
echo "✅ 如果所有測試都返回 HTTP 200 且有 success: true，表示 API 正常工作"
echo "❌ 如果出現錯誤，請檢查:"
echo "   1. web-admin 是否正在運行 (npm run dev)"
echo "   2. Supabase 連接是否正常"
echo "   3. bookings 表中是否有資料"
echo ""
echo "📝 檢查 Supabase 資料:"
echo "   在 Supabase SQL Editor 中執行:"
echo "   SELECT COUNT(*) FROM bookings;"
echo "   SELECT status, COUNT(*) FROM bookings GROUP BY status;"
echo ""

