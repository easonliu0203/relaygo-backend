# 聊天訊息儲存修復報告

**日期**: 2025-11-22  
**Commit**: `ebf9aa5`  
**狀態**: ✅ 已修復並推送到 GitHub  
**Railway 部署**: 🔄 自動部署中

---

## 📋 問題描述

### 症狀

司機出發/到達功能執行時：
- ✅ 定位資料成功儲存到 Firestore (`bookings/{bookingId}/location_history/`)
- ✅ Backend 日誌顯示「定位訊息已發送到聊天室」
- ❌ **聊天室沒有收到任何訊息**（沒有系統訊息，沒有定位 URL）

### Backend 日誌

```
[Location] ✅ 定位已儲存到 Firestore: r9KLa52IjOXXVrIlFUGq
[Location] ✅ 定位訊息已發送到聊天室: chat_4aefb8e7-8eab-4655-8920-17547f184ddc
[Location] ✅ 定位分享成功
```

### 用戶體驗

- 司機 APP 顯示「出發成功」
- 乘客 APP 的聊天室**沒有任何訊息**
- 無法看到司機定位的地圖連結

---

## 🔍 根本原因分析

### 問題代碼

**文件**: `backend/src/services/notification/NotificationService.ts`  
**位置**: `sendLocationMessageToChat()` 方法（第 693 行）

```typescript
// ❌ 錯誤：使用 ChatService.sendSystemMessage()
await chatService.sendSystemMessage(chatRoomId, messageContent);
```

### 為什麼會失敗？

#### 1. ChatService 的實作問題

**文件**: `backend/src/services/chat/ChatService.ts`  
**方法**: `sendSystemMessage()` (第 167-191 行)

```typescript
async sendSystemMessage(chatRoomId: string, content: string): Promise<ChatMessage> {
  const message: ChatMessage = {
    id: this.generateMessageId(),
    chatRoomId,
    senderId: 'system',
    senderType: 'system',
    type: MessageType.SYSTEM,
    content,
    status: MessageStatus.DELIVERED,
    createdAt: new Date(),
    updatedAt: new Date()
  };

  // ❌ 只儲存到記憶體中的 Map
  const roomMessages = this.messages.get(chatRoomId) || [];
  roomMessages.push(message);
  this.messages.set(chatRoomId, roomMessages);

  // ❌ 只通過 Socket.IO 推送（客戶端可能沒有連接）
  if (this.io) {
    this.io.to(`chat:${chatRoomId}`).emit('new_message', message);
  }

  return message;
}
```

**問題**：
1. **沒有儲存到 Firestore**：訊息只儲存在記憶體中的 `Map`
2. **重啟後遺失**：伺服器重啟後，所有訊息都會消失
3. **Socket.IO 依賴**：只通過 Socket.IO 推送，如果客戶端沒有連接就收不到

#### 2. 系統架構要求

根據系統架構說明：
> Firebase: 只用於登入認證、推播、**聊天即時**、檔案（聊天相關）、定位

聊天訊息應該儲存在 **Firebase Firestore** 中，而不是記憶體中。

#### 3. 正確的實作

**文件**: `backend/src/config/firebase.ts`  
**函數**: `sendSystemMessage()` (第 162-195 行)

```typescript
export async function sendSystemMessage(
  bookingId: string,
  message: string
): Promise<void> {
  try {
    const firestore = getFirestore();
    
    const systemMessage = {
      senderId: 'system',
      receiverId: 'all',
      senderName: '系統',
      receiverName: '所有人',
      messageText: message,
      translatedText: null,
      createdAt: admin.firestore.Timestamp.now(),
      readAt: null,
    };

    // ✅ 儲存到 Firestore
    await firestore
      .collection('chat_rooms')
      .doc(bookingId)
      .collection('messages')
      .add(systemMessage);

    // ✅ 更新聊天室的最後訊息
    await firestore.collection('chat_rooms').doc(bookingId).update({
      lastMessage: message,
      lastMessageTime: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log('[Firebase] ✅ 系統訊息已發送:', bookingId);
  } catch (error) {
    console.error('[Firebase] ❌ 發送系統訊息失敗:', error);
    throw error;
  }
}
```

**優點**：
1. ✅ 儲存到 Firestore（持久化）
2. ✅ 更新聊天室的最後訊息
3. ✅ 客戶端通過 Firestore 即時監聽自動收到訊息

---

## ✅ 修復方案

