# 司機即時定位分享功能 - 實作文檔

**實作日期**: 2025-11-22  
**狀態**: ✅ 已完成  
**部署環境**: Railway (`api.relaygo.pro`)

---

## 📋 功能概述

實作了司機在特定狀態變更時自動分享即時定位到聊天室的功能，並生成地圖連結供客戶和公司端查看。

### 核心功能
- ✅ 司機出發時自動分享定位（`driver_departed`）
- ✅ 司機到達時自動分享定位（`driver_arrived`）
- ✅ 生成 Google Maps 和 Apple Maps 連結
- ✅ 儲存定位歷史到 Firestore
- ✅ 發送系統訊息到聊天室（包含地圖連結）
- ✅ 完善的錯誤處理（不中斷主流程）

---

## 🏗️ 系統架構

### 資料流程
```
1. 司機點擊「出發」或「到達」
   ↓
2. Backend 接收狀態變更請求
   ↓
3. NotificationService.handleBookingStatusChange()
   ↓
4. sendDriverDepartedNotifications() 或 sendDriverArrivedNotifications()
   ↓
5. shareDriverLocation() 被調用
   ↓
6. 生成地圖連結 (Google Maps + Apple Maps)
   ↓
7. 儲存定位到 Firestore (location_history)
   ↓
8. 發送系統訊息到聊天室
   ↓
9. 客戶和公司端收到定位訊息
```

### 技術棧
- **Backend**: Node.js + TypeScript + Express
- **資料庫**: Firestore (儲存定位歷史)
- **聊天服務**: ChatService (發送系統訊息)
- **部署平台**: Railway

---

## 📁 修改的檔案

### 1. `backend/src/services/notification/NotificationService.ts`

**修改內容**:

#### A. 修改 `sendDriverDepartedNotifications()` 方法
```typescript
// 司機出發通知
private async sendDriverDepartedNotifications(booking: any): Promise<void> {
  // ... 原有的通知邏輯 ...

  // 新增：分享司機定位到聊天室
  if (booking.driver_location) {
    await this.shareDriverLocation(
      booking.id,
      booking.driver_id,
      'driver_departed',
      booking.driver_location.latitude,
      booking.driver_location.longitude
    );
  }
}
```

#### B. 修改 `sendDriverArrivedNotifications()` 方法
```typescript
// 司機到達通知
private async sendDriverArrivedNotifications(booking: any): Promise<void> {
  // ... 原有的通知邏輯 ...

  // 新增：分享司機定位到聊天室
  if (booking.driver_location) {
    await this.shareDriverLocation(
      booking.id,
      booking.driver_id,
      'driver_arrived',
      booking.driver_location.latitude,
      booking.driver_location.longitude
    );
  }
}
```

#### C. 新增 `shareDriverLocation()` 方法
主要功能方法，協調整個定位分享流程：
```typescript
async shareDriverLocation(
  bookingId: string,
  driverId: string,
  status: 'driver_departed' | 'driver_arrived',
  latitude: number,
  longitude: number
): Promise<void>
```

#### D. 新增 `generateMapLinks()` 方法
生成 Google Maps 和 Apple Maps 連結：
```typescript
private generateMapLinks(latitude: number, longitude: number): {
  googleMaps: string;
  appleMaps: string;
}
```

#### E. 新增 `saveLocationToFirestore()` 方法
儲存定位歷史到 Firestore：
```typescript
private async saveLocationToFirestore(
  bookingId: string,
  driverId: string,
  status: 'driver_departed' | 'driver_arrived',
  latitude: number,
  longitude: number,
  mapLinks: { googleMaps: string; appleMaps: string }
): Promise<void>
```

#### F. 新增 `sendLocationMessageToChat()` 方法
發送定位訊息到聊天室：
```typescript
private async sendLocationMessageToChat(
  bookingId: string,
  status: 'driver_departed' | 'driver_arrived',
  mapLinks: { googleMaps: string; appleMaps: string }
): Promise<void>
```

---

## 🔧 Firestore 資料結構

