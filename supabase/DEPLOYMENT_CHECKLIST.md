# 部署檢查清單

使用此清單來追蹤部署進度，確保所有步驟都已完成。

---

## 📋 部署前準備

- [ ] **Supabase CLI 已安裝**
  - 驗證：`supabase --version`
  - 安裝：`scoop install supabase` 或 `npm install -g supabase`

- [ ] **Firebase CLI 已安裝**（可選）
  - 驗證：`firebase --version`
  - 安裝：`npm install -g firebase-tools`

- [ ] **已登入 Supabase**
  - 執行：`supabase login`
  - 驗證：`supabase projects list`

- [ ] **已連接到專案**
  - 執行：`supabase link --project-ref vlyhwegpvpnjyocqmfqc`

---

## 🔧 步驟 1：執行資料庫 Migration

### 自動執行

- [ ] **執行 Migration**
  ```bash
  cd d:\repo/supabase
  supabase db push
  ```

### 驗證

- [ ] **檢查 outbox 表已創建**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/editor
  - 在左側表列表中找到 `outbox` 表

- [ ] **檢查 Trigger 已創建**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/database/triggers
  - 找到 `orders_outbox_trigger`

- [ ] **檢查函數已創建**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/database/functions
  - 找到 `orders_to_outbox()`
  - 找到 `cleanup_old_outbox_events()`

---

## ⚙️ 步驟 2：配置環境變數

### 獲取 Firebase 憑證

- [ ] **獲取 Firebase Project ID**
  - 前往：https://console.firebase.google.com
  - 專案設定 → 一般 → 專案 ID
  - 複製並暫存：`_________________`

- [ ] **獲取 Firebase API Key**
  - 方法 A：專案設定 → 一般 → 您的應用程式 → Web API Key
  - 方法 B：專案設定 → 服務帳戶 → 產生新的私密金鑰
  - 複製並暫存：`_________________`

### 設置環境變數

- [ ] **前往 Supabase Edge Functions 設定**
  - URL: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/settings/functions

- [ ] **添加 FIREBASE_PROJECT_ID**
  - 點擊 "Add new secret"
  - Name: `FIREBASE_PROJECT_ID`
  - Value: `<您的 Firebase Project ID>`
  - 點擊 "Save"

- [ ] **添加 FIREBASE_API_KEY**
  - 點擊 "Add new secret"
  - Name: `FIREBASE_API_KEY`
  - Value: `<您的 Firebase API Key>`
  - 點擊 "Save"

### 驗證

- [ ] **確認環境變數已設置**
  - 在 Secrets 區塊中看到：
    - ✅ `FIREBASE_PROJECT_ID`
    - ✅ `FIREBASE_API_KEY`

---

## 🚀 步驟 3：部署 Edge Functions

### 部署函數

- [ ] **部署 sync-to-firestore**
  ```bash
  cd d:\repo
  supabase functions deploy sync-to-firestore
  ```
  - 預期輸出：`✓ Function deployed successfully`

- [ ] **部署 cleanup-outbox**
  ```bash
  supabase functions deploy cleanup-outbox
  ```
  - 預期輸出：`✓ Function deployed successfully`

### 驗證

- [ ] **檢查函數已部署**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions
  - 看到：
    - ✅ `sync-to-firestore`
    - ✅ `cleanup-outbox`

### 測試函數

- [ ] **測試 sync-to-firestore**
  ```bash
  curl -X POST https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore \
    -H "Authorization: Bearer <YOUR_ANON_KEY>"
  ```
  - 預期回應：`{"message": "沒有待處理的事件", "processed": 0}`

---

## ⏰ 步驟 4：設置 Cron Job

### 啟用 pg_cron 擴展

- [ ] **啟用擴展**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/database/extensions
  - 搜尋 `pg_cron`
  - 點擊 "Enable"

### 創建 Cron Job

- [ ] **打開 SQL Editor**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql
  - 點擊 "New query"

- [ ] **執行 setup_cron_jobs.sql**
  - 複製 `supabase/setup_cron_jobs.sql` 的內容
  - 貼到 SQL Editor
  - 點擊 "Run"

### 驗證

- [ ] **確認 Cron Jobs 已創建**
  - 執行 SQL：`SELECT * FROM cron.job;`
  - 看到兩個任務：
    - ✅ `sync-orders-to-firestore` (*/30 * * * * *)
    - ✅ `cleanup-old-outbox-events` (0 2 * * *)

- [ ] **檢查 Cron Job 狀態**
  - 兩個任務的 `active` 欄位都是 `true`

---

## 🔒 步驟 5：更新 Firestore 安全規則

### 檢查規則已更新

- [ ] **檢查本地規則檔案**
  - 打開 `firebase/firestore.rules`
  - 確認包含 `orders_rt` 規則

