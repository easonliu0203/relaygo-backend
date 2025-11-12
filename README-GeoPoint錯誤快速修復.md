# 🚨 GeoPoint 類型錯誤 - 快速修復

**錯誤**: `type '_Map<String, dynamic>' is not a subtype of type 'GeoPoint'`  
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

### 1. Flutter 代碼修改 ✅

**文件**: `mobile/lib/core/models/booking_order.dart`

**修改內容**:
- 添加 `_parseGeoPoint()` 函數 - 支持 GeoPoint 和 Map 兩種格式
- 更新 `fromFirestore()` 方法使用這個函數

**效果**:
- ✅ 支持舊資料 (Map 格式: `{ latitude: ..., longitude: ... }`)
- ✅ 支持新資料 (GeoPoint 格式)
- ✅ 向後兼容,不會因為資料格式導致錯誤

### 2. Edge Function 已正確 ✅

**文件**: `supabase/functions/sync-to-firestore/index.ts`

**確認內容**:
- 使用 `_latitude` 和 `_longitude` 標記
- `convertToFirestoreFields` 正確轉換為 geoPointValue

**效果**:
- ✅ 新訂單使用正確的 GeoPoint 格式
- ✅ Firestore 存儲為 geoPointValue

---

## 📋 可選步驟 (推薦)

### 遷移 Firestore 資料

**目的**: 將舊資料轉換為正確的 GeoPoint 格式

**步驟**:

```bash
# 1. 安裝依賴
cd firebase
npm install firebase-admin

# 2. 設置 Firebase 憑證
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"

# 3. 驗證資料格式 (可選)
node verify-geopoint-fields.js

# 4. 遷移資料
node migrate-geopoint-fields.js
```

**注意**: 即使不遷移,應用也能正常工作 (因為 Flutter 代碼已支持兩種格式)

---

## ✅ 驗證修復

### 測試清單

- [ ] 「進行中」頁面正常載入
- [ ] 「歷史訂單」頁面正常載入
- [ ] 訂單詳情正確顯示地理位置
- [ ] 地圖正確顯示上下車地點
- [ ] 創建新訂單時地理位置正確記錄
- [ ] 不出現類型錯誤

### 測試新訂單

1. 創建新訂單
2. 選擇上下車地點
3. 完成支付
4. 查看訂單詳情

**預期結果**:
- ✅ 地理位置正確記錄
- ✅ 地圖正確顯示
- ✅ Firestore 中存儲為 GeoPoint 格式

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

### 問題 2: 地圖顯示不正確

**檢查**:
- 查看 Firestore 中的資料格式
- 運行驗證腳本: `node firebase/verify-geopoint-fields.js`

### 問題 3: 新訂單的地理位置格式錯誤

**原因**: Edge Function 可能未使用最新版本

**檢查**:
- 查看 `supabase/functions/sync-to-firestore/index.ts`
- 確認使用 `_latitude` 和 `_longitude` 標記

---

## 📚 詳細文檔

查看完整說明: `GeoPoint類型錯誤修復指南.md`

---

## 🎉 預期效果

1. ✅ 訂單列表正常顯示
2. ✅ 不出現類型錯誤
3. ✅ 支持舊資料和新資料
4. ✅ 地圖正確顯示地理位置
5. ✅ 新訂單使用正確格式

---

**需要幫助?** 查看 `GeoPoint類型錯誤修復指南.md` 獲取詳細說明

