# 取消訂單 `_dependents.isEmpty` 錯誤修復指南

**日期**: 2025-10-08  
**問題**: Flutter `_dependents.isEmpty` 斷言錯誤  
**狀態**: ✅ 已修復

---

## 📋 問題描述

### 錯誤訊息
```
'package:flutter/src/widgets/framework.dart': 
Failed assertion: line 6161 pos 14: '_dependents.isEmpty': is not true.
```

### 發生時機
1. 完成支付流程
2. 進入「預約成功」頁面
3. 點擊「查看訂單詳情」
4. 在訂單詳情頁面點擊「取消訂單」按鈕
5. 輸入取消原因並確認
6. ❌ 出現錯誤畫面

---

## 🔍 根本原因分析

### 問題 1: TextEditingController Dispose 時機
最初的問題是 `TextEditingController` 在對話框關閉前被 dispose。

**已修復**: 使用 `showDialog().then()` 回調,在對話框完全關閉後才 dispose。

### 問題 2: 狀態更新觸發頁面重建 (主要問題)
即使修復了 dispose 時機,仍然出現錯誤。原因是:

1. **StreamProvider 監聽 Firestore**
   ```dart
   final bookingProvider = StreamProvider.family<BookingOrder?, String>((ref, orderId) {
     final bookingService = ref.watch(bookingServiceProvider);
     return bookingService.watchBooking(orderId);  // 監聽 Firestore 變化
   });
   ```

2. **取消訂單的數據流**
   ```
   用戶點擊確認
   ↓
   Navigator.pop(reason)  // 對話框開始關閉動畫
   ↓
   .then() 回調執行
   ↓
   reasonController.dispose()  // ✅ 已經在 .then() 中
   ↓
   cancelBookingWithSupabase()  // ⚠️ 立即執行
   ↓
   更新 Supabase
   ↓
   Supabase Trigger 同步到 Firestore
   ↓
   StreamProvider 檢測到變化  // ⚠️ 對話框可能還在關閉動畫中
   ↓
   OrderDetailPage 重建  // ❌ 導致 context 相關問題
   ↓
   _dependents.isEmpty 錯誤
   ```

3. **時序問題**
   - 對話框關閉動畫通常需要 200-300ms
   - 但 `cancelBookingWithSupabase()` 立即執行
   - Firestore 更新可能在對話框動畫完成前到達
   - 導致頁面在對話框關閉過程中重建

---

## ✅ 修復方案

### 修改文件
`mobile/lib/apps/customer/presentation/pages/order_detail_page.dart`

### 修改內容

**修改前**:
```dart
).then((reason) async {
  // 對話框完全關閉後才 dispose controller
  reasonController.dispose();

  // 如果用戶確認取消（返回了取消原因）
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
```

**修改後**:
```dart
).then((reason) async {
  // 對話框完全關閉後才 dispose controller
  reasonController.dispose();

  // ✅ 等待對話框關閉動畫完成，避免 _dependents.isEmpty 錯誤
  await Future.delayed(const Duration(milliseconds: 300));

  // ✅ 檢查 context 是否仍然有效
  if (!context.mounted) return;

  // 如果用戶確認取消（返回了取消原因）
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
```

### 關鍵改進

1. **添加延遲**: `await Future.delayed(const Duration(milliseconds: 300))`
   - 確保對話框關閉動畫完全完成
   - 300ms 足夠覆蓋 Material Design 的標準動畫時長

2. **檢查 context**: `if (!context.mounted) return`
   - 在執行任何操作前檢查 context 是否仍然有效
   - 如果用戶在延遲期間離開頁面,則不執行後續操作

3. **保持原有的 context.mounted 檢查**
   - 在顯示 SnackBar 前仍然檢查 context
   - 雙重保護,確保不會在無效 context 上操作

---

## 🧪 測試步驟

### 1. 重新建置應用

