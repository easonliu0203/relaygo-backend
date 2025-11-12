# 🔴 訂單狀態不一致問題說明

**問題發現日期**：2025-01-12  
**嚴重程度**：🔴 高（影響訂單顯示和同步）  
**狀態**：需要修復

---

## 📋 問題總覽

系統中存在 **三套不同的訂單狀態定義**，導致訂單無法正確顯示在「進行中」頁面：

| 系統 | 狀態定義 | 文件位置 |
|------|---------|---------|
| **Supabase bookings 資料表** | `pending`, `confirmed`, `assigned`, `in_progress`, `completed`, `cancelled` | `database/schema.sql` |
| **Backend API** | `pending_payment`, `paid_deposit`, `assigned`, `driver_confirmed`, `driver_departed`, `driver_arrived`, `in_progress`, `completed`, `cancelled` | `backend/src/routes/bookings.ts` |
| **Flutter APP** | `pending`, `matched`, `inProgress`, `completed`, `cancelled` | `mobile/lib/core/models/booking_order.dart` |

---

## 🔴 問題 1：Supabase bookings 資料表的狀態定義與 Backend API 不一致

### Supabase bookings 資料表的狀態定義

**文件**：`database/schema.sql`（第 84 行）

```sql
CREATE TABLE bookings (
    -- ...
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',      -- 待處理
        'confirmed',    -- 已確認
        'assigned',     -- 已分配司機
        'in_progress',  -- 進行中
        'completed',    -- 已完成
        'cancelled'     -- 已取消
    )),
    -- ...
);
```

**問題**：
- ❌ 沒有 `pending_payment` 狀態（待付訂金）
- ❌ 沒有 `paid_deposit` 狀態（已付訂金）
- ❌ 沒有 `driver_confirmed` 狀態（司機已確認）
- ❌ 沒有 `driver_departed` 狀態（司機已出發）
- ❌ 沒有 `driver_arrived` 狀態（司機已到達）

### Backend API 使用的狀態

**文件**：`backend/src/routes/bookings.ts`

**創建訂單時**（第 165 行）：
```typescript
status: 'pending_payment', // 待付訂金
```

**支付訂金後**（第 330 行）：
```typescript
status: 'paid_deposit', // 已付訂金
```

**問題**：
- ❌ Backend API 使用的狀態 `pending_payment` 和 `paid_deposit` 在 Supabase 的 CHECK 約束中不存在
- ❌ 這會導致插入訂單時失敗（如果 CHECK 約束生效）
- ❌ 或者訂單狀態不正確（如果 CHECK 約束未生效）

---

## 🔴 問題 2：Flutter APP 的狀態定義與 Supabase 不一致

### Flutter APP 的狀態定義

**文件**：`mobile/lib/core/models/booking_order.dart`（第 9-24 行）

```dart
enum BookingStatus {
  @JsonValue('pending')
  pending,        // 待配對
  
  @JsonValue('matched')
  matched,        // 已配對
  
  @JsonValue('inProgress')
  inProgress,     // 進行中
  
  @JsonValue('completed')
  completed,      // 已完成
  
  @JsonValue('cancelled')
  cancelled,      // 已取消
}
```

**問題**：
- ❌ 沒有 `pending_payment` 狀態（待付訂金）
- ❌ 沒有 `paid_deposit` 狀態（已付訂金）
- ❌ 沒有 `confirmed` 狀態（已確認）
- ❌ 沒有 `assigned` 狀態（已分配司機）
- ❌ 使用 `inProgress` 而不是 `in_progress`（駝峰命名 vs 下劃線命名）

### 「進行中」頁面的查詢邏輯

**文件**：`mobile/lib/core/services/booking_service.dart`（第 354-358 行）

```dart
.where('status', whereIn: [
  BookingStatus.pending.name,      // 'pending'
  BookingStatus.matched.name,      // 'matched'
  BookingStatus.inProgress.name,   // 'inProgress'
])
```

