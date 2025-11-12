# 🚀 GoMyPay 支付整合部署指南

**日期**: 2025-11-12
**狀態**: ✅ 代碼已推送到 GitHub (`clean-payment-fix` 分支)
**最新 Commit**: `a7b551a` (修復 TypeScript 編譯錯誤)

---

## ⚠️ 重要診斷結果

### 問題根因
Railway 生產環境仍然返回 404 錯誤的原因：

1. **Railway 監聽的是 `main` 分支**，而我們的更改在 `clean-payment-fix` 分支
2. **TypeScript 編譯錯誤已修復**：使用 `tsconfig.min.json` 成功編譯
3. **路由已正確註冊**：`minimal-server.ts` 已註冊 `gomypayRoutes` 和 `pricingRoutes`

### 解決方案
您有兩個選擇：

**方案 A（推薦）**: 在 Railway 中更改監聽的分支為 `clean-payment-fix`
**方案 B**: 將 `clean-payment-fix` 合併到 `main` 分支（需要處理 mobile 目錄衝突）

---

## 📋 已完成的工作

### 1. ✅ GoMyPay 支付提供者實現
**文件**: `backend/src/services/payment/providers/GomypayProvider.ts`

- 實現完整的 GoMyPay API 整合
- 支持測試和正式環境切換
- MD5 簽名驗證
- 支付 URL 生成
- 回調處理

### 2. ✅ 支付配置更新
**文件**: `backend/src/config/paymentConfig.ts`

- 添加 GoMyPay 配置 case
- 支持從環境變數讀取配置
- 添加 GoMyPay 顯示名稱

### 3. ✅ 路由註冊
**文件**: `backend/src/minimal-server.ts`

- 註冊 `/api/payment` 路由（GoMyPay 回調）
- 註冊 `/api/pricing` 路由（價格 API）

**文件**: `backend/src/routes/gomypay.ts`

- ✅ `/api/payment/gomypay/return` (GET/POST) - 用戶支付完成後跳轉
- ✅ `/api/payment/gomypay/callback` (POST) - GoMyPay 後台通知
- ✅ `/api/payment/gomypay-callback` (GET/POST) - 舊版回調端點（向後兼容）

### 4. ✅ TypeScript 編譯錯誤修復
- 修復未使用參數警告
- 修復類型不匹配錯誤
- 修復 `exactOptionalPropertyTypes` 錯誤

---

## 🔧 Railway 部署步驟

### 方案 A: 更改 Railway 監聽的分支（推薦）⭐

這是最快速的解決方案，不需要處理 Git 合併衝突。

#### 步驟 1: 訪問 Railway Dashboard

1. 打開瀏覽器，訪問：
   ```
   https://railway.app/dashboard
   ```

2. 登入您的 Railway 帳號

#### 步驟 2: 選擇後端服務

1. 在 Dashboard 中找到您的後端項目（應該叫 `relaygo-backend` 或類似名稱）
2. 點擊進入服務詳情頁面

#### 步驟 3: 更改部署分支

1. 點擊 **"Settings"** 標籤
2. 找到 **"Source"** 或 **"GitHub"** 部分
3. 找到 **"Branch"** 設置
4. 將分支從 `main` 更改為 `clean-payment-fix`
5. 點擊 **"Save"** 或 **"Update"**

#### 步驟 4: 觸發重新部署

Railway 應該會自動檢測到分支更改並開始部署。如果沒有：

1. 點擊 **"Deployments"** 標籤
2. 點擊 **"Deploy"** 按鈕
3. 選擇最新的 commit (`a7b551a`)

#### 步驟 5: 監控部署日誌

在 "Deployments" 標籤中，點擊最新的部署，查看日誌輸出：

**預期的成功日誌**：
```
Building...
✅ TypeScript compilation successful
✅ Firebase Admin SDK 已初始化
[GoMyPay] 初始化完成 - 環境: 測試
[GoMyPay] API URL: https://n.gomypay.asia/TestShuntClass.aspx
Payment providers initialized: [ 'mock', 'offline', 'gomypay' ]
✅ 支付提供者初始化成功
✅ Server is running on port 3000
```

---

### 方案 B: 合併到 main 分支（備選）

如果您希望保持 Railway 監聽 `main` 分支，可以使用此方案。

⚠️ **注意**: 此方案需要處理 `mobile` 目錄的 Git 衝突。

#### 步驟（暫不推薦，除非您熟悉 Git）

```bash
# 1. 切換到 main 分支
git checkout main

# 2. 合併 clean-payment-fix 分支（僅 backend 目錄）
git merge clean-payment-fix --no-commit --no-ff

# 3. 如果有衝突，解決衝突後提交
git commit -m "Merge GoMyPay integration from clean-payment-fix"

# 4. 推送到 GitHub
git push origin main
```

---

### 方案 C: 使用 Railway CLI 手動部署

如果您安裝了 Railway CLI：

```bash
# 1. 安裝 Railway CLI（如果尚未安裝）
npm install -g @railway/cli

# 2. 登入 Railway
railway login

# 3. 連接到您的項目
railway link

# 4. 部署當前分支
cd backend
railway up
```

