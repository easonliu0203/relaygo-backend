# Android 模擬器網路連接修復說明

## 🎯 問題描述

在 Android 模擬器上測試支付流程時，出現網路連接錯誤：

```
Exception: 創建預約失敗: ClientException with SocketException: 
Connection refused (OS Error: Connection refused, errno = 111), 
address = localhost, port = 50156, 
uri=http://localhost:3001/api/bookings
```

## ✅ 已修復

### 修改的文件

1. **`mobile/lib/core/services/pricing_service.dart`** (第 55-57 行)
   ```dart
   // 修改前
   static const String _baseUrl = 'http://localhost:3001/api';
   
   // 修改後
   // Android 模擬器使用 10.0.2.2 訪問主機的 localhost
   static const String _baseUrl = 'http://10.0.2.2:3001/api';
   ```

2. **`mobile/lib/core/services/booking_service.dart`** (已經正確配置)
   ```dart
   // Android 模擬器使用 10.0.2.2 訪問主機的 localhost
   static const String _baseUrl = 'http://10.0.2.2:3001/api';
   ```

### 新增的文件

1. **`mobile/docs/Android模擬器網路配置指南.md`**
   - 詳細的網路配置說明
   - 常見問題排除
   - 最佳實踐建議

2. **`mobile/docs/支付流程測試指南.md`**
   - 完整的測試步驟
   - 測試檢查清單
   - 問題排除指南

3. **`docs/20250101_1630_10_Android模擬器支付流程網路連接問題修復.md`**
   - 詳細的開發歷程文件
   - 問題診斷過程
   - 修復方案和經驗總結

## 🔑 關鍵知識點

### Android 模擬器網路地址

| 地址 | 指向 | 用途 |
|------|------|------|
| `localhost` / `127.0.0.1` | 模擬器本身 | ❌ 無法訪問開發機器 |
| `10.0.2.2` | 開發機器的 localhost | ✅ 訪問開發機器服務 |
| `10.0.2.15` | 模擬器自己的 IP | - |

### 為什麼需要 10.0.2.2？

Android 模擬器運行在虛擬機中，有自己的網路堆疊。當你在模擬器中訪問 `localhost` 時，它指向的是模擬器本身，而不是你的開發機器。

要從模擬器訪問開發機器上運行的服務（如 web-admin 後端），必須使用特殊的 IP 地址 `10.0.2.2`。

## 🚀 快速開始

### 1. 確認修復已應用

```bash
# 檢查代碼是否已更新
grep -n "10.0.2.2" mobile/lib/core/services/pricing_service.dart
grep -n "10.0.2.2" mobile/lib/core/services/booking_service.dart
```

### 2. 啟動後端服務

```bash
cd web-admin
npm run dev
# 確認看到：✓ Ready on http://localhost:3001
```

### 3. 重新建置應用

```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 4. 測試支付流程

1. 登入應用
2. 選擇車型套餐
3. 創建預約訂單
4. 支付訂金
5. 確認訂單狀態更新

## 📚 相關文檔

- **配置指南**: `mobile/docs/Android模擬器網路配置指南.md`
- **測試指南**: `mobile/docs/支付流程測試指南.md`
- **開發歷程**: `docs/20250101_1630_10_Android模擬器支付流程網路連接問題修復.md`

## ⚠️ 注意事項

### iOS 模擬器

iOS 模擬器可以直接使用 `localhost`，不需要使用特殊 IP。

如果需要支援多平台，建議使用：

```dart
import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001/api';
    } else {
      return 'http://localhost:3001/api';
    }
  }
}
```

### 真實設備

在真實設備上測試時，需要：
1. 確保設備和開發機器在同一網路
2. 使用開發機器的實際 IP 地址（如 `192.168.1.100`）
3. 確保防火牆允許連接

### 生產環境

在生產環境中，應該使用實際的 API 域名：

```dart
static const String _baseUrl = 'https://api.yourdomain.com/api';
```

## 🐛 故障排除

### 仍然出現 Connection refused

1. 確認代碼已更新並重新編譯
2. 確認後端服務正在運行
3. 檢查防火牆設定
4. 重啟模擬器

### 後端服務無法訪問

```bash
# 測試後端服務
curl http://localhost:3001/api/health

# 檢查端口是否被佔用
netstat -ano | findstr :3001
```

### 模擬器網路問題

```bash
# 測試模擬器網路
adb shell ping 10.0.2.2
adb shell curl http://10.0.2.2:3001/api/health
```

## ✅ 驗證修復

運行以下命令驗證修復：

```bash
# 1. 檢查代碼
grep -r "localhost:3001" mobile/lib/core/services/
# 應該沒有結果

# 2. 檢查正確配置
grep -r "10.0.2.2:3001" mobile/lib/core/services/
# 應該找到 booking_service.dart 和 pricing_service.dart

# 3. 測試後端
curl http://localhost:3001/api/health
# 應該返回 {"status":"ok",...}

# 4. 運行應用
cd mobile
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

## 📞 需要協助？

如果遇到問題：

1. 查看詳細的配置指南：`mobile/docs/Android模擬器網路配置指南.md`
2. 查看測試指南：`mobile/docs/支付流程測試指南.md`
3. 查看開發歷程文件了解詳細的診斷過程
4. 檢查 Flutter 和後端的日誌輸出

---

**修復日期**: 2025-01-01  
**版本**: 1.0.0  
**狀態**: ✅ 已修復並驗證
