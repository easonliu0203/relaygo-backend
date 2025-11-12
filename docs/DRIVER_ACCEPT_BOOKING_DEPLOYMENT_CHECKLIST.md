# ✅ 司機端「確認接單」功能部署檢查清單

**日期**：2025-01-12  
**預計時間**：30 分鐘

---

## 📋 部署前檢查

### ✅ 1. Backend API（已完成）

- [x] API 端點已存在：`POST /api/booking-flow/bookings/:bookingId/accept`
- [x] Controller 已實作：`BookingFlowController.driverAcceptBooking()`
- [x] 功能已測試：更新訂單狀態為 `'driver_confirmed'`
- [x] Backend API 已啟動：Terminal 3，端口 3000

**狀態**：✅ 不需要修改

---

### ⚠️ 2. Edge Function（需要部署）

- [x] 狀態映射已修改：`'matched'` → `'pending'`，`'driver_confirmed'` → `'matched'`
- [ ] Edge Function 已部署到 Supabase

**文件**：`supabase/functions/sync-to-firestore/index.ts`

**修改內容**（第 327-344 行）：
```typescript
status: (() => {
  const statusMapping: { [key: string]: string } = {
    'pending_payment': 'pending',
    'paid_deposit': 'pending',
    'assigned': 'pending',          // ✅ 修改
    'matched': 'pending',            // ✅ 修改
    'driver_confirmed': 'matched',   // ✅ 保持
    'driver_departed': 'inProgress',
    'driver_arrived': 'inProgress',
    'in_progress': 'inProgress',
    'completed': 'completed',
    'cancelled': 'cancelled',
  };
  return statusMapping[bookingData.status] || 'pending';
})(),
```

**部署步驟**：
1. 打開 Supabase Dashboard
2. 進入 Edge Functions
3. 找到 `sync-to-firestore` 函數
4. 點擊「Edit」
5. 複製 `supabase/functions/sync-to-firestore/index.ts` 的全部內容
6. 貼上並保存
7. 點擊「Deploy」

**驗證**：
- 手動觸發 Edge Function
- 檢查 Firestore 中的訂單狀態是否正確映射

---

### ⚠️ 3. Flutter APP - 司機端（需要實作）

- [ ] 添加 `driverAcceptBooking()` 方法到 `BookingService`
- [ ] 添加「確認接單」按鈕到訂單詳情頁面
- [ ] 添加按鈕顯示邏輯（檢查訂單狀態和司機 ID）
- [ ] 添加按鈕點擊處理（調用 API + 錯誤處理）
- [ ] 使用 StreamBuilder 監聽 Firestore 訂單狀態變化

**參考文檔**：
- 實作指南：`docs/DRIVER_ACCEPT_BOOKING_IMPLEMENTATION_GUIDE.md`
- 代碼範例：`docs/FLUTTER_DRIVER_ACCEPT_BOOKING_CODE_EXAMPLE.md`

**關鍵文件**：
1. `mobile/lib/core/services/booking_service.dart`
2. `mobile/lib/features/driver/screens/booking_detail_screen.dart`

---

## 🚀 部署步驟

### 步驟 1：部署 Edge Function（5 分鐘）⚠️ **必須執行**

1. **打開 Supabase Dashboard**
   - 網址：https://supabase.com/dashboard
   - 選擇您的專案

2. **進入 Edge Functions**
   - 左側選單 > Edge Functions
   - 找到 `sync-to-firestore` 函數

3. **編輯函數代碼**
   - 點擊「Edit」或「Details」
   - 複製 `supabase/functions/sync-to-firestore/index.ts` 的全部內容
   - 貼上到編輯器中
   - 確認第 327-344 行的狀態映射已修改

4. **部署函數**
   - 點擊「Deploy」或「Save」
   - 等待部署完成（約 10-30 秒）

5. **驗證部署**
   - 檢查部署狀態是否為「Active」
   - 查看最近的日誌，確認沒有錯誤

---

### 步驟 2：實作 Flutter APP（20 分鐘）

#### 2.1 添加 API 調用方法（5 分鐘）

**文件**：`mobile/lib/core/services/booking_service.dart`

**添加方法**：
```dart
Future<void> driverAcceptBooking(String bookingId) async {
  // 參考：docs/FLUTTER_DRIVER_ACCEPT_BOOKING_CODE_EXAMPLE.md
}

Stream<BookingOrder> getBookingStream(String bookingId) {
  // 參考：docs/FLUTTER_DRIVER_ACCEPT_BOOKING_CODE_EXAMPLE.md
}
```

#### 2.2 修改訂單詳情頁面（15 分鐘）

**文件**：`mobile/lib/features/driver/screens/booking_detail_screen.dart`

**添加內容**：
1. `_shouldShowAcceptButton()` 方法
2. `_handleAcceptBooking()` 方法
3. 「確認接單」按鈕 UI
4. StreamBuilder 監聽訂單狀態變化

**參考**：`docs/FLUTTER_DRIVER_ACCEPT_BOOKING_CODE_EXAMPLE.md`

---

### 步驟 3：測試功能（5 分鐘）

#### 測試 1：手動派單後司機確認接單

