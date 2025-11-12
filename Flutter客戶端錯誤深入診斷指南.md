# Flutter 客戶端錯誤深入診斷指南

**日期**：2025-10-08  
**問題**：`_dependents.isEmpty` 錯誤持續出現  
**狀態**：🔍 深入診斷中

---

## 📋 問題描述

### 錯誤訊息

```
'package:flutter/src/widgets/framework.dart': 
Failed assertion: line 6161 pos 14: '_dependents.isEmpty': is not true.
```

### 已執行的修復

1. ✅ 代碼已正確修改（使用 `.then()` 回調）
2. ✅ 執行了完整的清理和重建
3. ✅ 卸載並重新安裝了 App
4. ❌ 錯誤仍然出現

---

## 🔍 深入診斷步驟

### 步驟 1：獲取完整的錯誤堆棧追蹤

#### 方法 1：從 Flutter 控制台複製

1. 在錯誤發生後，查看 Flutter 控制台
2. 向上滾動找到完整的錯誤訊息
3. 複製從 `════════ Exception caught by...` 開始到結束的所有內容

**應該包含**：
```
════════ Exception caught by widgets library ═══════════════════════════════════
The following assertion was thrown while finalizing the widget tree:
'package:flutter/src/widgets/framework.dart': Failed assertion: line 6161 pos 14: '_dependents.isEmpty': is not true.

When the exception was thrown, this was the stack:
#0      Element._unmount.<anonymous closure> (package:flutter/src/widgets/framework.dart:6161:14)
#1      Element._unmount (package:flutter/src/widgets/framework.dart:6161:7)
#2      ComponentElement._unmount (package:flutter/src/widgets/framework.dart:6161:11)
#3      StatefulElement._unmount (package:flutter/src/widgets/framework.dart:6161:11)
#4      Element.unmount (package:flutter/src/widgets/framework.dart:6161:5)
... (更多堆棧追蹤)
```

#### 方法 2：使用 Flutter DevTools

1. 在 Flutter 控制台中，點擊 DevTools 連結
2. 前往「Logging」標籤
3. 找到錯誤訊息
4. 點擊展開查看完整堆棧追蹤

---

### 步驟 2：添加詳細的調試日誌

讓我修改代碼添加更多日誌來追蹤問題：

#### 修改 `order_detail_page.dart`

在 `_showCancelDialog()` 方法中添加日誌：

```dart
void _showCancelDialog(BuildContext context, WidgetRef ref, BookingOrder order) {
  debugPrint('🔍 [OrderDetailPage] _showCancelDialog called');
  debugPrint('🔍 [OrderDetailPage] Order ID: ${order.id}');
  debugPrint('🔍 [OrderDetailPage] Creating TextEditingController');
  
  final reasonController = TextEditingController();
  debugPrint('🔍 [OrderDetailPage] TextEditingController created: ${reasonController.hashCode}');

  showDialog<String?>(
    context: context,
    builder: (context) {
      debugPrint('🔍 [OrderDetailPage] Building dialog');
      return AlertDialog(
        title: const Text('取消訂單'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('確定要取消此訂單嗎？已支付的訂金將會退還。'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '取消原因',
                hintText: '請輸入取消原因（至少 5 個字元）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🔍 [OrderDetailPage] User clicked "不取消"');
              Navigator.of(context).pop(null);
            },
            child: const Text('不取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              debugPrint('🔍 [OrderDetailPage] User clicked "確認取消", reason: $reason');

              if (reason.length < 5) {
                debugPrint('🔍 [OrderDetailPage] Reason too short, showing error');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('取消原因至少需要 5 個字元')),
                );
                return;
              }

              debugPrint('🔍 [OrderDetailPage] Closing dialog with reason');
              Navigator.of(context).pop(reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('確認取消'),
          ),
        ],
      );
    },
  ).then((reason) async {
    debugPrint('🔍 [OrderDetailPage] Dialog closed, .then() callback started');
    debugPrint('🔍 [OrderDetailPage] Returned reason: $reason');
    debugPrint('🔍 [OrderDetailPage] About to dispose controller: ${reasonController.hashCode}');
    
    try {
      reasonController.dispose();
      debugPrint('🔍 [OrderDetailPage] ✅ Controller disposed successfully');
    } catch (e) {
      debugPrint('🔍 [OrderDetailPage] ❌ Error disposing controller: $e');
      debugPrint('🔍 [OrderDetailPage] ❌ Stack trace: ${StackTrace.current}');
    }

    if (reason != null && reason.isNotEmpty) {
      debugPrint('🔍 [OrderDetailPage] Starting cancel booking process');
      try {
        await ref.read(bookingStateProvider.notifier).cancelBookingWithSupabase(
          order.id,
          reason,
        );
        debugPrint('🔍 [OrderDetailPage] ✅ Booking cancelled successfully');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('訂單已取消')),
          );
        }
      } catch (e) {
        debugPrint('🔍 [OrderDetailPage] ❌ Error cancelling booking: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('取消失敗：$e')),
          );
        }
      }
    } else {
      debugPrint('🔍 [OrderDetailPage] User cancelled, no action taken');
    }
    
    debugPrint('🔍 [OrderDetailPage] .then() callback completed');
  });
  
  debugPrint('🔍 [OrderDetailPage] _showCancelDialog completed');
}
```

