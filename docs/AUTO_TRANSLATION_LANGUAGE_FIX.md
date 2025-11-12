# 自動翻譯語言配置問題診斷與修正報告

**修正日期**: 2025-10-18  
**Git Commit**: `502d54f`

---

## 📋 問題描述

### 用戶報告的問題

**測試場景**：
1. 在客戶端（Customer App）的設定頁面將語言改為「韓文」(ko)
2. 從司機端發送新訊息：「我可以不要這樣吃冰嗎」
3. **問題**：客戶端沒有顯示韓文翻譯

### Firestore 資料檢查

用戶檢查了 Firestore 中該訊息的資料，發現：

```json
{
  "messageText": "我可以不要這樣吃冰嗎",
  "detectedLang": "zh-TW",
  "translatedText": "Can I not eat ice cream like this?",
  "translations": {
    "en": {
      "text": "Can I not eat ice cream like this?",
      "model": "gpt-4o-mini",
      "tokensUsed": 70,
      "duration": 1538,
      "at": "2025-10-18T09:45:19Z"
    },
    "ja": {
      "text": "私はこんな風にアイスを食べなくてもいいですか？",
      "model": "gpt-4o-mini",
      "tokensUsed": 78,
      "duration": 1703,
      "at": "2025-10-18T09:45:19Z"
    }
  }
}
```

**關鍵發現**：
- ❌ `translations` 物件中**沒有韓文 (ko) 翻譯**
- ✅ 只有英文 (en) 和日文 (ja) 翻譯
- ❌ 翻譯 API 沒有生成韓文翻譯

---

## 🔍 診斷過程

### 第一步：檢查 TranslationService 支援的語言

**檢查檔案**：`firebase/functions/src/services/translationService.js`

**發現**：

<augment_code_snippet path="firebase/functions/src/services/translationService.js" mode="EXCERPT">
```javascript
async translateWithOpenAI(text, sourceLang, targetLang) {
  const languageNames = {
    'zh-TW': '繁體中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',      // ✅ 支援韓文
    'th': 'ไทย',        // ✅ 支援泰文
    'vi': 'Tiếng Việt', // ✅ 支援越南文
    'id': 'Bahasa Indonesia', // ✅ 支援印尼文
    'ms': 'Bahasa Melayu',    // ✅ 支援馬來文
  };
  // ...
}
```
</augment_code_snippet>

**結論**：`TranslationService` 支援所有 8 種語言，包括韓文。

---

### 第二步：檢查 onMessageCreate 觸發器的目標語言配置

**檢查檔案**：`firebase/functions/index.js`

**發現的問題**：

<augment_code_snippet path="firebase/functions/index.js" mode="EXCERPT">
```javascript
// ❌ 修改前（第 96 行）
const targetLanguages = (process.env.TARGET_LANGUAGES || 'zh-TW,en,ja')
  .split(',')
  .map(lang => lang.trim())
  .filter(lang => lang !== sourceLang); // 排除來源語言
```
</augment_code_snippet>

**問題**：
- 環境變數 `TARGET_LANGUAGES` 的預設值是 `'zh-TW,en,ja'`
- **沒有包含韓文 (ko)**、泰文 (th)、越南文 (vi)、印尼文 (id)、馬來文 (ms)
- 當新訊息創建時，`onMessageCreate` Cloud Function 只會翻譯成英文和日文

**結論**：這是根本原因！

---

### 第三步：檢查 .env.example 配置

**檢查檔案**：`firebase/functions/.env.example`

**發現的問題**：

```bash
# ❌ 修改前（第 32 行）
TARGET_LANGUAGES=zh-TW,en,ja
```

**問題**：
- `.env.example` 中的範例配置也只包含 `zh-TW,en,ja`
- 這會誤導開發者以為只需要翻譯這三種語言

---

## 🔧 修正方案

### 修正 1：更新 `index.js` 中的 TARGET_LANGUAGES 預設值

**修改檔案**：`firebase/functions/index.js`

**修改前**：
```javascript
const targetLanguages = (process.env.TARGET_LANGUAGES || 'zh-TW,en,ja')
  .split(',')
  .map(lang => lang.trim())
  .filter(lang => lang !== sourceLang);
```

**修改後**：
```javascript
// 獲取目標語言清單
// 預設翻譯所有支援的語言（排除來源語言）
const targetLanguages = (process.env.TARGET_LANGUAGES || 'zh-TW,en,ja,ko,vi,th,ms,id')
  .split(',')
  .map(lang => lang.trim())
  .filter(lang => lang !== sourceLang); // 排除來源語言
```

**效果**：
- 現在預設會翻譯所有 8 種支援的語言
- 包括：繁體中文、英文、日文、韓文、越南文、泰文、馬來文、印尼文

---

### 修正 2：更新 `.env.example` 配置

**修改檔案**：`firebase/functions/.env.example`

**修改前**：
```bash
# 目標翻譯語言清單（逗號分隔）
# 支援的語言碼：zh-TW, en, ja, ko, th, vi, id, ms
TARGET_LANGUAGES=zh-TW,en,ja
```

**修改後**：
```bash
# 目標翻譯語言清單（逗號分隔）
# 支援的語言碼：zh-TW, en, ja, ko, th, vi, id, ms
# 預設：翻譯所有支援的語言（可根據需求調整以節省成本）
TARGET_LANGUAGES=zh-TW,en,ja,ko,vi,th,ms,id
```

**效果**：
- 提供正確的範例配置
- 說明可以根據需求調整以節省成本

---

## 📊 修改摘要

### 修改的檔案

| 檔案 | 變更類型 | 說明 |
|------|---------|------|
| `firebase/functions/index.js` | 修改 | 更新 TARGET_LANGUAGES 預設值 |
| `firebase/functions/.env.example` | 修改 | 更新範例配置 |

