# 司機定位分享功能 - 問題診斷與修復報告

**日期**: 2025-11-22  
**狀態**: ✅ Backend 已修復，等待司機端 APP 整合

---

## 🔍 問題診斷

### 問題描述
當司機點擊「出發前往載客」和「抵達搭車地點」時：
- ✅ 聊天室有收到系統訊息
- ❌ 訊息中**沒有包含地圖連結**
- ❌ 訊息格式不符合預期（應該包含 Google Maps 和 Apple Maps 連結）

### 根本原因

#### 1. API 端點沒有調用定位分享功能
**問題檔案**: `backend/src/routes/bookingFlow-minimal.ts`

**問題代碼** (第 350-359 行):
```typescript
// 6. 發送系統訊息到聊天室
try {
  await sendSystemMessage(
    bookingId,
    '司機已出發，正在前往上車地點 🚗'
  );
  console.log('[API] ✅ 系統訊息已發送');
} catch (messageError) {
  console.error('[API] ⚠️  發送系統訊息失敗（不影響主流程）:', messageError);
}
```

**問題分析**:
- API 端點直接調用 `sendSystemMessage()` 發送簡單訊息
- **沒有調用** `NotificationService.shareDriverLocation()` 方法
- **沒有接收** 司機端 APP 傳送的定位資訊（`latitude`, `longitude`）

#### 2. 司機端 APP 沒有發送定位資訊
**問題**: 司機端 APP 的 API 請求中沒有包含 `latitude` 和 `longitude` 欄位

**原有的請求 Body**:
```json
{
  "driverUid": "CMfTxhJFlUVDkosJPyUoJvKjCQk1"
}
```

**缺少的欄位**:
```json
{
  "driverUid": "CMfTxhJFlUVDkosJPyUoJvKjCQk1",
  "latitude": 25.0330,    // ❌ 缺少
  "longitude": 121.5654   // ❌ 缺少
}
```

#### 3. NotificationService 的定位分享功能沒有被觸發
雖然 `NotificationService` 中已經實作了 `shareDriverLocation()` 方法，但因為：
1. API 端點沒有調用這個方法
2. 司機端 APP 沒有提供定位資訊

所以定位分享功能從未被執行。

---

## 🛠️ 修復方案

### Backend 修復

#### 1. 修改 `bookingFlow-minimal.ts`

**修改內容**:

##### A. 新增 import
```typescript
import { notificationService } from '../services/notification/NotificationService';
```

##### B. 修改司機出發 API (第 270-377 行)
```typescript
router.post('/bookings/:bookingId/depart', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { driverUid, latitude, longitude } = req.body;  // ✅ 新增 latitude, longitude

    console.log(`[API] 司機出發: bookingId=${bookingId}, driverUid=${driverUid}, location=${latitude},${longitude}`);

    // ... 驗證邏輯 ...

    // 6. 分享司機定位到聊天室
    try {
      if (latitude && longitude) {
        // ✅ 如果有定位資訊，發送包含地圖連結的訊息
        console.log('[API] 📍 開始分享司機定位...');
        await notificationService.shareDriverLocation(
          bookingId,
          driver.id,
          'driver_departed',
          parseFloat(latitude),
          parseFloat(longitude)
        );
        console.log('[API] ✅ 定位分享成功');
      } else {
        // ⚠️  如果沒有定位資訊，發送簡單的系統訊息（向後兼容）
        console.log('[API] ⚠️  未提供定位資訊，發送簡單系統訊息');
        await sendSystemMessage(
          bookingId,
          '司機已出發，正在前往上車地點 🚗'
        );
        console.log('[API] ✅ 系統訊息已發送');
      }
    } catch (messageError) {
      console.error('[API] ⚠️  發送訊息失敗（不影響主流程）:', messageError);
    }
  }
});
```

##### C. 修改司機到達 API (第 397-508 行)
```typescript
router.post('/bookings/:bookingId/arrive', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { driverUid, latitude, longitude } = req.body;  // ✅ 新增 latitude, longitude

    console.log(`[API] 司機到達: bookingId=${bookingId}, driverUid=${driverUid}, location=${latitude},${longitude}`);

    // ... 驗證邏輯 ...

    // 6. 分享司機定位到聊天室
    try {
      if (latitude && longitude) {
        // ✅ 如果有定位資訊，發送包含地圖連結的訊息
        console.log('[API] 📍 開始分享司機定位...');
        await notificationService.shareDriverLocation(
          bookingId,
          driver.id,
          'driver_arrived',
          parseFloat(latitude),
          parseFloat(longitude)
        );
        console.log('[API] ✅ 定位分享成功');
      } else {
        // ⚠️  如果沒有定位資訊，發送簡單的系統訊息（向後兼容）
        console.log('[API] ⚠️  未提供定位資訊，發送簡單系統訊息');
        await sendSystemMessage(
          bookingId,
          '司機已到達上車地點，請準備上車 📍'
        );
        console.log('[API] ✅ 系統訊息已發送');
      }
    } catch (messageError) {
      console.error('[API] ⚠️  發送訊息失敗（不影響主流程）:', messageError);
    }
  }
});
```

