# Android 模擬器網路配置指南

## 📱 Android 模擬器網路說明

### 網路地址對應關係

在 Android 模擬器中，網路地址有特殊的對應關係：

| 地址 | 指向 | 說明 |
|------|------|------|
| `localhost` 或 `127.0.0.1` | 模擬器本身 | ❌ 無法訪問開發機器 |
| `10.0.2.2` | 開發機器的 localhost | ✅ 正確的配置 |
| `10.0.2.3` | 開發機器的第一個 DNS 伺服器 | - |
| `10.0.2.15` | 模擬器本身 | - |

### 為什麼需要使用 10.0.2.2？

Android 模擬器運行在虛擬機中，有自己的網路堆疊。當你在模擬器中訪問 `localhost` 時，它指向的是模擬器本身，而不是你的開發機器。

要從模擬器訪問開發機器上運行的服務（如 web-admin 後端），必須使用特殊的 IP 地址 `10.0.2.2`。

## 🛠️ 配置方法

### 1. Flutter 應用配置

在 Flutter 應用中，所有 HTTP 請求的 baseUrl 都應該使用 `10.0.2.2`：

**正確配置**：
```dart
// ✅ 正確：使用 10.0.2.2
static const String _baseUrl = 'http://10.0.2.2:3001/api';
```

**錯誤配置**：
```dart
// ❌ 錯誤：使用 localhost
static const String _baseUrl = 'http://localhost:3001/api';
```

### 2. 已修復的文件

以下文件已經正確配置：

1. **`mobile/lib/core/services/booking_service.dart`**
   ```dart
   // Android 模擬器使用 10.0.2.2 訪問主機的 localhost
   static const String _baseUrl = 'http://10.0.2.2:3001/api';
   ```

2. **`mobile/lib/core/services/pricing_service.dart`**
   ```dart
   // Android 模擬器使用 10.0.2.2 訪問主機的 localhost
   static const String _baseUrl = 'http://10.0.2.2:3001/api';
   ```

### 3. 環境變數配置（可選）

如果使用環境變數，可以在 `.env` 文件中配置：

```env
# Android 模擬器配置
API_BASE_URL=http://10.0.2.2:3001/api
WS_BASE_URL=ws://10.0.2.2:3001
```

然後在代碼中讀取：
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3001/api';
```

## 🧪 測試方法

### 1. 確認後端服務運行

在開發機器上確認 web-admin 服務正在運行：

```bash
# 進入 web-admin 目錄
cd web-admin

# 啟動開發服務器
npm run dev

# 應該看到：
# ✓ Ready on http://localhost:3001
```

### 2. 測試網路連接

在 Android 模擬器中測試連接：

```bash
# 在模擬器的終端中執行（需要 adb）
adb shell

# 測試連接
ping 10.0.2.2

# 測試 HTTP 連接
curl http://10.0.2.2:3001/api/health
```

### 3. 查看應用日誌

在 Flutter 應用中查看網路請求日誌：

```dart
debugPrint('API Request: $_baseUrl/bookings');
```

## 🐛 常見問題排除

### 問題 1：Connection refused

**錯誤訊息**：
```
SocketException: Connection refused (OS Error: Connection refused, errno = 111)
```

**可能原因**：
1. ❌ 使用了 `localhost` 而不是 `10.0.2.2`
2. ❌ 後端服務沒有運行
3. ❌ 端口號錯誤

**解決方法**：
1. 檢查代碼中的 baseUrl 是否使用 `10.0.2.2`
2. 確認後端服務在 `localhost:3001` 運行
3. 確認端口號正確

### 問題 2：Network unreachable

**錯誤訊息**：
```
SocketException: Network is unreachable
```

**可能原因**：
1. ❌ 模擬器沒有網路連接
2. ❌ 防火牆阻擋連接

**解決方法**：
1. 重啟 Android 模擬器
2. 檢查防火牆設定
3. 確認模擬器可以訪問外網

### 問題 3：Timeout

**錯誤訊息**：
```
TimeoutException: Connection timeout
```

**可能原因**：
1. ❌ 後端服務響應太慢
2. ❌ 網路延遲過高

**解決方法**：
1. 增加超時時間
2. 檢查後端服務性能
3. 使用更快的模擬器（如 x86_64）

## 📝 最佳實踐

### 1. 使用常數管理 URL

```dart
class ApiConfig {
  // 根據平台自動選擇 URL
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android 模擬器
      return 'http://10.0.2.2:3001/api';
    } else if (Platform.isIOS) {
      // iOS 模擬器可以使用 localhost
      return 'http://localhost:3001/api';
    } else {
      // 其他平台
      return 'http://localhost:3001/api';
    }
  }
}
```

### 2. 添加錯誤處理

```dart
try {
  final response = await http.get(Uri.parse('$_baseUrl/bookings'));
  // 處理回應
} on SocketException catch (e) {
  debugPrint('網路連接失敗: $e');
  // 顯示友好的錯誤訊息
  throw Exception('無法連接到伺服器，請檢查網路連接');
} catch (e) {
  debugPrint('請求失敗: $e');
  throw Exception('請求失敗: $e');
}
```

### 3. 添加日誌記錄

```dart
Future<Map<String, dynamic>> createBooking(BookingRequest request) async {
  debugPrint('[BookingService] 創建預約請求');
  debugPrint('[BookingService] URL: $_baseUrl/bookings');
  debugPrint('[BookingService] 請求資料: ${json.encode(requestBody)}');
  
  try {
    final response = await http.post(/* ... */);
    debugPrint('[BookingService] 回應狀態: ${response.statusCode}');
    debugPrint('[BookingService] 回應內容: ${response.body}');
    // ...
  } catch (e) {
    debugPrint('[BookingService] 錯誤: $e');
    throw e;
  }
}
```

## 🔧 開發環境設定

### 1. 確保後端服務運行

```bash
# 檢查服務是否運行
curl http://localhost:3001/api/health

# 應該返回：
# {"status":"ok","timestamp":"2025-01-01T12:00:00.000Z"}
```

### 2. 檢查防火牆設定

確保防火牆允許 3001 端口的連接：

**Windows**：
```powershell
# 添加防火牆規則
netsh advfirewall firewall add rule name="Web Admin" dir=in action=allow protocol=TCP localport=3001
```

**macOS/Linux**：
```bash
# 檢查端口是否開放
sudo lsof -i :3001
```

### 3. 使用 Charles Proxy 調試（可選）

如果需要查看詳細的網路請求，可以使用 Charles Proxy：

1. 在開發機器上啟動 Charles Proxy
2. 配置 Android 模擬器使用代理
3. 查看所有 HTTP/HTTPS 請求

## 📚 參考資料

- [Android Emulator Networking](https://developer.android.com/studio/run/emulator-networking)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Debugging Network Issues](https://flutter.dev/docs/development/data-and-backend/networking)

## ✅ 檢查清單

在部署到 Android 模擬器之前，請確認：

- [ ] 所有 API baseUrl 使用 `10.0.2.2` 而不是 `localhost`
- [ ] 後端服務在 `localhost:3001` 正常運行
- [ ] 防火牆允許 3001 端口連接
- [ ] Android 模擬器有網路連接
- [ ] 添加了適當的錯誤處理和日誌記錄
- [ ] 測試了完整的 API 請求流程

---

**最後更新**: 2025-01-01  
**版本**: 1.0.0
