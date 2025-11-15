# Flutter 支付 WebView 路由修復

**日期**: 2025-11-15  
**Commit**: 待提交

---

## 🐛 問題描述

### 問題 1: Flutter 客戶端路由錯誤 - `/payment-webview` 路由不存在

**錯誤訊息**:
```
GoException: no routes for location: /payment-webview
```

**問題描述**:
- ✅ 價格配置已經正確從生產環境獲取（成功獲取 4 個套餐）
- ✅ 訂單創建成功（訂單 ID: `7ab6e44c-978e-4d90-b315-da223d782bee`）
- ✅ 支付訂金 API 調用成功，返回 GOMYPAY 支付 URL
- ❌ 客戶端嘗試跳轉到 `/payment-webview` 路由時失敗

**客戶端日誌**:
```
I/flutter (31854): [PaymentDeposit] 跳轉到支付頁面: https://n.gomypay.asia/TestShuntClass.aspx?...
I/flutter (31854): 🔀 [Router] 路由重定向: /payment-webview, 認證狀態: AuthStateAuthenticated, 完成精靈: true
```

**根本原因**:
- `PaymentWebViewPage` 組件已存在於 `mobile/lib/apps/customer/presentation/pages/payment_webview_page.dart`
- `payment_deposit_page.dart` 和 `payment_balance_page.dart` 嘗試使用 `context.push('/payment-webview', extra: {...})` 跳轉
- 但 Flutter 客戶端的路由配置（`customer_router.dart`）中沒有定義 `/payment-webview` 路由

---

### 問題 2: Backend API 路由返回 404 錯誤（次要問題）

**錯誤訊息**:
訪問以下 URL 時返回 `{"success":false,"error":"Route not found"}`：
- `https://api.relaygo.pro/api/bookings` (GET)
- `https://api.relaygo.pro/api/bookings/:id/pay-deposit` (GET)

**說明**:
- ✅ POST 請求成功（`POST /api/bookings` 返回 200，`POST /api/bookings/:id/pay-deposit` 返回 200）
- ❌ GET 請求失敗（返回 404）
- **這不是錯誤，而是正常行為**
- 這些端點只接受 POST 請求，不接受 GET 請求
- GET 404 錯誤不影響核心功能

---

## ✅ 修復方案

### 修復 1: 添加 `/payment-webview` 路由

**文件**: `mobile/lib/apps/customer/presentation/router/customer_router.dart`

**修改內容**:

#### 1. 添加導入
```dart
import '../pages/payment_webview_page.dart';
import '../../../../core/services/payment/payment_models.dart';
```

#### 2. 添加路由配置
在 `routes` 數組中添加（在 `/payment-deposit` 路由之後）：

```dart
GoRoute(
  path: '/payment-webview',
  name: 'payment-webview',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    final paymentUrl = extra?['url'] as String? ?? '';
    final bookingId = extra?['bookingId'] as String? ?? '';
    final paymentType = extra?['paymentType'] as PaymentType? ?? PaymentType.deposit;

    return PaymentWebViewPage(
      paymentUrl: paymentUrl,
      bookingId: bookingId,
      paymentType: paymentType,
    );
  },
),
```

**關鍵變更**:
1. ✅ 添加 `PaymentWebViewPage` 導入
2. ✅ 添加 `PaymentType` 導入（用於區分訂金和尾款支付）
3. ✅ 添加 `/payment-webview` 路由配置
4. ✅ 從 `state.extra` 接收路由參數（`url`, `bookingId`, `paymentType`）

---

## 📝 相關文件

### 修改的文件

1. **`mobile/lib/apps/customer/presentation/router/customer_router.dart`**
   - 添加 `/payment-webview` 路由配置
   - 添加必要的導入

### 已存在的文件（未修改）

2. **`mobile/lib/apps/customer/presentation/pages/payment_webview_page.dart`**
   - GOMYPAY 支付 WebView 頁面
   - 功能完整，無需修改

