# Firebase 服務帳戶設置指南

**日期**: 2025-10-14  
**目的**: 配置 Backend 使用 Firebase Admin SDK 自動創建聊天室  
**預計時間**: 10 分鐘

---

## 📋 為什麼需要服務帳戶？

Backend API 需要使用 Firebase Admin SDK 來：
1. ✅ **自動創建聊天室** - 司機確認接單時自動創建 Firestore 聊天室
2. ✅ **發送系統訊息** - 在聊天室中發送歡迎訊息
3. ✅ **高權限操作** - 繞過 Firestore Security Rules，直接寫入資料

**架構設計**:
- **聊天室創建**: Backend API（使用 Service Account）
- **聊天訊息發送**: 客戶端直接寫入 Firestore（使用 Security Rules）

---

## 🚀 設置步驟

### 步驟 1: 下載服務帳戶私鑰

1. 打開 Firebase Console: https://console.firebase.google.com/
2. 選擇專案: **ride-platform-f1676**
3. 點擊左側齒輪圖標 ⚙️ > **專案設定**
4. 切換到 **服務帳戶** 標籤
5. 點擊 **產生新的私密金鑰**
6. 確認對話框，點擊 **產生金鑰**
7. 下載的 JSON 文件會自動儲存（例如：`ride-platform-f1676-firebase-adminsdk-xxxxx.json`）

**重要**: 此文件包含敏感資訊，請妥善保管，不要提交到 Git！

---

### 步驟 2: 提取服務帳戶資訊

打開下載的 JSON 文件，找到以下欄位：

```json
{
  "type": "service_account",
  "project_id": "ride-platform-f1676",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@ride-platform-f1676.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "...",
  "token_uri": "...",
  "auth_provider_x509_cert_url": "...",
  "client_x509_cert_url": "..."
}
```

需要的欄位：
- `project_id` → `FIREBASE_PROJECT_ID`
- `private_key` → `FIREBASE_PRIVATE_KEY`
- `client_email` → `FIREBASE_CLIENT_EMAIL`

---

### 步驟 3: 更新 Backend .env 文件

編輯 `backend/.env` 文件，更新以下配置：

```bash
# Firebase Admin SDK 配置
FIREBASE_PROJECT_ID=ride-platform-f1676
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@ride-platform-f1676.iam.gserviceaccount.com
```

**注意事項**:
1. ✅ `FIREBASE_PRIVATE_KEY` 必須用雙引號包裹
2. ✅ 保留 `\n` 換行符（不要替換成真實換行）
3. ✅ 確保沒有多餘的空格或換行

**正確範例**:
```bash
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASC...\n-----END PRIVATE KEY-----\n"
```

**錯誤範例**:
```bash
# ❌ 沒有引號
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...

# ❌ 使用單引號
FIREBASE_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\n...'

# ❌ 真實換行（會導致解析錯誤）
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASC...
-----END PRIVATE KEY-----"
```

---

### 步驟 4: 重新啟動 Backend

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

**解決方案**:
1. 檢查 `.env` 文件中的配置是否正確
2. 確認 `FIREBASE_PRIVATE_KEY` 的引號和換行符
3. 重新啟動 Backend

---

## 🧪 測試服務帳戶配置

### 方法 1: 使用測試腳本

```bash
cd backend
bash test-chat-room-creation.sh
```

**預期輸出**:
```
✅ Backend 正在運行
✅ API 調用成功
✅ 聊天室資訊已返回
⏳ 請手動檢查 Firestore 確認聊天室已創建
```

### 方法 2: 手動測試 API

```bash
curl -X POST http://localhost:3000/api/booking-flow/bookings/679dd766-91fe-4628-9564-1250b86efb82/accept \
  -H "Content-Type: application/json" \
  -d '{"driverUid":"CMfTxhJFlUVDkosJPyUoJvKjCQk1"}'
```

**預期響應**:
```json
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
```

### 方法 3: 檢查 Firestore Console

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

## ❌ 常見問題

### 問題 1: Firebase Admin SDK 初始化失敗

**錯誤訊息**:
```
❌ Firebase Admin SDK 初始化失敗: Error: Invalid service account certificate
```

**原因**: `FIREBASE_PRIVATE_KEY` 格式錯誤

**解決方案**:
1. 確認 `FIREBASE_PRIVATE_KEY` 用雙引號包裹
2. 確認保留 `\n` 換行符
3. 確認沒有多餘的空格

### 問題 2: 聊天室創建失敗

**錯誤訊息**:
```
⚠️  創建聊天室失敗（不影響接單）: Error: 7 PERMISSION_DENIED
```

**原因**: Firebase Admin SDK 沒有正確初始化

**解決方案**:
1. 檢查服務帳戶配置
2. 確認 Firebase 專案 ID 正確
3. 重新下載服務帳戶私鑰

### 問題 3: Backend 日誌顯示模擬模式

**警告訊息**:
```
⚠️  Firebase Admin SDK 配置不完整，使用模擬模式
```

**原因**: `.env` 文件中的配置不完整

**解決方案**:
1. 確認 `FIREBASE_PROJECT_ID` 已設置
2. 確認 `FIREBASE_PRIVATE_KEY` 已設置
3. 確認 `FIREBASE_CLIENT_EMAIL` 已設置
4. 重新啟動 Backend

---

## 🔒 安全性注意事項

### 1. 不要提交服務帳戶私鑰到 Git

**檢查 `.gitignore`**:
```bash
# 確認以下內容在 .gitignore 中
.env
*.json  # 服務帳戶 JSON 文件
```

### 2. 使用環境變數

- ✅ 開發環境: 使用 `.env` 文件
- ✅ 生產環境: 使用環境變數（不要使用 `.env` 文件）

### 3. 定期輪換密鑰

建議每 90 天輪換一次服務帳戶私鑰：
1. 在 Firebase Console 產生新的私鑰
2. 更新 `.env` 文件
3. 重新啟動 Backend
4. 刪除舊的私鑰

---

## 📝 總結

### 完成檢查清單

- [ ] 下載服務帳戶私鑰
- [ ] 提取 `project_id`, `private_key`, `client_email`
- [ ] 更新 `backend/.env` 文件
- [ ] 重新啟動 Backend
- [ ] 測試 API 調用
- [ ] 檢查 Firestore Console
- [ ] 確認聊天室已創建
- [ ] 確認系統訊息已發送

### 下一步

完成服務帳戶設置後：
1. ✅ 測試司機確認接單功能
2. ✅ 檢查聊天室是否自動創建
3. ✅ 測試客戶端和司機端聊天頁面
4. ✅ 測試發送和接收訊息

---

**最後更新**: 2025-10-14  
**相關文檔**: 
- `docs/20251014_CHAT_ROOM_AUTO_CREATION.md`
- `backend/test-chat-room-creation.sh`

