#!/bin/bash

# ============================================
# 部署修復後的 Edge Function
# ============================================

echo "🚀 開始部署修復後的 Edge Function..."

# 檢查是否已登入 Supabase
if ! supabase projects list > /dev/null 2>&1; then
  echo "❌ 請先登入 Supabase CLI:"
  echo "   supabase login"
  exit 1
fi

# 部署 sync-to-firestore function
echo "📦 部署 sync-to-firestore function..."
supabase functions deploy sync-to-firestore --project-ref vlyhwegpvpnjyocqmfqc

if [ $? -eq 0 ]; then
  echo "✅ Edge Function 部署成功！"
  echo ""
  echo "📋 下一步："
  echo "1. 執行診斷查詢檢查同步狀態"
  echo "2. 手動觸發 Edge Function 測試"
  echo "3. 創建新訂單驗證完整流程"
  echo ""
  echo "📝 診斷查詢: supabase/diagnose-sync-issue.sql"
  echo "📝 測試指南: supabase/SYNC_FIX_TESTING_GUIDE.md"
else
  echo "❌ Edge Function 部署失敗"
  echo "請檢查錯誤訊息並重試"
  exit 1
fi

