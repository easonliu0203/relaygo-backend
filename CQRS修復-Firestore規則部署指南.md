# Firestore 規則部署指南

**日期**：2025-10-07  
**目的**：部署修改後的 Firestore 規則，禁止客戶端寫入 `bookings` 集合

---

## 📋 修改內容

### 修改前（錯誤）❌

```javascript
// 訂單規則（舊版 bookings 集合）
match /bookings/{bookingId} {
  allow read: if request.auth != null &&
    (request.auth.uid == resource.data.customerId ||
     request.auth.uid == resource.data.driverId);
  allow create: if request.auth != null &&
    request.auth.uid == request.resource.data.customerId;  // ❌ 允許創建
  allow update: if request.auth != null &&
    (request.auth.uid == resource.data.customerId ||
     request.auth.uid == resource.data.driverId);  // ❌ 允許更新
}
```

**問題**：
- 允許客戶端創建訂單
- 允許客戶端更新訂單
- 違反 CQRS 原則

---

### 修改後（正確）✅

```javascript
// 訂單規則（bookings 集合）
// 此集合由 Supabase Edge Function 自動同步，客戶端只能讀取
match /bookings/{bookingId} {
  // 允許用戶讀取自己的訂單
  allow read: if request.auth != null &&
    (request.auth.uid == resource.data.customerId ||
     request.auth.uid == resource.data.driverId);

  // 禁止客戶端寫入（由 Supabase Edge Function 寫入）
  // 所有寫入操作必須通過 Supabase API
  allow write: if false;
}
```

**改進**：
- ✅ 禁止客戶端寫入
- ✅ 強制使用 Supabase API
- ✅ 符合 CQRS 原則

---

## 🚀 部署步驟

### 方法 1：使用 Firebase CLI（推薦）

#### 步驟 1：安裝 Firebase CLI（如果尚未安裝）

```bash
npm install -g firebase-tools
```

#### 步驟 2：登入 Firebase

```bash
firebase login
```

#### 步驟 3：部署 Firestore 規則

```bash
# 進入專案根目錄
cd d:/repo

# 部署 Firestore 規則
firebase deploy --only firestore:rules
```

**預期輸出**：
```
=== Deploying to 'your-project-id'...

i  deploying firestore
i  firestore: checking firestore.rules for compilation errors...
✔  firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
✔  firestore: released rules firestore.rules to cloud.firestore

✔  Deploy complete!
```

---

### 方法 2：使用 Firebase Console（手動）

#### 步驟 1：打開 Firebase Console

1. 前往：https://console.firebase.google.com
2. 選擇專案

#### 步驟 2：進入 Firestore 規則頁面

1. 點擊左側選單「Firestore Database」
2. 點擊「規則」標籤

#### 步驟 3：複製並貼上新規則

1. 打開 `firebase/firestore.rules` 文件
2. 複製全部內容
3. 貼上到 Firebase Console 的規則編輯器
4. 點擊「發布」按鈕

---

## ✅ 驗證步驟

### 驗證 1：檢查規則是否部署成功

**使用 Firebase Console**：
1. 打開 Firebase Console → Firestore Database → 規則
2. 確認 `bookings` 集合的規則為：
   ```javascript
   allow write: if false;
   ```

---

### 驗證 2：測試客戶端無法寫入

**測試代碼**（在客戶端 App 中執行）：

```dart
// 測試 1：嘗試創建訂單（應該失敗）
try {
  await FirebaseFirestore.instance
      .collection('bookings')
      .add({
        'customerId': 'test-user-id',
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
  print('❌ 錯誤：客戶端可以寫入 bookings 集合');
} catch (e) {
  print('✅ 正確：客戶端無法寫入 bookings 集合');
  print('錯誤訊息：$e');
}

// 測試 2：嘗試更新訂單（應該失敗）
try {
  await FirebaseFirestore.instance
      .collection('bookings')
      .doc('some-id')
      .update({'status': 'cancelled'});
  print('❌ 錯誤：客戶端可以更新 bookings 集合');
} catch (e) {
  print('✅ 正確：客戶端無法更新 bookings 集合');
  print('錯誤訊息：$e');
}
```