**問題**：
- ❌ 查詢 `status = 'pending'`，但 Backend API 創建的訂單狀態是 `'pending_payment'`
- ❌ 查詢 `status = 'matched'`，但 Supabase 沒有這個狀態
- ❌ 查詢 `status = 'inProgress'`，但 Supabase 使用 `'in_progress'`

**結果**：
- ❌ 「進行中」頁面無法顯示任何訂單
- ❌ 因為 Firestore 中的訂單狀態是 `'pending_payment'`，不匹配查詢條件

---

## 🔴 問題 3：Firestore 同步的訂單狀態不正確

### 當前的訂單狀態

根據您的描述：
- Firestore 的 `orders_rt` collection 中的訂單狀態是 `"pending_payment"`
- 這是 Backend API 創建訂單時設置的狀態

### 問題

1. **Flutter APP 無法識別 `pending_payment` 狀態**
   - `BookingStatus` 枚舉中沒有這個狀態
   - 可能導致解析錯誤或顯示為未知狀態

2. **「進行中」頁面無法顯示訂單**
   - 查詢條件是 `status IN ['pending', 'matched', 'inProgress']`
   - 但訂單狀態是 `'pending_payment'`
   - 不匹配，所以不會顯示

3. **訂單狀態流程不清晰**
   - `pending_payment` → `paid_deposit` → `assigned` → `in_progress` → `completed`
   - 但 Flutter APP 只有 5 個狀態：`pending`, `matched`, `inProgress`, `completed`, `cancelled`

---

## ✅ 解決方案

### 方案 1：統一訂單狀態定義（推薦）

**步驟 1：修改 Supabase bookings 資料表的 CHECK 約束**

```sql
-- 刪除舊的 CHECK 約束
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;

-- 添加新的 CHECK 約束（包含所有狀態）
ALTER TABLE bookings ADD CONSTRAINT bookings_status_check 
CHECK (status IN (
    'pending_payment',    -- 待付訂金
    'paid_deposit',       -- 已付訂金
    'assigned',           -- 已分配司機
    'driver_confirmed',   -- 司機已確認
    'driver_departed',    -- 司機已出發
    'driver_arrived',     -- 司機已到達
    'in_progress',        -- 進行中
    'completed',          -- 已完成
    'cancelled'           -- 已取消
));
```

**步驟 2：修改 Flutter APP 的 BookingStatus 枚舉**

```dart
enum BookingStatus {
  @JsonValue('pending_payment')
  pendingPayment,        // 待付訂金
  
  @JsonValue('paid_deposit')
  paidDeposit,          // 已付訂金
  
  @JsonValue('assigned')
  assigned,             // 已分配司機
  
  @JsonValue('driver_confirmed')
  driverConfirmed,      // 司機已確認
  
  @JsonValue('driver_departed')
  driverDeparted,       // 司機已出發
  
  @JsonValue('driver_arrived')
  driverArrived,        // 司機已到達
  
  @JsonValue('in_progress')
  inProgress,           // 進行中
  
  @JsonValue('completed')
  completed,            // 已完成
  
  @JsonValue('cancelled')
  cancelled,            // 已取消
}
```

**步驟 3：修改「進行中」頁面的查詢邏輯**

```dart
.where('status', whereIn: [
  BookingStatus.pendingPayment.name,    // 'pending_payment'
  BookingStatus.paidDeposit.name,       // 'paid_deposit'
  BookingStatus.assigned.name,          // 'assigned'
  BookingStatus.driverConfirmed.name,   // 'driver_confirmed'
  BookingStatus.driverDeparted.name,    // 'driver_departed'
  BookingStatus.driverArrived.name,     // 'driver_arrived'
  BookingStatus.inProgress.name,        // 'in_progress'
])
```

**步驟 4：修改「歷史訂單」頁面的查詢邏輯**

```dart
.where('status', whereIn: [
  BookingStatus.completed.name,   // 'completed'
  BookingStatus.cancelled.name,   // 'cancelled'
])
```

### 方案 2：在 Edge Function 中轉換狀態（臨時方案）

