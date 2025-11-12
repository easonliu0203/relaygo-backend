# BookingStatus color 屬性錯誤修復

**日期**：2025-10-06 22:54  
**編號**：10  
**主旨**：修復客戶端 App 無法訪問 BookingStatus.color 屬性的錯誤

---

## 📋 問題描述

### 症狀
客戶端 App 顯示以下錯誤：
```
NoSuchMethodError: Class 'BookingStatus' has no instance getter 'color'.
Receiver: Instance of 'BookingStatus'
Tried calling: color
See also: http://docs.flutter.dev/testing/errors
```

### 錯誤截圖

客戶端顯示紅色錯誤畫面：
```
NoSuchMethodError: Class 'BookingStatus' has no instance getter 'color'.
Receiver: Instance of 'BookingStatus'
Tried calling: color
```

### 背景資訊
- ✅ 所有 Firestore 同步問題已修復（GeoPoint、Timestamp、整數類型）
- ✅ 訂單資料已成功同步到 Firestore
- ✅ 客戶端可以讀取訂單資料
- ❌ 在顯示訂單時嘗試訪問 `BookingStatus.color` 屬性失敗

---

## 🔍 問題診斷過程

### 1. 檢查 BookingStatus 定義

**檔案**：`mobile/lib/core/models/booking_order.dart`

**BookingStatus enum 定義**（第 9-24 行）：
```dart
/// 訂單狀態枚舉
enum BookingStatus {
  @JsonValue('pending')
  pending,        // 待配對
  
  @JsonValue('matched')
  matched,        // 已配對
  
  @JsonValue('inProgress')
  inProgress,     // 進行中
  
  @JsonValue('completed')
  completed,      // 已完成
  
  @JsonValue('cancelled')
  cancelled,      // 已取消
}
```

**BookingStatusExtension 定義**（第 27-57 行）：
```dart
/// 訂單狀態擴展方法
extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return '待配對';
      case BookingStatus.matched:
        return '已配對';
      case BookingStatus.inProgress:
        return '進行中';
      case BookingStatus.completed:
        return '已完成';
      case BookingStatus.cancelled:
        return '已取消';
    }
  }

  Color get color {  // ✅ color getter 存在
    switch (this) {
      case BookingStatus.pending:
        return const Color(0xFFFF9800); // 橙色
      case BookingStatus.matched:
        return const Color(0xFF2196F3); // 藍色
      case BookingStatus.inProgress:
        return const Color(0xFF4CAF50); // 綠色
      case BookingStatus.completed:
        return const Color(0xFF9E9E9E); // 灰色
      case BookingStatus.cancelled:
        return const Color(0xFFF44336); // 紅色
    }
  }
}
```

**發現**：
- ✅ `BookingStatus` enum 定義正確
- ✅ `BookingStatusExtension` 定義正確
- ✅ `color` getter 存在（第 43-56 行）
- ✅ `Color` 已通過 `flutter/material.dart` 導入（第 2 行）

**結論**：`BookingStatus` 和 extension 定義都沒有問題。

---

### 2. 查找調用位置

**搜索結果**：找到 3 個頁面調用 `order.status.color`：

#### 頁面 1：`order_detail_page.dart` ✅
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/booking_order.dart';  // ✅ 有導入
import '../../../../shared/providers/booking_provider.dart';
```

**調用位置**（第 101、110、129 行）：
```dart
color: order.status.color.withOpacity(0.1),
color: order.status.color,
color: order.status.color,
```

**狀態**：✅ 正常（有導入 `booking_order.dart`）

---

#### 頁面 2：`order_list_page.dart` ✅
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/booking_order.dart';  // ✅ 有導入
import '../../../../shared/providers/booking_provider.dart';
```

**調用位置**（第 146、149、157 行）：
```dart
color: order.status.color.withOpacity(0.1),
color: order.status.color.withOpacity(0.3),
color: order.status.color,
```

**狀態**：✅ 正常（有導入 `booking_order.dart`）

