# Firebase Service Account 設置指南

**問題**：Firestore REST API 不接受 Web API Key  
**解決**：使用 Firebase Admin SDK 和 Service Account  
**預計時間**：5 分鐘

---

## 🔍 問題診斷

### 錯誤訊息
```
"reason": "ACCESS_TOKEN_TYPE_UNSUPPORTED"
"message": "Expected OAuth 2 access token"
```

### 根本原因
- **錯誤的認證方式**：使用了 Firebase Web API Key（AIza...）
- **正確的認證方式**：需要 Firebase Service Account JSON

**說明**：
- Web API Key 只能用於客戶端 SDK（瀏覽器、手機 App）
- Server-side 需要使用 Service Account 進行認證
- Edge Function 是 server-side，所以需要 Service Account

---

## 🚀 修復步驟

### 步驟 1：獲取 Firebase Service Account JSON（2 分鐘）

1. **打開 Firebase Console**
   ```
   https://console.firebase.google.com
   ```

2. **選擇您的專案**

3. **進入 Project Settings**
   - 點擊左上角齒輪圖標
   - 選擇「Project Settings」

4. **進入 Service Accounts 標籤**
   - 點擊「Service accounts」標籤

5. **生成新的 Private Key**
   - 點擊「Generate new private key」按鈕
   - 確認對話框
   - 會下載一個 JSON 檔案（例如：`your-project-firebase-adminsdk-xxxxx.json`）

6. **打開 JSON 檔案**
   - 使用文字編輯器打開下載的 JSON 檔案
   - 複製整個 JSON 內容

**JSON 格式範例**：
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "xxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\nXXXXX\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  "client_id": "xxxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40your-project.iam.gserviceaccount.com"
}
```

---

### 步驟 2：設置環境變數（2 分鐘）

1. **打開 Supabase 環境變數設置頁面**
   ```
   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/settings/functions
   ```

2. **刪除舊的環境變數**（如果存在）
   - 刪除 `FIREBASE_API_KEY`（不再需要）
   - 刪除 `FIREBASE_PROJECT_ID`（不再需要）

3. **添加新的環境變數**

   **變數名稱**：`FIREBASE_SERVICE_ACCOUNT`
   
   **變數值**：整個 JSON 內容（從步驟 1 複製的）
   
   **重要**：
   - 貼上整個 JSON，包括 `{` 和 `}`
   - 確保沒有多餘的空格或換行
   - JSON 必須是有效的格式

4. **確認其他環境變數**

   確保以下變數存在：
   
   | 變數名稱 | 值 |
   |----------|-----|
   | `SUPABASE_URL` | `https://vlyhwegpvpnjyocqmfqc.supabase.co` |
   | `SUPABASE_SERVICE_ROLE_KEY` | 您的 Supabase Service Role Key |

5. **保存**
   - 點擊「Save」或「Update」

---

### 步驟 3：重新部署 Edge Function（1 分鐘）

**Edge Function 代碼已更新**，需要重新部署：

```bash
cd d:\repo
npx supabase functions deploy sync-to-firestore --project-ref vlyhwegpvpnjyocqmfqc
```

**或者在 Supabase Dashboard 手動部署**：
1. 打開：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
2. 點擊 sync-to-firestore
3. 點擊「Deploy」（如果有此選項）

---

### 步驟 4：測試（30 秒）

1. **手動觸發 Edge Function**
   - 在 Functions 頁面
   - 點擊 sync-to-firestore
   - 點擊「Invoke」

2. **預期結果**
   ```json
   {
     "message": "事件處理完成",
     "total": 7,
     "success": 7,  // ✅ 全部成功
     "failure": 0   // ✅ 沒有失敗
   }
   ```

3. **檢查日誌**
   - 點擊「Logs」標籤
   - 應該看到：
     - `✅ Firebase Admin 初始化成功`
     - `✅ Firestore 文檔已更新: orders_rt/...`
   - 不應該看到 401 錯誤

---

## 📊 修復前後對比

### 修復前（錯誤）
```typescript
// 使用 Web API Key（不支援 server-side）
const FIREBASE_API_KEY = Deno.env.get('FIREBASE_API_KEY')!

// 使用 REST API + Bearer token
const response = await fetch(url, {
  headers: {
    'Authorization': `Bearer ${FIREBASE_API_KEY}`,  // ❌ 401 錯誤
  }
})
```

### 修復後（正確）
```typescript
// 使用 Service Account JSON
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!
const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT)

// 使用 Firebase Admin SDK
const firebaseApp = initializeApp({
  credential: cert(serviceAccount)  // ✅ 正確認證
})
const db = getFirestore(firebaseApp)

// 直接使用 SDK
await db.collection('orders_rt').doc(bookingId).set(data)  // ✅ 成功
```

---

## ✅ 驗證修復成功

### 1. Edge Function 測試
```json
{
  "success": 7,
  "failure": 0
}
```

### 2. Edge Function 日誌
```
✅ Firebase Admin 初始化成功
準備更新 Firestore: orders_rt/xxx
✅ Firestore 文檔已更新: orders_rt/xxx
```

### 3. Firestore Console
- 打開 Firebase Console → Firestore
- 查看 `orders_rt` 集合
- 應該看到 7 個訂單文檔

### 4. 手機 App
- 打開 App
- 查看訂單詳情
- 不再顯示「訂單不存在」

---

## 🆘 故障排除

### 問題 A：JSON 格式錯誤

**錯誤訊息**：
```
JSON parse error
或
Unexpected token
```

**解決**：
- 確認 JSON 格式正確
- 使用 JSON 驗證工具：https://jsonlint.com
- 確保沒有多餘的空格或換行

---

### 問題 B：權限不足

**錯誤訊息**：
```
Permission denied
或
Insufficient permissions
```

**解決**：
- 確認 Service Account 有 Firestore 權限
- 在 Firebase Console → IAM & Admin 中檢查權限
- Service Account 應該有「Firebase Admin SDK Administrator Service Agent」角色

---

### 問題 C：Firebase Admin 初始化失敗

**錯誤訊息**：
```
Firebase Admin 初始化失敗
```

**解決**：
1. 檢查環境變數 `FIREBASE_SERVICE_ACCOUNT` 是否正確設置
2. 檢查 JSON 格式是否有效
3. 查看 Edge Function 日誌獲取詳細錯誤

---

## 📋 檢查清單

- [ ] 從 Firebase Console 下載 Service Account JSON
- [ ] 複製整個 JSON 內容
- [ ] 在 Supabase Dashboard 設置 `FIREBASE_SERVICE_ACCOUNT` 環境變數
- [ ] 刪除舊的 `FIREBASE_API_KEY` 和 `FIREBASE_PROJECT_ID`（可選）
- [ ] 確認 `SUPABASE_URL` 和 `SUPABASE_SERVICE_ROLE_KEY` 存在
- [ ] 保存環境變數
- [ ] 重新部署 Edge Function
- [ ] 測試 Edge Function（Invoke）
- [ ] 檢查日誌（應該看到 ✅ Firebase Admin 初始化成功）
- [ ] 驗證 Firestore 有資料
- [ ] 測試 App

---

**狀態**：⏳ 等待設置 Service Account  
**下一步**：獲取 Service Account JSON 並設置環境變數  
**預計時間**：5 分鐘

🚀 **請立即執行步驟 1 和步驟 2，然後告訴我結果！**

