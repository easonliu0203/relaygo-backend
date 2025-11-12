# 部署狀態總結

本文件說明哪些部署步驟已自動完成，哪些需要您手動操作。

---

## ✅ 已自動完成的步驟

### 1. 代碼和配置文件準備 ✅

以下文件已創建並準備就緒：

#### 資料庫 Migration
- ✅ `supabase/migrations/20250101_create_outbox_table.sql`
  - outbox 表結構
  - Trigger 函數
  - 索引和註解

#### Edge Functions
- ✅ `supabase/functions/sync-to-firestore/index.ts`
  - 同步邏輯
  - Firestore REST API 整合
  - 錯誤處理和重試機制

- ✅ `supabase/functions/cleanup-outbox/index.ts`
  - 清理舊事件邏輯

#### Firestore 安全規則
- ✅ `firebase/firestore.rules`
  - 已添加 `orders_rt` 集合規則
  - 設置為只讀（客戶端無法寫入）

#### 部署腳本
- ✅ `supabase/deploy.sh` (Linux/macOS)
- ✅ `supabase/deploy.ps1` (Windows PowerShell)
- ✅ `supabase/setup_cron_jobs.sql` (Cron Job 設置腳本)

#### 文檔
- ✅ `supabase/DEPLOYMENT_GUIDE.md` (完整部署指南)
- ✅ `supabase/MANUAL_STEPS_GUIDE.md` (手動操作詳細指南)
- ✅ `supabase/DEPLOYMENT_CHECKLIST.md` (部署檢查清單)
- ✅ `supabase/DEPLOYMENT_STATUS.md` (本文件)

### 2. 前端代碼修改 ✅

- ✅ `mobile/lib/core/services/booking_service.dart`
  - 已移除雙向同步邏輯
  - 已修改查詢邏輯（從 `orders_rt` 讀取）

---

## ⚠️ 需要手動操作的步驟

### 步驟 0：安裝 Supabase CLI（如果尚未安裝）

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

---

### 步驟 1：執行資料庫 Migration ⚠️

**需要執行的命令**:
```bash
cd d:\repo
supabase login
supabase link --project-ref vlyhwegpvpnjyocqmfqc
cd supabase
supabase db push
```

**或使用自動部署腳本**:
```bash
# Windows PowerShell
cd d:\repo\supabase
.\deploy.ps1

# Linux/macOS
cd d:\repo/supabase
chmod +x deploy.sh
./deploy.sh
```

**驗證**:
- 前往 Supabase Dashboard 檢查 `outbox` 表和 trigger 是否已創建

---

### 步驟 2：配置環境變數 ⚠️

**此步驟必須手動完成**

#### 2.1 獲取 Firebase 憑證

1. **Firebase Project ID**:
   - 前往：https://console.firebase.google.com
   - 專案設定 → 一般 → 專案 ID
   - 複製 Project ID

2. **Firebase API Key**:
   - 方法 A：專案設定 → 一般 → 您的應用程式 → Web API Key
   - 方法 B：專案設定 → 服務帳戶 → 產生新的私密金鑰

#### 2.2 在 Supabase 中設置環境變數

1. 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/settings/functions
2. 在 Secrets 區塊中添加：
   - `FIREBASE_PROJECT_ID` = `<您的 Firebase Project ID>`
   - `FIREBASE_API_KEY` = `<您的 Firebase API Key>`

**詳細步驟請參考**：`MANUAL_STEPS_GUIDE.md` 的步驟 2

---

### 步驟 3：部署 Edge Functions ⚠️

**需要執行的命令**:
```bash
cd d:\repo
supabase functions deploy sync-to-firestore
supabase functions deploy cleanup-outbox
```

**或使用自動部署腳本**（會自動執行此步驟）:
```bash
# Windows PowerShell
cd d:\repo\supabase
.\deploy.ps1

# Linux/macOS
cd d:\repo/supabase
./deploy.sh
```

**驗證**:
- 前往 Supabase Dashboard 檢查兩個函數是否已部署

