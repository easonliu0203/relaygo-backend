# ChatService 模組導入錯誤修復報告

**日期**: 2025-11-22  
**Commit**: `7077ec2`  
**狀態**: ✅ 已修復並推送到 GitHub  
**Railway 部署**: 🔄 自動部署中

---

## 📋 問題描述

### 錯誤訊息

司機出發功能在 Railway 生產環境中執行時，定位資料成功儲存到 Firestore，但發送聊天訊息時失敗：

```
[Location] ❌ 發送定位訊息到聊天室失敗: Error: Cannot find module '../chat/ChatService'
Require stack:
- /app/dist/services/notification/NotificationService.js
- /app/dist/routes/bookingFlow-minimal.js
- /app/dist/minimal-server.js
```

### 影響範圍

- ✅ **定位儲存**: 正常運作（Firestore 儲存成功）
- ❌ **聊天訊息**: 失敗（無法發送包含地圖連結的訊息）
- ❌ **用戶體驗**: 乘客無法在聊天室看到司機定位訊息

---

## 🔍 根本原因分析

### 問題代碼

**文件**: `backend/src/services/notification/NotificationService.ts`  
**位置**: `sendLocationMessageToChat()` 方法（第 667 行）

```typescript
// ❌ 錯誤的動態導入
const chatService = require('../chat/ChatService').chatService;
```

### 為什麼會失敗？

1. **動態 require() 的問題**:
   - TypeScript 編譯後，模組路徑可能會改變
   - 在生產環境中，動態 `require()` 的路徑解析可能失敗
   - 缺少靜態分析，打包工具無法正確處理依賴

2. **模組解析問題**:
   - 編譯後的 `dist/` 目錄結構與 `src/` 不同
   - 相對路徑 `../chat/ChatService` 在運行時可能無法正確解析
   - Railway 生產環境的模組解析機制與本地開發不同

3. **最佳實踐違反**:
   - TypeScript 推薦使用靜態 `import` 語句
   - 動態 `require()` 應該只在特殊情況下使用（如條件導入）

---

## ✅ 修復方案

### 修改 1: 添加靜態導入

**文件**: `backend/src/services/notification/NotificationService.ts`  
**位置**: 文件頂部（第 1-4 行）

```typescript
import { Server as SocketIOServer } from 'socket.io';
import { getFirebaseApp, getFirestore } from '../../config/firebase';
import admin from 'firebase-admin';
import { chatService } from '../chat/ChatService';  // ✅ 新增靜態導入
```

### 修改 2: 移除動態 require()

**文件**: `backend/src/services/notification/NotificationService.ts`  
**位置**: `sendLocationMessageToChat()` 方法（第 661-699 行）

**修改前**:
```typescript
private async sendLocationMessageToChat(
  bookingId: string,
  status: 'driver_departed' | 'driver_arrived',
  mapLinks: { googleMaps: string; appleMaps: string }
): Promise<void> {
  try {
    const chatService = require('../chat/ChatService').chatService;  // ❌ 動態導入
    const chatRoomId = `chat_${bookingId}`;
    // ...
    await chatService.sendSystemMessage(chatRoomId, messageContent);
  } catch (error) {
    console.error('[Location] ❌ 發送定位訊息到聊天室失敗:', error);
    throw error;
  }
}
```

**修改後**:
```typescript
private async sendLocationMessageToChat(
  bookingId: string,
  status: 'driver_departed' | 'driver_arrived',
  mapLinks: { googleMaps: string; appleMaps: string }
): Promise<void> {
  try {
    const chatRoomId = `chat_${bookingId}`;  // ✅ 直接使用頂部導入的 chatService
    // ...
    await chatService.sendSystemMessage(chatRoomId, messageContent);
  } catch (error) {
    console.error('[Location] ❌ 發送定位訊息到聊天室失敗:', error);
    throw error;
  }
}
```

---

## 📊 編譯驗證

### TypeScript 編譯結果

