# RelayGo 24/7 自動派單背景服務

## 📋 概述

這是一個部署在 Railway 的 Node.js 背景服務，負責 24/7 全自動派單功能。

## 🏗️ 架構說明

```
前端（Vercel）
    ↓ 控制開關、查詢狀態
背景服務（Railway）← 您在這裡
    ↓ 讀寫資料
資料庫（Supabase）
```

## 🚀 部署到 Railway

### 步驟 1: 創建 Railway 專案

1. 訪問 https://railway.app/
2. 登入您的帳號
3. 點擊 "New Project"
4. 選擇 "Deploy from GitHub repo"
5. 選擇您的 repository（或創建新的）

### 步驟 2: 配置環境變數

在 Railway 專案設置中添加以下環境變數：

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
INTERVAL_SECONDS=30
BATCH_SIZE=10
```

### 步驟 3: 部署

Railway 會自動檢測 `package.json` 並執行：
```bash
npm install
npm start
```

## 📊 環境變數說明

| 變數名稱 | 說明 | 預設值 | 必填 |
|---------|------|--------|------|
| `SUPABASE_URL` | Supabase 專案 URL | - | ✅ |
| `SUPABASE_SERVICE_KEY` | Supabase Service Role Key | - | ✅ |
| `INTERVAL_SECONDS` | 執行間隔（秒） | 30 | ❌ |
| `BATCH_SIZE` | 每次處理的訂單數量 | 10 | ❌ |

## 🔧 本地開發

### 安裝依賴
```bash
cd railway-worker
npm install
```

### 創建 .env 文件
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
INTERVAL_SECONDS=30
BATCH_SIZE=10
```

### 啟動服務
```bash
npm run dev
```

## 📝 日誌輸出

服務運行時會輸出以下日誌：

```
🚀 24/7 自動派單服務啟動
⏱️  執行間隔: 30 秒
📦 批次大小: 10 筆
──────────────────────────────────────────────────
[2025-11-10T05:00:00.000Z] 開始執行自動派單...
✅ 自動派單已啟用，批次大小: 10
📦 找到 5 筆待派單訂單
✅ 訂單 123 派單成功
✅ 訂單 124 派單成功
⚠️  訂單 125 找不到合適的司機

📊 本次執行結果:
   - 處理訂單: 5 筆
   - 成功派單: 2 筆
   - 派單失敗: 3 筆
```

## 🎛️ 控制自動派單

### 啟用/停用

在 Supabase 執行：
```sql
-- 啟用
UPDATE system_settings
SET value = jsonb_set(value, '{enabled}', 'true')
WHERE key = 'auto_dispatch_24_7';

-- 停用
UPDATE system_settings
SET value = jsonb_set(value, '{enabled}', 'false')
WHERE key = 'auto_dispatch_24_7';
```

或在前端管理界面（Vercel）控制。

## 📈 監控

### 查看統計數據

```sql
SELECT value
FROM system_settings
WHERE key = 'auto_dispatch_24_7';
```

返回：
```json
{
  "enabled": true,
  "batch_size": 10,
  "last_run_at": "2025-11-10T05:00:00.000Z",
  "total_processed": 150,
  "total_assigned": 120,
  "total_failed": 30
}
```

## 🔄 更新部署

推送代碼到 GitHub 後，Railway 會自動重新部署。

## 🛑 停止服務

在 Railway Dashboard：
1. 進入專案設置
2. 點擊 "Stop Service"

## ⚠️ 注意事項

1. **確保 Supabase Service Key 安全**：不要提交到 Git
2. **監控 Railway 用量**：免費方案有限制
3. **調整執行間隔**：根據實際需求調整 `INTERVAL_SECONDS`
4. **錯誤處理**：服務會自動重試，但建議監控日誌

## 🆚 與 Vercel Cron Job 的比較

| 特性 | Vercel Cron | Railway Worker |
|------|-------------|----------------|
| 執行頻率 | 最多每分鐘 | **每秒都可以** ✅ |
| 準確性 | 有誤差 | **準時** ✅ |
| 長時間運行 | ❌ | **✅ 支援** |
| 成本 | 需 Pro 方案 | **免費方案可用** ✅ |
| 適合場景 | 低頻任務 | **高頻 24/7 任務** ✅ |

## 📞 支援

如有問題，請查看 Railway 日誌或聯繫開發團隊。