3. **`mobile/lib/apps/customer/presentation/pages/payment_deposit_page.dart`**
   - 支付訂金頁面
   - 已正確調用 `/payment-webview` 路由（之前的 commit 已修復）

4. **`mobile/lib/apps/customer/presentation/pages/payment_balance_page.dart`**
   - 支付尾款頁面
   - 已正確調用 `/payment-webview` 路由（之前的 commit 已修復）

---

## 🔍 PaymentWebViewPage 功能說明

**文件**: `mobile/lib/apps/customer/presentation/pages/payment_webview_page.dart`

**主要功能**:
1. ✅ 顯示 GOMYPAY 支付頁面（WebView）
2. ✅ 監聽支付結果（通過 URL 變化）
3. ✅ 處理支付完成後的跳轉
4. ✅ 處理用戶取消支付
5. ✅ 顯示載入指示器
6. ✅ 錯誤處理和重試機制

**支付結果處理**:
- 監聽 URL 變化，檢測 `ridebooking://payment-result` Deep Link
- 解析 GOMYPAY 返回參數：
  - `result`: 1=成功, 0=失敗
  - `ret_msg`: 返回訊息
  - `OrderID`: GOMYPAY 訂單號
  - `e_orderno`: 我們的訂單編號
  - `AvCode`: 授權碼

**導航邏輯**:
```dart
if (result == '1') {
  // 支付成功
  if (widget.paymentType == PaymentType.deposit) {
    context.pushReplacement('/booking-success/${widget.bookingId}');
  } else {
    context.pushReplacement('/booking-complete/${widget.bookingId}');
  }
} else {
  // 支付失敗
  _showErrorDialog(message, canRetry: true);
}
```

---

## 📋 測試步驟

### 1. 重新編譯 Flutter App
```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 2. 測試支付訂金流程

1. 創建訂單並進入支付訂金頁面
2. 點擊「確認支付」按鈕
3. **預期結果**: 應該跳轉到 GOMYPAY 支付頁面（WebView）
4. **預期日誌**:
   ```
   [PaymentDeposit] 跳轉到支付頁面: https://n.gomypay.asia/...
   ```
5. **驗證**: WebView 顯示 GOMYPAY 支付表單

### 3. 測試支付尾款流程

1. 確保訂單狀態為 `trip_ended`（行程已結束）
2. 進入訂單詳情頁面
3. 點擊「立即支付尾款」按鈕
4. **預期結果**: 應該跳轉到 GOMYPAY 支付頁面（WebView）
5. **預期日誌**:
   ```
   [PaymentBalance] 跳轉到支付頁面: https://n.gomypay.asia/...
   ```
6. **驗證**: WebView 顯示 GOMYPAY 支付表單

---

## 🎯 總結

### 修復的問題
1. ✅ **Flutter 客戶端路由錯誤** - 添加 `/payment-webview` 路由配置
2. ℹ️ **Backend GET 404 錯誤** - 正常行為，不影響功能

### 修改的文件
1. ✅ `mobile/lib/apps/customer/presentation/router/customer_router.dart` - 添加路由配置

### 預期修復後的行為
1. 用戶點擊「確認支付」按鈕
2. 調用 Backend API 創建支付訂單（✅ 已正常工作）
3. Backend 返回 GOMYPAY 支付 URL（✅ 已正常工作）
4. Flutter 客戶端跳轉到 `/payment-webview` 路由（✅ 本次修復）
5. WebView 顯示 GOMYPAY 支付頁面（✅ 本次修復）
6. 用戶完成支付後，返回 App 並跳轉到成功頁面

### 參考 Commit
- `b5d4d44` - Flutter payment flow not redirecting to GoMyPay WebView（支付訂金跳轉修復）
- `3700573` - 修復 Flutter 客戶端 API 連接和支付跳轉問題（最終版本）

