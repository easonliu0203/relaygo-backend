# 🚨 GeoPoint Null 值錯誤 - 快速修復

**錯誤**: `Invalid argument(s): GeoPoint cannot be null`  
**狀態**: ✅ 已修復 (Flutter 代碼)

---

## ⚡ 立即修復

### 步驟 1: 重新生成 freezed 代碼 (重要!)

```bash
cd mobile
flutter pub run build_runner build --delete-conflicting-outputs
```

### 步驟 2: 重新建置應用

```bash
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 步驟 3: 測試訂單頁面

1. 打開應用
2. 進入「我的訂單」
3. 切換「進行中」和「歷史訂單」標籤

**預期結果**: ✅ 頁面正常載入,不出現錯誤

---

## 🔧 已完成的修復

### 1. 修改 BookingOrder 模型 ✅

**文件**: `mobile/lib/core/models/booking_order.dart`

**修改內容**:
- `pickupLocation`: `required LocationPoint` → `LocationPoint?` (可選)
- `dropoffLocation`: `required LocationPoint` → `LocationPoint?` (可選)

**理由**:
- Supabase schema 中 `pickup_latitude` 和 `pickup_longitude` 是可選欄位
- 某些訂單有地址但沒有座標 (例如地址解析失敗)

### 2. 添加 _parseOptionalGeoPoint() 函數 ✅

**功能**:
- 支持 null 值
- 如果 value 為 null,返回 null
- 否則使用 `_parseGeoPoint()` 解析

### 3. 更新 fromFirestore() 和 toFirestore() ✅

**修改**:
- 使用 `_parseOptionalGeoPoint()` 解析地理位置
- 使用 null-aware 操作符 (`?.`) 處理可選欄位

---

## 📋 可選步驟 (推薦)

### 檢查有多少訂單缺少座標

**Firestore 檢查**:

```bash
# 1. 安裝依賴
cd firebase
npm install firebase-admin

# 2. 設置 Firebase 憑證
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"

# 3. 運行檢查腳本
node check-missing-geopoints.js
```

**Supabase 檢查**:

在 Supabase SQL Editor 中執行 `supabase/check-missing-geopoints.sql`

---

## ✅ 驗證修復

### 測試清單

- [ ] freezed 代碼已重新生成
- [ ] 「進行中」頁面正常載入
- [ ] 「歷史訂單」頁面正常載入
- [ ] 有座標的訂單顯示地圖
- [ ] 沒有座標的訂單顯示地址文字
- [ ] 創建新訂單正常
- [ ] 不出現 null 錯誤

### UI 處理建議

**有座標**: 顯示地圖
```dart
if (order.pickupLocation != null) {
  // 顯示 GoogleMap
}
```

**沒有座標**: 顯示地址文字
```dart
else {
  // 顯示 ListTile 或 Card
  Text(order.pickupAddress)
}
```

---

## 🔍 如果仍有問題

### 問題 1: 仍然出現 null 錯誤

**原因**: freezed 代碼未重新生成

**解決**:
```bash
cd mobile
flutter clean
rm -rf build/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 問題 2: UI 顯示錯誤

**原因**: UI 代碼沒有處理 null 的 pickupLocation

**解決**:
- 添加 null 檢查: `if (order.pickupLocation != null) { ... }`
- 或使用 null-aware 操作符: `order.pickupLocation?.latitude`

### 問題 3: freezed 生成失敗

**解決**:
```bash
# 檢查語法錯誤
flutter analyze

# 更新依賴
flutter pub upgrade

# 清理並重新生成
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📚 詳細文檔

查看完整說明: `GeoPoint-Null值錯誤修復指南.md`

---

## 🎉 預期效果

1. ✅ 訂單列表正常顯示
2. ✅ 不出現 null 錯誤
3. ✅ 支持有/無座標的訂單
4. ✅ 模型與資料庫一致
5. ✅ UI 靈活處理不同情況

---

## 💡 為什麼座標是可選的?

**Supabase Schema**:
```sql
pickup_location TEXT NOT NULL,        -- 地址必填
pickup_latitude DECIMAL(10, 8),       -- 座標可選
pickup_longitude DECIMAL(11, 8),      -- 座標可選
```

**原因**:
- 地址由用戶輸入,必填
- 座標由地址解析服務生成,可能失敗
- 某些訂單可能有地址但沒有座標

---

**需要幫助?** 查看 `GeoPoint-Null值錯誤修復指南.md` 獲取詳細說明