**預期結果**：
```
✅ 正確：客戶端無法寫入 bookings 集合
錯誤訊息：[cloud_firestore/permission-denied] Missing or insufficient permissions.

✅ 正確：客戶端無法更新 bookings 集合
錯誤訊息：[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

---

### 驗證 3：測試客戶端可以讀取

**測試代碼**：

```dart
// 測試：讀取訂單（應該成功）
try {
  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .where('customerId', isEqualTo: currentUserId)
      .get();
  print('✅ 正確：客戶端可以讀取 bookings 集合');
  print('訂單數量：${snapshot.docs.length}');
} catch (e) {
  print('❌ 錯誤：客戶端無法讀取 bookings 集合');
  print('錯誤訊息：$e');
}
```

**預期結果**：
```
✅ 正確：客戶端可以讀取 bookings 集合
訂單數量：5
```

---

### 驗證 4：測試 Edge Function 可以寫入

**步驟**：
1. 手動觸發 Edge Function：
   ```
   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
   ```
2. 點擊 `sync-to-firestore` → Invoke
3. 檢查 Firestore `bookings` 集合是否有新訂單

**預期結果**：
- ✅ Edge Function 可以成功寫入 `bookings` 集合
- ✅ 使用 Service Account 繞過規則限制

---

## 🔍 故障排除

### 問題 1：部署失敗 - 找不到 Firebase CLI

**錯誤訊息**：
```
bash: firebase: command not found
```

**解決方案**：
```bash
# 安裝 Firebase CLI
npm install -g firebase-tools

# 驗證安裝
firebase --version
```

---

### 問題 2：部署失敗 - 未登入

**錯誤訊息**：
```
Error: Not logged in
```

**解決方案**：
```bash
# 登入 Firebase
firebase login

# 驗證登入狀態
firebase projects:list
```

---

### 問題 3：部署失敗 - 專案 ID 不正確

**錯誤訊息**：
```
Error: Invalid project id
```

**解決方案**：
1. 檢查 `.firebaserc` 文件
2. 確認專案 ID 正確
3. 或使用 `--project` 參數：
   ```bash
   firebase deploy --only firestore:rules --project your-project-id
   ```

---

### 問題 4：規則部署後客戶端仍然可以寫入

**可能原因**：
- 規則尚未生效（需要幾秒鐘）
- 客戶端緩存了舊規則

**解決方案**：
1. 等待 10-30 秒
2. 重新啟動客戶端 App
3. 清除 App 緩存
4. 檢查 Firebase Console 確認規則已更新

---

## 📊 部署檢查清單

- [ ] **安裝 Firebase CLI**
  - [ ] 執行：`npm install -g firebase-tools`
  - [ ] 驗證：`firebase --version`

- [ ] **登入 Firebase**
  - [ ] 執行：`firebase login`
  - [ ] 驗證：`firebase projects:list`

- [ ] **部署 Firestore 規則**
  - [ ] 執行：`firebase deploy --only firestore:rules`
  - [ ] 確認：看到「Deploy complete!」訊息

- [ ] **驗證規則**
  - [ ] 檢查 Firebase Console 規則頁面
  - [ ] 確認 `bookings` 集合規則為 `allow write: if false`

- [ ] **測試客戶端**
  - [ ] 測試無法創建訂單（應該失敗）
  - [ ] 測試無法更新訂單（應該失敗）
  - [ ] 測試可以讀取訂單（應該成功）

- [ ] **測試 Edge Function**
  - [ ] 手動觸發 Edge Function
  - [ ] 確認可以寫入 `bookings` 集合

---

## 📚 相關文檔

- `firebase/firestore.rules` - Firestore 規則文件
- `docs/20251007_0847_12_CQRS架構審查報告.md` - 架構審查報告
- `CQRS架構修復計劃.md` - 修復計劃

---

**部署狀態**：⏳ 待執行  
**預計時間**：5-10 分鐘  
**風險等級**：低（可以隨時回滾）

🚀 **請按照步驟執行部署，並完成所有驗證測試！**

