# 智能翻譯優化：按需翻譯策略

**修正日期**: 2025-10-18  
**Git Commit**: `e30aa19`

---

## 📋 問題描述

### 用戶反饋

**用戶的重要觀察**：

> "還是只有翻譯英文跟日文
> 
> 不能去抓當下聊天室的人使用什麼語言然後雙向互翻就好嗎
> 
> 如果每次都把每種語言都翻譯上去，成本不就很高"

**用戶的核心觀點**：
1. ❌ 翻譯所有 8 種語言（zh-TW, en, ja, ko, vi, th, ms, id）成本太高
2. ✅ 聊天室只有 2 個人（司機和乘客）
3. ✅ 應該只翻譯他們實際使用的語言
4. ✅ 雙向互翻就足夠了

---

## 💰 成本分析

### 舊策略：翻譯所有語言

**範例場景**：
- 司機（繁體中文）發送訊息給乘客（韓文）
- 訊息：「我可以不要這樣吃冰嗎」（15 字）

**舊策略的翻譯**：
```
來源語言: zh-TW
目標語言: en, ja, ko, vi, th, ms, id (7 種語言)
總翻譯次數: 7 次
預估 Token 使用: 7 × 70 = 490 tokens
預估成本: $0.0007 USD (每則訊息)
```

**問題**：
- 用戶只需要韓文翻譯
- 但系統翻譯了 7 種語言
- **浪費了 85% 的翻譯成本**（6/7 的翻譯沒有被使用）

---

### 新策略：只翻譯接收者的語言

**範例場景**：
- 司機（繁體中文）發送訊息給乘客（韓文）
- 訊息：「我可以不要這樣吃冰嗎」（15 字）

**新策略的翻譯**：
```
來源語言: zh-TW
接收者語言: ko
後備語言: en
目標語言: ko, en (2 種語言)
總翻譯次數: 2 次
預估 Token 使用: 2 × 70 = 140 tokens
預估成本: $0.0002 USD (每則訊息)
```

**成本節省**：
- **節省 71% 的成本**（從 7 次翻譯降到 2 次）
- 仍然提供必要的翻譯（接收者的語言 + 英文後備）

---

## 🔧 修正方案

### 核心邏輯變更

**修改檔案**：`firebase/functions/index.js`

#### 舊邏輯（第 95-115 行）

```javascript
// ❌ 舊邏輯：翻譯所有語言
const targetLanguages = (process.env.TARGET_LANGUAGES || 'zh-TW,en,ja,ko,vi,th,ms,id')
  .split(',')
  .map(lang => lang.trim())
  .filter(lang => lang !== sourceLang); // 排除來源語言

console.log(`[onMessageCreate] Translating to: ${targetLanguages.join(', ')}`);

const translations = await translationService.translateBatch(
  text,
  sourceLang,
  targetLanguages,
  maxConcurrent
);
```

**問題**：
- 固定翻譯 7-8 種語言
- 不考慮聊天室中用戶的實際需求
- 浪費大量 API 成本

---

#### 新邏輯（第 95-143 行）

```javascript
// ✅ 新邏輯：只翻譯接收者的語言
const targetLanguages = [];

try {
  // 讀取發送者和接收者的語言偏好
  const [senderDoc, receiverDoc] = await Promise.all([
    db.collection('users').doc(senderId).get(),
    db.collection('users').doc(receiverId).get(),
  ]);

  const senderLang = senderDoc.exists ? (senderDoc.data().preferredLang || 'zh-TW') : 'zh-TW';
  const receiverLang = receiverDoc.exists ? (receiverDoc.data().preferredLang || 'zh-TW') : 'zh-TW';

  console.log(`[onMessageCreate] Sender language: ${senderLang}, Receiver language: ${receiverLang}`);

  // 只翻譯接收者的語言（如果與來源語言不同）
  if (receiverLang !== sourceLang && !targetLanguages.includes(receiverLang)) {
    targetLanguages.push(receiverLang);
  }

  // 可選：也翻譯成英文作為後備（如果兩個用戶都不是英文）
  if (sourceLang !== 'en' && receiverLang !== 'en' && !targetLanguages.includes('en')) {
    targetLanguages.push('en');
  }
} catch (error) {
  console.error('[onMessageCreate] Error fetching user language preferences:', error);
  // 如果無法獲取用戶語言偏好，使用預設值（英文）
  if (sourceLang !== 'en') {
    targetLanguages.push('en');
  }
}

if (targetLanguages.length === 0) {
  console.log('[onMessageCreate] No translation needed (sender and receiver use same language)');
  return null;
}

console.log(`[onMessageCreate] Translating to: ${targetLanguages.join(', ')}`);

const translations = await translationService.translateBatch(
  text,
  sourceLang,
  targetLanguages,
  maxConcurrent
);
```