---

## 🔐 環境變數配置

確保 Railway 項目中設置了以下環境變數：

### 必需的環境變數

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

# Supabase 配置（已存在）
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Firebase 配置（已存在）
FIREBASE_PROJECT_ID=your_project_id
# ... 其他 Firebase 配置
```

### 設置環境變數的步驟

1. **在 Railway Dashboard 中**:
   - 選擇您的後端服務
   - 點擊 "Variables" 標籤
   - 點擊 "New Variable"
   - 添加上述環境變數

2. **或使用 Railway CLI**:
   ```bash
   railway variables set PAYMENT_PROVIDER=gomypay
   railway variables set GOMYPAY_MERCHANT_ID=478A0C2370B2C364AACB347DE0754E14
   railway variables set GOMYPAY_API_KEY=f0qbvm3c0qb2qdjxwku59wimwh495271
   railway variables set GOMYPAY_TEST_MODE=true
   railway variables set GOMYPAY_RETURN_URL=https://api.relaygo.pro/api/payment/gomypay/return
   railway variables set GOMYPAY_CALLBACK_URL=https://api.relaygo.pro/api/payment/gomypay/callback
   ```

---

## ✅ 驗證部署

### 1. 檢查健康端點

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

### 2. 檢查 GoMyPay 回調端點

```bash
# 測試 Return URL
curl https://api.relaygo.pro/api/payment/gomypay/return

# 測試 Callback URL (應該返回 404，因為只接受 POST)
curl https://api.relaygo.pro/api/payment/gomypay/callback
```

**預期響應** (Return URL):
- 返回 HTML 頁面，顯示「支付處理中」

**預期響應** (Callback URL):
- GET 請求應該返回 404 或 405 (Method Not Allowed)
- POST 請求需要 GoMyPay 參數

### 3. 測試支付流程

在 Flutter 應用中：

1. **創建新訂單**
2. **點擊「支付訂金」**
3. **檢查後端日誌**:
   ```
   [GoMyPay] 創建支付請求 - 訂單: {booking_number}, 金額: {amount}
   [GoMyPay] 生成支付 URL: https://n.gomypay.asia/TestShuntClass.aspx?...
   ```

4. **檢查 Flutter 日誌**:
   ```
   I/flutter: [BookingService] 完整響應內容: {"success":true,"data":{"paymentUrl":"https://n.gomypay.asia/TestShuntClass.aspx?..."}}
   I/flutter: 🔗 導航到 /payment-webview
   ```

---

## 🐛 故障排除

### 問題 1: 仍然返回 Mock Payment URL

**症狀**:
```json
{
  "paymentUrl": "https://mock-payment.example.com/pay/mock_..."
}
```

**解決方案**:
1. 檢查 Railway 環境變數 `PAYMENT_PROVIDER` 是否設置為 `gomypay`
2. 重新部署服務
3. 檢查部署日誌，確認 GoMyPay 提供者已初始化

### 問題 2: 回調端點返回 404

**症狀**:
```json
{
  "success": false,
  "error": "Route not found"
}
```

**解決方案**:
1. 確認最新代碼已部署（commit `b01fc9e`）
2. 檢查 `minimal-server.ts` 是否註冊了 `gomypayRoutes`
3. 重新構建並部署

### 問題 3: TypeScript 編譯錯誤

**症狀**:
```
TSError: ⨯ Unable to compile TypeScript
```

**解決方案**:
1. 本地運行 `npm run build` 檢查編譯錯誤
2. 修復所有 TypeScript 錯誤
3. 推送修復並重新部署

### 問題 4: PricingService 超時

**症狀**:
```
I/flutter: [PricingService] API 請求超時，使用模擬資料
```

**解決方案**:
1. 檢查 `/api/pricing` 路由是否已註冊
2. 檢查 Supabase 連接是否正常
3. 檢查 `pricing_packages` 表是否有數據

---

## 📝 下一步

### 1. 測試支付流程

- [ ] 在 Flutter 應用中創建訂單
- [ ] 點擊支付訂金
- [ ] 驗證跳轉到 GoMyPay 測試頁面
- [ ] 完成測試支付
- [ ] 驗證回調處理和訂單狀態更新

### 2. 監控日誌

在 Railway Dashboard 中監控部署日誌，確保：
- GoMyPay 提供者成功初始化
- 沒有 TypeScript 編譯錯誤
- 所有路由正確註冊

### 3. 生產環境配置

當測試完成後，更新環境變數以使用正式環境：

```bash
GOMYPAY_TEST_MODE=false
GOMYPAY_RETURN_URL=https://api.relaygo.pro/api/payment/gomypay/return
GOMYPAY_CALLBACK_URL=https://api.relaygo.pro/api/payment/gomypay/callback
```

---

## 📞 支持

如果遇到問題，請檢查：

1. **Railway 部署日誌**: 查看詳細的錯誤信息
2. **GitHub Commit**: 確認最新代碼已推送 (`b01fc9e`)
3. **環境變數**: 確認所有必需的環境變數已設置

---

**部署完成後，請測試支付流程並報告結果！** 🚀

