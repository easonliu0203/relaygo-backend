# 翻譯顯示修復：translatedText 欄位設置

**問題發現日期**: 2025-10-17  
**修復完成時間**: 2025-10-17  
**狀態**: ✅ 已修復

---

## 🎯 問題總結

### 症狀
- 翻譯功能在 Cloud Functions 中成功運作
- Firestore 中有正確的翻譯數據（`translations.en.text`, `translations.ja.text`）
- 但是 Flutter App 沒有顯示翻譯結果

### 根本原因

**數據結構不匹配**：
- **Cloud Functions** 只寫入 `translations` 欄位
- **Flutter App** 從 `translatedText` 欄位讀取翻譯
- 導致 `translatedText` 一直是 `null`，Flutter UI 無法顯示翻譯

---

## 🔍 診斷分析

### Firestore 數據結構

**Cloud Functions 寫入的數據**（修復前）:
```json
{
  "messageText": "這次應該成功了",
  "translatedAt": "2025-10-17T18:37:41Z",
  "translatedText": null,  ← 沒有設置
  "translations": {
    "en": {
      "text": "This time it should be successful.",
      "model": "gpt-4o-mini",
      "tokensUsed": 68,
      "duration": 1246,
      "at": "2025-10-17T18:37:40Z"
    },
    "ja": {
      "text": "今回は成功するはずです。",
      "model": "gpt-4o-mini",
      "tokensUsed": 69,
      "duration": 1285,
      "at": "2025-10-17T18:37:40Z"
    }
  }
}
```

### Flutter App 代碼分析

#### 1. ChatMessage 模型（`mobile/lib/core/models/chat_message.dart`）

```dart
factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return ChatMessage(
    id: doc.id,
    senderId: data['senderId'] ?? '',
    receiverId: data['receiverId'] ?? '',
    senderName: data['senderName'],
    receiverName: data['receiverName'],
    messageText: data['messageText'] ?? '',
    translatedText: data['translatedText'],  // ← 從這裡讀取
    createdAt: _parseTimestamp(data['createdAt']),
    readAt: _parseOptionalTimestamp(data['readAt']),
  );
}
```

**問題**：模型從 `data['translatedText']` 讀取，但 Cloud Functions 沒有設置這個欄位。

#### 2. MessageBubble UI（`mobile/lib/shared/widgets/message_bubble.dart`）

```dart
// 翻譯文字（如果有）
if (message.translatedText != null &&
    message.translatedText!.isNotEmpty) ...[
  const SizedBox(height: 6),
  Container(
    padding: const EdgeInsets.only(top: 6),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: isMine
              ? Colors.white.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
    ),
    child: Text(
      message.translatedText!,  // ← 顯示這個欄位
      style: TextStyle(
        fontSize: 14,
        color: isMine
            ? Colors.white.withOpacity(0.9)
            : Colors.black54,
        height: 1.3,
        fontStyle: FontStyle.italic,
      ),
    ),
  ),
],
```

**問題**：UI 檢查 `message.translatedText` 是否為 null，如果是 null 就不顯示翻譯。

### Cloud Functions 代碼分析

#### 修復前的代碼（`firebase/functions/index.js`）

```javascript
// 批次翻譯
const translations = await translationService.translateBatch(
  text,
  sourceLang,
  targetLanguages,
  maxConcurrent
);

// 寫回 Firestore
await snapshot.ref.update({
  translations,  // ← 只寫入 translations
  translatedAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

**問題**：沒有設置 `translatedText` 欄位。

---

## ✅ 修復方案

### 修復 1: onMessageCreate 函數

**修復後的代碼**:
```javascript
// 批次翻譯
const maxConcurrent = parseInt(process.env.MAX_CONCURRENT_TRANSLATIONS || '2');
const translations = await translationService.translateBatch(
  text,
  sourceLang,
  targetLanguages,
  maxConcurrent
);

// 決定要顯示的翻譯文字（優先順序：en > ja > 第一個可用的翻譯）
let translatedText = null;
if (translations.en && translations.en.text) {
  translatedText = translations.en.text;
} else if (translations.ja && translations.ja.text) {
  translatedText = translations.ja.text;
} else {
  // 使用第一個可用的翻譯
  const firstLang = Object.keys(translations)[0];
  if (firstLang && translations[firstLang].text) {
    translatedText = translations[firstLang].text;
  }
}

// 寫回 Firestore
await snapshot.ref.update({
  translations,
  translatedText, // ← 設置 translatedText 欄位供 Flutter App 使用
  translatedAt: admin.firestore.FieldValue.serverTimestamp(),
});

console.log(`[onMessageCreate] Successfully translated to ${Object.keys(translations).length} languages`);
console.log(`[onMessageCreate] translatedText set to: ${translatedText ? translatedText.substring(0, 50) : 'null'}...`);
```

**優先順序邏輯**:
1. **優先使用英文翻譯** (`translations.en.text`)
2. **其次使用日文翻譯** (`translations.ja.text`)
3. **最後使用第一個可用的翻譯**

### 修復 2: translateMessage 函數（HTTPS 端點）

**修復後的代碼**:
```javascript
// 決定是否更新 translatedText（如果翻譯的是英文或日文）
const updateData = {
  [`translations.${targetLang}`]: translation,
  translatedAt: admin.firestore.FieldValue.serverTimestamp(),
};

// 如果翻譯的是英文，更新 translatedText
if (targetLang === 'en') {
  updateData.translatedText = translation.text;
}
// 如果翻譯的是日文，且目前沒有 translatedText，則使用日文翻譯
else if (targetLang === 'ja' && !messageData.translatedText) {
  updateData.translatedText = translation.text;
}

