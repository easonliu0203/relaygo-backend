# 支付尾款 GOMYPAY 整合修復總結

**日期**: 2025-11-14  
**狀態**: ✅ 已完成  
**影響範圍**: Backend API + Flutter 客戶端

---

## 📋 問題描述

客戶端點擊「立即支付尾款」按鈕後，沒有跳轉到 GOMYPAY 支付頁面，而是直接標記為完成。

---

## 🔍 根本原因

1. **Backend API** (`/api/booking-flow/bookings/:bookingId/pay-balance`) 使用模擬支付
2. 沒有調用 `PaymentProviderFactory` 來生成 GOMYPAY 支付 URL
3. 沒有返回 `paymentUrl` 和 `requiresRedirect` 給客戶端
4. 客戶端無法跳轉到 GOMYPAY 支付頁面

---

## ✅ 修復內容

### 1. Backend 修改

**文件**: `backend/src/routes/bookingFlow-minimal.ts`  
**位置**: 第 812-957 行

**關鍵修改**:
- ✅ 使用 `PaymentProviderFactory` 創建支付提供者
- ✅ 調用 `provider.initiatePayment()` 生成支付 URL
- ✅ 返回 `{paymentUrl, requiresRedirect: true}` 給客戶端
- ✅ 支持 GOMYPAY 和 Mock 兩種支付方式

**代碼片段**:
```typescript
// 使用 PaymentProviderFactory
const { PaymentProviderFactory, PaymentProviderType } = await import('../services/payment/PaymentProvider');

const paymentProviderType = process.env.PAYMENT_PROVIDER === 'gomypay' 
  ? PaymentProviderType.GOMYPAY 
  : PaymentProviderType.MOCK;

const provider = PaymentProviderFactory.createProvider({
  provider: paymentProviderType,
  isTestMode: process.env.GOMYPAY_TEST_MODE === 'true',
  config: {}
});

// 發起支付
const paymentResponse = await provider.initiatePayment(paymentRequest);

// 返回支付 URL
if (paymentResponse.paymentUrl) {
  res.json({
    success: true,
    data: {
      paymentUrl: paymentResponse.paymentUrl,
      requiresRedirect: true  // ✅ 關鍵
    }
  });
}
```

---

### 2. Flutter 客戶端修改

**文件**: `mobile/lib/apps/customer/presentation/pages/payment_balance_page.dart`  
**位置**: 第 1-5 行（導入）、第 330-369 行（支付邏輯）

**關鍵修改**:
- ✅ 添加 `PaymentType` 導入
- ✅ 檢查 `requiresRedirect` 標誌
- ✅ 跳轉到 `/payment-webview` 顯示 GOMYPAY 支付頁面
- ✅ 支付完成後跳轉到訂單完成頁面

**代碼片段**:
```dart
// 檢查是否需要跳轉到支付頁面
if (paymentResult['requiresRedirect'] == true && paymentResult['paymentUrl'] != null) {
  // 跳轉到 GoMyPay 支付頁面
  await context.push('/payment-webview', extra: {
    'url': paymentResult['paymentUrl'],
    'bookingId': widget.bookingId,
    'paymentType': PaymentType.balance,  // ✅ 標記為尾款支付
  });

  // 支付完成後，跳轉到訂單完成頁面
  if (mounted) {
    context.pushReplacement('/booking-complete/${widget.bookingId}');
  }
}
```

---

## 🔄 完整支付流程

### GOMYPAY 支付流程

```
客戶點擊「立即支付尾款」
    ↓
調用 Backend API
    ↓
Backend 使用 PaymentProviderFactory 創建 GoMyPay Provider
    ↓
Backend 調用 GoMyPay API 生成支付 URL
    ↓
Backend 返回 {paymentUrl, requiresRedirect: true}
    ↓
Flutter 檢查 requiresRedirect == true
    ↓
Flutter 跳轉到 /payment-webview
    ↓
顯示 GoMyPay 支付頁面（WebView）
    ↓
客戶輸入信用卡資訊並完成支付
    ↓
GoMyPay 回調到 Backend
    ↓
Backend 驗證簽名並更新訂單狀態為 completed
    ↓
WebView 檢測到支付完成
    ↓
Flutter 跳轉到 /booking-complete
```

