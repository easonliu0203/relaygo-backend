# 聊天翻譯功能驗收測試指南

**版本**: 1.0  
**日期**: 2025-10-17

---

## 📋 測試環境準備

### 1. 環境變數設定

在 `firebase/functions/.env` 檔案中設定：

```bash
# 複製範例檔案
cp firebase/functions/.env.example firebase/functions/.env

# 編輯 .env 檔案
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ENABLE_AUTO_TRANSLATE=true
TARGET_LANGUAGES=zh-TW,en,ja
OPENAI_MODEL=gpt-4o-mini
MAX_AUTO_TRANSLATE_LENGTH=500
MAX_CONCURRENT_TRANSLATIONS=2
```

### 2. 安裝依賴

```bash
cd firebase/functions
npm install
```

### 3. 部署 Cloud Functions

```bash
# 從專案根目錄
firebase deploy --only functions

# 或只部署特定函數
firebase deploy --only functions:onMessageCreate,functions:translateMessage
```

### 4. 部署 Firestore 規則

```bash
firebase deploy --only firestore:rules
```

---

## 🧪 驗收案例

### 案例 1: 自動翻譯 - 新訊息自動產生翻譯

**目標**: 驗證新訊息創建時自動翻譯到目標語言

**前置條件**:
- ✅ Cloud Functions 已部署
- ✅ `ENABLE_AUTO_TRANSLATE=true`
- ✅ `TARGET_LANGUAGES=zh-TW,en,ja`

**測試步驟**:

1. 在 Flutter App 中發送一則英文訊息：
   ```
   "Hello, how are you?"
   ```

2. 等待 3-5 秒

3. 在 Firestore Console 中檢查該訊息文檔

**預期結果**:

```json
{
  "messageText": "Hello, how are you?",
  "lang": "en",
  "translations": {
    "zh-TW": {
      "text": "你好，你好嗎？",
      "model": "gpt-4o-mini",
      "at": "2025-10-17T10:30:00Z",
      "tokensUsed": 25
    },
    "ja": {
      "text": "こんにちは、お元気ですか？",
      "model": "gpt-4o-mini",
      "at": "2025-10-17T10:30:01Z",
      "tokensUsed": 28
    }
  },
  "translatedAt": "2025-10-17T10:30:01Z"
}
```

**驗收標準**:
- ✅ `translations` 欄位存在
- ✅ 包含 `zh-TW` 和 `ja` 兩種翻譯
- ✅ 每個翻譯包含 `text`, `model`, `at` 欄位
- ✅ 翻譯內容正確且自然

**失敗排查**:

```bash
# 查看 Cloud Functions 日誌
firebase functions:log --only onMessageCreate

# 檢查環境變數
firebase functions:config:get

# 檢查 Firestore 規則
firebase firestore:rules:get
```

---

### 案例 2: 按需翻譯 - 點擊按鈕翻譯特定語言

**目標**: 驗證用戶點擊「翻譯」按鈕時產生翻譯

**前置條件**:
- ✅ Cloud Functions 已部署
- ✅ 用戶已登入並獲得 ID Token

**測試步驟**:

1. 使用 Postman 或 curl 呼叫 HTTPS 端點：

```bash
curl -X POST \
  https://asia-east1-ride-platform-f1676.cloudfunctions.net/translateMessage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "roomId": "test_room_123",
    "messageId": "test_msg_456",
    "targetLang": "ko"
  }'
```

2. 檢查回應

**預期結果**:

```json
{
  "success": true,
  "translation": {
    "text": "안녕하세요, 어떻게 지내세요?",
    "model": "gpt-4o-mini",
    "at": "2025-10-17T10:35:00Z",
    "tokensUsed": 30,
    "duration": 1200
  },
  "cached": false
}
```

**驗收標準**:
- ✅ HTTP 狀態碼 200
- ✅ `success: true`
- ✅ `translation` 物件包含正確的翻譯
- ✅ Firestore 中該訊息的 `translations.ko` 已更新

**錯誤案例測試**:

| 案例 | 請求 | 預期回應 |
|------|------|----------|
| 未提供 Token | 無 Authorization header | 401 Unauthorized |
| 無效 Token | 錯誤的 Token | 401 Unauthorized |
| 非聊天室成員 | 其他用戶的 Token | 403 Forbidden |
| 訊息不存在 | 錯誤的 messageId | 404 Not Found |
| 缺少參數 | 缺少 targetLang | 400 Bad Request |