// 寫回 Firestore
await messageRef.update(updateData);
```

**邏輯**:
- 如果翻譯的是英文，直接更新 `translatedText`
- 如果翻譯的是日文，且目前沒有 `translatedText`，則使用日文翻譯
- 其他語言不更新 `translatedText`（保持英文或日文翻譯）

---

## 📊 修復前後對比

### 修復前

**Firestore 數據**:
```json
{
  "messageText": "這次應該成功了",
  "translatedText": null,  ← null
  "translations": {
    "en": { "text": "This time it should be successful." },
    "ja": { "text": "今回は成功するはずです。" }
  }
}
```

**Flutter App**:
```dart
message.translatedText  // null
// UI 不顯示翻譯（因為 translatedText 是 null）
```

### 修復後

**Firestore 數據**:
```json
{
  "messageText": "這次應該成功了",
  "translatedText": "This time it should be successful.",  ← 設置為英文翻譯
  "translations": {
    "en": { "text": "This time it should be successful." },
    "ja": { "text": "今回は成功するはずです。" }
  }
}
```

**Flutter App**:
```dart
message.translatedText  // "This time it should be successful."
// UI 顯示翻譯（在原文下方，斜體，半透明）
```

---

## 🎯 測試步驟

### 步驟 1: 發送新的測試訊息

在 Flutter App 中發送訊息：**「翻譯應該會顯示了」**

### 步驟 2: 等待 5-10 秒

### 步驟 3: 檢查 Flutter App

**預期結果**:
- 訊息氣泡顯示原文：「翻譯應該會顯示了」
- 原文下方顯示翻譯（斜體，半透明）：「The translation should be displayed.」

### 步驟 4: 檢查 Firestore 數據

**預期數據**:
```json
{
  "messageText": "翻譯應該會顯示了",
  "translatedText": "The translation should be displayed.",  ← 有值
  "translations": {
    "en": {
      "text": "The translation should be displayed.",
      "model": "gpt-4o-mini",
      "tokensUsed": 15,
      "duration": 1200,
      "at": "2025-10-17T..."
    },
    "ja": {
      "text": "翻訳が表示されるはずです。",
      "model": "gpt-4o-mini",
      "tokensUsed": 18,
      "duration": 1500,
      "at": "2025-10-17T..."
    }
  }
}
```

### 步驟 5: 檢查 Cloud Functions 日誌

**預期日誌**:
```
[onMessageCreate] New message created: xxx in room xxx
[onMessageCreate] Auto-translate is enabled
[onMessageCreate] API key retrieved from Secret Manager: sk-proj-xxx...
[onMessageCreate] Translating to: en, ja
[Translation] Translated to en in 1200ms
[Translation] Tokens used: 45
[Translation] Translated to ja in 1500ms
[Translation] Tokens used: 52
[onMessageCreate] Successfully translated to 2 languages
[onMessageCreate] translatedText set to: The translation should be displayed...  ← 新增的日誌
```

---

## 💡 設計決策

### 為什麼選擇英文作為 translatedText？

**原因**:
1. **國際通用性** - 英文是最廣泛使用的國際語言
2. **用戶期望** - 大多數用戶期望看到英文翻譯
3. **一致性** - 所有訊息都顯示相同語言的翻譯，避免混亂

**優先順序**:
1. 英文（en）
2. 日文（ja）
3. 第一個可用的翻譯

### 為什麼保留 translations 欄位？

**原因**:
1. **多語言支援** - 未來可能需要顯示多種語言的翻譯
2. **靈活性** - Flutter App 可以根據用戶偏好選擇顯示哪種語言
3. **完整性** - 保留所有翻譯數據，方便後續分析和優化

### 未來可能的改進

**選項 1: 根據用戶語言偏好設置 translatedText**
```javascript
// 讀取用戶的語言偏好
const userLang = await getUserLanguagePreference(receiverId);
translatedText = translations[userLang]?.text || translations.en?.text;
```

**選項 2: Flutter App 直接從 translations 讀取**
```dart
// 修改 ChatMessage 模型
String? get translatedText {
  // 根據用戶語言偏好選擇翻譯
  final userLang = getUserLanguagePreference();
  return translations?[userLang]?.text ?? translations?['en']?.text;
}
```

---

## 📚 相關文檔

- [翻譯功能架構文檔](./chat-translate-architecture.md)
- [換行符 Bug 修復](./translation-newline-bug-fix.md)
- [翻譯功能測試指南](./translation-testing-guide.md)

---

## 🎉 總結

**問題**：`translatedText` 欄位未設置，導致 Flutter App 無法顯示翻譯  
**原因**：Cloud Functions 只寫入 `translations` 欄位，沒有設置 `translatedText`  
**解決方案**：在 Cloud Functions 中設置 `translatedText` 為英文翻譯（優先）  
**狀態**：✅ 已修復並部署

**修復內容**:
- ✅ `onMessageCreate` 函數：設置 `translatedText` 為英文翻譯（優先）
- ✅ `translateMessage` 函數：如果翻譯英文或日文，更新 `translatedText`
- ✅ 添加日誌：記錄 `translatedText` 的值

**預期結果**:
- ✅ Flutter App 顯示翻譯文字（在原文下方）
- ✅ Firestore 數據包含 `translatedText` 欄位
- ✅ 翻譯功能完全正常運作

---

**報告創建時間**: 2025-10-17  
**最後更新**: 2025-10-17  
**狀態**: ✅ 已修復