---

#### 頁面 3：`booking_success_page.dart` ❌ 問題頁面

**原始 imports**（修復前）：
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/booking_provider.dart';
// ❌ 缺少 booking_order.dart 的導入
```

**調用位置**（第 250、258、277 行）：
```dart
color: order.status.color,           // ❌ 無法訪問 extension
color: order.status.color,           // ❌ 無法訪問 extension
valueColor: AlwaysStoppedAnimation<Color>(order.status.color),  // ❌ 無法訪問 extension
```

**方法定義問題**（第 238 行）：
```dart
Widget _buildStatusCard(order) {  // ❌ 沒有類型聲明
  ...
  color: order.status.color,  // ❌ Dart 無法識別 order.status 的類型
  ...
}
```

**狀態**：❌ 錯誤（缺少導入 + 缺少類型聲明）

---

### 3. 根本原因

**問題 1：缺少 import**
- `booking_success_page.dart` 沒有導入 `booking_order.dart`
- 因此無法訪問 `BookingStatusExtension`

**問題 2：缺少類型聲明**
- `_buildStatusCard(order)` 方法的參數沒有類型聲明
- Dart 無法推斷 `order.status` 的類型
- 因此無法應用 `BookingStatusExtension`

**為什麼其他頁面沒有問題？**
- `order_detail_page.dart` 和 `order_list_page.dart` 都有導入 `booking_order.dart`
- 它們的方法參數都有明確的類型聲明：`Widget _buildOrderCard(BookingOrder order)`

---

## 🔧 修復方案

### 修復 1：添加 import

**檔案**：`mobile/lib/apps/customer/presentation/pages/booking_success_page.dart`

#### 修復前（錯誤）❌

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/booking_provider.dart';
```

---

#### 修復後（正確）✅

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/booking_order.dart';  // ✅ 添加導入
import '../../../../shared/providers/booking_provider.dart';
```

**關鍵變更**：
- ✅ 添加 `import '../../../../core/models/booking_order.dart';`
- ✅ 使 `BookingStatusExtension` 可用

---

### 修復 2：添加類型聲明

**檔案**：`mobile/lib/apps/customer/presentation/pages/booking_success_page.dart`

#### 修復前（錯誤）❌

```dart
Widget _buildStatusCard(order) {  // ❌ 沒有類型聲明
  return Card(
    elevation: 2,
    color: Colors.orange[50],
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                color: order.status.color,  // ❌ 無法訪問 extension
              ),
              ...
            ],
          ),
          ...
        ],
      ),
    ),
  );
}
```

---

#### 修復後（正確）✅

```dart
Widget _buildStatusCard(BookingOrder order) {  // ✅ 添加類型聲明
  return Card(
    elevation: 2,
    color: Colors.orange[50],
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                color: order.status.color,  // ✅ 可以訪問 extension
              ),
              ...
            ],
          ),
          ...
        ],
      ),
    ),
  );
}
```

**關鍵變更**：
- ✅ 將 `order` 改為 `BookingOrder order`
- ✅ Dart 可以識別 `order.status` 的類型為 `BookingStatus`
- ✅ 可以應用 `BookingStatusExtension`

---

### 修復 3：修復其他方法

**同樣的問題**：`_buildOrderInfoCard` 方法也沒有類型聲明

#### 修復前（錯誤）❌

```dart
Widget _buildOrderInfoCard(order) {  // ❌ 沒有類型聲明
  return Card(
    ...
  );
}
```

---

#### 修復後（正確）✅

```dart
Widget _buildOrderInfoCard(BookingOrder order) {  // ✅ 添加類型聲明
  return Card(
    ...
  );
}
```

---

## 📊 修復前後對比

### 修復前（錯誤）❌

```dart
// booking_success_page.dart

// ❌ 缺少 import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/booking_provider.dart';

class BookingSuccessPage extends ConsumerWidget {
  ...
  
