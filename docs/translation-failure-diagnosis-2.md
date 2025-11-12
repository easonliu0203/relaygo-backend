# 翻譯功能失敗診斷報告 #2

**問題發現日期**: 2025-10-17  
**測試時間**: 17:27:54 (UTC+8)  
**問題狀態**: 正在診斷

---

## 🔍 問題摘要

### 用戶報告
用戶在 OpenAI API 配額恢復並重新部署 Functions 後，測試翻譯功能仍然失敗。

### 觀察到的現象
1. ✅ Cloud Function 成功觸發（`translatedAt` 有時間戳記）
2. ❌ 翻譯失敗，錯誤訊息：`"Translation failed after 3 attempts: OpenAI API error: Connection error."`
3. ⚠️ 錯誤訊息仍然是舊的格式，沒有顯示改善後的詳細錯誤訊息

### Firestore 數據
```json
{
  "messageText": "不知道",
  "createdAt": "2025-10-17 17:27:54 (UTC+8)",
  "translatedAt": "2025-10-17 17:28:06 (UTC+8)",
  "translatedText": null,
  "translations": {
    "en": {
      "at": "2025-10-17 17:28:05 (UTC+8)",
      "error": "Translation failed after 3 attempts: OpenAI API error: Connection error."
    },
    "ja": {
      "at": "2025-10-17 17:28:05 (UTC+8)",
      "error": "Translation failed after 3 attempts: OpenAI API error: Connection error."
    }
  }
}
```

---

## 🔬 診斷分析

### 發現 1: 錯誤訊息格式分析

**錯誤訊息結構**:
```
Translation failed after 3 attempts: OpenAI API error: Connection error.
```

**分解**:
- `"Translation failed after 3 attempts: "` - 來自 `translationService.js` 第 83 行
- `"OpenAI API error: "` - 來自 `translationService.js` 第 166 行
- `"Connection error."` - 來自 OpenAI SDK 的原始錯誤

**代碼路徑**:
```javascript
// 第 83 行：重試邏輯
throw new Error(`Translation failed after ${this.maxRetries + 1} attempts: ${lastError.message}`);

// 第 166 行：錯誤分類（當沒有匹配到其他錯誤類型時）
errorMessage = `OpenAI API error: ${error.message}`;
```

### 發現 2: 為什麼改善的錯誤訊息沒有生效？

**原因**: OpenAI SDK 拋出的錯誤對象沒有 `status`、`code` 等屬性，只有 `message: "Connection error"`。

**證據**:
- 錯誤訊息走到了 `else` 分支（第 166 行）
- 這表示 `error.status`、`error.code` 等都是 `undefined`
- 因此無法匹配到任何特定的錯誤類型（429、401、ENOTFOUND 等）

### 發現 3: 可能的根本原因

有幾種可能性：

#### 可能性 1: OpenAI API 金鑰在 Cloud Functions 中無法存取
- Secret Manager 的金鑰可能沒有正確傳遞到 Cloud Functions
- 導致 OpenAI SDK 無法初始化或連線

#### 可能性 2: Cloud Functions 網路問題
- Cloud Functions 無法連線到 OpenAI API（api.openai.com）
- 可能是防火牆、VPC 設定或其他網路問題

#### 可能性 3: OpenAI SDK 版本問題
- OpenAI SDK 的錯誤處理方式可能與預期不同
- 某些錯誤被包裝成通用的 "Connection error"

---

## 🛠️ 診斷步驟

### 步驟 1: 添加詳細的錯誤日誌 ✅

**已完成**: 更新了 `translationService.js`，添加完整的錯誤對象日誌：

```javascript
console.error(`[Translation] Error after ${duration}ms:`, {
  status: error.status,
  code: error.code,
  message: error.message,
  type: error.type,
  name: error.name,
  // 記錄完整的錯誤對象以便診斷
  fullError: JSON.stringify(error, Object.getOwnPropertyNames(error)),
});
```

**部署狀態**: ✅ 已部署（剛才）

### 步驟 2: 重新測試並查看詳細日誌 ⏳

**需要用戶執行**:

1. **在 Flutter App 中發送新的測試訊息**:
   - 發送訊息：「測試 2」
   - 等待 5-10 秒

2. **查看 Cloud Functions 日誌**:
   ```bash
   firebase functions:log --only onMessageCreate
   ```

3. **尋找以下關鍵資訊**:
   - `[Translation] Error after XXXms:` - 錯誤詳情
   - `fullError` - 完整的錯誤對象 JSON

4. **提供日誌給我**:
   - 複製包含 `[Translation] Error` 的所有日誌行
   - 特別是 `fullError` 的內容

