# Firestore 權限錯誤修復 - 部署指南

**日期**：2025-10-08  
**問題**：訂單創建後跳轉到「預約成功」頁面時出現 `permission-denied` 錯誤  
**狀態**：✅ 已修復，待部署

---

## 🔍 問題診斷

### 錯誤訊息
```
[cloud_firestore/permission-denied] 
The caller does not have permission to execute the specified operation.
```

### 發生時機
1. 用戶完成支付流程
2. 跳轉到「預約成功」頁面
3. 頁面嘗試從 Firestore 讀取訂單資料
4. ❌ 權限錯誤

---

### 根本原因

**Firestore 規則問題**：

**修復前的規則**（錯誤）：
```javascript
match /orders_rt/{orderId} {
  allow read: if request.auth != null
              && resource.data.customerId == request.auth.uid;
}
```

**問題**：
- `resource.data` 只在文檔**已經存在**時才有值
- 如果文檔不存在（Edge Function 還沒同步），`resource.data` 為 null
- 導致權限檢查失敗 → `permission-denied`

---

### 時序問題

```
1. 用戶支付訂金
   ↓
2. Supabase API 處理支付
   ↓
3. 寫入 Supabase bookings 表
   ↓
4. Trigger 寫入 outbox 表
   ↓
5. 跳轉到「預約成功」頁面 ⭐
   ↓
6. 頁面嘗試讀取 Firestore orders_rt/{orderId}
   ↓
7. ❌ 文檔還不存在（Edge Function 還沒執行）
   ↓
8. ❌ resource.data 為 null
   ↓
9. ❌ 權限檢查失敗 → permission-denied
   ↓
10. (30 秒後) Cron Job 執行 Edge Function
   ↓
11. Edge Function 同步到 Firestore
   ↓
12. 文檔現在存在了（但用戶已經看到錯誤）
```

---

## 🔧 修復方案

### 修改 Firestore 規則

**修復後的規則**（正確）：

#### orders_rt 集合
```javascript
match /orders_rt/{orderId} {
  // 允許用戶讀取自己的訂單
  // 注意：使用 exists() 來允許讀取不存在的文檔（返回 null）
  // 這樣可以避免在 Edge Function 同步延遲時出現權限錯誤
  allow read: if request.auth != null
              && (
                // 文檔不存在時允許讀取（會返回 null）
                !exists(/databases/$(database)/documents/orders_rt/$(orderId))
                ||
                // 文檔存在時檢查是否為用戶自己的訂單
                resource.data.customerId == request.auth.uid
              );

  // 禁止客戶端寫入（由 Supabase 寫入）
  allow write: if false;
}
```

#### bookings 集合
```javascript
match /bookings/{bookingId} {
  // 允許用戶讀取自己的訂單
  // 注意：使用 exists() 來允許讀取不存在的文檔（返回 null）
  // 這樣可以避免在 Edge Function 同步延遲時出現權限錯誤
  allow read: if request.auth != null &&
    (
      // 文檔不存在時允許讀取（會返回 null）
      !exists(/databases/$(database)/documents/bookings/$(bookingId))
      ||
      // 文檔存在時檢查是否為用戶自己的訂單
      (request.auth.uid == resource.data.customerId ||
       request.auth.uid == resource.data.driverId)
    );

  // 禁止客戶端寫入（由 Supabase Edge Function 寫入）
  allow write: if false;
}
```

---

### 修復效果

**修復前**：
```
文檔不存在 → resource.data 為 null → 權限檢查失敗 → permission-denied
```

**修復後**：
```
文檔不存在 → exists() 返回 false → 允許讀取 → 返回 null（不報錯）
文檔存在 → 檢查 customerId → 允許讀取 → 返回文檔資料
```

---

## 🚀 部署步驟

### 方法 A：使用 Firebase CLI（推薦）

#### 步驟 1：確認 Firebase CLI 已安裝
```bash
firebase --version
```

如果未安裝：
```bash
npm install -g firebase-tools
```

---

#### 步驟 2：登入 Firebase
```bash
firebase login
```

---

#### 步驟 3：部署 Firestore 規則
```bash
# 進入專案根目錄
cd d:/repo

# 部署規則
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

### 方法 B：使用 Firebase Console（手動）

#### 步驟 1：打開 Firebase Console
1. 前往：https://console.firebase.google.com
2. 選擇您的專案

---

#### 步驟 2：進入 Firestore 規則編輯器
1. 左側選單 → Firestore Database
2. 點擊「規則」標籤

---

#### 步驟 3：複製並貼上新規則
1. 打開 `firebase/firestore.rules` 文件
2. 複製全部內容
3. 貼上到 Firebase Console 的規則編輯器
4. 點擊「發布」按鈕

---

#### 步驟 4：確認部署成功
- 查看頁面頂部的訊息
- 應該顯示「規則已發布」

---

## ✅ 驗證步驟

### 測試 1：讀取不存在的文檔（應該成功）

**測試代碼**（在客戶端 App 中）：
```dart
// 嘗試讀取一個不存在的訂單
final doc = await FirebaseFirestore.instance
    .collection('orders_rt')
    .doc('non-existent-order-id')
    .get();