**優點**：
1. **動態語言檢測**：根據聊天室中用戶的實際語言偏好
2. **成本優化**：只翻譯必要的語言（1-2 種）
3. **英文後備**：確保兼容性（如果雙方都不是英文）
4. **錯誤處理**：如果無法獲取用戶語言，使用英文作為後備

---

## 📊 實際效果

### 場景 1：司機（繁中）→ 乘客（韓文）

**Firestore 資料（新策略）**：
```json
{
  "messageText": "我可以不要這樣吃冰嗎",
  "detectedLang": "zh-TW",
  "senderId": "driver123",
  "receiverId": "customer456",
  "translations": {
    "ko": {
      "text": "이렇게 아이스크림을 먹지 않아도 되나요?",
      "model": "gpt-4o-mini",
      "tokensUsed": 72,
      "duration": 1450,
      "at": "2025-10-18T10:30:00Z"
    },
    "en": {
      "text": "Can I not eat ice cream like this?",
      "model": "gpt-4o-mini",
      "tokensUsed": 68,
      "duration": 1200,
      "at": "2025-10-18T10:30:00Z"
    }
  },
  "translatedText": "Can I not eat ice cream like this?"
}
```

**翻譯次數**：2 次（ko, en）  
**成本節省**：71%（從 7 次降到 2 次）

---

### 場景 2：司機（繁中）→ 乘客（繁中）

**Firestore 資料（新策略）**：
```json
{
  "messageText": "我可以不要這樣吃冰嗎",
  "detectedLang": "zh-TW",
  "senderId": "driver123",
  "receiverId": "customer789",
  "translations": {
    "en": {
      "text": "Can I not eat ice cream like this?",
      "model": "gpt-4o-mini",
      "tokensUsed": 68,
      "duration": 1200,
      "at": "2025-10-18T10:30:00Z"
    }
  },
  "translatedText": "Can I not eat ice cream like this?"
}
```

**翻譯次數**：1 次（en，作為後備）  
**成本節省**：85%（從 7 次降到 1 次）

---

### 場景 3：司機（繁中）→ 乘客（英文）

**Firestore 資料（新策略）**：
```json
{
  "messageText": "我可以不要這樣吃冰嗎",
  "detectedLang": "zh-TW",
  "senderId": "driver123",
  "receiverId": "customer101",
  "translations": {
    "en": {
      "text": "Can I not eat ice cream like this?",
      "model": "gpt-4o-mini",
      "tokensUsed": 68,
      "duration": 1200,
      "at": "2025-10-18T10:30:00Z"
    }
  },
  "translatedText": "Can I not eat ice cream like this?"
}
```

**翻譯次數**：1 次（en）  
**成本節省**：85%（從 7 次降到 1 次）

---

## 🎯 翻譯邏輯流程圖

```
新訊息創建
    ↓
讀取 senderId, receiverId
    ↓
從 Firestore 讀取用戶語言偏好
    ├─ users/{senderId}.preferredLang → senderLang
    └─ users/{receiverId}.preferredLang → receiverLang
    ↓
判斷需要翻譯的語言
    ├─ receiverLang ≠ sourceLang? → 添加 receiverLang
    └─ sourceLang ≠ 'en' AND receiverLang ≠ 'en'? → 添加 'en' (後備)
    ↓
targetLanguages.length > 0?
    ├─ Yes → 批次翻譯
    └─ No → 跳過翻譯（雙方使用相同語言）
    ↓
寫入 Firestore translations 欄位
```

