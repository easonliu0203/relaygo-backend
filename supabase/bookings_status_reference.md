# 📋 Bookings 表 Status 欄位完整參考

> **根據實際數據庫約束和狀態映射表整理**  
> **更新日期**: 2025-10-16

---

## 📊 Supabase 允許的 Status 值

根據您的狀態映射表，Supabase `bookings` 表的 `status` 欄位允許以下值：

### 完整列表（10 個狀態）

| # | Status 值 | 中文顯示 | 說明 | Firestore 映射 |
|---|-----------|---------|------|---------------|
| 1 | `pending_payment` | 待配對 | 訂單已創建，待支付訂金 | `pending` |
| 2 | `paid_deposit` | 待配對 | 已支付訂金，待派單 | `pending` |
| 3 | `matched` | 待司機確認 | 已派單，待司機確認 | `awaitingDriver` |
| 4 | `driver_confirmed` | 已配對 | 司機已確認接單 | `matched` |
| 5 | `driver_departed` | 進行中 | 司機已出發 | `inProgress` |
| 6 | `driver_arrived` | 進行中 | 司機已抵達 | `inProgress` |
| 7 | `trip_started` | 進行中 | 行程已開始 | `inProgress` |
| 8 | `trip_ended` | 待付尾款 | 行程已結束，待付尾款 | `awaitingBalance` |
| 9 | `completed` | 已完成 | 訂單已完成 | `completed` |
| 10 | `cancelled` | 已取消 | 訂單已取消 | `cancelled` |

---

## 🔄 狀態流轉圖

```
pending_payment (待配對)
    ↓ 支付訂金
paid_deposit (待配對)
    ↓ 手動派單
matched (待司機確認)
    ↓ 司機確認接單
driver_confirmed (已配對)
    ↓ 司機出發
driver_departed (進行中)
    ↓ 司機抵達
driver_arrived (進行中)
    ↓ 客戶開始行程
trip_started (進行中)
    ↓ 客戶結束行程
trip_ended (待付尾款)
    ↓ 支付尾款
completed (已完成)

任何狀態 → cancelled (已取消)
```

---

## 🎯 測試腳本使用的 Status

### test_realtime_sync.sql

**創建訂單時**：
- ✅ 使用智能檢測：從現有訂單獲取有效的 status
- ✅ 默認值：`'pending_payment'`（如果沒有現有訂單）

**更新訂單時**：
- ✅ 使用智能檢測：獲取不同的有效 status
- ✅ 建議值：`'paid_deposit'` 或 `'matched'`

---

## 📝 SQL CHECK 約束

根據您的數據庫，`status` 欄位的 CHECK 約束應該是：

```sql
CHECK (status IN (
  'pending_payment',
  'paid_deposit',
  'matched',
  'driver_confirmed',
  'driver_departed',
  'driver_arrived',
  'trip_started',
  'trip_ended',
  'completed',
  'cancelled'
))
```

**默認值**: `'pending_payment'`

---

## 🧪 測試建議

### 創建測試訂單

```sql
INSERT INTO bookings (
  customer_id,
  booking_number,
  status,
  pickup_location,
  destination,
  start_date,
  start_time,
  duration_hours,
  vehicle_type,
  base_price,
  total_amount,
  deposit_amount
) VALUES (
  (SELECT id FROM users WHERE role = 'customer' LIMIT 1),
  'TEST_' || EXTRACT(EPOCH FROM NOW())::BIGINT,
  'pending_payment',  -- ✅ 初始狀態
  'Test Location A',
  'Test Location B',
  CURRENT_DATE + INTERVAL '1 day',
  '14:00:00',
  8,
  'A',
  1500.00,
  1500.00,
  450.00
);
```

### 測試狀態流轉

```sql
-- 1. 支付訂金
UPDATE bookings
SET status = 'paid_deposit',
    updated_at = NOW()
WHERE booking_number = 'TEST_[時間戳]';

-- 2. 派單
UPDATE bookings
SET status = 'matched',
    updated_at = NOW()
WHERE booking_number = 'TEST_[時間戳]';

-- 3. 司機確認
UPDATE bookings
SET status = 'driver_confirmed',
    updated_at = NOW()
WHERE booking_number = 'TEST_[時間戳]';

-- 4. 司機出發
UPDATE bookings
SET status = 'driver_departed',
    updated_at = NOW()
WHERE booking_number = 'TEST_[時間戳]';

-- 5. 司機抵達
UPDATE bookings
SET status = 'driver_arrived',
    updated_at = NOW()
WHERE booking_number = 'TEST_[時間戳]';

-- 6. 開始行程
UPDATE bookings
SET status = 'trip_started',
    updated_at = NOW()
WHERE booking_number = 'TEST_[時間戳]';

-- 7. 結束行程
UPDATE bookings
SET status = 'trip_ended',
    updated_at = NOW()
WHERE booking_number = 'TEST_[時間戳]';

-- 8. 支付尾款
UPDATE bookings
SET status = 'completed',
    updated_at = NOW()
WHERE booking_number = 'TEST_[時間戳]';
```

