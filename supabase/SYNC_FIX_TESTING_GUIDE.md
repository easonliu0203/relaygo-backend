# 同步修復測試指南

**問題**：訂單創建成功，但客戶端顯示「訂單不存在」  
**根本原因**：Edge Function 的 aggregate_type 和 payload 欄位不匹配  
**狀態**：✅ 已修復 - 準備部署和測試

---

## 🔍 問題診斷結果

### 發現的問題

1. **aggregate_type 不匹配**
   - Trigger 創建：`'booking'`
   - Edge Function 檢查：`'order'` ❌
   - 結果：Edge Function 跳過所有事件

2. **payload 欄位不匹配**
   - Trigger 提供：`bookingNumber`, `startDate`, `startTime`, `durationHours` 等
   - Edge Function 期望：`dropoffAddress`, `bookingTime`, `passengerCount` 等 ❌
   - 結果：即使處理也會因欄位缺失而失敗

### 修復內容

**檔案**：`supabase/functions/sync-to-firestore/index.ts`

**修改 1**：aggregate_type 檢查
```typescript
// 修改前
if (event.aggregate_type === 'order') {  // ❌ 錯誤
  await syncOrderToFirestore(event)
}

// 修改後
if (event.aggregate_type === 'booking') {  // ✅ 正確
  await syncBookingToFirestore(event)
}
```

**修改 2**：payload 欄位映射
```typescript
// 修改前（不匹配 Trigger payload）
const firestoreData = {
  dropoffAddress: orderData.dropoffAddress,  // ❌ Trigger 沒有這個欄位
  bookingTime: orderData.bookingTime,        // ❌ Trigger 沒有這個欄位
  ...
}

// 修改後（匹配 Trigger payload）
const firestoreData = {
  bookingNumber: bookingData.bookingNumber,  // ✅ Trigger 有這個欄位
  destination: bookingData.destination,      // ✅ Trigger 有這個欄位
  startDate: bookingData.startDate,          // ✅ Trigger 有這個欄位
  startTime: bookingData.startTime,          // ✅ Trigger 有這個欄位
  ...
}
```

**修改 3**：增強日誌
- 添加詳細的同步日誌
- 添加錯誤狀態碼
- 添加 ✅ 成功指標

---

## 🚀 部署步驟

### 步驟 1：部署 Edge Function

**方法 A：使用自動化腳本**（推薦）
```bash
cd supabase
./deploy-edge-function-fix.sh
```

**方法 B：手動部署**
```bash
supabase functions deploy sync-to-firestore --project-ref vlyhwegpvpnjyocqmfqc
```

**預期輸出**：
```
Deploying Function sync-to-firestore...
✅ Function deployed successfully
```

---

### 步驟 2：診斷當前狀態

**執行診斷查詢**：
1. 打開 Supabase Dashboard SQL Editor
2. 執行 `supabase/diagnose-sync-issue.sql`
3. 檢查 6 個結果集

**重點檢查**：

#### 檢查 1：最近的訂單和同步狀態
```
期望看到：
- booking_id: <uuid>
- sync_status: '❌ 卡住了' 或 '⏳ 等待中'
- processed_at: NULL（修復前）
```

#### 檢查 2：Outbox 事件詳情
```
期望看到：
- aggregate_type: 'booking' ✅
- event_type: 'created'
- payload 包含 bookingNumber, startDate 等
- processed_at: NULL（修復前）
- error_message: NULL 或有錯誤訊息
```

#### 檢查 3：Cron Job 執行記錄
```
期望看到：
- 最近有執行記錄
- status: 可能是 'succeeded' 或 'failed'
- return_message: 檢查是否有錯誤
```

---

### 步驟 3：手動觸發 Edge Function 測試

**方法 A：使用 Supabase Dashboard**
1. 進入 Edge Functions 頁面
2. 找到 `sync-to-firestore`
3. 點擊「Invoke」按鈕
4. 查看執行結果

**方法 B：使用 curl**
```bash
curl -X POST \
  'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore' \
  -H 'Authorization: Bearer YOUR_ANON_KEY'
```

**預期輸出**：
```json
{
  "message": "事件處理完成",
  "total": 1,
  "success": 1,
  "failure": 0
}
```

---

### 步驟 4：驗證同步成功

