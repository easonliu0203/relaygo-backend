# Flutter 客戶端 API 連接修復（最終版本）

## 問題描述

### 問題 1: 價格配置 API 無法獲取正確資料
```
[PricingService] API URL: http://10.0.2.2:8080/api/pricing/packages
[PricingService] API 請求超時，使用模擬資料
```

**原因**:
- Flutter App 配置為訪問本地 Backend (`http://10.0.2.2:8080/api`)
- Backend 已經部署到 Railway，不再使用本地開發環境
- 應該訪問生產環境的 Backend API: `https://api.relaygo.pro/api`

### 問題 2: 支付尾款後沒有跳轉到 GOMYPAY
**原因**:
- `payment_balance_page.dart` 沒有檢查支付結果的 `requiresRedirect` 和 `paymentUrl`
- 直接跳轉到訂單完成頁面，跳過了 GOMYPAY 支付流程

---

## 修復內容

### 修復 1: 更新 API URL 為生產環境

#### 1.1 `pricing_service.dart`

**文件**: `mobile/lib/core/services/pricing_service.dart`

**修改前**:
```dart
// Backend API 基礎 URL
// 開發環境：Android 模擬器使用 10.0.2.2 訪問主機的 localhost (port 8080)
// 生產環境：使用 Railway 部署的 Backend API
static const String _baseUrl = kDebugMode
    ? 'http://10.0.2.2:8080/api'  // 開發環境（本地 Backend）
    : 'https://api.relaygo.pro/api';  // 生產環境（Railway Backend）
```

**修改後**:
```dart
// Backend API 基礎 URL
// 使用生產環境的 Railway Backend API
// 即使在 Debug 模式下也使用生產環境，因為本地不再運行 Backend
static const String _baseUrl = 'https://api.relaygo.pro/api';
```

**關鍵變更**:
1. ✅ 移除本地開發環境配置
2. ✅ 統一使用生產環境 API (`https://api.relaygo.pro/api`)
3. ✅ 即使在 Debug 模式下也使用生產環境

---

#### 1.2 `booking_service.dart`

**文件**: `mobile/lib/core/services/booking_service.dart`

**修改前**:
```dart
// Backend API 基礎 URL
// 開發環境：Android 模擬器使用 10.0.2.2 訪問主機的 localhost (port 8080)
// 生產環境：使用 Railway 部署的 Backend API
static const String _baseUrl = kDebugMode
    ? 'http://10.0.2.2:8080/api'  // 開發環境（本地 Backend）
    : 'https://api.relaygo.pro/api';  // 生產環境（Railway Backend）
```

**修改後**:
```dart
// Backend API 基礎 URL
// 使用生產環境的 Railway Backend API
// 即使在 Debug 模式下也使用生產環境，因為本地不再運行 Backend
static const String _baseUrl = 'https://api.relaygo.pro/api';
```

**關鍵變更**:
1. ✅ 移除本地開發環境配置
2. ✅ 統一使用生產環境 API (`https://api.relaygo.pro/api`)
3. ✅ 即使在 Debug 模式下也使用生產環境

---

### 修復 2: 支付尾款 GOMYPAY 跳轉

**文件**: `mobile/lib/apps/customer/presentation/pages/payment_balance_page.dart`

**修改前**:
```dart
void _processPayment() async {
  setState(() => _isProcessing = true);

  try {
    // 調用支付尾款 API
    await _bookingService.payBalance(
      widget.bookingId,
      _selectedPaymentMethod,
    );

    // 支付成功，導航到訂單完成頁面
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
        'paymentType': PaymentType.balance,
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
    _showErrorDialog('支付處理失敗：$e');
  } finally {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}
```

**關鍵變更**:
1. ✅ 接收 `payBalance` 的返回值 (`paymentResult`)
2. ✅ 檢查 `requiresRedirect` 和 `paymentUrl`
3. ✅ 如果需要跳轉，導航到 `/payment-webview` 並傳遞支付 URL
4. ✅ 如果不需要跳轉（Mock 支付），直接跳轉到訂單完成頁面
5. ✅ 添加 `PaymentType.balance` 參數

---

## Backend 配置確認

### Backend 運行狀態
```
✅ Railway 生產環境運行中
   Health check: https://api.relaygo.pro/health
```

### Backend API 端點
- ✅ `POST /api/bookings` - 創建訂單
- ✅ `POST /api/bookings/:id/pay-deposit` - 支付訂金
- ✅ `POST /api/booking-flow/bookings/:id/pay-balance` - 支付尾款
- ✅ `GET /api/pricing/packages` - 獲取價格套餐
- ✅ `POST /api/booking-flow/bookings/:id/accept` - 司機確認接單

### Backend 部署
- **生產環境**: `https://api.relaygo.pro` (Railway: relaygo-backend-production.up.railway.app)
- **管理後台**: `https://admin.relaygo.pro` (價格配置管理)

