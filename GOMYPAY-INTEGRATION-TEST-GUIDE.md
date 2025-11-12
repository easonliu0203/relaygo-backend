# GoMyPay 整合測試指南

## 📋 修復摘要

### ✅ 已完成的修復

#### 1. **支付流程整合 GoMyPay Provider** (commit `63c9ec1`)
- ✅ 移除 `backend/src/routes/bookings.ts` 中的硬編碼模擬支付邏輯
- ✅ 整合 `PaymentProviderFactory` 來動態選擇支付提供者
- ✅ 根據 `PAYMENT_PROVIDER` 環境變數選擇 GoMyPay 或 Mock
- ✅ 返回 `paymentUrl` 供 Flutter 應用跳轉到 GoMyPay 支付頁面
- ✅ 創建支付記錄時使用 `status: 'pending'`（等待回調確認）
- ✅ 支持兩種支付流程：
  - **GoMyPay**: 返回 `paymentUrl`，需要跳轉
  - **Mock**: 自動完成，直接返回 `status: paid_deposit`

#### 2. **Railway 部署配置** (之前的 commits)
- ✅ Root Directory: `/backend`
- ✅ Custom Build Command: `npm run build:min`
- ✅ Custom Start Command: `node dist/minimal-server.js`
- ✅ `tsconfig.min.json` 已添加並推送
- ✅ `railway.json` 已配置

---

## 🚀 Railway 部署驗證步驟

### 步驟 1: 確認 Railway 環境變數

在 Railway Dashboard → Settings → Variables 中確認以下環境變數：

```bash
# 必須設置的環境變數
PAYMENT_PROVIDER=gomypay          # ⭐ 關鍵：選擇 GoMyPay 提供者
GOMYPAY_MERCHANT_ID=478A0C2370B2C364AACB347DE0754E14
GOMYPAY_API_KEY=f0qbvm3c0qb2qdjxwku59wimwh495271
GOMYPAY_TEST_MODE=true            # 測試模式
GOMYPAY_RETURN_URL=https://api.relaygo.pro/api/payment/gomypay/return
GOMYPAY_CALLBACK_URL=https://api.relaygo.pro/api/payment/gomypay/callback

# Supabase 環境變數
SUPABASE_URL=<your-supabase-url>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
```

**⚠️ 重要**: 如果 `PAYMENT_PROVIDER` 沒有設置為 `gomypay`，系統會使用 Mock Provider！

### 步驟 2: 監控 Railway 部署

1. 進入 Railway Dashboard → Deployments
2. 查看最新部署（commit `63c9ec1`）
3. 確認部署狀態為 **"Success"**
4. 檢查部署日誌中是否有以下訊息：

```
Payment providers initialized: [ 'mock', 'offline', 'gomypay' ]
Server running on port 8080
```

### 步驟 3: 測試 API 端點

#### 3.1 測試 Pricing API（診斷問題 1）

```bash
# 測試價格 API
curl https://api.relaygo.pro/api/pricing/packages

# 預期響應
{
  "success": true,
  "data": [
    {
      "id": "small_6h",
      "name": "3-4人座 6小時方案",
      "duration": 6,
      "originalPrice": 50,
      "discountPrice": 50,
      "overtimeRate": 5,
      "vehicleCategory": "small",
      "features": [...]
    },
    ...
  ],
  "source": "database" // 或 "mock"
}
```

**如果超時或失敗**:
- 檢查 Railway 部署日誌中是否有 Supabase 連接錯誤
- 確認 `SUPABASE_URL` 和 `SUPABASE_SERVICE_ROLE_KEY` 環境變數正確
- 檢查 Supabase `vehicle_pricing` 表是否有資料

#### 3.2 測試 GoMyPay 支付流程（診斷問題 2）

**步驟 A: 創建測試訂單**

```bash
# 1. 先創建一個測試訂單（使用您的 Flutter 應用或 API）
# 假設訂單 ID 為: 7c08f2db-2ab1-460d-8559-59870e363850
```

**步驟 B: 測試支付訂金端點**

```bash
curl -X POST https://api.relaygo.pro/api/bookings/7c08f2db-2ab1-460d-8559-59870e363850/pay-deposit \
  -H "Content-Type: application/json" \
  -d '{
    "paymentMethod": "credit_card",
    "customerUid": "<your-firebase-uid>"
  }'
```

**預期響應（GoMyPay 模式）**:
```json
{
  "success": true,
  "data": {
    "bookingId": "7c08f2db-2ab1-460d-8559-59870e363850",
    "paymentId": "d55d16d0-8277-4049-adb5-fc862490e4ff",
    "transactionId": "gomypay_1762963978338_hdwhbisct",
    "paymentUrl": "https://n.gomypay.asia/TestShuntClass.aspx?...",
    "instructions": "請在支付頁面完成信用卡支付",
    "expiresAt": "2025-01-12T10:30:00.000Z",
    "requiresRedirect": true
  }
}
```

**⚠️ 如果返回 `status: paid_deposit` 而沒有 `paymentUrl`**:
- 檢查 Railway 環境變數 `PAYMENT_PROVIDER` 是否設置為 `gomypay`
- 檢查 Railway 部署日誌中的 `[API] 使用支付提供者:` 訊息
- 應該顯示 `gomypay`，而不是 `mock`

#### 3.3 測試 GoMyPay Callback 端點

```bash
# 模擬 GoMyPay 回調（測試用）
curl -X POST https://api.relaygo.pro/api/payment/gomypay/callback \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "Send_Type=1&Pay_Mode_No=2&CustomerId=478A0C2370B2C364AACB347DE0754E14&Order_No=BK20250112001&Amount=1250&Tr_No=TEST123456&Datetime=2025-01-12+10:00:00&ChkValue=<calculated-md5>"
```

