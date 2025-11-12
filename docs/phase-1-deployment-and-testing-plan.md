# 階段 1: 部署與測試計劃

**日期**: 2025-10-17  
**狀態**: 準備執行  
**前置條件**: 階段 1 代碼變更已提交到 Git

---

## 📋 執行步驟

### 步驟 1: 部署 Firestore 安全規則 ✅

**目的**: 更新 Firestore 安全規則以支持新的語言偏好欄位

**執行命令**:
```bash
cd firebase
firebase deploy --only firestore:rules
```

**預期結果**:
- ✅ Firestore 規則部署成功
- ✅ 新規則立即生效

**驗證方法**:
```bash
firebase firestore:rules:get
```

---

### 步驟 2: 執行資料遷移腳本 ⏳

**前置條件**: 
- 需要設置 Firebase Service Account Key
- 參考文檔: `firebase/migrations/README.md`

#### 2.1 設置 Service Account Key

**步驟**:
1. 前往 Firebase Console > Project Settings > Service Accounts
2. 點擊 "Generate New Private Key"
3. 下載 JSON 檔案並保存為 `firebase/service-account-key.json`
4. 確保 `.gitignore` 包含 `service-account-key.json`

#### 2.2 執行遷移腳本

**執行順序**:

**2.2.1 遷移用戶語言偏好**:
```bash
cd firebase/migrations
node add-user-language-preferences.js
```

**預期結果**:
- 為所有現有用戶添加語言偏好欄位
- 設置預設值：`preferredLang: 'zh-TW'`, `inputLangHint: 'zh-TW'`, `hasCompletedLanguageWizard: false`
- 顯示遷移進度和結果

**2.2.2 遷移聊天室成員列表**:
```bash
cd firebase/migrations
node add-chat-room-member-ids.js
```

**預期結果**:
- 為所有現有聊天室添加 `memberIds` 欄位
- 從 `customerId` 和 `driverId` 生成 `memberIds`
- 顯示遷移進度和結果

**2.2.3 （可選）遷移訊息語言偵測**:
```bash
cd firebase/migrations
node add-message-detected-lang.js
```

**注意**: 這個遷移是可選的，因為新訊息會自動包含 `detectedLang` 欄位。

**預期結果**:
- 為現有訊息添加 `detectedLang` 欄位
- 設置預設值：`detectedLang: 'zh-TW'`
- 限制處理 100 個聊天室

---

### 步驟 3: 創建測試用例 ⏳

#### 3.1 Flutter 資料模型測試

**測試檔案**: `mobile/test/models/phase1_data_model_test.dart`

**測試內容**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ride_platform/core/models/user_profile.dart';
import 'package:ride_platform/core/models/chat_room.dart';
import 'package:ride_platform/core/models/chat_message.dart';

