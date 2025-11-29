# 聊天室推播通知功能實作文檔

**實作日期**: 2025-11-22
**更新日期**: 2025-11-29
**狀態**: ✅ 已完成（Backend FCM 推播功能已實作）
**部署環境**: Railway (`api.relaygo.pro`)

---

## 📋 功能概述

實作了聊天室雙向推播通知機制，當客戶端或司機端發送訊息時，對方會收到 FCM 推播通知。

### 核心功能
- ✅ 使用 Firebase Cloud Messaging (FCM) 發送推播通知
- ✅ 通知內容包含發送者名稱和訊息預覽（前 50 字元）
- ✅ 自動判斷接收者（客戶或司機）
- ✅ 支援 Android 和 iOS 平台
- ✅ 處理無效 Token 的錯誤情況
- ✅ 不會向發送者自己發送通知

---

## 🏗️ 系統架構

### 資料流程
```
1. 用戶 A 發送訊息
   ↓
2. ChatService.sendMessage() 被調用
   ↓
3. 訊息儲存到記憶體（未來可改為 Firestore）
   ↓
4. ChatService.sendMessageNotification() 被調用
   ↓
5. NotificationService.sendNotification() 被調用
   ↓
6. NotificationService.sendPushNotification() 被調用
   ↓
7. 從 Firestore 獲取接收者的 FCM Token
   ↓
8. 使用 Firebase Admin SDK 發送 FCM 推播
   ↓
9. 用戶 B 收到推播通知
```

### 技術棧
- **Backend**: Node.js + TypeScript + Express
- **推播服務**: Firebase Cloud Messaging (FCM)
- **資料庫**: Firestore (儲存 FCM Tokens)
- **部署平台**: Railway

---

## 📁 修改的檔案

### 1. `backend/src/services/notification/NotificationService.ts`

**修改內容**:
- 新增 Firebase Admin SDK 導入
- 實作 `sendPushNotification()` 方法
- 新增 `getUserFcmToken()` 方法從 Firestore 獲取 FCM Token
- 構建 Android 和 iOS 特定的推播配置

**核心程式碼**:
```typescript
// 推播通知
private async sendPushNotification(notification: Notification): Promise<void> {
  try {
    // 1. 從 Firestore 獲取用戶的 FCM Token
    const fcmToken = await this.getUserFcmToken(notification.recipientId);

    if (!fcmToken) {
      console.log('[FCM] 用戶沒有 FCM Token，跳過推播');
      return;
    }

    // 2. 構建推播訊息
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.message
      },
      data: {
        type: notification.type.toString(),
        notificationId: notification.id,
        ...(notification.data || {})
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_messages',
          priority: 'high',
          sound: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            alert: { title: notification.title, body: notification.message },
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    // 3. 發送推播
    const messaging = admin.messaging(getFirebaseApp());
    const response = await messaging.send(message);
    console.log('[FCM] ✅ 推播通知發送成功:', response);
  } catch (error: any) {
    console.error('[FCM] ❌ 推播通知發送失敗:', error);
    // 處理無效 Token
    if (error.code === 'messaging/invalid-registration-token') {
      console.log('[FCM] Token 無效，考慮清理:', notification.recipientId);
    }
  }
}

// 從 Firestore 獲取用戶的 FCM Token
private async getUserFcmToken(userId: string): Promise<string | null> {
  try {
    const firestore = getFirestore();
    const userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return null;
    }

    const userData = userDoc.data();
    return userData?.fcmToken || null;
  } catch (error) {
    console.error('[FCM] 獲取 FCM Token 失敗:', error);
    return null;
  }
}
```

---

## 🔧 Firestore 資料結構

### FCM Token 儲存位置
```
/users/{userId}
{
  fcmToken: string,        // FCM 裝置 Token
  updatedAt: Timestamp,    // 最後更新時間
  ... (其他用戶資料)
}
```

### 注意事項
- FCM Token 由客戶端（Flutter App）在登入後自動儲存到 Firestore
- Backend 只負責讀取 Token 並發送推播
- 如果 Token 無效，會記錄錯誤但不會中斷流程

---

## 🚀 部署步驟

### 1. 提交程式碼
```bash
git add backend/src/services/notification/NotificationService.ts
git add backend/CHAT_PUSH_NOTIFICATION_IMPLEMENTATION.md
git commit -m "Implement FCM push notification for chat messages"
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

## 🧪 測試方法

### 前置條件
1. 確保客戶端和司機端 App 已安裝並登入
2. 確保兩端都已獲取並儲存 FCM Token 到 Firestore
3. 確保兩端都已授權推播通知權限

### 測試步驟

#### 測試 1：客戶發送訊息給司機
1. 客戶端開啟聊天室
2. 客戶發送訊息："你好，請問幾點到？"
3. **預期結果**：
   - ✅ 司機端收到推播通知
   - ✅ 通知標題：「新訊息」
   - ✅ 通知內容：「你好，請問幾點到？」
   - ✅ 點擊通知可導航到聊天室

#### 測試 2：司機發送訊息給客戶
1. 司機端開啟聊天室
2. 司機發送訊息："我大約 10 分鐘後到達」
3. **預期結果**：
   - ✅ 客戶端收到推播通知
   - ✅ 通知標題：「新訊息」
   - ✅ 通知內容：「我大約 10 分鐘後到達」
   - ✅ 點擊通知可導航到聊天室

#### 測試 3：長訊息截斷
1. 發送超過 50 字元的訊息
2. **預期結果**：
   - ✅ 通知內容只顯示前 50 字元 + "..."

---

## 📊 監控和日誌

### Backend 日誌
在 Railway 部署日誌中可以看到：
```
[FCM] 準備發送推播通知: { recipientId: 'xxx', type: 'new_message', title: '新訊息' }
[FCM] 找到 FCM Token: xxxxx...
[FCM] ✅ 推播通知發送成功: projects/xxx/messages/xxx
```

### 錯誤處理
如果發送失敗，會記錄錯誤：
```
[FCM] ❌ 推播通知發送失敗: Error: ...
[FCM] Token 無效，考慮清理: userId
```

---

## ⚠️ 已知限制

1. **FCM Token 管理**
   - 目前只儲存單一 Token（最新的裝置）
   - 如果用戶有多個裝置，只有最後登入的裝置會收到通知
   - 未來可改為儲存 Token 陣列支援多裝置

2. **訊息儲存**
   - 目前訊息儲存在記憶體中
   - 建議未來改為儲存到 Firestore 以支援持久化

3. **通知內容**
   - 目前只支援文字訊息預覽
   - 圖片/位置訊息會顯示為原始內容

---

## 🔮 未來改進

1. **多裝置支援**
   - 儲存用戶的所有 FCM Tokens
   - 向所有裝置發送推播

2. **訊息持久化**
   - 將訊息儲存到 Firestore
   - 支援訊息歷史查詢

3. **通知自訂化**
   - 根據訊息類型顯示不同的通知樣式
   - 支援圖片預覽

4. **通知設定**
   - 允許用戶自訂通知偏好
   - 支援勿擾模式

---

## ✅ 驗證清單

- ✅ FCM 推播功能已實作
- ✅ 從 Firestore 獲取 FCM Token
- ✅ 支援 Android 和 iOS 平台
- ✅ 訊息內容正確截斷（50 字元）
- ✅ 錯誤處理完善
- ✅ 程式碼已編譯通過
- ✅ 文檔已完成

---

## 📞 聯絡資訊

如有問題，請聯絡開發團隊。

