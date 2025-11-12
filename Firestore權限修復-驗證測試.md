# Firestore 權限修復 - 驗證測試

**日期**：2025-10-08  
**狀態**：✅ Firestore 規則已部署成功  
**部署時間**：剛剛完成

---

## ✅ 部署結果

### Firebase CLI 部署輸出
```
=== Deploying to 'ride-platform-f1676'...

i  deploying firestore
i  firestore: ensuring required API firestore.googleapis.com is enabled...
i  cloud.firestore: checking firestore.rules for compilation errors...
✔  cloud.firestore: rules file firestore.rules compiled successfully
i  firestore: latest version of firestore.rules already up to date, skipping upload...
✔  firestore: released rules firestore.rules to cloud.firestore

✔  Deploy complete!
```

**結果**：
- ✅ 規則編譯成功
- ✅ 規則已發布到 Cloud Firestore
- ✅ 部署完成

---

## 🧪 驗證測試步驟

### 測試 1：驗證規則已更新（Firebase Console）

#### 步驟
1. 打開 Firebase Console
2. 前往：https://console.firebase.google.com/project/ride-platform-f1676/firestore/rules
3. 檢查規則內容

#### 預期結果
應該看到以下規則：

**orders_rt 集合**：
```javascript
match /orders_rt/{orderId} {
  allow read: if request.auth != null
              && (
                !exists(/databases/$(database)/documents/orders_rt/$(orderId))
                ||
                resource.data.customerId == request.auth.uid
              );
  allow write: if false;
}
```

**bookings 集合**：
```javascript
match /bookings/{bookingId} {
  allow read: if request.auth != null &&
    (
      !exists(/databases/$(database)/documents/bookings/$(bookingId))
      ||
      (request.auth.uid == resource.data.customerId ||
       request.auth.uid == resource.data.driverId)
    );
  allow write: if false;
}
```

---

### 測試 2：測試完整訂單創建流程（最重要）⭐

#### 步驟
1. 啟動客戶端 App
   ```bash
   cd d:/repo/mobile
   flutter run --flavor customer --target lib/apps/customer/main_customer.dart
   ```

2. 登入測試帳號

3. 創建新訂單
   - 選擇上車地點
   - 選擇下車地點
   - 選擇預約時間
   - 選擇乘客人數
   - 點擊「確認預約」

4. 支付訂金
   - 選擇支付方式
   - 點擊「確認支付」

5. 觀察「預約成功」頁面

#### 預期結果
- ✅ **不顯示 `permission-denied` 錯誤**
- ✅ 頁面顯示「載入中」（CircularProgressIndicator）
- ✅ 等待幾秒後（Edge Function 同步）
- ✅ 顯示完整的訂單資訊：
  - 訂單編號
  - 上車地點
  - 下車地點
  - 預約時間
  - 乘客人數
  - 訂單狀態

#### 如果出現問題
- ❌ 如果仍然顯示 `permission-denied`：
  - 等待 30 秒（規則可能需要時間生效）
  - 重新啟動 App
  - 檢查 Firebase Console 確認規則已更新

- ❌ 如果顯示「訂單不存在」：
  - 這是正常的（Edge Function 還沒同步）
  - 等待幾秒鐘
  - 應該會自動更新顯示訂單資訊

---

### 測試 3：測試讀取不存在的文檔

#### 測試代碼（可選）
在客戶端 App 中添加測試代碼：

```dart
// 在某個測試頁面或按鈕的 onPressed 中
Future<void> testReadNonExistentDocument() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('orders_rt')
        .doc('non-existent-order-id-12345')
        .get();

    print('✅ 測試通過：可以讀取不存在的文檔');
    print('文檔存在: ${doc.exists}');  // 應該是 false
    print('資料: ${doc.data()}');      // 應該是 null
  } catch (e) {
    print('❌ 測試失敗: $e');
  }
}
```

#### 預期結果
```
✅ 測試通過：可以讀取不存在的文檔
文檔存在: false
資料: null
```

#### 如果失敗
```
❌ 測試失敗: [cloud_firestore/permission-denied] ...
```
→ 表示規則尚未生效，等待幾分鐘後重試

---

### 測試 4：測試監聽訂單變化（Stream）

#### 測試代碼（可選）
```dart
// 監聽一個剛創建的訂單
void testWatchBooking(String orderId) {
  print('開始監聽訂單: $orderId');
  
  FirebaseFirestore.instance
      .collection('orders_rt')
      .doc(orderId)
      .snapshots()
      .listen((doc) {
        if (doc.exists) {
          print('✅ 訂單已同步: ${doc.data()}');
        } else {
          print('⏳ 訂單尚未同步（等待 Edge Function）');
        }
      },
      onError: (error) {
        print('❌ 錯誤: $error');
      });
}
```

#### 預期結果
```
開始監聽訂單: mock_booking_1234567890
⏳ 訂單尚未同步（等待 Edge Function）
⏳ 訂單尚未同步（等待 Edge Function）
✅ 訂單已同步: {id: mock_booking_1234567890, status: matched, ...}
```

---

### 測試 5：驗證安全性（確保仍然禁止寫入）

#### 測試代碼（可選）
```dart
// 嘗試寫入 orders_rt 集合（應該失敗）
Future<void> testWritePermission() async {
  try {
    await FirebaseFirestore.instance
        .collection('orders_rt')
        .doc('test-order-id')
        .set({
          'customerId': 'test-user',
          'status': 'pending',
        });
    
    print('❌ 安全性測試失敗：不應該允許寫入');
  } catch (e) {
    if (e.toString().contains('permission-denied')) {
      print('✅ 安全性測試通過：正確禁止寫入');
    } else {
      print('❌ 未預期的錯誤: $e');
    }
  }
}
```