void main() {
  group('Phase 1: Data Model Tests', () {
    test('UserProfile should have default language preferences', () {
      final user = UserProfile(
        id: 'test-id',
        userId: 'test-user-id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      expect(user.preferredLang, 'zh-TW');
      expect(user.inputLangHint, 'zh-TW');
      expect(user.hasCompletedLanguageWizard, false);
    });
    
    test('ChatRoom should have default memberIds', () {
      final room = ChatRoom(
        bookingId: 'test-booking-id',
        customerId: 'customer-id',
        driverId: 'driver-id',
      );
      
      expect(room.memberIds, []);
      expect(room.roomLangOverride, null);
    });
    
    test('ChatMessage should have default detectedLang', () {
      final message = ChatMessage(
        id: 'test-message-id',
        senderId: 'sender-id',
        receiverId: 'receiver-id',
        messageText: 'Hello',
        createdAt: DateTime.now(),
      );
      
      expect(message.detectedLang, 'zh-TW');
    });
    
    test('UserProfile should serialize and deserialize correctly', () {
      final user = UserProfile(
        id: 'test-id',
        userId: 'test-user-id',
        preferredLang: 'en',
        inputLangHint: 'ja',
        hasCompletedLanguageWizard: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final json = user.toJson();
      final deserialized = UserProfile.fromJson(json);
      
      expect(deserialized.preferredLang, 'en');
      expect(deserialized.inputLangHint, 'ja');
      expect(deserialized.hasCompletedLanguageWizard, true);
    });
  });
}
```

**執行測試**:
```bash
cd mobile
flutter test test/models/phase1_data_model_test.dart
```

#### 3.2 Firestore 安全規則測試

**測試檔案**: `firebase/test/firestore-rules-phase1.test.js`

**測試內容**:
```javascript
const { assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { initializeTestEnvironment, RulesTestEnvironment } = require('@firebase/rules-unit-testing');
const fs = require('fs');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'test-project',
    firestore: {
      rules: fs.readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('Phase 1: Firestore Security Rules Tests', () => {
  test('User can read their own language preferences', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('alice').set({
        id: 'alice',
        userId: 'alice',
        preferredLang: 'zh-TW',
        inputLangHint: 'zh-TW',
        hasCompletedLanguageWizard: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });
    
    await assertSucceeds(alice.firestore().collection('users').doc('alice').get());
  });
  
  test('User can update their own language preferences', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('alice').set({
        id: 'alice',
        userId: 'alice',
        preferredLang: 'zh-TW',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });
    
    await assertSucceeds(
      alice.firestore().collection('users').doc('alice').update({
        preferredLang: 'en',
        inputLangHint: 'en',
        hasCompletedLanguageWizard: true,
      })
    );
  });
  
  test('User cannot read other users language preferences', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('bob').set({
        id: 'bob',
        userId: 'bob',
        preferredLang: 'zh-TW',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });
    
    await assertFails(alice.firestore().collection('users').doc('bob').get());
  });
  
  test('Chat room members can update roomLangOverride', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
        createdAt: new Date(),
      });
    });
    
    await assertSucceeds(
      alice.firestore().collection('chat_rooms').doc('room1').update({
        roomLangOverride: 'en',
      })
    );
  });
  
  test('New messages must include detectedLang field', async () => {
    const alice = testEnv.authenticatedContext('alice');
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('chat_rooms').doc('room1').set({
        bookingId: 'booking1',
        customerId: 'alice',
        driverId: 'bob',
        memberIds: ['alice', 'bob'],
      });
    });
    
    // Should fail without detectedLang
    await assertFails(
      alice.firestore()
        .collection('chat_rooms').doc('room1')
        .collection('messages').add({
          senderId: 'alice',
          receiverId: 'bob',
          messageText: 'Hello',
          createdAt: new Date(),
        })
    );
    
    // Should succeed with detectedLang
    await assertSucceeds(
      alice.firestore()
        .collection('chat_rooms').doc('room1')
        .collection('messages').add({
          senderId: 'alice',
          receiverId: 'bob',
          messageText: 'Hello',
          detectedLang: 'en',
          createdAt: new Date(),
        })
    );
  });
});
```

**執行測試**:
```bash
cd firebase
npm install --save-dev @firebase/rules-unit-testing
npm test
```

---

### 步驟 4: 驗證部署結果 ⏳

#### 4.1 驗證 Firestore 規則

**方法 1: Firebase Console**
1. 前往 Firebase Console > Firestore Database > Rules
2. 確認規則已更新
3. 檢查規則版本和時間戳

**方法 2: Firebase CLI**
```bash
firebase firestore:rules:get
```

#### 4.2 驗證資料遷移

**方法 1: Firebase Console**
1. 前往 Firebase Console > Firestore Database > Data
2. 檢查 `users` 集合中的文檔是否包含新欄位
3. 檢查 `chat_rooms` 集合中的文檔是否包含 `memberIds`
4. 檢查 `messages` 集合中的文檔是否包含 `detectedLang`

**方法 2: 執行驗證腳本**
```bash
cd firebase/migrations
node add-user-language-preferences.js --verify
node add-chat-room-member-ids.js --verify
```

#### 4.3 驗證 Flutter App

**方法 1: 單元測試**
```bash
cd mobile
flutter test
```

**方法 2: 手動測試**
1. 啟動 Flutter App（客戶端或司機端）
2. 登入測試帳號
3. 檢查用戶資料是否包含語言偏好欄位
4. 檢查聊天室資料是否包含 `memberIds`
5. 發送測試訊息，檢查是否包含 `detectedLang`

---

## 📊 測試檢查清單

### Firestore 安全規則測試
- [ ] 用戶可以讀取自己的語言設定
- [ ] 用戶可以更新自己的語言設定
- [ ] 用戶無法修改其他用戶的語言設定
- [ ] 聊天室成員可以更新 `roomLangOverride`
- [ ] 新訊息必須包含 `detectedLang` 欄位

### 資料模型測試
- [ ] UserProfile 模型可以正確序列化和反序列化
- [ ] ChatRoom 模型可以正確序列化和反序列化
- [ ] ChatMessage 模型可以正確序列化和反序列化
- [ ] 新增欄位的預設值正確

### 資料遷移測試
- [ ] 用戶語言偏好遷移成功
- [ ] 聊天室成員列表遷移成功
- [ ] 訊息語言偵測遷移成功（可選）
- [ ] 遷移後資料完整性驗證

### 整合測試
- [ ] Flutter App 可以讀取用戶語言偏好
- [ ] Flutter App 可以更新用戶語言偏好
- [ ] Flutter App 可以讀取聊天室 `memberIds`
- [ ] Flutter App 可以更新聊天室 `roomLangOverride`
- [ ] Flutter App 發送的新訊息包含 `detectedLang`

---

## 🚨 回滾計劃

如果部署或測試失敗，執行以下回滾步驟：

### 回滾 Firestore 安全規則

**步驟**:
1. 恢復備份的規則檔案：
   ```bash
   cp firebase/firestore.rules.backup firebase/firestore.rules
   ```

2. 重新部署規則：
   ```bash
   cd firebase
   firebase deploy --only firestore:rules
   ```

### 回滾資料遷移

**注意**: 資料遷移無法自動回滾，需要手動處理。

**選項 1: 刪除新增的欄位**（不推薦，可能導致資料丟失）

**選項 2: 保留新增的欄位**（推薦）
- 新增的欄位不會影響現有功能
- 可以在下次部署時修復問題

---

## 📝 執行記錄

### 部署記錄

**Firestore 安全規則部署**:
- 執行時間: _待填寫_
- 執行結果: _待填寫_
- 錯誤訊息: _待填寫_

**資料遷移執行**:
- 用戶語言偏好遷移: _待填寫_
- 聊天室成員列表遷移: _待填寫_
- 訊息語言偵測遷移: _待填寫_

### 測試記錄

**單元測試**:
- Flutter 資料模型測試: _待填寫_
- Firestore 安全規則測試: _待填寫_

**整合測試**:
- Flutter App 測試: _待填寫_

---

## ✅ 完成確認

在開始階段 2 之前，請確認以下事項：

- [ ] Firestore 安全規則已成功部署
- [ ] 資料遷移已成功執行
- [ ] 所有測試用例已通過
- [ ] 驗證結果符合預期
- [ ] 沒有發現任何錯誤或問題
- [ ] 已創建部署和測試記錄

---

**準備好開始階段 2 了嗎？** 🚀

