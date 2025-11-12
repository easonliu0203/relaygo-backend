# Railway 環境變數檢查清單

## 🎯 關鍵環境變數（必須設置）

### ⭐ 支付提供者配置（最重要！）

```bash
PAYMENT_PROVIDER=gomypay
```

**說明**: 
- 這個變數決定使用哪個支付提供者
- 如果設置為 `gomypay`，系統會使用 GoMyPay 信用卡支付
- 如果設置為 `mock` 或未設置，系統會使用模擬支付（直接標記為已支付）
- **這是導致問題 2 的根本原因！**

---

### 🔐 GoMyPay 配置

```bash
# GoMyPay 商店代號（測試環境）
GOMYPAY_MERCHANT_ID=478A0C2370B2C364AACB347DE0754E14

# GoMyPay API 密鑰
GOMYPAY_API_KEY=f0qbvm3c0qb2qdjxwku59wimwh495271

# 測試模式（true = 測試環境，false = 正式環境）
GOMYPAY_TEST_MODE=true

# GoMyPay 返回 URL（支付完成後跳轉）
GOMYPAY_RETURN_URL=https://api.relaygo.pro/api/payment/gomypay/return

# GoMyPay 回調 URL（後端接收支付結果）
GOMYPAY_CALLBACK_URL=https://api.relaygo.pro/api/payment/gomypay/callback
```

**說明**:
- `GOMYPAY_MERCHANT_ID`: GoMyPay 提供的商店代號
- `GOMYPAY_API_KEY`: GoMyPay 提供的 API 密鑰（用於 MD5 簽名）
- `GOMYPAY_TEST_MODE`: 
  - `true` = 使用測試環境 (`https://n.gomypay.asia/TestShuntClass.aspx`)
  - `false` = 使用正式環境 (`https://n.gomypay.asia/ShuntClass.aspx`)
- `GOMYPAY_RETURN_URL`: 用戶支付完成後，GoMyPay 會跳轉到這個 URL
- `GOMYPAY_CALLBACK_URL`: GoMyPay 會向這個 URL 發送支付結果（後端處理）

---

### 🗄️ Supabase 配置

```bash
# Supabase 項目 URL
SUPABASE_URL=https://your-project.supabase.co

# Supabase Service Role Key（後端使用）
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**說明**:
- `SUPABASE_URL`: Supabase 項目的 URL
- `SUPABASE_SERVICE_ROLE_KEY`: 
  - 後端使用的服務角色密鑰
  - **不要使用 anon key**，因為後端需要完整的資料庫訪問權限
  - 可以在 Supabase Dashboard → Settings → API 中找到

---

## 📋 完整環境變數清單

### 必須設置的變數

| 變數名稱 | 值 | 說明 |
|---------|-----|------|
| `PAYMENT_PROVIDER` | `gomypay` | ⭐ 選擇支付提供者 |
| `GOMYPAY_MERCHANT_ID` | `478A0C2370B2C364AACB347DE0754E14` | GoMyPay 商店代號 |
| `GOMYPAY_API_KEY` | `f0qbvm3c0qb2qdjxwku59wimwh495271` | GoMyPay API 密鑰 |
| `GOMYPAY_TEST_MODE` | `true` | 測試模式 |
| `GOMYPAY_RETURN_URL` | `https://api.relaygo.pro/api/payment/gomypay/return` | 支付完成跳轉 URL |
| `GOMYPAY_CALLBACK_URL` | `https://api.relaygo.pro/api/payment/gomypay/callback` | 支付結果回調 URL |
| `SUPABASE_URL` | `https://your-project.supabase.co` | Supabase URL |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | Supabase 服務密鑰 |

### 可選的變數

| 變數名稱 | 預設值 | 說明 |
|---------|--------|------|
| `PORT` | `8080` | 伺服器端口（Railway 自動設置） |
| `NODE_ENV` | `production` | Node.js 環境 |

---

## ✅ 驗證步驟

### 步驟 1: 在 Railway Dashboard 中檢查

1. 進入 Railway Dashboard
2. 選擇您的項目（relaygo-backend）
3. 點擊 **Settings** → **Variables**
4. 確認所有必須的環境變數都已設置
5. 特別檢查 `PAYMENT_PROVIDER=gomypay` ⭐

### 步驟 2: 檢查部署日誌

在 Railway 部署日誌中，應該看到以下訊息：

```
Payment providers initialized: [ 'mock', 'offline', 'gomypay' ]
```

