# 開發檢查清單

> **使用方法**：在開始任何開發工作前，複製此清單並逐項檢查。

---

## 📋 開發前準備

### 理解需求

- [ ] 我已經完全理解了需求
- [ ] 我知道這個功能涉及哪些資料表
- [ ] 我知道這個功能的資料流向（寫入/讀取）
- [ ] 我已經查閱了 [ARCHITECTURE.md](./ARCHITECTURE.md)

### 確認架構

- [ ] 我知道應該使用 CQRS 架構（寫入 Supabase，讀取 Firestore）
- [ ] 我知道應該使用哪個 ID 類型（`firebase_uid` vs `users.id`）
- [ ] 我知道資料應該通過 Backend API 寫入 Supabase
- [ ] 我知道資料應該從 Firestore 讀取（Flutter APP）

---

## 🔧 Backend API 開發

### 接收參數

- [ ] 我接收的是 `firebase_uid`（從 Flutter APP）
- [ ] 我已經驗證參數的有效性
- [ ] 我已經驗證用戶權限（是否有權執行此操作）

### ID 轉換

- [ ] 我已經查詢 `users` 表，將 `firebase_uid` 轉換為 `users.id`
- [ ] 我已經處理用戶不存在的情況（返回 404）
- [ ] 我已經記錄日誌（方便調試）

### 寫入 Supabase

- [ ] 我使用 `users.id` (UUID) 作為外鍵（`customer_id`, `driver_id`）
- [ ] 我已經驗證業務邏輯（如訂單狀態、金額計算等）
- [ ] 我已經處理錯誤情況（返回適當的 HTTP 狀態碼）
- [ ] 我已經返回必要的資料給 Flutter APP

### 代碼範例檢查

```typescript
// ✅ 檢查清單
router.post('/bookings', async (req, res) => {
  // [ ] 接收 firebase_uid
  const { customerUid } = req.body;
  
  // [ ] 驗證參數
  if (!customerUid) {
    return res.status(400).json({ error: 'customerUid is required' });
  }
  
  // [ ] 查詢 users 表，轉換 ID
  const { data: customer, error: userError } = await supabase
    .from('users')
    .select('id')
    .eq('firebase_uid', customerUid)
    .single();
  
  // [ ] 處理用戶不存在
  if (userError || !customer) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  // [ ] 使用 users.id 寫入 Supabase
  const { data: booking, error: bookingError } = await supabase
    .from('bookings')
    .insert({
      customer_id: customer.id, // ✅ 使用 users.id
      // ...
    })
    .select()
    .single();
  
  // [ ] 處理錯誤
  if (bookingError) {
    return res.status(500).json({ error: bookingError.message });
  }
  
  // [ ] 返回結果
  res.json({ success: true, data: booking });
});
```

---

## 🔄 Edge Function 開發

### 讀取 Supabase

- [ ] 我已經從 `outbox` 表讀取未處理的事件
- [ ] 我已經根據 `aggregate_type` 和 `event_type` 處理事件
- [ ] 我已經 JOIN `users` 表獲取 `firebase_uid`

### ID 轉換

- [ ] 我已經將 `users.id` (UUID) 轉換為 `firebase_uid`
- [ ] 我已經處理用戶不存在的情況
- [ ] 我已經記錄日誌（方便調試）

### 寫入 Firestore

- [ ] 我使用 `firebase_uid` 作為用戶 ID（`customerId`, `driverId`）
- [ ] 我已經映射訂單狀態（Supabase → Firestore）
- [ ] 我已經處理錯誤情況
- [ ] 我已經標記 `outbox` 記錄為已處理

### 代碼範例檢查

```typescript
// ✅ 檢查清單
async function syncBookingToFirestore(bookingId: string) {
  // [ ] 從 Supabase 讀取，JOIN users 表
  const { data: booking } = await supabase
    .from('bookings')
    .select(`
      *,
      customer:users!customer_id(firebase_uid),
      driver:users!driver_id(firebase_uid)
    `)
    .eq('id', bookingId)
    .single();
  
  // [ ] 處理不存在的情況
  if (!booking) {
    throw new Error('Booking not found');
  }
  
  // [ ] 映射狀態
  const statusMap = {
    'pending_payment': 'pending',
    'paid_deposit': 'matched',
    // ...
  };
  
  // [ ] 使用 firebase_uid 寫入 Firestore
  await firestore.collection('orders_rt').doc(booking.id).set({
    customerId: booking.customer.firebase_uid, // ✅ 使用 firebase_uid
    driverId: booking.driver?.firebase_uid || null, // ✅ 使用 firebase_uid
    status: statusMap[booking.status] || 'pending',
    // ...
  });
  
  // [ ] 標記為已處理
  await supabase
    .from('outbox')
    .update({ processed_at: new Date().toISOString() })
    .eq('aggregate_id', bookingId);
}
```