**預期響應**:
```
1|OK
```

---

## 📱 Flutter 應用測試步驟

### 步驟 1: 測試 PricingService

1. 打開 Flutter 應用
2. 進入「新增預約」頁面
3. 查看 Flutter 日誌：

```
I/flutter: [PricingService] 成功獲取價格資料
I/flutter: [PricingService] 價格方案數量: 4
```

**如果仍然顯示「使用模擬資料」**:
- 檢查 Flutter 應用的 API 超時設置（可能太短）
- 檢查網絡連接
- 使用 `curl` 測試 API 端點是否正常

### 步驟 2: 測試 GoMyPay 支付流程

1. 創建新訂單
2. 點擊「支付訂金」
3. 查看 Flutter 日誌：

```
I/flutter: [BookingService] 支付請求成功
I/flutter: [BookingService] 返回數據: {
  bookingId: ...,
  paymentId: ...,
  transactionId: gomypay_...,
  paymentUrl: https://n.gomypay.asia/TestShuntClass.aspx?...,
  requiresRedirect: true
}
I/flutter: [BookingService] 跳轉到支付頁面
```

4. 確認應用跳轉到 `/payment-webview` 頁面
5. 確認 WebView 顯示 GoMyPay 支付頁面
6. 使用測試信用卡完成支付：
   - **測試卡號**: `4111111111111111`
   - **有效期**: 任意未來日期（例如 `12/25`）
   - **CVV**: `123`

7. 支付完成後，GoMyPay 會回調到：
   ```
   https://api.relaygo.pro/api/payment/gomypay/callback
   ```

8. 後端處理回調後，訂單狀態應更新為 `paid_deposit`

---

## 🔍 問題診斷清單

### 問題 1: PricingService 超時

**症狀**: `[PricingService] API 請求超時，使用模擬資料`

**診斷步驟**:
1. ✅ 測試 API 端點: `curl https://api.relaygo.pro/api/pricing/packages`
2. ✅ 檢查 Railway 部署日誌是否有錯誤
3. ✅ 確認 Supabase 環境變數正確
4. ✅ 檢查 Flutter 應用的超時設置（可能需要增加到 30 秒）

**可能的解決方案**:
- 增加 Flutter 應用的 API 請求超時時間
- 檢查 Supabase `vehicle_pricing` 表是否有資料
- 如果 Supabase 查詢失敗，API 會自動使用模擬資料（這是正常的降級行為）

### 問題 2: 支付流程沒有顯示 GoMyPay 頁面

**症狀**: 直接返回 `status: paid_deposit`，沒有 `paymentUrl`

**診斷步驟**:
1. ✅ 檢查 Railway 環境變數 `PAYMENT_PROVIDER=gomypay`
2. ✅ 檢查 Railway 部署日誌中的 `[API] 使用支付提供者:` 訊息
3. ✅ 確認最新代碼已部署（commit `63c9ec1`）
4. ✅ 測試 API 端點返回的響應格式

**解決方案**:
- ✅ **已修復**: 代碼已更新為使用 `PaymentProviderFactory`
- ⚠️ **必須設置**: Railway 環境變數 `PAYMENT_PROVIDER=gomypay`
- ⚠️ **必須重新部署**: 確認 Railway 已部署最新代碼

---

## ✅ 驗證清單

在測試之前，請確認以下所有項目：

- [ ] Railway Root Directory 設置為 `/backend`
- [ ] Railway 環境變數 `PAYMENT_PROVIDER=gomypay` ⭐ **最重要**
- [ ] Railway 環境變數 `GOMYPAY_MERCHANT_ID` 已設置
- [ ] Railway 環境變數 `GOMYPAY_API_KEY` 已設置
- [ ] Railway 環境變數 `GOMYPAY_TEST_MODE=true`
- [ ] Railway 環境變數 `GOMYPAY_RETURN_URL` 已設置
- [ ] Railway 環境變數 `GOMYPAY_CALLBACK_URL` 已設置
- [ ] Railway 最新部署成功（commit `63c9ec1`）
- [ ] 本地構建成功 (`npm run build:min`)
- [ ] 代碼已推送到 GitHub `clean-payment-fix` 分支

---

## 📞 如果問題仍然存在

請提供以下資訊：

1. **Railway 部署日誌**（完整輸出）
2. **API 測試結果**（`curl` 命令的完整響應）
3. **Flutter 應用日誌**（完整的 `[BookingService]` 和 `[PricingService]` 日誌）
4. **Railway 環境變數截圖**（Settings → Variables）
5. **Railway 部署狀態截圖**（Deployments 頁面）

---

## 🎯 預期結果

**成功的支付流程**:
1. 用戶點擊「支付訂金」
2. Flutter 調用 `/api/bookings/{id}/pay-deposit`
3. 後端返回 GoMyPay `paymentUrl`
4. Flutter 跳轉到 `/payment-webview` 並顯示 GoMyPay 頁面
5. 用戶輸入信用卡資訊並完成支付
6. GoMyPay 回調到 `https://api.relaygo.pro/api/payment/gomypay/callback`
7. 後端更新訂單狀態為 `paid_deposit`
8. Flutter 顯示「預約成功」頁面

**成功的價格獲取**:
1. Flutter 調用 `/api/pricing/packages`
2. 後端從 Supabase 查詢價格資料
3. 返回 4 個價格方案（small_6h, small_8h, large_6h, large_8h）
4. Flutter 顯示正確的價格資訊