---

## 📁 修改的文件

### Backend
- ✅ `backend/src/routes/bookingFlow-minimal.ts` - 支付尾款 API

### Flutter
- ✅ `mobile/lib/apps/customer/presentation/pages/payment_balance_page.dart` - 支付尾款頁面

### 文檔
- ✅ `客戶端支付尾款GOMYPAY整合修復.md` - 詳細修復說明
- ✅ `支付尾款功能測試指南.md` - 測試指南
- ✅ `test-balance-payment.sh` - 測試腳本

---

## 🧪 測試方法

### 快速測試（使用腳本）

```bash
chmod +x test-balance-payment.sh
./test-balance-payment.sh <bookingId> <customerUid>
```

### 完整測試（使用 Flutter App）

1. 創建訂單並完成行程
2. 訂單狀態變為 `awaitingBalance`
3. 點擊「立即支付尾款」
4. 驗證跳轉到 GOMYPAY 支付頁面
5. 完成支付
6. 驗證訂單狀態變為 `completed`

---

## 🚀 部署步驟

### 1. Backend 部署

```bash
# 確保環境變數設置正確
PAYMENT_PROVIDER=gomypay
GOMYPAY_TEST_MODE=true  # 測試環境
# GOMYPAY_TEST_MODE=false  # 生產環境

# 提交並推送
git add .
git commit -m "修復支付尾款 GOMYPAY 整合"
git push origin main
```

### 2. Flutter App 部署

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

---

## ✅ 驗證清單

- [x] Backend API 修改完成
- [x] Flutter 客戶端修改完成
- [x] 測試腳本創建完成
- [x] 文檔創建完成
- [ ] Backend 部署到 Railway
- [ ] Flutter App 重新編譯
- [ ] 測試 GOMYPAY 支付流程
- [ ] 測試 Mock 支付流程
- [ ] 驗證支付回調
- [ ] 驗證訂單狀態更新
- [ ] 驗證聊天室系統訊息

---

## 📝 注意事項

1. **環境變數**
   - 測試環境：`PAYMENT_PROVIDER=gomypay`, `GOMYPAY_TEST_MODE=true`
   - 生產環境：`PAYMENT_PROVIDER=gomypay`, `GOMYPAY_TEST_MODE=false`

2. **支付金額**
   - GOMYPAY 金額以「分」為單位
   - 尾款金額 = 總金額 - 訂金金額

3. **訂單狀態**
   - 支付前：`trip_ended`（行程已結束）
   - 支付後：`completed`（訂單完成）

4. **回調 URL**
   - 確保 GOMYPAY 後台設置正確
   - `https://api.relaygo.pro/api/payment/gomypay/callback`

---

## 🔗 相關文件

- `客戶端支付尾款GOMYPAY整合修復.md` - 詳細修復說明
- `支付尾款功能測試指南.md` - 完整測試指南
- `test-balance-payment.sh` - 測試腳本
- `GOMYPAY-INTEGRATION-COMPLETE-SUMMARY.md` - GOMYPAY 整合總結（參考）

---

## 🎯 下一步

1. **測試**
   - 在測試環境測試完整流程
   - 驗證所有功能正常

2. **部署**
   - 部署 Backend 到 Railway
   - 重新編譯 Flutter App

3. **監控**
   - 監控支付成功率
   - 檢查錯誤日誌

4. **優化**
   - 添加支付失敗重試機制
   - 優化錯誤訊息顯示
   - 添加支付超時處理

---

## 📞 聯絡資訊

如有問題，請聯絡：
- **GitHub**: easonliu0203
- **Email**: kyle5916263@gmail.com

