# 診斷：Edge Function 顯示成功但 Firestore 沒有資料

**問題**：手動觸發顯示 `success: 7`，但 Firestore 沒有資料  
**最可能原因**：環境變數 `FIREBASE_SERVICE_ACCOUNT` 未設置  
**預計修復時間**：5 分鐘

---

## 🔍 問題分析

### 症狀
1. ✅ 手動觸發 Edge Function 返回 `success: 7, failure: 0`
2. ✅ Supabase `bookings` 表有新訂單
3. ✅ Supabase `outbox` 表有事件記錄
4. ❌ Firebase Firestore 沒有新訂單
5. ❌ 客戶端 App 顯示「訂單不存在」

### 診斷
**這種情況通常表示**：
- Edge Function 代碼執行了，但沒有真正寫入 Firestore
- 最可能的原因：環境變數 `FIREBASE_SERVICE_ACCOUNT` 未設置
- Edge Function 在獲取 Service Account 時失敗，但沒有拋出錯誤

---

## 🚀 立即診斷（三步驟）

### 步驟 1：檢查環境變數（1 分鐘）

1. **打開環境變數設置頁面**
   ```
   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/settings/functions
   ```

2. **檢查是否有 `FIREBASE_SERVICE_ACCOUNT` 變數**
   - 如果**沒有** → 跳到「修復方案 A」
   - 如果**有** → 繼續步驟 2

---

### 步驟 2：查看 Edge Function 日誌（1 分鐘）

1. **打開 Functions 頁面**
   ```
   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
   ```

2. **點擊 sync-to-firestore**

3. **點擊「Logs」標籤**

4. **查找以下訊息**：

   **如果看到**：
   ```
   ❌ Service Account 解析失敗
   或
   Cannot read property 'project_id' of undefined
   或
   JSON parse error
   ```
   → 跳到「修復方案 A」（環境變數未設置或格式錯誤）

   **如果看到**：
   ```
   ✅ Service Account 解析成功
   🔑 獲取新的 Access Token...
   ❌ 獲取 Access Token 失敗
   ```
   → 跳到「修復方案 B」（Service Account 格式錯誤）

   **如果看到**：
   ```
   ✅ Service Account 解析成功
   ✅ Access Token 獲取成功
   ✅ Firestore 文檔已更新
   ```
   → 跳到「修復方案 C」（其他問題）

---

### 步驟 3：執行 SQL 診斷（1 分鐘）

1. **打開 SQL Editor**
   ```
   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/sql
   ```

2. **執行診斷查詢**
   - 複製 `supabase/check-firestore-sync.sql` 內容
   - 貼到 SQL Editor
   - 點擊「Run」

3. **查看診斷結果**
   - 記下「診斷建議」部分的內容
   - 告訴我結果

---

## 🔧 修復方案

### 修復方案 A：設置 FIREBASE_SERVICE_ACCOUNT（最可能）

**如果環境變數未設置或格式錯誤**：

#### 1. 獲取 Firebase Service Account JSON（2 分鐘）

1. **打開 Firebase Console**
   ```
   https://console.firebase.google.com
   ```

2. **選擇您的專案**

3. **進入 Project Settings → Service accounts**
   - 點擊左上角齒輪圖標
   - 選擇「Project Settings」
   - 點擊「Service accounts」標籤

4. **生成新的 Private Key**
   - 點擊「Generate new private key」按鈕
   - 確認對話框
   - 會下載一個 JSON 檔案（例如：`your-project-firebase-adminsdk-xxxxx.json`）

5. **打開 JSON 檔案**
   - 使用文字編輯器（Notepad、VS Code）打開
   - 複製**整個 JSON 內容**（從 `{` 到 `}`）

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
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

#### 2. 設置環境變數（1 分鐘）

1. **打開環境變數設置頁面**
   ```
   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/settings/functions
   ```

2. **添加環境變數**
   - 點擊「Add variable」或「New secret」
   - **Name**: `FIREBASE_SERVICE_ACCOUNT`
   - **Value**: 貼上整個 JSON 內容（從步驟 1 複製的）

3. **重要**：
   - 確保貼上**整個 JSON**，包括 `{` 和 `}`
   - 確保沒有多餘的空格或換行
   - JSON 必須是有效的格式

4. **保存**
   - 點擊「Save」或「Update」

#### 3. 重新測試（1 分鐘）

1. **返回 Functions 頁面**
   ```
   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
   ```

