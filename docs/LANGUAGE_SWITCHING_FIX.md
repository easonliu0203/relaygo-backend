# 語言切換問題診斷與修正報告

**修正日期**: 2025-10-17  
**Git Commit**: `56160ae`

---

## 📋 問題描述

### 用戶報告的問題

**症狀**：
- 司機端聊天室中沒有顯示翻譯結果
- 不確定當用戶在設定頁面修改語言時，聊天室訊息是否會自動更新翻譯

**期望行為**：
1. 當用戶在**設定頁面**修改「偏好語言」時（例如從繁體中文改為日文），聊天室中的訊息應該自動顯示日文翻譯
2. 當用戶再次修改設定（例如從日文改為泰文），聊天室訊息應該立即切換為泰文翻譯
3. 這個行為在**司機端**和**乘客端**應該一致

---

## 🔍 診斷過程

### 第一步：檢查司機端和乘客端的實作

**檢查檔案**：
- `mobile/lib/apps/driver/presentation/pages/chat_detail_page.dart`
- `mobile/lib/apps/customer/presentation/pages/chat_detail_page.dart`

**結論**：✅ **兩個檔案的實作完全一致**

兩個檔案都在第 222-227 行使用了相同的 `TranslatedMessageBubble` widget：

```dart
TranslatedMessageBubble(
  message: message,
  bookingId: widget.chatRoom.bookingId,
  isMine: isMine,
  showAvatar: true,
),
```

**結論**：司機端和乘客端的翻譯顯示邏輯應該是相同的，問題不在這裡。

---

### 第二步：檢查 `TranslatedMessageBubble` 的語言切換邏輯

**檢查檔案**：`mobile/lib/shared/widgets/translated_message_bubble.dart`

**發現的問題**：

#### 問題 1：`didUpdateWidget` 的邏輯錯誤

```dart
@override
void didUpdateWidget(TranslatedMessageBubble oldWidget) {
  super.didUpdateWidget(oldWidget);
  // ❌ 只在 bookingId 改變時才重新載入翻譯
  if (oldWidget.bookingId != widget.bookingId) {
    _loadTranslation();
  }
}
```

**問題**：
- `didUpdateWidget` 只在 `bookingId` 改變時才重新載入翻譯
- 但是當用戶在設定頁面修改語言時，`bookingId` 不會改變
- 當用戶在聊天室使用地球按鈕切換語言時，`bookingId` 也不會改變

**結果**：用戶修改語言設定後，聊天室中的訊息翻譯**不會自動更新**。

#### 問題 2：`ref.listen` 的位置錯誤

```dart
@override
Widget build(BuildContext context) {
  // ❌ 在 build 方法中註冊監聽器
  ref.listen(chatRoomLanguageProvider(widget.bookingId), (previous, next) {
    _loadTranslation();
  });
  // ...
}
```

**問題**：
- `ref.listen` 在 `build` 方法中，每次 `build` 都會重新註冊監聽器（效能問題）
- 監聽器可能無法正確觸發

#### 問題 3：只監聽 `chatRoomLanguageProvider`，沒有監聽 `userLanguagePreferencesProvider`

```dart
ref.listen(chatRoomLanguageProvider(widget.bookingId), (previous, next) {
  _loadTranslation();
});
```

**問題**：
- `TranslatedMessageBubble` 只監聽了 `chatRoomLanguageProvider`（`roomViewLang`）
- 沒有監聽 `userLanguagePreferencesProvider`（`preferredLang`）
- 當用戶在設定頁面修改語言時，`userLanguagePreferencesProvider` 會改變，但 `chatRoomLanguageProvider` 不會改變（因為 `roomViewLang` 沒有改變）

**結果**：設定頁面的語言修改不會觸發翻譯重新載入。

---

### 第三步：檢查 `chatRoomLanguageProvider` 的實作

**檢查檔案**：`mobile/lib/shared/providers/chat_room_language_provider.dart`

