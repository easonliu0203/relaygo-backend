#!/bin/bash
# ========================================
# Flutter APP 實機測試啟動腳本
# ========================================
#
# 使用方法：
# 1. 找到你的電腦 IP 地址（ifconfig 或 ip addr）
# 2. 修改下面的 DEV_IP 變量
# 3. 確保實機和電腦在同一 WiFi 網絡
# 4. 運行此腳本: chmod +x run-device-testing.sh && ./run-device-testing.sh
#

# ✅ 已配置為您的電腦 IP 地址
# 如果 IP 變更，請重新運行: node scripts/test-device-connection.js
DEV_IP="192.168.0.152"

echo "========================================"
echo "Flutter APP 實機測試"
echo "========================================"
echo ""
echo "當前配置:"
echo "- 開發服務器 IP: $DEV_IP"
echo "- API URL: http://$DEV_IP:3001/api"
echo "- WebSocket URL: ws://$DEV_IP:3001"
echo ""
echo "請確認:"
echo "1. 實機和電腦在同一 WiFi 網絡"
echo "2. Next.js 服務器正在運行 (npm run dev)"
echo "3. 防火牆允許端口 3000 和 3001"
echo ""
read -p "按 Enter 繼續..."

echo ""
echo "正在啟動 Flutter APP..."
echo ""

flutter run \
  --dart-define=DEV_API_URL=http://$DEV_IP:3001/api \
  --dart-define=DEV_WS_URL=ws://$DEV_IP:3001 \
  --flavor customer \
  --target lib/apps/customer/main_customer.dart