1. **公司端手動派單**
   - 登入公司端 Web Admin (http://localhost:3001)
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

#### 測試 2：檢查 Backend API 日誌

**查看 Terminal 3**（Backend API）：
```
Driver accept booking: { bookingId: 'xxx', driverId: 'xxx' }
✅ Booking status updated: driver_confirmed
✅ Chat room created: xxx
```

#### 測試 3：檢查 Firestore 同步

**Firebase Console**：
1. 進入 Firestore Database
2. 查看 `orders_rt` collection
3. 找到測試訂單
4. 確認狀態變化：
   - 手動派單後：`status: 'pending'`
   - 司機確認後：`status: 'matched'`

---

## 🎯 驗證清單

### ✅ Edge Function 驗證

- [ ] Edge Function 已部署到 Supabase
- [ ] 部署狀態為「Active」
- [ ] 狀態映射已修改：`'matched'` → `'pending'`，`'driver_confirmed'` → `'matched'`
- [ ] 沒有部署錯誤

### ✅ Flutter APP 驗證

- [ ] `driverAcceptBooking()` 方法已添加
- [ ] `getBookingStream()` 方法已添加
- [ ] 「確認接單」按鈕已添加到訂單詳情頁面
- [ ] 按鈕顯示邏輯正確（只在待配對狀態顯示）
- [ ] 按鈕點擊處理正確（調用 API + 錯誤處理）
- [ ] StreamBuilder 正確監聽訂單狀態變化

### ✅ 功能驗證

- [ ] 手動派單後，司機端顯示「待配對」狀態
- [ ] 司機端顯示「確認接單」按鈕
- [ ] 點擊按鈕後，顯示成功訊息
- [ ] 訂單狀態自動更新為「已配對」
- [ ] 「確認接單」按鈕自動消失
- [ ] 客戶端訂單狀態同步更新為「已配對」
- [ ] Backend API 日誌顯示成功
- [ ] Firestore 訂單狀態正確同步

---

## 📊 狀態流程驗證

**預期流程**：
```
1. 手動派單
   ↓
   Supabase: status = 'matched'
   ↓
   Edge Function: 'matched' → 'pending'
   ↓
   Firestore: status = 'pending'
   ↓
   司機端 APP: 顯示「待配對」+ 「確認接單」按鈕

2. 司機點擊「確認接單」
   ↓
   Backend API: status = 'driver_confirmed'
   ↓
   Edge Function: 'driver_confirmed' → 'matched'
   ↓
   Firestore: status = 'matched'
   ↓
   司機端 APP: 顯示「已配對」，按鈕消失
   客戶端 APP: 顯示「已配對」
```

**驗證每個步驟**：
- [ ] 步驟 1：手動派單後，Supabase 狀態為 `'matched'`
- [ ] 步驟 2：Edge Function 轉換後，Firestore 狀態為 `'pending'`
- [ ] 步驟 3：司機端顯示「待配對」+ 按鈕
- [ ] 步驟 4：司機確認後，Backend API 更新為 `'driver_confirmed'`
- [ ] 步驟 5：Edge Function 轉換後，Firestore 狀態為 `'matched'`
- [ ] 步驟 6：司機端和客戶端都顯示「已配對」

---

## 🚨 常見問題

### 問題 1：Edge Function 部署失敗

**症狀**：部署時顯示錯誤訊息

**解決方案**：
1. 檢查代碼語法是否正確
2. 確認沒有遺漏逗號或括號
3. 查看 Edge Function 日誌，找出具體錯誤
4. 如果無法解決，使用 Supabase CLI 部署

### 問題 2：司機端按鈕不顯示

**症狀**：手動派單後，司機端沒有顯示「確認接單」按鈕

**可能原因**：
1. 訂單狀態不是 `'pending'`
2. 訂單沒有分配給當前司機
3. `_shouldShowAcceptButton()` 邏輯錯誤

**解決方案**：
1. 檢查 Firestore 中的訂單狀態
2. 檢查訂單的 `driverId` 是否等於當前司機的 Firebase UID
3. 添加日誌輸出，確認邏輯判斷

### 問題 3：點擊按鈕後沒有反應

**症狀**：點擊「確認接單」按鈕後，沒有顯示成功訊息

**可能原因**：
1. Backend API 調用失敗
2. 網路連接問題
3. 認證 Token 無效

**解決方案**：
1. 檢查 Backend API 日誌
2. 檢查 Flutter APP 日誌（`print` 輸出）
3. 確認 Firebase Auth Token 是否有效
4. 使用 Postman 測試 API 端點

### 問題 4：訂單狀態沒有自動更新

**症狀**：點擊按鈕後，訂單狀態沒有從「待配對」變為「已配對」

**可能原因**：
1. Edge Function 沒有正確同步到 Firestore
2. StreamBuilder 沒有正確監聽 Firestore 變化
3. 狀態映射錯誤

**解決方案**：
1. 檢查 Edge Function 日誌
2. 檢查 Firestore 中的訂單狀態是否已更新
3. 確認 StreamBuilder 的 stream 參數正確
4. 添加日誌輸出，確認 StreamBuilder 是否觸發

---

## 📝 總結

**部署清單**：
- [ ] Edge Function 已部署（5 分鐘）
- [ ] Flutter APP 已實作（20 分鐘）
- [ ] 功能已測試（5 分鐘）

**預期效果**：
- ✅ 手動派單後，司機看到「待配對」狀態 + 「確認接單」按鈕
- ✅ 司機點擊按鈕後，狀態變為「已配對」
- ✅ 客戶端和司機端的狀態一致
- ✅ 公司端可以看到司機已確認

**下一步**：
1. 完成部署
2. 測試功能
3. 如果有問題，參考「常見問題」章節

---

**部署完成時間**：2025-01-12  
**部署者**：Augment Agent  
**狀態**：檢查清單已完成

