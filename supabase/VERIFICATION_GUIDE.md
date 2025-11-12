# 部署驗證指南

本指南將幫助您驗證 Supabase Outbox Pattern 是否正確部署和運作。

---

## 🎯 驗證目標

確認以下項目都正常運作：

1. ✅ 資料庫結構（outbox 表、trigger）
2. ✅ Edge Functions（sync-to-firestore、cleanup-outbox）
3. ✅ Cron Jobs（定時任務）
4. ✅ 環境變數（Firebase 憑證）
5. ✅ 端到端同步流程

---

## 📋 快速驗證（5 分鐘）

### 步驟 1：執行驗證 SQL（2 分鐘）

1. **前往 Supabase SQL Editor**：
   - 🔗 https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/sql/new

2. **複製並執行 `verify-deployment.sql` 的內容**

3. **查看執行結果**：

   **驗證 1：outbox 表**
   - 應該顯示：`✅ 存在`

   **驗證 2：outbox 表結構**
   - 應該顯示所有欄位：id, aggregate_type, aggregate_id, event_type, payload, created_at, processed_at, retry_count, error_message

   **驗證 3：Trigger**
   - 應該顯示：`✅ 存在`

   **驗證 4：Cron Jobs**
   - 應該顯示兩個任務：
     - `sync-orders-to-firestore` - `✅ 已啟用`
     - `cleanup-old-outbox-events` - `✅ 已啟用`

   **驗證 5-7：事件統計和歷史**
   - 可能都是空的（如果還沒有創建訂單）

   **驗證 8：手動觸發同步**
   - 應該返回一個 UUID

### 步驟 2：查看 Edge Function 日誌（1 分鐘）

1. **前往 Edge Functions 頁面**：
   - 🔗 https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/functions

2. **點擊 `sync-to-firestore` 函數**

3. **點擊 "Logs" 分頁**

4. **查看最新的日誌**：

   **✅ 如果配置正確**：
   ```
   [2025-10-02 17:25:00] [INFO] 找到 0 個待處理事件
   [2025-10-02 17:25:00] [INFO] 處理完成: 成功 0, 失敗 0
   ```

   **❌ 如果環境變數錯誤**：
   ```
   [2025-10-02 17:25:00] [ERROR] Firestore 更新失敗: 401 Unauthorized
   ```
   或
   ```
   [2025-10-02 17:25:00] [ERROR] Firestore 更新失敗: 403 Forbidden
   ```

   **❌ 如果環境變數未設置**：
   ```
   [2025-10-02 17:25:00] [ERROR] FIREBASE_PROJECT_ID is not set
   ```

### 步驟 3：檢查環境變數（1 分鐘）

1. **前往 Edge Functions 設定**：
   - 🔗 https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/settings/functions

2. **在 Secrets 區塊中確認**：
   - ✅ `FIREBASE_PROJECT_ID` 存在
   - ✅ `FIREBASE_API_KEY` 存在

3. **確認格式**：
   - `FIREBASE_API_KEY` 應該是 Web API Key（`AIzaSyC...` 格式）
   - 不是 Service Account 的 `private_key`

---

## 🧪 完整驗證（10 分鐘）

### 測試 1：創建測試訂單

這是最完整的端到端測試。

#### 1. 準備測試環境

```bash
cd d:\repo/mobile
flutter clean
flutter pub get
```

#### 2. 運行應用

