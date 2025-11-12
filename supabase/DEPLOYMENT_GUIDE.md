# Supabase Outbox Pattern 部署指南

本指南將協助您完成 Supabase 到 Firestore 的單向鏡像部署。

## 📋 部署概覽

本部署包含 5 個主要步驟：

1. ✅ **執行資料庫 Migration** - 創建 outbox 表和 trigger
2. ⚠️ **配置環境變數** - 設置 Firebase 連接資訊（需手動）
3. ⚠️ **部署 Edge Functions** - 部署同步和清理函數（需手動）
4. ⚠️ **設置 Cron Job** - 配置定時任務（需手動）
5. ✅ **更新 Firestore 安全規則** - 已自動完成

---

## 🔧 前置準備

### 1. 安裝 Supabase CLI

**Windows (使用 Scoop)**:
```bash
scoop install supabase
```

**macOS (使用 Homebrew)**:
```bash
brew install supabase/tap/supabase
```

**使用 npm**:
```bash
npm install -g supabase
```

**驗證安裝**:
```bash
supabase --version
```

### 2. 登入 Supabase

```bash
supabase login
```

這會打開瀏覽器要求您登入 Supabase 帳號。

### 3. 連接到您的專案

```bash
cd d:\repo
supabase link --project-ref vlyhwegpvpnjyocqmfqc
```

**驗證連接**:
```bash
supabase projects list
```

---

## 📝 步驟 1：執行資料庫 Migration ✅

### 自動執行

```bash
cd d:\repo/supabase
supabase db push
```

### 驗證

1. **前往 Supabase Dashboard**:
   - URL: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc

2. **檢查 outbox 表**:
   - 點擊左側選單 `Database` → `Tables`
   - 應該看到新的 `outbox` 表
   - 表結構應包含以下欄位：
     - `id` (UUID)
     - `aggregate_type` (VARCHAR)
     - `aggregate_id` (VARCHAR)
     - `event_type` (VARCHAR)
     - `payload` (JSONB)
     - `created_at` (TIMESTAMP)
     - `processed_at` (TIMESTAMP)
     - `retry_count` (INTEGER)
     - `error_message` (TEXT)

3. **檢查 Trigger**:
   - 點擊左側選單 `Database` → `Triggers`
   - 應該看到 `orders_outbox_trigger`
   - 觸發條件：`AFTER INSERT OR UPDATE ON orders`

---

## ⚠️ 步驟 2：配置環境變數（需手動操作）

### 2.1 獲取 Firebase Project ID

1. **前往 Firebase Console**:
   - URL: https://console.firebase.google.com

2. **選擇您的專案**

3. **獲取 Project ID**:
   - 點擊左上角的齒輪圖示 ⚙️
   - 點擊「專案設定」
   - 在「一般」分頁中找到「專案 ID」
   - 複製這個 ID（例如：`my-charter-app`）

### 2.2 獲取 Firebase API Key

**方法 A：使用 Web API Key（簡單）**

1. 在 Firebase Console 的專案設定頁面
2. 找到「您的應用程式」區塊
3. 如果有 Web 應用，會看到 `apiKey`
4. 複製這個 Key（例如：`AIzaSyC...`）

**方法 B：使用 Service Account（推薦用於生產環境）**

1. 在 Firebase Console 的專案設定頁面
2. 點擊「服務帳戶」分頁
3. 點擊「產生新的私密金鑰」
4. 下載 JSON 檔案
5. 將整個 JSON 內容作為環境變數

### 2.3 在 Supabase Dashboard 中設置環境變數

1. **前往 Supabase Dashboard**:
   - URL: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc

2. **進入 Edge Functions 設定**:
   - 點擊左側選單 `Settings`（設定）
   - 點擊 `Edge Functions`
   - 找到 `Secrets` 區塊

3. **添加第一個環境變數**:
   - 點擊 `Add new secret`
   - Name: `FIREBASE_PROJECT_ID`
   - Value: `<您的 Firebase Project ID>`
   - 點擊 `Save`

4. **添加第二個環境變數**:
   - 點擊 `Add new secret`
   - Name: `FIREBASE_API_KEY`
   - Value: `<您的 Firebase API Key>`
   - 點擊 `Save`

### 驗證

在 Supabase Dashboard → Settings → Edge Functions → Secrets 中，應該看到：
- ✅ `FIREBASE_PROJECT_ID`
- ✅ `FIREBASE_API_KEY`

---

