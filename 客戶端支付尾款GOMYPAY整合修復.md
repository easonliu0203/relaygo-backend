# 客戶端支付尾款 GOMYPAY 整合修復

**修復時間**: 2025-11-14  
**狀態**: ✅ 已完成

---

## 📋 問題描述

客戶端點擊「立即支付尾款」按鈕後，沒有跳轉到 GOMYPAY 支付頁面，而是直接標記為完成。

### 原因分析

1. ❌ **Backend API** (`/api/booking-flow/bookings/:bookingId/pay-balance`) 使用模擬支付
2. ❌ 沒有調用 `PaymentProviderFactory` 來生成 GOMYPAY 支付 URL
3. ❌ 沒有返回 `paymentUrl` 和 `requiresRedirect` 給客戶端
4. ❌ 客戶端無法跳轉到 GOMYPAY 支付頁面

---

## ✅ 修復內容

### 1. Backend API 修改

**文件**: `backend/src/routes/bookingFlow-minimal.ts`

**修改位置**: 第 812-957 行

**修改內容**:

#### 修改前（模擬支付）
```typescript
// 6. 模擬支付處理
console.log('[API] 模擬支付處理:', {
  amount: balanceAmount,
  method: paymentMethod
});

// 7. 創建支付記錄
const paymentData = {
  booking_id: bookingId,
  customer_id: customer.id,
  type: 'balance',
  amount: balanceAmount,
  currency: 'TWD',
  status: 'processing',  // 模擬支付處理中
  payment_provider: 'mock',
  // ...
};

// 8. 更新訂單狀態為 completed（直接完成）
const { error: updateError } = await supabase
  .from('bookings')
  .update({
    status: 'completed',
    updated_at: now
  })
  .eq('id', bookingId);

// 10. 返回成功響應（沒有 paymentUrl）
res.json({
  success: true,
  data: {
    paymentId: payment.id,
    transactionId: payment.transaction_id,
    amount: balanceAmount,
    status: 'processing',
    isAutoPayment: true,
    message: '尾款支付成功'
  }
});
```

#### 修改後（使用 PaymentProviderFactory）
```typescript
// 6. 使用 PaymentProviderFactory 創建支付提供者
const { PaymentProviderFactory, PaymentProviderType } = await import('../services/payment/PaymentProvider');

const paymentProviderType = process.env.PAYMENT_PROVIDER === 'gomypay' 
  ? PaymentProviderType.GOMYPAY 
  : PaymentProviderType.MOCK;

const provider = PaymentProviderFactory.createProvider({
  provider: paymentProviderType,
  isTestMode: process.env.GOMYPAY_TEST_MODE === 'true',
  config: {}
});

// 7. 發起支付
const paymentRequest = {
  orderId: booking.booking_number,
  amount: balanceAmount,
  currency: 'TWD',
  description: `RelayGo 訂單尾款 - ${booking.booking_number}`,
  customerInfo: {
    id: customer.id,
    name: booking.customer_name || '客戶',
    email: '',
    phone: booking.customer_phone || ''
  },
  metadata: {
    bookingId: booking.id,
    paymentType: 'balance'
  }
};

const paymentResponse = await provider.initiatePayment(paymentRequest);

// 8. 創建支付記錄（狀態為 pending）
const paymentData = {
  booking_id: bookingId,
  customer_id: customer.id,
  transaction_id: paymentResponse.transactionId,
  type: 'balance',
  amount: balanceAmount,
  currency: 'TWD',
  status: 'pending', // 等待支付完成
  payment_provider: paymentProviderType,
  payment_method: paymentMethod || 'credit_card',
  is_test_mode: process.env.GOMYPAY_TEST_MODE === 'true',
  // ...
};

// 9. 返回支付 URL（如果有）
if (paymentResponse.paymentUrl) {
  // GoMyPay 或其他需要跳轉的支付方式
  res.json({
    success: true,
    data: {
      bookingId,
      paymentId: payment.id,
      transactionId: paymentResponse.transactionId,
      paymentUrl: paymentResponse.paymentUrl,
      instructions: paymentResponse.instructions,
      expiresAt: paymentResponse.expiresAt,
      requiresRedirect: true  // ✅ 關鍵：告訴客戶端需要跳轉
    }
  });
} else {
  // Mock 支付：直接更新訂單狀態為 completed
  // ...
}
```

---

### 2. Flutter 客戶端修改

**文件**: `mobile/lib/apps/customer/presentation/pages/payment_balance_page.dart`

**修改內容**:

#### 1. 添加導入
```dart
import '../../../../core/services/payment/payment_models.dart';
```

#### 2. 修改支付處理邏輯（第 330-369 行）

**修改前**:
```dart
void _processPayment() async {
  setState(() => _isProcessing = true);

  try {
    await _bookingService.payBalance(
      widget.bookingId,
      _selectedPaymentMethod,
    );

    // 直接導航到訂單完成頁面
    if (mounted) {
      context.pushReplacement('/booking-complete/${widget.bookingId}');
    }
  } catch (e) {
    _showErrorDialog('支付處理失敗：$e');
  } finally {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}
```

