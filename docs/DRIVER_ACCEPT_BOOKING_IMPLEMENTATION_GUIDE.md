# 🚀 司機端「確認接單」功能實作指南

**日期**：2025-01-12  
**目的**：解決手動派單後訂單狀態顯示不一致的問題  
**預計時間**：30 分鐘

---

## 📋 當前問題

**手動派單後的訂單狀態顯示**：
- 公司端 Web Admin：顯示「已配對」（`status: 'matched'`）
- 客戶端 APP：顯示「待配對」（因為 Edge Function 將 `'matched'` 轉換為 `'pending'`）
- 司機端 APP：顯示「待配對」（同樣原因）

**問題根源**：
- 手動派單 API 將訂單狀態設置為 `'matched'`
- Edge Function 的狀態映射將 `'matched'` 轉換為 `'pending'`
- 導致客戶端和司機端看到的狀態與公司端不一致

---

## ✅ 解決方案

### 方案概述

1. **修改 Edge Function 的狀態映射**：將 `'driver_confirmed'` 映射為 `'matched'`
2. **司機端添加「確認接單」按鈕**：調用 Backend API 更新訂單狀態
3. **訂單狀態流程**：
   ```
   手動派單（matched）
     ↓ Edge Function 轉換
   Firestore（pending）← 司機看到「待配對」
     ↓ 司機點擊「確認接單」
   Backend API（driver_confirmed）
     ↓ Edge Function 轉換
   Firestore（matched）← 司機和客戶看到「已配對」
   ```

---

## 🔧 實作步驟

### 步驟 1：修改 Edge Function 的狀態映射（5 分鐘）

**文件**：`supabase/functions/sync-to-firestore/index.ts`

**當前代碼**（第 328-343 行）：
```typescript
status: (() => {
  const statusMapping: { [key: string]: string } = {
    'pending_payment': 'pending',
    'paid_deposit': 'pending',
    'assigned': 'matched',
    'driver_confirmed': 'matched',
    'driver_departed': 'inProgress',
    'driver_arrived': 'inProgress',
    'in_progress': 'inProgress',
    'completed': 'completed',
    'cancelled': 'cancelled',
  };
  return statusMapping[bookingData.status] || 'pending';
})(),
```

**需要修改為**：
```typescript
status: (() => {
  const statusMapping: { [key: string]: string } = {
    'pending_payment': 'pending',
    'paid_deposit': 'pending',
    'assigned': 'pending',          // ✅ 修改：已分配司機 → 待配對（等待司機確認）
    'matched': 'pending',            // ✅ 修改：手動派單 → 待配對（等待司機確認）
    'driver_confirmed': 'matched',   // ✅ 保持：司機確認後 → 已配對
    'driver_departed': 'inProgress',
    'driver_arrived': 'inProgress',
    'in_progress': 'inProgress',
    'completed': 'completed',
    'cancelled': 'cancelled',
  };
  return statusMapping[bookingData.status] || 'pending';
})(),
```

**修改說明**：
- `'assigned'` 和 `'matched'` 都映射為 `'pending'`（待配對）
- 司機確認接單後，狀態變為 `'driver_confirmed'`，映射為 `'matched'`（已配對）
- 這樣客戶端和司機端都會看到正確的狀態變化

**部署 Edge Function**：
1. 使用 Supabase Dashboard 手動更新代碼
2. 或者使用 Supabase CLI：`supabase functions deploy sync-to-firestore`

---

### 步驟 2：確認 Backend API（已完成）✅

**API 端點**：`POST /api/booking-flow/bookings/:bookingId/accept`

**文件**：
- 路由：`backend/src/routes/bookingFlow.ts`（第 110-113 行）
- Controller：`backend/src/controllers/BookingFlowController.ts`（第 206-252 行）

**功能**：
- 檢查司機權限（只有被分配的司機可以確認）
- 更新訂單狀態為 `'driver_confirmed'`
- 創建聊天室（司機和客戶可以溝通）
- 返回成功響應

**請求格式**：
```http
POST /api/booking-flow/bookings/:bookingId/accept
Authorization: Bearer <driver_token>
```

**響應格式**：
```json
{
  "success": true,
  "data": {
    "bookingId": "xxx",
    "status": "driver_confirmed",
    "chatRoomId": "xxx",
    "nextStep": "driver_depart"
  }
}
```

**狀態**：✅ 已實作完成，不需要修改

---

### 步驟 3：Flutter APP 實作（20 分鐘）

#### 3.1 添加「確認接單」按鈕

**文件**：`mobile/lib/features/driver/screens/booking_detail_screen.dart`（或類似文件）

**顯示條件**：
```dart
// 檢查是否應該顯示「確認接單」按鈕
bool shouldShowAcceptButton(BookingOrder booking) {
  // 1. 訂單狀態為「待配對」
  final isPending = booking.status == BookingStatus.pending;
  
  // 2. 訂單已分配給當前司機
  final currentDriverId = ref.read(authProvider).currentUser?.uid;
  final isAssignedToMe = booking.driverId == currentDriverId;
  
  // 3. 司機尚未確認接單（可以通過檢查狀態或添加新欄位）
  final notConfirmed = booking.status != BookingStatus.matched;
  
  return isPending && isAssignedToMe && notConfirmed;
}
```

**UI 代碼**：
```dart
// 在訂單詳情頁面添加按鈕
if (shouldShowAcceptButton(booking))
  Padding(
    padding: const EdgeInsets.all(16.0),
    child: ElevatedButton(
      onPressed: isLoading ? null : () => _handleAcceptBooking(booking.id),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              '確認接單',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    ),
  ),
```

