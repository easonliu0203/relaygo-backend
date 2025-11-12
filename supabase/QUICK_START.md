# 快速開始指南

本指南幫助您在 10 分鐘內完成 Supabase Outbox Pattern 的部署。

---

## ⚡ 快速部署（推薦）

### 1. 執行自動部署腳本

**Windows PowerShell**:
```powershell
cd d:\repo\supabase
.\deploy.ps1
```

**Linux/macOS**:
```bash
cd d:\repo/supabase
chmod +x deploy.sh
./deploy.sh
```

### 2. 按照提示完成手動操作

腳本會在需要手動操作時暫停，並顯示詳細指引。

---

## 📝 手動操作步驟

### 步驟 2：配置環境變數（約 3 分鐘）

#### 2.1 獲取 Firebase Project ID

1. 前往：https://console.firebase.google.com
2. 選擇您的專案
3. 點擊齒輪圖示 ⚙️ → 專案設定
4. 複製「專案 ID」

#### 2.2 獲取 Firebase API Key

1. 在專案設定頁面
2. 找到「您的應用程式」區塊
3. 複製 Web API Key（`apiKey`）

#### 2.3 設置環境變數

1. 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/settings/functions
2. 在 Secrets 區塊中添加：
   - Name: `FIREBASE_PROJECT_ID`，Value: `<您的 Project ID>`
   - Name: `FIREBASE_API_KEY`，Value: `<您的 API Key>`

---

### 步驟 4：設置 Cron Job（約 2 分鐘）

#### 4.1 啟用 pg_cron 擴展

1. 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/database/extensions
2. 搜尋 `pg_cron`
3. 點擊 "Enable"

#### 4.2 執行 SQL 腳本

1. 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql
2. 點擊 "New query"
3. 複製以下 SQL 並執行：

```sql
-- 啟用 pg_cron 擴展
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 創建同步任務（每 30 秒）
SELECT cron.schedule(
  'sync-orders-to-firestore',
  '*/30 * * * * *',
  $$
  SELECT
    net.http_post(
      url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      )
    ) as request_id;
  $$
);

-- 創建清理任務（每天凌晨 2 點）
SELECT cron.schedule(
  'cleanup-old-outbox-events',
  '0 2 * * *',
  $$
  SELECT
    net.http_post(
      url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/cleanup-outbox',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
      )
    ) as request_id;
  $$
);

-- 驗證
SELECT * FROM cron.job;
```

---

## ✅ 驗證部署

### 快速驗證清單

- [ ] **outbox 表已創建**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/editor
  - 確認看到 `outbox` 表

- [ ] **環境變數已設置**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/settings/functions
  - 確認看到 `FIREBASE_PROJECT_ID` 和 `FIREBASE_API_KEY`

- [ ] **Edge Functions 已部署**
  - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions
  - 確認看到 `sync-to-firestore` 和 `cleanup-outbox`

- [ ] **Cron Job 已設置**
  - 執行 SQL：`SELECT * FROM cron.job;`
  - 確認看到兩個任務

- [ ] **Firestore 規則已更新**
  - 前往：https://console.firebase.google.com
  - Firestore Database → 規則
  - 確認看到 `orders_rt` 規則

---

## 🧪 測試同步功能

### 1. 創建測試訂單

```bash
cd d:\repo/mobile
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

在應用中創建一個訂單。

### 2. 檢查 Supabase

前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/editor

**檢查 orders 表**：
- 確認看到新訂單

**檢查 outbox 表**：
- 確認看到新事件（`event_type = 'created'`）
- `processed_at` 應該是 `NULL`

### 3. 等待 30 秒

Cron Job 會自動執行同步。

### 4. 檢查同步結果

**檢查 outbox 表**：
- 重新整理頁面
- `processed_at` 應該有時間戳記

**檢查 Firestore**：
- 前往：https://console.firebase.google.com
- Firestore Database
- 找到 `orders_rt` 集合
- 確認看到新訂單文檔

### 5. 檢查應用

- 在「預約成功」頁面確認顯示訂單資訊
- 在「我的訂單」中確認看到該訂單

---

## ❓ 常見問題

### Q1：Supabase CLI 未安裝？

**Windows (Scoop)**:
```bash
scoop install supabase
```

**macOS (Homebrew)**:
```bash
brew install supabase/tap/supabase
```

**npm**:
```bash
npm install -g supabase
```

### Q2：找不到 Firebase API Key？

1. 前往 Firebase Console → 專案設定
2. 在「一般」分頁中找到「您的應用程式」
3. 如果沒有 Web 應用，點擊「新增應用程式」→ 選擇 Web
4. 複製 `apiKey` 欄位

### Q3：Cron Job 沒有執行？

**檢查執行歷史**:
```sql
SELECT * FROM cron.job_run_details 
WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore')
ORDER BY start_time DESC
LIMIT 10;
```

**手動觸發測試**:
```sql
SELECT
  net.http_post(
    url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    )
  ) as request_id;
```

### Q4：Firestore 沒有資料？

**診斷步驟**:

1. **檢查環境變數**：
   - 確認 `FIREBASE_PROJECT_ID` 和 `FIREBASE_API_KEY` 已設置

2. **檢查 Edge Function 日誌**：
   - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions
   - 點擊 `sync-to-firestore`
   - 查看 Logs

3. **檢查 outbox 表**：
   - 確認有未處理的事件
   - 檢查 `error_message` 欄位

4. **手動測試 Edge Function**：
   ```bash
   curl -X POST https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore \
     -H "Authorization: Bearer <YOUR_ANON_KEY>"
   ```

---

## 📚 詳細文檔

如果需要更詳細的說明，請參考：

- **完整部署指南**：`DEPLOYMENT_GUIDE.md`
- **手動操作指南**：`MANUAL_STEPS_GUIDE.md`
- **部署檢查清單**：`DEPLOYMENT_CHECKLIST.md`
- **部署狀態總結**：`DEPLOYMENT_STATUS.md`

---

## 🎯 下一步

部署完成後：

1. **監控系統**：
   - 定期檢查 outbox 表大小
   - 查看 Cron Job 執行歷史
   - 監控 Edge Function 日誌

2. **優化配置**：
   - 根據實際使用情況調整同步頻率
   - 調整清理任務的保留天數

3. **備份資料**：
   - 定期備份 Supabase 資料庫
   - 定期備份 Firestore 資料

---

## 🎉 完成！

恭喜您完成部署！現在您的系統已經使用單向鏡像模式：

- ✅ Supabase 是唯一的資料寫入來源
- ✅ Firestore 作為即時資料的鏡像
- ✅ 資料自動同步（每 30 秒）
- ✅ 舊事件自動清理（每天凌晨 2 點）

如果遇到任何問題，請查看詳細文檔或聯繫支援。

祝使用愉快！🚀

