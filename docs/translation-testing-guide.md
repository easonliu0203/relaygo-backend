# 翻譯功能測試指南

**測試日期**: 2025-10-17  
**狀態**: OpenAI API 配額已恢復，Functions 已部署  
**目的**: 驗證自動翻譯功能正常運作

---

## ✅ 已完成的準備工作

### 1. OpenAI API 配額測試 ✅
- ✅ API 金鑰有效
- ✅ 配額正常（$10.00 USD 可用）
- ✅ 測試翻譯成功（"你好" → "Hello"）
- ✅ 回應時間：1367ms
- ✅ 成本：$0.000009 USD/次

### 2. Firebase Cloud Functions 部署 ✅
- ✅ `onMessageCreate` - 自動翻譯觸發器（已更新）
- ✅ `translateMessage` - 按需翻譯 API（已更新）
- ✅ 包含改善的錯誤處理邏輯
- ✅ 部署時間：2025-10-17

---

## 📋 測試步驟

### 測試 1: 自動翻譯功能（核心測試）

#### 步驟 1: 在 Flutter App 中發送測試訊息

1. 打開 Flutter App（Customer 或 Driver）
2. 登入任意帳號
3. 進入任一聊天室
4. 發送一則**中文**測試訊息：
   ```
   你好，今天天氣很好
   ```
5. 等待 **3-5 秒**

#### 步驟 2: 檢查訊息顯示

**預期結果**:
- ✅ 訊息氣泡顯示原文（上方，正常字體）：
  ```
  你好，今天天氣很好
  ```
- ✅ 訊息氣泡顯示翻譯（下方，斜體，較小字體）：
  ```
  Hello, the weather is nice today
  ```
  或
  ```
  こんにちは、今日は天気がいいですね
  ```

**如果沒有顯示翻譯**:
- 等待更長時間（最多 10 秒）
- 檢查網路連線
- 查看 Cloud Functions 日誌（見下方）

#### 步驟 3: 查看 Cloud Functions 日誌

在電腦上執行：
```bash
firebase functions:log --only onMessageCreate
```

**預期日誌**（成功）:
```
[onMessageCreate] New message created: xxx in room xxx
[onMessageCreate] Translating to: en, ja
[Translation] Translated to en in 1200ms
[Translation] Tokens used: 45
[Translation] Translated to ja in 1500ms
[Translation] Tokens used: 52
[onMessageCreate] Successfully translated to 2 languages
```

**如果看到錯誤**:
- 如果顯示 `"OpenAI API quota exceeded"` → 配額問題，檢查 OpenAI 帳戶
- 如果顯示 `"OpenAI API authentication failed"` → API 金鑰問題
- 如果顯示 `"DNS resolution failed"` → 網路問題
- 其他錯誤 → 查看完整錯誤訊息

#### 步驟 4: 檢查 Firestore 數據

1. 打開 Firebase Console: https://console.firebase.google.com/project/ride-platform-f1676/firestore
2. 導航到 `chat_rooms/{roomId}/messages/{messageId}`
3. 找到剛才發送的訊息

**預期數據結構**:
```json
{
  "messageText": "你好，今天天氣很好",
  "senderId": "user_xxx",
  "receiverId": "user_yyy",
  "createdAt": "2025-10-17T...",
  "translatedAt": "2025-10-17T...",
  "translatedText": "Hello, the weather is nice today",
  "translations": {
    "en": {
      "text": "Hello, the weather is nice today",
      "model": "gpt-4o-mini",
      "at": "2025-10-17T...",
      "tokensUsed": 45,
      "duration": 1200
    },
    "ja": {
      "text": "こんにちは、今日は天気がいいですね",
      "model": "gpt-4o-mini",
      "at": "2025-10-17T...",
      "tokensUsed": 52,
      "duration": 1500
    }
  }
}
```

**如果數據不正確**:
- 如果 `translations` 欄位包含 `error` → 翻譯失敗，查看錯誤訊息
- 如果 `translatedAt` 為 `null` → Function 未觸發
- 如果 `translations` 欄位不存在 → Function 未執行

---

### 測試 2: 不同語言測試

#### 測試案例 2.1: 英文訊息
發送訊息：
```
Hello, how are you?
```

**預期結果**:
- ✅ 翻譯成中文：「你好，你好嗎？」
- ✅ 翻譯成日文：「こんにちは、お元気ですか？」
- ✅ **不翻譯成英文**（因為原文就是英文）

#### 測試案例 2.2: 日文訊息
發送訊息：
```
こんにちは
```