---

## 測試步驟

### 1. 重新編譯 Flutter App
```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 2. 測試價格配置 API

1. 啟動 Flutter App
2. 進入選擇方案頁面
3. **預期結果**: 應該從 `https://api.relaygo.pro/api/pricing/packages` 獲取價格配置
4. **預期日誌**:
   ```
   [PricingService] 開始獲取價格配置
   [PricingService] API URL: https://api.relaygo.pro/api/pricing/packages
   [PricingService] 成功獲取價格配置
   ```
5. **驗證**: 顯示的價格應該與管理後台 (https://admin.relaygo.pro/settings/pricing) 一致

### 3. 測試支付訂金流程

#### 測試 GOMYPAY 支付
1. 確保 Backend 環境變數：
   - `PAYMENT_PROVIDER=gomypay`
   - `GOMYPAY_TEST_MODE=true`（測試模式）
2. 創建訂單並進入支付訂金頁面
3. 點擊「確認支付」按鈕
4. **預期結果**: 應該跳轉到 GOMYPAY 支付頁面（WebView）
5. **預期日誌**:
   ```
   [PaymentDeposit] 跳轉到支付頁面: https://n.gomypay.asia/...
   ```
6. **驗證**: WebView 顯示 GOMYPAY 支付表單

#### 測試 Mock 支付
1. 確保 Backend 環境變數：
   - `PAYMENT_PROVIDER=mock`（或未設置）
2. 創建訂單並進入支付訂金頁面
3. 點擊「確認支付」按鈕
4. **預期結果**: 應該直接跳轉到預約成功頁面
5. **預期日誌**:
   ```
   [PaymentDeposit] 自動支付完成，跳轉到預約成功頁面
   ```

### 4. 測試支付尾款流程

#### 測試 GOMYPAY 支付
1. 確保訂單狀態為 `trip_ended`（行程已結束）
2. 進入訂單詳情頁面
3. 點擊「立即支付尾款」按鈕
4. **預期結果**: 應該跳轉到 GOMYPAY 支付頁面（WebView）
5. **預期日誌**:
   ```
   [PaymentBalance] 跳轉到支付頁面: https://n.gomypay.asia/...
   ```
6. **驗證**: WebView 顯示 GOMYPAY 支付表單

#### 測試 Mock 支付
1. 確保訂單狀態為 `trip_ended`（行程已結束）
2. 進入訂單詳情頁面
3. 點擊「立即支付尾款」按鈕
4. **預期結果**: 應該直接跳轉到訂單完成頁面
5. **預期日誌**:
   ```
   [PaymentBalance] 自動支付完成，跳轉到訂單完成頁面
   ```

---

## 環境配置說明

### 統一使用生產環境
- **Backend URL**: `https://api.relaygo.pro/api`
- **用途**: 所有環境（Debug 和 Release）都使用生產環境
- **原因**: 本地不再運行 Backend，統一使用 Railway 部署的生產環境

### 價格配置管理
- **管理後台**: https://admin.relaygo.pro/settings/pricing
- **資料來源**: Supabase `vehicle_pricing` 表
- **API 端點**: `GET /api/pricing/packages`

---

## 總結

### 修改的文件
1. ✅ `mobile/lib/core/services/pricing_service.dart` - 更新 API URL 為生產環境
2. ✅ `mobile/lib/core/services/booking_service.dart` - 更新 API URL 為生產環境
3. ✅ `mobile/lib/apps/customer/presentation/pages/payment_balance_page.dart` - 添加 GOMYPAY 跳轉邏輯

### 修復的問題
1. ✅ 價格配置 API 無法獲取正確資料（使用本地 API 而非生產環境）
2. ✅ 支付訂金跳轉問題（已在之前的 commit 修復）
3. ✅ 支付尾款沒有跳轉到 GOMYPAY（缺少跳轉邏輯）
4. ✅ 統一使用生產環境 API（移除本地開發環境配置）

### 關鍵變更
1. **API URL**: 從 `http://10.0.2.2:8080/api` 改為 `https://api.relaygo.pro/api`
2. **價格資料**: 從 Supabase 資料庫獲取（可在管理後台管理）
3. **支付流程**: 支付訂金和支付尾款都支持 GOMYPAY 跳轉

### 下一步
1. 重新編譯並測試 Flutter App
2. 驗證價格配置是否從生產環境正確獲取
3. 驗證支付訂金流程是否跳轉到 GOMYPAY
4. 驗證支付尾款流程是否跳轉到 GOMYPAY

### 參考 Commit
- `b5d4d44` - Flutter payment flow not redirecting to GoMyPay WebView（支付訂金跳轉修復）
- 本次修復基於該 commit 的實現，並擴展到支付尾款