---

## 📱 Flutter APP 開發

### 環境配置檢查

- [ ] 我已經配置 `.env` 文件
- [ ] 我已經確認 `API_BASE_URL=http://localhost:3000/api`（固定端口）
- [ ] 我已經確認 `SUPABASE_URL` 正確
- [ ] 我已經確認 `FIREBASE_PROJECT_ID` 正確
- [ ] 我已經載入環境變數（`dotenv.load(fileName: ".env")`）

### Flavor 配置檢查

- [ ] 我知道客戶端使用 `--flavor customer --target lib/apps/customer/main_customer.dart`
- [ ] 我知道司機端使用 `--flavor driver --target lib/apps/driver/main_driver.dart`
- [ ] 我已經配置正確的 Flavor（Android: `android/app/build.gradle`）
- [ ] 我已經配置正確的 Bundle ID（iOS: `ios/Runner.xcodeproj`）

### 寫入操作

- [ ] 我**不**直接寫入 Firestore（違反 CQRS）
- [ ] 我**不**直接寫入 Supabase（違反 RLS）
- [ ] 我通過 Backend API 寫入（HTTP POST）
- [ ] 我傳遞 `firebase_uid` 給 Backend API
- [ ] 我已經處理 API 錯誤（顯示錯誤訊息）
- [ ] 我已經處理網路連接錯誤

### 讀取操作

- [ ] 我從 Firestore 讀取（即時查詢）
- [ ] 我使用 `firebase_uid` 查詢（`where customerId == currentUser.uid`）
- [ ] 我已經確認查詢有對應的索引
- [ ] 我已經處理空資料的情況
- [ ] 我已經處理錯誤情況
- [ ] 我已經處理權限錯誤（Firestore 安全規則）

### Firebase 初始化檢查

- [ ] 我已經初始化 Firebase Core（`Firebase.initializeApp()`）
- [ ] 我已經初始化 Supabase（`Supabase.initialize()`）
- [ ] 我已經初始化 Firebase Services（`FirebaseService().initialize()`）
- [ ] 初始化順序正確（Supabase → Firebase → Services）

### 代碼範例檢查

```dart
// ✅ 寫入檢查清單
Future<void> createBooking(BookingRequest request) async {
  // [ ] 獲取 firebase_uid
  final user = _auth.currentUser;
  if (user == null) throw Exception('User not logged in');

  // [ ] 使用環境變數中的 API URL
  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  // [ ] 通過 Backend API 寫入
  final response = await http.post(
    Uri.parse('$apiBaseUrl/bookings'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'customerUid': user.uid, // ✅ 傳遞 firebase_uid
      // ...
    }),
  );

  // [ ] 處理錯誤
  if (response.statusCode != 200) {
    throw Exception('Failed to create booking');
  }
}

// ✅ 讀取檢查清單
Stream<List<BookingOrder>> getUserBookings() {
  // [ ] 獲取 firebase_uid
  final currentUserId = _auth.currentUser?.uid;
  if (currentUserId == null) {
    return Stream.value([]);
  }

  // [ ] 從 Firestore 讀取，使用 firebase_uid 查詢
  return _firestore
      .collection('orders_rt')
      .where('customerId', isEqualTo: currentUserId) // ✅ 使用 firebase_uid
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => BookingOrder.fromFirestore(doc))
          .toList());
}
```

### Flutter 專案結構檢查

- [ ] 我遵循專案結構（`lib/apps/customer/` 或 `lib/apps/driver/`）
- [ ] 我使用共享代碼（`lib/shared/`）
- [ ] 我使用核心服務（`lib/core/services/`）
- [ ] 我不重複實作已有的功能

### 常見問題檢查

- [ ] 我沒有使用 Windows 桌面平台（需要額外配置）
- [ ] 我使用 Android 模擬器或實體設備測試
- [ ] 我已經處理 GeoPoint 類型（`{latitude, longitude}`）
- [ ] 我已經處理 Timestamp 類型（`Timestamp.fromDate()`）
- [ ] 我已經處理 null 值（使用 `??` 或 `?.`）

---

## 🧪 測試

### 單元測試

- [ ] 我已經測試 ID 轉換邏輯
- [ ] 我已經測試錯誤處理（用戶不存在、參數無效等）
- [ ] 我已經測試業務邏輯（訂單狀態、金額計算等）

### 整合測試

- [ ] 我已經測試完整的寫入流程（Flutter APP → Backend API → Supabase）
- [ ] 我已經測試完整的讀取流程（Firestore → Flutter APP）
- [ ] 我已經測試同步流程（Supabase → Outbox → Edge Function → Firestore）

### 手動測試

