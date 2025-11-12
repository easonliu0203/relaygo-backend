# Outbox Pattern 設置指南

## 📋 概述

本指南說明如何設置 Outbox Pattern 實現 Supabase 到 Firestore 的單向資料鏡像。

### 架構設計

```
App → Supabase API → orders 表
                        ↓
                   Trigger 監聽
                        ↓
                   outbox 表（事件佇列）
                        ↓
                Edge Function 消費
                        ↓
              Firestore orders_rt 集合（鏡像）
                        ↓
                   App 即時讀取
```

### 關鍵特性

- ✅ **Single Source of Truth**：Supabase 是唯一的資料寫入來源
- ✅ **單向鏡像**：資料只從 Supabase 流向 Firestore
- ✅ **解耦設計**：寫入和即時展示完全解耦
- ✅ **可靠性**：使用 outbox 表確保事件不丟失
- ✅ **重試機制**：失敗事件自動重試（最多 3 次）
- ✅ **自動清理**：定期清理舊事件

## 🚀 部署步驟

### 步驟 1：執行資料庫 Migration

```bash
# 進入 Supabase 目錄
cd supabase

# 執行 migration 創建 outbox 表和 trigger
supabase db push

# 或者手動執行 SQL
psql $DATABASE_URL -f migrations/20250101_create_outbox_table.sql
```

**驗證**：
```sql
-- 檢查 outbox 表是否創建成功
SELECT * FROM outbox LIMIT 1;

-- 檢查 trigger 是否存在
SELECT tgname FROM pg_trigger WHERE tgname = 'orders_outbox_trigger';
```

### 步驟 2：配置環境變數

在 Supabase Dashboard 中設置以下環境變數：

```bash
# Firebase 配置
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key

# Supabase 配置（自動提供）
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

**獲取 Firebase API Key**：
1. 前往 Firebase Console
2. 專案設定 → 服務帳戶
3. 生成新的私密金鑰
4. 將金鑰內容設置為環境變數

### 步驟 3：部署 Edge Functions

```bash
# 部署 sync-to-firestore 函數
supabase functions deploy sync-to-firestore

# 部署 cleanup-outbox 函數
supabase functions deploy cleanup-outbox
```

**驗證**：
```bash
# 測試 sync-to-firestore 函數
curl -X POST https://your-project.supabase.co/functions/v1/sync-to-firestore \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"

# 應該返回：{"message": "沒有待處理的事件", "processed": 0}
```

### 步驟 4：設置 Cron Job

在 Supabase Dashboard 中設置定時任務：

1. 前往 Database → Cron Jobs
2. 創建新的 Cron Job：
   - **名稱**：sync-orders-to-firestore
   - **排程**：`*/30 * * * * *`（每 30 秒）
   - **命令**：調用 sync-to-firestore Edge Function

3. 創建清理任務：
   - **名稱**：cleanup-old-outbox-events
   - **排程**：`0 2 * * *`（每天 02:00）
   - **命令**：調用 cleanup-outbox Edge Function

**或使用 pg_cron**：
```sql
-- 每 30 秒執行同步
SELECT cron.schedule(
  'sync-orders-to-firestore',
  '*/30 * * * * *',
  $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/sync-to-firestore',
    headers := '{"Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}'::jsonb
  );
  $$
);

-- 每天凌晨 2 點清理舊事件
SELECT cron.schedule(
  'cleanup-old-outbox-events',
  '0 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/cleanup-outbox',
    headers := '{"Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}'::jsonb
  );
  $$
);
```

### 步驟 5：配置 Firestore 安全規則

更新 Firestore 安全規則，確保 `orders_rt` 集合只能讀取：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // orders_rt 集合：只讀（由 Supabase 寫入）
    match /orders_rt/{orderId} {
      // 允許用戶讀取自己的訂單
      allow read: if request.auth != null 
                  && resource.data.customerId == request.auth.uid;
      
      // 禁止客戶端寫入
      allow write: if false;
    }
    
    // 其他集合的規則...
  }
}
```

部署規則：
```bash
firebase deploy --only firestore:rules
```

## 🧪 測試驗證

### 測試 1：創建訂單並驗證鏡像

```bash
# 1. 創建訂單（通過 App 或 API）
curl -X POST http://localhost:3001/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "customerUid": "test-user-123",
    "pickupAddress": "台北車站",
    "pickupLatitude": 25.0478,
    "pickupLongitude": 121.5170,
    "dropoffAddress": "台北101",
    "dropoffLatitude": 25.0339,
    "dropoffLongitude": 121.5645,
    "bookingTime": "2025-01-02T10:00:00Z",
    "passengerCount": 2,
    "estimatedFare": 500
  }'

# 2. 檢查 outbox 表
SELECT * FROM outbox WHERE aggregate_type = 'order' ORDER BY created_at DESC LIMIT 1;

# 3. 手動觸發同步（或等待 30 秒）
curl -X POST https://your-project.supabase.co/functions/v1/sync-to-firestore \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"

# 4. 檢查 Firestore（使用 Firebase Console 或 App）
# 應該在 orders_rt 集合中看到新訂單
```

