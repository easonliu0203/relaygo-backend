# Flutter 支付流程修復報告

**日期**: 2025-11-13  
**問題**: Flutter 應用收到 GoMyPay `paymentUrl` 後沒有跳轉到支付頁面

---

## 🐛 問題診斷

### 問題描述

用戶在 Android 模擬器測試 GoMyPay 支付整合時發現：

1. ✅ 後端正確返回了 `paymentUrl` 和 `requiresRedirect: true`
2. ✅ Flutter 應用成功接收到支付響應
3. ❌ **但是應用直接跳轉到 `/booking-success`，沒有顯示 GoMyPay 支付頁面**

### 日誌分析

```
I/flutter: [BookingService] 完整響應內容: {
  "success":true,
  "data":{
    "bookingId":"7dce69dd-d2c0-441b-888a-3f4a1df237dd",
    "paymentId":"411c7123-032f-45f0-b2b1-c2fd206f7465",
    "transactionId":"gomypay_1762990386429_wudv4tryh",
    "paymentUrl":"https://n.gomypay.asia/TestShuntClass.aspx?...",
    "requiresRedirect":true  ← ✅ 後端正確返回
  }
}
I/flutter: [BookingService] 支付成功
I/flutter: [BookingService] 返回數據: {..., paymentUrl: https://..., requiresRedirect: true}
I/flutter: 🔀 [Router] 路由重定向: /booking-success/...  ← ❌ 直接跳轉，沒有檢查 paymentUrl
```

### 根本原因

#### 問題 1: `booking_provider.dart` 沒有返回支付結果

**文件**: `mobile/lib/shared/providers/booking_provider.dart`

**問題代碼** (第 88-113 行):
```dart
Future<void> payDepositWithSupabase(String bookingId, String paymentMethod) async {
  // ...
  final result = await _bookingService.payDepositWithSupabase(bookingId, paymentMethod);
  // ❌ 沒有返回 result，導致調用方無法獲取 paymentUrl
}
```

#### 問題 2: `payment_deposit_page.dart` 沒有檢查 `paymentUrl`

**文件**: `mobile/lib/apps/customer/presentation/pages/payment_deposit_page.dart`

**問題代碼** (第 313-345 行):
```dart
void _processPayment() async {
  // ...
  await ref.read(bookingStateProvider.notifier).payDepositWithSupabase(
    bookingState.order.id,
    _selectedPaymentMethod,
  );

  // ❌ 直接跳轉到成功頁面，沒有檢查是否需要跳轉到支付頁面
  if (mounted) {
    context.pushReplacement('/booking-success/${bookingState.order.id}');
  }
}
```

---

## ✅ 修復方案

### 修復 1: `booking_provider.dart` 返回支付結果

**文件**: `mobile/lib/shared/providers/booking_provider.dart`

**修改前**:
```dart
Future<void> payDepositWithSupabase(String bookingId, String paymentMethod) async {
  state = const BookingStateLoading();

  try {
    final result = await _bookingService.payDepositWithSupabase(bookingId, paymentMethod);
    // ...
  } catch (e) {
    state = BookingStateError(e.toString());
  }
}
```

**修改後**:
```dart
/// 支付訂金（使用 Supabase API）
/// 
/// 返回支付結果，包含 paymentUrl（如果需要跳轉）
Future<Map<String, dynamic>> payDepositWithSupabase(String bookingId, String paymentMethod) async {
  state = const BookingStateLoading();

  try {
    final result = await _bookingService.payDepositWithSupabase(bookingId, paymentMethod);
    
    // ... (更新訂單狀態)
    
    // ✅ 返回支付結果（包含 paymentUrl 等資訊）
    return result;
  } catch (e) {
    state = BookingStateError(e.toString());
    rethrow;  // ✅ 重新拋出異常，讓調用方處理
  }
}
```

