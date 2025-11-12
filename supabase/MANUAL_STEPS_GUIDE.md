# 手動操作詳細指南

本指南提供需要手動完成的步驟的詳細說明，包括具體的 UI 操作路徑。

---

## 📋 需要手動操作的步驟

- ⚠️ **步驟 2**：配置環境變數
- ⚠️ **步驟 4**：設置 Cron Job

---

## ⚠️ 步驟 2：配置環境變數

### 2.1 獲取 Firebase Project ID

#### 操作步驟：

1. **打開 Firebase Console**
   - 在瀏覽器中前往：https://console.firebase.google.com
   - 使用您的 Google 帳號登入

2. **選擇您的專案**
   - 在專案列表中找到您的專案
   - 點擊專案卡片進入專案

3. **進入專案設定**
   - 點擊左上角的 **齒輪圖示 ⚙️**
   - 在下拉選單中點擊 **「專案設定」** (Project settings)

4. **複製 Project ID**
   - 在「一般」(General) 分頁中
   - 找到「專案 ID」(Project ID) 欄位
   - 點擊右側的 **複製圖示** 📋
   - 將 Project ID 暫存到記事本（例如：`my-charter-app`）

#### UI 路徑：
```
Firebase Console 首頁
  → 選擇專案
  → 齒輪圖示 ⚙️
  → 專案設定
  → 一般分頁
  → 專案 ID (複製)
```

---

### 2.2 獲取 Firebase API Key

#### 方法 A：使用 Web API Key（推薦用於開發環境）

1. **在專案設定頁面**
   - 確保您在「一般」(General) 分頁

2. **找到您的應用程式**
   - 向下滾動到「您的應用程式」(Your apps) 區塊
   - 如果有 Web 應用，會看到一個 `</>` 圖示的應用

3. **查看應用配置**
   - 點擊應用名稱下方的 **「SDK 設定和配置」** (SDK setup and configuration)
   - 或點擊 **「設定」** (Config) 按鈕

4. **複製 API Key**
   - 在 Firebase 配置物件中找到 `apiKey` 欄位
   - 複製整個 API Key（例如：`AIzaSyC...`）
   - 將 API Key 暫存到記事本

#### UI 路徑：
```
Firebase Console → 專案設定 → 一般分頁
  → 您的應用程式
  → Web 應用
  → SDK 設定和配置
  → apiKey (複製)
```

#### 方法 B：使用 Service Account（推薦用於生產環境）

1. **進入服務帳戶分頁**
   - 在專案設定頁面
   - 點擊頂部的 **「服務帳戶」** (Service accounts) 分頁

2. **產生新的私密金鑰**
   - 向下滾動到「Firebase Admin SDK」區塊
   - 點擊 **「產生新的私密金鑰」** (Generate new private key) 按鈕
   - 在彈出的對話框中點擊 **「產生金鑰」** (Generate key)

3. **下載 JSON 檔案**
   - JSON 檔案會自動下載到您的電腦
   - 檔案名稱類似：`your-project-id-firebase-adminsdk-xxxxx.json`

4. **提取 API Key**
   - 打開下載的 JSON 檔案
   - 複製整個 JSON 內容，或使用其中的 `private_key` 欄位

#### UI 路徑：
```
Firebase Console → 專案設定 → 服務帳戶分頁
  → Firebase Admin SDK
  → 產生新的私密金鑰
  → 產生金鑰
  → 下載 JSON 檔案
```

---

### 2.3 在 Supabase Dashboard 中設置環境變數

#### 操作步驟：

1. **打開 Supabase Dashboard**
   - 在瀏覽器中前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc
   - 或前往：https://app.supabase.com 並選擇您的專案

2. **進入 Edge Functions 設定**
   - 點擊左側選單的 **「Settings」** (設定)
   - 在設定選單中點擊 **「Edge Functions」**

3. **找到 Secrets 區塊**
   - 向下滾動到 **「Secrets」** 區塊
   - 這裡會顯示所有已設置的環境變數

4. **添加第一個環境變數（FIREBASE_PROJECT_ID）**
   - 點擊 **「Add new secret」** 按鈕
   - 在 **「Name」** 欄位輸入：`FIREBASE_PROJECT_ID`
   - 在 **「Value」** 欄位貼上您的 Firebase Project ID
   - 點擊 **「Save」** 按鈕

5. **添加第二個環境變數（FIREBASE_API_KEY）**
   - 再次點擊 **「Add new secret」** 按鈕
   - 在 **「Name」** 欄位輸入：`FIREBASE_API_KEY`
   - 在 **「Value」** 欄位貼上您的 Firebase API Key
   - 點擊 **「Save」** 按鈕

#### UI 路徑：
```
Supabase Dashboard
  → Settings (左側選單)
  → Edge Functions
  → Secrets 區塊
  → Add new secret
  → 輸入 Name 和 Value
  → Save
```

#### 驗證：

在 Secrets 區塊中，您應該看到：
- ✅ `FIREBASE_PROJECT_ID` (值已隱藏)
- ✅ `FIREBASE_API_KEY` (值已隱藏)