**執行驗證查詢**：
```sql
-- 檢查事件是否已處理
SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  processed_at,
  CASE 
    WHEN processed_at IS NOT NULL THEN '✅ 已同步'
    ELSE '❌ 未同步'
  END as status
FROM outbox
WHERE created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC;
```

**預期結果**：
- `processed_at` 有值（不是 NULL）
- `status` 顯示 '✅ 已同步'

---

### 步驟 5：檢查 Firestore

**方法 A：使用 Firebase Console**
1. 打開 Firebase Console
2. 進入 Firestore Database
3. 查看 `orders_rt` 集合
4. 確認有對應的文檔（ID = booking_id）

**方法 B：使用客戶端測試**
1. 打開手機 App
2. 查看訂單詳情
3. 確認不再顯示「訂單不存在」

---

## ✅ 成功標準

### 立即成功（部署後）
- [x] Edge Function 部署成功
- [x] 手動觸發返回 success: 1
- [x] Outbox 事件 processed_at 有值
- [x] Firestore 有對應文檔

### 完整流程成功（創建新訂單）
- [x] 從 App 創建新訂單
- [x] 訂單創建成功（Supabase）
- [x] 事件創建成功（Outbox）
- [x] 30 秒內自動同步（Cron Job）
- [x] Firestore 有文檔
- [x] App 可以查看訂單詳情
- [x] 不再顯示「訂單不存在」

---

## 🔧 故障排除

### 問題 A：部署失敗

**症狀**：`supabase functions deploy` 失敗

**可能原因**：
1. 未登入 Supabase CLI
2. Project ref 錯誤
3. 網路問題

**解決方案**：
```bash
# 1. 登入
supabase login

# 2. 檢查 project
supabase projects list

# 3. 重新部署
supabase functions deploy sync-to-firestore --project-ref vlyhwegpvpnjyocqmfqc
```

---

### 問題 B：手動觸發失敗

**症狀**：手動觸發返回錯誤

**檢查 Edge Function 日誌**：
1. 進入 Supabase Dashboard
2. Edge Functions → sync-to-firestore
3. 查看 Logs 標籤
4. 檢查錯誤訊息

**常見錯誤**：

1. **"查詢 outbox 失敗"**
   - 原因：資料庫連接問題
   - 解決：檢查 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY

2. **"Firestore 更新失敗"**
   - 原因：Firebase 權限或配置問題
   - 解決：檢查 FIREBASE_PROJECT_ID 和 FIREBASE_API_KEY

3. **"未知的聚合類型"**
   - 原因：修復未生效
   - 解決：確認部署成功，重新部署

---

### 問題 C：processed_at 仍然是 NULL

**症狀**：手動觸發成功，但 processed_at 仍是 NULL

**診斷步驟**：

1. **檢查 Edge Function 日誌**
   ```
   查找：
   - "處理事件: <event_id>"
   - "事件 <event_id> 處理成功"
   - 或錯誤訊息
   ```

2. **檢查事件的 error_message**
   ```sql
   SELECT id, error_message, retry_count
   FROM outbox
   WHERE processed_at IS NULL
   ORDER BY created_at DESC;
   ```

3. **檢查 Firestore 錯誤**
   - 可能是權限問題
   - 可能是 API Key 無效
   - 可能是資料格式問題

---

### 問題 D：Firestore 沒有文檔

**症狀**：processed_at 有值，但 Firestore 沒有文檔

**可能原因**：
1. Firestore 權限問題
2. 集合名稱錯誤（應該是 `orders_rt`）
3. 文檔 ID 不匹配

**驗證步驟**：

1. **檢查 Edge Function 日誌**
   ```
   查找：
   - "✅ Firestore 文檔已更新: orders_rt/<booking_id>"
   - 或 "Firestore 更新失敗"
   ```

2. **檢查 Firestore 規則**
   ```javascript
   // 確保允許寫入
   match /orders_rt/{orderId} {
     allow write: if true;  // 測試用，生產環境需要更嚴格的規則
   }
   ```

3. **手動測試 Firestore API**
   ```bash
   curl -X PATCH \
     'https://firestore.googleapis.com/v1/projects/YOUR_PROJECT/databases/(default)/documents/orders_rt/test' \
     -H 'Authorization: Bearer YOUR_API_KEY' \
     -H 'Content-Type: application/json' \
     -d '{"fields": {"test": {"stringValue": "test"}}}'
   ```

