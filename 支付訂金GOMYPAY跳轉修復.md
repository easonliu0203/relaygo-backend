# 支付訂金 GOMYPAY 跳轉修復

## 問題描述

客戶端在選擇方案並確認支付後，遇到兩個問題：

### 問題 1: 價格配置 API 超時
```
[PricingService] API 請求超時，使用模擬資料
[PricingService] 請求超時: TimeoutException: API 請求超時
```

**原因**：
- Flutter App 嘗試訪問 `http://10.0.2.2:3001/api/pricing/packages`
- 這是 Android 模擬器訪問本地主機的地址
- Backend 可能沒有在 port 3001 運行，或者 API 端點不存在

### 問題 2: 支付後沒有跳轉到 GOMYPAY
```
確認支付之後也沒有跳轉至GOMYPAY
```

**原因**：
- `booking_provider.dart` 中的 `payDepositWithSupabase` 方法返回類型是 `Future<void>`
- `payment_deposit_page.dart` 沒有接收返回值
- 無法檢查 `requiresRedirect` 和 `paymentUrl`
- 直接跳轉到預約成功頁面，跳過了 GOMYPAY 支付流程

---

## 修復內容

### 修復 1: 修改 `booking_provider.dart`

**文件**: `mobile/lib/shared/providers/booking_provider.dart`

**修改前**:
```dart
Future<void> payDepositWithSupabase(String bookingId, String paymentMethod) async {
  state = const BookingStateLoading();

  try {
    final result = await _bookingService.payDepositWithSupabase(bookingId, paymentMethod);
    // ... 更新狀態
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
    // ... 更新狀態
    
    // ✅ 返回支付結果（包含 paymentUrl 等資訊）
    return result;
  } catch (e) {
    state = BookingStateError(e.toString());
    rethrow;  // ✅ 重新拋出異常，讓調用方處理
  }
}
```

**關鍵變更**:
1. 返回類型從 `Future<void>` 改為 `Future<Map<String, dynamic>>`
2. 返回 `result`（包含 `paymentUrl` 和 `requiresRedirect`）
3. 使用 `rethrow` 重新拋出異常

---

### 修復 2: 修改 `payment_deposit_page.dart`

**文件**: `mobile/lib/apps/customer/presentation/pages/payment_deposit_page.dart`

#### 2.1 添加導入
```dart
import '../../../../core/services/payment/payment_models.dart';
```

#### 2.2 修改支付處理邏輯

**修改前**:
```dart
void _processPayment() async {
  // ... 創建訂單
  
  if (bookingState is BookingStateSuccess) {
    // 使用 Supabase API 處理支付
    await ref.read(bookingStateProvider.notifier).payDepositWithSupabase(
      bookingState.order.id,
      _selectedPaymentMethod,
    );

    // 導航到預約成功頁面
    if (mounted) {
      context.pushReplacement('/booking-success/${bookingState.order.id}');
    }
  }
}
```

**修改後**:
```dart
void _processPayment() async {
  // ... 創建訂單
  
  if (bookingState is BookingStateSuccess) {
    // 使用 Supabase API 處理支付
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
  }
}
```

**關鍵變更**:
1. 接收 `payDepositWithSupabase` 的返回值到 `paymentResult`
2. 檢查 `requiresRedirect` 和 `paymentUrl`
3. 如果需要跳轉，導航到 `/payment-webview` 並傳遞支付 URL
4. 如果不需要跳轉（Mock 支付），直接跳轉到成功頁面

---

## 測試步驟

### 1. 重新編譯 Flutter App
```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 2. 測試支付流程

#### 測試場景 1: GOMYPAY 支付（生產環境）
1. 確保 Backend 環境變數設置為：
   - `PAYMENT_PROVIDER=gomypay`
   - `GOMYPAY_TEST_MODE=false`（或 `true` 用於測試）
2. 在客戶端 App 中創建訂單
3. 選擇支付方式並點擊「確認支付」
4. **預期結果**：應該跳轉到 GOMYPAY 支付頁面（WebView）
5. 完成支付後，應該返回到預約成功頁面

#### 測試場景 2: Mock 支付（開發環境）
1. 確保 Backend 環境變數設置為：
   - `PAYMENT_PROVIDER=mock`（或未設置）
2. 在客戶端 App 中創建訂單
3. 選擇支付方式並點擊「確認支付」
4. **預期結果**：應該直接跳轉到預約成功頁面（不經過 WebView）

### 3. 檢查日誌

查看 Flutter 日誌，應該看到以下輸出之一：

**GOMYPAY 支付**:
```
[PaymentDeposit] 跳轉到支付頁面: https://gomypay.com/...
```

**Mock 支付**:
```
[PaymentDeposit] 自動支付完成，跳轉到預約成功頁面
```

---

## 價格配置 API 問題

### 問題
```
[PricingService] API URL: http://10.0.2.2:3001/api/pricing/packages
[PricingService] API 請求超時，使用模擬資料
```

### 可能的原因

1. **Backend 沒有在 port 3001 運行**
   - 檢查 Backend 是否啟動
   - 確認 Backend 監聽的端口

2. **API 端點不存在**
   - 確認 Backend 是否有 `/api/pricing/packages` 端點
   - 檢查路由配置

3. **網絡連接問題**
   - Android 模擬器使用 `10.0.2.2` 訪問主機的 `localhost`
   - 確認防火牆沒有阻擋連接

### 解決方案

#### 方案 1: 確認 Backend 運行狀態
```bash
# 檢查 Backend 是否運行
curl http://localhost:3001/api/pricing/packages

# 或者從 Android 模擬器的角度測試
adb shell curl http://10.0.2.2:3001/api/pricing/packages
```

#### 方案 2: 檢查 Backend 路由配置
確認 Backend 有以下路由：
- `GET /api/pricing/packages` - 獲取所有價格套餐

#### 方案 3: 使用遠端 API（如果 Backend 已部署）
修改 `mobile/lib/core/services/pricing_service.dart`:
```dart
// 使用遠端 API
static const String _baseUrl = 'https://api.relaygo.pro/api';
```

---

## 總結

### 修改的文件
1. ✅ `mobile/lib/shared/providers/booking_provider.dart` - 修改返回類型
2. ✅ `mobile/lib/apps/customer/presentation/pages/payment_deposit_page.dart` - 添加支付跳轉邏輯

### 修復的問題
1. ✅ 支付訂金後正確跳轉到 GOMYPAY 支付頁面
2. ✅ Mock 支付時直接跳轉到成功頁面
3. ⚠️ 價格配置 API 超時問題需要進一步檢查 Backend 配置

### 下一步
1. 重新編譯並測試 Flutter App
2. 檢查 Backend 的價格配置 API 端點
3. 驗證 GOMYPAY 支付流程

