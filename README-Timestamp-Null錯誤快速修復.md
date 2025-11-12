# 🚨 Timestamp Null 值錯誤 - 快速修復

**錯誤**: `Invalid argument(s): Timestamp cannot be null`  
**狀態**: ✅ 已修復 (Flutter 代碼)

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

### 1. 修改 fromFirestore() 方法 ✅

**文件**: `mobile/lib/core/models/booking_order.dart`

**修改內容**:
```dart
// 解析 createdAt (必填欄位)
final createdAt = _parseTimestamp(data['createdAt']);

// 解析 bookingTime,如果為 null 則使用 createdAt 作為後備值
final bookingTime = data['bookingTime'] != null 
    ? _parseTimestamp(data['bookingTime'])
    : createdAt;  // ✅ 使用 createdAt 作為後備值
```

**效果**:
- ✅ 如果 bookingTime 有值,使用 bookingTime
- ✅ 如果 bookingTime 是 null,使用 createdAt
- ✅ 不會拋出錯誤,頁面正常載入

### 2. 問題根源

**Supabase Schema**:
- 使用 `start_date` 和 `start_time` 兩個欄位
- 沒有單一的 `booking_time` 欄位

**Edge Function**:
- 組合 `start_date` 和 `start_time` 成 `bookingTime`
- 如果這些欄位是 null,`bookingTime` 也會是 null

---

## 📋 可選步驟 (推薦)

### 檢查有多少訂單缺少 bookingTime

**Firestore 檢查**:

```bash
# 1. 安裝依賴
cd firebase
npm install firebase-admin

# 2. 設置 Firebase 憑證
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"

# 3. 運行檢查腳本
node check-missing-timestamps.js
```

**Supabase 檢查**:

在 Supabase SQL Editor 中執行 `supabase/check-missing-timestamps.sql`

---

## ✅ 驗證修復

### 測試清單

- [ ] 「進行中」頁面正常載入
- [ ] 「歷史訂單」頁面正常載入
- [ ] 訂單時間正確顯示
- [ ] 創建新訂單正常
- [ ] 不出現 null 錯誤

### 檢查訂單時間

**有 bookingTime**: 顯示預約時間
```dart
訂單時間: 2025-01-15 14:00
```

**沒有 bookingTime**: 顯示建立時間
```dart
訂單時間: 2025-01-01 10:00 (建立時間)
```

---

## 🔧 Edge Function 修復建議 (可選)

### 當前邏輯 (有問題)

```typescript
let bookingTimeStr: string
if (bookingData.startDate && bookingData.startTime) {
  bookingTimeStr = `${bookingData.startDate}T${bookingData.startTime}`
} else {
  bookingTimeStr = bookingData.createdAt  // ← 如果也是 null?
}
```

### 建議修復

```typescript
// 確保總是有值
const bookingTimeStr = bookingData.startDate && bookingData.startTime
  ? `${bookingData.startDate}T${bookingData.startTime}`
  : (bookingData.createdAt || new Date().toISOString())  // ✅ 雙重後備
```

**部署**:
```bash
cd supabase/functions
supabase functions deploy sync-to-firestore
```

---

## 🔍 如果仍有問題

### 問題 1: 仍然出現 null 錯誤

**解決**:
```bash
cd mobile
flutter clean
rm -rf build/
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 問題 2: 訂單時間顯示不正確

**檢查**:
- 運行檢查腳本: `node firebase/check-missing-timestamps.js`
- 查看 Supabase 資料: `supabase/check-missing-timestamps.sql`
- 確認 start_date 和 start_time 是否正確

### 問題 3: 大量訂單缺少 bookingTime

**原因**: Edge Function 的組合邏輯有問題

**解決**:
1. 修復 Edge Function (使用建議的修復方案)
2. 重新部署 Edge Function
3. 檢查 Supabase 中的 start_date 和 start_time 資料

---

## 📚 詳細文檔

查看完整說明: `Timestamp-Null值錯誤修復指南.md`

---

## 🎉 預期效果

1. ✅ 訂單列表正常顯示
2. ✅ 不出現 null 錯誤
3. ✅ 支持有/無 bookingTime 的訂單
4. ✅ 使用 createdAt 作為合理的後備值
5. ✅ 提供良好的用戶體驗

---

## 💡 為什麼使用 createdAt 作為後備值?

**合理性**:
- ✅ 如果沒有明確的預約時間,使用訂單建立時間是合理的
- ✅ createdAt 有預設值 (NOW()),幾乎總是有值
- ✅ 顯示建立時間比顯示錯誤或空白更好

**業務邏輯**:
- 預約時間 (bookingTime) 應該是用戶選擇的時間
- 如果缺失,使用建立時間作為替代
- 用戶仍然可以看到訂單的時間資訊

---

**需要幫助?** 查看 `Timestamp-Null值錯誤修復指南.md` 獲取詳細說明