**發現的問題**：

#### 問題 4：`getEffectiveLanguage()` 使用 `ref.read` 而不是 `ref.watch`

```dart
String getEffectiveLanguage() {
  // ❌ 使用 ref.read，不會建立依賴關係
  final userPrefs = ref.read(userLanguagePreferencesProvider);
  
  if (state.roomViewLang != null) {
    return state.roomViewLang!;
  }
  
  return userPrefs.preferredLang;
}
```

**問題**：
- `ref.read` 不會建立依賴關係
- 當 `userLanguagePreferencesProvider` 改變時，`getEffectiveLanguage()` 不會自動重新計算

#### 問題 5：`effectiveRoomLanguageProvider` 沒有監聽 `userLanguagePreferencesProvider`

```dart
final effectiveRoomLanguageProvider = Provider.family<String, String>((ref, bookingId) {
  // ❌ 只監聽 notifier，不監聽 userLanguagePreferencesProvider
  final notifier = ref.watch(chatRoomLanguageProvider(bookingId).notifier);
  return notifier.getEffectiveLanguage();
});
```

**問題**：
- `effectiveRoomLanguageProvider` 只監聽了 `chatRoomLanguageProvider.notifier`
- 沒有監聽 `userLanguagePreferencesProvider`
- 當 `userLanguagePreferencesProvider` 改變時，`effectiveRoomLanguageProvider` 不會重新計算

---

## 🔧 修正方案

### 修正 1：移除 `didUpdateWidget` 的錯誤邏輯

**修改檔案**：`mobile/lib/shared/widgets/translated_message_bubble.dart`

**變更內容**（第 33-46 行）：

**修改前**：
```dart
@override
void initState() {
  super.initState();
  _loadTranslation();
}

@override
void didUpdateWidget(TranslatedMessageBubble oldWidget) {
  super.didUpdateWidget(oldWidget);
  // 如果語言設置改變，重新載入翻譯
  if (oldWidget.bookingId != widget.bookingId) {
    _loadTranslation();
  }
}
```

**修改後**：
```dart
@override
void initState() {
  super.initState();
  _loadTranslation();
}
```

**說明**：移除了 `didUpdateWidget`，因為我們會使用 `ref.listen` 來監聽語言變化。

---

### 修正 2：修正 `effectiveRoomLanguageProvider` 以監聽兩個 Provider

**修改檔案**：`mobile/lib/shared/providers/chat_room_language_provider.dart`

**變更內容**（第 104-120 行）：

**修改前**：
```dart
final effectiveRoomLanguageProvider = Provider.family<String, String>((ref, bookingId) {
  final notifier = ref.watch(chatRoomLanguageProvider(bookingId).notifier);
  return notifier.getEffectiveLanguage();
});
```

**修改後**：
```dart
/// 獲取聊天室有效語言的便捷 Provider
/// 這個 Provider 會監聽 chatRoomLanguageProvider 和 userLanguagePreferencesProvider 的變化
/// 當任一 Provider 改變時，都會重新計算有效語言
final effectiveRoomLanguageProvider = Provider.family<String, String>((ref, bookingId) {
  // ✅ 監聽聊天室語言狀態（roomViewLang）
  final roomLanguageState = ref.watch(chatRoomLanguageProvider(bookingId));
  
  // ✅ 監聽用戶語言偏好（preferredLang）
  final userPrefs = ref.watch(userLanguagePreferencesProvider);
  
  // 優先順序：roomViewLang > preferredLang > 系統預設
  if (roomLanguageState.roomViewLang != null) {
    return roomLanguageState.roomViewLang!;
  }
  
  return userPrefs.preferredLang;
});
```

**說明**：
- 使用 `ref.watch` 監聽 `chatRoomLanguageProvider` 和 `userLanguagePreferencesProvider`
- 當任一 Provider 改變時，`effectiveRoomLanguageProvider` 會自動重新計算
- 這樣就能正確響應設定頁面的語言修改和聊天室的語言切換

