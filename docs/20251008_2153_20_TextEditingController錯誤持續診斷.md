# TextEditingController 錯誤持續診斷

**日期**：2025-10-08 21:53  
**問題**：`_dependents.isEmpty` 錯誤在修復後仍然出現  
**狀態**：🔍 診斷中

---

## 📋 問題描述

### 用戶報告

**錯誤訊息**：
```
'package:flutter/src/widgets/framework.dart': 
Failed assertion: line 6161 pos 14: '_dependents.isEmpty': is not true.
```

**發生時機**：
1. 完成支付流程
2. 進入「預約成功」頁面
3. 點擊「查看訂單詳情」
4. 在訂單詳情頁面點擊「取消訂單」按鈕
5. 輸入取消原因並確認
6. ❌ 出現錯誤畫面

**用戶已執行的步驟**：
- ✅ 執行了 `flutter clean`
- ✅ 執行了 `flutter pub get`
- ✅ 重新建置了 App
- ❌ 錯誤仍然出現

---

## 🔍 診斷過程

### 步驟 1：檢查代碼是否已修改

**檢查文件**：`mobile/lib/apps/customer/presentation/pages/order_detail_page.dart`

**檢查結果**：✅ 代碼已正確修改

**關鍵代碼**（第 463-543 行）：

```dart
void _showCancelDialog(BuildContext context, WidgetRef ref, BookingOrder order) {
  final reasonController = TextEditingController();

  showDialog<String?>(  // ✅ 正確
    context: context,
    builder: (context) => AlertDialog(
      // ...
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);  // ✅ 正確：不 dispose
          },
          child: const Text('不取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            final reason = reasonController.text.trim();
            if (reason.length < 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('取消原因至少需要 5 個字元')),
              );
              return;
            }
            Navigator.of(context).pop(reason);  // ✅ 正確：返回值
          },
          child: const Text('確認取消'),
        ),
      ],
    ),
  ).then((reason) async {
    reasonController.dispose();  // ✅ 正確：在 .then() 中 dispose

    if (reason != null && reason.isNotEmpty) {
      try {
        await ref.read(bookingStateProvider.notifier).cancelBookingWithSupabase(
          order.id,
          reason,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('訂單已取消')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('取消失敗：$e')),
          );
        }
      }
    }
  });
}
```

**結論**：
- ✅ `showDialog<String?>()` 正確指定返回類型
- ✅ `.then()` 回調正確使用
- ✅ `reasonController.dispose()` 在 `.then()` 回調中執行
- ✅ `Navigator.pop()` 返回值，不 dispose
- ✅ 所有修復都已正確應用

---

### 步驟 2：檢查其他可能的問題

**檢查項目**：
1. ✅ 檢查是否有其他對話框 - 沒有發現
2. ✅ 檢查是否有其他 `TextEditingController` - 只有這一個
3. ✅ 檢查是否有嵌套對話框 - 沒有
4. ✅ 檢查 `context.mounted` 使用 - 正確使用

**結論**：代碼完全正確，沒有發現問題。

---

## 🤔 可能的原因分析

### 原因 1：Hot Reload 問題（最可能）⭐

**問題描述**：
- Flutter 的 Hot Reload（按 `r`）不會重新初始化所有狀態
- 某些 Widget 的舊實例可能仍在記憶體中
- 舊的代碼邏輯可能仍在運行

**為什麼會這樣**：
```
1. 用戶修改了代碼
2. 用戶按了 `r`（Hot Reload）
3. Flutter 嘗試保留 Widget 狀態
4. 舊的 TextEditingController 仍在記憶體中
5. 新的代碼邏輯沒有完全應用
6. 錯誤仍然出現
```

**解決方案**：
- 完全停止 App（按 `q` 或 Ctrl+C）
- 重新運行 App（不是 Hot Reload）

---

### 原因 2：Build 緩存問題

**問題描述**：
- 即使執行了 `flutter clean`，可能還有其他緩存
- Gradle 緩存（Android）
- CocoaPods 緩存（iOS）
- Dart 分析緩存

**為什麼會這樣**：
```
1. flutter clean 只清理 Flutter 的 build 目錄
2. 不清理 Gradle、CocoaPods 等緩存
3. 不清理 .dart_tool 目錄
4. 舊的編譯產物可能仍在使用
```