**預期結果**:
- ✅ 翻譯成中文：「你好」
- ✅ 翻譯成英文：「Hello」
- ✅ **不翻譯成日文**（因為原文就是日文）

#### 測試案例 2.3: 混合語言
發送訊息：
```
Hello 你好 こんにちは
```

**預期結果**:
- ✅ 翻譯成各種語言
- ✅ 保持原文的混合特性

---

### 測試 3: 成本控制機制

#### 測試案例 3.1: 長訊息截斷
發送超過 500 字元的訊息（複製以下文字）：
```
這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。這是一則非常長的訊息，用來測試成本控制機制。
```

**預期結果**:
- ✅ 訊息正常發送
- ✅ **不產生翻譯**（因為超過 500 字元）
- ✅ 日誌顯示：`Message too long (XXX chars), skipping auto-translate`

#### 測試案例 3.2: 翻譯快取
1. 發送訊息：「你好」
2. 等待翻譯完成
3. **立即**再次發送相同訊息：「你好」

**預期結果**:
- ✅ 第一次：調用 OpenAI API（較慢，約 1-2 秒）
- ✅ 第二次：使用快取（更快，< 100ms）
- ✅ 日誌顯示：`Using cached translation`

**注意**: 快取有效期為 10 分鐘，超過後會重新翻譯。

---

### 測試 4: 錯誤處理（可選）

#### 測試案例 4.1: 空訊息
發送空白訊息（只有空格）

**預期結果**:
- ✅ 訊息正常發送
- ✅ 不產生翻譯（因為內容為空）

#### 測試案例 4.2: 特殊字元
發送包含特殊字元的訊息：
```
Hello! 😊 你好 #test @user
```

**預期結果**:
- ✅ 訊息正常發送
- ✅ 翻譯正常（保留特殊字元）

---

## 📊 測試結果記錄表

### 測試 1: 自動翻譯功能
- [ ] 訊息顯示原文
- [ ] 訊息顯示翻譯
- [ ] Cloud Functions 日誌正常
- [ ] Firestore 數據正確

### 測試 2: 不同語言
- [ ] 英文訊息翻譯正確
- [ ] 日文訊息翻譯正確
- [ ] 混合語言翻譯正確

### 測試 3: 成本控制
- [ ] 長訊息跳過翻譯
- [ ] 翻譯快取生效

### 測試 4: 錯誤處理（可選）
- [ ] 空訊息處理正確
- [ ] 特殊字元處理正確

---

## 🆘 故障排除

### 問題 1: 訊息沒有顯示翻譯

**可能原因**:
1. Cloud Function 未觸發
2. 翻譯失敗
3. Flutter App 未正確讀取 Firestore 數據

**診斷步驟**:
1. 查看 Cloud Functions 日誌：
   ```bash
   firebase functions:log --only onMessageCreate
   ```
2. 檢查 Firestore 數據（見上方）
3. 檢查 Flutter App 日誌

---

### 問題 2: 日誌顯示 "OpenAI API quota exceeded"

**解決方案**:
1. 檢查 OpenAI 帳戶餘額：https://platform.openai.com/account/billing
2. 充值帳戶
3. 等待 5-10 分鐘
4. 重試

---

### 問題 3: 日誌顯示 "OpenAI API authentication failed"

**解決方案**:
1. 檢查 API 金鑰是否正確
2. 更新 Secret Manager：
   ```bash
   echo "新的API金鑰" | firebase functions:secrets:set OPENAI_API_KEY
   firebase deploy --only functions
   ```

---

### 問題 4: 翻譯速度很慢（> 10 秒）

**可能原因**:
1. OpenAI API 回應慢
2. 網路問題
3. Cold start（第一次調用）

**解決方案**:
1. 等待更長時間
2. 檢查網路連線
3. 重試（第二次應該更快）

---

## 📞 測試完成後

### 如果測試成功 ✅
1. 記錄測試結果
2. 監控 OpenAI 使用量
3. 定期檢查成本

### 如果測試失敗 ❌
1. 記錄錯誤訊息
2. 查看 Cloud Functions 日誌
3. 檢查 Firestore 數據
4. 參考故障排除指南
5. 如需協助，提供：
   - 錯誤訊息
   - Cloud Functions 日誌
   - Firestore 數據截圖

---

## 📚 相關文檔

- [錯誤診斷報告](./translation-error-diagnosis-report.md)
- [OpenAI 配額排查指南](./openai-quota-troubleshooting.md)
- [翻譯功能架構](./chat-translate-architecture.md)
- [部署後檢查清單](./secret-manager-post-deployment-checklist.md)

---

**測試指南創建時間**: 2025-10-17  
**最後更新**: 2025-10-17

