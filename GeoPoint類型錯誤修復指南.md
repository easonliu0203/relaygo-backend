# 🔧 GeoPoint 類型錯誤修復指南

**日期**: 2025-10-09  
**問題**: `type '_Map<String, dynamic>' is not a subtype of type 'GeoPoint'`  
**狀態**: ✅ 已修復

---

## 📋 問題描述

### 錯誤訊息
```
載入失敗
type '_Map<String, dynamic>' is not a subtype of type 'GeoPoint'
```

### 發生位置
- 客戶端「我的訂單 > 進行中」標籤頁
- 客戶端「我的訂單 > 歷史訂單」標籤頁

### 症狀
- 頁面無法正常載入訂單列表
- 出現地理位置資料類型轉換錯誤

---

## 🔍 根本原因分析

### 問題根源

1. **Firestore 資料格式不一致**
   - **舊資料**: 地理位置存儲為 `Map` 格式 (例如: `{ latitude: 25.033, longitude: 121.565 }`)
   - **新資料**: 地理位置存儲為 `Firestore GeoPoint` 格式 (正確)

2. **Flutter 代碼不兼容**
   - `LocationPoint.fromGeoPoint()` 方法期望 `GeoPoint` 類型
   - 代碼: `LocationPoint.fromGeoPoint(data['pickupLocation'])`
   - 遇到 Map 格式時拋出錯誤

3. **歷史背景**
   - 舊版 Edge Function 將地理位置存儲為 Map
   - 新版 Edge Function 已修復 (使用 `{ _latitude: ..., _longitude: ... }` 格式)
   - 但舊資料仍然是 Map 格式,未遷移

### 影響範圍

**受影響的欄位**:
- `pickupLocation` (LocationPoint) - 上車地點
- `dropoffLocation` (LocationPoint) - 下車地點

**受影響的集合**:
- `orders_rt` - 客戶端即時訂單
- `bookings` - 完整訂單記錄

---

## ✅ 解決方案

### 方案概述

採用 **混合方案**,確保向後兼容:

1. ✅ **修改 Flutter 代碼** - 支持 GeoPoint 和 Map 兩種格式
2. ✅ **Edge Function 已正確** - 使用 `_latitude` 和 `_longitude` 標記
3. ✅ **提供遷移腳本** - 將舊資料轉換為正確格式
4. ✅ **提供驗證腳本** - 檢查資料格式是否正確

### 優點

- ✅ **立即修復**: Flutter 代碼修改後,應用立即可用
- ✅ **向後兼容**: 支持舊資料,不會因為資料格式導致錯誤
- ✅ **Edge Function 正確**: 新資料使用正確格式
- ✅ **漸進遷移**: 可以選擇性地遷移舊資料

---

## 🔧 修復步驟

### 步驟 1: 修改 Flutter 代碼 ✅ 已完成

**文件**: `mobile/lib/core/models/booking_order.dart`

**修改內容**:

1. 添加輔助函數 `_parseGeoPoint()`
2. 更新 `fromFirestore()` 方法使用這個函數

**關鍵代碼**:

```dart
/// 解析 GeoPoint - 支持 GeoPoint 和 Map 兩種格式
static LocationPoint _parseGeoPoint(dynamic value) {
  if (value == null) {
    throw ArgumentError('GeoPoint cannot be null');
  }
  
  // 處理 Firestore GeoPoint 格式 (正確格式)
  if (value is GeoPoint) {
    return LocationPoint.fromGeoPoint(value);
  }
  
  // 處理 Map 格式 (舊資料兼容)
  if (value is Map) {
    final map = value as Map<String, dynamic>;
    
    // 檢查是否包含 latitude 和 longitude 欄位
    if (map.containsKey('latitude') && map.containsKey('longitude')) {
      final lat = map['latitude'];
      final lng = map['longitude'];
      
      final latitude = lat is double ? lat : (lat is int ? lat.toDouble() : double.parse(lat.toString()));
      final longitude = lng is double ? lng : (lng is int ? lng.toDouble() : double.parse(lng.toString()));
      
      return LocationPoint(
        latitude: latitude,
        longitude: longitude,
      );
    }
    
    // 檢查是否包含 _latitude 和 _longitude 欄位
    if (map.containsKey('_latitude') && map.containsKey('_longitude')) {
      final lat = map['_latitude'];
      final lng = map['_longitude'];
      
      final latitude = lat is double ? lat : (lat is int ? lat.toDouble() : double.parse(lat.toString()));
      final longitude = lng is double ? lng : (lng is int ? lng.toDouble() : double.parse(lng.toString()));
      
      return LocationPoint(
        latitude: latitude,
        longitude: longitude,
      );
    }
    
    throw ArgumentError('Map does not contain valid latitude/longitude fields');
  }
  
  throw ArgumentError('Invalid GeoPoint format: ${value.runtimeType}');
}
```

**使用方式**:

```dart
factory BookingOrder.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  
  return BookingOrder(
    ...
    pickupLocation: _parseGeoPoint(data['pickupLocation']),
    dropoffLocation: _parseGeoPoint(data['dropoffLocation']),
    ...
  );
}
```

---

### 步驟 2: 驗證 Edge Function ✅ 已正確

**文件**: `supabase/functions/sync-to-firestore/index.ts`

**確認內容**:

Edge Function 已經正確使用 `_latitude` 和 `_longitude` 標記:

```typescript
// 地點資訊
pickupAddress: bookingData.pickupAddress || '',
pickupLocation: {
  _latitude: pickupLocation.latitude,  // ✅ 使用 _latitude 標記
  _longitude: pickupLocation.longitude, // ✅ 使用 _longitude 標記
},
dropoffAddress: bookingData.destination || '',
dropoffLocation: {
  _latitude: dropoffLocation.latitude,  // ✅ 使用 _latitude 標記
  _longitude: dropoffLocation.longitude, // ✅ 使用 _longitude 標記
},
```

**convertToFirestoreFields 函數**:

```typescript
// 檢查是否是 GeoPoint 格式（包含 _latitude 和 _longitude）
if ('_latitude' in value && '_longitude' in value) {
  fields[key] = {
    geoPointValue: {  // ✅ 轉換為 geoPointValue
      latitude: value._latitude,
      longitude: value._longitude,
    }
  }
}
```

**效果**:
- ✅ 新資料使用正確的 GeoPoint 格式
- ✅ Firestore 存儲為 geoPointValue

---

### 步驟 3: 驗證 Firestore 資料格式 (可選)

**目的**: 檢查 Firestore 中有多少文檔需要遷移

**腳本**: `firebase/verify-geopoint-fields.js`

**使用方法**:

```bash
# 1. 安裝依賴
cd firebase
npm install firebase-admin

# 2. 設置 Firebase 憑證
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"

# 3. 運行驗證腳本
node verify-geopoint-fields.js
```

**輸出示例**:

```
╔════════════════════════════════════════╗
║  Firestore GeoPoint 欄位驗證腳本       ║
╚════════════════════════════════════════╝

📋 檢查計劃:
  集合: orders_rt, bookings
  欄位: pickupLocation, dropoffLocation

========================================
檢查集合: orders_rt
========================================

📊 總文檔數: 15

📊 欄位類型統計:

pickupLocation:
  ✅ GeoPoint: 10
  ⚠️  Map (latitude/longitude): 5
  ⚠️  Map (_latitude/_longitude): 0
  ❌ Map (other): 0
  ⏭️  null: 0
  ❓ other: 0

⚠️  發現 5 個問題

========================================

總計:
  總文檔數: 15
  總問題數: 5

⚠️  發現問題! 需要運行遷移腳本修復

執行以下命令進行修復:
  node firebase/migrate-geopoint-fields.js
```

---

### 步驟 4: 遷移 Firestore 資料 (可選,推薦)

**目的**: 將舊資料轉換為正確的 GeoPoint 格式

**腳本**: `firebase/migrate-geopoint-fields.js`

**使用方法**:

```bash
# 1. 確認已安裝依賴和設置憑證 (同步驟 3)

# 2. 運行遷移腳本
node migrate-geopoint-fields.js
```

**輸出示例**:

```
╔════════════════════════════════════════╗
║  Firestore GeoPoint 欄位遷移腳本       ║
╚════════════════════════════════════════╝

📋 遷移計劃:
  集合: orders_rt, bookings
  欄位: pickupLocation, dropoffLocation
  操作: Map → Firestore GeoPoint

⚠️  警告: 此操作將修改 Firestore 資料
請確認您已備份資料並了解操作風險

========================================
開始遷移集合: orders_rt
========================================

📊 總文檔數: 15

處理批次 1/2 (文檔 1-10)
----------------------------------------
  🔄 pickupLocation: Map → GeoPoint (25.033, 121.565)
  ✅ 已更新: orders_rt/abc123
  ...

========================================
集合 orders_rt 遷移完成
========================================
📊 統計:
  總文檔數: 15
  ✅ 已更新: 5
  ⏭️  已跳過: 10
  ❌ 失敗: 0
========================================

🎉 遷移成功! 所有 GeoPoint 欄位都已轉換為正確格式
```

---

### 步驟 5: 測試應用

**重新建置應用**:

```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

**測試步驟**:

1. **測試「進行中」頁面**
   ```
   1. 打開應用
   2. 進入「我的訂單」
   3. 切換到「進行中」標籤
   ```
   
   **預期結果**:
   - ✅ 頁面正常載入
   - ✅ 顯示進行中的訂單列表
   - ✅ 地圖正確顯示上下車地點
   - ✅ 不出現類型錯誤

2. **測試「歷史訂單」頁面**
   ```
   1. 切換到「歷史訂單」標籤
   ```
   
   **預期結果**:
   - ✅ 頁面正常載入
   - ✅ 顯示所有訂單
   - ✅ 地理位置正確顯示
   - ✅ 不出現類型錯誤

3. **測試新訂單創建**
   ```
   1. 創建新訂單
   2. 選擇上下車地點
   3. 完成支付
   4. 查看訂單詳情
   ```
   
   **預期結果**:
   - ✅ 訂單正常創建
   - ✅ 地理位置正確記錄
   - ✅ 地圖正確顯示
   - ✅ 不出現類型錯誤

---

## 📊 技術說明

### 為什麼會有兩種格式?

**歷史演進**:

1. **舊版 Edge Function** (已棄用)
   ```typescript
   const firestoreData = {
     pickupLocation: { latitude: 25.033, longitude: 121.565 },  // ❌ Map 格式
     dropoffLocation: { latitude: 25.033, longitude: 121.565 }, // ❌ Map 格式
   }
   ```

2. **新版 Edge Function** (當前版本)
   ```typescript
   const firestoreData = {
     pickupLocation: {
       _latitude: pickupLocation.latitude,   // ✅ 使用 _latitude 標記
       _longitude: pickupLocation.longitude, // ✅ 使用 _longitude 標記
     },
     dropoffLocation: {
       _latitude: dropoffLocation.latitude,   // ✅ 使用 _latitude 標記
       _longitude: dropoffLocation.longitude, // ✅ 使用 _longitude 標記
     },
   }
   
   // convertToFirestoreFields 會轉換為:
   {
     pickupLocation: { 
       geoPointValue: { latitude: 25.033, longitude: 121.565 }  // ✅ Firestore GeoPoint
     },
     dropoffLocation: { 
       geoPointValue: { latitude: 25.033, longitude: 121.565 }  // ✅ Firestore GeoPoint
     },
   }
   ```

### 為什麼 Flutter 代碼需要支持兩種格式?

1. **舊資料未遷移**: Firestore 中仍有 Map 格式的地理位置
2. **向後兼容**: 確保應用在遷移期間仍然可用
3. **漸進遷移**: 可以選擇性地遷移資料,不影響業務

---

## 🔍 故障排除

### 問題 1: 仍然出現類型錯誤

**症狀**: 修改代碼後仍然報錯

**可能原因**:
- Flutter 代碼未正確更新
- 應用緩存了舊代碼

**解決方法**:
```bash
cd mobile
flutter clean
rm -rf build/
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 問題 2: 地圖顯示不正確

**症狀**: 地圖上的標記位置錯誤

**可能原因**:
- 地理位置資料格式錯誤
- latitude 和 longitude 值互換

**解決方法**:
- 運行驗證腳本檢查資料格式
- 檢查 Firestore 中的實際資料

### 問題 3: 遷移腳本執行失敗

**症狀**: `Error: Could not load the default credentials`

**原因**: Firebase 憑證未設置

**解決方法**:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
```

---

## ✅ 成功標準

### Flutter 代碼
- ✅ `_parseGeoPoint()` 函數正確處理 GeoPoint 和 Map
- ✅ `fromFirestore()` 方法使用輔助函數

### Edge Function
- ✅ 使用 `_latitude` 和 `_longitude` 標記
- ✅ `convertToFirestoreFields` 正確轉換為 geoPointValue

### Firestore 資料
- ✅ 所有地理位置欄位都是 GeoPoint 格式
- ✅ 驗證腳本不報告任何問題

### 應用功能
- ✅ 「進行中」頁面正常載入
- ✅ 「歷史訂單」頁面正常載入
- ✅ 新訂單創建正常
- ✅ 地圖正確顯示
- ✅ 不出現類型錯誤

---

## 📚 相關文檔

| 文檔 | 說明 |
|------|------|
| `docs/20251006_0840_07_GeoPoint格式修復.md` | Edge Function GeoPoint 修復歷史 |
| `firebase/migrate-geopoint-fields.js` | Firestore 資料遷移腳本 |
| `firebase/verify-geopoint-fields.js` | Firestore 資料驗證腳本 |
| `mobile/lib/core/models/booking_order.dart` | BookingOrder 模型定義 |
| `supabase/functions/sync-to-firestore/index.ts` | Edge Function 同步邏輯 |

---

## 🎉 完成後的效果

1. **應用立即可用**
   - 不再出現類型錯誤
   - 訂單列表正常顯示
   - 支持舊資料和新資料

2. **資料格式統一** (遷移後)
   - 所有地理位置都是 GeoPoint 格式
   - 提升查詢性能
   - 減少代碼複雜度

3. **功能正確**
   - 地圖正確顯示上下車地點
   - 地理位置正確記錄和顯示
   - Edge Function 使用正確格式

---

## 📞 需要幫助?

1. **查看錯誤日誌**: 檢查 Flutter 控制台的詳細錯誤訊息
2. **運行驗證腳本**: 確認 Firestore 資料格式
3. **檢查 Edge Function**: 確認使用最新版本
4. **查看相關文檔**: 了解歷史修復記錄