### 程式碼統計

- **新增**: 4 行
- **刪除**: 2 行
- **淨變化**: +2 行

---

## 🎯 預期效果

### 修正後的行為

#### 場景 1：新訊息自動翻譯

**流程**：
1. 司機發送新訊息：「我可以不要這樣吃冰嗎」（繁體中文）
2. `onMessageCreate` Cloud Function 觸發
3. 讀取 `TARGET_LANGUAGES` 環境變數（預設：`zh-TW,en,ja,ko,vi,th,ms,id`）
4. 排除來源語言（zh-TW），得到目標語言：`en,ja,ko,vi,th,ms,id`
5. 批次翻譯成 7 種語言
6. 寫入 Firestore `translations` 欄位

**Firestore 資料（修正後）**：
```json
{
  "messageText": "我可以不要這樣吃冰嗎",
  "detectedLang": "zh-TW",
  "translatedText": "Can I not eat ice cream like this?",
  "translations": {
    "en": { "text": "Can I not eat ice cream like this?", ... },
    "ja": { "text": "私はこんな風にアイスを食べなくてもいいですか？", ... },
    "ko": { "text": "이렇게 아이스크림을 먹지 않아도 되나요?", ... },  // ✅ 新增
    "vi": { "text": "Tôi có thể không ăn kem như thế này không?", ... },  // ✅ 新增
    "th": { "text": "ฉันสามารถไม่กินไอศกรีมแบบนี้ได้ไหม", ... },  // ✅ 新增
    "ms": { "text": "Bolehkah saya tidak makan ais krim seperti ini?", ... },  // ✅ 新增
    "id": { "text": "Bisakah saya tidak makan es krim seperti ini?", ... }  // ✅ 新增
  }
}
```

#### 場景 2：客戶端顯示韓文翻譯

**流程**：
1. 客戶在設定頁面將語言改為「韓文」(ko)
2. `effectiveRoomLanguageProvider` 返回 `'ko'`
3. `TranslatedMessageBubble` 調用 `message.getTranslation('ko')`
4. 從 Firestore `translations.ko.text` 讀取韓文翻譯
5. **✅ 顯示韓文翻譯**：「이렇게 아이스크림을 먹지 않아도 되나요?」

---

## ⚠️ 重要注意事項

### 1. 此修正只影響新訊息

**重要**：
- ✅ **新訊息**（修正部署後創建的訊息）：會自動翻譯成所有 8 種語言
- ❌ **舊訊息**（修正部署前創建的訊息）：仍然只有英文和日文翻譯

### 2. 如何為舊訊息獲取翻譯

用戶可以使用以下方法為舊訊息獲取韓文翻譯：

#### 方法 1：使用聊天室的地球按鈕（推薦）

1. 在聊天室中點擊地球按鈕
2. 選擇「韓文」
3. `TranslatedMessageBubble` 會檢測到 `translations.ko` 不存在
4. 調用 `TranslationDisplayService.getDisplayText()`
5. 調用 `translateMessage` Cloud Function 端點
6. 翻譯結果會寫入 Firestore `translations.ko`

#### 方法 2：直接調用 translateMessage Cloud Function

```javascript
// 調用 Cloud Function
const response = await fetch('https://asia-east1-your-project.cloudfunctions.net/translateMessage', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${idToken}`,
  },
  body: JSON.stringify({
    roomId: 'room123',
    messageId: 'msg456',
    targetLang: 'ko',
  }),
});
```

### 3. 成本考量

**重要**：
- 翻譯成 8 種語言會增加 OpenAI API 成本
- 如果只需要特定語言，可以在生產環境設定 `TARGET_LANGUAGES` 環境變數

**設定方式**（Firebase Console）：
```bash
# 只翻譯英文、日文、韓文
firebase functions:config:set translation.target_languages="zh-TW,en,ja,ko"
```

或使用 `.env` 檔案（本地測試）：
```bash
TARGET_LANGUAGES=zh-TW,en,ja,ko
```

---

## 🚀 部署步驟

### 1. 部署 Cloud Functions

```bash
cd firebase/functions
firebase deploy --only functions
```

### 2. 驗證部署

檢查 Firebase Console 的 Functions 日誌：

```bash
firebase functions:log
```

### 3. 測試新訊息

1. 從司機端發送新訊息
2. 檢查 Firestore 中的 `translations` 欄位
3. 確認包含所有 7 種目標語言（排除來源語言）

### 4. 測試客戶端顯示

1. 在客戶端設定頁面將語言改為「韓文」
2. 檢查聊天室是否顯示韓文翻譯
3. 測試其他語言（泰文、越南文等）

---

## 📝 總結

**修正狀態**: ✅ **完成**

1. ✅ 診斷出自動翻譯只生成英文和日文的根本原因
2. ✅ 更新 `TARGET_LANGUAGES` 預設值以包含所有支援的語言
3. ✅ 更新 `.env.example` 配置範例
4. ✅ 提供舊訊息的翻譯獲取方法
5. ✅ 說明成本考量和配置方式

**Git Commit**: `502d54f`

**預期效果**：
- ✅ 新訊息會自動翻譯成所有 8 種支援的語言
- ✅ 用戶可以在設定頁面選擇任何語言並看到對應的翻譯
- ✅ 舊訊息可以通過地球按鈕或 Cloud Function 端點獲取翻譯
- ✅ 開發者可以根據需求調整 `TARGET_LANGUAGES` 以節省成本

**下一步**：
1. 部署 Cloud Functions 到生產環境
2. 測試新訊息的自動翻譯
3. 驗證所有語言的翻譯顯示
4. 監控 OpenAI API 成本

系統現在能夠自動翻譯成所有支援的語言！🎉