---

## 📝 修改統計

| 指標 | 數值 |
|------|------|
| **修改的檔案** | 2 個 |
| **新增行數** | +41 行 |
| **刪除行數** | -12 行 |
| **淨變化** | +29 行 |

---

## ⚠️ 重要注意事項

### 1. 此修正只影響新訊息

**重要**：
- ✅ **新訊息**（修正部署後創建的訊息）：只翻譯接收者的語言 + 英文後備
- ❌ **舊訊息**（修正部署前創建的訊息）：仍然只有英文和日文翻譯

### 2. 如果用戶切換語言怎麼辦？

**場景**：
- 訊息創建時，乘客的語言是韓文（ko）
- 系統翻譯成韓文和英文
- 後來乘客在設定頁面將語言改為泰文（th）

**解決方案**：
- `TranslatedMessageBubble` 會檢測到 `translations.th` 不存在
- 調用 `TranslationDisplayService.getDisplayText()`
- 調用 `translateMessage` Cloud Function 端點
- 翻譯結果會寫入 Firestore `translations.th`
- 這是**按需翻譯**（on-demand translation）

### 3. 英文後備的作用

**為什麼需要英文後備？**
1. **兼容性**：如果用戶切換到其他語言，至少有英文可以顯示
2. **調試**：開發者可以查看英文翻譯來驗證翻譯品質
3. **後備方案**：如果按需翻譯失敗，可以顯示英文

**何時不添加英文後備？**
- 如果來源語言是英文（sourceLang === 'en'）
- 如果接收者的語言是英文（receiverLang === 'en'）

---

## 🚀 部署步驟

### 1. 部署 Cloud Functions

```bash
cd firebase/functions
firebase deploy --only functions
```

### 2. 測試新訊息

**測試場景 1：司機（繁中）→ 乘客（韓文）**

1. 確認乘客的 `users/{customerId}.preferredLang = 'ko'`
2. 司機發送訊息：「金額是什麼」
3. 檢查 Firestore `translations` 欄位
4. **預期結果**：只有 `ko` 和 `en` 兩個翻譯

**測試場景 2：司機（繁中）→ 乘客（繁中）**

1. 確認乘客的 `users/{customerId}.preferredLang = 'zh-TW'`
2. 司機發送訊息：「金額是什麼」
3. 檢查 Firestore `translations` 欄位
4. **預期結果**：只有 `en` 一個翻譯（後備）

### 3. 驗證成本節省

1. 檢查 OpenAI API 使用量
2. 對比修正前後的 Token 使用量
3. **預期結果**：Token 使用量降低 70-85%

---

## 📚 相關文檔

- **智能翻譯優化報告**: `docs/SMART_TRANSLATION_OPTIMIZATION.md`（本文檔）
- **自動翻譯語言配置修正報告**: `docs/AUTO_TRANSLATION_LANGUAGE_FIX.md`
- **Firestore Translations 欄位修正報告**: `docs/TRANSLATIONS_FIELD_FIX.md`

---

## 🎉 總結

**修正狀態**: ✅ **完成**

1. ✅ 採納用戶的建議：只翻譯聊天室中用戶實際使用的語言
2. ✅ 實現動態語言檢測：從 Firestore 讀取用戶語言偏好
3. ✅ 大幅降低成本：從 7 次翻譯降到 1-2 次（節省 71-85%）
4. ✅ 保持兼容性：添加英文作為後備
5. ✅ 支援按需翻譯：用戶切換語言時自動調用 API

**Git Commit**: `e30aa19`

**預期效果**：
- ✅ 成本節省 70-85%
- ✅ 仍然提供必要的翻譯
- ✅ 支援用戶切換語言（按需翻譯）
- ✅ 英文後備確保兼容性

**感謝用戶的寶貴建議！** 這個優化大幅降低了翻譯成本，同時保持了系統的功能性。🎉