  // ❌ 沒有類型聲明
  Widget _buildStatusCard(order) {
    return Card(
      ...
      color: order.status.color,  // ❌ NoSuchMethodError
      ...
    );
  }
  
  // ❌ 沒有類型聲明
  Widget _buildOrderInfoCard(order) {
    return Card(...);
  }
}
```

**結果**：
```
❌ NoSuchMethodError: Class 'BookingStatus' has no instance getter 'color'.
```

---

### 修復後（正確）✅

```dart
// booking_success_page.dart

// ✅ 添加 import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/booking_order.dart';  // ✅ 新增
import '../../../../shared/providers/booking_provider.dart';

class BookingSuccessPage extends ConsumerWidget {
  ...
  
  // ✅ 添加類型聲明
  Widget _buildStatusCard(BookingOrder order) {
    return Card(
      ...
      color: order.status.color,  // ✅ 正常工作
      ...
    );
  }
  
  // ✅ 添加類型聲明
  Widget _buildOrderInfoCard(BookingOrder order) {
    return Card(...);
  }
}
```

**結果**：
```
✅ 正常顯示訂單狀態和顏色
```

---

## 🚀 測試和驗證

### 測試步驟

#### 步驟 1：重新啟動 App（1 分鐘）

1. **完全關閉 App**（從最近使用的 App 列表中滑掉）
2. **重新打開 App**
3. **登入測試帳號**

---

#### 步驟 2：測試預約成功頁面（1 分鐘）

1. **創建新訂單**（或查看現有訂單）
2. **進入預約成功頁面**
3. **預期結果**：
   - ✅ 不再顯示 `NoSuchMethodError`
   - ✅ 顯示訂單狀態卡片
   - ✅ 狀態圖標顯示正確的顏色（橙色）
   - ✅ 狀態文字顯示正確的顏色（橙色）
   - ✅ 進度條顯示正確的顏色（橙色）

---

#### 步驟 3：測試訂單列表頁面（1 分鐘）

1. **進入「預約訂單」頁面**
2. **查看訂單列表**
3. **預期結果**：
   - ✅ 訂單狀態標籤顯示正確的顏色
   - ✅ 不同狀態顯示不同顏色：
     - pending（待配對）：橙色
     - matched（已配對）：藍色
     - inProgress（進行中）：綠色
     - completed（已完成）：灰色
     - cancelled（已取消）：紅色

---

#### 步驟 4：測試訂單詳情頁面（1 分鐘）

1. **點擊任一訂單**
2. **查看訂單詳情**
3. **預期結果**：
   - ✅ 狀態卡片顯示正確的背景顏色
   - ✅ 狀態圖標顯示正確的顏色
   - ✅ 狀態文字顯示正確的顏色

---

### 驗證成功的標準

**預約成功頁面**：
```
✅ 顯示狀態卡片（橙色背景）
✅ 顯示狀態圖標（橙色）
✅ 顯示狀態文字「當前狀態：待配對」（橙色）
✅ 顯示進度條（橙色）
✅ 不顯示任何錯誤訊息
```

**訂單列表頁面**：
```
✅ 訂單狀態標籤顯示正確的顏色
✅ 不同狀態顯示不同顏色
✅ 不顯示任何錯誤訊息
```

**訂單詳情頁面**：
```
✅ 狀態卡片顯示正確的顏色
✅ 狀態圖標和文字顯示正確的顏色
✅ 不顯示任何錯誤訊息
```

---

## 💡 開發心得和經驗總結

### 1. Dart Extension 的使用要點

**Extension 必須被導入才能使用**：
- Extension 不會自動可用
- 必須 import 定義 extension 的文件
- 即使類型本身已經可用，extension 也需要單獨導入

**示例**：
```dart
// booking_order.dart
enum BookingStatus { ... }
extension BookingStatusExtension on BookingStatus { ... }

