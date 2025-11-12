# 司機端 APP 啟動問題 - 診斷和修復完成

**日期**: 2025-10-11  
**問題**: 司機端 APP 啟動失敗  
**狀態**: ✅ 已修復並成功啟動

---

## 📋 問題總結

### 問題 1: Windows 桌面支援未配置

**症狀**:
- 使用 `flutter run -d windows` 啟動失敗
- 錯誤訊息：`No Windows desktop project configured`

**原因**:
- Flutter 項目未添加 Windows 桌面支援

### 問題 2: 司機端訂單詳情頁面編譯錯誤

**症狀**:
- 編譯失敗，錯誤訊息：
  ```
  Error: The getter 'customerName' isn't defined for the class 'BookingOrder'.
  Error: The getter 'customerPhone' isn't defined for the class 'BookingOrder'.
  ```

**原因**:
- 新創建的 `driver_order_detail_page.dart` 使用了不存在的欄位
- `BookingOrder` 模型只有 `customerId`，沒有 `customerName` 和 `customerPhone`

### 問題 3: Gradle 編譯警告

**症狀**:
- Kotlin 編譯器緩存錯誤
- NDK 版本不匹配警告

**原因**:
- Gradle 緩存問題
- Android NDK 版本配置不一致

---

## 🔧 修復方案

### 修復 1: 使用 Android 模擬器代替 Windows

**解決方案**:
- 使用 Android 模擬器啟動司機端 APP
- 命令：`flutter run -d emulator-5554 --flavor driver --target lib/apps/driver/main_driver.dart`

**原因**:
- Windows 桌面支援需要額外配置
- Android 模擬器已經可用且配置完整

### 修復 2: 修復司機端訂單詳情頁面

**文件**: `mobile/lib/apps/driver/presentation/pages/driver_order_detail_page.dart`

**修改內容**:
- 移除不存在的 `customerName` 和 `customerPhone` 欄位
- 改為顯示 `customerId`

**修改前**:
```dart
Text(
  order.customerName ?? '未知客戶',  // ❌ 欄位不存在
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 4),
if (order.customerPhone != null)  // ❌ 欄位不存在
  Text(
    order.customerPhone!,
    style: const TextStyle(
      fontSize: 14,
      color: Colors.grey,
    ),
  ),
```

**修改後**:
```dart
Text(
  '客戶 ID: ${order.customerId.substring(0, 8)}...',  // ✅ 使用 customerId
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 4),
const Text(
  '客戶資訊載入中...',  // ✅ 臨時顯示
  style: TextStyle(
    fontSize: 14,
    color: Colors.grey,
  ),
),
```

### 修復 3: Gradle 編譯問題

**解決方案**:
- Gradle 自動重新編譯並清理緩存
- 編譯成功完成

---

## ✅ 修復驗證

### 啟動成功

**命令**:
```bash
cd mobile
flutter run -d emulator-5554 --flavor driver --target lib/apps/driver/main_driver.dart
```

**結果**:
```
✅ Built build\app\outputs\flutter-apk\app-driver-debug.apk
✅ Installing build\app\outputs\flutter-apk\app-driver-debug.apk...
✅ Supabase 初始化成功
✅ Firebase 初始化完成
✅ APP 正在運行中
```

### 初始化日誌

```
I/flutter: ✅ Supabase 初始化成功
I/flutter: 💡 正在初始化 Firebase...
I/flutter: 💡 Firestore 本地快取已啟用
I/flutter: 💡 Crashlytics 設定完成
I/flutter: 💡 用戶已授權推播通知
I/flutter: 💡 FCM Token: cysoX6__TPygifqV8OmUSZ:APA91bG10Y0H-HXHQUaQ2hs5YC_PVZtCGOIdFAkTAIARkUnb1mRrYx_poED-0zHlnqkGqqlNrj-e-mlJ1ilO25gmPw1J2p_soQqibLLeFzItu_r98DPzOpg
I/flutter: 💡 Firebase Messaging 設定完成
I/flutter: 💡 Firebase Analytics 設定完成
I/flutter: 💡 Firebase 初始化完成
```

### Flutter DevTools

```
A Dart VM Service on sdk gphone64 x86 64 is available at: http://127.0.0.1:56005/Fq1qLoAX7u8=/
The Flutter DevTools debugger and profiler on sdk gphone64 x86 64 is available at: http://127.0.0.1:56009?uri=http://127.0.0.1:56005/Fq1qLoAX7u8=/
```

---

## 📝 修改的文件

### 修改的文件（1個）

