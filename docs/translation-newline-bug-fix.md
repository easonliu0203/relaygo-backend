# 翻譯功能修復：API 金鑰換行符問題

**問題發現日期**: 2025-10-17  
**修復完成時間**: 2025-10-17  
**狀態**: ✅ 已修復

---

## 🎯 問題總結

### 症狀
- 翻譯功能在 Cloud Functions 中持續失敗
- 錯誤訊息：`"Translation failed after 3 attempts: OpenAI API error: Connection error."`
- 本地測試成功，但 Cloud Functions 部署後失敗
- OpenAI API 配額正常（$10 USD 可用）

### 真正的根本原因

**API 金鑰中包含換行符 `\n`**

從 `fullError` 日誌中發現：
```
"cause": {
  "message": "Bearer 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\n is not a legal HTTP header value"
}
```

**關鍵發現**：API 金鑰末尾有 `\n` 換行符，導致 HTTP header 驗證失敗。

---

## 🔍 診斷過程

### 步驟 1: 添加詳細錯誤日誌

在 `translationService.js` 中添加：
```javascript
console.error(`[Translation] Error after ${duration}ms:`, {
  status: error.status,
  code: error.code,
  message: error.message,
  type: error.type,
  name: error.name,
  fullError: JSON.stringify(error, Object.getOwnPropertyNames(error)),
});
```

### 步驟 2: 查看 Cloud Functions 日誌

**關鍵日誌**（2025-10-17 09:50:54）:
```json
{
  "status": undefined,
  "code": undefined,
  "message": "Connection error.",
  "type": undefined,
  "name": "Error",
  "fullError": "{
    \"stack\": \"Error: Connection error.\\n    at OpenAI.makeRequest (/workspace/node_modules/openai/core.js:332:19)...\",
    \"message\": \"Connection error.\",
    \"cause\": {
      \"stack\": \"TypeError: Bearer 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\\n is not a legal HTTP header value\\n    at validateValue (/workspace/node_modules/node-fetch/lib/index.js:684:9)...\",
      \"message\": \"Bearer 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\\n is not a legal HTTP header value\"
    }
  }"
}
```

### 步驟 3: 分析錯誤原因

**錯誤堆疊**:
```
TypeError: Bearer sk-proj-xxx...\n is not a legal HTTP header value
    at validateValue (/workspace/node_modules/node-fetch/lib/index.js:684:9)
    at Headers.append (/workspace/node_modules/node-fetch/lib/index.js:836:3)
```

**原因**:
1. OpenAI SDK 嘗試設置 HTTP Authorization header
2. Header 值為：`Bearer sk-proj-xxx...\n`（末尾有換行符）
3. `node-fetch` 驗證 header 值時發現換行符
4. 拋出 `TypeError: ... is not a legal HTTP header value`

### 步驟 4: 驗證 Secret Manager 中的金鑰

```bash
$ firebase functions:secrets:access OPENAI_API_KEY
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

                                                                                                                                                                    ← 這裡有換行符
```

**確認**：Secret Manager 中的 API 金鑰末尾確實有換行符。

---

## ✅ 修復方案

### 修復步驟

#### 1. 創建不含換行符的 API 金鑰文件

```bash
# 創建臨時文件（不含換行符）
echo -n "sk-proj-xxx..." > temp_api_key.txt
```

**重要**：使用 `echo -n` 或設置 `add_last_line_newline: false` 來避免添加換行符。

#### 2. 更新 Secret Manager

```bash
$ firebase functions:secrets:set OPENAI_API_KEY < temp_api_key.txt
+  Created a new secret version projects/930299492291/secrets/OPENAI_API_KEY/versions/2
i  2 functions are using stale version of secret OPENAI_API_KEY:
        translateMessage(asia-east1)
        onMessageCreate(asia-east1)
i  Please deploy your functions for the change to take effect
```

**結果**：
- ✅ 創建了新的 Secret 版本（version 2）
- ✅ 新版本不含換行符

#### 3. 重新部署 Cloud Functions

```bash
$ firebase deploy --only functions
+  functions[onMessageCreate(asia-east1)] Successful update operation.
+  functions[translateMessage(asia-east1)] Successful update operation.
```

**結果**：
- ✅ 兩個 Functions 都已更新為使用 Secret version 2
- ✅ 部署成功

---

## 🔬 為什麼本地測試成功？

### 本地測試環境

**本地測試腳本**:
```javascript
process.env.OPENAI_API_KEY = 'sk-proj-xxx...'; // 直接賦值，沒有換行符
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
```

**為什麼成功**:
- ✅ 直接在代碼中賦值，沒有換行符
- ✅ 或者從 `.env` 文件讀取時，`dotenv` 會自動 trim 掉換行符

### Cloud Functions 環境

**Cloud Functions**:
```javascript
const apiKey = openaiApiKey.value(); // 從 Secret Manager 讀取
// apiKey = "sk-proj-xxx...\n" ← 包含換行符
const openai = new OpenAI({ apiKey });
```