```bash
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

#### 3. 在應用中創建訂單

- 選擇車型套餐
- 填寫訂單資訊
- 完成支付

#### 4. 檢查 Supabase orders 表

1. 前往：https://supabase.com/dashboard/project/vlyhwegpvpnjyocqmfqc/editor
2. 選擇 `orders` 表
3. 確認看到新訂單
4. 記下訂單 ID（例如：`order_123`）

#### 5. 檢查 Supabase outbox 表

1. 選擇 `outbox` 表
2. 確認看到新事件：
   - `aggregate_type` = `order`
   - `aggregate_id` = 您的訂單 ID
   - `event_type` = `created`
   - `processed_at` = `NULL`（尚未處理）

#### 6. 等待 30 秒

Cron Job 會在每 30 秒執行一次同步。

#### 7. 重新檢查 outbox 表

1. 重新整理頁面
2. 找到剛才的事件

**✅ 如果同步成功**：
- `processed_at` 應該有時間戳記（例如：`2025-10-02 17:26:00`）
- `error_message` 應該是 `NULL`

**❌ 如果同步失敗**：
- `processed_at` 仍然是 `NULL`
- `error_message` 會有錯誤訊息
- `retry_count` 可能增加

#### 8. 檢查 Firestore

1. 前往：https://console.firebase.google.com
2. 選擇您的專案
3. 點擊左側選單的 "Firestore Database"
4. 找到 `orders_rt` 集合

**✅ 如果同步成功**：
- 應該看到新訂單文檔
- 文檔 ID 應該與訂單 ID 相同
- 文檔內容應該與 Supabase orders 表中的資料一致

**❌ 如果同步失敗**：
- 集合可能不存在
- 或沒有新文檔

#### 9. 檢查應用顯示

1. 在「預約成功」頁面確認顯示訂單資訊
2. 在「我的訂單」中確認看到該訂單
3. 確認訂單資料完整且正確

---

## 📊 驗證檢查清單

### 快速驗證（必須）

- [ ] **資料庫結構**
  - [ ] outbox 表存在
  - [ ] orders_outbox_trigger 存在
  
- [ ] **Cron Jobs**
  - [ ] sync-orders-to-firestore 已啟用
  - [ ] cleanup-old-outbox-events 已啟用
  
- [ ] **Edge Functions**
  - [ ] sync-to-firestore 已部署且 ACTIVE
  - [ ] cleanup-outbox 已部署且 ACTIVE
  
- [ ] **環境變數**
  - [ ] FIREBASE_PROJECT_ID 已設置
  - [ ] FIREBASE_API_KEY 已設置（Web API Key 格式）
  
- [ ] **函數測試**
  - [ ] 手動觸發同步成功（返回 UUID）
  - [ ] 函數日誌無錯誤

### 完整驗證（推薦）

- [ ] **端到端測試**
  - [ ] 創建測試訂單成功
  - [ ] orders 表有新訂單
  - [ ] outbox 表有新事件
  - [ ] 等待 30 秒後，outbox 事件被處理
  - [ ] Firestore orders_rt 集合有新文檔
  - [ ] 應用中可以看到訂單

---

## ❌ 常見問題和解決方法

### 問題 1：函數日誌顯示 401 Unauthorized

**原因**：Firebase API Key 無效或格式錯誤

**診斷**：
1. 檢查 `FIREBASE_API_KEY` 的格式
2. 應該是 `AIzaSyC...` 開頭
3. 不應該是 Service Account 的 `private_key`

**解決方法**：
1. 前往 Firebase Console 獲取正確的 Web API Key
2. 更新 Supabase 環境變數
3. 重新測試

### 問題 2：函數日誌顯示 403 Forbidden

**原因**：Firebase API Key 沒有權限

**診斷**：
1. 檢查 Firebase API Key 是否正確
2. 檢查 Firebase Project ID 是否正確

**解決方法**：
1. 確認 `FIREBASE_PROJECT_ID` 與 Firebase Console 中的專案 ID 一致
2. 確認 `FIREBASE_API_KEY` 是該專案的 API Key
3. 重新測試

### 問題 3：outbox 事件一直沒有被處理

**原因**：Cron Job 沒有執行或執行失敗

**診斷**：
```sql
-- 查看 Cron Job 執行歷史
SELECT * FROM cron.job_run_details 
WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore')
ORDER BY start_time DESC
LIMIT 10;
```

**解決方法**：
1. 如果沒有執行記錄，檢查 Cron Job 是否正確設置
2. 如果有執行記錄但狀態是 `failed`，查看錯誤訊息
3. 手動觸發同步測試

### 問題 4：Firestore 沒有資料

**原因**：同步失敗或 Firestore 規則阻止寫入

**診斷**：
1. 查看 Edge Function 日誌
2. 查看 outbox 表的 `error_message` 欄位

**解決方法**：
1. 確認環境變數正確
2. 確認 Firestore 規則允許服務端寫入
3. 手動觸發同步並查看日誌

### 問題 5：應用中看不到訂單

**原因**：前端代碼問題或 Firestore 規則問題

**診斷**：
1. 檢查 Firestore orders_rt 集合是否有資料
2. 檢查 Firestore 規則是否允許讀取
3. 檢查應用日誌

**解決方法**：
1. 確認 Firestore 規則正確（參考 `firebase/firestore.rules`）
2. 確認前端代碼從 `orders_rt` 集合讀取
3. 重新部署 Firestore 規則

---

## 🔍 進階診斷

### 查看詳細的 outbox 事件

```sql
SELECT 
  id,
  aggregate_type,
  aggregate_id,
  event_type,
  payload,
  created_at,
  processed_at,
  retry_count,
  error_message