2. **點擊 sync-to-firestore → Invoke**

3. **預期結果**：
   ```json
   {
     "message": "事件處理完成",
     "total": 7,
     "success": 7,
     "failure": 0
   }
   ```

4. **檢查日誌**：
   - 點擊「Logs」標籤
   - 應該看到：
     - `✅ Service Account 解析成功, Project ID: your-project-id`
     - `🔑 獲取新的 Access Token...`
     - `✅ Access Token 獲取成功`
     - `✅ Firestore 文檔已更新: orders_rt/...`

5. **檢查 Firestore**：
   - 打開 Firebase Console → Firestore
   - 查看 `orders_rt` 集合
   - 應該看到新的訂單文檔

---

### 修復方案 B：修復 Service Account 格式

**如果日誌顯示「獲取 Access Token 失敗」**：

1. **檢查 JSON 格式**
   - 使用 JSON 驗證工具：https://jsonlint.com
   - 貼上您的 Service Account JSON
   - 確認格式正確

2. **檢查 private_key**
   - 確保包含 `-----BEGIN PRIVATE KEY-----` 和 `-----END PRIVATE KEY-----`
   - 確保 `\n` 換行符存在

3. **重新設置環境變數**
   - 刪除舊的 `FIREBASE_SERVICE_ACCOUNT`
   - 重新添加（使用正確格式的 JSON）

---

### 修復方案 C：檢查 Firestore 權限

**如果日誌顯示「Access Token 獲取成功」但仍然失敗**：

1. **檢查 Service Account 權限**
   - 打開 Firebase Console → IAM & Admin
   - 找到您的 Service Account
   - 確認有「Firebase Admin SDK Administrator Service Agent」角色

2. **檢查 Firestore 安全規則**
   - 打開 Firebase Console → Firestore → Rules
   - 確認允許寫入 `orders_rt` 集合

---

## 📊 驗證修復成功

### 1. Edge Function 日誌
```
✅ Service Account 解析成功, Project ID: your-project-id
🔑 獲取新的 Access Token...
✅ Access Token 獲取成功
準備更新 Firestore: orders_rt/xxx
✅ Firestore 文檔已更新: orders_rt/xxx
```

### 2. Firestore Console
- 打開 Firebase Console → Firestore
- 查看 `orders_rt` 集合
- 應該看到新的訂單文檔

### 3. 客戶端 App
- 打開 App
- 查看訂單詳情
- 不再顯示「訂單不存在」

---

## 🎯 最快的修復流程

**如果您確定環境變數未設置**（90% 的情況）：

1. ✅ 從 Firebase Console 下載 Service Account JSON（2 分鐘）
2. ✅ 在 Supabase 設置 `FIREBASE_SERVICE_ACCOUNT` 環境變數（1 分鐘）
3. ✅ 重新測試 Edge Function（1 分鐘）
4. ✅ 檢查 Firestore 有資料（30 秒）
5. ✅ 測試 App（30 秒）

**總計**：5 分鐘

---

## 📋 檢查清單

- [ ] 檢查環境變數是否有 `FIREBASE_SERVICE_ACCOUNT`
- [ ] 如果沒有，從 Firebase Console 下載 Service Account JSON
- [ ] 設置 `FIREBASE_SERVICE_ACCOUNT` 環境變數
- [ ] 保存環境變數
- [ ] 重新測試 Edge Function（Invoke）
- [ ] 檢查日誌（應該看到 ✅ Access Token 獲取成功）
- [ ] 檢查 Firestore 有資料
- [ ] 測試 App

---

## 🆘 如果仍然失敗

**請提供以下資訊**：

1. **環境變數截圖**
   - Supabase Dashboard → Settings → Functions
   - 顯示是否有 `FIREBASE_SERVICE_ACCOUNT`

2. **Edge Function 日誌**
   - 最近一次 Invoke 的完整日誌
   - 特別是錯誤訊息

3. **SQL 診斷結果**
   - 執行 `supabase/check-firestore-sync.sql` 的結果
   - 特別是「診斷建議」部分

我會根據這些資訊提供進一步的修復方案。

---

**當前狀態**：⏳ 等待診斷  
**最可能問題**：環境變數 `FIREBASE_SERVICE_ACCOUNT` 未設置  
**推薦行動**：立即執行修復方案 A  
**預計時間**：5 分鐘

🚀 **請立即執行步驟 1 檢查環境變數，然後告訴我結果！**

