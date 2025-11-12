#!/bin/bash

# 取消訂單錯誤修復 - 測試腳本
# 日期: 2025-10-08

echo "=========================================="
echo "取消訂單 _dependents.isEmpty 錯誤修復測試"
echo "=========================================="
echo ""

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 步驟 1: 檢查修改是否存在
echo "步驟 1: 檢查代碼修改..."
echo ""

if grep -q "await Future.delayed(const Duration(milliseconds: 300))" mobile/lib/apps/customer/presentation/pages/order_detail_page.dart; then
    echo -e "${GREEN}✅ 找到延遲代碼${NC}"
else
    echo -e "${RED}❌ 未找到延遲代碼${NC}"
    echo "請確認文件已正確修改"
    exit 1
fi

if grep -q "if (!context.mounted) return;" mobile/lib/apps/customer/presentation/pages/order_detail_page.dart; then
    echo -e "${GREEN}✅ 找到 context.mounted 檢查${NC}"
else
    echo -e "${RED}❌ 未找到 context.mounted 檢查${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}代碼檢查通過!${NC}"
echo ""

# 步驟 2: 清理並重新建置
echo "步驟 2: 清理並重新建置應用..."
echo ""

cd mobile

echo "執行 flutter clean..."
flutter clean

echo ""
echo "執行 flutter pub get..."
flutter pub get

echo ""
echo -e "${GREEN}✅ 建置準備完成${NC}"
echo ""

# 步驟 3: 提示用戶運行應用
echo "=========================================="
echo "步驟 3: 運行應用並測試"
echo "=========================================="
echo ""
echo -e "${YELLOW}請執行以下命令運行應用:${NC}"
echo ""
echo "  flutter run --flavor customer --target lib/apps/customer/main_customer.dart"
echo ""
echo -e "${YELLOW}測試步驟:${NC}"
echo ""
echo "1. 創建一個新訂單並完成支付"
echo "2. 進入「預約成功」頁面"
echo "3. 點擊「查看訂單詳情」"
echo "4. 點擊「取消訂單」按鈕"
echo "5. 輸入取消原因 (至少 5 個字元)"
echo "6. 點擊「確認取消」"
echo ""
echo -e "${YELLOW}預期結果:${NC}"
echo ""
echo "✅ 對話框平滑關閉"
echo "✅ 顯示「訂單已取消」訊息"
echo "✅ 訂單狀態更新為「已取消」"
echo "✅ 不出現任何錯誤畫面"
echo ""
echo -e "${YELLOW}如果測試成功:${NC}"
echo "恭喜! _dependents.isEmpty 錯誤已修復"
echo ""
echo -e "${YELLOW}如果仍然有問題:${NC}"
echo "請查看 取消訂單_dependents錯誤修復指南.md 中的故障排除部分"
echo ""
echo "=========================================="

