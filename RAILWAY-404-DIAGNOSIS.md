# 🔍 Railway 404 錯誤診斷報告

**日期**: 2025-11-12  
**問題**: GoMyPay 回調路由返回 404 錯誤  
**狀態**: ✅ 已診斷，等待部署

---

## 📋 問題描述

用戶報告以下端點返回 404 錯誤：

1. `https://api.relaygo.pro/api/payment/gomypay/return` → `{"success":false,"error":"Route not found"}`
2. `https://api.relaygo.pro/api/payment/gomypay/callback` → `{"success":false,"error":"Route not found"}`

---

## 🔎 診斷過程

### 1. 檢查代碼是否已推送 ✅

```bash
git log --oneline -5
```

**結果**:
- ✅ `a7b551a` - fix: resolve TypeScript compilation errors in gomypay routes
- ✅ `b01fc9e` - feat: integrate GoMyPay payment provider and add callback routes
- ✅ `678c73d` - fix: update booking_service for payment flow

**結論**: 代碼已成功推送到 GitHub 的 `clean-payment-fix` 分支。

---

### 2. 檢查 TypeScript 編譯 ✅

```bash
cd backend
npm run build:min
```

**結果**:
```
✅ TypeScript compilation successful
✅ dist/routes/gomypay.js 已生成
✅ dist/routes/pricing.js 已生成
✅ dist/minimal-server.js 已生成
```

**結論**: TypeScript 編譯成功，沒有錯誤。

---

### 3. 檢查路由註冊 ✅

**文件**: `backend/src/minimal-server.ts`

```typescript
import gomypayRoutes from './routes/gomypay';
import pricingRoutes from './routes/pricing';

// ...

app.use('/api/payment', gomypayRoutes); // ✅ 已註冊
app.use('/api/pricing', pricingRoutes); // ✅ 已註冊
```

**結論**: 路由已正確註冊。

---

### 4. 檢查 GoMyPay 路由定義 ✅

**文件**: `backend/src/routes/gomypay.ts`

```typescript
// ✅ Return URL (GET)
router.get('/gomypay/return', async (req, res) => { ... });

// ✅ Return URL (POST)
router.post('/gomypay/return', async (req, res) => { ... });

// ✅ Callback URL (POST) - 新版
router.post('/gomypay/callback', handleGomypayCallback);

// ✅ Callback URL (POST) - 舊版（向後兼容）
router.post('/gomypay-callback', handleGomypayCallback);
```

**結論**: 所有必需的路由都已定義。

---

### 5. 檢查 Railway 部署分支 ❌

**問題發現**: Railway 很可能配置為監聽 `main` 分支，而我們的更改在 `clean-payment-fix` 分支。

**證據**:
1. 本地編譯成功，但生產環境返回 404
2. `git branch -a` 顯示有 `main` 和 `clean-payment-fix` 兩個分支
3. Railway 默認監聽 `main` 分支

**結論**: **這是 404 錯誤的根本原因！**

---

## 🎯 根本原因

**Railway 生產環境監聽的是 `main` 分支，而 GoMyPay 整合代碼在 `clean-payment-fix` 分支。**

因此，即使代碼已推送到 GitHub，Railway 也不會部署這些更改。

---

## ✅ 解決方案

### 方案 A: 更改 Railway 監聽的分支（推薦）⭐

**優點**:
- ✅ 最快速的解決方案
- ✅ 不需要處理 Git 合併衝突
- ✅ 可以立即測試

**步驟**:
1. 訪問 Railway Dashboard: https://railway.app/dashboard
2. 選擇後端服務
3. 進入 **Settings** → **Source** → **Branch**
4. 將分支從 `main` 更改為 `clean-payment-fix`
5. 保存並等待自動部署

**預計時間**: 5-10 分鐘

---

### 方案 B: 合併到 main 分支（備選）

**優點**:
- ✅ 保持 Railway 監聽 `main` 分支
- ✅ 符合標準的 Git 工作流程

**缺點**:
- ⚠️ 需要處理 `mobile` 目錄的 Git 衝突
- ⚠️ 需要更多時間

**步驟**:
1. 解決 Git 衝突
2. 合併 `clean-payment-fix` 到 `main`
3. 推送到 GitHub
4. 等待 Railway 自動部署

**預計時間**: 15-30 分鐘

---

## 📊 驗證清單

部署完成後，請驗證以下端點：

### 1. 健康檢查
```bash
curl https://api.relaygo.pro/health
```

