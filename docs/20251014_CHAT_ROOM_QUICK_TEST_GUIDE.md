# 聊天室自動創建功能 - 快速測試指南

**日期**: 2025-10-14  
**功能**: 司機確認接單後自動創建聊天室  
**預計測試時間**: 15 分鐘

---

## 🚀 快速測試（15 分鐘）

### 前置條件檢查

- [ ] Backend 正在運行（Port 3000）
- [ ] Firebase 服務帳戶已配置（參考 `docs/20251014_FIREBASE_SERVICE_ACCOUNT_SETUP.md`）
- [ ] 有狀態為 `matched` 的測試訂單

---

## 步驟 1: 配置 Firebase 服務帳戶（5 分鐘）

### 1.1 下載服務帳戶私鑰

1. 打開 Firebase Console: https://console.firebase.google.com/
2. 選擇專案: **ride-platform-f1676**
3. 點擊齒輪圖標 ⚙️ > **專案設定**
4. 切換到 **服務帳戶** 標籤
5. 點擊 **產生新的私密金鑰**
6. 下載 JSON 文件

### 1.2 更新 .env 文件

打開下載的 JSON 文件，複製以下欄位到 `backend/.env`：

```bash
# Firebase Admin SDK 配置
FIREBASE_PROJECT_ID=ride-platform-f1676
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n[複製 private_key 的值]\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=[複製 client_email 的值]
```

**重要**: 
- ✅ `FIREBASE_PRIVATE_KEY` 必須用雙引號包裹
- ✅ 保留 `\n` 換行符（不要替換成真實換行）

### 1.3 重新啟動 Backend

```bash
cd backend
npm run dev
```

**預期輸出**:
```
✅ Firebase Admin SDK 已初始化
✅ Server is running on port 3000
```

**如果看到警告**:
```
⚠️  Firebase Admin SDK 配置不完整，使用模擬模式
```

**解決方案**: 檢查 `.env` 文件配置，確認格式正確

---

## 步驟 2: 測試 Backend API（5 分鐘）

### 2.1 運行測試腳本

```bash
cd backend
bash test-chat-room-creation.sh
```

**預期輸出**:
```
========================================
測試聊天室創建功能
========================================

步驟 1: 檢查 Backend 是否運行...
✅ Backend 正在運行

步驟 2: 調用司機確認接單 API...
   POST http://localhost:3000/api/booking-flow/bookings/679dd766-91fe-4628-9564-1250b86efb82/accept

📥 API 響應：
{
  "success": true,
  "data": {
    "bookingId": "679dd766-91fe-4628-9564-1250b86efb82",
    "status": "driver_confirmed",
    "chatRoom": {
      "id": "679dd766-91fe-4628-9564-1250b86efb82",
      "bookingId": "679dd766-91fe-4628-9564-1250b86efb82",
      "customerId": "...",
      "driverId": "CMfTxhJFlUVDkosJPyUoJvKjCQk1",
      "customerName": "客戶",
      "driverName": "driver.test",
      "pickupAddress": "...",
      "bookingTime": "2025-10-13"
    },
    "nextStep": "driver_depart"
  },
  "message": "接單成功"
}

✅ API 調用成功
✅ 聊天室資訊已返回
```

### 2.2 檢查 Backend 日誌

在 Backend 終端機中應該看到：

```
[API] 開始創建聊天室到 Firestore...
[Firebase] 開始創建聊天室到 Firestore: 679dd766-91fe-4628-9564-1250b86efb82
[Firebase] ✅ 聊天室創建成功: 679dd766-91fe-4628-9564-1250b86efb82
[Firebase] ✅ 系統訊息已發送: 聊天室已開啟，您可以與司機/客戶開始溝通
[API] ✅ 聊天室創建成功
```

### 2.3 檢查 Firestore Console

1. 打開 Firebase Console: https://console.firebase.google.com/
2. 選擇專案: **ride-platform-f1676**
3. 進入 **Firestore Database**
4. 檢查 `chat_rooms` 集合
5. 查找文檔 ID: `679dd766-91fe-4628-9564-1250b86efb82`

**預期結果**:
- ✅ 文檔存在
- ✅ `customerId` 和 `driverId` 正確
- ✅ `customerName` 和 `driverName` 正確
- ✅ `createdAt` 和 `updatedAt` 有值
- ✅ `messages` 子集合中有系統歡迎訊息

---

## 步驟 3: 測試 Flutter APP（5 分鐘）

### 3.1 重新編譯 Flutter APP

```bash
cd mobile
flutter clean
flutter pub get
flutter run -t lib/apps/driver/main_driver.dart
```

### 3.2 測試司機確認接單

1. 登入司機帳號: `driver.test@relaygo.com` / `Test1234`
2. 進入「我的訂單」>「進行中」
3. 點擊訂單查看詳情
4. 點擊「確認接單」按鈕
5. 在確認對話框點擊「確認接單」

**預期結果**:
- ✅ 載入對話框顯示
- ✅ 載入對話框自動關閉
- ✅ 顯示成功訊息「✅ 接單成功！聊天室已創建...」
- ✅ 「確認接單」按鈕消失

### 3.3 檢查聊天頁面

1. 切換到「聊天」標籤
2. 檢查聊天室列表