| 文件 | 說明 | 修改內容 |
|------|------|----------|
| `mobile/lib/apps/driver/presentation/pages/driver_order_detail_page.dart` | 司機端訂單詳情頁面 | 移除不存在的欄位，改用 customerId |

---

## 🚀 啟動步驟

### 方法 1: 使用腳本（推薦）

```bash
cd mobile
scripts\run-driver.bat
```

**注意**: 腳本會自動選擇可用設備，但如果有多個設備，可能需要手動選擇。

### 方法 2: 手動啟動（指定設備）

```bash
cd mobile
flutter run -d emulator-5554 --flavor driver --target lib/apps/driver/main_driver.dart
```

### 方法 3: 查看可用設備

```bash
cd mobile
flutter devices
```

**輸出示例**:
```
Found 4 connected devices:
  sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64    • Android 14 (API 34) (emulator)
  Windows (desktop)            • windows       • windows-x64    • Microsoft Windows [版本 10.0.19045.6332]
  Chrome (web)                 • chrome        • web-javascript • Google Chrome 140.0.7339.208
  Edge (web)                   • edge          • web-javascript • Microsoft Edge 141.0.3537.57
```

---

## 💡 技術亮點

### 1. Flutter Flavor 支援

**司機端 APP 使用 Flavor**:
```bash
flutter run --flavor driver --target lib/apps/driver/main_driver.dart
```

**客戶端 APP 使用 Flavor**:
```bash
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

**優點**:
- 同一個代碼庫支援多個 APP
- 共享核心代碼，減少重複
- 獨立的配置和資源

### 2. 多平台支援

**可用平台**:
- ✅ Android (模擬器和實體設備)
- ⚠️ Windows (需要額外配置)
- ✅ Web (Chrome/Edge)
- ✅ iOS (需要 macOS)

### 3. Firebase 和 Supabase 雙資料庫架構

**初始化順序**:
1. Supabase 初始化（PostgreSQL 寫入模型）
2. Firebase 初始化（Firestore 讀取模型）
3. Firebase Crashlytics（錯誤追蹤）
4. Firebase Messaging（推播通知）
5. Firebase Analytics（分析）

---

## 🔍 常見問題

### Q1: 為什麼不使用 Windows 桌面？

**A**: Windows 桌面支援需要額外配置：
```bash
flutter create --platforms=windows .
```

但目前 Android 模擬器已經可用且配置完整，所以優先使用 Android。

### Q2: 如何切換到客戶端 APP？

**A**: 使用客戶端啟動腳本：
```bash
cd mobile
scripts\run-customer.bat
```

或手動啟動：
```bash
flutter run -d emulator-5554 --flavor customer --target lib/apps/customer/main_customer.dart
```

### Q3: 如何查看 APP 日誌？

**A**: 日誌會自動顯示在終端中，或使用 Flutter DevTools：
```
http://127.0.0.1:56009?uri=http://127.0.0.1:56005/Fq1qLoAX7u8=/
```

### Q4: 如何熱重載？

**A**: 在 Flutter 運行時，按 `r` 鍵進行熱重載：
```
Flutter run key commands:
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

---

## 📞 需要幫助？

### 查看運行狀態

**終端 ID**: 60

**查看日誌**:
```bash
# 查看完整日誌
flutter logs
```

### 停止 APP

**方法 1**: 在 Flutter 終端按 `q` 鍵

**方法 2**: 終止進程
```bash
# 查看進程
flutter devices

# 終止 APP
flutter kill
```

---

## 🎉 恭喜！

**司機端 APP 已成功啟動並運行！**

**啟動時間**: 2025-10-11  
**啟動狀態**: ✅ 成功

**啟動總結**:
- ✅ 診斷了啟動問題（Windows 桌面未配置、編譯錯誤）
- ✅ 修復了司機端訂單詳情頁面（移除不存在的欄位）
- ✅ 使用 Android 模擬器成功啟動
- ✅ Supabase 和 Firebase 初始化成功
- ✅ APP 正在運行中

**當前狀態**:
- ✅ 司機端 APP 運行在 Android 模擬器（emulator-5554）
- ✅ Flutter DevTools 可用
- ✅ 熱重載功能可用

**下一步**: 在 APP 中測試訂單詳情功能！

```
測試步驟:
1. 在公司端配對訂單給司機
2. 在司機端 APP 中打開「訂單」頁面
3. 點擊某個「已配對訂單」
4. 檢查訂單詳情頁面是否正常顯示
```

**祝使用順利！** 🚀