---

### 案例 3: Firestore 規則 - 客戶端不能直接寫入翻譯

**目標**: 驗證客戶端無法直接修改 `translations` 欄位

**測試步驟**:

1. 在 Flutter App 中嘗試直接更新訊息：

```dart
await FirebaseFirestore.instance
  .collection('chat_rooms')
  .doc(roomId)
  .collection('messages')
  .doc(messageId)
  .update({
    'translations.ko': {
      'text': 'Hacked!',
      'model': 'fake',
      'at': Timestamp.now(),
    }
  });
```

**預期結果**:

```
FirebaseException: [permission-denied] Missing or insufficient permissions.
```

**驗收標準**:
- ✅ 更新操作被拒絕
- ✅ 錯誤訊息為 `permission-denied`
- ✅ Firestore 中的資料未被修改

---

### 案例 4: 成本控制 - 長訊息不自動翻譯

**目標**: 驗證超過閾值的長訊息不會自動翻譯

**前置條件**:
- ✅ `MAX_AUTO_TRANSLATE_LENGTH=500`

**測試步驟**:

1. 發送一則 600 字元的訊息

2. 等待 5 秒

3. 檢查 Firestore

**預期結果**:

```json
{
  "messageText": "AAAA...AAAA (600 chars)",
  "lang": "en",
  "createdAt": "2025-10-17T10:40:00Z"
  // 沒有 translations 欄位
}
```

**驗收標準**:
- ✅ `translations` 欄位不存在
- ✅ Cloud Functions 日誌顯示 "Message too long, skipping auto-translate"

---

### 案例 5: 冪等性 - 重複觸發不重複翻譯

**目標**: 驗證已有翻譯的訊息不會重複翻譯

**測試步驟**:

1. 發送一則訊息，等待自動翻譯完成

2. 手動觸發 Cloud Function（模擬重複觸發）：

```bash
# 使用 Firebase Emulator 或直接修改 Firestore 觸發
```

3. 檢查 Cloud Functions 日誌

**預期結果**:

```
[onMessageCreate] Translations already exist, skipping
```

**驗收標準**:
- ✅ 不會重複呼叫 OpenAI API
- ✅ `translations` 欄位未被覆蓋
- ✅ 日誌顯示跳過翻譯

---

### 案例 6: 語言偵測 - 相同語言不翻譯

**目標**: 驗證來源語言等於目標語言時跳過翻譯

**測試步驟**:

1. 發送一則中文訊息（lang: zh-TW）

2. 目標語言清單包含 zh-TW

3. 檢查翻譯結果

**預期結果**:

```json
{
  "messageText": "你好",
  "lang": "zh-TW",
  "translations": {
    "en": { "text": "Hello", ... },
    "ja": { "text": "こんにちは", ... }
    // 沒有 zh-TW
  }
}
```

**驗收標準**:
- ✅ `translations` 中不包含 `zh-TW`
- ✅ 只翻譯到其他語言

---

### 案例 7: 錯誤處理 - OpenAI API 失敗

**目標**: 驗證 API 失敗時的錯誤處理

**測試步驟**:

1. 暫時設定錯誤的 API 金鑰：

```bash
firebase functions:config:set openai.api_key="invalid_key"
firebase deploy --only functions
```

2. 發送一則訊息

3. 檢查 Firestore 和日誌

**預期結果**:

```json
{
  "messageText": "Hello",
  "lang": "en",
  "translationError": {
    "message": "Translation failed after 3 attempts: Invalid API key",
    "at": "2025-10-17T10:50:00Z"
  }
}
```

**驗收標準**:
- ✅ `translationError` 欄位存在
- ✅ 錯誤訊息清楚描述問題
- ✅ Cloud Function 不會無限重試
- ✅ 日誌記錄完整錯誤堆疊

**恢復**:

```bash
firebase functions:config:set openai.api_key="correct_key"
firebase deploy --only functions
```

---

## 🔍 自動化測試

### 執行測試腳本

```bash
cd firebase/functions

# 設定環境變數
export OPENAI_API_KEY="sk-proj-xxxxx"
export ENABLE_AUTO_TRANSLATE="true"
export TARGET_LANGUAGES="zh-TW,en,ja"

# 執行測試
node test/test-translation.js
```

### 預期輸出