FROM outbox
WHERE processed_at IS NULL
ORDER BY created_at DESC;
```

### 查看失敗的事件

```sql
SELECT 
  id,
  aggregate_id,
  event_type,
  retry_count,
  error_message,
  created_at
FROM outbox
WHERE error_message IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
```

### 手動重置失敗的事件

```sql
-- 重置特定事件（將 'xxx' 替換為實際的事件 ID）
UPDATE outbox
SET 
  processed_at = NULL,
  retry_count = 0,
  error_message = NULL
WHERE id = 'xxx';
```

### 查看 Cron Job 執行統計

```sql
SELECT 
  j.jobname,
  COUNT(*) as total_runs,
  SUM(CASE WHEN d.status = 'succeeded' THEN 1 ELSE 0 END) as successful_runs,
  SUM(CASE WHEN d.status = 'failed' THEN 1 ELSE 0 END) as failed_runs,
  AVG(EXTRACT(EPOCH FROM (d.end_time - d.start_time))) as avg_duration_seconds
FROM cron.job_run_details d
JOIN cron.job j ON d.jobid = j.jobid
WHERE j.jobname IN ('sync-orders-to-firestore', 'cleanup-old-outbox-events')
  AND d.start_time > NOW() - INTERVAL '24 hours'
GROUP BY j.jobname;
```

---

## 🎯 驗證成功的標準

如果以下所有項目都通過，表示部署成功：

### 基本驗證

- ✅ outbox 表存在且結構正確
- ✅ Trigger 存在且正常工作
- ✅ Cron Jobs 存在且已啟用
- ✅ Edge Functions 已部署且 ACTIVE
- ✅ 環境變數已正確設置
- ✅ 手動觸發同步成功
- ✅ 函數日誌無錯誤

### 端到端驗證

- ✅ 創建訂單後，outbox 表有新事件
- ✅ 30 秒後，outbox 事件被處理（`processed_at` 有值）
- ✅ Firestore orders_rt 集合有對應的文檔
- ✅ 應用中可以正常顯示訂單

---

## 📞 需要協助？

如果驗證過程中遇到問題：

1. **記錄錯誤訊息**：
   - Edge Function 日誌中的錯誤
   - outbox 表中的 `error_message`
   - Cron Job 執行歷史中的錯誤

2. **提供以下資訊**：
   - 執行的驗證步驟
   - 預期結果 vs 實際結果
   - 錯誤訊息的完整內容
   - 相關的截圖

3. **查看相關文檔**：
   - [部署指南](./DEPLOYMENT_GUIDE.md)
   - [手動操作指南](./MANUAL_STEPS_GUIDE.md)
   - [快速開始](./QUICK_START.md)

---

## 🎉 驗證完成後

如果所有驗證都通過，恭喜您！系統已經正常運作。

接下來您可以：

1. **監控系統運作**：
   - 定期檢查 outbox 表
   - 查看 Cron Job 執行歷史
   - 監控 Edge Function 日誌

2. **優化配置**：
   - 根據實際使用情況調整同步頻率
   - 調整清理任務的保留天數

3. **開始使用**：
   - 在生產環境中使用
   - 享受單向鏡像帶來的好處！

祝使用愉快！🚀