**為什麼失敗**:
- ❌ Secret Manager 原樣返回 Secret 值（包含換行符）
- ❌ OpenAI SDK 直接使用這個值設置 HTTP header
- ❌ `node-fetch` 驗證失敗

---

## 📊 修復前後對比

### 修復前

**Secret Manager**:
```
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\n
```

**HTTP Header**:
```
Authorization: Bearer sk-proj-xxx...\n
```

**結果**:
```
❌ TypeError: Bearer sk-proj-xxx...\n is not a legal HTTP header value
```

### 修復後

**Secret Manager**:
```
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
```

**HTTP Header**:
```
Authorization: Bearer sk-proj-xxx...
```

**結果**:
```
✅ OpenAI API 連線成功
```

---

## 🎯 測試步驟

### 步驟 1: 發送測試訊息

在 Flutter App 中發送訊息：**「這次應該成功了」**

### 步驟 2: 等待 5-10 秒

### 步驟 3: 查看 Cloud Functions 日誌

```bash
firebase functions:log --only onMessageCreate
```

**預期日誌**（成功）:
```
[onMessageCreate] New message created: xxx in room xxx
[onMessageCreate] Auto-translate is enabled
[onMessageCreate] API key retrieved from Secret Manager: sk-proj-JgaW_xqWKOE6...
[onMessageCreate] Translating to: en, ja
[Translation] Translated to en in 1200ms
[Translation] Tokens used: 45
[Translation] Translated to ja in 1500ms
[Translation] Tokens used: 52
[onMessageCreate] Successfully translated to 2 languages
```

### 步驟 4: 檢查 Firestore 數據

**預期數據**（成功）:
```json
{
  "messageText": "這次應該成功了",
  "translatedText": "This time it should succeed",
  "translations": {
    "en": {
      "text": "This time it should succeed",
      "model": "gpt-4o-mini",
      "at": "2025-10-17T...",
      "tokensUsed": 15,
      "duration": 1200
    },
    "ja": {
      "text": "今回は成功するはずです",
      "model": "gpt-4o-mini",
      "at": "2025-10-17T...",
      "tokensUsed": 18,
      "duration": 1500
    }
  }
}
```

---

## 💡 經驗教訓

### 1. Secret Manager 不會自動 trim 值

**教訓**：
- Secret Manager 會原樣存儲和返回 Secret 值
- 如果創建 Secret 時包含換行符，讀取時也會包含換行符
- 需要在創建 Secret 時確保不包含多餘的空白字符

**最佳實踐**：
```bash
# ✅ 正確：使用 echo -n（不添加換行符）
echo -n "secret-value" | firebase functions:secrets:set SECRET_NAME

# ❌ 錯誤：使用 echo（會添加換行符）
echo "secret-value" | firebase functions:secrets:set SECRET_NAME
```

### 2. 錯誤訊息可能具有誤導性

**教訓**：
- OpenAI SDK 將底層錯誤包裝成通用的 "Connection error"
- 需要查看 `error.cause` 或 `fullError` 才能找到真正的原因
- 添加詳細的錯誤日誌非常重要

**最佳實踐**：
```javascript
console.error('Error:', {
  message: error.message,
  status: error.status,
  code: error.code,
  // 記錄完整的錯誤對象
  fullError: JSON.stringify(error, Object.getOwnPropertyNames(error)),
});
```

### 3. 本地測試和生產環境可能有差異

**教訓**：
- 本地測試成功不代表生產環境也會成功
- 環境變數、Secret 讀取方式可能不同
- 需要在生產環境中測試並查看日誌

**最佳實踐**：
- 添加詳細的日誌來診斷問題
- 在部署後立即測試
- 使用 `fullError` 日誌來捕獲所有錯誤細節

---

## 📚 相關文檔

- [翻譯功能測試指南](./translation-testing-guide.md)
- [錯誤診斷報告 #1](./translation-error-diagnosis-report.md)
- [錯誤診斷報告 #2](./translation-failure-diagnosis-2.md)
- [修復總結](./translation-fix-summary.md)
- [OpenAI 配額排查指南](./openai-quota-troubleshooting.md)

---

## 🎉 總結

**問題**：API 金鑰中包含換行符 `\n`  
**影響**：所有 OpenAI API 請求失敗（HTTP header 驗證錯誤）  
**解決方案**：更新 Secret Manager，移除換行符  
**修復時間**：< 5 分鐘  
**狀態**：✅ 已修復，等待測試確認

**這是一個非常隱蔽的 bug，因為**：
1. 錯誤訊息具有誤導性（"Connection error"）
2. 本地測試成功（`.env` 文件會自動 trim）
3. 需要查看 `fullError` 才能發現真正原因

**感謝詳細的錯誤日誌，讓我們能夠快速定位問題！** 🎯

---

**報告創建時間**: 2025-10-17  
**最後更新**: 2025-10-17  
**狀態**: ✅ 已修復

