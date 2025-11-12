# OpenAI API 配額問題排查指南

**問題**: Cloud Functions 翻譯失敗，錯誤訊息為 "Connection error"  
**根本原因**: OpenAI API 配額已用盡（HTTP 429 錯誤）  
**發現日期**: 2025-10-17

---

## 🔍 問題診斷

### 錯誤症狀

**Firestore 中的錯誤訊息**:
```json
{
  "translations": {
    "en": {
      "error": "Translation failed after 3 attempts: Connection error."
    }
  }
}
```

**Cloud Functions 日誌**:
```
[Translation] Attempt 1 failed: Connection error.
[Translation] Retrying in 1000ms...
[Translation] Attempt 2 failed: Connection error.
[Translation] Retrying in 2000ms...
[Translation] Attempt 3 failed: Connection error.
```

**實際錯誤**（通過本地測試發現）:
```
❌ OpenAI API error: 429 You exceeded your current quota, 
please check your plan and billing details.
```

### 為什麼錯誤訊息不準確？

OpenAI Node.js SDK 將 HTTP 429 錯誤包裝成了通用的 "Connection error"，導致難以診斷。

---

## ✅ 解決方案

### 方案 1: 檢查並充值 OpenAI 帳戶（推薦）

#### 步驟 1: 檢查 OpenAI 帳戶狀態

1. 登入 OpenAI Platform: https://platform.openai.com/
2. 進入 **Settings** > **Billing** > **Usage**
3. 檢查：
   - ✅ 當前配額使用情況
   - ✅ 帳單狀態（是否有未付款項）
   - ✅ 付款方式是否有效
   - ✅ 使用限制（Usage limits）

#### 步驟 2: 充值或升級方案

**免費方案限制**:
- 每月 $5 USD 免費額度（新帳戶前 3 個月）
- 額度用完後無法繼續使用

**付費方案**:
1. 進入 **Settings** > **Billing** > **Payment methods**
2. 添加信用卡或其他付款方式
3. 設定自動充值（建議設定 $10-$20 USD）
4. 設定使用限制（避免意外超支）

**建議配置**:
```
- 自動充值: $10 USD（當餘額低於 $2 時）
- 每月限制: $50 USD（根據實際需求調整）
- 通知設定: 啟用餘額低於 $5 時發送郵件
```

#### 步驟 3: 等待配額恢復

- 充值後通常 **5-10 分鐘**內生效
- 可以通過以下指令測試：

```bash
cd firebase/functions
node -e "
const OpenAI = require('openai');
const apiKey = 'YOUR_API_KEY';
const client = new OpenAI({ apiKey });
client.chat.completions.create({
  model: 'gpt-4o-mini',
  messages: [{ role: 'user', content: 'test' }],
  max_tokens: 10
})
.then(() => console.log('✅ OpenAI API 配額已恢復'))
.catch(e => console.error('❌ 仍然有問題:', e.message));
"
```

---

### 方案 2: 更新錯誤處理邏輯（改善診斷）

為了避免未來再次遇到誤導性的錯誤訊息，我們可以改善錯誤處理：

#### 更新 `translationService.js`

在 `translateWithOpenAI` 方法中添加更詳細的錯誤處理：

```javascript
async translateWithOpenAI(text, sourceLang, targetLang) {
  try {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [...],
      max_tokens: this.maxTokens,
      temperature: this.temperature,
    });
    
    return {
      text: response.choices[0].message.content.trim(),
      model: this.model,
      at: admin.firestore.Timestamp.now(),
    };
  } catch (error) {
    // 詳細的錯誤分類
    if (error.status === 429) {
      throw new Error('OpenAI API quota exceeded. Please check billing.');
    } else if (error.status === 401) {
      throw new Error('OpenAI API key is invalid.');
    } else if (error.status === 503) {
      throw new Error('OpenAI API is temporarily unavailable.');
    } else if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
      throw new Error('Network connection error.');
    } else {
      throw new Error(`OpenAI API error: ${error.message}`);
    }
  }
}
```

---

### 方案 3: 使用替代 API 金鑰（臨時方案）

如果需要立即恢復服務，可以：

1. 創建新的 OpenAI 帳戶（獲得新的免費額度）
2. 生成新的 API 金鑰
3. 更新 Secret Manager：

```bash
# 更新 Secret（創建新版本）
echo "新的API金鑰" | firebase functions:secrets:set OPENAI_API_KEY

# 重新部署 Functions
firebase deploy --only functions
```

**注意**: 這只是臨時方案，建議還是充值主帳戶。

---

## 🔧 改善錯誤處理（建議實施）

### 目標
讓錯誤訊息更清晰，方便未來診斷。

### 實施步驟

#### 1. 更新 `translationService.js`

添加詳細的錯誤分類和日誌：