- [ ] 我已經在 Flutter APP 中測試功能
- [ ] 我已經檢查 Supabase 資料是否正確
- [ ] 我已經檢查 Firestore 資料是否正確
- [ ] 我已經檢查 `outbox` 表是否有未處理的記錄

---

## 📝 代碼審查

### 架構檢查

- [ ] 所有寫入操作都通過 Backend API
- [ ] Backend API 正確轉換 `firebase_uid` → `users.id`
- [ ] Edge Function 正確轉換 `users.id` → `firebase_uid`
- [ ] Flutter APP 從 Firestore 讀取，使用 `firebase_uid` 查詢
- [ ] 沒有直接從 Flutter APP 寫入 Firestore

### ID 使用檢查

- [ ] Supabase `bookings` 表使用 `users.id` (UUID)
- [ ] Firestore `orders_rt` collection 使用 `firebase_uid`
- [ ] 沒有混用 `firebase_uid` 和 `users.id`

### 錯誤處理檢查

- [ ] 所有 API 都有適當的錯誤處理
- [ ] 所有錯誤都返回適當的 HTTP 狀態碼
- [ ] 所有錯誤都有清晰的錯誤訊息
- [ ] 所有錯誤都有日誌記錄

---

## 🚀 部署前檢查

### 環境變數

- [ ] 我已經配置所有必要的環境變數
- [ ] 我已經驗證 Supabase URL 和 API Key
- [ ] 我已經驗證 Firebase 配置
- [ ] 我**沒有**修改固定的端口配置（3000, 3001）
- [ ] 我**沒有**修改 API URL
- [ ] 我已經確認所有 `.env` 文件都已配置

### 資料庫

- [ ] 我已經運行所有必要的資料庫遷移
- [ ] 我已經驗證 Trigger 是否正常運行
- [ ] 我已經驗證 Edge Function 是否正常運行
- [ ] 我已經驗證 RLS 政策是否正確
- [ ] 我已經部署 Firestore 安全規則
- [ ] 我已經部署 Firestore 索引

### Firestore 配置

- [ ] 我已經部署安全規則（`firebase deploy --only firestore:rules`）
- [ ] 我已經部署索引（`firebase deploy --only firestore:indexes`）
- [ ] 我已經驗證所有查詢都有對應的索引
- [ ] 我已經測試 Firestore 權限（讀取/寫入）

### Flutter APP 配置

- [ ] 我已經測試客戶端 APP（`--flavor customer`）
- [ ] 我已經測試司機端 APP（`--flavor driver`）
- [ ] 我已經確認 API 連接正常
- [ ] 我已經確認 Firebase 初始化正常
- [ ] 我已經確認 Supabase 初始化正常

### 文檔

- [ ] 我已經更新 API 文檔
- [ ] 我已經更新架構文檔（如有變更）
- [ ] 我已經添加代碼註釋
- [ ] 我已經更新 README（如有新功能）

---

## ⚠️ 常見錯誤檢查

### ID 類型錯誤

- [ ] 我沒有在 Supabase 中使用 `firebase_uid`
- [ ] 我沒有在 Firestore 中使用 `users.id`
- [ ] 我沒有混用兩種 ID

### 架構違反

- [ ] 我沒有直接從 Flutter APP 寫入 Firestore
- [ ] 我沒有直接從 Flutter APP 寫入 Supabase
- [ ] 我沒有跳過 Backend API 直接操作 Supabase
- [ ] 我沒有從 Flutter APP 讀取 Supabase
- [ ] 我沒有違反 RLS 規則
- [ ] 我沒有違反 Firestore 安全規則

### 業務邏輯錯誤

- [ ] 我已經驗證訂單狀態流程
- [ ] 我已經驗證權限檢查
- [ ] 我已經驗證金額計算

### 配置錯誤

- [ ] 我沒有修改固定的端口（3000, 3001）
- [ ] 我沒有修改 API URL
- [ ] 我沒有修改 Supabase URL
- [ ] 我沒有修改 Firebase Project ID
- [ ] 我已經確認 CORS 配置正確

### Firestore 錯誤

- [ ] 我沒有缺少必需的索引
- [ ] 我沒有違反安全規則（直接寫入）
- [ ] 我已經處理權限錯誤
- [ ] 我已經處理索引缺失錯誤

### Flutter 錯誤

- [ ] 我沒有使用錯誤的 Flavor
- [ ] 我沒有使用錯誤的 API URL
- [ ] 我已經處理 GeoPoint 類型錯誤
- [ ] 我已經處理 Timestamp 類型錯誤
- [ ] 我已經處理 null 值錯誤

---

## 📚 參考資料

- [完整架構文檔](./ARCHITECTURE.md)
- [快速參考卡片](./QUICK_REFERENCE.md)

---

**最後更新**: 2025-01-12

