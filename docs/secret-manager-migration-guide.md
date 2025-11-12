# Secret Manager 遷移指南

**目的**: 從 Firebase Functions Config (`functions.config()`) 遷移到 Google Cloud Secret Manager  
**原因**: Firebase Functions Config 將於 2026 年 3 月停用  
**日期**: 2025-10-17

---

## 📊 為什麼選擇 Secret Manager？

### Secret Manager 的優勢

| 功能 | functions.config() | .env 檔案 | Secret Manager |
|------|-------------------|-----------|----------------|
| **安全性** | ⚠️ 中等 | ❌ 低（易洩漏） | ✅ 高（加密儲存） |
| **版本控制** | ❌ 無 | ❌ 無 | ✅ 完整版本歷史 |
| **存取控制** | ⚠️ 基本 | ❌ 無 | ✅ IAM 精細控制 |
| **審計日誌** | ❌ 無 | ❌ 無 | ✅ 完整審計追蹤 |
| **自動輪替** | ❌ 無 | ❌ 無 | ✅ 支援 |
| **跨服務共享** | ❌ 僅 Functions | ❌ 僅本機 | ✅ 所有 GCP 服務 |
| **加密** | ⚠️ 基本 | ❌ 明文 | ✅ 靜態加密 |
| **成本** | ✅ 免費 | ✅ 免費 | ⚠️ 小額費用* |

**成本說明**: Secret Manager 前 6 個 secrets 免費，每個額外 secret $0.06/月。對於我們的使用場景（1-2 個 secrets），**完全免費**。

### 安全性優勢詳解

1. **加密儲存**: Secrets 使用 Google 管理的加密金鑰加密
2. **存取控制**: 可精確控制哪些服務帳號可以存取哪些 secrets
3. **審計追蹤**: 所有存取都會記錄在 Cloud Audit Logs
4. **版本管理**: 可以回滾到舊版本的 secret
5. **自動輪替**: 支援定期自動更新 API 金鑰

---

## 🚀 遷移步驟總覽

```
1. 啟用 Secret Manager API
   ↓
2. 創建 Secret（儲存 OpenAI API 金鑰）
   ↓
3. 授予 Cloud Functions 存取權限
   ↓
4. 修改程式碼（使用 defineSecret）
   ↓
5. 部署更新後的 Functions
   ↓
6. 驗證功能正常
   ↓
7. 清理舊的 functions.config()
```

---

## 📝 詳細步驟

### 步驟 1: 啟用 Secret Manager API

#### 方法 A: 使用 Firebase CLI（推薦）

```bash
# 確認專案
firebase use ride-platform-f1676

# 啟用 Secret Manager API
firebase projects:addfirebase ride-platform-f1676
```

#### 方法 B: 使用 gcloud CLI

```bash
# 設定專案
gcloud config set project ride-platform-f1676

# 啟用 API
gcloud services enable secretmanager.googleapis.com
```

#### 方法 C: 使用 Google Cloud Console

1. 前往 https://console.cloud.google.com/apis/library/secretmanager.googleapis.com
2. 選擇專案 `ride-platform-f1676`
3. 點選「啟用」

---

### 步驟 2: 創建 Secret

#### 方法 A: 使用 Firebase CLI（最簡單）

```bash
# 創建 OpenAI API 金鑰 Secret
# 請將 YOUR_OPENAI_API_KEY 替換成你的實際金鑰
firebase functions:secrets:set OPENAI_API_KEY
# 執行後會提示你輸入 secret 值，貼上你的 OpenAI API 金鑰

# 或者一行指令完成（推薦）
echo "sk-proj-YOUR_ACTUAL_KEY" | firebase functions:secrets:set OPENAI_API_KEY
```

#### 方法 B: 使用 gcloud CLI