#### 3.2 調用 Backend API

**創建 API Service 方法**：

**文件**：`mobile/lib/core/services/booking_service.dart`

```dart
/// 司機確認接單
Future<void> driverAcceptBooking(String bookingId) async {
  try {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw Exception('未登入');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/booking-flow/bookings/$bookingId/accept'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? '確認接單失敗');
    }

    final data = json.decode(response.body);
    if (!data['success']) {
      throw Exception(data['error'] ?? '確認接單失敗');
    }

    print('✅ 確認接單成功: ${data['data']}');
  } catch (e) {
    print('❌ 確認接單失敗: $e');
    rethrow;
  }
}
```

#### 3.3 處理按鈕點擊事件

**在訂單詳情頁面添加處理方法**：

```dart
bool isLoading = false;

Future<void> _handleAcceptBooking(String bookingId) async {
  setState(() {
    isLoading = true;
  });

  try {
    // 調用 API
    await ref.read(bookingServiceProvider).driverAcceptBooking(bookingId);

    // 顯示成功訊息
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 確認接單成功！'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Firestore 會自動更新訂單狀態，UI 會自動刷新
    // 不需要手動刷新

  } catch (e) {
    // 顯示錯誤訊息
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 確認接單失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}
```

#### 3.4 監聽 Firestore 訂單狀態變化

**使用 StreamBuilder 自動更新 UI**：

```dart
StreamBuilder<BookingOrder>(
  stream: ref.read(bookingServiceProvider).getBookingStream(bookingId),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return Text('錯誤: ${snapshot.error}');
    }

    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    final booking = snapshot.data!;

    return Column(
      children: [
        // 訂單資訊
        BookingInfoCard(booking: booking),

        // 確認接單按鈕（根據狀態自動顯示/隱藏）
        if (shouldShowAcceptButton(booking))
          AcceptBookingButton(
            bookingId: booking.id,
            onPressed: _handleAcceptBooking,
          ),

        // 其他操作按鈕
        // ...
      ],
    );
  },
)
```

**添加 getBookingStream 方法**（如果尚未存在）：

```dart
/// 獲取訂單的即時更新流
Stream<BookingOrder> getBookingStream(String bookingId) {
  return _firestore
      .collection('orders_rt')
      .doc(bookingId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) {
          throw Exception('訂單不存在');
        }
        return BookingOrder.fromFirestore(snapshot);
      });
}
```

---

## 🧪 測試步驟

### 測試 1：手動派單後司機確認接單

1. **公司端手動派單**
   - 登入公司端 Web Admin
   - 選擇待處理訂單
   - 手動派單給司機

2. **檢查司機端狀態**
   - 打開司機端 APP
   - 進入「我的訂單」>「進行中」
   - 確認訂單狀態顯示為「待配對」
   - 確認顯示「確認接單」按鈕

3. **司機確認接單**
   - 點擊「確認接單」按鈕
   - 確認顯示成功訊息
   - 確認訂單狀態自動更新為「已配對」
   - 確認「確認接單」按鈕消失

4. **檢查客戶端狀態**
   - 打開客戶端 APP
   - 進入「我的訂單」>「進行中」
   - 確認訂單狀態顯示為「已配對」

5. **檢查公司端狀態**
   - 刷新公司端 Web Admin
   - 確認訂單狀態顯示為「司機已確認」或「已配對」

### 測試 2：檢查 Firestore 同步

1. **打開 Firebase Console**
   - 進入 Firestore Database
   - 查看 `orders_rt` collection
   - 找到測試訂單

2. **確認狀態變化**
   - 手動派單後：`status: 'pending'`
   - 司機確認後：`status: 'matched'`

3. **確認時間戳記**
   - `updatedAt` 應該在司機確認後更新

### 測試 3：檢查 Backend API 日誌

1. **查看 Backend API 終端機**（Terminal 3）

2. **確認日誌**
   ```
   Driver accept booking: { bookingId: 'xxx', driverId: 'xxx' }
   ✅ Booking status updated: driver_confirmed
   ✅ Chat room created: xxx
   ```

---

## 📊 狀態流程圖

```
手動派單
  ↓
Supabase: status = 'matched'
  ↓
Trigger → outbox (event_type: 'updated', status: 'matched')
  ↓
Edge Function 處理
  ↓
Firestore: status = 'pending' (因為 'matched' → 'pending')
  ↓
司機端 APP: 顯示「待配對」+ 「確認接單」按鈕
  ↓
司機點擊「確認接單」
  ↓
Backend API: status = 'driver_confirmed'
  ↓
Trigger → outbox (event_type: 'updated', status: 'driver_confirmed')
  ↓
Edge Function 處理
  ↓
Firestore: status = 'matched' (因為 'driver_confirmed' → 'matched')
  ↓
司機端 APP: 顯示「已配對」，按鈕消失
客戶端 APP: 顯示「已配對」
```

---

## 📝 總結

**修改的文件**：2 個
1. `supabase/functions/sync-to-firestore/index.ts`（修改狀態映射）
2. `mobile/lib/features/driver/screens/booking_detail_screen.dart`（添加確認接單按鈕）
3. `mobile/lib/core/services/booking_service.dart`（添加 API 調用方法）

**Backend API**：✅ 已存在，不需要修改

**預期效果**：
- ✅ 手動派單後，司機看到「待配對」狀態
- ✅ 司機點擊「確認接單」後，狀態變為「已配對」
- ✅ 客戶端和司機端的狀態一致
- ✅ 公司端可以看到司機已確認

**修復完成時間**：2025-01-12  
**修復者**：Augment Agent  
**狀態**：實作指南已完成