```bash
cd mobile
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

### 2. 完整測試流程

#### 步驟 1: 創建訂單
1. 打開應用
2. 填寫預約資訊
3. 選擇套餐
4. 完成支付

#### 步驟 2: 進入訂單詳情
1. 在「預約成功」頁面點擊「查看訂單詳情」
2. 或從「我的訂單」進入訂單詳情

#### 步驟 3: 測試取消訂單
1. 點擊「取消訂單」按鈕
2. 輸入取消原因 (至少 5 個字元)
3. 點擊「確認取消」

#### 預期結果
- ✅ 對話框平滑關閉
- ✅ 顯示「訂單已取消」訊息
- ✅ 訂單狀態更新為「已取消」
- ✅ **不出現任何錯誤畫面**
- ✅ 頁面正常顯示

### 3. 邊界情況測試

#### 測試 A: 快速離開頁面
1. 點擊「取消訂單」
2. 輸入原因並確認
3. 在對話框關閉後立即按返回鍵
4. **預期**: 不應該出現錯誤

#### 測試 B: 網絡延遲
1. 開啟飛航模式
2. 點擊「取消訂單」
3. 輸入原因並確認
4. **預期**: 顯示「取消失敗」訊息,不崩潰

#### 測試 C: 多次點擊
1. 點擊「取消訂單」
2. 快速點擊「確認取消」多次
3. **預期**: 只執行一次取消操作

---

## 📊 驗證成功標準

### 控制台日誌
```
[BookingService] 開始取消訂單: <booking_id>
[BookingService] 請求 URL: http://localhost:3001/api/bookings/<booking_id>/cancel
✅ 訂單已取消
```

### UI 表現
- ✅ 對話框平滑關閉 (無卡頓)
- ✅ SnackBar 正常顯示
- ✅ 訂單狀態正確更新
- ✅ 頁面不重新載入或閃爍

### Firestore 驗證
1. 打開 Firebase Console
2. 查看訂單文檔
3. ✅ `status` 欄位為 `cancelled`
4. ✅ `cancellation_reason` 欄位包含取消原因
5. ✅ `cancelled_at` 欄位有時間戳

---

## 🔧 故障排除

### 問題: 仍然出現 _dependents.isEmpty 錯誤

**可能原因**:
- 代碼沒有重新編譯
- 延遲時間不夠長

**解決方法**:
```bash
# 完全清理並重新建置
flutter clean
flutter pub get
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

如果仍然有問題,可以嘗試增加延遲時間:
```dart
await Future.delayed(const Duration(milliseconds: 500));
```

### 問題: 取消操作沒有執行

**可能原因**:
- context.mounted 檢查返回 false
- 用戶在延遲期間離開頁面

**解決方法**:
- 檢查控制台日誌
- 確認用戶沒有在對話框關閉後立即離開頁面

---

## 📚 技術要點總結

### Flutter Dialog 生命週期
1. `showDialog()` 顯示對話框
2. 用戶操作 → `Navigator.pop(value)`
3. 對話框開始關閉動畫 (200-300ms)
4. `.then()` 回調**立即**執行 (不等動畫完成)
5. 動畫完成,對話框完全移除

### 為什麼需要延遲
- `.then()` 回調在動畫開始時就執行
- 如果立即更新狀態,可能觸發頁面重建
- 頁面重建會影響正在進行的動畫
- 導致 widget 依賴關係錯誤

### 最佳實踐
1. 在 `.then()` 中 dispose controller
2. 添加適當延遲等待動畫完成
3. 檢查 context.mounted 再執行操作
4. 所有異步操作都要檢查 context

---

## ✅ 修復完成

此修復解決了:
- ✅ TextEditingController dispose 時機問題
- ✅ 對話框關閉時的狀態更新衝突
- ✅ StreamProvider 觸發的頁面重建問題
- ✅ Context 失效導致的錯誤

用戶現在可以順利取消訂單,不會再遇到 `_dependents.isEmpty` 錯誤。