### 修改 1: 更新導入語句

**文件**: `backend/src/services/notification/NotificationService.ts`  
**位置**: 第 1-3 行

**修改前**:
```typescript
import { Server as SocketIOServer } from 'socket.io';
import { getFirebaseApp, getFirestore } from '../../config/firebase';
import admin from 'firebase-admin';
import { chatService } from '../chat/ChatService';  // ❌ 不需要
```

**修改後**:
```typescript
import { Server as SocketIOServer } from 'socket.io';
import { getFirebaseApp, getFirestore, sendSystemMessage } from '../../config/firebase';  // ✅ 添加 sendSystemMessage
import admin from 'firebase-admin';
```

### 修改 2: 使用正確的函數

**文件**: `backend/src/services/notification/NotificationService.ts`  
**位置**: `sendLocationMessageToChat()` 方法（第 660-698 行）

**修改前**:
```typescript
private async sendLocationMessageToChat(
  bookingId: string,
  status: 'driver_departed' | 'driver_arrived',
  mapLinks: { googleMaps: string; appleMaps: string }
): Promise<void> {
  try {
    const chatRoomId = `chat_${bookingId}`;  // ❌ 不需要加前綴
    // ...
    await chatService.sendSystemMessage(chatRoomId, messageContent);  // ❌ 只儲存到記憶體
    console.log('[Location] ✅ 定位訊息已發送到聊天室:', chatRoomId);
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
    // ...
    await sendSystemMessage(bookingId, messageContent);  // ✅ 儲存到 Firestore
    console.log('[Location] ✅ 定位訊息已發送到聊天室:', bookingId);
  } catch (error) {
    console.error('[Location] ❌ 發送定位訊息到聊天室失敗:', error);
    throw error;
  }
}
```

---

## 📊 Firestore 資料結構

### 聊天訊息集合

**路徑**: `chat_rooms/{bookingId}/messages/{messageId}`

**系統訊息格式**:
```json
{
  "senderId": "system",
  "receiverId": "all",
  "senderName": "系統",
  "receiverName": "所有人",
  "messageText": "🚗 司機已出發前往接送地點\n📍 查看司機位置：\n• Google Maps: https://maps.google.com/?q=37.4219983,-122.084\n• Apple Maps: http://maps.apple.com/?q=37.4219983,-122.084\n時間：2025-11-22 14:30:00",
  "translatedText": null,
  "createdAt": Timestamp,
  "readAt": null
}
```

### 聊天室更新

**路徑**: `chat_rooms/{bookingId}`

**更新欄位**:
```json
{
  "lastMessage": "🚗 司機已出發前往接送地點...",
  "lastMessageTime": Timestamp,
  "updatedAt": Timestamp
}
```

---

## 🚀 部署狀態

### Git Commit

```
Commit: ebf9aa5
Message: Fix chat message storage for driver location sharing
Branch: main
Status: ✅ 已推送到 GitHub
```

### Railway 部署

- 🔄 **自動部署中**
- 📍 **域名**: `api.relaygo.pro`
- ⏱️ **預計時間**: 2-5 分鐘

---

## ✅ 預期結果

修復後，司機出發/到達功能應該完整運作：

### 1. Backend 日誌（成功）

```
[API] 司機出發: bookingId=xxx, driverUid=yyy, location=37.4219983,-122.084
[API] 📍 開始分享司機定位...
[Location] ✅ 定位已儲存到 Firestore: r9KLa52IjOXXVrIlFUGq
[Firebase] ✅ 系統訊息已發送: xxx  ← 新增的日誌
[Location] ✅ 定位訊息已發送到聊天室: xxx
[Location] ✅ 定位分享成功
```

### 2. Firestore 儲存（成功）

**定位歷史**: `bookings/{bookingId}/location_history/{locationId}`
**聊天訊息**: `chat_rooms/{bookingId}/messages/{messageId}`  ← 新增

### 3. 聊天室顯示（成功）

乘客 APP 聊天室會顯示：
```
🚗 司機已出發前往接送地點
📍 查看司機位置：
• Google Maps: https://maps.google.com/?q=37.4219983,-122.084
• Apple Maps: http://maps.apple.com/?q=37.4219983,-122.084
時間：2025-11-22 14:30:00
```

---

**文檔版本**: 1.0  
**最後更新**: 2025-11-22  
**修復狀態**: ✅ 已完成  
**作者**: Augment Agent

