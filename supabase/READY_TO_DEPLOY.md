# 🚀 準備部署 Edge Functions

您已經完成了步驟 2（環境變數）和步驟 4（Cron Job）的設置。

現在只需要部署 Edge Functions（步驟 3），就可以完成整個部署流程！

---

## ✅ 已完成的步驟

- ✅ **步驟 1**：資料庫 Migration（outbox 表和 trigger）
- ✅ **步驟 2**：環境變數（FIREBASE_PROJECT_ID 和 FIREBASE_API_KEY）
- ⏳ **步驟 3**：部署 Edge Functions（**即將完成**）
- ✅ **步驟 4**：Cron Job（每 30 秒同步，每天凌晨 2 點清理）
- ✅ **步驟 5**：Firestore 規則（orders_rt 只讀）

---

## 🎯 現在需要做的：部署 Edge Functions

### 方法 A：使用自動化腳本（推薦，最簡單）⭐

**只需要 3 步驟，約 3 分鐘**：

#### 1. 打開 PowerShell

在 Windows 搜尋欄中輸入 "PowerShell"，右鍵點擊「以系統管理員身分執行」

#### 2. 執行部署腳本

```powershell
cd d:\repo\supabase
.\deploy-functions.ps1
```

#### 3. 按照提示操作

- 如果尚未登入 Supabase，腳本會打開瀏覽器
- 在瀏覽器中登入您的 Supabase 帳號
- 登入後返回 PowerShell 視窗
- 腳本會自動完成其餘步驟

**就這麼簡單！** 🎉

---

### 方法 B：手動執行命令

如果自動化腳本無法使用，可以手動執行：

```bash
# 1. 登入 Supabase
cd d:\repo
npx supabase login

# 2. 連接到專案
npx supabase link --project-ref vlyhwegpvpnjyocqmfqc

# 3. 部署 sync-to-firestore
npx supabase functions deploy sync-to-firestore

# 4. 部署 cleanup-outbox
npx supabase functions deploy cleanup-outbox
```

**詳細說明**：請參考 [`DEPLOY_FUNCTIONS_GUIDE.md`](./DEPLOY_FUNCTIONS_GUIDE.md)

---

## ✅ 驗證部署是否成功

### 快速驗證（1 分鐘）

1. **前往 Supabase Dashboard**：
   - URL: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions

2. **確認看到兩個函數**：
   - ✅ `sync-to-firestore`
   - ✅ `cleanup-outbox`

### 完整測試（5 分鐘）

1. **手動觸發同步**：
   - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql
   - 執行以下 SQL：
     ```sql
     SELECT
       net.http_post(
         url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
         headers := jsonb_build_object(
           'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
         )
       ) as request_id;
     ```

2. **查看函數日誌**：
   - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions
   - 點擊 `sync-to-firestore` → Logs
   - 應該看到：`找到 0 個待處理事件` 或 `處理完成: 成功 X, 失敗 0`

3. **創建測試訂單**：
   - 在應用中創建訂單
   - 檢查 outbox 表（應該有新事件）
   - 等待 30 秒
   - 檢查 outbox 表（`processed_at` 應該有時間戳記）
   - 檢查 Firestore `orders_rt` 集合（應該有新文檔）

---

## 📋 部署後檢查清單

完成部署後，請確認：

- [ ] **Edge Functions 已部署**
  - [ ] `sync-to-firestore` 在 Dashboard 中可見
  - [ ] `cleanup-outbox` 在 Dashboard 中可見

- [ ] **環境變數已設置**
  - [ ] `FIREBASE_PROJECT_ID` 已設置
  - [ ] `FIREBASE_API_KEY` 已設置（Web API Key 格式）

- [ ] **Cron Job 已設置**
  - [ ] `sync-orders-to-firestore`（每 30 秒）
  - [ ] `cleanup-old-outbox-events`（每天凌晨 2 點）

- [ ] **函數測試成功**
  - [ ] 手動觸發同步成功
  - [ ] 函數日誌無錯誤
  - [ ] 創建訂單後自動同步成功
  - [ ] Firestore 有鏡像資料

---

## 🎉 完成後的效果

部署完成後，您的系統將實現：

### 資料流

```
App → Supabase API → orders 表 (寫入)
                        ↓
                   Trigger 監聽
                        ↓
                   outbox 表 (事件佇列)
                        ↓
              Edge Function 消費 (每 30 秒)
                        ↓
            Firestore orders_rt 集合 (鏡像)
                        ↓
                   App 讀取 (即時)
```

### 關鍵特性

- ✅ **Single Source of Truth**：Supabase 是唯一的資料寫入來源
- ✅ **單向資料流**：資料只從 Supabase 流向 Firestore
- ✅ **自動同步**：每 30 秒自動同步新訂單
- ✅ **可靠性**：失敗事件自動重試（最多 3 次）
- ✅ **自動清理**：舊事件自動清理（保留 7 天）

### 用戶體驗

- ✅ 創建訂單後，30 秒內自動同步到 Firestore
- ✅ 「預約成功」頁面正常顯示訂單資訊
- ✅ 「我的訂單」頁面正常顯示所有訂單
- ✅ 訂單狀態即時更新

---

## 📚 相關文檔

- **[部署指南](./DEPLOY_FUNCTIONS_GUIDE.md)** - 詳細的部署步驟和故障排除
- **[快速開始](./QUICK_START.md)** - 10 分鐘快速部署
- **[手動操作指南](./MANUAL_STEPS_GUIDE.md)** - 手動步驟詳解
- **[部署檢查清單](./DEPLOYMENT_CHECKLIST.md)** - 完整的檢查清單

---

## ❓ 常見問題

### Q1：PowerShell 腳本無法執行？

**錯誤**：「無法載入檔案，因為這個系統上已停用指令碼執行」

**解決方法**：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q2：登入時瀏覽器沒有打開？

**解決方法**：
1. 複製終端機中顯示的 URL
2. 在瀏覽器中手動打開
3. 完成登入後複製 Access Token
4. 返回終端機並貼上

### Q3：部署後函數無法執行？

**診斷步驟**：
1. 檢查環境變數是否正確設置
2. 查看函數日誌中的錯誤訊息
3. 確認 Firebase API Key 格式正確（`AIzaSyC...`）

---

## 🚀 立即開始

準備好了嗎？

**使用自動化腳本**（推薦）：
```powershell
cd d:\repo\supabase
.\deploy-functions.ps1
```

**或手動執行**：
```bash
cd d:\repo
npx supabase login
npx supabase link --project-ref vlyhwegpvpnjyocqmfqc
npx supabase functions deploy sync-to-firestore
npx supabase functions deploy cleanup-outbox
```

---

## 📞 需要協助？

如果遇到任何問題：

1. 查看 [`DEPLOY_FUNCTIONS_GUIDE.md`](./DEPLOY_FUNCTIONS_GUIDE.md) 的「常見問題」區塊
2. 查看函數日誌中的錯誤訊息
3. 提供錯誤訊息和截圖以獲得協助

祝部署順利！🚀

---

## 🎊 部署完成後

完成部署後，請告訴我：

1. ✅ 函數是否成功部署？
2. ✅ 函數日誌是否正常？
3. ✅ 測試訂單是否成功同步？

我會幫您驗證整個系統是否正常運作！