---

## ⚠️ 步驟 4：設置 Cron Job

### 4.1 啟用 pg_cron 擴展

#### 操作步驟：

1. **打開 Supabase Dashboard**
   - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc

2. **進入 Extensions 頁面**
   - 點擊左側選單的 **「Database」**
   - 在子選單中點擊 **「Extensions」**

3. **搜尋 pg_cron**
   - 在搜尋框中輸入：`pg_cron`
   - 找到 **「pg_cron」** 擴展

4. **啟用擴展**
   - 點擊 pg_cron 右側的 **「Enable」** 按鈕
   - 等待啟用完成（通常需要幾秒鐘）

#### UI 路徑：
```
Supabase Dashboard
  → Database (左側選單)
  → Extensions
  → 搜尋 "pg_cron"
  → Enable
```

#### 驗證：

pg_cron 的狀態應該顯示為 **「Enabled」** (已啟用)。

---

### 4.2 創建 Cron Job（使用 SQL Editor）

#### 操作步驟：

1. **打開 SQL Editor**
   - 在 Supabase Dashboard 中
   - 點擊左側選單的 **「SQL Editor」**

2. **創建新查詢**
   - 點擊右上角的 **「New query」** 按鈕
   - 會打開一個空白的 SQL 編輯器

3. **複製 SQL 腳本**
   - 打開專案中的 `supabase/setup_cron_jobs.sql` 檔案
   - 複製整個檔案的內容

4. **貼上並執行 SQL**
   - 將複製的 SQL 貼到 SQL 編輯器中
   - 點擊右下角的 **「Run」** 按鈕
   - 等待執行完成

5. **查看執行結果**
   - 在編輯器下方的「Results」區塊
   - 應該看到兩個 Cron Jobs 的資訊：
     - `sync-orders-to-firestore`
     - `cleanup-old-outbox-events`

#### UI 路徑：
```
Supabase Dashboard
  → SQL Editor (左側選單)
  → New query
  → 貼上 setup_cron_jobs.sql 的內容
  → Run
  → 查看 Results
```

#### SQL 腳本內容：

如果您無法打開 `setup_cron_jobs.sql` 檔案，可以直接複製以下內容：

```sql
-- 啟用 pg_cron 擴展
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 刪除舊的 Cron Jobs（如果存在）
SELECT cron.unschedule('sync-orders-to-firestore') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'sync-orders-to-firestore'
);

SELECT cron.unschedule('cleanup-old-outbox-events') WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup-old-outbox-events'
);

-- 創建同步任務（每 30 秒執行一次）
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

-- 創建清理任務（每天凌晨 2 點執行）
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

-- 驗證 Cron Jobs 已創建
SELECT 
  jobid,
  jobname,
  schedule,
  active,
  command
FROM cron.job
WHERE jobname IN ('sync-orders-to-firestore', 'cleanup-old-outbox-events')
ORDER BY jobname;
```

#### 驗證：

執行以下 SQL 查詢來驗證 Cron Jobs 已創建：

```sql
SELECT * FROM cron.job;
```

您應該看到兩個任務：

| jobid | jobname                      | schedule        | active | command                    |
|-------|------------------------------|-----------------|--------|----------------------------|
| 1     | sync-orders-to-firestore     | */30 * * * * *  | true   | SELECT net.http_post(...)  |
| 2     | cleanup-old-outbox-events    | 0 2 * * *       | true   | SELECT net.http_post(...)  |

---

## 🧪 驗證部署是否成功

### 驗證步驟 2：環境變數

1. 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/settings/functions
2. 在 Secrets 區塊中確認：
   - ✅ `FIREBASE_PROJECT_ID` 存在
   - ✅ `FIREBASE_API_KEY` 存在

### 驗證步驟 4：Cron Job

1. 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql
2. 執行以下 SQL：
   ```sql
   SELECT * FROM cron.job;
   ```
3. 確認看到兩個任務

### 查看 Cron Job 執行歷史

```sql
SELECT * FROM cron.job_run_details 
WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore')
ORDER BY start_time DESC
LIMIT 10;
```

---

## ❓ 常見問題

### Q1：找不到 Secrets 區塊？

**解決方法**：
- 確保您在 Settings → Edge Functions 頁面
- 向下滾動到頁面底部
- Secrets 區塊在 Environment Variables 下方

### Q2：pg_cron 擴展無法啟用？

**解決方法**：
- 確保您的 Supabase 專案是付費方案（免費方案可能不支援）
- 聯繫 Supabase 支援團隊

### Q3：Cron Job SQL 執行失敗？

**解決方法**：
- 確保 pg_cron 擴展已啟用
- 檢查 SQL 語法是否正確
- 確保專案 URL 正確（`vlyhwegpvpnjyocqmfqc`）

---

## 📞 需要協助？

如果您在手動操作過程中遇到任何問題，請提供：
1. 您正在執行的步驟編號
2. 錯誤訊息的完整內容
3. Supabase Dashboard 的截圖

祝操作順利！🚀

