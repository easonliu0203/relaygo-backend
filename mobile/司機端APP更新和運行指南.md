# 司機端 APP 更新和運行指南

**日期**: 2025-10-10  
**版本**: 1.0  
**適用於**: Relay GO 司機端應用程式

---

## 📋 更新內容

### 本次更新 (2025-10-10)

**功能**: 司機端接單頁面訂單顯示功能

**修改的文件**:
1. `mobile/lib/core/services/booking_service.dart` - 新增司機訂單查詢方法
2. `mobile/lib/apps/driver/providers/driver_booking_provider.dart` - 新建 Riverpod Provider
3. `mobile/lib/apps/driver/presentation/pages/driver_order_page.dart` - 重寫訂單列表頁面

**新增功能**:
- ✅ 司機可以查看所有訂單
- ✅ 司機可以查看進行中的訂單
- ✅ 訂單列表支持即時更新
- ✅ 支持下拉刷新
- ✅ 顯示訂單詳細資訊（狀態、路線、金額等）

---

## 🚀 快速開始（推薦方式）

### 方法 1: 使用批次腳本（最簡單）

**步驟**:

1. **打開終端機（命令提示字元）**
   ```
   按 Win + R
   輸入: cmd
   按 Enter
   ```

2. **切換到 mobile 目錄**
   ```bash
   cd d:\repo\mobile
   ```

3. **運行司機端應用**
   ```bash
   scripts\run-driver.bat
   ```

**就這麼簡單！** 腳本會自動啟動司機端應用。

---

## 🔧 手動更新和運行（詳細步驟）

### 方法 2: 手動執行 Flutter 指令

如果您想更好地控制更新過程，可以使用以下手動步驟：

#### 步驟 1: 打開終端機

```
按 Win + R
輸入: cmd
按 Enter
```

#### 步驟 2: 切換到 mobile 目錄

```bash
cd d:\repo\mobile
```

#### 步驟 3: 清理緩存（可選但推薦）

```bash
flutter clean
```

**說明**: 清理之前的編譯緩存，確保使用最新的代碼。

**預期輸出**:
```
Deleting build...
Deleting .dart_tool...
Deleting .flutter-plugins...
Deleting .flutter-plugins-dependencies...
```

#### 步驟 4: 獲取依賴

```bash
flutter pub get
```

**說明**: 下載和更新所有 Flutter 套件依賴。

**預期輸出**:
```
Running "flutter pub get" in mobile...
Resolving dependencies...
Got dependencies!
```

#### 步驟 5: 運行司機端應用

```bash
flutter run --flavor driver --target lib/apps/driver/main_driver.dart
```

**說明**:
- `--flavor driver`: 指定編譯司機端版本
- `--target lib/apps/driver/main_driver.dart`: 指定司機端的入口文件

**預期輸出**:
```
Launching lib/apps/driver/main_driver.dart on sdk gphone64 arm64 in debug mode...
Running Gradle task 'assembleDriverDebug'...
✓ Built build\app\outputs\flutter-apk\app-driver-debug.apk.
Installing build\app\outputs\flutter-apk\app-driver-debug.apk...
Waiting for sdk gphone64 arm64 to report its views...
Syncing files to device sdk gphone64 arm64...
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

An Observatory debugger and profiler on sdk gphone64 arm64 is available at: http://127.0.0.1:xxxxx/
The Flutter DevTools debugger and profiler on sdk gphone64 arm64 is available at: http://127.0.0.1:xxxxx/
```

---

## 📱 確認應用已啟動

### 在模擬器/實體機上

1. **檢查應用圖標**
   - 應用名稱: "Relay GO 司機端"
   - 圖標顏色: 綠色

2. **登入測試帳號**
   - Email: `driver@test.com`
   - Password: `Test1234!`

3. **查看訂單頁面**
   - 點擊底部導航欄的「訂單」圖標
   - 應該看到兩個分頁：「進行中」和「所有訂單」

---

## 🧪 測試新功能

### 測試步驟

#### 1. 在公司端配對司機

**打開公司端**:
```bash
# 在另一個終端機視窗
cd d:\repo\web-admin
npm run dev
```

**訪問**: http://localhost:3001/orders/pending

**操作**:
1. 找到一個未分配司機的訂單
2. 點擊「手動派單」按鈕
3. 選擇測試司機（driver@test.com）
4. 點擊「選擇」確認

#### 2. 在司機端查看訂單

**等待同步**:
- 等待 30 秒（Cron Job 同步時間）
- 或在司機端下拉刷新

**預期結果**:
- ✅ 「進行中」分頁顯示已配對的訂單
- ✅ 訂單卡片顯示：
  - 訂單狀態（綠色標籤：「已配對」）
  - 預約時間
  - 訂單 ID
  - 上車地點（綠色圖標）
  - 目的地（紅色圖標）
  - 預估費用

#### 3. 測試下拉刷新

**操作**:
1. 在訂單列表頁面
2. 向下拉動頁面
3. 釋放手指