## ⚠️ 步驟 3：部署 Edge Functions（需手動操作）

### 3.1 部署 sync-to-firestore 函數

```bash
cd d:\repo
supabase functions deploy sync-to-firestore
```

**預期輸出**:
```
Deploying function sync-to-firestore...
✓ Function deployed successfully
Function URL: https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore
```

### 3.2 部署 cleanup-outbox 函數

```bash
supabase functions deploy cleanup-outbox
```

**預期輸出**:
```
Deploying function cleanup-outbox...
✓ Function deployed successfully
Function URL: https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/cleanup-outbox
```

### 驗證

1. **前往 Supabase Dashboard**:
   - URL: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc

2. **檢查 Edge Functions**:
   - 點擊左側選單 `Edge Functions`
   - 應該看到兩個函數：
     - ✅ `sync-to-firestore`
     - ✅ `cleanup-outbox`

### 測試函數

**獲取 Anon Key**:
1. 前往 Supabase Dashboard → Settings → API
2. 複製 `anon` `public` key

**測試 sync-to-firestore**:
```bash
curl -X POST https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore \
  -H "Authorization: Bearer <YOUR_ANON_KEY>"
```

**預期回應**:
```json
{"message": "沒有待處理的事件", "processed": 0}
```

---

## ⚠️ 步驟 4：設置 Cron Job（需手動操作）

### 4.1 啟用 pg_cron 擴展

1. **前往 Supabase Dashboard**:
   - URL: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc

2. **啟用擴展**:
   - 點擊左側選單 `Database` → `Extensions`
   - 搜尋 `pg_cron`
   - 點擊 `Enable`

### 4.2 創建 Cron Job（使用 SQL Editor）

1. **前往 SQL Editor**:
   - 點擊左側選單 `SQL Editor`
   - 點擊 `New query`

2. **複製以下 SQL**:

```sql
-- 每 30 秒執行同步任務
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

-- 每天凌晨 2 點執行清理任務
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
```

3. **執行 SQL**:
   - 點擊 `Run` 按鈕
   - 應該看到成功訊息

### 驗證

**查看已設置的 Cron Jobs**:
```sql
SELECT * FROM cron.job;
```

應該看到兩個任務：
- ✅ `sync-orders-to-firestore` (每 30 秒)
- ✅ `cleanup-old-outbox-events` (每天凌晨 2 點)

---

## ✅ 步驟 5：更新 Firestore 安全規則（已自動完成）

Firestore 規則已自動更新，添加了 `orders_rt` 集合的規則：

```javascript
// 訂單即時鏡像規則（orders_rt 集合）
match /orders_rt/{orderId} {
  // 允許用戶讀取自己的訂單
  allow read: if request.auth != null 
              && resource.data.customerId == request.auth.uid;
  
  // 禁止客戶端寫入（由 Supabase 寫入）
  allow write: if false;
}
```

### 部署規則到 Firebase

```bash
cd d:\repo/firebase
firebase deploy --only firestore:rules
```

**如果尚未安裝 Firebase CLI**:
```bash
npm install -g firebase-tools
firebase login
```

---

## 🧪 完整測試流程

### 測試 1：創建訂單並驗證鏡像

1. **重新建置應用**:
```bash
cd d:\repo/mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

2. **在應用中創建訂單**

3. **檢查 Supabase outbox 表**:
   - 前往 Supabase Dashboard → Database → Table Editor
   - 選擇 `outbox` 表
   - 應該看到新事件（`event_type = 'created'`）

4. **等待 30 秒**（Cron Job 執行）

5. **檢查 Firestore**:
   - 前往 Firebase Console → Firestore Database
   - 找到 `orders_rt` 集合
   - 應該看到新訂單文檔

---

## ❓ 常見問題

### Q1：Supabase CLI 無法連接？

```bash
supabase logout
supabase login
supabase projects list
```

### Q2：Edge Function 部署失敗？

```bash
# 檢查函數語法
deno check supabase/functions/sync-to-firestore/index.ts

# 查看詳細錯誤
supabase functions deploy sync-to-firestore --debug
```

### Q3：Cron Job 沒有執行？

```sql
-- 查看執行歷史
SELECT * FROM cron.job_run_details 
WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore')
ORDER BY start_time DESC
LIMIT 10;
```

---

## 📞 需要協助？

如果遇到任何問題，請提供：
1. 錯誤訊息的完整內容
2. 執行的命令
3. Supabase Dashboard 的截圖

祝部署順利！🚀