```bash
# 創建 Secret
echo -n "sk-proj-YOUR_ACTUAL_KEY" | gcloud secrets create OPENAI_API_KEY \
  --data-file=- \
  --replication-policy="automatic"

# 驗證創建成功
gcloud secrets list
```

#### 方法 C: 使用 Google Cloud Console

1. 前往 https://console.cloud.google.com/security/secret-manager
2. 點選「建立密鑰」
3. 名稱: `OPENAI_API_KEY`
4. 密鑰值: 貼上你的 OpenAI API 金鑰
5. 點選「建立密鑰」

---

### 步驟 3: 授予 Cloud Functions 存取權限

Firebase Functions 會自動授予權限，但如果遇到權限問題，可以手動設定：

```bash
# 獲取 Cloud Functions 服務帳號
PROJECT_ID="ride-platform-f1676"
SERVICE_ACCOUNT="${PROJECT_ID}@appspot.gserviceaccount.com"

# 授予存取權限
gcloud secrets add-iam-policy-binding OPENAI_API_KEY \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

---

### 步驟 4: 修改程式碼

我已經為你準備好修改後的程式碼，主要變更：

#### 4.1 修改 `index.js`

**變更重點**:
- 使用 `defineSecret()` 定義 secrets
- 在 function 定義中使用 `runWith({ secrets: [...] })`
- 透過 `secret.value()` 讀取 secret 值

#### 4.2 修改 `translationService.js`

**變更重點**:
- 接受 `apiKey` 作為參數（而非從 process.env 讀取）
- 保持其他邏輯不變

---

### 步驟 5: 部署

```bash
# 確保在專案根目錄
cd d:\repo

# 安裝依賴（如果還沒安裝）
cd firebase/functions
npm install
cd ../..

# 部署 Functions
firebase deploy --only functions
```

**預期輸出**:
```
✔  functions: Finished running predeploy script.
i  functions: preparing codebase default for deployment
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: Loading and analyzing source code for codebase default to determine what to deploy
Serving at port 8081

i  functions: preparing functions directory for uploading...
i  functions: packaged /path/to/functions (X.XX MB) for uploading
✔  functions: functions folder uploaded successfully

The following functions will deploy:
  onMessageCreate(asia-east1)
  translateMessage(asia-east1)

i  functions: creating Node.js 18 function onMessageCreate(asia-east1)...
i  functions: creating Node.js 18 function translateMessage(asia-east1)...
✔  functions[onMessageCreate(asia-east1)] Successful update operation.
✔  functions[translateMessage(asia-east1)] Successful update operation.

✔  Deploy complete!
```

---

### 步驟 6: 驗證

#### 6.1 檢查 Secret 是否正確綁定

```bash
# 查看 Function 的 secrets
firebase functions:secrets:access OPENAI_API_KEY
```

#### 6.2 測試翻譯功能

```bash
# 查看 Functions 日誌
firebase functions:log --only onMessageCreate

# 或執行測試腳本
cd firebase/functions
node test/test-translation.js
```

#### 6.3 在 Flutter App 中測試

1. 發送一則測試訊息
2. 檢查是否自動翻譯
3. 查看 Firestore 中的 `translations` 欄位

---

### 步驟 7: 清理舊配置（選用）

確認新的 Secret Manager 運作正常後，可以清理舊的 functions.config()：

```bash
# 查看現有配置
firebase functions:config:get

# 刪除舊配置（謹慎操作！）
firebase functions:config:unset openai
firebase functions:config:unset translation

# 重新部署以套用變更
firebase deploy --only functions
```

---

## 🔧 進階配置

### 創建其他環境變數的 Secrets

```bash
# 如果你想將其他配置也移到 Secret Manager
firebase functions:secrets:set TRANSLATION_CONFIG
# 輸入 JSON 格式的配置：
# {"auto_translate": true, "target_languages": ["zh-TW", "en", "ja"]}
```

### 更新 Secret 值

```bash
# 方法 1: 使用 Firebase CLI
echo "new-api-key-value" | firebase functions:secrets:set OPENAI_API_KEY

