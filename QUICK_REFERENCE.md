# 快速參考卡片

> **⚠️ 開發前必讀！** 這是最常用的架構規則速查表。
> 
> 完整文檔請參閱 [ARCHITECTURE.md](./ARCHITECTURE.md)

---

## 🆔 ID 使用規則（最重要！）

### Supabase 表格

| 表格 | 欄位 | 使用的 ID | 範例 |
|------|------|----------|------|
| `bookings` | `customer_id` | **`users.id` (UUID)** | `550e8400-e29b-41d4-a716-446655440000` |
| `bookings` | `driver_id` | **`users.id` (UUID)** | `660e8400-e29b-41d4-a716-446655440001` |
| `users` | `id` | **UUID (主鍵)** | `550e8400-e29b-41d4-a716-446655440000` |
| `users` | `firebase_uid` | **Firebase UID** | `hUu4fH5dTIW9VUYm6GojXvRLdni2` |

### Firestore Collection

| Collection | 欄位 | 使用的 ID | 範例 |
|-----------|------|----------|------|
| `orders_rt` | `customerId` | **`firebase_uid`** | `hUu4fH5dTIW9VUYm6GojXvRLdni2` |
| `orders_rt` | `driverId` | **`firebase_uid`** | `CMfTxhJFlUVDkosJPyUoJvKjCQk1` |
| `chat_rooms` | `customerId` | **`firebase_uid`** | `hUu4fH5dTIW9VUYm6GojXvRLdni2` |
| `chat_rooms` | `driverId` | **`firebase_uid`** | `CMfTxhJFlUVDkosJPyUoJvKjCQk1` |

### 記憶口訣

```
Supabase 用 UUID (users.id)
Firestore 用 Firebase UID
Backend API 要轉換！
```

---

## 📝 訂單狀態流程

```
pending_payment (待付訂金)
    ↓ 客戶支付訂金
paid_deposit (已付訂金)
    ↓ 公司配對司機
matched (已配對)
    ↓ 司機確認接單
driver_confirmed (司機確認)
    ↓ 司機出發
driver_departed (司機出發)
    ↓ 開始服務
in_progress (進行中)
    ↓ 完成服務
completed (已完成)

OR

cancelled (已取消) - 任何階段都可取消
```

### Supabase → Firestore 狀態映射

| Supabase | Firestore | 說明 |
|----------|-----------|------|
| `pending_payment` | `pending` | 待付訂金 |
| `paid_deposit` | `matched` | 已付訂金 |
| `matched` | `matched` | 已配對 |
| `driver_confirmed` | `inProgress` | 司機確認 |
| `driver_departed` | `inProgress` | 司機出發 |
| `in_progress` | `inProgress` | 進行中 |
| `completed` | `completed` | 已完成 |
| `cancelled` | `cancelled` | 已取消 |

---

## 🔄 資料流向

### ✅ 正確的寫入流程

```
Flutter APP
    ↓ HTTP POST (firebase_uid)
Backend API
    ↓ 1. 查詢 users 表 (firebase_uid → users.id)
    ↓ 2. 寫入 Supabase (使用 users.id)
Supabase
    ↓ Trigger
Outbox 表
    ↓ Edge Function
Firestore (使用 firebase_uid)
```

### ✅ 正確的讀取流程

```
Flutter APP
    ↓ 即時查詢 (where customerId == currentUser.uid)
Firestore
```

### ❌ 錯誤的流程

```
❌ Flutter APP → 直接寫入 Firestore (違反 CQRS)
❌ Backend API → 使用 firebase_uid 寫入 Supabase (ID 類型錯誤)
❌ Edge Function → 使用 users.id 寫入 Firestore (ID 類型錯誤)
```

---

## 💻 代碼範本

### Backend API：接收 Firebase UID，寫入 Supabase

