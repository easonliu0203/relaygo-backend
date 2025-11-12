# Secret Manager 快速開始指南

**適用對象**: 已經有 OpenAI API 金鑰，想要快速設定的開發者  
**預計時間**: 10-15 分鐘

---

## 🚀 三步驟快速設定

### 方法一：使用自動化腳本（推薦）

#### Windows 用戶

```bash
# 1. 切換到 functions 目錄
cd d:\repo\firebase\functions

# 2. 執行設定腳本
setup-secrets.bat

# 3. 按照提示輸入你的 OpenAI API 金鑰
```

#### Mac/Linux 用戶

```bash
# 1. 切換到 functions 目錄
cd firebase/functions

# 2. 賦予執行權限
chmod +x setup-secrets.sh

# 3. 執行設定腳本
./setup-secrets.sh

# 4. 按照提示輸入你的 OpenAI API 金鑰
```

---

### 方法二：手動設定（3 個指令）

```bash
# 1. 確認專案
firebase use ride-platform-f1676

# 2. 創建 Secret（請替換 YOUR_OPENAI_KEY）
echo "sk-proj-YOUR_OPENAI_KEY" | firebase functions:secrets:set OPENAI_API_KEY

# 3. 驗證
firebase functions:secrets:access OPENAI_API_KEY
```

---

## 📦 部署

```bash
# 1. 安裝依賴
cd firebase/functions
npm install

# 2. 回到專案根目錄
cd ../..

# 3. 部署
firebase deploy --only functions
```

**預期輸出**:
```
✔  functions[onMessageCreate(asia-east1)] Successful update operation.
✔  functions[translateMessage(asia-east1)] Successful update operation.
✔  Deploy complete!
```

---

## ✅ 驗證

### 1. 檢查 Secret 是否創建成功

```bash
firebase functions:secrets:access OPENAI_API_KEY
```

應該會顯示你的 API 金鑰（部分遮蔽）。

### 2. 測試翻譯功能

在 Flutter App 中發送一則測試訊息，等待 3-5 秒，檢查 Firestore 中是否有 `translations` 欄位。

### 3. 查看日誌

```bash
firebase functions:log --only onMessageCreate
```

應該看到類似的日誌：
```
[onMessageCreate] New message created: msg_123 in room room_456
[onMessageCreate] Translating to: zh-TW, ja
[Translation] Translated to zh-TW in 1200ms
[Translation] Translated to ja in 1350ms
[onMessageCreate] Successfully translated to 2 languages
```

---

## 🔧 常見問題

### Q: 我的 API 金鑰在哪裡？

A: 前往 https://platform.openai.com/api-keys 創建新的 API 金鑰。

### Q: 如何更新 API 金鑰？

A: 重新執行設定指令：
```bash
echo "new-api-key" | firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions
```

### Q: 部署後出現權限錯誤？

A: 執行以下指令授予權限：
```bash
gcloud secrets add-iam-policy-binding OPENAI_API_KEY \
  --member="serviceAccount:ride-platform-f1676@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Q: 如何查看我的 Secret？

A: 
- **CLI**: `firebase functions:secrets:access OPENAI_API_KEY`
- **Console**: https://console.cloud.google.com/security/secret-manager?project=ride-platform-f1676

---

## 📚 進階設定

詳細的遷移指南和進階配置，請參考：
- [Secret Manager 遷移指南](./secret-manager-migration-guide.md)

---

## 🎉 完成！

設定完成後，你的 OpenAI API 金鑰將以最安全的方式儲存在 Google Cloud Secret Manager 中，並且不會再收到 `functions.config()` 的棄用警告。

**下一步**:
1. 在 Flutter App 中測試翻譯功能
2. 查看 Firestore 中的翻譯結果
3. 監控 Cloud Functions 日誌

有任何問題，請參考完整的遷移指南或聯絡技術支援。