### 定位歷史儲存位置
```
/bookings/{bookingId}/location_history/{locationId}
{
  id: string,                    // 定位記錄 ID
  bookingId: string,             // 訂單 ID
  driverId: string,              // 司機 ID
  status: 'driver_departed' | 'driver_arrived',  // 觸發狀態
  latitude: number,              // 緯度
  longitude: number,             // 經度
  googleMapsUrl: string,         // Google Maps 連結
  appleMapsUrl: string,          // Apple Maps 連結
  timestamp: Timestamp,          // 時間戳記
  createdAt: Timestamp           // 建立時間
}
```

### 資料範例
```json
{
  "id": "abc123xyz",
  "bookingId": "booking_001",
  "driverId": "driver_001",
  "status": "driver_departed",
  "latitude": 25.0330,
  "longitude": 121.5654,
  "googleMapsUrl": "https://maps.google.com/?q=25.0330,121.5654",
  "appleMapsUrl": "http://maps.apple.com/?q=25.0330,121.5654",
  "timestamp": "2025-11-22T14:30:00Z",
  "createdAt": "2025-11-22T14:30:00Z"
}
```

---

## 💬 聊天室訊息格式

### 司機出發訊息
```
🚗 司機已出發前往接送地點
📍 查看司機位置：
• Google Maps: https://maps.google.com/?q=25.0330,121.5654
• Apple Maps: http://maps.apple.com/?q=25.0330,121.5654
時間：2025-11-22 14:30:00
```

### 司機到達訊息
```
📍 司機已到達接送地點
📍 查看司機位置：
• Google Maps: https://maps.google.com/?q=25.0330,121.5654
• Apple Maps: http://maps.apple.com/?q=25.0330,121.5654
時間：2025-11-22 14:35:00
```

---

## 🚀 部署步驟

### 1. 提交程式碼
```bash
git add backend/src/services/notification/NotificationService.ts
git add backend/DRIVER_LOCATION_SHARING_IMPLEMENTATION.md
git commit -m "Implement driver location sharing feature"
git push origin main
```

### 2. Railway 自動部署
- Railway 會自動檢測到新的 commit
- 自動執行建置和部署
- 部署到 `api.relaygo.pro`

### 3. 驗證環境變數
確保 Railway 中已設定以下環境變數：
- ✅ `FIREBASE_PROJECT_ID`
- ✅ `FIREBASE_PRIVATE_KEY`
- ✅ `FIREBASE_CLIENT_EMAIL`

---

## 📊 資料依賴

### Backend 需要的資料
當狀態變更時，`booking` 物件需要包含：
```typescript
{
  id: string,                    // 訂單 ID
  driver_id: string,             // 司機 ID
  customer_id: string,           // 客戶 ID
  booking_number: string,        // 訂單編號
  driver_location: {             // 司機當前定位
    latitude: number,            // 緯度
    longitude: number            // 經度
  }
}
```

### 注意事項
- `driver_location` 欄位由司機端 APP 提供
- 如果 `driver_location` 不存在，定位分享功能會被跳過（不會報錯）
- 定位資料應該在狀態變更請求中一併傳送

---

## 🧪 測試方法

### 前置條件
1. 確保 Backend 已部署到 Railway
2. 確保司機端 APP 可以提供當前定位
3. 確保聊天室已開啟

### 測試步驟

#### 測試 1：司機出發時分享定位
1. 司機端點擊「出發前往載客」
2. 狀態從 `driver_confirmed` 變更為 `driver_departed`
3. **預期結果**：
   - ✅ Firestore 中新增一筆定位記錄（status: driver_departed）
   - ✅ 聊天室收到系統訊息（包含地圖連結）
   - ✅ 客戶端可以點擊連結查看司機位置

#### 測試 2：司機到達時分享定位
1. 司機端點擊「抵達上車地點」
2. 狀態從 `driver_departed` 變更為 `driver_arrived`
3. **預期結果**：
   - ✅ Firestore 中新增一筆定位記錄（status: driver_arrived）
   - ✅ 聊天室收到系統訊息（包含地圖連結）
   - ✅ 客戶端可以點擊連結查看司機位置

