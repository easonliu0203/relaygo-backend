# 🚨 整數類型錯誤 - 快速修復

**錯誤**: `type 'double' is not a subtype of type 'int'`  
**狀態**: ✅ 已修復 (Flutter 代碼 + Edge Function)

---

## ⚡ 立即測試

### 步驟 1: 重新建置應用

```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 步驟 2: 測試訂單頁面

1. 打開應用
2. 進入「我的訂單」
3. 切換「進行中」和「歷史訂單」標籤

**預期結果**: ✅ 頁面正常載入,不出現錯誤

---

## 🔧 已完成的修復

### 1. Flutter 代碼修改 ✅

**文件**: `mobile/lib/core/models/booking_order.dart`

**修改內容**:
- 添加 `_parseInt()` 函數 - 支持 int 和 double 兩種格式
- 添加 `_parseOptionalInt()` 函數 - 支持 null 值
- 更新 `fromFirestore()` 方法使用這些函數

**效果**:
- ✅ 支持舊資料 (double 格式)
- ✅ 支持新資料 (int 格式)
- ✅ 向後兼容,不會因為資料格式導致錯誤

### 2. Edge Function 修改 ✅

**文件**: `supabase/functions/sync-to-firestore/index.ts`

**修改內容**:
- 使用實際的 `passengerCount` 值 (不再硬編碼為 1)
- 使用實際的 `luggageCount` 值 (不再是 null)
- 使用 `_integer` 標記確保正確格式

**效果**:
- ✅ 新訂單使用實際的乘客數量
- ✅ 新訂單使用實際的行李數量
- ✅ Firestore 存儲為 integerValue 格式

---

## 🚀 部署 Edge Function (重要)

**目的**: 確保新訂單使用正確的資料格式

```bash
# 部署 Edge Function
cd supabase/functions
supabase functions deploy sync-to-firestore

# 驗證部署
supabase functions list
```

---

## 📋 可選步驟 (推薦)

### 遷移 Firestore 資料

**目的**: 將舊資料轉換為正確的 int 格式

**步驟**:

```bash
# 1. 安裝依賴
cd firebase
npm install firebase-admin

# 2. 設置 Firebase 憑證
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"

# 3. 驗證資料格式 (可選)
node verify-integer-fields.js

# 4. 遷移資料
node migrate-integer-fields.js
```

**注意**: 即使不遷移,應用也能正常工作 (因為 Flutter 代碼已支持兩種格式)

---

## ✅ 驗證修復

### 測試清單

- [ ] 「進行中」頁面正常載入
- [ ] 「歷史訂單」頁面正常載入
- [ ] 訂單詳情正確顯示乘客數量
- [ ] 創建新訂單時乘客數量正確記錄
- [ ] 不出現類型錯誤

### 測試新訂單

1. 創建新訂單
2. 設置乘客數量為 3 人
3. 完成支付
4. 查看訂單詳情

**預期結果**:
- ✅ 乘客數量顯示為 3 人 (不是 1 人)
- ✅ Firestore 中存儲為 integerValue 格式

---

## 🔍 如果仍有問題

### 問題 1: 仍然出現錯誤

**解決**:
```bash
cd mobile
flutter clean
rm -rf build/
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 問題 2: 新訂單的乘客數量仍然是 1

**原因**: Edge Function 未部署

**解決**:
```bash
cd supabase/functions
supabase functions deploy sync-to-firestore
```

### 問題 3: 數值顯示不正確

**檢查**:
- 查看 Firestore 中的資料格式
- 運行驗證腳本: `node firebase/verify-integer-fields.js`

---

## 📚 詳細文檔

查看完整說明: `整數類型錯誤修復指南.md`

---

## 🎉 預期效果

1. ✅ 訂單列表正常顯示
2. ✅ 不出現類型錯誤
3. ✅ 支持舊資料和新資料
4. ✅ 乘客數量正確記錄和顯示
5. ✅ Edge Function 使用實際值

---

**需要幫助?** 查看 `整數類型錯誤修復指南.md` 獲取詳細說明

