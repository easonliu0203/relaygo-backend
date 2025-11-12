# 階段 1: 資料模型與安全規則 - 實施總結

**開始日期**: 2025-10-17  
**狀態**: 🚧 進行中  
**預計時間**: 2-3 天  

---

## 📋 任務概覽

階段 1 的目標是更新 Firestore 數據模型和安全規則，為按需翻譯系統奠定基礎。

---

## 🎯 主要任務

### 1.1 更新 Firestore 用戶文檔（`users/{uid}`）

**新增欄位**:
```typescript
{
  preferredLang: string,              // 用戶偏好語言（zh-TW, en, ja, ko, etc.）
  inputLangHint: string,              // 輸入語言提示（用於語言偵測）
  hasCompletedLanguageWizard: boolean // 是否完成語言精靈
}
```

**實施步驟**:
- [ ] 更新 Flutter `UserProfile` 模型
- [ ] 更新 Firestore 安全規則
- [ ] 創建數據遷移腳本

---

### 1.2 更新 Firestore 聊天室文檔（`chat_rooms/{roomId}`）

**新增欄位**:
```typescript
{
  memberIds: string[],                // 成員 Firebase UID 列表 [customerId, driverId]
  roomLangOverride: string?,          // 聊天室語言覆蓋（可選，存儲在本地）
}
```

**實施步驟**:
- [ ] 更新 Flutter `ChatRoom` 模型
- [ ] 更新 Firestore 安全規則
- [ ] 創建數據遷移腳本

**注意**: `roomLangOverride` 將主要存儲在客戶端本地（SharedPreferences），Firestore 中可選。

---

### 1.3 更新 Firestore 訊息文檔（`messages/{msgId}`）

**新增欄位**:
```typescript
{
  detectedLang: string,               // 偵測到的語言（zh-TW, en, ja, etc.）
}
```

**移除欄位**（逐步遷移）:
```typescript
{
  translatedText: string?,            // 將不再自動填充（改為客戶端按需翻譯）
  translations: map?,                 // 將不再自動填充（改為客戶端快取）
}
```

**實施步驟**:
- [ ] 更新 Flutter `ChatMessage` 模型
- [ ] 更新 Firestore 安全規則
- [ ] 保留 `translatedText` 和 `translations` 欄位（向後兼容）

**遷移策略**:
- 保留現有欄位以確保向後兼容
- 新訊息將包含 `detectedLang` 欄位
- 舊訊息的 `translatedText` 和 `translations` 仍然可用
- 逐步停用 `onMessageCreate` 自動翻譯功能

---

### 1.4 更新 Firestore 安全規則

**users/{uid} 規則**:
```javascript
match /users/{userId} {
  // 允許讀取自己的語言設定
  allow read: if request.auth != null && request.auth.uid == userId;
  
  // 允許更新自己的語言設定
  allow update: if request.auth != null && 
    request.auth.uid == userId &&
    // 只允許更新這些欄位
    request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['preferredLang', 'inputLangHint', 'hasCompletedLanguageWizard', 
                'firstName', 'lastName', 'phone', 'avatarUrl', 'dateOfBirth', 
                'gender', 'address', 'emergencyContactName', 'emergencyContactPhone', 
                'updatedAt']);
}
```

**chat_rooms/{roomId} 規則**:
```javascript
match /chat_rooms/{roomId} {
  // 允許成員讀取聊天室
  allow read: if request.auth != null &&
    (
      !exists(/databases/$(database)/documents/chat_rooms/$(roomId))
      ||
      (request.auth.uid in resource.data.memberIds)
    );

  // 允許成員更新聊天室（lastMessage, unreadCount, roomLangOverride）
  allow update: if request.auth != null &&
    (request.auth.uid in resource.data.memberIds) &&
    request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly(['lastMessage', 'lastMessageTime', 'customerUnreadCount', 
                'driverUnreadCount', 'roomLangOverride', 'updatedAt']);
}
```

**messages/{msgId} 規則**:
```javascript
match /messages/{messageId} {
  // 允許創建訊息時設置 detectedLang
  allow create: if request.auth != null &&
    (get(/databases/$(database)/documents/chat_rooms/$(roomId)).data.customerId == request.auth.uid ||
     get(/databases/$(database)/documents/chat_rooms/$(roomId)).data.driverId == request.auth.uid) &&
    request.resource.data.senderId == request.auth.uid &&
    // 確保包含 detectedLang 欄位
    request.resource.data.keys().hasAll(['messageText', 'senderId', 'receiverId', 'createdAt', 'detectedLang']);
}
```