# 方法 2: 使用 gcloud CLI
echo -n "new-api-key-value" | gcloud secrets versions add OPENAI_API_KEY --data-file=-

# 部署以使用新版本
firebase deploy --only functions
```

### 查看 Secret 版本歷史

```bash
# 列出所有版本
gcloud secrets versions list OPENAI_API_KEY

# 查看特定版本
gcloud secrets versions access 1 --secret="OPENAI_API_KEY"
```

### 回滾到舊版本

```bash
# 停用當前版本
gcloud secrets versions disable latest --secret="OPENAI_API_KEY"

# 啟用舊版本
gcloud secrets versions enable 1 --secret="OPENAI_API_KEY"

# 重新部署
firebase deploy --only functions
```

---

## 🐛 故障排除

### 問題 1: 權限錯誤

**錯誤訊息**: `Permission denied on secret OPENAI_API_KEY`

**解決方案**:
```bash
# 手動授予權限
PROJECT_ID="ride-platform-f1676"
SERVICE_ACCOUNT="${PROJECT_ID}@appspot.gserviceaccount.com"

gcloud secrets add-iam-policy-binding OPENAI_API_KEY \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

### 問題 2: Secret 不存在

**錯誤訊息**: `Secret OPENAI_API_KEY not found`

**解決方案**:
```bash
# 檢查 Secret 是否存在
gcloud secrets list

# 如果不存在，重新創建
echo "sk-proj-YOUR_KEY" | firebase functions:secrets:set OPENAI_API_KEY
```

### 問題 3: 部署後 Function 無法啟動

**錯誤訊息**: `Function failed on loading user code`

**解決方案**:
```bash
# 查看詳細錯誤日誌
firebase functions:log --only onMessageCreate

# 檢查程式碼語法錯誤
cd firebase/functions
npm run lint
```

### 問題 4: Secret 值讀取為空

**症狀**: `secret.value()` 返回空字串

**解決方案**:
```bash
# 確認 Secret 有值
firebase functions:secrets:access OPENAI_API_KEY

# 確認 Function 有正確綁定 Secret
# 查看 Firebase Console > Functions > 選擇 Function > 配置
```

---

## 📊 成本估算

### Secret Manager 定價

- **前 6 個 active secrets**: 免費
- **每個額外 active secret**: $0.06/月
- **每 10,000 次存取**: $0.03

### 我們的使用場景

- **Secrets 數量**: 1 個（OPENAI_API_KEY）
- **每月存取次數**: ~10,000 次（假設每天 300 則訊息）
- **每月成本**: **$0.00**（在免費額度內）

---

## ✅ 遷移檢查清單

### 遷移前

- [ ] 已啟用 Secret Manager API
- [ ] 已取得 OpenAI API 金鑰
- [ ] 已備份現有的 functions.config()

### 遷移中

- [ ] 已創建 OPENAI_API_KEY Secret
- [ ] 已授予 Cloud Functions 存取權限
- [ ] 已修改程式碼使用 defineSecret
- [ ] 已更新 package.json（如需要）
- [ ] 已部署更新後的 Functions

### 遷移後

- [ ] 自動翻譯功能正常
- [ ] 按需翻譯 API 正常
- [ ] 日誌無錯誤訊息
- [ ] 已清理舊的 functions.config()（選用）

---

## 📚 參考資源

- [Firebase Functions Secrets 官方文檔](https://firebase.google.com/docs/functions/config-env#secret-manager)
- [Google Cloud Secret Manager 文檔](https://cloud.google.com/secret-manager/docs)
- [Secret Manager 定價](https://cloud.google.com/secret-manager/pricing)
- [IAM 權限管理](https://cloud.google.com/iam/docs/overview)

---

**遷移完成後，你的 API 金鑰將以最安全的方式儲存，並且不會再收到棄用警告！** 🎉

