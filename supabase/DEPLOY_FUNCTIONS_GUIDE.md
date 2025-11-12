# Edge Functions 部署指南

本指南說明如何部署 `sync-to-firestore` 和 `cleanup-outbox` 這兩個 Edge Functions。

---

## 🚀 方法 1：使用自動化腳本（推薦）

### Windows PowerShell（推薦）

1. **打開 PowerShell**（以系統管理員身分執行）

2. **執行部署腳本**：
   ```powershell
   cd d:\repo\supabase
   .\deploy-functions.ps1
   ```

3. **按照提示操作**：
   - 如果尚未登入，腳本會打開瀏覽器要求登入
   - 登入後返回 PowerShell 視窗
   - 腳本會自動完成其餘步驟

### Windows 命令提示字元

1. **打開命令提示字元**（以系統管理員身分執行）

2. **執行部署腳本**：
   ```cmd
   cd d:\repo\supabase
   deploy-functions.bat
   ```

3. **按照提示操作**（同上）

---

## 📝 方法 2：手動執行命令

如果自動化腳本無法使用，可以手動執行以下命令：

### 步驟 1：登入 Supabase

```bash
cd d:\repo
npx supabase login
```

- 會打開瀏覽器
- 登入您的 Supabase 帳號
- 授權後自動返回終端機

### 步驟 2：連接到專案

```bash
npx supabase link --project-ref vlyhwegpvpnjyocqmfqc
```

- 如果提示輸入資料庫密碼，請輸入您的 Supabase 資料庫密碼

### 步驟 3：部署 sync-to-firestore

```bash
npx supabase functions deploy sync-to-firestore
```

**預期輸出**：
```
Deploying function sync-to-firestore...
✓ Function deployed successfully
Function URL: https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore
```

### 步驟 4：部署 cleanup-outbox

```bash
npx supabase functions deploy cleanup-outbox
```

**預期輸出**：
```
Deploying function cleanup-outbox...
✓ Function deployed successfully
Function URL: https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/cleanup-outbox
```

---

## ✅ 驗證部署是否成功

### 方法 1：在 Supabase Dashboard 中檢查

1. **前往 Edge Functions 頁面**：
   - URL: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions

2. **確認看到兩個函數**：
   - ✅ `sync-to-firestore`
   - ✅ `cleanup-outbox`

3. **檢查函數狀態**：
   - 兩個函數都應該顯示為 "Active"（綠色）

### 方法 2：使用 CLI 檢查

```bash
npx supabase functions list
```

**預期輸出**：
```
┌─────────────────────┬─────────┬─────────────────────┐
│ NAME                │ STATUS  │ UPDATED AT          │
├─────────────────────┼─────────┼─────────────────────┤
│ sync-to-firestore   │ ACTIVE  │ 2025-01-01 20:00:00 │
│ cleanup-outbox      │ ACTIVE  │ 2025-01-01 20:00:00 │
└─────────────────────┴─────────┴─────────────────────┘
```

### 方法 3：測試函數調用

**測試 sync-to-firestore**：

1. 前往 Supabase SQL Editor：
   - URL: https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql

2. 執行以下 SQL：
   ```sql
   SELECT
     net.http_post(
       url := 'https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/sync-to-firestore',
       headers := jsonb_build_object(
         'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
       )
     ) as request_id;
   ```

3. 查看函數日誌：
   - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions
   - 點擊 `sync-to-firestore` → Logs
   - 應該看到執行記錄

---

## ❓ 常見問題

### Q1：執行腳本時出現「無法載入檔案」錯誤（PowerShell）

**錯誤訊息**：
```
無法載入檔案 deploy-functions.ps1，因為這個系統上已停用指令碼執行。
```

**解決方法**：

1. 以系統管理員身分打開 PowerShell

2. 執行以下命令：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. 輸入 `Y` 確認

4. 重新執行部署腳本

### Q2：登入時瀏覽器沒有打開

**解決方法**：

1. 手動複製終端機中顯示的 URL

2. 在瀏覽器中打開該 URL

3. 完成登入後，複製 Access Token

4. 返回終端機並貼上 Access Token

### Q3：部署時出現「Project not linked」錯誤

**解決方法**：

```bash
npx supabase link --project-ref vlyhwegpvpnjyocqmfqc
```

### Q4：部署時出現「Function not found」錯誤

**可能原因**：
- 函數目錄結構不正確
- 函數檔案不存在

**解決方法**：

1. 檢查目錄結構：
   ```
   supabase/
   └── functions/
       ├── sync-to-firestore/
       │   └── index.ts
       └── cleanup-outbox/
           └── index.ts
   ```

2. 確認檔案存在：
   ```bash
   dir d:\repo\supabase\functions\sync-to-firestore\index.ts
   dir d:\repo\supabase\functions\cleanup-outbox\index.ts
   ```

### Q5：部署成功但函數無法執行

**診斷步驟**：

1. **檢查環境變數**：
   - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/settings/functions
   - 確認 `FIREBASE_PROJECT_ID` 和 `FIREBASE_API_KEY` 已設置

2. **查看函數日誌**：
   - 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions
   - 點擊函數名稱 → Logs
   - 查看錯誤訊息

3. **手動測試函數**：
   - 使用上面的 SQL 測試方法

---

## 🔄 重新部署

如果需要更新函數代碼後重新部署：

```bash
cd d:\repo\supabase

# 重新部署 sync-to-firestore
npx supabase functions deploy sync-to-firestore

# 重新部署 cleanup-outbox
npx supabase functions deploy cleanup-outbox
```

或使用腳本：

```powershell
.\deploy-functions.ps1
```

---

## 📊 部署檢查清單

- [ ] **已安裝 Node.js 和 npm**
- [ ] **已登入 Supabase**（`npx supabase login`）
- [ ] **已連接到專案**（`npx supabase link`）
- [ ] **已部署 sync-to-firestore**
- [ ] **已部署 cleanup-outbox**
- [ ] **已在 Dashboard 中確認函數存在**
- [ ] **已測試函數調用**
- [ ] **已查看函數日誌（無錯誤）**

---

## 🎯 下一步

部署完成後：

1. **設置環境變數**（如果尚未設置）：
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_API_KEY`

2. **設置 Cron Job**：
   - 參考 `MANUAL_STEPS_GUIDE.md` 的步驟 4

3. **測試同步功能**：
   - 創建訂單
   - 檢查 outbox 表
   - 等待 30 秒
   - 檢查 Firestore

---

## 📞 需要協助？

如果遇到問題：

1. 查看本指南的「常見問題」區塊
2. 查看函數日誌中的錯誤訊息
3. 提供錯誤訊息和截圖以獲得協助

祝部署順利！🚀