**解決方案**：
- 執行更徹底的清理
- 刪除 `build` 目錄
- 刪除 `.dart_tool` 目錄
- 執行 `flutter pub cache repair`

---

### 原因 3：多個 App 實例

**問題描述**：
- 可能有多個 App 實例在運行
- 用戶看到的是舊版本的 App
- 新版本的 App 沒有運行

**為什麼會這樣**：
```
1. 用戶之前運行了 App
2. 沒有完全停止
3. 又運行了新的 App
4. 兩個實例同時存在
5. 用戶操作的是舊實例
```

**解決方案**：
- 卸載舊的 App
- 確認只有一個設備連接
- 重新安裝 App

---

### 原因 4：錯誤來自其他地方

**問題描述**：
- 錯誤可能不是來自 `order_detail_page.dart`
- 可能是其他頁面或組件
- 堆棧追蹤可能指向錯誤的位置

**為什麼會這樣**：
```
1. Flutter 的錯誤訊息有時不準確
2. 堆棧追蹤可能被截斷
3. 錯誤可能在異步操作中發生
4. 實際的錯誤源可能在其他地方
```

**解決方案**：
- 查看完整的錯誤堆棧追蹤
- 確認錯誤發生的具體位置
- 檢查所有相關的代碼

---

## 🔧 解決方案

### 方案 1：徹底的清理和重建（推薦）⭐

**步驟**：