print('文檔存在: ${doc.exists}');  // 應該輸出: false
print('資料: ${doc.data()}');      // 應該輸出: null
```

**預期結果**：
- ✅ 不拋出 `permission-denied` 錯誤
- ✅ `doc.exists` 為 `false`
- ✅ `doc.data()` 為 `null`

---

### 測試 2：讀取存在的文檔（應該成功）

**測試代碼**：
```dart
// 嘗試讀取一個存在的訂單（自己的）
final doc = await FirebaseFirestore.instance
    .collection('orders_rt')
    .doc('existing-order-id')
    .get();

print('文檔存在: ${doc.exists}');  // 應該輸出: true
print('訂單 ID: ${doc.data()?['id']}');
```

**預期結果**：
- ✅ 不拋出 `permission-denied` 錯誤
- ✅ `doc.exists` 為 `true`
- ✅ 可以讀取訂單資料

---

### 測試 3：完整訂單創建流程（最重要）⭐

**測試步驟**：
1. 啟動客戶端 App
2. 登入測試帳號
3. 創建新訂單
4. 支付訂金
5. 等待跳轉到「預約成功」頁面

**預期結果**：
- ✅ 不顯示 `permission-denied` 錯誤
- ✅ 頁面顯示「載入中」（CircularProgressIndicator）
- ✅ 等待 Edge Function 同步後，顯示訂單資訊
- ✅ 如果同步延遲，頁面可能暫時顯示「訂單不存在」，但不會報錯

---

### 測試 4：監聽訂單變化（Stream）

**測試代碼**：
```dart
// 監聽訂單變化
FirebaseFirestore.instance
    .collection('orders_rt')
    .doc('order-id')
    .snapshots()
    .listen((doc) {
      if (doc.exists) {
        print('訂單資料: ${doc.data()}');
      } else {
        print('訂單尚未同步');
      }
    });
```

**預期結果**：
- ✅ 不拋出 `permission-denied` 錯誤
- ✅ 初始時可能收到 `doc.exists = false`
- ✅ Edge Function 同步後收到 `doc.exists = true`

---

## 🔍 故障排除

### 問題 1：部署後仍然出現權限錯誤

**可能原因**：
- 規則尚未生效（需要幾秒鐘）
- 瀏覽器緩存

**解決方案**：
1. 等待 30 秒
2. 重新啟動客戶端 App
3. 清除瀏覽器緩存（如果是 Web 版）
4. 檢查 Firebase Console 確認規則已更新

---

### 問題 2：Firebase CLI 部署失敗

**錯誤訊息**：
```
Error: HTTP Error: 403, The caller does not have permission
```

**解決方案**：
1. 確認已登入正確的 Google 帳號
2. 確認帳號有專案的編輯權限
3. 重新登入：
   ```bash
   firebase logout
   firebase login
   ```

---

### 問題 3：規則語法錯誤

**錯誤訊息**：
```
Error: firestore.rules compilation failed
```

**解決方案**：
1. 檢查規則語法
2. 確認括號匹配
3. 確認路徑格式正確
4. 使用 Firebase Console 的規則編輯器檢查語法

---

## 💡 關鍵要點

### 1. exists() 函數的作用

**語法**：
```javascript
exists(/databases/$(database)/documents/collection/$(docId))
```

**作用**：
- 檢查文檔是否存在
- 返回 `true` 或 `false`
- 不會拋出權限錯誤

**使用場景**：
- 允許讀取不存在的文檔（返回 null）
- 避免同步延遲導致的權限錯誤

---

### 2. resource.data 的限制

**問題**：
- `resource.data` 只在文檔存在時有值
- 文檔不存在時為 null
- 使用 `resource.data.field` 會導致權限檢查失敗

**解決方案**：
- 先用 `exists()` 檢查文檔是否存在
- 文檔不存在時允許讀取
- 文檔存在時再檢查 `resource.data`

---

### 3. CQRS 架構的同步延遲

**問題**：
- Supabase 寫入 → Outbox → Cron Job → Edge Function → Firestore
- 整個流程可能需要 1-30 秒
- 客戶端可能在同步完成前嘗試讀取

**解決方案**：
- 允許讀取不存在的文檔（返回 null）
- 使用 Stream 監聽文檔變化
- 顯示「載入中」狀態

---

### 4. 安全性不受影響

**重要**：
- 修復後仍然禁止客戶端寫入（`allow write: if false`）
- 只允許讀取不存在的文檔（返回 null）
- 文檔存在時仍然檢查 `customerId`
- 不違反 CQRS 架構原則

---

## 📊 修改對比

| 項目 | 修復前 | 修復後 |
|------|--------|--------|
| **讀取不存在的文檔** | ❌ permission-denied | ✅ 返回 null |
| **讀取自己的訂單** | ✅ 成功 | ✅ 成功 |
| **讀取別人的訂單** | ❌ permission-denied | ❌ permission-denied |
| **寫入操作** | ❌ 禁止 | ❌ 禁止 |
| **安全性** | ✅ 安全 | ✅ 安全 |

---

## 📚 相關文檔

1. **`firebase/firestore.rules`**
   - Firestore 安全規則文件

2. **`docs/20251007_2305_13_CQRS架構修復第一階段完成.md`**
   - CQRS 架構修復報告

3. **`CQRS修復-Firestore規則部署指南.md`**
   - Firestore 規則部署指南

4. **Firebase 官方文檔**
   - https://firebase.google.com/docs/firestore/security/rules-conditions

---

**修復狀態**：✅ 已完成  
**部署狀態**：⏳ 待部署  
**測試狀態**：⏳ 待測試

🚀 **請立即部署 Firestore 規則並測試訂單創建流程！**

