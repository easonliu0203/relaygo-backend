# 翻譯功能錯誤診斷報告

**問題發現日期**: 2025-10-17  
**問題狀態**: 已診斷，待修復  
**影響範圍**: 所有自動翻譯功能

---

## 🔍 問題摘要

### 症狀
用戶在 Firestore 中發送訊息後，自動翻譯功能失敗，錯誤訊息為 "Connection error"。

### 根本原因
**OpenAI API 配額已用盡（HTTP 429 錯誤）**

### 誤導性錯誤訊息
- Firestore 顯示：`"Translation failed after 3 attempts: Connection error."`
- 實際錯誤：`429 You exceeded your current quota`
- 原因：OpenAI Node.js SDK 將 HTTP 429 錯誤包裝成了通用的 "Connection error"

---

## 📊 診斷過程

### 1. 檢查 Firestore 數據

**位置**: `chat_rooms/{roomId}/messages/{messageId}`

**觀察到的數據**:
```json
{
  "messageText": "不懂",
  "translatedAt": "2025-10-17T14:11:22+08:00",
  "translatedText": null,
  "translations": {
    "en": {
      "at": "2025-10-17T14:11:21+08:00",
      "error": "Translation failed after 3 attempts: Connection error."
    },
    "ja": {
      "at": "2025-10-17T14:11:21+08:00",
      "error": "Translation failed after 3 attempts: Connection error."
    }
  }
}
```

**分析**:
- ✅ Cloud Function 成功觸發（`translatedAt` 有時間戳記）
- ❌ 翻譯失敗（`translations.*.error` 有錯誤訊息）
- ❌ `translatedText` 為 `null`（應該包含翻譯結果）
- ⏱️ 翻譯嘗試時間：約 10 秒（表示有重試機制運作）

### 2. 檢查 Cloud Functions 日誌

**指令**: `firebase functions:log --only onMessageCreate`

**關鍵日誌**:
```
[onMessageCreate] New message created: ZF1CvYvrJSJvegkJeCBG in room 19dc008a-...
[onMessageCreate] Translating to: en, ja
[Translation] Attempt 1 failed: Connection error.
[Translation] Retrying in 1000ms...
[Translation] Attempt 2 failed: Connection error.
[Translation] Retrying in 2000ms...
[Translation] Attempt 3 failed: Connection error.
```

**分析**:
- ✅ Function 正常觸發
- ✅ 重試機制正常運作（指數退避：1s, 2s）
- ❌ 所有重試都失敗
- ⚠️ 錯誤訊息不夠詳細（只顯示 "Connection error"）

### 3. 驗證 Secret Manager

**指令**: `firebase functions:secrets:access OPENAI_API_KEY`

**結果**:
```
sk-proj-JgaW_xqWKOE6UEtGn9rJP4QPfclaW4YYErJIuC31Bs5BunZMbrXUECh-U9uwTL0jEAH1wTARjXT3BlbkFJ_3...
```

**分析**:
- ✅ Secret Manager 正常運作
- ✅ API 金鑰可以正常讀取
- ✅ Cloud Functions 有正確的存取權限

### 4. 測試 OpenAI API 連線

**指令**:
```bash
cd firebase/functions
node -e "
const OpenAI = require('openai');
const apiKey = 'sk-proj-JgaW_xqWKOE6UEtGn9rJP4QPfclaW4YYErJIuC31Bs5BunZMbrXUECh-U9uwTL0jEAH1wTARjXT3BlbkFJ_3...';
const client = new OpenAI({ apiKey });
client.chat.completions.create({
  model: 'gpt-4o-mini',
  messages: [{ role: 'user', content: 'test' }],
  max_tokens: 10
})
.then(() => console.log('✅ Success'))
.catch(e => console.error('❌ Error:', e.message));
"
```

**結果**:
```
❌ OpenAI API error: 429 You exceeded your current quota, 
please check your plan and billing details. 
For more information on this error, read the docs: 
https://platform.openai.com/docs/guides/error-codes/api-errors.
```

**分析**:
- ❌ OpenAI API 配額已用盡
- ✅ 這是真正的錯誤原因
- ⚠️ SDK 將此錯誤包裝成了 "Connection error"

---

## ✅ 解決方案

### 方案 1: 充值 OpenAI 帳戶（立即執行）

#### 步驟 1: 檢查帳單狀態
1. 登入 OpenAI Platform: https://platform.openai.com/
2. 進入 **Settings** > **Billing** > **Usage**
3. 檢查配額使用情況和帳單狀態

#### 步驟 2: 充值帳戶
1. 進入 **Settings** > **Billing** > **Payment methods**
2. 添加付款方式（信用卡）
3. 充值 $10-$20 USD
4. 設定自動充值（建議）

**建議配置**:
```
- 初始充值: $10 USD
- 自動充值閾值: $2 USD
- 每月限制: $20 USD
- 警告閾值: $15 USD
```

#### 步驟 3: 等待配額恢復
- 充值後通常 **5-10 分鐘**內生效
- 使用測試腳本驗證：

```bash
cd firebase/functions
OPENAI_API_KEY="sk-proj-xxx..." node test/test-openai-quota.js
```

---

### 方案 2: 改善錯誤處理（已完成）

#### 更新內容
已更新 `firebase/functions/src/services/translationService.js`，添加詳細的錯誤分類：