---

### 步驟 3：檢查是否有其他地方使用 TextEditingController

搜索整個專案中所有使用 `TextEditingController` 的地方：

```bash
# 在專案根目錄執行
grep -r "TextEditingController" mobile/lib/apps/customer/ --include="*.dart"
```

**檢查**：
- 是否有其他對話框也使用 `TextEditingController`？
- 是否有其他地方沒有正確 dispose？

---

### 步驟 4：檢查 Widget 樹

使用 Flutter DevTools 的 Widget Inspector：

1. 打開 Flutter DevTools
2. 前往「Widget Inspector」標籤
3. 在錯誤發生前後檢查 Widget 樹
4. 查看是否有 Widget 沒有正確卸載

---

### 步驟 5：檢查是否是 API 錯誤導致的

**假設**：
- 如果 API 返回錯誤（例如資料庫欄位缺少）
- 可能會導致異步操作失敗
- 進而影響 Widget 的生命週期

**驗證**：
1. 先修復資料庫結構問題（執行 SQL）
2. 重啟管理後台
3. 再次測試取消訂單功能
4. 查看錯誤是否仍然出現

---

## 🔬 可能的根本原因

### 原因 1：TextField 仍在使用 Controller

**問題**：
- 對話框關閉動畫還沒完成
- TextField 仍然持有 controller 的引用
- 但 `.then()` 回調已經執行並 dispose 了 controller

**證據**：
- 錯誤訊息：`_dependents.isEmpty`
- 這表示有其他 Widget 仍然依賴這個 Element

**解決方案**：
- 添加延遲？（不推薦）
- 檢查是否有其他地方也在使用這個 controller

---

### 原因 2：多個對話框實例

**問題**：
- 可能有多個對話框同時打開
- 或者對話框被多次創建

**驗證**：
- 檢查日誌中是否有多次「Creating TextEditingController」
- 檢查是否有多次「Dialog closed」

---

### 原因 3：API 錯誤導致的異步問題

**問題**：
- API 返回錯誤（資料庫欄位缺少）
- 異步操作失敗
- Widget 在錯誤狀態下被 dispose

**驗證**：
- 先修復資料庫問題
- 再測試是否仍然出現錯誤

---

### 原因 4：Riverpod 狀態管理問題

**問題**：
- `bookingStateProvider` 在 dispose 後仍然被使用
- 或者狀態更新在 Widget dispose 後發生

**驗證**：
- 檢查 `context.mounted` 是否正確使用
- 檢查 Provider 的生命週期

---

## 📊 診斷檢查清單

### 代碼檢查
- [x] 確認 `.then()` 回調正確使用
- [x] 確認 `dispose()` 在 `.then()` 中執行
- [ ] 檢查是否有其他地方使用 `TextEditingController`
- [ ] 檢查是否有多個對話框實例

### 日誌檢查
- [ ] 添加詳細的調試日誌
- [ ] 重新建置並運行 App
- [ ] 測試取消訂單功能
- [ ] 查看完整的日誌輸出
- [ ] 獲取完整的錯誤堆棧追蹤

### 環境檢查
- [x] 執行了 `flutter clean`
- [x] 卸載了舊的 App
- [x] 完全重新建置
- [ ] 修復資料庫結構問題
- [ ] 重啟管理後台

---

## 🎯 下一步行動

### 立即執行（優先級：高）

1. **修復資料庫結構** ⭐
   - 執行 SQL 添加缺少的欄位
   - 這可能是導致錯誤的根本原因

2. **添加詳細日誌**
   - 修改 `order_detail_page.dart` 添加日誌
   - 重新建置 App

3. **測試並收集資訊**
   - 測試取消訂單功能
   - 複製完整的日誌輸出
   - 複製完整的錯誤堆棧追蹤

---

### 如果仍然失敗

**提供以下資訊**：

1. **完整的錯誤堆棧追蹤**
   ```
   從 ════════ Exception caught by... 開始
   到結束的所有內容
   ```

2. **完整的日誌輸出**
   ```
   所有 🔍 [OrderDetailPage] 開頭的日誌
   ```

3. **確認步驟**
   - [ ] 資料庫結構已修復
   - [ ] 管理後台已重啟
   - [ ] App 已重新建置
   - [ ] 添加了詳細日誌

---

**狀態**：🔍 深入診斷中  
**下一步**：先修復資料庫，再添加日誌測試

🚀 **請先執行資料庫修復，然後我們再深入診斷 Flutter 錯誤！**

**關鍵假設**：
- 資料庫欄位缺少可能導致 API 錯誤
- API 錯誤可能影響異步操作
- 異步操作失敗可能導致 Widget 生命週期問題
- 修復資料庫後，Flutter 錯誤可能會消失

**如果修復資料庫後錯誤仍然存在**：
- 我們會添加詳細日誌
- 獲取完整的錯誤堆棧追蹤
- 進行更深入的診斷