```typescript
// ✅ 正確示例
router.post('/bookings', async (req, res) => {
  const { customerUid } = req.body; // Firebase UID
  
  // 1. 查詢 users 表，轉換 ID
  const { data: customer, error: userError } = await supabase
    .from('users')
    .select('id')
    .eq('firebase_uid', customerUid)
    .single();
  
  if (userError || !customer) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  // 2. 寫入 bookings 表，使用 users.id
  const { data: booking, error: bookingError } = await supabase
    .from('bookings')
    .insert({
      customer_id: customer.id, // ✅ 使用 users.id (UUID)
      // ... 其他欄位
    })
    .select()
    .single();
  
  if (bookingError) {
    return res.status(500).json({ error: bookingError.message });
  }
  
  res.json({ success: true, data: booking });
});
```

### Edge Function：從 Supabase 同步到 Firestore

```typescript
// ✅ 正確示例
async function syncBookingToFirestore(bookingId: string) {
  // 1. 從 Supabase 讀取訂單，JOIN users 表獲取 firebase_uid
  const { data: booking } = await supabase
    .from('bookings')
    .select(`
      *,
      customer:users!customer_id(firebase_uid),
      driver:users!driver_id(firebase_uid)
    `)
    .eq('id', bookingId)
    .single();
  
  // 2. 寫入 Firestore，使用 firebase_uid
  await firestore.collection('orders_rt').doc(booking.id).set({
    customerId: booking.customer.firebase_uid, // ✅ 使用 firebase_uid
    driverId: booking.driver?.firebase_uid || null, // ✅ 使用 firebase_uid
    // ... 其他欄位
  });
}
```

### Flutter APP：從 Firestore 讀取訂單

```dart
// ✅ 正確示例
Stream<List<BookingOrder>> getUserBookings() {
  final currentUserId = _auth.currentUser?.uid; // Firebase UID
  
  if (currentUserId == null) {
    return Stream.value([]);
  }
  
  // 從 Firestore 讀取，使用 firebase_uid 查詢
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

---

## ⚠️ 常見錯誤

### ❌ 錯誤 1：在 Supabase 中使用 Firebase UID

```typescript
// ❌ 錯誤
await supabase.from('bookings').insert({
  customer_id: 'hUu4fH5dTIW9VUYm6GojXvRLdni2', // Firebase UID - 錯誤！
});

// ✅ 正確
const { data: user } = await supabase
  .from('users')
  .select('id')
  .eq('firebase_uid', 'hUu4fH5dTIW9VUYm6GojXvRLdni2')
  .single();

await supabase.from('bookings').insert({
  customer_id: user.id, // Supabase UUID - 正確！
});
```

### ❌ 錯誤 2：在 Firestore 中使用 Supabase UUID

```typescript
// ❌ 錯誤
await firestore.collection('orders_rt').doc(bookingId).set({
  customerId: '550e8400-e29b-41d4-a716-446655440000', // Supabase UUID - 錯誤！
});

// ✅ 正確
await firestore.collection('orders_rt').doc(bookingId).set({
  customerId: 'hUu4fH5dTIW9VUYm6GojXvRLdni2', // Firebase UID - 正確！
});
```

### ❌ 錯誤 3：直接從 Flutter APP 寫入 Firestore

```dart
// ❌ 錯誤：違反 CQRS 架構
await FirebaseFirestore.instance.collection('orders_rt').add({
  'customerId': currentUserId,
  // ...
});

// ✅ 正確：通過 Backend API
final response = await http.post(
  Uri.parse('$_baseUrl/bookings'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'customerUid': currentUserId, // Firebase UID
    // ...
  }),
);
```

---

## 📦 環境變數與端口固定

> **⚠️ AI 助理注意**：以下配置是固定的，請勿更改！

### 固定端口

| 服務 | 端口 | 不可更改 |
|------|------|---------|
| Backend API | `3000` | ✅ |
| Web Admin | `3001` | ✅ |
| Supabase Local DB | `54322` | ✅ |
| Supabase Studio | `54323` | ✅ |

### 關鍵環境變數

```bash
# Backend API
PORT=3000  # ← 固定！
API_BASE_URL=http://localhost:3000
WEB_ADMIN_URL=http://localhost:3001  # ← 固定！

# Flutter APP
API_BASE_URL=http://localhost:3000/api  # ← 固定！

