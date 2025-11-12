# 取消訂單功能測試指南

**日期**：2025-10-07  
**功能**：取消訂單（使用 Supabase API）  
**狀態**：✅ 代碼完成，待部署和測試

---

## 📋 實現內容

### 1. 後端 API

**檔案**：`web-admin/src/app/api/bookings/[id]/cancel/route.ts`

**API 規格**：
```
POST /api/bookings/:id/cancel
Content-Type: application/json

Request Body:
{
  "customerUid": "hUu4fH5dTlW9VUYm6GojXvRLdni2",
  "reason": "行程有變，需要取消"
}

Response (成功):
{
  "success": true,
  "message": "訂單已成功取消",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "cancelled",
    "cancelledAt": "2025-10-07T15:30:00Z",
    "cancellationReason": "行程有變，需要取消"
  }
}

Response (失敗):
{
  "success": false,
  "error": "錯誤訊息"
}
```

**功能**：
1. ✅ 驗證用戶權限（只能取消自己的訂單）
2. ✅ 檢查訂單狀態（只能取消 pending 或 matched 狀態）
3. ✅ 更新 Supabase bookings 表
4. ✅ Trigger 自動寫入 outbox 表
5. ✅ Edge Function 自動同步到 Firestore

---

### 2. 客戶端方法

**檔案**：`mobile/lib/core/services/booking_service.dart`

**新增方法**：
```dart
/// 取消訂單（使用 Supabase API）
Future<Map<String, dynamic>> cancelBookingWithSupabase(
  String bookingId,
  String reason,
) async {
  // 調用 Supabase API
  // 資料將由 Supabase Trigger 自動鏡像到 Firestore
}
```

**舊版方法**：
```dart
/// 取消訂單（已棄用）
@Deprecated('請使用 cancelBookingWithSupabase 方法')
Future<void> cancelBooking(String orderId) async {
  throw Exception('此方法已棄用...');
}
```

---

### 3. Provider 方法

**檔案**：`mobile/lib/shared/providers/booking_provider.dart`

**新增方法**：
```dart
/// 取消預約（使用 Supabase API）
Future<void> cancelBookingWithSupabase(String bookingId, String reason) async {
  // 調用 BookingService.cancelBookingWithSupabase()
  // 更新狀態
}
```

---

### 4. UI 更新

**檔案**：`mobile/lib/apps/customer/presentation/pages/order_detail_page.dart`

**修改內容**：
- ✅ 添加取消原因輸入框
- ✅ 驗證取消原因長度（5-200 字元）
- ✅ 調用 `cancelBookingWithSupabase()` 方法

---

### 5. 資料庫 Migration

**檔案**：`supabase/migrations/20250102_add_cancellation_fields.sql`

**新增欄位**：
- ✅ `cancellation_reason` TEXT - 取消原因
- ✅ `cancelled_at` TIMESTAMP - 取消時間

---

## 🚀 部署步驟

### 步驟 1：執行資料庫 Migration

**方法 A：使用 Supabase CLI**
```bash
# 進入專案根目錄
cd d:/repo

# 執行 migration
supabase db push
```

**方法 B：使用 Supabase Dashboard**
1. 前往：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/editor
2. 點擊「SQL Editor」
3. 複製 `supabase/migrations/20250102_add_cancellation_fields.sql` 內容
4. 執行 SQL

**驗證**：
```sql
-- 檢查欄位是否已添加
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'bookings' 
  AND column_name IN ('cancellation_reason', 'cancelled_at');
```

**預期結果**：
```
column_name          | data_type
---------------------|---------------------------
cancellation_reason  | text
cancelled_at         | timestamp with time zone
```

---

### 步驟 2：啟動管理後台（如果尚未啟動）

```bash
# 進入管理後台目錄
cd web-admin

# 安裝依賴（如果尚未安裝）
npm install

# 啟動開發伺服器
npm run dev
```

**驗證**：
- 打開：http://localhost:3001
- 確認伺服器正常運行

---

### 步驟 3：重新建置客戶端 App

```bash
# 進入 mobile 目錄
cd mobile

# 清理舊的建置
flutter clean

# 獲取依賴
flutter pub get

# 運行客戶端應用
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

---

## ✅ 測試步驟

### 測試 1：API 端點測試（使用 Postman 或 curl）

**測試 1.1：成功取消訂單**

```bash
curl -X POST http://localhost:3001/api/bookings/{booking-id}/cancel \
  -H "Content-Type: application/json" \
  -d '{
    "customerUid": "hUu4fH5dTlW9VUYm6GojXvRLdni2",
    "reason": "行程有變，需要取消"
  }'