**預期結果**:
- ✅ 顯示載入指示器
- ✅ 訂單列表更新

---

## 🔥 熱重載（開發時使用）

### 什麼是熱重載？

熱重載允許您在不重新啟動應用的情況下查看代碼更改。

### 如何使用？

**在終端機中按鍵**:
- `r` - 熱重載（保留應用狀態）
- `R` - 熱重啟（重置應用狀態）
- `q` - 退出應用

**示例**:
```
修改代碼 → 保存文件 → 在終端機按 'r' → 查看更改
```

---

## 🛠️ 常見問題排除

### 問題 1: 找不到 Flutter 指令

**錯誤訊息**:
```
'flutter' 不是內部或外部命令，也不是可執行的程式或批次檔。
```

**解決方案**:
1. 確認 Flutter 已安裝
2. 檢查環境變數是否設置正確
3. 重新打開終端機

**檢查 Flutter 安裝**:
```bash
flutter --version
```

### 問題 2: 模擬器未啟動

**錯誤訊息**:
```
No devices found
```

**解決方案**:

**方法 A: 使用 Android Studio 啟動模擬器**
1. 打開 Android Studio
2. 點擊 "Device Manager"
3. 選擇一個模擬器並點擊 "Play"

**方法 B: 使用指令啟動模擬器**
```bash
# 列出可用的模擬器
emulator -list-avds

# 啟動模擬器（替換 <模擬器名稱>）
emulator -avd <模擬器名稱>
```

### 問題 3: 編譯錯誤

**錯誤訊息**:
```
Error: ... is not defined
```

**解決方案**:
```bash
# 清理並重新獲取依賴
flutter clean
flutter pub get

# 重新運行
flutter run --flavor driver --target lib/apps/driver/main_driver.dart
```

### 問題 4: 訂單列表是空的

**可能原因**:
1. 沒有配對司機的訂單
2. Firestore 同步延遲
3. 司機帳號不正確

**解決方案**:
1. 在公司端配對司機
2. 等待 30 秒或下拉刷新
3. 確認登入的是正確的司機帳號

### 問題 5: 應用閃退

**解決方案**:
```bash
# 查看錯誤日誌
flutter logs

# 或在終端機中查看即時日誌
# 應用運行時會自動顯示日誌
```

---

## 📝 完整指令參考

### 基本指令

```bash
# 切換到 mobile 目錄
cd d:\repo\mobile

# 清理緩存
flutter clean

# 獲取依賴
flutter pub get

# 運行司機端（使用腳本）
scripts\run-driver.bat

# 運行司機端（手動）
flutter run --flavor driver --target lib/apps/driver/main_driver.dart

# 運行客戶端（使用腳本）
scripts\run-customer.bat

# 運行客戶端（手動）
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 進階指令

```bash
# 查看可用設備
flutter devices

# 指定設備運行
flutter run --flavor driver --target lib/apps/driver/main_driver.dart -d <設備ID>

# 編譯 Release 版本
flutter build apk --flavor driver --target lib/apps/driver/main_driver.dart

# 查看日誌
flutter logs

# 分析代碼
flutter analyze

# 運行測試
flutter test
```

---

## 🎯 快速參考卡

### 最常用的指令

| 操作 | 指令 |
|------|------|
| 切換目錄 | `cd d:\repo\mobile` |
| 運行司機端 | `scripts\run-driver.bat` |
| 運行客戶端 | `scripts\run-customer.bat` |
| 清理緩存 | `flutter clean` |
| 獲取依賴 | `flutter pub get` |
| 熱重載 | 按 `r` |
| 熱重啟 | 按 `R` |
| 退出應用 | 按 `q` |

### 測試帳號

| 角色 | Email | Password |
|------|-------|----------|
| 司機 | driver@test.com | Test1234! |
| 客戶 | customer@test.com | Test1234! |

---

## 📚 相關文檔

- `docs/20251010_0600_33_司機端接單頁面訂單顯示修復.md` - 本次更新的詳細說明
- `docs/20251010_0530_32_訂單狀態同步問題診斷報告.md` - 訂單同步問題診斷
- `DEVELOPER_GUIDE.md` - 開發者指南
- `README.md` - 專案說明

---

## 💡 提示

### 開發時的最佳實踐

1. **使用熱重載**: 修改 UI 代碼後按 `r` 即可查看更改
2. **定期清理**: 遇到奇怪問題時先執行 `flutter clean`
3. **查看日誌**: 應用運行時終端機會顯示即時日誌
4. **使用腳本**: 使用 `run-driver.bat` 腳本更方便

### 測試時的注意事項

1. **等待同步**: 配對司機後等待 30 秒讓 Firestore 同步
2. **下拉刷新**: 如果訂單沒有顯示，嘗試下拉刷新
3. **檢查帳號**: 確認登入的是正確的司機帳號
4. **查看日誌**: 如果有問題，查看終端機的錯誤訊息

---

**更新完成！** 🎉

如有任何問題，請參考「常見問題排除」章節或查看相關文檔。