#### 測試 3：地圖連結功能
1. 在聊天室中點擊 Google Maps 連結
2. **預期結果**：
   - ✅ 開啟 Google Maps APP 或網頁
   - ✅ 顯示司機當前位置

3. 在聊天室中點擊 Apple Maps 連結
4. **預期結果**：
   - ✅ 開啟 Apple Maps APP（iOS）或網頁
   - ✅ 顯示司機當前位置

---

## 🔍 除錯方法

### 1. 檢查 Railway 日誌

**成功的日誌範例**：
```
[Location] 分享司機定位: { bookingId: 'xxx', driverId: 'yyy', status: 'driver_departed', latitude: 25.0330, longitude: 121.5654 }
[Location] ✅ 定位已儲存到 Firestore: abc123xyz
[Location] ✅ 定位訊息已發送到聊天室: chat_xxx
[Location] ✅ 定位分享成功
```

**失敗的日誌範例**：
```
[Location] ❌ 定位分享失敗: Error: ...
```

### 2. 檢查 Firestore 資料

1. 前往 Firebase Console: https://console.firebase.google.com
2. 選擇專案：`ride-platform-f1676`
3. 進入 Firestore Database
4. 查看 `bookings/{bookingId}/location_history` collection
5. 確認有兩筆記錄：
   - 一筆 `status: driver_departed`
   - 一筆 `status: driver_arrived`

### 3. 檢查聊天室訊息

1. 在客戶端 APP 開啟聊天室
2. 確認有系統訊息顯示定位資訊
3. 確認地圖連結可以點擊

---

## ⚠️ 已知限制

1. **定位資料來源**
   - 目前依賴司機端 APP 提供 `driver_location` 欄位
   - 如果 APP 沒有提供，定位分享功能會被跳過

2. **即時定位更新**
   - 目前只在「出發」和「到達」兩個時間點分享定位
   - 每分鐘更新的即時定位功能尚未實作（未來改進）

3. **定位精確度**
   - 定位精確度取決於司機端裝置的 GPS 精確度
   - 可能受到訊號、建築物等因素影響

---

## 🔮 未來改進

### 短期（1-2 週）
1. **即時定位更新**
   - 實作每分鐘更新一次的即時定位
   - 儲存到 `bookings/{bookingId}/realtime_location`

2. **公司端顯示**
   - 在公司端訂單詳情頁面顯示定位歷史
   - 顯示司機即時位置（如果可用）

### 中期（1-2 個月）
3. **地圖視覺化**
   - 在聊天室中嵌入地圖預覽
   - 顯示司機移動軌跡

4. **定位通知優化**
   - 當司機接近目的地時發送提醒
   - 預估到達時間（ETA）

---

## ✅ 驗證清單

- [x] 定位分享功能已實作
- [x] 地圖連結生成功能已實作
- [x] Firestore 儲存功能已實作
- [x] 聊天室訊息發送功能已實作
- [x] 錯誤處理已完善
- [x] 程式碼已編譯通過
- [x] 文檔已完成

---

## 🎯 API 整合說明

### Backend API 需要的資料格式

當司機端 APP 發送狀態變更請求時，需要包含司機當前定位：

**請求範例**：
```json
{
  "bookingId": "booking_001",
  "status": "driver_departed",
  "driver_location": {
    "latitude": 25.0330,
    "longitude": 121.5654
  }
}
```

### 狀態變更 API 端點
```
PATCH /api/bookings/{bookingId}/status
```

**Request Body**:
```json
{
  "status": "driver_departed",  // 或 "driver_arrived"
  "driver_location": {
    "latitude": 25.0330,
    "longitude": 121.5654
  }
}
```

**Response**:
```json
{
  "success": true,
  "message": "狀態已更新",
  "data": {
    "bookingId": "booking_001",
    "status": "driver_departed",
    "locationShared": true
  }
}
```

---

## 📞 聯絡資訊

如有問題，請聯絡開發團隊。