---

### 步驟 4：設置 Cron Job ⚠️

**此步驟必須手動完成**

#### 4.1 啟用 pg_cron 擴展

1. 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/database/extensions
2. 搜尋 `pg_cron`
3. 點擊 "Enable"

#### 4.2 執行 SQL 腳本

1. 前往：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/sql
2. 點擊 "New query"
3. 複製 `supabase/setup_cron_jobs.sql` 的內容並貼上
4. 點擊 "Run"

**驗證**:
```sql
SELECT * FROM cron.job;
```

應該看到兩個任務：
- `sync-orders-to-firestore` (每 30 秒)
- `cleanup-old-outbox-events` (每天凌晨 2 點)

**詳細步驟請參考**：`MANUAL_STEPS_GUIDE.md` 的步驟 4

---

### 步驟 5：部署 Firestore 安全規則 ⚠️

**需要執行的命令**:
```bash
cd d:\repo/firebase
firebase deploy --only firestore:rules
```

**如果尚未安裝 Firebase CLI**:
```bash
npm install -g firebase-tools
firebase login
```

**或使用自動部署腳本**（會自動執行此步驟）:
```bash
# Windows PowerShell
cd d:\repo\supabase
.\deploy.ps1

# Linux/macOS
cd d:\repo/supabase
./deploy.sh
```

**驗證**:
- 前往 Firebase Console 檢查規則是否已更新

---

## 🚀 推薦的部署流程

### 選項 A：使用自動部署腳本（推薦）

1. **執行部署腳本**:
   ```bash
   # Windows PowerShell
   cd d:\repo\supabase
   .\deploy.ps1

   # Linux/macOS
   cd d:\repo/supabase
   chmod +x deploy.sh
   ./deploy.sh
   ```

2. **腳本會自動執行**:
   - ✅ 檢查前置條件
   - ✅ 執行資料庫 Migration
   - ⏸️ 暫停並提示您設置環境變數
   - ✅ 部署 Edge Functions
   - ⏸️ 暫停並提示您設置 Cron Job
   - ✅ 部署 Firestore 規則

3. **您只需要手動完成**:
   - ⚠️ 步驟 2：設置環境變數
   - ⚠️ 步驟 4：設置 Cron Job

### 選項 B：手動執行所有步驟

按照 `DEPLOYMENT_GUIDE.md` 中的步驟逐一執行。

---

## 📋 快速檢查清單

使用此清單快速確認部署狀態：

- [ ] **Supabase CLI 已安裝**
- [ ] **已登入 Supabase**
- [ ] **步驟 1：Migration 已執行**
- [ ] **步驟 2：環境變數已設置**（必須手動）
- [ ] **步驟 3：Edge Functions 已部署**
- [ ] **步驟 4：Cron Job 已設置**（必須手動）
- [ ] **步驟 5：Firestore 規則已部署**
- [ ] **測試：創建訂單並驗證同步**

---

## 📚 相關文檔

- **完整部署指南**：`DEPLOYMENT_GUIDE.md`
- **手動操作指南**：`MANUAL_STEPS_GUIDE.md`
- **部署檢查清單**：`DEPLOYMENT_CHECKLIST.md`
- **Outbox Pattern 設置**：`OUTBOX_PATTERN_SETUP.md`

---

## ❓ 需要協助？

如果您在部署過程中遇到任何問題：

1. **查看相關文檔**：根據問題類型查看對應的文檔
2. **檢查錯誤訊息**：記錄完整的錯誤訊息
3. **驗證前置條件**：確保所有前置條件都已滿足
4. **聯繫支援**：提供錯誤訊息和截圖

---

## 🎯 下一步

完成部署後：

1. **執行完整測試**：按照 `DEPLOYMENT_CHECKLIST.md` 中的測試流程
2. **監控系統**：定期檢查 outbox 表和 Cron Job 執行狀態
3. **優化配置**：根據實際使用情況調整同步頻率

祝部署順利！🚀

