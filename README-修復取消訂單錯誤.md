# 🚨 取消訂單錯誤 - 修復指南

> **問題**: 取消訂單時出現 `_dependents.isEmpty` 錯誤和後端 500 錯誤  
> **狀態**: 🔧 需要執行修復  
> **預計時間**: 10-15 分鐘

---

## 🎯 問題概述

### A) 後端問題 (API 500)
```
❌ PGRST205 Could not find the table 'public.payments'
❌ PGRST204 Could not find the 'cancellation_reason' column of 'bookings'
```

### B) 前端問題 (紅畫面)
```
❌ A TextEditingController was used after being disposed
❌ _dependents.isEmpty: is not true
```

---

## ⚡ 快速修復 (3 步驟)

### 步驟 1: 修復資料庫 (5 分鐘)

1. 打開 [Supabase Dashboard](https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc)
2. 點擊 **SQL Editor** → **New query**
3. 複製並執行 `supabase/fix-schema-complete.sql`
4. 驗證看到 `🎉 所有修復已完成!`

### 步驟 2: 重新建置前端 (3 分鐘)

```bash
cd mobile
flutter clean
flutter pub get
```

### 步驟 3: 重啟並測試 (5 分鐘)

```bash
# 重啟管理後台
cd web-admin
npm run dev

# 運行 Flutter 應用
cd mobile
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

---

## ✅ 驗證修復

### 測試流程
1. 創建訂單 → 支付 → 查看詳情
2. 點擊「取消訂單」
3. 輸入原因 → 確認

### 成功標準
- ✅ 對話框平滑關閉
- ✅ 顯示「訂單已取消」
- ✅ 無紅色錯誤畫面
- ✅ 後端日誌顯示「✅ 訂單已取消」

---

## 📚 詳細文檔

- **完整指南**: `完整修復指南-後端與前端.md`
- **SQL 腳本**: `supabase/fix-schema-complete.sql`
- **快速腳本**: `bash quick-fix.sh`

---

## 🆘 遇到問題?

### 後端仍報錯
```bash
# 重新載入 schema cache
# 在 Supabase Dashboard: Settings → Database → Reload schema cache
```

### 前端仍有錯誤
```bash
cd mobile
flutter clean
rm -rf build/
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

---

## 🔧 技術細節

### 後端修復
- ✅ 添加 `bookings.cancellation_reason` 欄位
- ✅ 添加 `bookings.cancelled_at` 欄位
- ✅ 創建 `payments` 表

### 前端修復
- ✅ 使用 `StatefulWidget` 管理 TextEditingController
- ✅ 在正確的生命週期 dispose controller
- ✅ 添加 300ms 延遲等待對話框關閉
- ✅ 檢查 `context.mounted` 避免無效操作

---

## 📞 需要幫助?

查看詳細文檔或執行:
```bash
bash quick-fix.sh
```