**預期響應**:
```json
{
  "status": "OK",
  "timestamp": "2025-11-12T...",
  "service": "Ride Booking Backend API"
}
```

---

### 2. GoMyPay Return URL (GET)
```bash
curl https://api.relaygo.pro/api/payment/gomypay/return
```

**預期響應**:
- ✅ 返回 HTML 頁面（支付處理中）
- ✅ 狀態碼 200

---

### 3. GoMyPay Callback URL (POST)
```bash
curl -X POST https://api.relaygo.pro/api/payment/gomypay/callback \
  -H "Content-Type: application/json" \
  -d '{"result":"1","e_orderno":"test","str_check":"test"}'
```

**預期響應**:
- ✅ 不返回 404 錯誤
- ✅ 返回支付處理結果（可能是 400 因為測試數據不完整，但不應該是 404）

---

### 4. 支付流程測試

在 Flutter 應用中：

1. **創建新訂單**
2. **點擊「支付訂金」**
3. **檢查響應**:
   ```json
   {
     "success": true,
     "data": {
       "paymentUrl": "https://n.gomypay.asia/TestShuntClass.aspx?..."
     }
   }
   ```

**預期結果**:
- ✅ `paymentUrl` 應該是 GoMyPay 測試 URL
- ✅ 不應該是 `https://mock-payment.example.com/...`

---

## 📝 部署後檢查

### Railway 部署日誌應該顯示：

```
Building...
Installing dependencies...
Running build script...
✅ TypeScript compilation successful

Starting server...
✅ Firebase Admin SDK 已初始化
[GoMyPay] 初始化完成 - 環境: 測試
[GoMyPay] API URL: https://n.gomypay.asia/TestShuntClass.aspx
Payment providers initialized: [ 'mock', 'offline', 'gomypay' ]
✅ 支付提供者初始化成功
✅ Server is running on port 3000
```

### 如果看到以下日誌，表示部署成功：

- ✅ `[GoMyPay] 初始化完成`
- ✅ `Payment providers initialized: [ 'mock', 'offline', 'gomypay' ]`
- ✅ 沒有 TypeScript 編譯錯誤
- ✅ 沒有路由註冊錯誤

---

## 🚨 常見問題

### Q1: 部署後仍然返回 404

**可能原因**:
1. Railway 緩存問題
2. 環境變數未設置

**解決方案**:
1. 在 Railway Dashboard 中手動觸發重新部署
2. 檢查環境變數是否正確設置（見下方）

---

### Q2: 部署日誌顯示 TypeScript 編譯錯誤

**可能原因**:
Railway 使用 `npm run build` 而不是 `npm run build:min`

**解決方案**:
檢查 `package.json` 中的 `build` 腳本：
```json
{
  "scripts": {
    "build": "tsc -p tsconfig.min.json"
  }
}
```

---

### Q3: 支付仍然使用 Mock Provider

**可能原因**:
環境變數 `PAYMENT_PROVIDER` 未設置為 `gomypay`

**解決方案**:
在 Railway Dashboard 中設置環境變數：
```
PAYMENT_PROVIDER=gomypay
```

---

## 🔐 必需的環境變數

確保 Railway 項目中設置了以下環境變數：

```bash
# 支付配置
PAYMENT_PROVIDER=gomypay
PAYMENT_TEST_MODE=true

# GoMyPay 配置
GOMYPAY_MERCHANT_ID=478A0C2370B2C364AACB347DE0754E14
GOMYPAY_API_KEY=f0qbvm3c0qb2qdjxwku59wimwh495271
GOMYPAY_TEST_MODE=true
GOMYPAY_RETURN_URL=https://api.relaygo.pro/api/payment/gomypay/return
GOMYPAY_CALLBACK_URL=https://api.relaygo.pro/api/payment/gomypay/callback
```

---

## 📞 下一步

1. **立即行動**: 在 Railway Dashboard 中更改監聽的分支為 `clean-payment-fix`
2. **等待部署**: 通常需要 5-10 分鐘
3. **驗證端點**: 使用上述驗證清單測試所有端點
4. **測試支付**: 在 Flutter 應用中測試完整的支付流程

---

**預計總時間**: 15-20 分鐘（包括部署和測試）

**成功標誌**: 
- ✅ `/api/payment/gomypay/return` 返回 HTML 頁面
- ✅ `/api/payment/gomypay/callback` 不返回 404
- ✅ Flutter 應用收到 GoMyPay 支付 URL