```

**預期結果**：
```json
{
  "success": true,
  "message": "訂單已成功取消",
  "data": {
    "id": "...",
    "status": "cancelled",
    "cancelledAt": "2025-10-07T15:30:00Z",
    "cancellationReason": "行程有變，需要取消"
  }
}
```

---

**測試 1.2：取消原因太短**

```bash
curl -X POST http://localhost:3001/api/bookings/{booking-id}/cancel \
  -H "Content-Type: application/json" \
  -d '{
    "customerUid": "hUu4fH5dTlW9VUYm6GojXvRLdni2",
    "reason": "取消"
  }'
```

**預期結果**：
```json
{
  "success": false,
  "error": "取消原因至少需要 5 個字元"
}
```

---

**測試 1.3：權限不足（嘗試取消別人的訂單）**

```bash
curl -X POST http://localhost:3001/api/bookings/{booking-id}/cancel \
  -H "Content-Type: application/json" \
  -d '{
    "customerUid": "wrong-user-id",
    "reason": "行程有變，需要取消"
  }'
```

**預期結果**：
```json
{
  "success": false,
  "error": "您沒有權限取消此訂單"
}
```

---

**測試 1.4：訂單狀態不允許取消**

```bash
# 嘗試取消已完成的訂單
curl -X POST http://localhost:3001/api/bookings/{completed-booking-id}/cancel \
  -H "Content-Type: application/json" \
  -d '{
    "customerUid": "hUu4fH5dTlW9VUYm6GojXvRLdni2",
    "reason": "行程有變，需要取消"
  }'
```

**預期結果**：
```json
{
  "success": false,
  "error": "訂單狀態為 completed，無法取消。只能取消待配對或已配對的訂單。"
}
```

---

### 測試 2：Supabase 資料驗證

**步驟**：
1. 打開 Supabase Dashboard
2. 前往：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/editor
3. 執行查詢：

```sql
SELECT 
  id,
  booking_number,
  status,
  cancellation_reason,
  cancelled_at,
  updated_at
FROM bookings
WHERE status = 'cancelled'
ORDER BY cancelled_at DESC
LIMIT 5;
```

**預期結果**：
```
id                                   | booking_number | status    | cancellation_reason      | cancelled_at
-------------------------------------|----------------|-----------|--------------------------|-------------------------
550e8400-e29b-41d4-a716-446655440000 | BK20251007001  | cancelled | 行程有變，需要取消       | 2025-10-07 15:30:00+00
```

---

### 測試 3：Outbox 事件驗證

**步驟**：
1. 執行查詢：

```sql
SELECT 
  id,
  aggregate_type,
  aggregate_id,
  event_type,
  payload->>'status' as status,
  payload->>'cancellationReason' as cancellation_reason,
  created_at,
  processed_at
FROM outbox
WHERE aggregate_id = '{booking-id}'
ORDER BY created_at DESC
LIMIT 5;
```

**預期結果**：
```
aggregate_type | event_type | status    | cancellation_reason      | processed_at
---------------|------------|-----------|--------------------------|-------------
booking        | updated    | cancelled | 行程有變，需要取消       | NULL (待處理)
```

---

### 測試 4：Firestore 同步驗證

**步驟**：
1. 等待 30 秒（Cron Job 執行週期）
2. 或手動觸發 Edge Function：
   ```
   https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions
   ```
3. 打開 Firebase Console → Firestore Database
4. 檢查 `orders_rt` 集合
5. 檢查 `bookings` 集合

**預期結果**：
```
orders_rt/{booking-id}:
  status: "cancelled"
  
bookings/{booking-id}:
  status: "cancelled"