### 測試 2：更新訂單狀態

```bash
# 1. 支付訂金
curl -X POST http://localhost:3001/api/bookings/{orderId}/pay-deposit \
  -H "Content-Type: application/json" \
  -d '{
    "paymentMethod": "credit_card",
    "customerUid": "test-user-123"
  }'

# 2. 檢查 outbox 表（應該有新的 updated 事件）
SELECT * FROM outbox WHERE aggregate_id = '{orderId}' ORDER BY created_at DESC;

# 3. 等待同步完成（30 秒內）

# 4. 檢查 Firestore（訂單狀態應該已更新）
```

### 測試 3：驗證重試機制

```bash
# 1. 暫時關閉 Firebase 連接（模擬失敗）

# 2. 創建訂單

# 3. 檢查 outbox 表（retry_count 應該增加）
SELECT id, retry_count, error_message FROM outbox WHERE processed_at IS NULL;

# 4. 恢復 Firebase 連接

# 5. 等待下次同步（事件應該成功處理）
```

## 📊 監控和維護

### 監控指標

**1. 未處理事件數量**：
```sql
SELECT COUNT(*) as pending_events
FROM outbox
WHERE processed_at IS NULL;
```

**2. 失敗事件數量**：
```sql
SELECT COUNT(*) as failed_events
FROM outbox
WHERE processed_at IS NULL
  AND retry_count >= 3;
```

**3. 平均處理時間**：
```sql
SELECT AVG(EXTRACT(EPOCH FROM (processed_at - created_at))) as avg_processing_seconds
FROM outbox
WHERE processed_at IS NOT NULL
  AND created_at > NOW() - INTERVAL '1 hour';
```

**4. 事件類型分布**：
```sql
SELECT event_type, COUNT(*) as count
FROM outbox
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY event_type;
```

### 告警設置

建議設置以下告警：

1. **未處理事件積壓**：
   - 條件：未處理事件 > 100
   - 動作：發送通知給開發團隊

2. **失敗事件過多**：
   - 條件：失敗事件（retry_count >= 3）> 10
   - 動作：發送緊急通知

3. **處理延遲過高**：
   - 條件：平均處理時間 > 60 秒
   - 動作：檢查 Edge Function 性能

### 手動處理失敗事件

```sql
-- 查看失敗事件
SELECT id, aggregate_id, event_type, error_message, retry_count
FROM outbox
WHERE processed_at IS NULL
  AND retry_count >= 3
ORDER BY created_at DESC;

-- 重置失敗事件（允許重試）
UPDATE outbox
SET retry_count = 0, error_message = NULL
WHERE id = 'event-id-here';

-- 手動標記為已處理（放棄處理）
UPDATE outbox
SET processed_at = NOW()
WHERE id = 'event-id-here';
```

## 🔧 故障排除

### 問題 1：事件沒有被處理

**診斷**：
```sql
-- 檢查是否有未處理事件
SELECT * FROM outbox WHERE processed_at IS NULL LIMIT 10;

-- 檢查 Cron Job 是否運行
SELECT * FROM cron.job WHERE jobname = 'sync-orders-to-firestore';
```

**解決方法**：
1. 檢查 Cron Job 是否正確設置
2. 手動觸發 Edge Function
3. 檢查 Edge Function 日誌

### 問題 2：Firestore 更新失敗

**診斷**：
```sql
-- 查看錯誤訊息
SELECT id, error_message, retry_count
FROM outbox
WHERE error_message IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
```

**解決方法**：
1. 檢查 Firebase API Key 是否正確
2. 檢查 Firestore 安全規則
3. 檢查網路連接

### 問題 3：資料不一致

**診斷**：
```sql
-- 比較 Supabase 和 Firestore 的訂單數量
SELECT COUNT(*) FROM orders WHERE created_at > NOW() - INTERVAL '1 day';
-- 然後在 Firestore Console 中檢查 orders_rt 集合
```

**解決方法**：
1. 檢查是否有失敗事件
2. 手動重新同步特定訂單
3. 如果需要，可以批次重建鏡像

## 📚 相關文檔

- **架構設計文檔**: `docs/20250101_1900_13_訂單資料架構重構_單向鏡像模式.md`
- **資料庫 Schema**: `supabase/migrations/20250101_create_outbox_table.sql`
- **Edge Function**: `supabase/functions/sync-to-firestore/index.ts`
- **前端查詢邏輯**: `mobile/lib/core/services/booking_service.dart`

## ✅ 檢查清單

部署完成後，確認以下項目：

- [ ] outbox 表已創建
- [ ] orders_outbox_trigger 已創建
- [ ] Edge Functions 已部署
- [ ] 環境變數已設置
- [ ] Cron Jobs 已設置
- [ ] Firestore 安全規則已更新
- [ ] 測試場景 1-3 全部通過
- [ ] 監控指標正常
- [ ] 告警已設置

---

**版本**: 1.0.0  
**最後更新**: 2025-01-01  
**維護者**: 開發團隊