**改善前**:
```javascript
const response = await this.openai.chat.completions.create({...});
// 錯誤會被包裝成 "Connection error"
```

**改善後**:
```javascript
try {
  const response = await this.openai.chat.completions.create({...});
  return { text: ..., model: ..., at: ... };
  
} catch (error) {
  // 詳細的錯誤分類
  if (error.status === 429) {
    throw new Error('OpenAI API quota exceeded. Please check billing at https://platform.openai.com/account/billing');
  } else if (error.status === 401 || error.status === 403) {
    throw new Error('OpenAI API authentication failed. Please check API key.');
  } else if (error.status === 503 || error.status === 500) {
    throw new Error('OpenAI API is temporarily unavailable. Please retry later.');
  } else if (error.code === 'ENOTFOUND') {
    throw new Error('DNS resolution failed. Check network connectivity.');
  } else if (error.code === 'ECONNREFUSED') {
    throw new Error('Connection refused. OpenAI API may be down.');
  } else if (error.code === 'ETIMEDOUT') {
    throw new Error('Request timeout. Network may be slow.');
  } else {
    throw new Error(`OpenAI API error: ${error.message}`);
  }
}
```

**優點**:
- ✅ 錯誤訊息更清晰
- ✅ 更容易診斷問題
- ✅ 提供具體的解決建議

#### 部署更新
```bash
firebase deploy --only functions
```

---

### 方案 3: 添加配額監控（建議實施）

#### 創建測試腳本
已創建 `firebase/functions/test/test-openai-quota.js`：

**功能**:
- ✅ 測試 OpenAI API 連線
- ✅ 檢查配額狀態
- ✅ 診斷錯誤類型
- ✅ 提供解決建議
- ✅ 顯示成本估算

**使用方式**:
```bash
cd firebase/functions
OPENAI_API_KEY="sk-proj-xxx..." node test/test-openai-quota.js
```

---

## 📊 成本分析

### gpt-4o-mini 定價（2025-10-17）
- **輸入**: $0.150 / 1M tokens
- **輸出**: $0.600 / 1M tokens

### 翻譯成本估算

**每則訊息**:
- 平均長度：50 字元
- 翻譯到 2 種語言（英文、日文）
- 每次翻譯約 100 tokens（輸入 + 輸出）
- **成本**: $0.0001 USD（約 0.003 台幣）

**每月成本**:
| 訊息量 | 每月成本 (USD) | 每月成本 (TWD) |
|--------|---------------|---------------|
| 100 則/天 × 30 天 = 3,000 則 | $0.30 | 約 9 台幣 |
| 500 則/天 × 30 天 = 15,000 則 | $1.50 | 約 45 台幣 |
| 1,000 則/天 × 30 天 = 30,000 則 | $3.00 | 約 90 台幣 |
| 5,000 則/天 × 30 天 = 150,000 則 | $15.00 | 約 450 台幣 |

### 建議的配額設定
```
- 初始充值: $10 USD（可支援約 100,000 則訊息）
- 自動充值: 當餘額 < $2 時充值 $10
- 每月限制: $20 USD（避免意外超支）
- 警告閾值: $15 USD（發送通知）
```

---

## 🎯 下一步行動

### 立即執行（今天）✅

1. **充值 OpenAI 帳戶**
   - 前往 https://platform.openai.com/account/billing
   - 充值 $10 USD
   - 設定自動充值

2. **測試配額恢復**
   ```bash
   cd firebase/functions
   OPENAI_API_KEY="sk-proj-xxx..." node test/test-openai-quota.js
   ```

3. **部署改善的錯誤處理**
   ```bash
   firebase deploy --only functions
   ```

4. **測試翻譯功能**
   - 在 Flutter App 中發送測試訊息
   - 檢查翻譯是否成功
   - 查看 Cloud Functions 日誌

### 短期優化（本週）📅

5. **設定成本警報**
   - 在 OpenAI Platform 設定使用限制
   - 啟用郵件通知

6. **監控翻譯使用量**
   - 定期檢查 OpenAI Usage 頁面
   - 分析翻譯成本趨勢

7. **優化成本控制**
   - 檢查快取機制是否有效
   - 考慮調整翻譯策略（如只翻譯重要訊息）

### 長期維護（未來）📆

8. **定期檢查配額**
   - 每週檢查 API 使用量
   - 每月檢查帳單

9. **優化翻譯邏輯**
   - 實施更智能的快取策略
   - 考慮批次翻譯優化

10. **考慮替代方案**
    - 如果成本過高，考慮其他翻譯 API
    - 評估自建翻譯模型的可行性

---

## 📚 相關文檔

- [OpenAI 配額排查指南](./openai-quota-troubleshooting.md)
- [Secret Manager 遷移指南](./secret-manager-migration-guide.md)
- [翻譯功能架構](./chat-translate-architecture.md)
- [部署後檢查清單](./secret-manager-post-deployment-checklist.md)

---

## 📞 支援資源

- **OpenAI Platform**: https://platform.openai.com/
- **OpenAI Billing**: https://platform.openai.com/account/billing
- **OpenAI API 文檔**: https://platform.openai.com/docs/guides/error-codes
- **OpenAI 狀態頁面**: https://status.openai.com/
- **定價資訊**: https://openai.com/api/pricing/

---

**報告創建時間**: 2025-10-17  
**最後更新**: 2025-10-17  
**下次檢查**: 配額充值後