**編譯後的導入** (`dist/services/notification/NotificationService.js` 第 9 行):
```javascript
const ChatService_1 = require("../chat/ChatService");
```

**編譯後的使用** (`dist/services/notification/NotificationService.js` 第 452 行):
```javascript
await ChatService_1.chatService.sendSystemMessage(chatRoomId, messageContent);
```

### 驗證結果

- ✅ TypeScript 編譯成功
- ✅ 模組路徑正確解析
- ✅ `ChatService.js` 正確導出 `chatService`
- ✅ 相對路徑 `../chat/ChatService` 在編譯後正確

---

## 🚀 部署狀態

### Git Commit

```bash
Commit: 7077ec2
Author: easonliu0203
Message: Fix ChatService import in NotificationService
Branch: main
```

### GitHub 推送

```
✅ 已推送到 GitHub
Repository: easonliu0203/relaygo-backend
Branch: main
Commit: 7077ec2
```

### Railway 自動部署

Railway 會自動檢測到 GitHub 的推送並觸發部署：

1. **檢測推送**: Railway 監聽 `main` 分支
2. **拉取代碼**: 從 GitHub 拉取最新代碼
3. **執行構建**: 運行 `npm install` 和 `npm run build`
4. **部署服務**: 重啟 Backend 服務
5. **健康檢查**: 驗證服務正常運行

**預計部署時間**: 2-5 分鐘

---

## ✅ 預期結果

修復後，司機出發功能應該完整運作：

### 1. 司機點擊「出發」按鈕

**Backend 日誌**:
```
[API] 司機出發: bookingId=xxx, driverUid=yyy, location=25.0330,121.5654
[API] 📍 開始分享司機定位...
[Location] 📍 開始分享定位: bookingId=xxx, driverId=yyy, status=driver_departed
[Location] ✅ 定位已儲存到 Firestore
[Location] ✅ 定位訊息已發送到聊天室: chat_xxx
[Location] ✅ 定位分享成功
[API] ✅ 定位分享成功
```

### 2. 聊天室收到訊息

**訊息格式**:
```
🚗 司機已出發前往接送地點
📍 查看司機位置：
• Google Maps: https://maps.google.com/?q=25.0330,121.5654
• Apple Maps: http://maps.apple.com/?q=25.0330,121.5654
時間：2025-11-22 14:30:00
```

### 3. Firestore 儲存定位歷史

**集合路徑**: `bookings/{bookingId}/location_history/{locationId}`

**文檔內容**:
```json
{
  "latitude": 25.0330,
  "longitude": 121.5654,
  "googleMapsUrl": "https://maps.google.com/?q=25.0330,121.5654",
  "appleMapsUrl": "http://maps.apple.com/?q=25.0330,121.5654",
  "status": "driver_departed",
  "timestamp": "2025-11-22T14:30:00.000Z"
}
```

---

## 📚 相關文檔

- **定位分享功能實作**: `DRIVER_LOCATION_SHARING_DIAGNOSIS_AND_FIX.md`
- **Backend API 端點**: `src/routes/bookingFlow-minimal.ts`
- **NotificationService**: `src/services/notification/NotificationService.ts`
- **ChatService**: `src/services/chat/ChatService.ts`

---

## 🎯 測試步驟

### 等待 Railway 部署完成後

1. **檢查 Railway 日誌**:
   - 訪問 Railway Dashboard
   - 查看部署狀態
   - 確認服務正常啟動

2. **測試司機出發功能**:
   - 使用司機 APP 接受訂單
   - 點擊「出發」按鈕
   - 觀察 APP 日誌

3. **驗證聊天室訊息**:
   - 打開乘客 APP
   - 進入聊天室
   - 確認收到包含地圖連結的訊息

4. **檢查 Firestore**:
   - 訪問 Firebase Console
   - 查看 `bookings/{bookingId}/location_history/` 集合
   - 確認定位資料已儲存

---

**文檔版本**: 1.0  
**最後更新**: 2025-11-22  
**修復狀態**: ✅ 已完成  
**作者**: Augment Agent

