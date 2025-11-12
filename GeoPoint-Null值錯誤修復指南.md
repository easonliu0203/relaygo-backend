# 🔧 GeoPoint Null 值錯誤修復指南

**日期**: 2025-10-09  
**問題**: `Invalid argument(s): GeoPoint cannot be null`  
**狀態**: ✅ 已修復

---

## 📋 問題描述

### 錯誤訊息
```
載入失敗
Invalid argument(s): GeoPoint cannot be null
```

### 發生位置
- 客戶端「我的訂單 > 進行中」標籤頁
- 客戶端「我的訂單 > 歷史訂單」標籤頁

### 症狀
- 頁面無法正常載入訂單列表
- 出現 GeoPoint 欄位為 null 的錯誤

---

## 🔍 根本原因分析

### 問題根源

1. **Supabase Schema 定義**
   ```sql
   pickup_location TEXT NOT NULL,        -- 地址是必填的
   pickup_latitude DECIMAL(10, 8),       -- 座標是可選的 (沒有 NOT NULL)
   pickup_longitude DECIMAL(11, 8),      -- 座標是可選的 (沒有 NOT NULL)
   ```

2. **BookingOrder 模型定義** (修復前)
   ```dart
   required LocationPoint pickupLocation,  // ❌ 必填,但實際資料可能為 null
   required LocationPoint dropoffLocation, // ❌ 必填,但實際資料可能為 null
   ```

3. **資料不匹配**
   - 某些訂單有地址但沒有座標
   - 可能原因: 地址解析失敗、測試資料、早期訂單

### 影響範圍

**受影響的欄位**:
- `pickupLocation` (LocationPoint?) - 上車座標
- `dropoffLocation` (LocationPoint?) - 下車座標

**受影響的集合**:
- `orders_rt` - 客戶端即時訂單
- `bookings` - 完整訂單記錄

---

## ✅ 解決方案

### 方案概述

採用 **修改模型為可選欄位** 方案:

1. ✅ **修改 BookingOrder 模型** - pickupLocation 和 dropoffLocation 改為可選
2. ✅ **添加 _parseOptionalGeoPoint()** - 支持 null 值
3. ✅ **更新 fromFirestore() 和 toFirestore()** - 處理可選的 GeoPoint
4. ✅ **重新生成 freezed 代碼** - 更新生成的代碼
5. ✅ **提供檢查腳本** - 檢查有多少訂單缺少座標

### 優點

- ✅ **符合實際資料結構**: 反映 Supabase schema 的定義
- ✅ **避免使用假資料**: 不使用 (0, 0) 等預設值
- ✅ **長期易維護**: 模型與資料庫一致
- ✅ **靈活處理**: UI 可以根據是否有座標顯示不同內容

---

## 🔧 修復步驟

### 步驟 1: 修改 BookingOrder 模型 ✅ 已完成

**文件**: `mobile/lib/core/models/booking_order.dart`

**修改內容**:

```dart
const factory BookingOrder({
  required String id,
  required String customerId,
  String? driverId,
  required String pickupAddress,         // 地址是必填的
  LocationPoint? pickupLocation,         // ✅ 座標改為可選
  required String dropoffAddress,        // 地址是必填的
  LocationPoint? dropoffLocation,        // ✅ 座標改為可選
  required DateTime bookingTime,
  required int passengerCount,
  int? luggageCount,
  String? notes,
  required double estimatedFare,
  required double depositAmount,
  @Default(false) bool depositPaid,
  @Default(BookingStatus.pending) BookingStatus status,
  required DateTime createdAt,
  DateTime? matchedAt,
  DateTime? completedAt,
}) = _BookingOrder;
```

---

### 步驟 2: 添加 _parseOptionalGeoPoint() 函數 ✅ 已完成

**文件**: `mobile/lib/core/models/booking_order.dart`

**新增函數**:

```dart
/// 解析可選的 GeoPoint - 支持 null 值
/// 
/// 這個方法用於處理可選的地理位置欄位:
/// - 如果 value 為 null,返回 null
/// - 否則使用 [_parseGeoPoint] 解析
/// 
/// [value] 要解析的值,可以為 null
/// 
/// 背景說明:
/// 根據 Supabase schema,pickup_latitude 和 pickup_longitude 是可選欄位。
/// 某些訂單可能有地址但沒有座標 (例如地址解析失敗的情況)。
static LocationPoint? _parseOptionalGeoPoint(dynamic value) {
  if (value == null) {
    return null;
  }
  return _parseGeoPoint(value);
}
```

---

### 步驟 3: 更新 fromFirestore() 方法 ✅ 已完成

**修改內容**:

```dart
factory BookingOrder.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  
  return BookingOrder(
    ...
    pickupLocation: _parseOptionalGeoPoint(data['pickupLocation']),   // ✅ 使用可選解析
    dropoffLocation: _parseOptionalGeoPoint(data['dropoffLocation']), // ✅ 使用可選解析
    ...
  );
}
```