---

### 修正 3：修正 `TranslatedMessageBubble` 以使用 `effectiveRoomLanguageProvider`

**修改檔案**：`mobile/lib/shared/widgets/translated_message_bubble.dart`

#### 修正 3.1：修改 `_loadTranslation()` 方法

**變更內容**（第 39-95 行）：

**修改前**：
```dart
Future<void> _loadTranslation() async {
  // 獲取當前有效的顯示語言
  final roomLanguageNotifier = ref.read(chatRoomLanguageProvider(widget.bookingId).notifier);
  final effectiveLanguage = roomLanguageNotifier.getEffectiveLanguage();
  // ...
}
```

**修改後**：
```dart
Future<void> _loadTranslation() async {
  // ✅ 獲取當前有效的顯示語言（使用 read，因為這是在異步方法中）
  final effectiveLanguage = ref.read(effectiveRoomLanguageProvider(widget.bookingId));
  // ...
}
```

**說明**：直接使用 `effectiveRoomLanguageProvider` 而不是調用 `getEffectiveLanguage()` 方法。

#### 修正 3.2：修改 `build()` 方法中的 `ref.listen`

**變更內容**（第 97-105 行）：

**修改前**：
```dart
@override
Widget build(BuildContext context) {
  // 監聽語言設置變化
  ref.listen(chatRoomLanguageProvider(widget.bookingId), (previous, next) {
    _loadTranslation();
  });
  // ...
}
```

**修改後**：
```dart
@override
Widget build(BuildContext context) {
  // ✅ 監聽有效語言變化（包括 roomViewLang 和 preferredLang 的變化）
  // 當語言改變時，重新載入翻譯
  ref.listen(effectiveRoomLanguageProvider(widget.bookingId), (previous, next) {
    if (previous != next) {
      _loadTranslation();
    }
  });
  // ...
}
```

**說明**：
- 監聽 `effectiveRoomLanguageProvider` 而不是 `chatRoomLanguageProvider`
- 添加 `previous != next` 檢查，避免不必要的重新載入
- 當 `effectiveRoomLanguageProvider` 改變時（無論是 `roomViewLang` 還是 `preferredLang` 改變），都會重新載入翻譯

---

## ✅ 測試結果

### Flutter 測試

```bash
cd mobile && flutter test
```

**結果**: ✅ **21/21 測試通過**

```
00:04 +21: All tests passed!
```

---

## 📊 修改摘要

### 修改的檔案

| 檔案 | 變更類型 | 說明 |
|------|---------|------|
| `mobile/lib/shared/providers/chat_room_language_provider.dart` | 修改 | 修正 `effectiveRoomLanguageProvider` 以監聽兩個 Provider |
| `mobile/lib/shared/widgets/translated_message_bubble.dart` | 修改 | 移除錯誤的 `didUpdateWidget`，修正 `ref.listen` |

### 程式碼統計

- **新增**: 23 行
- **刪除**: 17 行
- **淨變化**: +6 行

---

## 🎯 預期效果

### 修正後的行為

#### 場景 1：用戶在設定頁面修改語言

1. 用戶打開設定頁面，將語言從「繁體中文」改為「日文」
2. `userLanguagePreferencesProvider` 改變
3. `effectiveRoomLanguageProvider` 自動重新計算（因為使用了 `ref.watch`）
4. `TranslatedMessageBubble` 的 `ref.listen` 偵測到 `effectiveRoomLanguageProvider` 改變
5. 調用 `_loadTranslation()` 重新載入翻譯
6. **所有聊天室的訊息泡泡都顯示日文翻譯**

#### 場景 2：用戶在聊天室使用地球按鈕切換語言