#### 2. 向後兼容性
- ✅ 如果司機端 APP 沒有提供 `latitude` 和 `longitude`，Backend 會發送簡單的系統訊息
- ✅ 這樣可以確保舊版 APP 仍然可以正常運作
- ✅ 新版 APP 提供定位後，會自動發送包含地圖連結的訊息

---

### 司機端 APP 修復

請參考 `DRIVER_APP_LOCATION_INTEGRATION_GUIDE.md` 文檔，主要修改：

1. **請求定位權限**
2. **獲取當前定位**（使用 `geolocator` 套件）
3. **修改 API 請求**（在 Request Body 中加入 `latitude` 和 `longitude`）

---

## 📊 修復後的資料流程

### 完整流程

```
1. 司機點擊「出發」按鈕
   ↓
2. 司機端 APP 獲取當前定位
   ↓
3. 司機端 APP 發送 API 請求（包含 latitude, longitude）
   ↓
4. Backend 接收請求
   ↓
5. Backend 更新訂單狀態為 driver_departed
   ↓
6. Backend 調用 notificationService.shareDriverLocation()
   ↓
7. 生成 Google Maps 和 Apple Maps 連結
   ↓
8. 儲存定位到 Firestore (location_history)
   ↓
9. 發送包含地圖連結的系統訊息到聊天室
   ↓
10. 客戶端收到訊息（包含地圖連結）
```

### 預期的聊天室訊息

```
🚗 司機已出發前往接送地點
📍 查看司機位置：
• Google Maps: https://maps.google.com/?q=25.0330,121.5654
• Apple Maps: http://maps.apple.com/?q=25.0330,121.5654
時間：2025-11-22 14:30:00
```

---

## 🧪 測試驗證

### Backend 測試（已完成）
- [x] 程式碼已修改
- [x] 編譯成功
- [x] 已推送到 GitHub
- [ ] Railway 部署成功
- [ ] 功能測試完成

### 司機端 APP 測試（待完成）
- [ ] 定位權限請求正常
- [ ] 可以獲取當前定位
- [ ] API 請求包含定位資訊
- [ ] 聊天室收到包含地圖連結的訊息
- [ ] 地圖連結可以正常開啟

---

## 📋 預期的 Backend 日誌

### 成功的日誌（有定位）
```
[API] 司機出發: bookingId=xxx, driverUid=yyy, location=25.0330,121.5654
[API] ✅ 訂單狀態已更新為 driver_departed
[API] 📍 開始分享司機定位...
[Location] 分享司機定位: { bookingId: 'xxx', driverId: 'yyy', status: 'driver_departed', latitude: 25.0330, longitude: 121.5654 }
[Location] ✅ 定位已儲存到 Firestore: abc123
[Location] ✅ 定位訊息已發送到聊天室: chat_xxx
[Location] ✅ 定位分享成功
[API] ✅ 定位分享成功
```

### 向後兼容的日誌（無定位）
```
[API] 司機出發: bookingId=xxx, driverUid=yyy, location=undefined,undefined
[API] ✅ 訂單狀態已更新為 driver_departed
[API] ⚠️  未提供定位資訊，發送簡單系統訊息
[Firebase] ✅ 系統訊息已發送: 司機已出發，正在前往上車地點 🚗
[API] ✅ 系統訊息已發送
```

---

## ✅ 驗證清單

### Backend
- [x] 修改 `bookingFlow-minimal.ts`
- [x] 新增 `latitude` 和 `longitude` 參數接收
- [x] 調用 `notificationService.shareDriverLocation()`
- [x] 實作向後兼容邏輯
- [x] 編譯成功
- [x] 推送到 GitHub
- [ ] Railway 部署成功

### 司機端 APP
- [ ] 請求定位權限
- [ ] 獲取當前定位
- [ ] 修改 API 請求（加入 latitude, longitude）
- [ ] 測試定位分享功能
- [ ] 發布新版本 APP

### 整合測試
- [ ] 司機出發時聊天室收到包含地圖連結的訊息
- [ ] 司機到達時聊天室收到包含地圖連結的訊息
- [ ] Firestore 正確儲存定位歷史
- [ ] 地圖連結可以正常開啟
- [ ] 舊版 APP 仍然可以正常運作（向後兼容）

---

**文檔版本**: 1.0  
**最後更新**: 2025-11-22