```

---

### 測試 5：客戶端 App 測試（完整流程）⭐

**步驟 1：創建測試訂單**
1. 啟動客戶端 App
2. 登入測試帳號
3. 創建新訂單
4. 支付訂金
5. 記下訂單 ID

---

**步驟 2：取消訂單**
1. 進入「我的訂單」頁面
2. 點擊訂單查看詳情
3. 點擊「取消訂單」按鈕
4. 輸入取消原因：「測試取消功能」
5. 確認取消

**預期結果**：
- ✅ 顯示取消原因輸入框
- ✅ 驗證取消原因長度（少於 5 個字元會提示錯誤）
- ✅ 取消成功後顯示「訂單已取消」訊息
- ✅ 訂單狀態變為「已取消」

---

**步驟 3：驗證訂單狀態**
1. 返回「我的訂單」頁面
2. 確認訂單狀態顯示為「已取消」
3. 重新進入訂單詳情
4. 確認「取消訂單」按鈕已隱藏或禁用

---

**步驟 4：驗證資料同步**
1. 檢查 Supabase `bookings` 表（應該有 `cancellation_reason` 和 `cancelled_at`）
2. 檢查 Supabase `outbox` 表（應該有更新事件）
3. 等待 30 秒
4. 檢查 Firestore `orders_rt` 集合（狀態應該為 `cancelled`）
5. 檢查 Firestore `bookings` 集合（狀態應該為 `cancelled`）

---

## 🔍 故障排除

### 問題 1：資料庫欄位不存在

**錯誤訊息**：
```
column "cancellation_reason" of relation "bookings" does not exist
```

**解決方案**：
1. 確認 migration 已執行
2. 執行：
   ```sql
   ALTER TABLE bookings ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
   ALTER TABLE bookings ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE;
   ```

---

### 問題 2：API 返回 404

**可能原因**：
- 管理後台未啟動
- 路由路徑錯誤

**解決方案**：
1. 確認管理後台正在運行：http://localhost:3001
2. 檢查 API 路徑：`/api/bookings/{id}/cancel`
3. 檢查檔案路徑：`web-admin/src/app/api/bookings/[id]/cancel/route.ts`

---

### 問題 3：權限錯誤

**錯誤訊息**：
```
您沒有權限取消此訂單
```

**可能原因**：
- `customerUid` 不匹配
- 訂單的 `customer_id` 對應的 `firebase_uid` 不正確

**解決方案**：
1. 檢查 `users` 表中的 `firebase_uid`
2. 確認請求中的 `customerUid` 正確
3. 執行查詢驗證：
   ```sql
   SELECT u.firebase_uid, b.id, b.booking_number
   FROM bookings b
   JOIN users u ON b.customer_id = u.id
   WHERE b.id = '{booking-id}';
   ```

---

### 問題 4：Firestore 未同步

**可能原因**：
- Edge Function 未執行
- Outbox 事件未處理

**解決方案**：
1. 檢查 `outbox` 表：
   ```sql
   SELECT * FROM outbox WHERE processed_at IS NULL;
   ```
2. 手動觸發 Edge Function
3. 檢查 Edge Function 日誌

---

## 📊 測試檢查清單

### 資料庫層面
- [ ] Migration 已執行
- [ ] `cancellation_reason` 欄位已添加
- [ ] `cancelled_at` 欄位已添加
- [ ] 索引已創建

### API 層面
- [ ] 成功取消訂單（200 OK）
- [ ] 取消原因太短（400 Bad Request）
- [ ] 權限不足（403 Forbidden）
- [ ] 訂單不存在（404 Not Found）
- [ ] 訂單狀態不允許取消（400 Bad Request）

### 資料同步層面
- [ ] Supabase `bookings` 表已更新
- [ ] Supabase `outbox` 表有事件
- [ ] Firestore `orders_rt` 集合已同步
- [ ] Firestore `bookings` 集合已同步

### 客戶端層面
- [ ] 取消原因輸入框顯示正常
- [ ] 取消原因驗證正常
- [ ] 取消成功訊息顯示
- [ ] 訂單狀態更新
- [ ] 取消按鈕狀態正確

---

## 💡 關鍵要點

### 1. CQRS 架構遵循

**正確的流程**：
```
客戶端 App
    ↓ POST /api/bookings/:id/cancel
Supabase/PostgreSQL (更新 bookings 表)
    ↓ Trigger
Outbox 表 (寫入事件)
    ↓ Cron Job
Edge Function (消費事件)
    ↓ 雙寫
Firestore (orders_rt + bookings)
    ↑ 讀取
客戶端 App (顯示更新後的狀態)
```

**關鍵原則**：
- ✅ 所有寫入操作都通過 Supabase API
- ✅ Firestore 只作為 Read Model
- ✅ 客戶端不直接寫入 Firestore

---

### 2. 取消原因的重要性

**為什麼需要取消原因？**
- 業務分析：了解客戶取消訂單的原因
- 服務改進：根據取消原因改進服務
- 爭議處理：有記錄可查

**驗證規則**：
- 最少 5 個字元
- 最多 200 個字元
- 必填欄位

---

### 3. 訂單狀態管理

**可取消的狀態**：
- `pending` - 待配對
- `matched` - 已配對

**不可取消的狀態**：
- `in_progress` - 進行中
- `completed` - 已完成
- `cancelled` - 已取消

---

## 📚 相關文檔

1. **`docs/20251007_0847_12_CQRS架構審查報告.md`**
   - 完整的架構審查報告

2. **`CQRS架構修復計劃.md`**
   - 詳細的修復步驟

3. **`docs/20251007_2305_13_CQRS架構修復第一階段完成.md`**
   - 第一階段修復報告

4. **`web-admin/src/app/api/bookings/[id]/cancel/route.ts`**
   - 取消訂單 API 實現

5. **`mobile/lib/core/services/booking_service.dart`**
   - 客戶端服務實現

---

**測試狀態**：⏳ 待執行  
**預計時間**：30-45 分鐘  
**風險等級**：低（可以隨時回滾）

🚀 **請按照測試步驟執行完整測試，確認取消訂單功能正常運作！**

