# Flutter APP 測試指南 - 司機確認接單功能

**日期**: 2025-10-13  
**功能**: 測試司機端 APP 確認接單功能  
**前置條件**: Backend API 正常運行

---

## ✅ 前置檢查

### 1. 確認 Backend 運行
```bash
curl http://localhost:3000/health
```

**預期響應**:
```json
{
  "status": "OK",
  "timestamp": "2025-10-13T16:49:17.027Z",
  "service": "Ride Booking Backend API"
}
```

如果 Backend 未運行，請先啟動：
```bash
cd backend
npm run dev
```

### 2. 確認訂單狀態
在 Supabase Dashboard 或使用 SQL 查詢：
```sql
SELECT id, booking_number, status, driver_id
FROM bookings
WHERE driver_id IS NOT NULL
  AND status = 'matched'
ORDER BY created_at DESC
LIMIT 5;
```

**需要**: 至少一個狀態為 `matched` 的訂單

---

## 🧪 測試步驟

### 步驟 1: 準備測試訂單

#### 方法 A: 使用現有訂單
如果已有 `matched` 狀態的訂單，跳到步驟 2

#### 方法 B: 創建新訂單
1. 打開客戶端 APP
2. 登入測試帳號: `customer.test@relaygo.com` / `Test1234`
3. 創建新訂單
4. 支付訂金

#### 方法 C: 手動派單
1. 打開 Web Admin: http://localhost:3001
2. 登入管理員帳號: `admin@relaygo.com` / `Admin1234`
3. 進入「待處理訂單」
4. 選擇訂單，點擊「派單」
5. 選擇司機: `driver.test@relaygo.com`
6. 確認派單

---

### 步驟 2: 重新編譯 Flutter APP

**重要**: 必須重新編譯才能應用之前的按鈕修復！

```bash
cd mobile
flutter clean
flutter pub get
flutter run -t lib/apps/driver/main_driver.dart
```

或使用自動化腳本：
```bash
cd mobile/scripts
rebuild-driver-app.bat
```

---

### 步驟 3: 登入司機端 APP

1. 打開司機端 APP
2. 登入測試帳號:
   - Email: `driver.test@relaygo.com`
   - Password: `Test1234`

---

### 步驟 4: 查看訂單

1. 進入「我的訂單」頁面
2. 切換到「進行中」標籤
3. 應該看到剛才派單的訂單

**預期狀態**:
- 訂單卡片顯示「待確認」或類似狀態
- 訂單詳情可以點擊查看

---

### 步驟 5: 確認接單

1. 點擊訂單卡片，進入訂單詳情頁面
2. **檢查按鈕顯示**:
   - ✅ 應該顯示綠色的「確認接單」按鈕
   - ✅ 按鈕應該是全寬的
   - ✅ 按鈕應該在頁面底部

3. 點擊「確認接單」按鈕
4. **檢查確認對話框**:
   - ✅ 應該彈出確認對話框
   - ✅ 對話框顯示訂單資訊

5. 點擊「確認」
6. **檢查載入狀態**:
   - ✅ 按鈕顯示載入動畫
   - ✅ 按鈕文字變為「處理中...」

---

### 步驟 6: 驗證結果

#### 6.1 Flutter APP 檢查
- ✅ 顯示成功提示訊息
- ✅ 「確認接單」按鈕消失
- ✅ 訂單狀態更新為「已確認」或「進行中」
- ✅ 可能顯示「司機出發」按鈕

#### 6.2 Backend 日誌檢查
查看 Backend 終端機，應該看到：
```
[API] 司機確認接單: bookingId=xxx, driverUid=CMfTxhJFlUVDkosJPyUoJvKjCQk1
[API] 訂單資料: { id: 'xxx', status: 'matched', ... }
[API] 司機資料: { id: 'xxx', firebase_uid: 'CMfTxhJFlUVDkosJPyUoJvKjCQk1', ... }
[API] ✅ 訂單狀態已更新為 driver_confirmed
```

#### 6.3 Supabase 檢查
在 Supabase Dashboard 查詢：
```sql
SELECT id, booking_number, status, updated_at
FROM bookings
WHERE id = '<BOOKING_ID>';
```