// 其他文件
import 'booking_order.dart';  // ✅ 必須導入才能使用 extension
```

---

### 2. 類型推斷的限制

**Dart 無法推斷動態類型的 extension**：
- 如果參數沒有類型聲明，Dart 將其視為 `dynamic`
- `dynamic` 類型無法應用 extension
- 必須明確聲明類型

**錯誤示例**：
```dart
Widget _buildCard(order) {  // ❌ order 是 dynamic
  return Text(order.status.displayName);  // ❌ 無法訪問 extension
}
```

**正確示例**：
```dart
Widget _buildCard(BookingOrder order) {  // ✅ order 是 BookingOrder
  return Text(order.status.displayName);  // ✅ 可以訪問 extension
}
```

---

### 3. 錯誤訊息的價值

**`NoSuchMethodError` 的診斷**：
- 錯誤訊息：`Class 'BookingStatus' has no instance getter 'color'`
- 表示：Dart 找到了 `BookingStatus` 類型，但找不到 `color` getter
- 原因：Extension 沒有被應用

**診斷步驟**：
1. 確認 extension 是否存在 ✅
2. 確認 extension 是否被導入 ❌
3. 確認類型是否明確聲明 ❌

---

### 4. 代碼一致性的重要性

**為什麼其他頁面沒有問題？**
- `order_detail_page.dart` 和 `order_list_page.dart` 都有導入 `booking_order.dart`
- 它們的方法參數都有明確的類型聲明

**教訓**：
- 保持代碼風格一致
- 所有方法參數都應該有類型聲明
- 所有需要的 import 都應該添加

---

### 5. 遇到的困難

**困難 1：錯誤訊息誤導**
- 錯誤訊息說「沒有 color getter」
- 實際上 color getter 存在
- 真正的問題是 extension 沒有被應用

**解決**：
- 不要只看錯誤訊息的表面
- 深入檢查 import 和類型聲明
- 對比正常工作的代碼

**困難 2：IDE 沒有提示**
- IDE 沒有提示缺少 import
- IDE 沒有提示缺少類型聲明
- 只有在運行時才發現錯誤

**解決**：
- 啟用更嚴格的 lint 規則
- 使用 `always_specify_types` lint 規則
- 定期檢查代碼質量

---

## 📋 後續改進

### 1. 啟用更嚴格的 Lint 規則

**建議**：在 `analysis_options.yaml` 中添加：
```yaml
linter:
  rules:
    - always_specify_types  # 強制指定類型
    - prefer_typing_uninitialized_variables  # 強制初始化變數時指定類型
```

---

### 2. 添加單元測試

**建議**：測試 `BookingStatusExtension`
```dart
test('BookingStatus.color returns correct colors', () {
  expect(BookingStatus.pending.color, const Color(0xFFFF9800));
  expect(BookingStatus.matched.color, const Color(0xFF2196F3));
  expect(BookingStatus.inProgress.color, const Color(0xFF4CAF50));
  expect(BookingStatus.completed.color, const Color(0xFF9E9E9E));
  expect(BookingStatus.cancelled.color, const Color(0xFFF44336));
});
```

---

### 3. 代碼審查檢查清單

**建議**：在代碼審查時檢查：
- [ ] 所有方法參數都有類型聲明
- [ ] 所有需要的 import 都已添加
- [ ] Extension 的使用是否正確
- [ ] 是否有類似的問題在其他文件中

---

## 📚 相關文檔

- `docs/20251006_2158_09_整數類型修復.md` - 整數類型修復
- `docs/20251006_2047_08_Timestamp格式修復.md` - Timestamp 修復
- `docs/20251006_0840_07_GeoPoint格式修復.md` - GeoPoint 修復
- `mobile/docs/20250930_2330_10_管理後台啟動與預約流程優化.md` - 之前發現的同樣問題

---

**修復狀態**：✅ 完成  
**測試狀態**：⏳ 待用戶驗證  
**影響範圍**：客戶端 App - 預約成功頁面

🚀 **請重新啟動 App 並測試預約成功頁面，應該不再顯示錯誤了！**

