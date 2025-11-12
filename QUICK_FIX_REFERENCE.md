# 🚀 取消訂單錯誤 - 快速修復參考

## ❌ 問題
```
'package:flutter/src/widgets/framework.dart': 
Failed assertion: line 6161 pos 14: '_dependents.isEmpty': is not true.
```

## ✅ 解決方案

### 修改文件
`mobile/lib/apps/customer/presentation/pages/order_detail_page.dart`

### 關鍵修改
在 `.then()` 回調中添加延遲:

```dart
).then((reason) async {
  reasonController.dispose();
  
  // ✅ 添加這兩行
  await Future.delayed(const Duration(milliseconds: 300));
  if (!context.mounted) return;
  
  if (reason != null && reason.isNotEmpty) {
    // ... 取消訂單邏輯
  }
});
```

## 🧪 快速測試

```bash
cd mobile
flutter clean && flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

測試步驟:
1. 創建訂單 → 支付 → 查看詳情
2. 點擊「取消訂單」
3. 輸入原因 → 確認

預期: ✅ 平滑關閉,顯示「訂單已取消」,無錯誤

## 🔍 為什麼需要延遲?

```
用戶確認 → Navigator.pop() → 對話框開始關閉動畫 (200-300ms)
                              ↓
                         .then() 立即執行
                              ↓
                         取消訂單 API
                              ↓
                         Firestore 更新
                              ↓
                         StreamProvider 檢測變化
                              ↓
                         ⚠️ 頁面重建 (對話框還在關閉中)
                              ↓
                         ❌ _dependents.isEmpty 錯誤
```

**修復**: 延遲 300ms 確保對話框完全關閉後再更新狀態

## 📚 詳細文檔
查看 `取消訂單_dependents錯誤修復指南.md`