#### 預期結果
```
✅ 安全性測試通過：正確禁止寫入
```

---

## 📊 測試檢查清單

### 部署驗證
- [x] Firebase CLI 部署成功
- [x] 規則編譯成功
- [x] 規則已發布到 Cloud Firestore
- [ ] Firebase Console 顯示最新規則

### 功能測試
- [ ] 完整訂單創建流程（不顯示 permission-denied）
- [ ] 「預約成功」頁面正常顯示
- [ ] 訂單資訊正確顯示
- [ ] 讀取不存在的文檔（不報錯）
- [ ] 監聽訂單變化（Stream 正常）

### 安全性測試
- [ ] 仍然禁止客戶端寫入 orders_rt
- [ ] 仍然禁止客戶端寫入 bookings
- [ ] 只能讀取自己的訂單
- [ ] 不能讀取別人的訂單

---

## 🔍 故障排除

### 問題 1：規則部署後仍然出現 permission-denied

**可能原因**：
- 規則需要幾秒鐘才能生效
- App 緩存了舊的規則

**解決方案**：
1. 等待 30-60 秒
2. 重新啟動客戶端 App
3. 清除 App 緩存
4. 檢查 Firebase Console 確認規則已更新

---

### 問題 2：「預約成功」頁面顯示「訂單不存在」

**這是正常的！**

**原因**：
- Edge Function 還沒同步訂單到 Firestore
- Cron Job 每 30 秒執行一次

**預期行為**：
1. 初始顯示「載入中」或「訂單不存在」
2. 等待幾秒到 30 秒
3. Edge Function 同步完成
4. 頁面自動更新顯示訂單資訊

**如果超過 1 分鐘仍未顯示**：
1. 檢查 Supabase `outbox` 表是否有事件
2. 檢查 Edge Function 日誌
3. 手動觸發 Edge Function

---

### 問題 3：測試時出現其他錯誤

**錯誤訊息**：
```
[cloud_firestore/unavailable] The service is currently unavailable
```

**解決方案**：
- 這是網路問題，不是規則問題
- 檢查網路連接
- 稍後重試

---

## 💡 測試技巧

### 1. 使用 Flutter DevTools 查看日誌

```bash
# 啟動 App 時查看詳細日誌
flutter run --flavor customer --target lib/apps/customer/main_customer.dart --verbose
```

**查看**：
- Firestore 讀取請求
- 權限錯誤訊息
- 文檔快照變化

---

### 2. 使用 Firebase Console 監控

**步驟**：
1. 打開 Firebase Console
2. 前往 Firestore Database
3. 查看 `orders_rt` 集合
4. 觀察文檔何時被創建

---

### 3. 檢查 Supabase Outbox

**步驟**：
1. 打開 Supabase Dashboard
2. 前往 Table Editor
3. 查看 `outbox` 表
4. 確認有新事件且 `processed_at` 為 NULL

**SQL 查詢**：
```sql
SELECT 
  id,
  aggregate_type,
  aggregate_id,
  event_type,
  created_at,
  processed_at
FROM outbox
WHERE processed_at IS NULL
ORDER BY created_at DESC
LIMIT 10;
```

---

## 📈 預期時間線

### 正常流程時間線

```
T+0s:  用戶點擊「確認支付」
T+1s:  Supabase API 處理支付
T+2s:  跳轉到「預約成功」頁面
T+2s:  頁面嘗試讀取 Firestore（文檔不存在，返回 null）
T+2s:  顯示「載入中」或「訂單不存在」
T+5s:  (等待 Cron Job)
T+10s: (等待 Cron Job)
T+15s: (等待 Cron Job)
T+20s: (等待 Cron Job)
T+25s: (等待 Cron Job)
T+30s: Cron Job 執行 Edge Function
T+31s: Edge Function 同步到 Firestore
T+32s: Firestore 觸發 snapshot 更新
T+32s: 頁面自動顯示訂單資訊 ✅
```

**關鍵點**：
- 前 30 秒：文檔不存在（正常）
- 30 秒後：文檔同步完成
- 頁面自動更新（使用 Stream）

---

## ✅ 成功標準

### 修復成功的標誌

1. **不再出現 permission-denied 錯誤** ⭐
   - 這是最重要的指標
   - 即使文檔不存在也不報錯

2. **頁面正常顯示載入狀態**
   - 顯示 CircularProgressIndicator
   - 或顯示「訂單不存在」（暫時的）

3. **等待後自動顯示訂單**
   - 不需要手動刷新
   - Stream 自動更新

4. **安全性保持不變**
   - 仍然禁止寫入
   - 仍然只能讀取自己的訂單

---

## 📚 相關文檔

1. **`firebase/firestore.rules`**
   - 修改後的 Firestore 規則

2. **`Firestore權限錯誤修復-部署指南.md`**
   - 詳細的部署指南

3. **`docs/20251008_0738_15_Firestore權限錯誤修復.md`**
   - 開發歷程文檔

4. **Firebase Console**
   - https://console.firebase.google.com/project/ride-platform-f1676/firestore/rules

---

**部署狀態**：✅ 已完成  
**規則生效**：✅ 已生效  
**測試狀態**：⏳ 待執行

🚀 **請立即測試完整訂單創建流程，確認不再出現 permission-denied 錯誤！**

**最重要的測試**：
1. 創建新訂單
2. 支付訂金
3. 觀察「預約成功」頁面
4. ✅ 不應該顯示 permission-denied 錯誤
5. ✅ 應該顯示「載入中」或等待後顯示訂單資訊