**變更說明**:
- 返回類型從 `Future<void>` 改為 `Future<Map<String, dynamic>>`
- 返回 `result`，包含 `paymentUrl`、`requiresRedirect` 等資訊
- 異常處理改為 `rethrow`，讓調用方可以捕獲異常

---

### 修復 2: `payment_deposit_page.dart` 檢查並處理 `paymentUrl`

**文件**: `mobile/lib/apps/customer/presentation/pages/payment_deposit_page.dart`

**修改 1: 添加 import**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/booking_provider.dart';
import '../../../../core/services/payment/payment_models.dart';  // ✅ 新增
```

**修改 2: 更新支付處理邏輯**

**修改前**:
```dart
void _processPayment() async {
  setState(() => _isProcessing = true);

  try {
    // 創建預約訂單
    final bookingRequest = ref.read(bookingRequestProvider);
    await ref.read(bookingStateProvider.notifier).createBookingWithSupabase(
      bookingRequest.toBookingRequest(),
    );

    final bookingState = ref.read(bookingStateProvider);
    if (bookingState is BookingStateSuccess) {
      // 使用 Supabase API 處理支付
      await ref.read(bookingStateProvider.notifier).payDepositWithSupabase(
        bookingState.order.id,
        _selectedPaymentMethod,
      );

      // ❌ 直接跳轉，沒有檢查 paymentUrl
      if (mounted) {
        context.pushReplacement('/booking-success/${bookingState.order.id}');
      }
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
    // 創建預約訂單（使用 Supabase API）
    final bookingRequest = ref.read(bookingRequestProvider);
    await ref.read(bookingStateProvider.notifier).createBookingWithSupabase(
      bookingRequest.toBookingRequest(),
    );

    final bookingState = ref.read(bookingStateProvider);
    if (bookingState is BookingStateSuccess) {
      // ✅ 獲取支付結果
      final paymentResult = await ref.read(bookingStateProvider.notifier).payDepositWithSupabase(
        bookingState.order.id,
        _selectedPaymentMethod,
      );

      if (!mounted) return;

      // ✅ 檢查是否需要跳轉到支付頁面（GoMyPay 等第三方支付）
      if (paymentResult['requiresRedirect'] == true && paymentResult['paymentUrl'] != null) {
        // 跳轉到 GoMyPay 支付頁面
        debugPrint('[PaymentDeposit] 跳轉到支付頁面: ${paymentResult['paymentUrl']}');
        await context.push('/payment-webview', extra: {
          'url': paymentResult['paymentUrl'],
          'bookingId': bookingState.order.id,
          'paymentType': PaymentType.deposit,
        });
        
        // 支付完成後，跳轉到預約成功頁面
        if (mounted) {
          context.pushReplacement('/booking-success/${bookingState.order.id}');
        }
      } else {
        // 自動支付（Mock）或不需要跳轉，直接導航到預約成功頁面
        debugPrint('[PaymentDeposit] 自動支付完成，跳轉到預約成功頁面');
        context.pushReplacement('/booking-success/${bookingState.order.id}');
      }
    } else if (bookingState is BookingStateError) {
      _showErrorDialog(bookingState.message);
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

**變更說明**:
1. ✅ 獲取 `paymentResult` 而不是忽略返回值
2. ✅ 檢查 `requiresRedirect` 和 `paymentUrl`
3. ✅ 如果需要跳轉，使用 `context.push('/payment-webview')` 跳轉到 GoMyPay 頁面
4. ✅ 如果不需要跳轉（Mock 支付），直接跳轉到成功頁面
5. ✅ 添加日誌輸出，方便調試

---

## 📊 修復後的流程

### GoMyPay 支付流程（正式環境）

```
用戶點擊「確認支付」
    ↓
創建訂單 (createBookingWithSupabase)
    ↓
調用支付 API (payDepositWithSupabase)
    ↓
後端返回 {paymentUrl, requiresRedirect: true}
    ↓
✅ 檢查 requiresRedirect == true
    ↓
✅ 跳轉到 /payment-webview
    ↓
顯示 GoMyPay 支付頁面（WebView）
    ↓
用戶輸入信用卡資訊並完成支付
    ↓
GoMyPay 回調到後端 /api/payment/gomypay/callback
    ↓
後端更新訂單狀態為 paid_deposit
    ↓
WebView 檢測到支付完成（URL 變化）
    ↓
跳轉到 /booking-success
```

### Mock 支付流程（測試環境）

```
用戶點擊「確認支付」
    ↓
創建訂單 (createBookingWithSupabase)
    ↓
調用支付 API (payDepositWithSupabase)
    ↓
後端返回 {requiresRedirect: false}
    ↓
✅ 檢查 requiresRedirect == false
    ↓
✅ 直接跳轉到 /booking-success
```

---

## 🧪 測試步驟

### 步驟 1: 確認 Railway 環境變數

在 Railway Dashboard 中確認：
```
PAYMENT_PROVIDER=gomypay  ← ⭐ 必須設置
```

### 步驟 2: 重新構建 Flutter 應用

```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 步驟 3: 測試支付流程

1. 登入應用
2. 選擇車型套餐
3. 填寫預約資訊
4. 點擊「確認支付」
5. **預期**: 應用跳轉到 GoMyPay WebView 頁面
6. **預期**: 顯示 GoMyPay 支付表單
7. 輸入測試信用卡資訊：
   - 卡號: `4111111111111111`
   - 有效期: `12/25`
   - CVV: `123`
8. 完成支付
9. **預期**: 跳轉到「預約成功」頁面

### 步驟 4: 檢查日誌

**預期日誌輸出**:
```
I/flutter: [BookingService] 完整響應內容: {..., paymentUrl: https://..., requiresRedirect: true}
I/flutter: [PaymentDeposit] 跳轉到支付頁面: https://n.gomypay.asia/TestShuntClass.aspx?...
I/flutter: 🔀 [Router] 路由重定向: /payment-webview
I/flutter: 📱 WebView URL 變化: https://n.gomypay.asia/...
I/flutter: ✅ 支付成功
I/flutter: 🔀 [Router] 路由重定向: /booking-success/...
```

---

## 📝 相關文件

### 修改的文件

1. **`mobile/lib/shared/providers/booking_provider.dart`**
   - 修改 `payDepositWithSupabase` 方法返回類型
   - 返回支付結果而不是 void

2. **`mobile/lib/apps/customer/presentation/pages/payment_deposit_page.dart`**
   - 添加 `payment_models.dart` import
   - 更新 `_processPayment` 方法邏輯
   - 檢查 `requiresRedirect` 和 `paymentUrl`
   - 根據支付類型選擇跳轉路徑

### 未修改的文件（已正確實現）

3. **`mobile/lib/apps/customer/presentation/pages/payment_webview_page.dart`**
   - GoMyPay WebView 頁面
   - 功能完整，無需修改

4. **`mobile/lib/apps/customer/presentation/router/customer_router.dart`**
   - `/payment-webview` 路由已配置
   - 無需修改

5. **`backend/src/routes/bookings.ts`**
   - 支付端點已正確返回 `paymentUrl`
   - 無需修改

---

## ✅ 驗證清單

- [ ] `booking_provider.dart` 返回支付結果
- [ ] `payment_deposit_page.dart` 檢查 `requiresRedirect`
- [ ] `payment_deposit_page.dart` 導入 `payment_models.dart`
- [ ] Railway 環境變數 `PAYMENT_PROVIDER=gomypay`
- [ ] Flutter 應用重新構建
- [ ] 測試 GoMyPay 支付流程
- [ ] 確認跳轉到 WebView 頁面
- [ ] 確認顯示 GoMyPay 支付表單
- [ ] 確認支付完成後跳轉到成功頁面

---

**最後更新**: 2025-11-13