```javascript
async translateWithOpenAI(text, sourceLang, targetLang) {
  const startTime = Date.now();
  
  try {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: 'system',
          content: 'You are a professional translator.',
        },
        {
          role: 'user',
          content: `Translate from ${sourceLang} to ${targetLang}: ${text}`,
        },
      ],
      max_tokens: this.maxTokens,
      temperature: this.temperature,
    });

    const duration = Date.now() - startTime;
    console.log(`[Translation] Success: ${targetLang} in ${duration}ms`);
    
    return {
      text: response.choices[0].message.content.trim(),
      model: this.model,
      at: admin.firestore.Timestamp.now(),
    };
    
  } catch (error) {
    const duration = Date.now() - startTime;
    
    // 詳細的錯誤日誌
    console.error(`[Translation] Error after ${duration}ms:`, {
      status: error.status,
      code: error.code,
      message: error.message,
      type: error.type,
    });
    
    // 分類錯誤並提供清晰的訊息
    let errorMessage = 'Unknown error';
    
    if (error.status === 429) {
      errorMessage = 'OpenAI API quota exceeded. Please check billing at https://platform.openai.com/account/billing';
    } else if (error.status === 401 || error.status === 403) {
      errorMessage = 'OpenAI API authentication failed. Please check API key.';
    } else if (error.status === 503 || error.status === 500) {
      errorMessage = 'OpenAI API is temporarily unavailable. Please retry later.';
    } else if (error.code === 'ENOTFOUND') {
      errorMessage = 'DNS resolution failed. Check network connectivity.';
    } else if (error.code === 'ECONNREFUSED') {
      errorMessage = 'Connection refused. OpenAI API may be down.';
    } else if (error.code === 'ETIMEDOUT') {
      errorMessage = 'Request timeout. Network may be slow.';
    } else {
      errorMessage = `OpenAI API error: ${error.message}`;
    }
    
    throw new Error(errorMessage);
  }
}
```

#### 2. 添加配額監控

在 `index.js` 中添加配額使用監控：

```javascript
exports.onMessageCreate = onDocumentCreated({
  document: 'chat_rooms/{roomId}/messages/{messageId}',
  region: 'asia-east1',
  secrets: [openaiApiKey],
}, async (event) => {
  try {
    // ... 翻譯邏輯
    
  } catch (error) {
    console.error('[onMessageCreate] Translation failed:', error.message);
    
    // 如果是配額問題，發送通知（可選）
    if (error.message.includes('quota exceeded')) {
      // 發送郵件或 Slack 通知給管理員
      console.error('⚠️ URGENT: OpenAI API quota exceeded! Please check billing.');
    }
    
    // 不要拋出錯誤，避免阻塞聊天功能
  }
});
```

---

## 📊 成本估算與監控

### gpt-4o-mini 定價（2025-10-17）

- **輸入**: $0.150 / 1M tokens
- **輸出**: $0.600 / 1M tokens

### 翻譯成本估算

假設每則訊息：
- 平均長度：50 字元
- 翻譯到 2 種語言（英文、日文）
- 每次翻譯約 100 tokens（輸入 + 輸出）

**每則訊息成本**:
```
100 tokens × 2 語言 × $0.375 / 1M tokens = $0.000075 USD
≈ 每則訊息 $0.0001 USD（0.01 台幣）
```

**每月成本估算**:
```
- 100 則訊息/天 × 30 天 = 3,000 則/月
- 成本: 3,000 × $0.0001 = $0.30 USD/月（約 9 台幣）

- 1,000 則訊息/天 × 30 天 = 30,000 則/月
- 成本: 30,000 × $0.0001 = $3.00 USD/月（約 90 台幣）
```

### 建議的配額設定

```
- 初始充值: $10 USD
- 自動充值閾值: $2 USD
- 每月限制: $20 USD（約 200,000 則訊息）
- 警告閾值: $15 USD
```

---

## 🧪 測試配額恢復

### 本地測試腳本

```bash
cd firebase/functions

# 測試 OpenAI API 連線
node -e "
const OpenAI = require('openai');
const apiKey = process.env.OPENAI_API_KEY || 'YOUR_API_KEY';
const client = new OpenAI({ apiKey });

console.log('🧪 Testing OpenAI API...');

client.chat.completions.create({
  model: 'gpt-4o-mini',
  messages: [{ role: 'user', content: 'Translate to English: 你好' }],
  max_tokens: 50
})
.then(response => {
  console.log('✅ OpenAI API is working!');
  console.log('Translation:', response.choices[0].message.content);
  console.log('Tokens used:', response.usage.total_tokens);
})
.catch(error => {
  console.error('❌ OpenAI API error:');
  console.error('Status:', error.status);
  console.error('Message:', error.message);
  
  if (error.status === 429) {
    console.error('');
    console.error('⚠️  配額已用盡！請執行以下步驟：');
    console.error('1. 前往 https://platform.openai.com/account/billing');
    console.error('2. 檢查帳單狀態並充值');
    console.error('3. 等待 5-10 分鐘後重試');
  }
});
"
```

### 部署後測試

```bash
# 1. 重新部署 Functions（如果有更新錯誤處理）
firebase deploy --only functions

# 2. 在 Flutter App 中發送測試訊息

# 3. 查看日誌
firebase functions:log --only onMessageCreate

# 4. 檢查 Firestore 數據
# 前往 Firebase Console > Firestore Database
# 查看 chat_rooms/{roomId}/messages/{messageId}
# 確認 translations 欄位有正確的翻譯結果
```

---

## 📞 相關資源

- **OpenAI Platform**: https://platform.openai.com/
- **OpenAI Billing**: https://platform.openai.com/account/billing
- **OpenAI API 文檔**: https://platform.openai.com/docs/guides/error-codes
- **定價資訊**: https://openai.com/api/pricing/

---

## 🎯 下一步行動

### 立即執行（今天）

1. ✅ 登入 OpenAI Platform 檢查帳單狀態
2. ✅ 充值帳戶（建議 $10 USD）
3. ✅ 設定自動充值和使用限制
4. ✅ 等待 5-10 分鐘後測試

### 短期優化（本週）

5. ✅ 更新錯誤處理邏輯（改善診斷）
6. ✅ 添加配額監控和警告
7. ✅ 設定成本警報（當使用超過 $15 時通知）

### 長期維護（未來）

8. ✅ 定期檢查 API 使用量
9. ✅ 根據實際使用調整配額限制
10. ✅ 考慮實施更多成本控制策略（如快取優化）

---

**文檔創建時間**: 2025-10-17  
**最後更新**: 2025-10-17