```
╔════════════════════════════════════════════════════════╗
║         聊天翻譯功能測試套件                           ║
╚════════════════════════════════════════════════════════╝

=== 測試案例 1: 按需翻譯 ===
✅ 翻譯成功！

=== 測試案例 2: 批次翻譯 ===
✅ 批次翻譯完成！

=== 測試案例 3: 長訊息控制 ===
✅ 正確跳過長訊息翻譯

=== 測試案例 4: 快取機制 ===
✅ 快取機制正常運作

=== 測試案例 5: 語言偵測 ===
✅ 正確跳過相同語言翻譯

╔════════════════════════════════════════════════════════╗
║                    測試結果總覽                        ║
╚════════════════════════════════════════════════════════╝

✅ PASS - 按需翻譯
✅ PASS - 批次翻譯
✅ PASS - 長訊息控制
✅ PASS - 快取機制
✅ PASS - 語言偵測

總計: 5/5 測試通過

🎉 所有測試通過！
```

---

## 📊 驗收檢查清單

### 功能驗收

- [ ] 案例 1: 自動翻譯正常運作
- [ ] 案例 2: 按需翻譯 API 正常運作
- [ ] 案例 3: Firestore 規則正確限制客戶端寫入
- [ ] 案例 4: 長訊息成本控制生效
- [ ] 案例 5: 冪等性檢查生效
- [ ] 案例 6: 語言偵測正確跳過
- [ ] 案例 7: 錯誤處理機制完善

### 效能驗收

- [ ] 單次翻譯平均耗時 < 2 秒
- [ ] 批次翻譯（3 語言）平均耗時 < 5 秒
- [ ] 快取命中率 > 30%（相同訊息重複翻譯）
- [ ] Cloud Function 冷啟動時間 < 3 秒

### 成本驗收

- [ ] 每則訊息翻譯成本 < $0.0001
- [ ] 長訊息（>500 字元）不自動翻譯
- [ ] 相同語言不重複翻譯
- [ ] 已翻譯訊息不重複翻譯

### 安全驗收

- [ ] API 金鑰不暴露給客戶端
- [ ] 客戶端無法直接寫入 translations
- [ ] HTTPS 端點需要有效的 ID Token
- [ ] 非聊天室成員無法翻譯訊息

### 監控驗收

- [ ] Cloud Functions 日誌正常記錄
- [ ] 翻譯成功/失敗次數可追蹤
- [ ] Token 使用量可統計
- [ ] 錯誤訊息清晰可讀

---

## 🐛 常見問題排查

### 問題 1: 自動翻譯不生效

**症狀**: 新訊息沒有 `translations` 欄位

**排查步驟**:

1. 檢查 Cloud Function 是否部署：
   ```bash
   firebase functions:list
   ```

2. 檢查環境變數：
   ```bash
   firebase functions:config:get
   ```

3. 查看日誌：
   ```bash
   firebase functions:log --only onMessageCreate
   ```

4. 檢查 Firestore 觸發器是否正確：
   - 路徑: `chat_rooms/{roomId}/messages/{messageId}`
   - 事件: onCreate

### 問題 2: 按需翻譯 API 回傳 401

**症狀**: HTTPS 端點回傳 Unauthorized

**排查步驟**:

1. 檢查 ID Token 是否有效：
   ```javascript
   const user = firebase.auth().currentUser;
   const token = await user.getIdToken();
   console.log(token);
   ```

2. 檢查 Authorization header 格式：
   ```
   Authorization: Bearer {token}
   ```

3. 檢查 Token 是否過期（有效期 1 小時）

### 問題 3: 翻譯品質不佳

**症狀**: 翻譯結果不自然或錯誤

**解決方案**:

1. 調整 Prompt（在 `translationService.js` 中）
2. 增加上下文資訊
3. 使用更好的模型（如 gpt-4）
4. 建立專業術語詞典

---

## ✅ 驗收簽核

| 項目 | 負責人 | 狀態 | 日期 | 備註 |
|------|--------|------|------|------|
| 功能測試 | | ⬜ 待測試 | | |
| 效能測試 | | ⬜ 待測試 | | |
| 成本測試 | | ⬜ 待測試 | | |
| 安全測試 | | ⬜ 待測試 | | |
| 最終驗收 | | ⬜ 待驗收 | | |

---

**驗收完成後，請更新此文檔並提交到版本控制系統。**