# Web Admin
NEXT_PUBLIC_API_URL=http://localhost:3000  # ← 固定！
NEXT_PUBLIC_PORT=3001  # ← 固定！
```

---

## 🧱 Firestore 安全規則與索引

### 安全規則總覽

| Collection | 讀取 | 寫入 | 說明 |
|-----------|------|------|------|
| `orders_rt` | ✅ 用戶自己 | ❌ 禁止 | Edge Function 同步 |
| `bookings` | ✅ 用戶自己 | ❌ 禁止 | Edge Function 同步 |
| `chat_rooms` | ✅ 用戶自己 | ❌ 禁止 | Edge Function 同步 |
| `driver_locations` | ✅ 所有人 | ✅ 僅司機 | 即時位置 |

### 必需的索引

```json
// orders_rt: customerId + createdAt
// orders_rt: customerId + status + createdAt
// orders_rt: driverId + createdAt
// orders_rt: driverId + status + createdAt
// chat_rooms: customerId + lastMessageTime
// chat_rooms: driverId + lastMessageTime
```

### 部署命令

```bash
# 部署安全規則
firebase deploy --only firestore:rules

# 部署索引
firebase deploy --only firestore:indexes
```

---

## 🔐 RLS 規則快速參考

### RLS 保護的資料表

| 資料表 | 允許的存取方式 |
|--------|--------------|
| `users` | Backend API（service_role_key） |
| `bookings` | Backend API（service_role_key） |
| `payments` | Backend API（service_role_key） |
| `chat_rooms` | Backend API / Edge Function |
| `user_profiles` | Backend API（service_role_key） |

### 正確的存取方式

```typescript
// ✅ 正確：Backend API 使用 service_role_key
const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY  // ← 繞過 RLS
);

// ❌ 錯誤：Flutter APP 直接存取
const supabase = Supabase.instance.client;  // ← 受 RLS 限制
```

---

## 🔍 檢查清單

### 修改代碼前

- [ ] 我已經閱讀了 [ARCHITECTURE.md](./ARCHITECTURE.md)
- [ ] 我知道應該使用哪個 ID（`firebase_uid` vs `users.id`）
- [ ] 我知道資料應該寫入哪裡（Supabase）
- [ ] 我知道資料應該從哪裡讀取（Firestore）
- [ ] 我確認不會修改固定的端口配置
- [ ] 我確認不會違反 RLS 規則
- [ ] 我確認不會違反 Firestore 安全規則

### 寫入 Supabase 時

- [ ] 我使用 `users.id` (UUID) 作為外鍵
- [ ] 我先查詢 `users` 表轉換 `firebase_uid` → `users.id`
- [ ] 我通過 Backend API 寫入，不是直接從 Flutter APP
- [ ] 我使用 `service_role_key` 繞過 RLS

### 寫入 Firestore 時

- [ ] 我只在 Edge Function 中寫入 Firestore
- [ ] 我使用 `firebase_uid` 作為用戶 ID
- [ ] 我先查詢 `users` 表轉換 `users.id` → `firebase_uid`
- [ ] 我確認 Firestore 安全規則允許此操作

### 從 Firestore 讀取時

- [ ] 我使用 `firebase_uid` 查詢（`where customerId == currentUser.uid`）
- [ ] 我從 Flutter APP 直接讀取 Firestore（不通過 Backend API）
- [ ] 我確認查詢有對應的索引

### 配置環境變數時

- [ ] 我沒有修改固定的端口（3000, 3001）
- [ ] 我沒有修改 API URL
- [ ] 我沒有修改 Supabase URL
- [ ] 我沒有修改 Firebase Project ID

---

## 📞 需要幫助？

如果遇到以下情況，請查閱完整文檔：

- 不確定應該使用哪個 ID
- 不確定資料應該寫入哪裡
- 不確定資料應該從哪裡讀取
- 遇到 ID 類型錯誤
- 遇到資料不一致問題
- 遇到端口配置錯誤
- 遇到 RLS 權限錯誤
- 遇到 Firestore 權限錯誤
- 遇到索引缺失錯誤

**完整文檔**: [ARCHITECTURE.md](./ARCHITECTURE.md)

---

**最後更新**: 2025-01-12

