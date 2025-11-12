#!/bin/bash

# 快速修復腳本 - 取消訂單功能
# 日期: 2025-10-08

set -e  # 遇到錯誤立即退出

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo -e "${BLUE}取消訂單功能 - 快速修復腳本${NC}"
echo "=========================================="
echo ""

# ============================================
# 第一步: 檢查前端代碼修復
# ============================================

echo -e "${YELLOW}步驟 1: 檢查前端代碼修復...${NC}"
echo ""

if grep -q "class _CancelOrderDialog extends StatefulWidget" mobile/lib/apps/customer/presentation/pages/order_detail_page.dart; then
    echo -e "${GREEN}✅ 找到 StatefulWidget 實現${NC}"
else
    echo -e "${RED}❌ 未找到 StatefulWidget 實現${NC}"
    echo "請確認文件已正確修改"
    exit 1
fi

if grep -q "await Future.delayed(const Duration(milliseconds: 300))" mobile/lib/apps/customer/presentation/pages/order_detail_page.dart; then
    echo -e "${GREEN}✅ 找到延遲代碼${NC}"
else
    echo -e "${RED}❌ 未找到延遲代碼${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}前端代碼檢查通過!${NC}"
echo ""

# ============================================
# 第二步: 重新建置 Flutter 應用
# ============================================

echo -e "${YELLOW}步驟 2: 重新建置 Flutter 應用...${NC}"
echo ""

cd mobile

echo "執行 flutter clean..."
flutter clean

echo ""
echo "執行 flutter pub get..."
flutter pub get

echo ""
echo -e "${GREEN}✅ Flutter 應用建置準備完成${NC}"
echo ""

cd ..

# ============================================
# 第三步: 提示執行後端修復
# ============================================

echo "=========================================="
echo -e "${YELLOW}步驟 3: 修復後端資料庫 Schema${NC}"
echo "=========================================="
echo ""
echo -e "${RED}⚠️  此步驟需要手動執行${NC}"
echo ""
echo "請按照以下步驟操作:"
echo ""
echo "1. 打開 Supabase Dashboard"
echo "   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc"
echo ""
echo "2. 點擊左側選單的 'SQL Editor'"
echo ""
echo "3. 點擊 'New query'"
echo ""
echo "4. 複製以下文件的內容:"
echo "   ${BLUE}supabase/fix-schema-complete.sql${NC}"
echo ""
echo "5. 貼上並點擊 'Run' 執行"
echo ""
echo "6. 驗證看到以下訊息:"
echo "   ${GREEN}✅ Added cancellation_reason column to bookings table${NC}"
echo "   ${GREEN}✅ Added cancelled_at column to bookings table${NC}"
echo "   ${GREEN}✅ payments 表存在${NC}"
echo "   ${GREEN}🎉 所有修復已完成!${NC}"
echo ""

read -p "按 Enter 繼續查看 SQL 內容..."

echo ""
echo "=========================================="
echo "SQL 腳本內容:"
echo "=========================================="
echo ""
cat supabase/fix-schema-complete.sql
echo ""
echo "=========================================="
echo ""

# ============================================
# 第四步: 提示重啟管理後台
# ============================================

echo "=========================================="
echo -e "${YELLOW}步驟 4: 重啟管理後台${NC}"
echo "=========================================="
echo ""
echo "執行以下命令重啟管理後台:"
echo ""
echo "  ${BLUE}cd web-admin${NC}"
echo "  ${BLUE}npm run dev${NC}"
echo ""

# ============================================
# 第五步: 提示運行 Flutter 應用
# ============================================

echo "=========================================="
echo -e "${YELLOW}步驟 5: 運行 Flutter 應用${NC}"
echo "=========================================="
echo ""
echo "執行以下命令運行應用:"
echo ""
echo "  ${BLUE}cd mobile${NC}"
echo "  ${BLUE}flutter run --flavor customer --target lib/apps/customer/main_customer.dart${NC}"
echo ""

# ============================================
# 第六步: 測試指南
# ============================================

echo "=========================================="
echo -e "${YELLOW}步驟 6: 測試取消訂單功能${NC}"
echo "=========================================="
echo ""
echo "測試流程:"
echo ""
echo "1. 創建新訂單並完成支付"
echo "2. 進入「預約成功」頁面"
echo "3. 點擊「查看訂單詳情」"
echo "4. 點擊「取消訂單」按鈕"
echo "5. 輸入取消原因 (至少 5 個字元)"
echo "6. 點擊「確認取消」"
echo ""
echo -e "${GREEN}預期結果:${NC}"
echo ""
echo "✅ 對話框平滑關閉"
echo "✅ 顯示「訂單已取消」訊息"
echo "✅ 訂單狀態更新為「已取消」"
echo "✅ 不出現任何錯誤畫面"
echo ""
echo -e "${GREEN}後端日誌應該顯示:${NC}"
echo ""
echo "🚫 收到取消訂單請求"
echo "📋 找到訂單"
echo "✅ 訂單已取消"
echo ""

# ============================================
# 完成
# ============================================

echo "=========================================="
echo -e "${GREEN}修復腳本執行完成!${NC}"
echo "=========================================="
echo ""
echo "接下來請:"
echo ""
echo "1. 在 Supabase Dashboard 執行 SQL 腳本"
echo "2. 重啟管理後台 (cd web-admin && npm run dev)"
echo "3. 運行 Flutter 應用並測試"
echo ""
echo "詳細說明請查看: ${BLUE}完整修復指南-後端與前端.md${NC}"
echo ""

