# Flutter 客戶端 API 連接修復

## 問題描述

### 問題 1: 價格配置 API 超時
```
[PricingService] API URL: http://10.0.2.2:3001/api/pricing/packages
[PricingService] API 請求超時，使用模擬資料
```

**原因**:
- Flutter App 嘗試訪問 `http://10.0.2.2:3001/api/pricing/packages`
- Backend 實際運行在 port **8080**（Railway 部署）
- Port 不匹配導致連接超時

### 問題 2: 支付訂金後沒有跳轉到 GOMYPAY
**原因**: 已在之前的提交中修復（commit: 125b130）

---

## 修復內容

### 修復 1: 更新 `pricing_service.dart` 的 API URL

**文件**: `mobile/lib/core/services/pricing_service.dart`

**修改前**:
```dart
// Backend API 基礎 URL
// Android 模擬器使用 10.0.2.2 訪問主機的 localhost
// Backend 運行在 port 3000
static const String _baseUrl = 'http://10.0.2.2:3000/api';
```

**修改後**:
```dart
// Backend API 基礎 URL
// 開發環境：Android 模擬器使用 10.0.2.2 訪問主機的 localhost (port 8080)
// 生產環境：使用 Railway 部署的 Backend API
static const String _baseUrl = kDebugMode
    ? 'http://10.0.2.2:8080/api'  // 開發環境（本地 Backend）
    : 'https://api.relaygo.pro/api';  // 生產環境（Railway Backend）
```

**關鍵變更**:
1. 修改開發環境 port 從 **3000** 改為 **8080**
2. 添加生產環境配置（使用 Railway 部署的 Backend）
3. 使用 `kDebugMode` 自動切換環境

---

### 修復 2: 更新 `booking_service.dart` 的 API URL

**文件**: `mobile/lib/core/services/booking_service.dart`

**修改前**:
```dart
// Backend API 基礎 URL
// Android 模擬器使用 10.0.2.2 訪問主機的 localhost
// Backend API 運行在 3000 端口，web-admin 運行在 3001 端口
static const String _baseUrl = 'http://10.0.2.2:3000/api';
```

**修改後**:
```dart
// Backend API 基礎 URL
// 開發環境：Android 模擬器使用 10.0.2.2 訪問主機的 localhost (port 8080)
// 生產環境：使用 Railway 部署的 Backend API
static const String _baseUrl = kDebugMode
    ? 'http://10.0.2.2:8080/api'  // 開發環境（本地 Backend）
    : 'https://api.relaygo.pro/api';  // 生產環境（Railway Backend）
```

**關鍵變更**:
1. 修改開發環境 port 從 **3000** 改為 **8080**
2. 添加生產環境配置（使用 Railway 部署的 Backend）
3. 使用 `kDebugMode` 自動切換環境

---

## Backend 配置確認

### Backend 運行狀態
```
✅ Server is running on port 8080
   Health check: http://localhost:8080/health
```

### Backend API 端點
- ✅ `POST /api/bookings` - 創建訂單
- ✅ `POST /api/bookings/:id/pay-deposit` - 支付訂金
- ✅ `GET /api/pricing/packages` - 獲取價格套餐
- ✅ `POST /api/booking-flow/bookings/:id/accept` - 司機確認接單

### Backend 部署
- **本地開發**: `http://localhost:8080`
- **Railway 生產**: `https://api.relaygo.pro` (relaygo-backend-production.up.railway.app)

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

#### 開發環境（Debug 模式）
1. 確保本地 Backend 運行在 port 8080
2. 啟動 Flutter App（Debug 模式）
3. 進入選擇方案頁面
4. **預期結果**: 應該從 `http://10.0.2.2:8080/api/pricing/packages` 獲取價格配置
5. **預期日誌**:
   ```
   [PricingService] 開始獲取價格配置
   [PricingService] API URL: http://10.0.2.2:8080/api/pricing/packages
   [PricingService] 成功獲取價格配置
   ```

#### 生產環境（Release 模式）
1. 編譯 Release 版本：
   ```bash
   flutter build apk --flavor customer --target lib/apps/customer/main_customer.dart
   ```
2. 安裝並啟動 App
3. 進入選擇方案頁面
4. **預期結果**: 應該從 `https://api.relaygo.pro/api/pricing/packages` 獲取價格配置

### 3. 測試支付流程

#### 測試 GOMYPAY 支付
1. 確保 Backend 環境變數：
   - `PAYMENT_PROVIDER=gomypay`
   - `GOMYPAY_TEST_MODE=true`（測試模式）
2. 創建訂單並支付
3. **預期結果**: 應該跳轉到 GOMYPAY 支付頁面（WebView）
4. **預期日誌**:
   ```
   [PaymentDeposit] 跳轉到支付頁面: https://n.gomypay.asia/...
   ```

#### 測試 Mock 支付
1. 確保 Backend 環境變數：
   - `PAYMENT_PROVIDER=mock`（或未設置）
2. 創建訂單並支付
3. **預期結果**: 應該直接跳轉到預約成功頁面
4. **預期日誌**:
   ```
   [PaymentDeposit] 自動支付完成，跳轉到預約成功頁面
   ```

---

## 環境配置說明

### 開發環境（Debug 模式）
- **Backend URL**: `http://10.0.2.2:8080/api`
- **用途**: 本地開發和測試
- **要求**: 本地 Backend 必須運行在 port 8080

### 生產環境（Release 模式）
- **Backend URL**: `https://api.relaygo.pro/api`
- **用途**: 正式發布的 App
- **要求**: Railway Backend 必須正常運行

### 如何切換環境
Flutter 會自動根據編譯模式切換：
- **Debug 模式**: `flutter run` → 使用本地 Backend
- **Release 模式**: `flutter build apk` → 使用 Railway Backend

---

## 總結

### 修改的文件
1. ✅ `mobile/lib/core/services/pricing_service.dart` - 更新 API URL
2. ✅ `mobile/lib/core/services/booking_service.dart` - 更新 API URL

### 修復的問題
1. ✅ 價格配置 API 超時問題（port 不匹配）
2. ✅ 支付訂金跳轉問題（已在之前修復）
3. ✅ 添加生產環境配置（自動切換）

### 下一步
1. 重新編譯並測試 Flutter App
2. 驗證價格配置 API 是否正常
3. 驗證支付流程是否正常（訂金和尾款）