**預期結果**:
- ✅ `status` = `'driver_confirmed'`
- ✅ `updated_at` 是最新時間

#### 6.4 Firestore 檢查
在 Firebase Console > Firestore Database 查看：
```
bookings/<BOOKING_ID>
```

**預期結果**:
- ✅ `status` = `'matched'`（注意：Firestore 的 matched 對應 Supabase 的 driver_confirmed）
- ✅ `updatedAt` 是最新時間

---

## ❌ 常見問題排查

### 問題 1: 按鈕不顯示

**可能原因**:
1. Flutter APP 沒有重新編譯
2. 訂單狀態不是 `pending`（Firestore）
3. 訂單沒有分配司機

**解決方案**:
```bash
# 1. 重新編譯
cd mobile
flutter clean
flutter pub get
flutter run -t lib/apps/driver/main_driver.dart

# 2. 檢查 Firestore 訂單狀態
# 在 Firebase Console 查看 bookings/<BOOKING_ID>
# 確認 status = 'pending' 且 driverId 不為 null

# 3. 重新派單
# 在 Web Admin 重新派單
```

---

### 問題 2: 點擊按鈕後報錯

**錯誤訊息**: `ClientException: Connection reset by peer`

**可能原因**: Backend 未運行

**解決方案**:
```bash
cd backend
npm run dev
```

---

### 問題 3: 權限驗證失敗

**錯誤訊息**: `無權限操作此訂單`

**可能原因**:
1. 登入的司機不是被派單的司機
2. 訂單的 driver_id 不匹配

**解決方案**:
1. 確認登入的司機帳號
2. 確認訂單派給了正確的司機
3. 重新派單

---

### 問題 4: 訂單狀態不正確

**錯誤訊息**: `訂單狀態不正確（當前: driver_confirmed，需要: matched）`

**可能原因**: 訂單已經被確認過了

**解決方案**:
1. 創建新訂單
2. 手動派單
3. 再次測試

---

## 📊 測試檢查清單

### 前置條件
- [ ] Backend 正常運行（Port 3000）
- [ ] 有狀態為 `matched` 的測試訂單
- [ ] Flutter APP 已重新編譯

### UI 測試
- [ ] 訂單詳情頁面正常顯示
- [ ] 「確認接單」按鈕正確顯示
- [ ] 按鈕樣式正確（綠色、全寬）
- [ ] 點擊按鈕彈出確認對話框
- [ ] 確認對話框顯示正確資訊

### 功能測試
- [ ] 點擊確認後顯示載入狀態
- [ ] API 調用成功
- [ ] 顯示成功提示訊息
- [ ] 按鈕消失或變為其他狀態
- [ ] 訂單狀態正確更新

### 數據驗證
- [ ] Supabase bookings.status = `driver_confirmed`
- [ ] Firestore bookings.status = `matched`
- [ ] Backend 日誌正確
- [ ] 時間戳正確更新

---

## 🎯 預期結果總結

### 成功標準
1. ✅ 按鈕正確顯示
2. ✅ 點擊按鈕功能正常
3. ✅ API 調用成功
4. ✅ 訂單狀態正確更新
5. ✅ UI 狀態正確更新

### 完整流程
```
手動派單 
  → Supabase: matched 
  → Firestore: pending 
  → Flutter: 顯示「確認接單」按鈕
  → 司機點擊按鈕
  → API 調用成功
  → Supabase: driver_confirmed
  → Firestore: matched
  → Flutter: 按鈕消失，狀態更新
```

---

## 📞 需要幫助？

如果測試失敗，請檢查：
1. `docs/20251013_NETWORK_ERROR_FIX.md` - 網路錯誤修復
2. `docs/20251013_BACKEND_STARTUP_GUIDE.md` - Backend 啟動指南
3. `docs/DRIVER_ACCEPT_BUTTON_TEST_CHECKLIST.md` - 詳細測試清單

---

**最後更新**: 2025-10-13  
**測試狀態**: ⏳ 待執行  
**預期結果**: ✅ 全部通過