**修改後**:
```dart
void _processPayment() async {
  setState(() => _isProcessing = true);

  try {
    // 調用支付尾款 API
    final paymentResult = await _bookingService.payBalance(
      widget.bookingId,
      _selectedPaymentMethod,
    );

    if (!mounted) return;

    // ✅ 檢查是否需要跳轉到支付頁面（GoMyPay 等第三方支付）
    if (paymentResult['requiresRedirect'] == true && paymentResult['paymentUrl'] != null) {
      // 跳轉到 GoMyPay 支付頁面
      debugPrint('[PaymentBalance] 跳轉到支付頁面: ${paymentResult['paymentUrl']}');
      await context.push('/payment-webview', extra: {
        'url': paymentResult['paymentUrl'],
        'bookingId': widget.bookingId,
        'paymentType': PaymentType.balance,  // ✅ 標記為尾款支付
      });

      // 支付完成後，跳轉到訂單完成頁面
      if (mounted) {
        context.pushReplacement('/booking-complete/${widget.bookingId}');
      }
    } else {
      // 自動支付（Mock）或不需要跳轉，直接導航到訂單完成頁面
      debugPrint('[PaymentBalance] 自動支付完成，跳轉到訂單完成頁面');
      context.pushReplacement('/booking-complete/${widget.bookingId}');
    }
  } catch (e) {
    debugPrint('[PaymentBalance] ❌ 支付處理失敗: $e');
    _showErrorDialog('支付處理失敗：$e');
  } finally {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}
```

---

## 🔄 完整支付流程

### GOMYPAY 支付流程（生產環境）

```
1. 客戶點擊「立即支付尾款」
   ↓
2. 調用 Backend API: POST /api/booking-flow/bookings/:bookingId/pay-balance
   ↓
3. Backend 使用 PaymentProviderFactory 創建 GoMyPay Provider
   ↓
4. Backend 調用 GoMyPay API 生成支付 URL
   ↓
5. Backend 返回 {paymentUrl, requiresRedirect: true}
   ↓
6. ✅ Flutter 檢查 requiresRedirect == true
   ↓
7. ✅ Flutter 跳轉到 /payment-webview
   ↓
8. 顯示 GoMyPay 支付頁面（WebView）
   ↓
9. 客戶輸入信用卡資訊並完成支付
   ↓
10. GoMyPay 回調到 https://api.relaygo.pro/api/payment/gomypay/callback
    ↓
11. Backend 驗證 MD5 簽名
    ↓
12. Backend 更新訂單狀態為 completed
    ↓
13. WebView 檢測到支付完成（URL 變化）
    ↓
14. Flutter 跳轉到 /booking-complete
```

### Mock 支付流程（測試環境）

```
1. 客戶點擊「立即支付尾款」
   ↓
2. 調用 Backend API
   ↓
3. Backend 使用 Mock Provider（不生成 paymentUrl）
   ↓
4. Backend 直接更新訂單狀態為 completed
   ↓
5. Backend 返回 {requiresRedirect: false}
   ↓
6. Flutter 直接跳轉到 /booking-complete
```

---

## 🧪 測試步驟

### 前置條件

1. 確保 Backend 正在運行
2. 設置環境變數：
   ```bash
   PAYMENT_PROVIDER=gomypay  # 使用 GOMYPAY
   GOMYPAY_TEST_MODE=true    # 測試模式
   ```

### 測試流程

1. **創建測試訂單並完成行程**
   - 客戶端創建訂單
   - 支付訂金
   - 司機確認接單 → 出發 → 到達
   - 客戶開始行程
   - 客戶結束行程

2. **測試支付尾款**
   - 訂單狀態應為 `awaitingBalance`（待付尾款）
   - 點擊「立即支付尾款」按鈕
   - 檢查是否跳轉到 GOMYPAY 支付頁面
   - 完成支付
   - 檢查是否跳轉到訂單完成頁面

3. **驗證結果**
   - 檢查訂單狀態是否為 `completed`
   - 檢查 `payments` 表中是否有尾款支付記錄
   - 檢查聊天室是否收到系統訊息

---

## 📝 注意事項

1. **環境變數配置**
   - `PAYMENT_PROVIDER=gomypay` - 使用 GOMYPAY
   - `PAYMENT_PROVIDER=mock` - 使用模擬支付（測試）

2. **支付金額計算**
   - 尾款金額 = 總金額 - 訂金金額
   - Backend 會自動計算

3. **支付回調**
   - GOMYPAY 回調 URL: `https://api.relaygo.pro/api/payment/gomypay/callback`
   - 回調會更新訂單狀態和支付記錄

---

## ✅ 完成清單

- [x] 修改 Backend API 使用 PaymentProviderFactory
- [x] 修改 Flutter 客戶端支付處理邏輯
- [x] 添加 GOMYPAY 支付 URL 跳轉
- [x] 創建測試文檔
- [ ] 測試 GOMYPAY 支付流程
- [ ] 測試 Mock 支付流程
- [ ] 驗證支付回調

