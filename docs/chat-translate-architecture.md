# 聊天翻譯系統架構設計

**版本**: 1.0  
**日期**: 2025-10-17  
**狀態**: ✅ 實作完成

---

## 📋 目錄

1. [系統概述](#系統概述)
2. [架構設計](#架構設計)
3. [資料模型](#資料模型)
4. [功能實作](#功能實作)
5. [成本控制策略](#成本控制策略)
6. [安全設計](#安全設計)
7. [部署與維運](#部署與維運)
8. [未來擴展](#未來擴展)

---

## 系統概述

### 目標

為 Firestore 聊天系統加入 AI 翻譯功能，支援多語言即時翻譯，提升跨語言溝通體驗。

### 核心需求

- ✅ 自動翻譯：新訊息創建時自動翻譯
- ✅ 按需翻譯：用戶點擊「翻譯」按鈕時翻譯
- ✅ 多語言支援：支援 8+ 種語言
- ✅ 成本控制：避免不必要的 API 呼叫
- ✅ 安全性：API 金鑰僅存於伺服端

### 技術棧

- **AI 平台**: OpenAI (gpt-4o-mini)
- **後端**: Firebase Cloud Functions (Node.js 18)
- **資料庫**: Firestore
- **認證**: Firebase Authentication
- **前端**: Flutter (Mobile App)

---

## 架構設計

### 整體架構圖

```
┌─────────────────────────────────────────────────────────────┐
│                         客戶端 (Flutter)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ 聊天室列表   │  │ 聊天詳情頁   │  │ 訊息氣泡     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                            ▼                                 │
│                   Firestore 即時監聽                         │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      Firestore Database                      │
│                                                               │
│  chat_rooms/{roomId}/messages/{messageId}                   │
│  ├── messageText: string (原文)                              │
│  ├── lang: string (語言碼)                                   │
│  ├── senderId: string                                        │
│  ├── createdAt: Timestamp                                    │
│  └── translations: map                                       │
│      ├── zh-TW: {text, model, at, tokensUsed}               │
│      ├── en: {text, model, at, tokensUsed}                  │
│      └── ja: {text, model, at, tokensUsed}                  │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                  Firebase Cloud Functions                    │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  onMessageCreate (onCreate 觸發器)                     │  │
│  │  ├── 監聽新訊息創建                                    │  │
│  │  ├── 檢查自動翻譯開關                                  │  │
│  │  ├── 批次翻譯到目標語言                                │  │
│  │  └── 寫回 translations 欄位                            │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  translateMessage (HTTPS 端點)                         │  │
│  │  ├── 驗證 Firebase ID Token                            │  │
│  │  ├── 檢查聊天室成員權限                                │  │
│  │  ├── 翻譯特定語言                                      │  │
│  │  └── 寫回 translations.{lang}                          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      OpenAI API                              │
│                   (gpt-4o-mini)                              │
└─────────────────────────────────────────────────────────────┘
```

### 資料流

#### 流程 1: 自動翻譯（onCreate）

```
1. 用戶 A 發送訊息 "Hello" (lang: en)
   ↓
2. Flutter App 寫入 Firestore
   chat_rooms/{roomId}/messages/{messageId}
   {
     messageText: "Hello",
     lang: "en",
     senderId: "user_a_uid",
     createdAt: Timestamp
   }
   ↓
3. Firestore onCreate 觸發 Cloud Function
   ↓
4. onMessageCreate Function:
   - 檢查 ENABLE_AUTO_TRANSLATE = true
   - 檢查訊息長度 <= 500 字元
   - 讀取 TARGET_LANGUAGES = ["zh-TW", "ja"]
   - 排除來源語言 "en"
   ↓
5. 批次翻譯:
   - 翻譯到 zh-TW: "你好"
   - 翻譯到 ja: "こんにちは"
   ↓
6. 寫回 Firestore:
   {
     ...原有欄位,
     translations: {
       "zh-TW": {text: "你好", model: "gpt-4o-mini", at: Timestamp},
       "ja": {text: "こんにちは", model: "gpt-4o-mini", at: Timestamp}
     },
     translatedAt: Timestamp
   }
   ↓
7. Flutter App 即時監聽到更新，顯示翻譯
```

#### 流程 2: 按需翻譯（HTTPS）

```
1. 用戶 B 點擊「翻譯為韓文」按鈕
   ↓
2. Flutter App 呼叫 HTTPS 端點
   POST /translateMessage
   Headers: {Authorization: "Bearer {idToken}"}
   Body: {
     roomId: "room_123",
     messageId: "msg_456",
     targetLang: "ko"
   }
   ↓
3. translateMessage Function:
   - 驗證 ID Token
   - 檢查用戶是否為聊天室成員
   - 檢查是否已有 translations.ko
   ↓
4. 翻譯到韓文: "안녕하세요"
   ↓
5. 寫回 Firestore:
   {
     ...原有欄位,
     translations: {
       ...已有翻譯,
       "ko": {text: "안녕하세요", model: "gpt-4o-mini", at: Timestamp}
     }
   }
   ↓
6. 回傳結果給 Flutter App
   {
     success: true,
     translation: {text: "안녕하세요", ...}
   }
   ↓
7. Flutter App 顯示翻譯
```

---

## 資料模型

### Firestore 訊息結構

```typescript
interface ChatMessage {
  // 基本欄位
  id: string;                    // 訊息 ID
  senderId: string;              // 發送者 Firebase UID
  receiverId: string;            // 接收者 Firebase UID
  senderName?: string;           // 發送者姓名
  receiverName?: string;         // 接收者姓名
  
  // 訊息內容
  messageText: string;           // 原文
  lang: string;                  // 語言碼 (ISO 639-1)
  
  // 翻譯結果
  translations?: {
    [langCode: string]: {
      text: string;              // 翻譯文字
      model: string;             // 使用的模型 (e.g., "gpt-4o-mini")
      at: Timestamp;             // 翻譯時間
      tokensUsed?: number;       // Token 使用量
      duration?: number;         // 翻譯耗時 (ms)
    }
  };
  
  // 時間戳記
  createdAt: Timestamp;          // 發送時間
  readAt?: Timestamp;            // 已讀時間
  translatedAt?: Timestamp;      // 最後翻譯時間
  
  // 錯誤處理
  translationError?: {
    message: string;
    at: Timestamp;
  };
}
```

### 範例資料

```json
{
  "id": "msg_abc123",
  "senderId": "user_a_uid",
  "receiverId": "user_b_uid",
  "senderName": "Alice",
  "receiverName": "Bob",
  "messageText": "Hello, how are you?",
  "lang": "en",
  "translations": {
    "zh-TW": {
      "text": "你好，你好嗎？",
      "model": "gpt-4o-mini",
      "at": "2025-10-17T10:30:00Z",
      "tokensUsed": 25,
      "duration": 1200
    },
    "ja": {
      "text": "こんにちは、お元気ですか？",
      "model": "gpt-4o-mini",
      "at": "2025-10-17T10:30:01Z",
      "tokensUsed": 28,
      "duration": 1350
    }
  },
  "createdAt": "2025-10-17T10:29:58Z",
  "translatedAt": "2025-10-17T10:30:01Z"
}
```

---

## 功能實作

### 1. 自動翻譯 (onMessageCreate)

**觸發條件**:
- Firestore onCreate 事件
- `ENABLE_AUTO_TRANSLATE=true`
- 訊息長度 <= `MAX_AUTO_TRANSLATE_LENGTH`
- 尚未有翻譯結果（冪等性）

**處理流程**:
1. 讀取訊息內容和語言
2. 獲取目標語言清單
3. 排除來源語言
4. 批次翻譯（併發控制）
5. 寫回 Firestore

**錯誤處理**:
- OpenAI API 失敗：指數退避重試（最多 2 次）
- 重試失敗：記錄錯誤到 `translationError` 欄位
- 不拋出異常，避免無限重試

### 2. 按需翻譯 (translateMessage)

**端點**: `POST /translateMessage`

**認證**: Firebase ID Token (Bearer)

**請求體**:
```json
{
  "roomId": "string",
  "messageId": "string",
  "targetLang": "string"
}
```

**回應**:
```json
{
  "success": true,
  "translation": {
    "text": "string",
    "model": "string",
    "at": "timestamp"
  },
  "cached": false
}
```

**權限檢查**:
1. 驗證 ID Token
2. 檢查用戶是否為聊天室成員 (customerId 或 driverId)
3. 拒絕非成員請求 (403 Forbidden)

---

## 成本控制策略

### 1. 長訊息截斷

```javascript
// 超過 500 字元不自動翻譯
if (text.length > MAX_AUTO_TRANSLATE_LENGTH) {
  console.log('Message too long, skipping auto-translate');
  return null;
}
```

**效果**: 避免翻譯長文消耗大量 Token

### 2. 去重與快取

```javascript
// 記憶體快取（10 分鐘 TTL）
const cacheKey = `${text.substring(0, 50)}_${targetLang}`;
const cached = cache.get(cacheKey);
if (cached && Date.now() - cached.timestamp < 600000) {
  return cached.data;
}
```

**效果**: 相同文字 10 分鐘內不重複翻譯

### 3. 語言自動偵測

```javascript
// 來源語言 == 目標語言，跳過翻譯
if (sourceLang === targetLang) {
  return null;
}
```

**效果**: 避免無意義的翻譯請求

### 4. 併發控制

```javascript
// 單訊息最多同時 2 個語言翻譯
const maxConcurrent = 2;
await translateBatch(text, sourceLang, targetLangs, maxConcurrent);
```

**效果**: 避免瞬間大量 API 請求

### 5. 冪等性檢查

```javascript
// 已有翻譯結果，跳過
if (messageData.translations && Object.keys(messageData.translations).length > 0) {
  return null;
}
```

**效果**: 避免重複翻譯

### 6. 錯誤重試

```javascript
// 指數退避重試（最多 2 次）
for (let attempt = 0; attempt <= maxRetries; attempt++) {
  try {
    return await translateWithOpenAI(...);
  } catch (error) {
    if (attempt < maxRetries) {
      await sleep(retryDelay * Math.pow(2, attempt));
    }
  }
}
```

**效果**: 提高成功率，但避免無限重試

---

## 安全設計

### 1. API 金鑰保護

- ✅ 金鑰僅存於 Firebase Functions 環境變數
- ✅ 不下發到客戶端
- ✅ 使用 Firebase Functions Config 管理
- ⚠️ 未來應實作金鑰加密儲存

### 2. Firestore 規則

```javascript
// 客戶端可創建訊息，但不能更新
allow create: if request.auth != null && 
  request.resource.data.senderId == request.auth.uid;

allow update: if false; // 禁止客戶端更新

// Cloud Functions 使用 Admin SDK，不受規則限制
```

### 3. HTTPS 端點認證

```javascript
// 驗證 Firebase ID Token
const idToken = req.headers.authorization.split('Bearer ')[1];
const decodedToken = await admin.auth().verifyIdToken(idToken);

// 檢查聊天室成員權限
if (roomData.customerId !== userId && roomData.driverId !== userId) {
  return res.status(403).json({error: 'Forbidden'});
}
```

### 4. CORS 配置

```javascript
res.set('Access-Control-Allow-Origin', '*');
res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
```

---

## 部署與維運

### 部署步驟

詳見 [部署指南](./deployment-guide.md)

### 監控指標

- **執行次數**: Firebase Console > Functions
- **錯誤率**: Cloud Logging
- **Token 使用量**: 記錄在 Firestore
- **平均延遲**: 記錄在 `duration` 欄位

### 日誌查詢

```bash
# 查看所有翻譯日誌
firebase functions:log

# 過濾特定函數
firebase functions:log --only onMessageCreate

# 查看錯誤
firebase functions:log --only onMessageCreate --min-log-level error
```

---

## 未來擴展

### 1. 多 AI 平台支援

- Google Gemini
- Anthropic Claude
- Azure Translator

### 2. 翻譯品質優化

- 上下文感知翻譯
- 專業術語詞典
- 用戶反饋機制

### 3. 成本優化

- 使用更便宜的模型（如 Gemini Flash）
- 實作更智能的快取策略
- 批次翻譯優化

### 4. 功能增強

- 語音翻譯
- 圖片 OCR + 翻譯
- 即時語音轉文字 + 翻譯

---

## 附錄

### 支援的語言清單

| 語言碼 | 語言名稱 | 使用場景 |
|--------|----------|----------|
| zh-TW  | 繁體中文 | 台灣用戶 |
| en     | English  | 國際用戶 |
| ja     | 日本語   | 日本遊客 |
| ko     | 한국어   | 韓國遊客 |
| th     | ไทย      | 泰國遊客 |
| vi     | Tiếng Việt | 越南移工 |
| id     | Bahasa Indonesia | 印尼移工 |
| ms     | Bahasa Melayu | 馬來西亞遊客 |

### 成本估算

**假設**:
- 平均訊息長度: 50 字元
- 平均翻譯長度: 60 字元
- gpt-4o-mini 價格: $0.15 / 1M input tokens, $0.60 / 1M output tokens
- 每則訊息翻譯 2 種語言

**計算**:
- Input tokens: ~20 tokens/訊息
- Output tokens: ~25 tokens/訊息
- 成本: (20 * $0.15 + 25 * $0.60) / 1,000,000 * 2 = **$0.00006 / 訊息**

**每月成本** (假設 10,000 則訊息):
- 10,000 * $0.00006 = **$0.60 / 月**

非常經濟實惠！ 💰

