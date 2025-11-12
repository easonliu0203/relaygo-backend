# 包車系統架構文檔

> **⚠️ 重要提示**：在修改任何代碼之前，必須先閱讀此文檔！
> 
> 本文檔定義了系統的核心架構原則、資料庫結構和開發規範。
> 違反這些原則將導致資料不一致、功能異常和系統崩潰。

---

## 📋 目錄

1. [核心架構原則](#核心架構原則)
2. [技術分工](#技術分工)
3. [資料流向](#資料流向)
4. [Supabase 資料庫結構](#supabase-資料庫結構)
5. [🔐 RLS（Row Level Security）規則說明](#rls-row-level-security-規則說明)
6. [Firestore 資料庫結構](#firestore-資料庫結構)
7. [🧱 Firestore 安全規則與索引](#firestore-安全規則與索引)
8. [ID 映射規則（關鍵！）](#id-映射規則)
9. [Backend API 規範](#backend-api-規範)
10. [Edge Functions](#edge-functions)
11. [🧩 Outbox → Firestore Payload 格式契約](#outbox-firestore-payload-格式契約)
12. [📦 環境變數與端口固定](#環境變數與端口固定)
13. [開發規範](#開發規範)
14. [常見錯誤示例](#常見錯誤示例)
15. [快速參考指南](#快速參考指南)

---

## 核心架構原則

### CQRS 架構（Command Query Responsibility Segregation）

系統採用 **CQRS 架構**，將寫入和讀取分離：

- **寫入模型（Command）**：Supabase/PostgreSQL
  - 唯一真實數據源
  - 所有寫入操作必須通過 Backend API 寫入 Supabase
  - 負責資料一致性、事務處理、業務邏輯驗證

- **讀取模型（Query）**：Firestore
  - 即時查詢、實時監聽
  - 資料來自 Supabase 的單向鏡像（通過 Outbox Pattern 同步）
  - 只讀，不可直接寫入

### Outbox Pattern

使用 **Outbox Pattern** 確保資料同步的可靠性：

1. Supabase 寫入操作完成後，觸發 Trigger
2. Trigger 將事件寫入 `outbox` 表
3. Edge Function 定期讀取 `outbox` 表
4. Edge Function 將事件同步到 Firestore
5. 標記 `outbox` 記錄為已處理

---

## 技術分工

| 技術 | 用途 | 說明 |
|------|------|------|
| **Firebase** | 登入、推播、聊天即時、檔案、定位 | 即時性要求高的功能 |
| **Supabase/PostgreSQL** | 訂單金額、結帳、退款、獎金、報表、模擬支付 | 唯一真實數據源，所有業務資料 |
| **Firestore** | 訂單列表、聊天室列表、用戶資料（讀取） | Supabase 的鏡像，用於即時查詢 |
| **Backend API** | 業務邏輯、資料驗證、Supabase 寫入 | Node.js/Express/TypeScript |

---

## 資料流向

### 寫入流程（Command）

```
Flutter APP
    ↓ (HTTP POST)
Backend API
    ↓ (驗證 + 業務邏輯)
Supabase (Write Model)
    ↓ (Database Trigger)
Outbox 表
    ↓ (Edge Function 輪詢)
Firestore (Read Model)
```

### 讀取流程（Query）

```
Flutter APP
    ↓ (即時監聽)
Firestore (Read Model)
```

### 架構圖

```mermaid
graph TB
    subgraph "Flutter APP"
        A[客戶端 APP]
        B[司機端 APP]
    end
    
    subgraph "Backend"
        C[Backend API<br/>Node.js/Express]
    end
    
    subgraph "Supabase (Write Model)"
        D[PostgreSQL Database]
        E[Outbox 表]
        F[Database Trigger]
    end
    
    subgraph "Firestore (Read Model)"
        G[orders_rt collection]
        H[chat_rooms collection]
        I[users collection]
    end
    
    J[Edge Function<br/>sync-to-firestore]
    
    A -->|HTTP POST| C
    B -->|HTTP POST| C
    C -->|寫入| D
    D -->|觸發| F
    F -->|寫入| E
    E -->|輪詢| J
    J -->|同步| G
    J -->|同步| H
    J -->|同步| I
    
    A -.->|即時讀取| G
    A -.->|即時讀取| H
    B -.->|即時讀取| G
    B -.->|即時讀取| H
    
    style D fill:#f9f,stroke:#333,stroke-width:4px
    style G fill:#bbf,stroke:#333,stroke-width:2px
    style H fill:#bbf,stroke:#333,stroke-width:2px
    style I fill:#bbf,stroke:#333,stroke-width:2px
```

---

## Supabase 資料庫結構

### `bookings` 表（訂單）

| 欄位名稱 | 類型 | 說明 | 範例 |
|---------|------|------|------|
| `id` | UUID | 訂單 ID（主鍵） | `da8bdde0-a58a-4f6f-9391-87dfa91ac2fe` |
| `customer_id` | UUID | 客戶 ID（外鍵 → `users.id`） | `550e8400-e29b-41d4-a716-446655440000` |
| `driver_id` | UUID | 司機 ID（外鍵 → `users.id`，可為 null） | `660e8400-e29b-41d4-a716-446655440001` |
| `booking_number` | VARCHAR | 訂單編號 | `BK1760278749264` |
| `status` | VARCHAR | 訂單狀態（見下表） | `matched` |
| `start_date` | DATE | 預約日期 | `2025-01-15` |
| `start_time` | TIME | 預約時間 | `09:00:00` |
| `duration_hours` | INTEGER | 預約時長（小時） | `8` |
| `vehicle_type` | VARCHAR | 車型 | `標準 8 小時包車` |
| `pickup_location` | TEXT | 上車地點 | `台北市信義區市府路1號` |
| `pickup_latitude` | DECIMAL | 上車緯度 | `25.0408` |
| `pickup_longitude` | DECIMAL | 上車經度 | `121.5674` |
| `destination` | TEXT | 目的地（可為空） | `台北市松山區南京東路五段123號` |
| `special_requirements` | TEXT | 特殊需求 | `需要兒童座椅` |
| `requires_foreign_language` | BOOLEAN | 是否需要外語服務 | `false` |
| `base_price` | DECIMAL | 基本費用 | `3000.00` |
| `foreign_language_surcharge` | DECIMAL | 外語加價 | `0.00` |
| `overtime_fee` | DECIMAL | 超時費用 | `0.00` |
| `tip_amount` | DECIMAL | 小費 | `0.00` |
| `total_amount` | DECIMAL | 總金額 | `3000.00` |
| `deposit_amount` | DECIMAL | 訂金金額（30%） | `900.00` |
| `actual_start_time` | TIMESTAMP | 實際開始時間 | `2025-01-15 09:05:00` |
| `actual_end_time` | TIMESTAMP | 實際結束時間 | `2025-01-15 17:30:00` |
| `created_at` | TIMESTAMP | 創建時間 | `2025-01-12 14:30:00` |
| `updated_at` | TIMESTAMP | 更新時間 | `2025-01-12 15:00:00` |
| `cancellation_reason` | TEXT | 取消原因 | `客戶臨時有事` |
| `cancelled_at` | TIMESTAMP | 取消時間 | `2025-01-13 10:00:00` |

#### 訂單狀態（`status` 欄位）

| 狀態值 | 中文名稱 | 說明 | 下一步操作 |
|--------|---------|------|-----------|
| `pending_payment` | 待付訂金 | 訂單已創建，等待客戶支付訂金 | 客戶支付訂金 |
| `paid_deposit` | 已付訂金 | 訂金已支付，等待公司配對司機 | 公司配對司機 |
| `matched` | 已配對 | 已分配司機，等待司機確認接單 | 司機確認接單 |
| `driver_confirmed` | 司機確認 | 司機已確認接單，等待出發 | 司機出發 |
| `driver_departed` | 司機出發 | 司機已出發前往上車地點 | 開始服務 |
| `in_progress` | 進行中 | 服務進行中 | 完成服務 |
| `completed` | 已完成 | 服務已完成 | - |
| `cancelled` | 已取消 | 訂單已取消 | - |

#### 關鍵欄位說明

⚠️ **重要**：
- `customer_id` 和 `driver_id` 存儲的是 **`users.id`（UUID）**，不是 `firebase_uid`
- 在 Backend API 中，需要先通過 `firebase_uid` 查詢 `users` 表獲取 `users.id`，然後再寫入 `bookings` 表

### `users` 表（用戶）

| 欄位名稱 | 類型 | 說明 | 範例 |
|---------|------|------|------|
| `id` | UUID | 用戶 ID（主鍵，Supabase UUID） | `550e8400-e29b-41d4-a716-446655440000` |
| `firebase_uid` | VARCHAR | Firebase Authentication UID | `hUu4fH5dTIW9VUYm6GojXvRLdni2` |
| `email` | VARCHAR | 郵箱 | `customer@example.com` |
| `phone` | VARCHAR | 電話 | `0912345678` |
| `role` | VARCHAR | 角色（`customer`, `driver`, `admin`） | `customer` |
| `status` | VARCHAR | 狀態（`active`, `inactive`, `suspended`） | `active` |
| `preferred_language` | VARCHAR | 偏好語言 | `zh-TW` |
| `created_at` | TIMESTAMP | 創建時間 | `2025-01-01 10:00:00` |
| `updated_at` | TIMESTAMP | 更新時間 | `2025-01-12 14:30:00` |

#### 關鍵欄位說明

⚠️ **重要**：
- `id`：Supabase UUID，用於 `bookings` 表的外鍵（`customer_id`, `driver_id`）
- `firebase_uid`：Firebase Authentication UID，用於 Firestore 查詢和 Backend API 驗證
- **目前沒有 `name` 欄位**，如需顯示用戶名稱，使用 `email` 的用戶名部分（`@` 之前）

### `outbox` 表（事件同步）

| 欄位名稱 | 類型 | 說明 |
|---------|------|------|
| `id` | UUID | 事件 ID |
| `aggregate_type` | VARCHAR | 聚合類型（`booking`, `user`, `chat_message`） |
| `aggregate_id` | UUID | 聚合 ID（如 `booking.id`） |
| `event_type` | VARCHAR | 事件類型（`created`, `updated`, `deleted`） |
| `payload` | JSONB | 事件資料 |
| `created_at` | TIMESTAMP | 創建時間 |
| `processed_at` | TIMESTAMP | 處理時間（null 表示未處理） |
| `retry_count` | INTEGER | 重試次數 |

### 其他表格

- `chat_messages`：聊天訊息（存儲在 Firestore，Supabase 可能有備份）
- `drivers`：司機詳細資料（車輛、評分等）
- `payments`：支付記錄
- `user_profiles`：用戶詳細資料

---

## 🔐 RLS (Row Level Security) 規則說明

> **⚠️ 重要提示**：Supabase 已啟用 RLS（Row Level Security），App 端不可直接操作資料表，必須透過指定的 API 或 Edge Functions！

### RLS 保護的資料表

以下資料表已啟用 RLS 保護，**禁止客戶端直接存取**：

| 資料表 | RLS 狀態 | 允許的存取方式 | 說明 |
|--------|---------|--------------|------|
| `users` | ✅ 啟用 | Backend API | 用戶只能查看和更新自己的資料 |
| `bookings` | ✅ 啟用 | Backend API | 客戶可查看自己的訂單，司機可查看指派的訂單 |
| `payments` | ✅ 啟用 | Backend API | 僅管理員可存取所有資料 |
| `chat_rooms` | ✅ 啟用 | Backend API / Edge Function | 用戶只能存取自己參與的聊天室 |
| `chat_messages` | ✅ 啟用 | Backend API / Edge Function | 用戶只能存取自己的訊息 |
| `user_profiles` | ✅ 啟用 | Backend API | 用戶只能查看和更新自己的資料 |

### RLS 政策詳細說明

#### 1. `users` 表 RLS 政策

```sql
-- 用戶可以查看自己的資料
CREATE POLICY "用戶自己的資料" ON users
FOR SELECT
USING (auth.uid()::text = id::text);

-- 用戶可以更新自己的資料
CREATE POLICY "用戶更新自己的資料" ON users
FOR UPDATE
USING (auth.uid()::text = id::text);

-- 管理員可以存取所有資料
CREATE POLICY "管理員全權限" ON users
FOR ALL
USING (auth.jwt() ->> 'role' = 'admin');
```

#### 2. `bookings` 表 RLS 政策

```sql
-- 客戶可以查看自己的訂單
CREATE POLICY "客戶查看自己的訂單" ON bookings
FOR SELECT
USING (auth.uid()::text = customer_id::text);

-- 司機可以查看指派給自己的訂單
CREATE POLICY "司機查看指派的訂單" ON bookings
FOR SELECT
USING (auth.uid()::text = driver_id::text);

-- 管理員可以存取所有訂單
CREATE POLICY "管理員全權限" ON bookings
FOR ALL
USING (auth.jwt() ->> 'role' = 'admin');
```

#### 3. `user_profiles` 表 RLS 政策

```sql
-- 用戶可以查看自己的資料
CREATE POLICY "用戶可以查看自己的資料" ON user_profiles
FOR SELECT
USING (
  user_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
);

-- 用戶可以更新自己的資料
CREATE POLICY "用戶可以更新自己的資料" ON user_profiles
FOR UPDATE
USING (
  user_id IN (
    SELECT id FROM users WHERE firebase_uid = auth.jwt() ->> 'sub'
  )
);
```

### 正確的存取方式

#### ✅ 正確：通過 Backend API

```typescript
// Flutter APP
final response = await http.post(
  Uri.parse('$_baseUrl/bookings'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'customerUid': currentUser.uid,
    // ...
  }),
);
```

```typescript
// Backend API
router.post('/bookings', async (req, res) => {
  const { customerUid } = req.body;

  // 使用 service_role_key，繞過 RLS
  const { data: customer } = await supabase
    .from('users')
    .select('id')
    .eq('firebase_uid', customerUid)
    .single();

  const { data: booking } = await supabase
    .from('bookings')
    .insert({
      customer_id: customer.id,
      // ...
    })
    .select()
    .single();

  res.json({ success: true, data: booking });
});
```

#### ❌ 錯誤：直接從 App 操作 Supabase

```dart
// ❌ 錯誤：違反 RLS 規則
final response = await Supabase.instance.client
  .from('bookings')
  .insert({
    'customer_id': currentUserId,
    // ...
  });
// 這會失敗，因為 RLS 不允許直接插入
```

### RLS 繞過方式

只有以下情況可以繞過 RLS：

1. **Backend API**：使用 `service_role_key`（完全權限）
2. **Edge Functions**：使用 `service_role_key`（完全權限）
3. **管理員**：通過 JWT token 中的 `role = 'admin'`

---

## Firestore 資料庫結構

### `orders_rt` collection（訂單鏡像）

**文檔 ID**：使用 Supabase `bookings.id`（UUID）

| 欄位名稱 | 類型 | 說明 | 範例 |
|---------|------|------|------|
| `customerId` | String | 客戶 Firebase UID（**不是** `users.id`） | `hUu4fH5dTIW9VUYm6GojXvRLdni2` |
| `driverId` | String | 司機 Firebase UID（**不是** `users.id`） | `CMfTxhJFlUVDkosJPyUoJvKjCQk1` |
| `pickupAddress` | String | 上車地點 | `台北市信義區市府路1號` |
| `pickupLocation` | GeoPoint | 上車座標 | `{latitude: 25.0408, longitude: 121.5674}` |
| `dropoffAddress` | String | 下車地點 | `台北市松山區南京東路五段123號` |
| `dropoffLocation` | GeoPoint | 下車座標 | `{latitude: 25.0518, longitude: 121.5527}` |
| `bookingTime` | Timestamp | 預約時間 | `2025-01-15 09:00:00` |
| `createdAt` | Timestamp | 創建時間 | `2025-01-12 14:30:00` |
| `passengerCount` | Number | 乘客人數 | `2` |
| `luggageCount` | Number | 行李數量 | `1` |
| `notes` | String | 備註 | `需要兒童座椅` |
| `estimatedFare` | Number | 預估費用 | `3000` |
| `depositAmount` | Number | 訂金金額 | `900` |
| `depositPaid` | Boolean | 訂金是否已支付 | `true` |
| `status` | String | 訂單狀態（映射自 Supabase） | `matched` |

#### 狀態映射（Supabase → Firestore）

| Supabase `status` | Firestore `status` | 說明 |
|-------------------|-------------------|------|
| `pending_payment` | `pending` | 待付訂金 |
| `paid_deposit` | `matched` | 已付訂金（等待配對） |
| `matched` | `matched` | 已配對 |
| `driver_confirmed` | `inProgress` | 司機確認 |
| `driver_departed` | `inProgress` | 司機出發 |
| `in_progress` | `inProgress` | 進行中 |
| `completed` | `completed` | 已完成 |
| `cancelled` | `cancelled` | 已取消 |

### `chat_rooms` collection（聊天室）

**文檔 ID**：使用 `bookingId`（與訂單 ID 相同）

| 欄位名稱 | 類型 | 說明 |
|---------|------|------|
| `bookingId` | String | 訂單 ID |
| `customerId` | String | 客戶 Firebase UID |
| `driverId` | String | 司機 Firebase UID |
| `customerName` | String | 客戶名稱 |
| `driverName` | String | 司機名稱 |
| `pickupAddress` | String | 上車地點 |
| `bookingTime` | Timestamp | 預約時間 |
| `lastMessage` | String | 最後一條訊息 |
| `lastMessageTime` | Timestamp | 最後訊息時間 |
| `customerUnreadCount` | Number | 客戶未讀數 |
| `driverUnreadCount` | Number | 司機未讀數 |
| `createdAt` | Timestamp | 創建時間 |
| `updatedAt` | Timestamp | 更新時間 |

### `users` collection（用戶鏡像）

**文檔 ID**：使用 `firebase_uid`

| 欄位名稱 | 類型 | 說明 |
|---------|------|------|
| `email` | String | 郵箱 |
| `phone` | String | 電話 |
| `role` | String | 角色 |
| `status` | String | 狀態 |
| `createdAt` | Timestamp | 創建時間 |

---

## 🧱 Firestore 安全規則與索引

> **⚠️ 重要提示**：Firestore 已配置安全規則，禁止客戶端直接寫入！所有寫入必須通過 Supabase Edge Function！

### Firestore 安全規則總覽

| Collection | 讀取權限 | 寫入權限 | 說明 |
|-----------|---------|---------|------|
| `orders_rt` | ✅ 用戶自己的訂單 | ❌ 禁止 | 由 Edge Function 同步 |
| `bookings` | ✅ 用戶自己的訂單 | ❌ 禁止 | 由 Edge Function 同步 |
| `chat_rooms` | ✅ 用戶參與的聊天室 | ❌ 禁止 | 由 Edge Function 同步 |
| `chat_rooms/{roomId}/messages` | ✅ 用戶參與的聊天室 | ❌ 禁止 | 由 Edge Function 同步 |
| `driver_locations` | ✅ 所有用戶 | ✅ 僅司機自己 | 司機即時位置 |
| `users` | ✅ 僅自己 | ✅ 僅自己 | 用戶資料 |

### 關鍵安全規則詳解

#### 1. `orders_rt` 集合（訂單即時鏡像）

```javascript
// firebase/firestore.rules
match /orders_rt/{orderId} {
  // ✅ 允許讀取：用戶自己的訂單（客戶或司機）
  allow read: if request.auth != null
              && (
                // 文檔不存在時允許讀取（返回 null）
                !exists(/databases/$(database)/documents/orders_rt/$(orderId))
                ||
                // 文檔存在時檢查是否為用戶自己的訂單
                (resource.data.customerId == request.auth.uid ||
                 resource.data.driverId == request.auth.uid)
              );

  // ❌ 禁止寫入：由 Supabase Edge Function 寫入
  allow write: if false;
}
```

**為什麼使用 `exists()` 檢查？**
- 避免在 Edge Function 同步延遲時出現權限錯誤
- 允許讀取不存在的文檔（返回 null），而不是拋出權限錯誤

#### 2. `chat_rooms` 集合（聊天室）

```javascript
match /chat_rooms/{roomId} {
  // ✅ 允許讀取：用戶參與的聊天室
  allow read: if request.auth != null &&
    (
      !exists(/databases/$(database)/documents/chat_rooms/$(roomId))
      ||
      (resource.data.customerId == request.auth.uid ||
       resource.data.driverId == request.auth.uid)
    );

  // ❌ 禁止寫入：由 Supabase Edge Function 寫入
  allow write: if false;

  // 聊天訊息子集合
  match /messages/{messageId} {
    allow read: if request.auth != null &&
      (
        !exists(/databases/$(database)/documents/chat_rooms/$(roomId))
        ||
        (get(/databases/$(database)/documents/chat_rooms/$(roomId)).data.customerId == request.auth.uid ||
         get(/databases/$(database)/documents/chat_rooms/$(roomId)).data.driverId == request.auth.uid)
      );

    allow write: if false;
  }
}
```

#### 3. `driver_locations` 集合（司機即時位置）

```javascript
match /driver_locations/{driverId} {
  // ✅ 允許讀取：所有已登入用戶
  allow read: if request.auth != null;

  // ✅ 允許寫入：僅司機自己
  allow write: if request.auth != null && request.auth.uid == driverId;
}
```

### Firestore 索引配置

> **⚠️ 重要提示**：以下索引是必需的，缺少任何一個都會導致查詢失敗！

#### 必需的複合索引

**文件位置**：`firebase/firestore.indexes.json`

##### 1. `orders_rt` 集合索引

```json
{
  "indexes": [
    // 索引 1：客戶查詢自己的訂單（按創建時間排序）
    {
      "collectionGroup": "orders_rt",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "customerId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },

    // 索引 2：客戶查詢自己的訂單（按狀態和創建時間排序）
    {
      "collectionGroup": "orders_rt",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "customerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },

    // 索引 3：司機查詢自己的訂單（按創建時間排序）
    {
      "collectionGroup": "orders_rt",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "driverId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },

    // 索引 4：司機查詢自己的訂單（按狀態和創建時間排序）
    {
      "collectionGroup": "orders_rt",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "driverId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

##### 2. `chat_rooms` 集合索引

```json
{
  "indexes": [
    // 索引 5：客戶查詢自己的聊天室（按最後訊息時間排序）
    {
      "collectionGroup": "chat_rooms",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "customerId", "order": "ASCENDING" },
        { "fieldPath": "lastMessageTime", "order": "DESCENDING" }
      ]
    },

    // 索引 6：司機查詢自己的聊天室（按最後訊息時間排序）
    {
      "collectionGroup": "chat_rooms",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "driverId", "order": "ASCENDING" },
        { "fieldPath": "lastMessageTime", "order": "DESCENDING" }
      ]
    }
  ]
}
```

### 部署 Firestore 規則和索引

#### 部署安全規則

```bash
# Windows
deploy-firestore-rules.bat

# Linux/Mac
./deploy-firestore-rules.sh

# 或使用 Firebase CLI
firebase deploy --only firestore:rules
```

#### 部署索引

```bash
# Windows
deploy-firestore-indexes.bat

# Linux/Mac
./deploy-firestore-indexes.sh

# 或使用 Firebase CLI
firebase deploy --only firestore:indexes
```

### 常見查詢範例

#### ✅ 正確：符合索引的查詢

```dart
// 客戶查詢自己的訂單（按創建時間排序）
_firestore
  .collection('orders_rt')
  .where('customerId', isEqualTo: currentUserId)
  .orderBy('createdAt', descending: true)
  .snapshots();

// 客戶查詢自己的特定狀態訂單
_firestore
  .collection('orders_rt')
  .where('customerId', isEqualTo: currentUserId)
  .where('status', isEqualTo: 'inProgress')
  .orderBy('createdAt', descending: true)
  .snapshots();
```

#### ❌ 錯誤：缺少索引的查詢

```dart
// ❌ 錯誤：缺少 (customerId, bookingTime) 索引
_firestore
  .collection('orders_rt')
  .where('customerId', isEqualTo: currentUserId)
  .orderBy('bookingTime', descending: true) // 應該使用 createdAt
  .snapshots();
```

---

## ID 映射規則

⚠️ **這是最容易出錯的地方！請仔細閱讀！**

### ID 類型對照表

| ID 類型 | 格式 | 範例 | 用途 |
|---------|------|------|------|
| **Supabase `users.id`** | UUID | `550e8400-e29b-41d4-a716-446655440000` | Supabase 內部關聯（外鍵） |
| **Firebase UID** | String (28 chars) | `hUu4fH5dTIW9VUYm6GojXvRLdni2` | Firebase Auth、Firestore 查詢 |

### 使用場景對照表

| 場景 | 使用的 ID | 類型 | 說明 |
|------|----------|------|------|
| **Supabase `bookings.customer_id`** | `users.id` | UUID | 外鍵關聯 |
| **Supabase `bookings.driver_id`** | `users.id` | UUID | 外鍵關聯 |
| **Firestore `orders_rt.customerId`** | `firebase_uid` | String | 用於 Flutter APP 查詢 |
| **Firestore `orders_rt.driverId`** | `firebase_uid` | String | 用於 Flutter APP 查詢 |
| **Backend API 接收參數** | `firebase_uid` | String | 從 Firebase Auth 獲取 |
| **Backend API 寫入 Supabase** | `users.id` | UUID | 需要先查詢轉換 |
| **Flutter APP 查詢 Firestore** | `firebase_uid` | String | 直接使用當前用戶 UID |

### 轉換流程

#### Backend API：Firebase UID → Supabase users.id

```typescript
// 1. 接收 Firebase UID
const { customerUid } = req.body; // Firebase UID

// 2. 查詢 users 表獲取 Supabase UUID
const { data: user } = await supabase
  .from('users')
  .select('id')
  .eq('firebase_uid', customerUid)
  .single();

// 3. 使用 users.id 寫入 bookings 表
await supabase
  .from('bookings')
  .insert({
    customer_id: user.id, // ✅ 使用 users.id (UUID)
    // ...
  });
```

#### Edge Function：Supabase users.id → Firebase UID

```typescript
// 1. 從 Supabase 讀取訂單
const booking = await supabase
  .from('bookings')
  .select('*, customer:users!customer_id(firebase_uid)')
  .eq('id', bookingId)
  .single();

// 2. 使用 firebase_uid 寫入 Firestore
await firestore.collection('orders_rt').doc(booking.id).set({
  customerId: booking.customer.firebase_uid, // ✅ 使用 firebase_uid
  // ...
});
```

---

## Backend API 規範

### API 端點

| 端點 | 方法 | 說明 |
|------|------|------|
| `/api/bookings` | POST | 創建訂單 |
| `/api/bookings/:id/pay-deposit` | POST | 支付訂金 |
| `/api/booking-flow/bookings/:id/accept` | POST | 司機確認接單 |

### 標準流程

1. **接收 Firebase UID**（從 Flutter APP）
2. **查詢 `users` 表**（Firebase UID → Supabase UUID）
3. **驗證權限和業務邏輯**
4. **寫入 Supabase**（使用 Supabase UUID）
5. **返回結果**（包含必要資訊）

### 代碼示例

```typescript
// ✅ 正確示例
router.post('/bookings', async (req, res) => {
  const { customerUid } = req.body; // Firebase UID
  
  // 1. 查詢用戶
  const { data: customer } = await supabase
    .from('users')
    .select('id')
    .eq('firebase_uid', customerUid)
    .single();
  
  // 2. 創建訂單
  const { data: booking } = await supabase
    .from('bookings')
    .insert({
      customer_id: customer.id, // ✅ 使用 users.id
      // ...
    })
    .select()
    .single();
  
  res.json({ success: true, data: booking });
});
```

```typescript
// ❌ 錯誤示例
router.post('/bookings', async (req, res) => {
  const { customerUid } = req.body;
  
  // ❌ 直接使用 firebase_uid 寫入 Supabase
  const { data: booking } = await supabase
    .from('bookings')
    .insert({
      customer_id: customerUid, // ❌ 錯誤！應該使用 users.id
      // ...
    });
});
```

---

## Edge Functions

### `sync-to-firestore`

- **URL**: `https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore`
- **功能**: 從 Outbox 讀取事件，同步到 Firestore
- **觸發方式**: 定時任務（每分鐘）或 HTTP 請求

### 同步流程

1. 查詢 `outbox` 表中未處理的記錄（`processed_at IS NULL`）
2. 根據 `aggregate_type` 和 `event_type` 處理事件
3. 將資料寫入對應的 Firestore collection
4. 標記 `outbox` 記錄為已處理（`processed_at = NOW()`）

---

## 🧩 Outbox → Firestore Payload 格式契約

> **⚠️ 重要提示**：此章節定義從 Supabase Outbox 到 Firestore 的資料同步格式，請勿隨意修改！

### Edge Function 觸發機制

**觸發方式**：
1. **定時任務**：每 30 秒執行一次（通過 Supabase Cron Job）
2. **手動觸發**：HTTP POST 請求到 Edge Function

**Edge Function URL**：
```
https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore
```

**觸發流程**：
```
Supabase Trigger (bookings 表變更)
    ↓
寫入 outbox 表
    ↓
Edge Function 輪詢 (每 30 秒)
    ↓
讀取未處理的 outbox 記錄
    ↓
同步到 Firestore
    ↓
標記 outbox 記錄為已處理
```

### Outbox 表結構

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| `id` | UUID | 事件 ID | `550e8400-e29b-41d4-a716-446655440000` |
| `aggregate_type` | VARCHAR | 聚合類型 | `booking`, `chat_message` |
| `aggregate_id` | UUID | 聚合 ID（如 booking.id） | `da8bdde0-a58a-4f6f-9391-87dfa91ac2fe` |
| `event_type` | VARCHAR | 事件類型 | `created`, `updated`, `deleted` |
| `payload` | JSONB | 事件資料（JSON 格式） | 見下方範例 |
| `created_at` | TIMESTAMP | 創建時間 | `2025-01-12 14:30:00` |
| `processed_at` | TIMESTAMP | 處理時間（null = 未處理） | `2025-01-12 14:30:05` |
| `retry_count` | INTEGER | 重試次數 | `0` |

### Payload 格式範例

#### 1. 訂單創建事件（`booking.created`）

**Outbox Payload**（Supabase Trigger 寫入）：

```json
{
  "id": "da8bdde0-a58a-4f6f-9391-87dfa91ac2fe",
  "customer_id": "550e8400-e29b-41d4-a716-446655440000",
  "driver_id": null,
  "booking_number": "BK1760278749264",
  "status": "pending_payment",
  "start_date": "2025-01-15",
  "start_time": "09:00:00",
  "duration_hours": 8,
  "vehicle_type": "標準 8 小時包車",
  "pickup_location": "台北市信義區市府路1號",
  "pickup_latitude": 25.0408,
  "pickup_longitude": 121.5674,
  "destination": "台北市松山區南京東路五段123號",
  "special_requirements": "需要兒童座椅",
  "requires_foreign_language": false,
  "base_price": 3000.00,
  "foreign_language_surcharge": 0.00,
  "overtime_fee": 0.00,
  "tip_amount": 0.00,
  "total_amount": 3000.00,
  "deposit_amount": 900.00,
  "created_at": "2025-01-12T14:30:00Z",
  "updated_at": "2025-01-12T14:30:00Z"
}
```

**Firestore Payload**（Edge Function 寫入）：

```json
{
  "customerId": "hUu4fH5dTIW9VUYm6GojXvRLdni2",  // ← 轉換為 firebase_uid
  "driverId": null,
  "pickupAddress": "台北市信義區市府路1號",
  "pickupLocation": {
    "latitude": 25.0408,
    "longitude": 121.5674
  },
  "dropoffAddress": "台北市松山區南京東路五段123號",
  "dropoffLocation": null,
  "bookingTime": "2025-01-15T09:00:00Z",  // ← 合併 start_date + start_time
  "createdAt": "2025-01-12T14:30:00Z",
  "passengerCount": 1,
  "luggageCount": 0,
  "notes": "需要兒童座椅",
  "estimatedFare": 3000,
  "depositAmount": 900,
  "depositPaid": false,
  "status": "pending"  // ← 映射 Supabase status
}
```

#### 2. 訂單更新事件（`booking.updated`）

**Outbox Payload**：

```json
{
  "id": "da8bdde0-a58a-4f6f-9391-87dfa91ac2fe",
  "customer_id": "550e8400-e29b-41d4-a716-446655440000",
  "driver_id": "660e8400-e29b-41d4-a716-446655440001",  // ← 新增司機
  "status": "matched",  // ← 狀態變更
  "updated_at": "2025-01-12T15:00:00Z"
  // ... 其他欄位
}
```

**Firestore Payload**：

```json
{
  "customerId": "hUu4fH5dTIW9VUYm6GojXvRLdni2",
  "driverId": "CMfTxhJFlUVDkosJPyUoJvKjCQk1",  // ← 轉換為 firebase_uid
  "status": "matched",  // ← 映射狀態
  "updatedAt": "2025-01-12T15:00:00Z"
  // ... 其他欄位
}
```

### Firestore 欄位映射關係表

| Supabase 欄位 | Firestore 欄位 | 資料轉換 | 說明 |
|--------------|---------------|---------|------|
| `customer_id` (UUID) | `customerId` (String) | `users.id` → `firebase_uid` | 查詢 users 表轉換 |
| `driver_id` (UUID) | `driverId` (String) | `users.id` → `firebase_uid` | 查詢 users 表轉換 |
| `pickup_location` | `pickupAddress` | 直接複製 | 字串 |
| `pickup_latitude` + `pickup_longitude` | `pickupLocation` | 合併為 GeoPoint | `{latitude, longitude}` |
| `destination` | `dropoffAddress` | 直接複製 | 字串 |
| `start_date` + `start_time` | `bookingTime` | 合併為 Timestamp | ISO 8601 格式 |
| `special_requirements` | `notes` | 直接複製 | 字串 |
| `total_amount` | `estimatedFare` | 直接複製 | 數字 |
| `deposit_amount` | `depositAmount` | 直接複製 | 數字 |
| `status` | `status` | 狀態映射（見下表） | 字串 |
| `created_at` | `createdAt` | 轉換為 Timestamp | ISO 8601 格式 |
| `updated_at` | `updatedAt` | 轉換為 Timestamp | ISO 8601 格式 |

### 狀態映射規則

| Supabase `status` | Firestore `status` | 說明 |
|-------------------|-------------------|------|
| `pending_payment` | `pending` | 待付訂金 |
| `paid_deposit` | `matched` | 已付訂金（等待配對） |
| `matched` | `matched` | 已配對 |
| `driver_confirmed` | `inProgress` | 司機確認 |
| `driver_departed` | `inProgress` | 司機出發 |
| `in_progress` | `inProgress` | 進行中 |
| `completed` | `completed` | 已完成 |
| `cancelled` | `cancelled` | 已取消 |

### Edge Function 核心代碼

**文件位置**：`supabase/functions/sync-to-firestore/index.ts`

```typescript
async function syncBookingToFirestore(event: OutboxEvent) {
  const bookingId = event.aggregate_id;
  const payload = event.payload;

  // 1. 查詢 users 表，轉換 customer_id → firebase_uid
  const { data: customer } = await supabase
    .from('users')
    .select('firebase_uid')
    .eq('id', payload.customer_id)
    .single();

  // 2. 查詢 users 表，轉換 driver_id → firebase_uid（如果有）
  let driverUid = null;
  if (payload.driver_id) {
    const { data: driver } = await supabase
      .from('users')
      .select('firebase_uid')
      .eq('id', payload.driver_id)
      .single();
    driverUid = driver?.firebase_uid || null;
  }

  // 3. 映射狀態
  const statusMap = {
    'pending_payment': 'pending',
    'paid_deposit': 'matched',
    'matched': 'matched',
    'driver_confirmed': 'inProgress',
    'driver_departed': 'inProgress',
    'in_progress': 'inProgress',
    'completed': 'completed',
    'cancelled': 'cancelled',
  };

  // 4. 構建 Firestore payload
  const firestorePayload = {
    customerId: customer.firebase_uid,
    driverId: driverUid,
    pickupAddress: payload.pickup_location,
    pickupLocation: payload.pickup_latitude && payload.pickup_longitude
      ? { latitude: payload.pickup_latitude, longitude: payload.pickup_longitude }
      : null,
    dropoffAddress: payload.destination || null,
    bookingTime: `${payload.start_date}T${payload.start_time}Z`,
    createdAt: payload.created_at,
    updatedAt: payload.updated_at,
    notes: payload.special_requirements || '',
    estimatedFare: payload.total_amount,
    depositAmount: payload.deposit_amount,
    depositPaid: payload.status !== 'pending_payment',
    status: statusMap[payload.status] || 'pending',
  };

  // 5. 雙寫策略：同時寫入 orders_rt 和 bookings
  await Promise.all([
    // 寫入 orders_rt（客戶端即時訂單）
    firestore.collection('orders_rt').doc(bookingId).set(firestorePayload),

    // 寫入 bookings（完整訂單記錄）
    firestore.collection('bookings').doc(bookingId).set(firestorePayload),
  ]);

  console.log(`✅ 訂單 ${bookingId} 同步到 Firestore 成功`);
}
```

### 資料轉換規則

#### 1. GeoPoint 轉換

```typescript
// Supabase → Firestore
const pickupLocation = payload.pickup_latitude && payload.pickup_longitude
  ? {
      latitude: payload.pickup_latitude,
      longitude: payload.pickup_longitude
    }
  : null;
```

#### 2. Timestamp 轉換

```typescript
// Supabase → Firestore
const bookingTime = `${payload.start_date}T${payload.start_time}Z`;
// 範例：'2025-01-15' + 'T' + '09:00:00' + 'Z' = '2025-01-15T09:00:00Z'
```

#### 3. Boolean 轉換

```typescript
// Supabase → Firestore
const depositPaid = payload.status !== 'pending_payment';
// pending_payment → false
// 其他狀態 → true
```

---

## 📦 環境變數與端口固定

> **⚠️ 重要提示**：以下配置是固定的，請勿隨意更改！AI 助理請特別注意！

### 固定端口配置

| 服務 | 端口 | 環境變數 | 說明 | ⚠️ 不可更改 |
|------|------|---------|------|-----------|
| **Backend API** | `3000` | `PORT=3000` | Node.js 後端 API | ✅ 固定 |
| **Web Admin** | `3001` | `NEXT_PUBLIC_PORT=3001` | Next.js 管理後台 | ✅ 固定 |
| **Supabase Local DB** | `54322` | `DB_PORT=54322` | 本地 PostgreSQL | ✅ 固定 |
| **Supabase Studio** | `54323` | `STUDIO_PORT=54323` | Supabase 管理介面 | ✅ 固定 |

**為什麼固定端口？**
- 避免 CORS 配置錯誤
- 避免 API 端點配置錯誤
- 避免 Flutter APP 連接錯誤
- 避免之前發生的 port 3000/3001 混淆問題

### 關鍵環境變數

#### 1. Backend API 環境變數（`backend/.env`）

```bash
# ⚠️ 固定配置 - 不可更改
NODE_ENV=development
PORT=3000  # ← 固定端口
API_BASE_URL=http://localhost:3000
WEB_ADMIN_URL=http://localhost:3001  # ← 固定端口
CORS_ORIGIN=http://localhost:3001,http://localhost:3000

# Supabase 配置
SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>

# Firebase 配置
FIREBASE_PROJECT_ID=ride-platform-f1676
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@ride-platform-f1676.iam.gserviceaccount.com
```

#### 2. Flutter APP 環境變數（`mobile/.env`）

```bash
# ⚠️ 固定配置 - 不可更改
API_BASE_URL=http://localhost:3000/api  # ← 固定端口
WS_BASE_URL=ws://localhost:3000

# Firebase 配置
FIREBASE_PROJECT_ID=ride-platform-f1676
FIREBASE_API_KEY=AIzaSyC9HGGFyVONzKcjTNAr1FQo_ivGyrByQz4
FIREBASE_AUTH_DOMAIN=ride-platform-f1676.firebaseapp.com
FIREBASE_STORAGE_BUCKET=ride-platform-f1676.firebasestorage.app

# Supabase 配置
SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

#### 3. Web Admin 環境變數（`web-admin/.env.local`）

```bash
# ⚠️ 固定配置 - 不可更改
NEXT_PUBLIC_API_URL=http://localhost:3000  # ← 固定端口
NEXT_PUBLIC_PORT=3001  # ← 固定端口

# Supabase 配置
NEXT_PUBLIC_SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-anon-key>
```

### 不可更改的配置項目清單

| 配置項目 | 固定值 | 原因 |
|---------|-------|------|
| `PORT` (Backend) | `3000` | CORS、Flutter APP 連接 |
| `NEXT_PUBLIC_PORT` (Web Admin) | `3001` | CORS、API 端點 |
| `API_BASE_URL` | `http://localhost:3000` | Flutter APP 連接 |
| `SUPABASE_URL` | `https://vlyhwegpvpnjyocqmfqc.supabase.co` | 生產環境 Supabase 專案 |
| `FIREBASE_PROJECT_ID` | `ride-platform-f1676` | Firebase 專案 ID |

### Flutter 專案特定環境配置

#### Flavor 配置

```bash
# 客戶端 APP
flutter run --flavor customer --target lib/apps/customer/main_customer.dart

# 司機端 APP
flutter run --flavor driver --target lib/apps/driver/main_driver.dart
```

#### 環境變數載入

```dart
// mobile/lib/main.dart
await dotenv.load(fileName: ".env");

// 使用環境變數
final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
```

### 常見錯誤與解決方案

#### ❌ 錯誤 1：隨意更改端口

```bash
# ❌ 錯誤
PORT=3001  # Backend API 改為 3001

# 結果：Flutter APP 無法連接，CORS 錯誤
```

**解決方案**：
```bash
# ✅ 正確
PORT=3000  # 保持固定端口
```

#### ❌ 錯誤 2：API URL 配置錯誤

```dart
// ❌ 錯誤
final apiBaseUrl = 'http://localhost:3001/api';  // 錯誤端口

// ✅ 正確
final apiBaseUrl = 'http://localhost:3000/api';  // 正確端口
```

#### ❌ 錯誤 3：CORS 配置不匹配

```typescript
// ❌ 錯誤
CORS_ORIGIN=http://localhost:8080  // 錯誤端口

// ✅ 正確
CORS_ORIGIN=http://localhost:3001,http://localhost:3000
```

---

## 開發規範

### 修改代碼前必須檢查

- [ ] ✅ 查閱此架構文檔
- [ ] ✅ 確認使用正確的 ID 類型（`firebase_uid` vs `users.id`）
- [ ] ✅ 確認資料流向（寫入 Supabase，讀取 Firestore）
- [ ] ✅ 不要直接從 Flutter APP 寫入 Firestore（違反 CQRS）
- [ ] ✅ 不要混用 `firebase_uid` 和 `users.id`
- [ ] ✅ Backend API 必須先查詢 `users` 表轉換 ID

### 代碼審查清單

- [ ] 所有寫入操作都通過 Backend API
- [ ] Backend API 正確轉換 Firebase UID → Supabase UUID
- [ ] Firestore 查詢使用 Firebase UID
- [ ] Supabase 外鍵使用 Supabase UUID
- [ ] 沒有直接從 Flutter APP 寫入 Firestore

---

## 常見錯誤示例

### ❌ 錯誤 1：在 Supabase 中使用 Firebase UID

```typescript
// ❌ 錯誤
await supabase.from('bookings').insert({
  customer_id: 'hUu4fH5dTIW9VUYm6GojXvRLdni2', // Firebase UID
});

// ✅ 正確
const { data: user } = await supabase
  .from('users')
  .select('id')
  .eq('firebase_uid', 'hUu4fH5dTIW9VUYm6GojXvRLdni2')
  .single();

await supabase.from('bookings').insert({
  customer_id: user.id, // Supabase UUID
});
```

### ❌ 錯誤 2：在 Firestore 中使用 Supabase UUID

```typescript
// ❌ 錯誤
await firestore.collection('orders_rt').doc(bookingId).set({
  customerId: '550e8400-e29b-41d4-a716-446655440000', // Supabase UUID
});

// ✅ 正確
await firestore.collection('orders_rt').doc(bookingId).set({
  customerId: 'hUu4fH5dTIW9VUYm6GojXvRLdni2', // Firebase UID
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
  body: json.encode({
    'customerUid': currentUserId,
    // ...
  }),
);
```

### ❌ 錯誤 4：混用 ID 類型

```typescript
// ❌ 錯誤：查詢時混用 ID
const { data: booking } = await supabase
  .from('bookings')
  .select('*')
  .eq('customer_id', 'hUu4fH5dTIW9VUYm6GojXvRLdni2') // Firebase UID
  .single();

// ✅ 正確：先轉換 ID
const { data: user } = await supabase
  .from('users')
  .select('id')
  .eq('firebase_uid', 'hUu4fH5dTIW9VUYm6GojXvRLdni2')
  .single();

const { data: booking } = await supabase
  .from('bookings')
  .select('*')
  .eq('customer_id', user.id) // Supabase UUID
  .single();
```

---

## 快速參考指南

### 我應該使用哪個 ID？

| 我在... | 我應該使用... | 原因 |
|---------|--------------|------|
| Supabase `bookings` 表 | `users.id` (UUID) | 外鍵關聯 |
| Firestore `orders_rt` collection | `firebase_uid` | Flutter APP 查詢 |
| Backend API 接收參數 | `firebase_uid` | 從 Firebase Auth 獲取 |
| Backend API 寫入 Supabase | `users.id` (UUID) | 需要先查詢轉換 |

### 我應該從哪裡讀取資料？

| 我在... | 我應該從... | 原因 |
|---------|------------|------|
| Flutter APP | Firestore | 即時查詢、實時監聽 |
| Backend API | Supabase | 唯一真實數據源 |
| Web-admin | Supabase | 管理後台，需要完整資料 |

### 我應該往哪裡寫入資料？

| 我在... | 我應該往... | 原因 |
|---------|------------|------|
| Flutter APP | Backend API → Supabase | 遵循 CQRS 架構 |
| Backend API | Supabase | 唯一真實數據源 |
| Edge Function | Firestore | 同步鏡像資料 |

---

## 版本歷史

| 版本 | 日期 | 修改內容 |
|------|------|---------|
| 1.0 | 2025-01-12 | 初始版本 |

---

**最後更新**: 2025-01-12
**維護者**: 開發團隊
**聯絡方式**: [待補充]

