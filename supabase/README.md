# 包車平台模擬金流處理系統

基於 Supabase Edge Functions 的模擬支付系統，使用 Provider Pattern 設計，支援未來無縫切換到真實金流服務。

## 🏗️ 架構設計

### Provider Pattern 架構
```
PaymentProvider (抽象層)
├── MockProvider (模擬實作)
├── StripeProvider (未來實作)
└── BluePayProvider (未來實作)
```

### API 端點
- `POST /payments/create-intent` - 建立支付意圖
- `POST /payments/confirm` - 確認支付
- `POST /payments/webhook` - 處理支付回調

## 📁 專案結構

```
supabase/
├── config.toml                    # Supabase 配置
├── functions/
│   ├── payments-create-intent/     # 建立支付意圖
│   │   └── index.ts
│   ├── payments-confirm/           # 確認支付
│   │   └── index.ts
│   ├── payments-webhook/           # 支付回調
│   │   └── index.ts
│   └── _shared/                    # 共享模組
│       ├── providers/              # 支付提供者
│       │   ├── PaymentProvider.ts  # 抽象介面
│       │   ├── MockProvider.ts     # 模擬實作
│       │   └── index.ts
│       ├── types/                  # 類型定義
│       │   └── payment.ts
│       └── utils/                  # 工具函數
│           ├── database.ts         # 資料庫操作
│           ├── validation.ts       # 資料驗證
│           └── cors.ts             # CORS 設定
├── test-payment-flow.ts            # 測試腳本
└── README.md                       # 說明文件
```

## 🚀 快速開始

### 1. 環境準備

確保已安裝 Supabase CLI：
```bash
npm install -g supabase
```

### 2. 初始化專案

```bash
# 登入 Supabase
supabase login

# 連結到現有專案
supabase link --project-ref vlyhwegpvpnjyocqmfqc
```

### 3. 部署 Edge Functions

```bash
# 部署所有函數
supabase functions deploy

# 或單獨部署
supabase functions deploy payments-create-intent
supabase functions deploy payments-confirm
supabase functions deploy payments-webhook
```

### 4. 設定環境變數

在 Supabase Dashboard 中設定以下環境變數：
```
SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
PAYMENT_PROVIDER_TYPE=mock
PAYMENT_TEST_MODE=true
```

## 🧪 測試

### 本地測試
```bash
# 啟動本地開發環境
supabase start

# 執行測試腳本
deno run --allow-net --allow-env test-payment-flow.ts
```

### API 測試範例

#### 1. 建立支付意圖
```bash
curl -X POST https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/payments-create-intent \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "123e4567-e89b-12d3-a456-426614174000",
    "customerId": "987fcdeb-51a2-43d7-8f9e-123456789abc",
    "amount": 1500.00,
    "currency": "TWD",
    "paymentType": "deposit",
    "description": "包車服務訂金"
  }'
```

#### 2. 確認支付
```bash
curl -X POST https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/payments-confirm \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "transactionId": "mock_1640995200000_abc123def"
  }'
```

#### 3. Webhook 回調
```bash
curl -X POST https://vlyhwegpvpnjyocqmfqc.supabase.co/functions/v1/payments-webhook \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "transactionId": "mock_1640995200000_abc123def",
    "externalTransactionId": "ext_1640995200000_xyz789ghi",
    "status": "completed",
    "amount": 1500.00,
    "currency": "TWD",
    "timestamp": "2024-01-01T12:00:00.000Z"
  }'
```

## 🔄 支付流程

### 完整支付流程
1. **建立支付意圖** → 生成 `transaction_id`，建立 `payments` 記錄
2. **用戶支付** → 模擬支付頁面（實際環境中為真實支付）
3. **確認支付** → 更新支付狀態為 `completed`
4. **更新訂單** → 根據支付類型更新 `bookings` 狀態
5. **Webhook 通知** → 同步支付狀態變更

### 狀態流轉
- **Payment**: `pending` → `processing` → `completed`/`failed`
- **Booking**: `pending_payment` → `paid_deposit`/`completed`

## 🔧 擴展到真實金流