---

### 步驟 4: 更新 toFirestore() 方法 ✅ 已完成

**修改內容**:

```dart
Map<String, dynamic> toFirestore() {
  return {
    ...
    'pickupLocation': pickupLocation?.toGeoPoint(),   // ✅ 使用 null-aware 操作符
    'dropoffLocation': dropoffLocation?.toGeoPoint(), // ✅ 使用 null-aware 操作符
    ...
  };
}
```

---

### 步驟 5: 重新生成 freezed 代碼 (重要!)

**目的**: 更新 freezed 生成的代碼以支持可選的 LocationPoint

**命令**:

```bash
cd mobile
flutter pub run build_runner build --delete-conflicting-outputs
```

**預期輸出**:

```
[INFO] Generating build script...
[INFO] Generating build script completed, took 1.2s
[INFO] Creating build script snapshot...
[INFO] Creating build script snapshot completed, took 3.4s
[INFO] Running build...
[INFO] Running build completed, took 5.6s
[INFO] Caching finalized dependency graph...
[INFO] Caching finalized dependency graph completed, took 0.1s
[SUCCESS] Build completed successfully
```

**驗證**:
- 檢查 `mobile/lib/core/models/booking_order.freezed.dart` 已更新
- 檢查 `mobile/lib/core/models/booking_order.g.dart` 已更新
- IDE 不再報告類型錯誤

---

### 步驟 6: 檢查 Firestore 資料 (可選)

**目的**: 了解有多少訂單缺少地理位置座標

**腳本**: `firebase/check-missing-geopoints.js`

**使用方法**:

```bash
# 1. 安裝依賴
cd firebase
npm install firebase-admin

# 2. 設置 Firebase 憑證
export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"

# 3. 運行檢查腳本
node check-missing-geopoints.js
```

**輸出示例**:

```
╔════════════════════════════════════════╗
║  Firestore 缺失 GeoPoint 檢查腳本      ║
╚════════════════════════════════════════╝

📋 檢查計劃:
  集合: orders_rt, bookings
  欄位: pickupLocation, dropoffLocation

========================================
檢查集合: orders_rt
========================================

📊 總文檔數: 15

📊 GeoPoint 欄位統計:

pickupLocation:
  ✅ 有座標: 12
  ❌ 缺少座標: 3 (20.0%)

dropoffLocation:
  ✅ 有座標: 12
  ❌ 缺少座標: 3 (20.0%)

⚠️  發現 3 個訂單缺少地理位置座標:

1. abc123
   上車地點: 台北車站
   下車地點: 松山機場
   狀態: completed
   缺少欄位: pickupLocation, dropoffLocation
   建立時間: 2025-01-01T10:00:00.000Z

...

總計:
  總文檔數: 15
  缺少座標的訂單: 3
  缺失比例: 20.0%

⚠️  發現問題! 有 3 個訂單缺少地理位置座標

建議:
  1. 檢查這些訂單的來源 (可能是測試資料或早期訂單)
  2. 如果是測試資料,可以考慮刪除
  3. 如果是真實訂單,需要補充座標資料
  4. Flutter 代碼已修改為支持缺少座標的訂單
```

---

### 步驟 7: 檢查 Supabase 資料 (可選)

**目的**: 了解 Supabase 中有多少訂單缺少座標

**腳本**: `supabase/check-missing-geopoints.sql`

**使用方法**:

在 Supabase SQL Editor 中執行此腳本,或使用 psql:

```bash
psql -h <host> -U postgres -d postgres -f supabase/check-missing-geopoints.sql
```

**輸出示例**:

```
統計項目                    | 數量
---------------------------+------
📊 總訂單數                 | 15
✅ 有 pickup 座標           | 12
❌ 缺少 pickup 座標         | 3
✅ 有 dropoff 座標          | 12
❌ 缺少 dropoff 地址        | 3

⚠️  缺少 pickup 座標的訂單 (前 10 個):

id       | 訂單編號 | 上車地點   | 緯度 | 經度 | 狀態      | 建立時間
---------+----------+------------+------+------+-----------+----------
abc123   | BK001    | 台北車站   | NULL | NULL | completed | 2025-01-01
...

💡 建議:
⚠️  少數訂單缺少座標,可能是測試資料或早期訂單。
Flutter 代碼已修改為支持缺少座標的訂單。
```

---

### 步驟 8: 測試應用

**重新建置應用**:

```bash
cd mobile
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
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
   - ✅ 有座標的訂單顯示地圖
   - ✅ 沒有座標的訂單顯示地址文字
   - ✅ 不出現 null 錯誤

2. **測試「歷史訂單」頁面**
   ```
   1. 切換到「歷史訂單」標籤
   ```
   
   **預期結果**:
   - ✅ 頁面正常載入
   - ✅ 顯示所有訂單
   - ✅ 正確處理有/無座標的訂單
   - ✅ 不出現 null 錯誤

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
   - ✅ 不出現錯誤

---

## 📊 技術說明

### 為什麼座標是可選的?

**業務邏輯**:
1. **地址是必填的**: 用戶必須輸入上下車地點
2. **座標是可選的**: 座標由地址解析服務生成,可能失敗

**可能導致座標缺失的原因**:
1. **地址解析失敗**: Google Maps API 無法解析地址
2. **測試資料**: 開發/測試時手動創建的訂單
3. **早期訂單**: 系統早期版本可能沒有記錄座標
4. **網路問題**: 地址解析時網路中斷

### UI 如何處理缺少座標的訂單?

**建議的 UI 處理方式**:

```dart
// 在訂單詳情頁面
Widget buildLocationInfo(BookingOrder order) {
  if (order.pickupLocation != null) {
    // 有座標,顯示地圖
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          order.pickupLocation!.latitude,
          order.pickupLocation!.longitude,
        ),
        zoom: 15,
      ),
      markers: {
        Marker(
          markerId: MarkerId('pickup'),
          position: LatLng(
            order.pickupLocation!.latitude,
            order.pickupLocation!.longitude,
          ),
        ),
      },
    );
  } else {
    // 沒有座標,只顯示地址文字
    return Card(
      child: ListTile(
        leading: Icon(Icons.location_on),
        title: Text(order.pickupAddress),
        subtitle: Text('座標資料不可用'),
      ),
    );
  }
}
```

---

## 🔍 故障排除

### 問題 1: 仍然出現 null 錯誤

**症狀**: 修改代碼後仍然報錯

**可能原因**:
- freezed 代碼未重新生成
- 應用緩存了舊代碼

**解決方法**:
```bash
cd mobile
flutter clean
rm -rf build/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 問題 2: UI 顯示錯誤

**症狀**: 訂單列表顯示異常

**可能原因**:
- UI 代碼沒有處理 null 的 pickupLocation/dropoffLocation

**解決方法**:
- 檢查所有使用 pickupLocation 和 dropoffLocation 的地方
- 添加 null 檢查: `if (order.pickupLocation != null) { ... }`
- 或使用 null-aware 操作符: `order.pickupLocation?.latitude`

### 問題 3: freezed 生成失敗

**症狀**: `build_runner` 報錯

**可能原因**:
- 代碼語法錯誤
- freezed 版本不兼容

**解決方法**:
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

## ✅ 成功標準

### BookingOrder 模型
- ✅ `pickupLocation` 和 `dropoffLocation` 是可選欄位 (LocationPoint?)
- ✅ `_parseOptionalGeoPoint()` 函數正確處理 null 值
- ✅ `fromFirestore()` 和 `toFirestore()` 正確處理可選的 GeoPoint

### freezed 生成的代碼
- ✅ `booking_order.freezed.dart` 已更新
- ✅ `booking_order.g.dart` 已更新
- ✅ IDE 不報告類型錯誤

### 應用功能
- ✅ 「進行中」頁面正常載入
- ✅ 「歷史訂單」頁面正常載入
- ✅ 正確處理有/無座標的訂單
- ✅ 新訂單創建正常
- ✅ 不出現 null 錯誤

---

## 📚 相關文檔

| 文檔 | 說明 |
|------|------|
| `GeoPoint類型錯誤修復指南.md` | GeoPoint 類型轉換錯誤修復 |
| `firebase/check-missing-geopoints.js` | Firestore 缺失座標檢查腳本 |
| `supabase/check-missing-geopoints.sql` | Supabase 缺失座標檢查腳本 |
| `mobile/lib/core/models/booking_order.dart` | BookingOrder 模型定義 |
| `supabase/migrations/20250100_create_base_schema.sql` | Supabase schema 定義 |

---

## 🎉 完成後的效果

1. **應用立即可用**
   - 不再出現 null 錯誤
   - 訂單列表正常顯示
   - 支持有/無座標的訂單

2. **模型與資料庫一致**
   - BookingOrder 模型反映 Supabase schema
   - 座標欄位正確標記為可選
   - 避免使用假資料

3. **靈活的 UI 處理**
   - 有座標時顯示地圖
   - 沒有座標時顯示地址文字
   - 提供良好的用戶體驗

---

## 📞 需要幫助?

1. **查看錯誤日誌**: 檢查 Flutter 控制台的詳細錯誤訊息
2. **運行檢查腳本**: 確認有多少訂單缺少座標
3. **檢查 UI 代碼**: 確保正確處理 null 值
4. **查看相關文檔**: 了解 GeoPoint 類型轉換修復