---

### 問題 E：客戶端仍顯示「訂單不存在」

**症狀**：Firestore 有文檔，但客戶端讀取失敗

**可能原因**：
1. 客戶端使用錯誤的訂單 ID
2. Firestore 讀取權限問題
3. 客戶端快取問題

**診斷步驟**：

1. **檢查客戶端使用的 ID**
   ```dart
   // 在 booking_service.dart 中添加日誌
   debugPrint('[BookingService] 查詢訂單 ID: $orderId');
   ```

2. **檢查 Firestore 文檔 ID**
   ```sql
   -- 在 Supabase 中查詢
   SELECT id FROM bookings ORDER BY created_at DESC LIMIT 1;
   ```
   
   確認兩者匹配

3. **檢查 Firestore 讀取權限**
   ```javascript
   match /orders_rt/{orderId} {
     allow read: if true;  // 測試用
   }
   ```

4. **清除客戶端快取**
   - 重啟 App
   - 清除 App 資料
   - 重新登入

---

## 📊 完整驗證腳本

```sql
-- ============================================
-- 完整驗證腳本（部署後執行）
-- ============================================

-- 1. 檢查最近的訂單
SELECT '=== 1. 最近的訂單 ===' as check;
SELECT id, booking_number, status, created_at
FROM bookings
WHERE created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC;

-- 2. 檢查對應的事件
SELECT '=== 2. 對應的事件 ===' as check;
SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'bookingNumber' as booking_number,
  created_at,
  processed_at,
  error_message
FROM outbox
WHERE created_at >= NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC;

-- 3. 檢查同步狀態
SELECT '=== 3. 同步狀態 ===' as check;
SELECT 
  COUNT(*) as total_events,
  COUNT(*) FILTER (WHERE processed_at IS NOT NULL) as synced,
  COUNT(*) FILTER (WHERE processed_at IS NULL) as pending,
  COUNT(*) FILTER (WHERE error_message IS NOT NULL) as errors
FROM outbox
WHERE created_at >= NOW() - INTERVAL '10 minutes';

-- 4. 檢查 Cron Job 最近執行
SELECT '=== 4. Cron Job 最近執行 ===' as check;
SELECT 
  start_time,
  status,
  return_message
FROM cron.job_run_details
WHERE jobname = 'sync-orders-to-firestore'
ORDER BY start_time DESC
LIMIT 3;
```

**預期結果**：
- 檢查 1：有訂單
- 檢查 2：有事件，processed_at 有值
- 檢查 3：synced = total_events, pending = 0, errors = 0
- 檢查 4：最近有執行，status = 'succeeded'

---

## 🎯 測試流程總結

### 快速測試（5 分鐘）

1. **部署 Edge Function**（1 分鐘）
   ```bash
   ./supabase/deploy-edge-function-fix.sh
   ```

2. **手動觸發測試**（1 分鐘）
   - Supabase Dashboard → Edge Functions → Invoke

3. **檢查同步狀態**（2 分鐘）
   - 執行 `diagnose-sync-issue.sql`
   - 確認 processed_at 有值

4. **驗證 Firestore**（1 分鐘）
   - Firebase Console → Firestore
   - 確認有文檔

### 完整測試（10 分鐘）

1. **部署 Edge Function**（1 分鐘）
2. **創建新訂單**（3 分鐘）
   - 從 App 創建訂單
   - 完成支付
3. **等待自動同步**（30 秒）
4. **驗證完整流程**（5 分鐘）
   - 檢查 Supabase
   - 檢查 Outbox
   - 檢查 Firestore
   - 檢查 App

---

## 📚 相關文檔

| 文檔 | 用途 |
|------|------|
| `diagnose-sync-issue.sql` | 診斷同步問題 |
| `deploy-edge-function-fix.sh` | 自動化部署腳本 |
| `SYNC_FIX_TESTING_GUIDE.md` | 本文檔 |
| `docs/20251004_XXXX_04_Sync_Issue_Fix.md` | 開發歷程 |

---

**最後更新**：2025-10-04  
**狀態**：✅ 準備部署和測試  
**預計時間**：5-10 分鐘

