# 🚨 修復 'matched' 狀態錯誤

**日期**：2025-01-12  
**錯誤代碼**：23514  
**錯誤訊息**：`new row for relation "bookings" violates check constraint "bookings_status_check"`

---

## ❌ 問題描述

**操作**：手動派單（分配司機給訂單）

**錯誤**：
```
❌ 更新訂單失敗: {
  code: '23514',
  message: 'new row for relation "bookings" violates check constraint "bookings_status_check"'
}
```

**根本原因**：

1. **手動派單 API 使用 `'matched'` 狀態**
   - 文件：`web-admin/src/app/api/admin/bookings/[id]/assign-driver/route.ts`
   - 第 166 行：`status: 'matched'`

2. **CHECK 約束不允許 `'matched'` 狀態**
   - 當前的 `bookings_status_check` 約束只允許：
     - `'pending_payment'`, `'paid_deposit'`, `'assigned'`, `'driver_confirmed'`, `'driver_departed'`, `'driver_arrived'`, `'in_progress'`, `'completed'`, `'cancelled'`
   - 不包含 `'matched'`, `'pending'`, `'inProgress'` 等 Flutter APP 使用的狀態

3. **狀態定義不一致**
   - Backend API 使用：`'pending_payment'`, `'paid_deposit'`, `'assigned'` 等
   - Flutter APP 使用：`'pending'`, `'matched'`, `'inProgress'` 等
   - Web Admin 使用：`'matched'`（與 Flutter APP 一致）

---

## ✅ 解決方案

### 步驟 1：執行 SQL 腳本修復 CHECK 約束（5 分鐘）⚠️ **必須執行**

1. **打開 Supabase Dashboard**
   - 網址：https://supabase.com/dashboard
   - 進入 SQL Editor

2. **執行 SQL 腳本**
   - 打開文件：`supabase/fix-bookings-status-constraint-complete.sql`
   - 複製全部內容
   - 貼上到 SQL Editor
   - 點擊「Run」執行

3. **確認執行成功**

   **步驟 1：檢查當前的 CHECK 約束**
   ```
   約束名稱 | 約束定義
   ---------|----------
   bookings_status_check | CHECK (status IN ('pending_payment', 'paid_deposit', ...))
   ```

   **步驟 3：刪除舊的 CHECK 約束**
   ```
   ✅ 舊的 CHECK 約束已刪除
   ```

   **步驟 4：添加新的 CHECK 約束**
   ```
   ✅ 新的 CHECK 約束已添加
   ```

   **步驟 5：驗證新的 CHECK 約束**
   ```
   約束名稱 | 約束定義
   ---------|----------
   bookings_status_check | CHECK (status IN ('pending_payment', 'paid_deposit', 'assigned', 'driver_confirmed', 'driver_departed', 'driver_arrived', 'in_progress', 'completed', 'cancelled', 'pending', 'matched', 'inProgress', 'confirmed'))
   ```

   **步驟 7-8：檢查所有訂單**
   ```
   所有訂單的檢查結果都應該是 ✅ 符合約束
   ```

---

### 步驟 2：重新測試手動派單功能（2 分鐘）

1. **登入公司端 Web Admin**
   - 網址：http://localhost:3001

2. **進入「待處理訂單」頁面**

3. **選擇訂單並手動派單**
   - 選擇訂單 ID: `b6bac7fb-e78f-4166-9b6c-8949118bfffc`
   - 點擊「手動派單」
   - 選擇司機：`driver.test@relaygo.com`
   - 點擊「確認分配」

4. **確認分配成功**

   **預期日誌**：
   ```
   📋 手動分配司機: {
     bookingId: 'b6bac7fb-e78f-4166-9b6c-8949118bfffc',
     driverId: '416556f9-adbf-4c2e-920f-164d80f5307a'
   }
   ✅ 成功分配司機: {
     bookingId: 'b6bac7fb-e78f-4166-9b6c-8949118bfffc',
     driverId: '416556f9-adbf-4c2e-920f-164d80f5307a',
     status: 'matched'
   }
   ```

   **預期結果**：
   - ✅ 分配成功
   - ✅ 訂單狀態更新為 `'matched'`
   - ✅ 司機已分配

---

## 📊 修復摘要

### 問題根本原因

**三套不同的狀態定義**：

| 系統 | 狀態定義 |
|------|---------|
| **Backend API** | `pending_payment`, `paid_deposit`, `assigned`, `driver_confirmed`, `driver_departed`, `driver_arrived`, `in_progress`, `completed`, `cancelled` |
| **Flutter APP** | `pending`, `matched`, `inProgress`, `completed`, `cancelled` |
| **Web Admin** | `matched`（與 Flutter APP 一致）|
| **CHECK 約束（舊）** | 只包含 Backend API 的狀態 |

**問題**：
- Web Admin 手動派單時使用 `'matched'` 狀態
- 但 CHECK 約束不允許 `'matched'`
- 導致更新失敗

### 修復方案

**更新 CHECK 約束，包含所有狀態**：

```sql
ALTER TABLE bookings ADD CONSTRAINT bookings_status_check 
CHECK (status IN (
    -- Backend API 狀態
    'pending_payment', 'paid_deposit', 'assigned', 'driver_confirmed',
    'driver_departed', 'driver_arrived', 'in_progress', 'completed', 'cancelled',
    -- Flutter APP 狀態
    'pending', 'matched', 'inProgress',
    -- 舊的狀態（向後兼容）
    'confirmed'
));
```

**修復效果**：
- ✅ 支援所有 Backend API 使用的狀態
- ✅ 支援所有 Flutter APP 使用的狀態
- ✅ 支援 Web Admin 使用的狀態
- ✅ 向後兼容舊的狀態

---

## 🎯 手動派單 API 代碼分析

**文件**：`web-admin/src/app/api/admin/bookings/[id]/assign-driver/route.ts`

**第 166 行**：
```typescript
status: 'matched',  // 使用 'matched' 而不是 'assigned'，與 Flutter 應用的狀態定義一致
```

**為什麼使用 `'matched'`？**
- 與 Flutter APP 的狀態定義一致
- Flutter APP 的 `BookingStatus` 枚舉中有 `matched` 狀態
- 表示「已配對司機」

**為什麼不使用 `'assigned'`？**
- `'assigned'` 是 Backend API 的狀態
- 但 Flutter APP 不認識這個狀態
- 會導致 Flutter APP 無法正確顯示訂單狀態

---

## 🚨 重要提醒

**必須執行 SQL 腳本才能修復問題！**

**執行步驟**：
1. 打開 Supabase Dashboard
2. 進入 SQL Editor
3. 執行 `supabase/fix-bookings-status-constraint-complete.sql`
4. 確認所有步驟都顯示 ✅
5. 重新測試手動派單功能

**預計時間**：5 分鐘

---

## 📝 相關文檔

- **SQL 腳本**：`supabase/fix-bookings-status-constraint-complete.sql`
- **手動派單 API**：`web-admin/src/app/api/admin/bookings/[id]/assign-driver/route.ts`
- **訂單狀態問題說明**：`docs/ORDER_STATUS_ISSUE_EXPLANATION.md`

---

**修復完成時間**：2025-01-12  
**修復者**：Augment Agent  
**狀態**：等待執行 SQL 腳本

