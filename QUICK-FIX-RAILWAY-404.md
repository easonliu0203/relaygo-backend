# ⚡ Railway 404 錯誤快速修復指南

**問題**: GoMyPay 回調路由返回 404 錯誤  
**根本原因**: Railway 監聽 `main` 分支，而代碼在 `clean-payment-fix` 分支  
**解決時間**: 5-10 分鐘

---

## 🎯 快速修復步驟

### 步驟 1: 訪問 Railway Dashboard

打開瀏覽器，訪問：
```
https://railway.app/dashboard
```

---

### 步驟 2: 選擇後端服務

在 Dashboard 中找到您的後端項目，點擊進入。

---

### 步驟 3: 更改部署分支 ⭐

1. 點擊 **"Settings"** 標籤
2. 找到 **"Source"** 或 **"GitHub"** 部分
3. 找到 **"Branch"** 設置
4. 將分支從 `main` 更改為 `clean-payment-fix`
5. 點擊 **"Save"**

---

### 步驟 4: 等待自動部署

Railway 會自動檢測到分支更改並開始部署。

**預計時間**: 5-10 分鐘

---

### 步驟 5: 驗證部署

#### 5.1 檢查部署日誌

在 "Deployments" 標籤中，查看最新部署的日誌：

**成功標誌**:
```
✅ Firebase Admin SDK 已初始化
[GoMyPay] 初始化完成 - 環境: 測試
[GoMyPay] API URL: https://n.gomypay.asia/TestShuntClass.aspx
Payment providers initialized: [ 'mock', 'offline', 'gomypay' ]
✅ 支付提供者初始化成功
```

#### 5.2 測試端點

```bash
# 測試 Return URL
curl https://api.relaygo.pro/api/payment/gomypay/return
```

**預期**: 返回 HTML 頁面（不是 404）

---

## ✅ 完成！

現在您可以在 Flutter 應用中測試支付流程：

1. 創建新訂單
2. 點擊「支付訂金」
3. 應該會看到 GoMyPay 支付 URL（不是 mock URL）

---

## 📋 環境變數檢查

確保 Railway 中設置了以下環境變數：

```
PAYMENT_PROVIDER=gomypay
GOMYPAY_MERCHANT_ID=478A0C2370B2C364AACB347DE0754E14
GOMYPAY_API_KEY=f0qbvm3c0qb2qdjxwku59wimwh495271
GOMYPAY_TEST_MODE=true
GOMYPAY_RETURN_URL=https://api.relaygo.pro/api/payment/gomypay/return
GOMYPAY_CALLBACK_URL=https://api.relaygo.pro/api/payment/gomypay/callback
```

如果缺少，請在 Railway Dashboard 的 "Variables" 標籤中添加。

---

## 🚨 如果仍然有問題

1. **手動觸發重新部署**: 在 "Deployments" 標籤中點擊 "Deploy"
2. **清除緩存**: 在 Railway 設置中清除構建緩存
3. **檢查日誌**: 查看部署日誌中是否有錯誤信息

---

**詳細文檔**: 
- `RAILWAY-404-DIAGNOSIS.md` - 完整診斷報告
- `GOMYPAY-DEPLOYMENT-GUIDE.md` - 詳細部署指南