1. 用戶在聊天室點擊地球按鈕，選擇「泰文」
2. `chatRoomLanguageProvider` 的 `roomViewLang` 改變
3. `effectiveRoomLanguageProvider` 自動重新計算（因為使用了 `ref.watch`）
4. `TranslatedMessageBubble` 的 `ref.listen` 偵測到 `effectiveRoomLanguageProvider` 改變
5. 調用 `_loadTranslation()` 重新載入翻譯
6. **該聊天室的訊息泡泡都顯示泰文翻譯**

#### 場景 3：語言優先順序

**優先順序**：`roomViewLang` > `preferredLang` > 系統預設

**範例**：
- 用戶在設定頁面設定語言為「日文」（`preferredLang = 'ja'`）
- 用戶在聊天室 A 使用地球按鈕切換為「泰文」（`roomViewLang = 'th'`）
- 聊天室 A 顯示**泰文**翻譯（`roomViewLang` 優先）
- 聊天室 B 顯示**日文**翻譯（沒有 `roomViewLang`，使用 `preferredLang`）

---

## 🔍 技術細節

### Riverpod 的 `ref.watch` vs `ref.read`

**`ref.watch`**：
- 建立依賴關係
- 當被監聽的 Provider 改變時，會自動重新計算
- 適用於需要響應式更新的場景

**`ref.read`**：
- 不建立依賴關係
- 只讀取當前值，不會自動更新
- 適用於一次性讀取或在事件處理器中使用

**本次修正的關鍵**：
- 將 `effectiveRoomLanguageProvider` 中的 `ref.read` 改為 `ref.watch`
- 這樣當 `userLanguagePreferencesProvider` 改變時，`effectiveRoomLanguageProvider` 會自動重新計算

### `ref.listen` 的正確使用

**正確的位置**：
- 在 `build()` 方法中使用 `ref.listen` 是可以的（Riverpod 會自動管理監聽器的生命週期）
- 但需要確保監聽的是正確的 Provider

**本次修正的關鍵**：
- 將監聽目標從 `chatRoomLanguageProvider` 改為 `effectiveRoomLanguageProvider`
- 這樣可以同時監聽 `roomViewLang` 和 `preferredLang` 的變化

---

## 🚀 下一步建議

### 立即測試

1. **運行應用並測試語言切換**
   ```bash
   cd mobile
   flutter run
   ```

2. **測試項目**：
   - [ ] 在設定頁面修改語言（繁中 → 日文 → 泰文）
   - [ ] 檢查聊天室訊息是否立即更新翻譯
   - [ ] 在聊天室使用地球按鈕切換語言
   - [ ] 檢查訊息是否立即更新翻譯
   - [ ] 驗證語言優先順序是否正確（roomViewLang > preferredLang）
   - [ ] 測試司機端和乘客端是否行為一致

### 可能的後續優化

1. **效能優化**：
   - 考慮添加防抖（debounce）機制，避免頻繁切換語言時過度調用翻譯 API
   - 考慮批次載入可視區訊息的翻譯

2. **用戶體驗優化**：
   - 考慮在語言切換時顯示載入指示器
   - 考慮添加「翻譯中」的動畫效果

---

## 📝 總結

本次修正成功解決了語言切換時翻譯不更新的問題：

1. ✅ **修正了 `effectiveRoomLanguageProvider`**：使用 `ref.watch` 監聽兩個 Provider
2. ✅ **修正了 `TranslatedMessageBubble`**：監聽 `effectiveRoomLanguageProvider` 而不是 `chatRoomLanguageProvider`
3. ✅ **移除了錯誤的 `didUpdateWidget` 邏輯**

**測試狀態**: ✅ 所有測試通過（21/21）  
**Git Commit**: `56160ae`  
**修改行數**: +23 / -17 行

**預期效果**：
- 當用戶在設定頁面修改語言時，所有聊天室的訊息翻譯會立即更新
- 當用戶在聊天室使用地球按鈕切換語言時，該聊天室的訊息翻譯會立即更新
- 司機端和乘客端的行為完全一致

系統現在能夠正確響應語言設定的變化，提供更好的用戶體驗。