如果不想修改 Flutter APP 的代碼，可以在 Edge Function 同步到 Firestore 時轉換狀態：

```typescript
// Supabase → Firestore 狀態映射
const statusMapping = {
  'pending_payment': 'pending',
  'paid_deposit': 'pending',
  'assigned': 'matched',
  'driver_confirmed': 'matched',
  'driver_departed': 'inProgress',
  'driver_arrived': 'inProgress',
  'in_progress': 'inProgress',
  'completed': 'completed',
  'cancelled': 'cancelled',
};

// 轉換狀態
const firestoreStatus = statusMapping[supabaseStatus] || 'pending';
```

**問題**：
- ❌ 狀態資訊丟失（例如 `pending_payment` 和 `paid_deposit` 都變成 `pending`）
- ❌ 無法區分訂單的詳細狀態
- ❌ 不利於後續功能擴展

---

## 📊 推薦的訂單狀態流程

```
1. pending_payment    (待付訂金)
   ↓ 客戶支付訂金
2. paid_deposit       (已付訂金，等待分配司機)
   ↓ 系統或管理員分配司機
3. assigned           (已分配司機，等待司機確認)
   ↓ 司機確認接單
4. driver_confirmed   (司機已確認，等待出發)
   ↓ 司機出發前往上車地點
5. driver_departed    (司機已出發)
   ↓ 司機到達上車地點
6. driver_arrived     (司機已到達)
   ↓ 開始行程
7. in_progress        (行程進行中)
   ↓ 行程結束
8. completed          (已完成)

或者在任何階段：
   ↓ 取消訂單
9. cancelled          (已取消)
```

---

## ✅ 立即修復步驟

### 步驟 1：修改 Supabase bookings 資料表的 CHECK 約束

創建 SQL 腳本：`supabase/fix-booking-status-constraint.sql`

```sql
-- 刪除舊的 CHECK 約束
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;

-- 添加新的 CHECK 約束（包含所有狀態）
ALTER TABLE bookings ADD CONSTRAINT bookings_status_check 
CHECK (status IN (
    'pending_payment',
    'paid_deposit',
    'assigned',
    'driver_confirmed',
    'driver_departed',
    'driver_arrived',
    'in_progress',
    'completed',
    'cancelled'
));
```

### 步驟 2：執行 SQL 腳本

1. 打開 Supabase Dashboard
2. 進入 SQL Editor
3. 複製上述 SQL 腳本
4. 執行

### 步驟 3：驗證修復結果

```sql
-- 檢查 CHECK 約束
SELECT 
    conname AS "約束名稱",
    pg_get_constraintdef(oid) AS "約束定義"
FROM pg_constraint
WHERE conrelid = 'bookings'::regclass
  AND contype = 'c';
```

### 步驟 4：測試訂單創建

1. 在客戶端 APP 創建新訂單
2. 確認訂單狀態為 `pending_payment`
3. 支付訂金
4. 確認訂單狀態更新為 `paid_deposit`
5. 檢查 Firestore 的 `orders_rt` collection
6. 確認訂單正確同步

---

## 🎉 總結

**問題根源**：
- 三套不同的訂單狀態定義（Supabase, Backend API, Flutter APP）
- 狀態不一致導致訂單無法正確顯示和同步

**解決方案**：
- ✅ 修改 Supabase bookings 資料表的 CHECK 約束（立即執行）
- ⚠️ 修改 Flutter APP 的 BookingStatus 枚舉（後續任務）
- ⚠️ 修改「進行中」和「歷史訂單」頁面的查詢邏輯（後續任務）

**優先級**：
1. 🔴 **立即執行**：修改 Supabase bookings 資料表的 CHECK 約束
2. 🟡 **後續任務**：修改 Flutter APP 的 BookingStatus 枚舉
3. 🟡 **後續任務**：修改查詢邏輯

**修復完成時間**：2025-01-12  
**修復者**：Augment Agent  
**狀態**：需要執行 SQL 腳本