---

## 🎨 狀態顏色映射

| Status | 顏色 | 用途 |
|--------|------|------|
| `pending_payment`, `paid_deposit` | 🟠 橙色 | 待配對 |
| `matched` | 🟡 淺橙色 | 待司機確認 |
| `driver_confirmed` | 🔵 藍色 | 已配對 |
| `driver_departed`, `driver_arrived`, `trip_started` | 🟢 綠色 | 進行中 |
| `trip_ended` | 🟡 金色 | 待付尾款 |
| `completed` | ⚪ 灰色 | 已完成 |
| `cancelled` | 🔴 紅色 | 已取消 |

---

## 🔍 查詢現有訂單的 Status 分佈

```sql
SELECT 
  status AS "狀態",
  COUNT(*) AS "數量",
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS "百分比",
  CASE status
    WHEN 'pending_payment' THEN '🟠 待配對'
    WHEN 'paid_deposit' THEN '🟠 待配對'
    WHEN 'matched' THEN '🟡 待司機確認'
    WHEN 'driver_confirmed' THEN '🔵 已配對'
    WHEN 'driver_departed' THEN '🟢 進行中'
    WHEN 'driver_arrived' THEN '🟢 進行中'
    WHEN 'trip_started' THEN '🟢 進行中'
    WHEN 'trip_ended' THEN '🟡 待付尾款'
    WHEN 'completed' THEN '⚪ 已完成'
    WHEN 'cancelled' THEN '🔴 已取消'
    ELSE '❓ 未知'
  END AS "顯示"
FROM bookings
GROUP BY status
ORDER BY COUNT(*) DESC;
```

---

## 📊 狀態統計

```sql
WITH status_stats AS (
  SELECT 
    CASE 
      WHEN status IN ('pending_payment', 'paid_deposit') THEN '待配對'
      WHEN status = 'matched' THEN '待司機確認'
      WHEN status = 'driver_confirmed' THEN '已配對'
      WHEN status IN ('driver_departed', 'driver_arrived', 'trip_started') THEN '進行中'
      WHEN status = 'trip_ended' THEN '待付尾款'
      WHEN status = 'completed' THEN '已完成'
      WHEN status = 'cancelled' THEN '已取消'
    END AS status_group,
    COUNT(*) AS count
  FROM bookings
  GROUP BY status_group
)
SELECT 
  status_group AS "狀態組",
  count AS "數量",
  ROUND(count * 100.0 / SUM(count) OVER (), 2) AS "百分比"
FROM status_stats
ORDER BY count DESC;
```

---

## 🚨 常見錯誤

### 錯誤 1: 使用不存在的 status 值

```
ERROR: 23514: new row for relation "bookings" violates check constraint "bookings_status_check"
```

**原因**: 使用了不在允許列表中的 status 值（如 `'pending'`, `'draft'`, `'confirmed'` 等）

**解決**: 只使用上面列出的 10 個有效 status 值

### 錯誤 2: status 為 NULL

```
ERROR: 23502: null value in column "status" violates not-null constraint
```

**原因**: status 欄位不允許為 NULL

**解決**: 始終提供 status 值，或使用默認值 `'pending_payment'`

---

## ✅ 最佳實踐

1. **創建訂單**: 始終使用 `'pending_payment'` 作為初始狀態
2. **狀態流轉**: 按照狀態流轉圖的順序更新
3. **取消訂單**: 可以從任何狀態直接變更為 `'cancelled'`
4. **測試**: 使用智能狀態檢測，從現有訂單獲取有效值
5. **監控**: 定期檢查狀態分佈，發現異常

---

## 📚 相關文檔

- **狀態映射表**: `docs/訂單狀態映射速查表.md`
- **API 端點**: 見狀態映射表中的 "API 端點" 欄位
- **Flutter 枚舉**: `BookingStatus` 枚舉定義

---

**更新日期**: 2025-10-16  
**版本**: v1.0.0

