# 司機端 APP 定位整合指南

**目標**: 修改司機端 APP，在點擊「出發」和「到達」按鈕時發送當前定位到 Backend

---

## 📋 需要修改的內容

### 1. 請求定位權限

在司機端 APP 啟動時，請求定位權限。

#### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>我們需要您的位置資訊來分享給客戶</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>我們需要您的位置資訊來追蹤行程</string>
```

---

### 2. 獲取當前定位

使用 Flutter 的 `geolocator` 套件獲取當前定位。

#### pubspec.yaml
```yaml
dependencies:
  geolocator: ^10.1.0
```

#### 獲取定位的程式碼
```dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// 檢查定位權限
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[Location] 定位服務未啟用');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('[Location] 定位權限被拒絕');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('[Location] 定位權限被永久拒絕');
      return false;
    }

    return true;
  }

  /// 獲取當前定位
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('[Location] 當前位置: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('[Location] 獲取定位失敗: $e');
      return null;
    }
  }
}
```

---

### 3. 修改 API 請求

在點擊「出發」和「到達」按鈕時，先獲取定位，然後在 API 請求中包含定位資訊。

#### 司機出發 API 請求

**原有的請求**：
```dart
Future<void> driverDepart(String bookingId) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/booking-flow/bookings/$bookingId/depart'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'driverUid': currentUser.uid,
    }),
  );
  
  // 處理響應...
}
```

**修改後的請求**：
```dart
Future<void> driverDepart(String bookingId) async {
  // 1. 獲取當前定位
  final locationService = LocationService();
  final position = await locationService.getCurrentLocation();

  // 2. 構建請求 body
  final Map<String, dynamic> requestBody = {
    'driverUid': currentUser.uid,
  };

  // 3. 如果有定位資訊，加入請求中
  if (position != null) {
    requestBody['latitude'] = position.latitude;
    requestBody['longitude'] = position.longitude;
    print('[API] 包含定位資訊: ${position.latitude}, ${position.longitude}');
  } else {
    print('[API] ⚠️  無法獲取定位，將發送不含定位的請求');
  }

  // 4. 發送 API 請求
  final response = await http.post(
    Uri.parse('$baseUrl/api/booking-flow/bookings/$bookingId/depart'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );
  
  // 處理響應...
}
```

#### 司機到達 API 請求

**修改後的請求**：
```dart
Future<void> driverArrive(String bookingId) async {
  // 1. 獲取當前定位
  final locationService = LocationService();
  final position = await locationService.getCurrentLocation();

  // 2. 構建請求 body
  final Map<String, dynamic> requestBody = {
    'driverUid': currentUser.uid,
  };

  // 3. 如果有定位資訊，加入請求中
  if (position != null) {
    requestBody['latitude'] = position.latitude;
    requestBody['longitude'] = position.longitude;
    print('[API] 包含定位資訊: ${position.latitude}, ${position.longitude}');
  } else {
    print('[API] ⚠️  無法獲取定位，將發送不含定位的請求');
  }

  // 4. 發送 API 請求
  final response = await http.post(
    Uri.parse('$baseUrl/api/booking-flow/bookings/$bookingId/arrive'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );
  
  // 處理響應...
}
```

---

## 🧪 測試步驟

### 1. 測試定位權限
1. 安裝修改後的 APP
2. 啟動 APP
3. **預期結果**：彈出定位權限請求對話框
4. 點擊「允許」

### 2. 測試司機出發
1. 進入訂單詳情頁面（狀態為 `driver_confirmed`）
2. 點擊「出發前往載客」按鈕
3. **預期結果**：
   - APP 日誌顯示：`[Location] 當前位置: 25.0330, 121.5654`
   - APP 日誌顯示：`[API] 包含定位資訊: 25.0330, 121.5654`
   - Backend 日誌顯示：`[API] 司機出發: bookingId=xxx, driverUid=yyy, location=25.0330,121.5654`
   - Backend 日誌顯示：`[API] 📍 開始分享司機定位...`
   - Backend 日誌顯示：`[Location] ✅ 定位分享成功`
   - 聊天室收到包含地圖連結的系統訊息

### 3. 測試司機到達
1. 點擊「抵達上車地點」按鈕
2. **預期結果**：
   - APP 日誌顯示：`[Location] 當前位置: 25.0340, 121.5660`
   - APP 日誌顯示：`[API] 包含定位資訊: 25.0340, 121.5660`
   - Backend 日誌顯示：`[API] 司機到達: bookingId=xxx, driverUid=yyy, location=25.0340,121.5660`
   - Backend 日誌顯示：`[API] 📍 開始分享司機定位...`
   - Backend 日誌顯示：`[Location] ✅ 定位分享成功`
   - 聊天室收到包含地圖連結的系統訊息

---

## 📊 Backend API 變更

### 司機出發 API

**端點**: `POST /api/booking-flow/bookings/:bookingId/depart`

**Request Body** (新增 latitude 和 longitude 欄位):
```json
{
  "driverUid": "Firebase UID",
  "latitude": 25.0330,
  "longitude": 121.5654
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "bookingId": "xxx",
    "status": "driver_departed",
    "nextStep": "driver_arrive"
  },
  "message": "已出發"
}
```

### 司機到達 API

**端點**: `POST /api/booking-flow/bookings/:bookingId/arrive`

**Request Body** (新增 latitude 和 longitude 欄位):
```json
{
  "driverUid": "Firebase UID",
  "latitude": 25.0340,
  "longitude": 121.5660
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "bookingId": "xxx",
    "status": "driver_arrived",
    "nextStep": "start_trip"
  },
  "message": "已到達"
}
```

---

## ⚠️ 重要注意事項

### 1. 向後兼容性
- Backend 已修改為**向後兼容**
- 如果 APP 沒有提供 `latitude` 和 `longitude`，Backend 會發送簡單的系統訊息（不含地圖連結）
- 這樣可以確保舊版 APP 仍然可以正常運作

### 2. 錯誤處理
- 如果無法獲取定位（權限被拒絕、GPS 未啟用等），APP 仍然可以發送請求
- Backend 會檢查是否有定位資訊，如果沒有就發送簡單訊息
- 不會因為定位問題而中斷正常流程

### 3. 定位精確度
- 使用 `LocationAccuracy.high` 獲取高精確度定位
- 可能需要幾秒鐘才能獲取到定位
- 建議在按鈕點擊時顯示載入指示器

---

## 🚀 部署步驟

### 1. Backend 部署
- ✅ Backend 程式碼已修改完成
- ✅ 已推送到 GitHub
- ✅ Railway 會自動部署

### 2. 司機端 APP 部署
1. 修改 APP 程式碼（參考上述範例）
2. 測試定位功能
3. 測試 API 整合
4. 發布新版本 APP

---

**文檔版本**: 1.0  
**最後更新**: 2025-11-22