---

## 📝 數據遷移計劃

### 遷移腳本 1: 為現有用戶設置默認語言

**文件**: `firebase/migrations/add-user-language-preferences.js`

**邏輯**:
1. 查詢所有 `users` 文檔
2. 為每個用戶添加默認值：
   - `preferredLang`: `'zh-TW'`（默認繁體中文）
   - `inputLangHint`: `'zh-TW'`（默認繁體中文）
   - `hasCompletedLanguageWizard`: `false`（未完成語言精靈）
3. 批次更新（每批 500 個文檔）

**執行命令**:
```bash
cd firebase
node migrations/add-user-language-preferences.js
```

---

### 遷移腳本 2: 為現有聊天室添加 memberIds

**文件**: `firebase/migrations/add-chat-room-member-ids.js`

**邏輯**:
1. 查詢所有 `chat_rooms` 文檔
2. 為每個聊天室添加 `memberIds`:
   - `memberIds`: `[customerId, driverId]`
3. 批次更新（每批 500 個文檔）

**執行命令**:
```bash
cd firebase
node migrations/add-chat-room-member-ids.js
```

---

### 遷移腳本 3: 為現有訊息添加 detectedLang（可選）

**文件**: `firebase/migrations/add-message-detected-lang.js`

**邏輯**:
1. 查詢所有 `chat_rooms/{roomId}/messages` 文檔
2. 為每個訊息添加默認值：
   - `detectedLang`: `'zh-TW'`（默認繁體中文，或根據 `messageText` 偵測）
3. 批次更新（每批 500 個文檔）

**注意**: 這個遷移是可選的，因為舊訊息可以在客戶端動態偵測語言。

**執行命令**:
```bash
cd firebase
node migrations/add-message-detected-lang.js
```

---

## 🔄 Flutter 數據模型更新

### UserProfile 模型更新

**文件**: `mobile/lib/core/models/user_profile.dart`

**新增欄位**:
```dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    required DateTime createdAt,
    required DateTime updatedAt,
    
    // 新增：語言偏好設定
    @Default('zh-TW') String preferredLang,           // 偏好語言
    @Default('zh-TW') String inputLangHint,           // 輸入語言提示
    @Default(false) bool hasCompletedLanguageWizard,  // 是否完成語言精靈
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
```

---

### ChatRoom 模型更新

**文件**: `mobile/lib/core/models/chat_room.dart`

**新增欄位**:
```dart
@freezed
class ChatRoom with _$ChatRoom {
  const factory ChatRoom({
    required String bookingId,
    required String customerId,
    required String driverId,
    String? customerName,
    String? driverName,
    String? pickupAddress,
    DateTime? bookingTime,
    String? lastMessage,
    DateTime? lastMessageTime,
    @Default(0) int customerUnreadCount,
    @Default(0) int driverUnreadCount,
    DateTime? updatedAt,
    
    // 新增：成員列表和語言覆蓋
    @Default([]) List<String> memberIds,              // 成員 UID 列表
    String? roomLangOverride,                         // 聊天室語言覆蓋（可選）
  }) = _ChatRoom;

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);
}
```

**更新 fromFirestore 方法**:
```dart
factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return ChatRoom(
    bookingId: doc.id,
    customerId: data['customerId'] ?? '',
    driverId: data['driverId'] ?? '',
    customerName: data['customerName'],
    driverName: data['driverName'],
    pickupAddress: data['pickupAddress'],
    bookingTime: _parseOptionalTimestamp(data['bookingTime']),
    lastMessage: data['lastMessage'],
    lastMessageTime: _parseOptionalTimestamp(data['lastMessageTime']),
    customerUnreadCount: data['customerUnreadCount'] ?? 0,
    driverUnreadCount: data['driverUnreadCount'] ?? 0,
    updatedAt: _parseOptionalTimestamp(data['updatedAt']),
    
    // 新增欄位
    memberIds: data['memberIds'] != null 
      ? List<String>.from(data['memberIds']) 
      : [data['customerId'] ?? '', data['driverId'] ?? ''],
    roomLangOverride: data['roomLangOverride'],
  );
}
```

---

### ChatMessage 模型更新

**文件**: `mobile/lib/core/models/chat_message.dart`