**預期結果**:
- ✅ 聊天室自動出現在列表中
- ✅ 顯示客戶名稱
- ✅ 顯示上車地點
- ✅ 顯示最後訊息「聊天室已開啟，您可以與司機/客戶開始溝通」
- ✅ 顯示時間

### 3.4 測試發送訊息

1. 點擊聊天室進入詳情頁面
2. 輸入訊息「測試訊息」
3. 點擊發送按鈕

**預期結果**:
- ✅ 訊息成功發送
- ✅ 訊息即時顯示在聊天列表中
- ✅ 訊息顯示在右側（我發送的）

### 3.5 測試客戶端接收訊息

1. 切換到客戶端 APP（或使用另一台設備）
2. 登入客戶帳號
3. 進入「聊天」標籤
4. 檢查聊天室列表

**預期結果**:
- ✅ 聊天室自動出現在列表中
- ✅ 顯示司機名稱
- ✅ 顯示最後訊息「測試訊息」
- ✅ 未讀訊息計數顯示「1」

---

## ✅ 驗證檢查清單

### Backend 檢查

- [ ] Firebase Admin SDK 初始化成功
- [ ] API 調用成功（200 狀態碼）
- [ ] 聊天室資訊已返回
- [ ] Backend 日誌顯示聊天室創建成功
- [ ] Backend 日誌顯示系統訊息已發送

### Firestore 檢查

- [ ] `chat_rooms` 集合中有新文檔
- [ ] 文檔 ID 等於 `bookingId`
- [ ] `customerId` 和 `driverId` 正確
- [ ] `customerName` 和 `driverName` 正確
- [ ] `messages` 子集合中有系統歡迎訊息

### Flutter APP 檢查

- [ ] 司機端聊天室列表顯示新聊天室
- [ ] 客戶端聊天室列表顯示新聊天室
- [ ] 雙方可以發送和接收訊息
- [ ] 訊息即時同步
- [ ] 未讀訊息計數正確

---

## ❌ 如果測試失敗

### 問題 1: Firebase Admin SDK 初始化失敗

**錯誤訊息**:
```
⚠️  Firebase Admin SDK 配置不完整，使用模擬模式
```

**解決方案**:
1. 檢查 `backend/.env` 文件
2. 確認 `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, `FIREBASE_CLIENT_EMAIL` 已設置
3. 確認 `FIREBASE_PRIVATE_KEY` 格式正確（雙引號、`\n` 換行符）
4. 重新啟動 Backend

### 問題 2: API 調用失敗

**錯誤訊息**:
```
❌ API 調用失敗
```

**解決方案**:
1. 檢查 Backend 是否運行
2. 檢查訂單 ID 是否正確
3. 檢查司機 UID 是否正確
4. 檢查 Backend 日誌查看詳細錯誤

### 問題 3: 聊天室未創建

**症狀**: API 成功但 Firestore 中沒有聊天室

**解決方案**:
1. 檢查 Backend 日誌是否有 Firebase 錯誤
2. 檢查 Firebase 服務帳戶權限
3. 檢查 Firestore 規則是否正確
4. 手動測試 Firebase Admin SDK

### 問題 4: Flutter APP 聊天室列表為空

**症狀**: Firestore 有聊天室但 APP 不顯示

**解決方案**:
1. 檢查 Flutter APP 是否登入
2. 檢查 `customerId` 或 `driverId` 是否匹配當前用戶
3. 下拉刷新聊天室列表
4. 重新啟動 APP

### 問題 5: 訊息無法發送

**症狀**: 點擊發送按鈕沒有反應

**解決方案**:
1. 檢查 Firestore Security Rules
2. 檢查網路連接
3. 檢查 Flutter 終端機日誌
4. 檢查 Backend API 是否正常

---

## 📞 需要幫助？

如果測試失敗，請檢查：

1. **詳細文檔**:
   - `docs/20251014_0947_03_司機確認接單自動創建聊天室功能實作.md`
   - `docs/20251014_FIREBASE_SERVICE_ACCOUNT_SETUP.md`

2. **日誌**:
   - Backend 終端機日誌
   - Flutter 終端機日誌
   - Firestore Console

3. **配置**:
   - `backend/.env` 文件
   - Firebase 服務帳戶設置
   - Firestore Security Rules

---

## 📊 測試結果記錄

**測試日期**: ___________  
**測試人員**: ___________

| 測試項目 | 結果 | 備註 |
|---------|------|------|
| Firebase Admin SDK 初始化 | [ ] 通過 [ ] 失敗 | |
| Backend API 調用 | [ ] 通過 [ ] 失敗 | |
| Firestore 聊天室創建 | [ ] 通過 [ ] 失敗 | |
| 系統訊息發送 | [ ] 通過 [ ] 失敗 | |
| 司機端聊天室列表 | [ ] 通過 [ ] 失敗 | |
| 客戶端聊天室列表 | [ ] 通過 [ ] 失敗 | |
| 發送訊息 | [ ] 通過 [ ] 失敗 | |
| 接收訊息 | [ ] 通過 [ ] 失敗 | |
| 未讀訊息計數 | [ ] 通過 [ ] 失敗 | |

**總體評價**: [ ] 通過 [ ] 失敗

**問題描述**（如果失敗）:
```
___________________________________________
___________________________________________
___________________________________________
```

---

**最後更新**: 2025-10-14  
**預計測試時間**: 15 分鐘  
**難度**: ⭐⭐ 中等