這表示 GoMyPay Provider 已成功註冊。

### 步驟 3: 測試 API 端點

使用以下命令測試支付端點：

```bash
# 創建測試訂單後，替換 {BOOKING_ID} 和 {FIREBASE_UID}
curl -X POST https://api.relaygo.pro/api/bookings/{BOOKING_ID}/pay-deposit \
  -H "Content-Type: application/json" \
  -d '{
    "paymentMethod": "credit_card",
    "customerUid": "{FIREBASE_UID}"
  }'
```

**預期響應（GoMyPay 模式）**:
```json
{
  "success": true,
  "data": {
    "bookingId": "...",
    "paymentId": "...",
    "transactionId": "gomypay_...",
    "paymentUrl": "https://n.gomypay.asia/TestShuntClass.aspx?...",
    "requiresRedirect": true
  }
}
```

**如果返回 `status: paid_deposit` 而沒有 `paymentUrl`**:
- ❌ `PAYMENT_PROVIDER` 沒有設置為 `gomypay`
- ❌ 或者環境變數沒有生效（需要重新部署）

---

## 🔧 如何設置環境變數

### 方法 1: Railway Dashboard（推薦）

1. 進入 Railway Dashboard
2. 選擇項目 → Settings → Variables
3. 點擊 **"New Variable"**
4. 輸入變數名稱和值
5. 點擊 **"Add"**
6. Railway 會自動觸發重新部署

### 方法 2: Railway CLI

```bash
# 安裝 Railway CLI
npm install -g @railway/cli

# 登入
railway login

# 連接到項目
railway link

# 設置環境變數
railway variables set PAYMENT_PROVIDER=gomypay
railway variables set GOMYPAY_MERCHANT_ID=478A0C2370B2C364AACB347DE0754E14
railway variables set GOMYPAY_API_KEY=f0qbvm3c0qb2qdjxwku59wimwh495271
railway variables set GOMYPAY_TEST_MODE=true
railway variables set GOMYPAY_RETURN_URL=https://api.relaygo.pro/api/payment/gomypay/return
railway variables set GOMYPAY_CALLBACK_URL=https://api.relaygo.pro/api/payment/gomypay/callback

# 查看所有環境變數
railway variables
```

---

## 🚨 常見問題

### Q1: 設置環境變數後，為什麼還是使用 Mock Provider？

**A**: 環境變數更改後，Railway 會自動重新部署。但如果沒有自動部署，請手動觸發：

1. 進入 Railway Dashboard → Deployments
2. 點擊最新部署的 **"..."** 菜單
3. 選擇 **"Redeploy"**

### Q2: 如何確認環境變數已生效？

**A**: 檢查 Railway 部署日誌中的以下訊息：

```
[API] 使用支付提供者: gomypay
```

如果顯示 `mock`，表示 `PAYMENT_PROVIDER` 沒有設置為 `gomypay`。

### Q3: GOMYPAY_API_KEY 是什麼？

**A**: 這是 GoMyPay 提供的 API 密鑰，用於生成 MD5 簽名驗證支付請求的真實性。

**MD5 簽名計算公式**:
```
MD5(商店代號 + 交易單號 + 交易金額 + 交易密碼)
```

例如：
```
MD5("478A0C2370B2C364AACB347DE0754E14" + "BK20250112001" + "1250" + "f0qbvm3c0qb2qdjxwku59wimwh495271")
```

### Q4: 測試環境和正式環境有什麼區別？

**A**: 

| 項目 | 測試環境 | 正式環境 |
|------|---------|---------|
| `GOMYPAY_TEST_MODE` | `true` | `false` |
| 支付 URL | `https://n.gomypay.asia/TestShuntClass.aspx` | `https://n.gomypay.asia/ShuntClass.aspx` |
| 測試卡號 | `4111111111111111` | 真實信用卡 |
| 實際扣款 | ❌ 不扣款 | ✅ 真實扣款 |

---

## 📞 需要幫助？

如果環境變數設置後仍有問題，請提供：

1. Railway Dashboard → Settings → Variables 的截圖
2. Railway 部署日誌的完整輸出
3. API 測試的完整響應

---

## 🎯 快速檢查命令

```bash
# 檢查 Railway 環境變數（需要 Railway CLI）
railway variables

# 測試 API 端點
curl https://api.relaygo.pro/api/pricing/packages

# 查看 Railway 部署日誌（需要 Railway CLI）
railway logs
```