**新增欄位**:
```dart
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String senderId,
    required String receiverId,
    String? senderName,
    String? receiverName,
    required String messageText,
    String? translatedText,                // 保留（向後兼容）
    required DateTime createdAt,
    DateTime? readAt,
    
    // 新增：偵測到的語言
    @Default('zh-TW') String detectedLang,  // 偵測到的語言
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
```

**更新 fromFirestore 方法**:
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
    translatedText: data['translatedText'],
    createdAt: _parseTimestamp(data['createdAt']),
    readAt: _parseOptionalTimestamp(data['readAt']),
    
    // 新增欄位
    detectedLang: data['detectedLang'] ?? 'zh-TW',  // 默認繁體中文
  );
}
```

---

## 📊 實施進度

### 任務清單

- [ ] **1.1 更新 UserProfile 模型**
  - [ ] 修改 `user_profile.dart`
  - [ ] 運行 `flutter pub run build_runner build`
  - [ ] 測試編譯

- [ ] **1.2 更新 ChatRoom 模型**
  - [ ] 修改 `chat_room.dart`
  - [ ] 運行 `flutter pub run build_runner build`
  - [ ] 測試編譯

- [ ] **1.3 更新 ChatMessage 模型**
  - [ ] 修改 `chat_message.dart`
  - [ ] 運行 `flutter pub run build_runner build`
  - [ ] 測試編譯

- [ ] **1.4 更新 Firestore 安全規則**
  - [ ] 修改 `firebase/firestore.rules`
  - [ ] 部署規則：`firebase deploy --only firestore:rules`
  - [ ] 測試規則

- [ ] **1.5 創建數據遷移腳本**
  - [ ] 創建 `add-user-language-preferences.js`
  - [ ] 創建 `add-chat-room-member-ids.js`
  - [ ] 創建 `add-message-detected-lang.js`（可選）
  - [ ] 測試遷移腳本

- [ ] **1.6 執行數據遷移**
  - [ ] 執行用戶語言偏好遷移
  - [ ] 執行聊天室成員列表遷移
  - [ ] 驗證遷移結果

---

## ⚠️ 重要注意事項

### 向後兼容性

1. **保留現有欄位**: `translatedText` 和 `translations` 欄位將保留，以確保舊訊息仍然可以顯示翻譯
2. **默認值**: 所有新欄位都有默認值，確保舊數據仍然可以正常工作
3. **逐步遷移**: 不會立即刪除自動翻譯功能，而是逐步停用

### 數據遷移風險

1. **大量數據**: 如果有大量用戶和訊息，遷移可能需要較長時間
2. **Firestore 配額**: 注意 Firestore 讀寫配額限制
3. **測試環境**: 建議先在測試環境中執行遷移腳本

### 安全規則變更

1. **memberIds 檢查**: 新的安全規則使用 `memberIds` 數組，確保遷移腳本正確設置此欄位
2. **語言設定權限**: 用戶只能修改自己的語言設定
3. **向後兼容**: 保留對 `customerId` 和 `driverId` 的檢查，以支持舊數據

---

## 🧪 測試計劃

### 單元測試

- [ ] 測試 `UserProfile.fromJson` 和 `toJson`
- [ ] 測試 `ChatRoom.fromFirestore` 和 `toFirestore`
- [ ] 測試 `ChatMessage.fromFirestore` 和 `toFirestore`

### 整合測試

- [ ] 測試用戶語言偏好讀寫
- [ ] 測試聊天室成員列表讀寫
- [ ] 測試訊息 `detectedLang` 欄位讀寫

### Firestore 規則測試

- [ ] 測試用戶只能讀取自己的語言設定
- [ ] 測試用戶只能更新自己的語言設定
- [ ] 測試聊天室成員可以讀取聊天室
- [ ] 測試非成員無法讀取聊天室

---

## 📚 相關文檔

- ✅ `docs/multi-language-translation-implementation-plan.md` - 完整實施計劃
- ✅ `docs/phase-0-preparation-summary.md` - 階段 0 總結
- ✅ `docs/phase-1-data-model-summary.md` - 階段 1 總結（本文檔）

---

## 🎯 下一步

完成階段 1 後，將進入**階段 2: 首次登入語言選擇**，包括：
- 創建語言精靈畫面
- 偵測系統語言並預選
- 完成後寫入 `users/{uid}.preferredLang`

---

**文檔創建時間**: 2025-10-17  
**最後更新**: 2025-10-17  
**狀態**: 🚧 進行中