### 1. 實作新的 Provider
```typescript
export class StripeProvider extends PaymentProvider {
  readonly name = 'Stripe Payment Provider';
  readonly type = 'stripe';
  readonly isTestMode = false;

  async createPaymentIntent(request: PaymentIntentRequest): Promise<PaymentIntentResponse> {
    // 實作 Stripe 支付邏輯
  }
  
  // ... 其他方法
}
```

### 2. 註冊新 Provider
```typescript
PaymentProviderFactory.registerProvider('stripe', new StripeProvider());
```

### 3. 更新配置
```typescript
const paymentService = new PaymentService({
  providerType: 'stripe', // 從 'mock' 改為 'stripe'
  isTestMode: false,
  apiKey: process.env.STRIPE_API_KEY,
  secretKey: process.env.STRIPE_SECRET_KEY,
});
```

## 📊 監控和日誌

所有 API 調用都會記錄詳細日誌，可在 Supabase Dashboard 的 Edge Functions 日誌中查看：
- 請求參數
- 處理結果
- 錯誤資訊
- 執行時間

## 🔒 安全性

- 使用 Supabase Service Role Key 進行資料庫操作
- 所有 API 端點都有輸入驗證
- 支援 CORS 跨域請求
- 敏感資料加密存儲

## 📝 注意事項

1. **測試模式**: 當前為模擬支付，所有交易都會自動成功
2. **資料庫相容**: 完全相容現有的 `payments` 和 `bookings` 表結構
3. **冪等性**: 所有 API 都支援重複調用而不產生副作用
4. **錯誤處理**: 完整的錯誤處理和回滾機制

## 🆘 故障排除

### 常見問題
1. **函數部署失敗**: 檢查 Supabase CLI 版本和專案連結
2. **資料庫連接錯誤**: 確認 Service Role Key 設定正確
3. **CORS 錯誤**: 檢查前端請求的 Headers 設定

### 日誌查看
```bash
# 查看函數日誌
supabase functions logs payments-create-intent
supabase functions logs payments-confirm
supabase functions logs payments-webhook
```

---

## 🔄 Outbox Pattern（單向鏡像模式）

### 概述

本專案實作了 Outbox Pattern，將 Supabase 的訂單資料單向鏡像到 Firestore，實現：
- ✅ Supabase 作為唯一的資料寫入來源（Single Source of Truth）
- ✅ Firestore 作為即時資料的只讀鏡像
- ✅ 可靠的事件處理和自動重試機制

### 快速部署

**使用自動部署腳本**（推薦）：

```bash
# Windows PowerShell
cd d:\repo\supabase
.\deploy.ps1

# Linux/macOS
cd d:\repo/supabase
chmod +x deploy.sh
./deploy.sh
```

### 相關文檔

- **[快速開始指南](./QUICK_START.md)** - 10 分鐘快速部署
- **[完整部署指南](./DEPLOYMENT_GUIDE.md)** - 詳細的部署步驟
- **[手動操作指南](./MANUAL_STEPS_GUIDE.md)** - 手動步驟詳解
- **[部署檢查清單](./DEPLOYMENT_CHECKLIST.md)** - 可打印的檢查清單
- **[Outbox Pattern 設置](./OUTBOX_PATTERN_SETUP.md)** - 技術文檔

### 架構流程

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

### 部署步驟

| 步驟 | 內容 | 自動化 |
|------|------|--------|
| 1 | 執行資料庫 Migration | ✅ 自動 |
| 2 | 配置環境變數 | ⚠️ 手動 |
| 3 | 部署 Edge Functions | ✅ 自動 |
| 4 | 設置 Cron Job | ⚠️ 手動 |
| 5 | 更新 Firestore 規則 | ✅ 自動 |

**自動化程度**：60%（3/5 步驟可自動化）

### 監控指標

```sql
-- 檢查未處理事件數量
SELECT COUNT(*) FROM outbox WHERE processed_at IS NULL;

-- 檢查失敗事件
SELECT * FROM outbox WHERE retry_count >= 3;

-- 查看 Cron Job 執行歷史
SELECT * FROM cron.job_run_details
WHERE jobid IN (SELECT jobid FROM cron.job WHERE jobname = 'sync-orders-to-firestore')
ORDER BY start_time DESC
LIMIT 10;
```

---

## 🔗 相關連結

- **Supabase Dashboard**：https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc
- **Firebase Console**：https://console.firebase.google.com
- **專案文檔**：[../docs/](../docs/)