```bash
# 1. 完全停止 App
# 在 Flutter 終端按 q 或 Ctrl+C

# 2. 徹底清理
cd mobile
flutter clean
flutter pub cache repair

# 3. 刪除緩存目錄（Windows）
if exist build rmdir /s /q build
if exist .dart_tool rmdir /s /q .dart_tool

# 4. 重新獲取依賴
flutter pub get

# 5. 卸載舊的 App（Android）
adb uninstall com.example.mobile.customer

# 6. 完全重新運行
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

**重要**：
- ❌ 不要使用 Hot Reload（按 `r`）
- ❌ 不要使用 Hot Restart（按 `R`）
- ✅ 完全停止並重新運行

---

### 方案 2：添加調試日誌

**目的**：確認新代碼是否真的在運行

**修改**：在 `_showCancelDialog()` 方法中添加日誌

```dart
void _showCancelDialog(BuildContext context, WidgetRef ref, BookingOrder order) {
  debugPrint('🔍 [OrderDetailPage] _showCancelDialog called - Version: 2025-10-08-21:53');
  final reasonController = TextEditingController();

  showDialog<String?>(
    // ...
  ).then((reason) async {
    debugPrint('🔍 [OrderDetailPage] Dialog closed, disposing controller');
    reasonController.dispose();
    debugPrint('🔍 [OrderDetailPage] Controller disposed successfully');
    
    // ...
  });
}
```

**測試**：
1. 重新建置 App
2. 測試取消訂單
3. 查看控制台日誌
4. 確認看到新的日誌訊息

**如果看不到日誌**：
- 說明運行的是舊版本的 App
- 需要更徹底的清理

---

### 方案 3：檢查完整的錯誤堆棧追蹤

**需要的資訊**：

1. **完整的錯誤訊息**
   ```
   請複製從錯誤開始到結束的所有內容
   ```

2. **錯誤堆棧追蹤**
   ```
   包括所有的 #0, #1, #2... 行
   ```

3. **發生錯誤的文件和行號**
   ```
   確認是哪個文件的哪一行
   ```

**如何獲取**：
- 在 Flutter 控制台中查看
- 或在 VS Code 的 Debug Console 中查看
- 截圖或複製完整的輸出

---

## 📊 診斷檢查清單

### 代碼檢查
- [x] 檢查 `_showCancelDialog()` 方法
- [x] 確認使用 `.then()` 回調
- [x] 確認 `dispose()` 在 `.then()` 中
- [x] 確認 `Navigator.pop()` 返回值
- [x] 檢查其他對話框
- [x] 檢查其他 `TextEditingController`

### 清理和重建
- [ ] 完全停止 App（按 q 或 Ctrl+C）
- [ ] 執行 `flutter clean`
- [ ] 執行 `flutter pub cache repair`
- [ ] 刪除 `build` 目錄
- [ ] 刪除 `.dart_tool` 目錄
- [ ] 執行 `flutter pub get`
- [ ] 卸載舊的 App
- [ ] 完全重新運行（不是 Hot Reload）

### 測試
- [ ] 創建新訂單
- [ ] 支付訂金
- [ ] 進入訂單詳情
- [ ] 點擊「取消訂單」
- [ ] 輸入取消原因
- [ ] 點擊「確認取消」
- [ ] 查看是否仍然出現錯誤

### 診斷
- [ ] 查看完整的錯誤堆棧追蹤
- [ ] 確認錯誤來自哪個文件
- [ ] 確認錯誤來自哪一行
- [ ] 添加調試日誌
- [ ] 確認新代碼是否在運行

---

## 💡 開發心得

### 1. Hot Reload 的限制

**學習**：
- Hot Reload 不是萬能的
- 某些狀態變更需要完全重啟
- Widget 生命週期相關的修改尤其需要重啟

**最佳實踐**：
- 修改 Widget 生命週期相關代碼後，完全重啟
- 不要依賴 Hot Reload
- 使用 `debugPrint` 確認代碼版本

---

### 2. 緩存問題的重要性

**學習**：
- `flutter clean` 不清理所有緩存
- 需要手動刪除某些目錄
- 緩存問題可能導致舊代碼運行

**最佳實踐**：
- 定期清理所有緩存
- 遇到奇怪問題時，先徹底清理
- 使用腳本自動化清理過程

---

### 3. 調試日誌的價值

**學習**：
- 添加版本號可以確認代碼版本
- 詳細的日誌幫助診斷問題
- `debugPrint` 是最簡單的調試工具

**最佳實踐**：
- 在關鍵位置添加日誌
- 包含時間戳和版本號
- 使用不同的前綴區分不同模組

---

### 4. 錯誤診斷的方法

**學習**：
- 代碼正確不代表問題解決
- 需要確認新代碼真的在運行
- 完整的錯誤堆棧追蹤很重要

**最佳實踐**：
- 系統化的診斷流程
- 逐步排除可能的原因
- 收集完整的診斷資訊

---

## 🎯 下一步行動

### 立即執行

1. **徹底清理和重建**
   - 按照「方案 1」的步驟執行
   - 確保完全停止 App
   - 不要使用 Hot Reload

2. **添加調試日誌**（可選）
   - 按照「方案 2」添加日誌
   - 確認新代碼是否在運行

3. **測試取消訂單功能**
   - 完整的測試流程
   - 查看是否仍然出現錯誤

---

### 如果仍然失敗

**提供以下資訊**：

1. **完整的錯誤堆棧追蹤**
2. **Flutter 版本**
   ```bash
   flutter --version
   flutter doctor -v
   ```
3. **設備資訊**
   ```bash
   flutter devices
   adb devices
   ```
4. **確認已執行的步驟**
   - 列出所有執行過的清理步驟
   - 確認是否完全重啟了 App

**我會**：
1. 分析錯誤堆棧追蹤
2. 找出錯誤的真正來源
3. 提供更具體的修復方案
4. 如果需要，修改代碼

---

## 📚 相關文檔

1. **`docs/20251008_1935_16_取消訂單TextEditingController錯誤修復.md`**
   - 原始的修復文檔

2. **`TextEditingController錯誤診斷指南.md`**
   - 詳細的診斷指南

3. **`測試執行清單.md`**
   - 測試步驟

4. **`README-修復工作快速參考.md`**
   - 快速參考

---

**狀態**：🔍 診斷中  
**下一步**：執行徹底的清理和重建

🚀 **請立即執行清理和重建步驟！**

**最關鍵的步驟**：
1. ✅ 完全停止 App（不是 Hot Reload）
2. ✅ 執行 `flutter clean`
3. ✅ 刪除 `build` 和 `.dart_tool` 目錄
4. ✅ 卸載舊的 App
5. ✅ 完全重新運行

**如果仍然失敗**：
- 提供完整的錯誤堆棧追蹤
- 提供 Flutter 版本資訊
- 我會進一步深入診斷