### 步驟 3: 驗證 Secret Manager 存取 ⏳

**需要用戶執行**:

```bash
# 檢查 Secret 是否存在
firebase functions:secrets:access OPENAI_API_KEY
```

**預期輸出**: 應該顯示 API 金鑰（sk-proj-xxx...）

### 步驟 4: 測試 Cloud Functions 中的 OpenAI 連線 ⏳

**需要添加臨時測試代碼**（如果步驟 2 的日誌不夠詳細）:

在 `index.js` 的 `onMessageCreate` 函數開頭添加：

```javascript
// 臨時測試代碼
console.log('[DEBUG] Testing OpenAI API connection...');
console.log('[DEBUG] API Key exists:', !!apiKey);
console.log('[DEBUG] API Key prefix:', apiKey ? apiKey.substring(0, 20) : 'N/A');

try {
  const testClient = new OpenAI({ apiKey });
  const testResponse = await testClient.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [{ role: 'user', content: 'test' }],
    max_tokens: 5,
  });
  console.log('[DEBUG] OpenAI API test successful:', testResponse.choices[0].message.content);
} catch (testError) {
  console.error('[DEBUG] OpenAI API test failed:', {
    message: testError.message,
    status: testError.status,
    code: testError.code,
    type: testError.type,
    fullError: JSON.stringify(testError, Object.getOwnPropertyNames(testError)),
  });
}
```

---

## 🎯 下一步行動

### 立即執行（現在）

1. **在 Flutter App 中發送測試訊息**:
   - 訊息內容：「測試 2」
   - 等待 5-10 秒

2. **查看 Cloud Functions 日誌**:
   ```bash
   firebase functions:log --only onMessageCreate
   ```

3. **提供以下資訊**:
   - 包含 `[Translation] Error` 的完整日誌
   - 特別是 `fullError` 的 JSON 內容
   - Firestore 中的錯誤訊息

### 根據日誌結果採取行動

#### 如果日誌顯示 `status: 429`
→ OpenAI API 配額問題（但本地測試成功，所以可能性低）

#### 如果日誌顯示 `status: 401` 或 `status: 403`
→ API 金鑰在 Cloud Functions 中無效或無法存取

#### 如果日誌顯示 `code: 'ENOTFOUND'` 或 `code: 'ECONNREFUSED'`
→ Cloud Functions 無法連線到 OpenAI API

#### 如果日誌沒有 `status` 和 `code`，只有 `message: "Connection error"`
→ 需要查看 `fullError` 的完整內容來診斷

---

## 📊 可能的解決方案

### 解決方案 1: Secret Manager 權限問題

**如果**: API 金鑰無法在 Cloud Functions 中存取

**解決方案**:
```bash
# 檢查 Service Account 權限
gcloud projects get-iam-policy ride-platform-f1676 \
  --flatten="bindings[].members" \
  --filter="bindings.members:930299492291-compute@developer.gserviceaccount.com"

# 授予 Secret Manager 存取權限
gcloud secrets add-iam-policy-binding OPENAI_API_KEY \
  --member="serviceAccount:930299492291-compute@developer.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### 解決方案 2: Cloud Functions 網路設定

**如果**: Cloud Functions 無法連線到外部 API

**解決方案**:
1. 檢查 VPC 設定
2. 檢查防火牆規則
3. 確認 Cloud Functions 有外部網路存取權限

### 解決方案 3: 使用環境變數代替 Secret Manager（臨時）

**如果**: Secret Manager 有問題

**臨時解決方案**:
```javascript
// 在 index.js 中
const apiKey = openaiApiKey.value() || process.env.OPENAI_API_KEY;
```

然後在 `firebase.json` 中添加：
```json
{
  "functions": {
    "source": "firebase/functions",
    "runtime": "nodejs20",
    "env": {
      "OPENAI_API_KEY": "sk-proj-xxx..."
    }
  }
}
```

**注意**: 這只是臨時方案，不建議在生產環境使用。

---

## 📞 需要的資訊

請提供以下資訊以便進一步診斷：

1. **Cloud Functions 日誌**（發送測試訊息後）:
   - 包含 `[Translation] Error` 的所有行
   - 特別是 `fullError` 的內容

2. **Secret Manager 驗證**:
   ```bash
   firebase functions:secrets:access OPENAI_API_KEY
   ```
   輸出結果（前 20 個字元即可）

3. **Firestore 錯誤訊息**:
   - 最新測試訊息的 `translations.*.error` 內容

---

**報告創建時間**: 2025-10-17  
**最後更新**: 2025-10-17  
**狀態**: 等待用戶提供詳細日誌