### 部署規則

- [ ] **部署到 Firebase**
  ```bash
  cd d:\repo/firebase
  firebase deploy --only firestore:rules
  ```
  - 預期輸出：`✓ Deploy complete!`

### 驗證

- [ ] **檢查規則已部署**
  - 前往：https://console.firebase.google.com
  - Firestore Database → 規則
  - 確認看到 `orders_rt` 規則

---

## 🧪 完整測試

### 測試 1：創建訂單並驗證鏡像

- [ ] **重新建置應用**
  ```bash
  cd d:\repo/mobile
  flutter clean
  flutter pub get
  flutter run --flavor customer --target lib/apps/customer/main_customer.dart
  ```

- [ ] **在應用中創建訂單**
  - 選擇車型套餐
  - 填寫訂單資訊
  - 完成支付

- [ ] **檢查 Supabase orders 表**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/editor
  - 選擇 `orders` 表
  - 確認看到新訂單

- [ ] **檢查 Supabase outbox 表**
  - 選擇 `outbox` 表
  - 確認看到新事件（`event_type = 'created'`）
  - `processed_at` 應該是 `NULL`

- [ ] **等待 30 秒**（Cron Job 執行）

- [ ] **檢查 outbox 事件已處理**
  - 重新整理 `outbox` 表
  - `processed_at` 應該有時間戳記

- [ ] **檢查 Firestore orders_rt 集合**
  - 前往：https://console.firebase.google.com
  - Firestore Database
  - 找到 `orders_rt` 集合
  - 確認看到新訂單文檔

- [ ] **檢查應用顯示**
  - 在應用中查看「預約成功」頁面
  - 確認顯示完整訂單資訊
  - 在「我的訂單」中查看訂單
  - 確認訂單正常顯示

### 測試 2：更新訂單並驗證同步

- [ ] **在 Supabase 中更新訂單**
  - 在 `orders` 表中修改訂單狀態
  - 例如：將 `status` 改為 `matched`

- [ ] **檢查 outbox 表**
  - 確認看到新的 `updated` 事件

- [ ] **等待 30 秒**

- [ ] **檢查 Firestore**
  - 確認 `orders_rt` 中的訂單已更新

- [ ] **檢查應用**
  - 確認應用中的訂單狀態已更新

### 測試 3：監控 Cron Job 執行

- [ ] **查看 Cron Job 執行歷史**
  ```sql
  SELECT * FROM cron.job_run_details 
  WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore')
  ORDER BY start_time DESC
  LIMIT 10;
  ```

- [ ] **確認定期執行**
  - 應該看到每 30 秒執行一次的記錄
  - `status` 應該是 `succeeded`

---

## 📊 監控指標

### 每日檢查

- [ ] **檢查 outbox 表大小**
  ```sql
  SELECT COUNT(*) FROM outbox;
  ```
  - 應該保持在合理範圍（< 10000）

- [ ] **檢查未處理事件數量**
  ```sql
  SELECT COUNT(*) FROM outbox WHERE processed_at IS NULL;
  ```
  - 應該接近 0

- [ ] **檢查失敗事件**
  ```sql
  SELECT * FROM outbox WHERE retry_count >= 3;
  ```
  - 應該沒有或很少

### 每週檢查

- [ ] **檢查 Cron Job 執行統計**
  ```sql
  SELECT 
    jobname,
    COUNT(*) as total_runs,
    SUM(CASE WHEN status = 'succeeded' THEN 1 ELSE 0 END) as successful_runs,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_runs
  FROM cron.job_run_details
  WHERE start_time > NOW() - INTERVAL '7 days'
  GROUP BY jobname;
  ```

- [ ] **檢查 Edge Function 日誌**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions
  - 查看 `sync-to-firestore` 和 `cleanup-outbox` 的日誌

---

## ✅ 部署完成確認

- [ ] **所有步驟都已完成**
- [ ] **所有驗證都已通過**
- [ ] **測試流程都已成功**
- [ ] **監控指標正常**

---

## 📝 部署資訊記錄

**部署日期**：`____________________`

**部署人員**：`____________________`

**Firebase Project ID**：`____________________`

**Supabase Project Ref**：`vlyhwegpvpnjyocqmfqc`

**備註**：
```
_____________________________________________
_____________________________________________
_____________________________________________
```

---

## 🎉 恭喜！

如果所有項目都已勾選，表示部署已成功完成！

現在您的系統已經使用單向鏡像模式：
- ✅ Supabase 是唯一的資料寫入來源
- ✅ Firestore 作為即時資料的鏡像
- ✅ 資料自動同步（每 30 秒）
- ✅ 舊事件自動清理（每天凌晨 2 點）

祝使用愉快！🚀

