# 司機端「確認接單」按鈕測試清單

**日期**: 2025-10-13  
**修復內容**: 按鈕顯示條件從 `status == matched` 改為 `status == pending && driverId != null`  
**測試目標**: 驗證按鈕在正確的情況下顯示和隱藏

---

## 📋 測試前準備

### 1. 重新編譯 Flutter APP
```bash
cd mobile
flutter clean
flutter pub get
flutter run -t lib/apps/driver/main_driver.dart
```

或使用快速腳本：
```bash
cd mobile/scripts
rebuild-driver-app.bat
```

### 2. 確認測試帳號
- ✅ 客戶端: `customer.test@relaygo.com` / `Test1234!`
- ✅ 司機端: `driver.test@relaygo.com` / `Test1234!`
- ✅ 管理員: `admin@relaygo.com` / `Admin1234!`

### 3. 確認服務運行
- ✅ Backend API: `http://localhost:3000`
- ✅ Web Admin: `http://localhost:3001`
- ✅ Supabase: 已連接
- ✅ Firebase: 已連接

---

## ✅ 測試案例 1: 正常流程 - 按鈕應該顯示

### 前置條件
- 訂單狀態: `pending`
- 已分配司機: `driverId != null`
- 司機尚未確認

### 測試步驟

#### Step 1: 創建訂單（客戶端 APP）
```
1. 打開客戶端 APP
2. 登入: customer.test@relaygo.com
3. 點擊「立即預約」
4. 填寫訂單資訊：
   - 上車地點: 台北車站
   - 下車地點: 松山機場
   - 預約時間: 明天 10:00
   - 乘客人數: 2
5. 點擊「下一步」
6. 選擇車型: 舒適4人座
7. 確認訂單
8. 完成訂金支付
```

**預期結果**:
- ✅ 訂單創建成功
- ✅ 訂金支付成功
- ✅ 訂單狀態: 待處理

#### Step 2: 手動派單（Web Admin）
```
1. 打開瀏覽器: http://localhost:3001
2. 登入: admin@relaygo.com
3. 進入「訂單管理」>「待處理訂單」
4. 找到剛創建的訂單
5. 點擊「手動派單」按鈕
6. 在司機列表中選擇: driver.test@relaygo.com
7. 點擊「確認派單」
```

**預期結果**:
- ✅ 派單成功提示
- ✅ 訂單狀態更新為「已派單」
- ✅ 司機資訊顯示正確

#### Step 3: 驗證 Supabase 狀態
```sql
-- 在 Supabase SQL Editor 執行
SELECT 
    id,
    booking_number,
    status,
    driver_id,
    updated_at
FROM bookings
ORDER BY updated_at DESC
LIMIT 1;
```

**預期結果**:
- ✅ `status` = `'matched'`
- ✅ `driver_id` = 司機的 UUID（不為 NULL）

#### Step 4: 驗證 Firestore 狀態
```
1. 打開 Firebase Console
2. 進入 Firestore Database
3. 查看 orders_rt 集合
4. 找到對應的訂單文檔
```

**預期結果**:
- ✅ `status` = `'pending'`（映射後的狀態）
- ✅ `driverId` = 司機的 Firebase UID（不為 NULL）
- ✅ `driverName` = 司機姓名

#### Step 5: 驗證按鈕顯示（司機端 APP）⭐ 關鍵測試
```
1. 打開司機端 APP
2. 登入: driver.test@relaygo.com
3. 進入「我的訂單」頁面
4. 切換到「進行中」標籤
5. 找到剛派單的訂單
6. 點擊訂單卡片進入詳情頁面
```

**預期結果**:
- ✅ 訂單詳情頁面正確顯示
- ✅ 訂單狀態顯示「待配對」（橙色）
- ✅ **顯示「確認接單」按鈕**（綠色，全寬）
- ✅ 按鈕文字為「確認接單」
- ✅ 按鈕可點擊（非禁用狀態）

#### Step 6: 測試按鈕功能
```
1. 點擊「確認接單」按鈕
2. 在確認對話框中點擊「確認接單」
3. 等待處理完成
```

**預期結果**:
- ✅ 顯示確認對話框
- ✅ 對話框內容正確
- ✅ 顯示載入狀態（轉圈圈）
- ✅ 顯示成功訊息「✅ 接單成功！聊天室已創建，您可以與客戶開始溝通」
- ✅ 訂單狀態更新為「已配對」（藍色）
- ✅ **「確認接單」按鈕消失**

#### Step 7: 驗證最終狀態
```sql
-- Supabase
SELECT status FROM bookings WHERE id = 'YOUR_BOOKING_ID';
-- 預期: 'driver_confirmed'
```

```
// Firestore
orders_rt/{bookingId}.status
// 預期: 'matched'
```

**預期結果**:
- ✅ Supabase: `status` = `'driver_confirmed'`
- ✅ Firestore: `status` = `'matched'`
- ✅ 聊天室已創建

---

## ❌ 測試案例 2: 邊界情況 - 按鈕不應該顯示

### 案例 2.1: 未分配司機的訂單

**前置條件**:
- 訂單狀態: `pending`
- 未分配司機: `driverId == null`

**測試步驟**:
```
1. 創建新訂單（客戶端）
2. 完成訂金支付
3. 不要手動派單
4. 在司機端 APP 查看訂單列表
```

**預期結果**:
- ✅ 訂單不出現在司機端的「進行中」列表
- ✅ 即使手動查看訂單詳情，也不顯示「確認接單」按鈕

### 案例 2.2: 已確認的訂單

**前置條件**:
- 訂單狀態: `matched`（Firestore）
- 已分配司機: `driverId != null`
- 司機已確認

**測試步驟**:
```
1. 使用測試案例 1 創建並派單
2. 司機確認接單
3. 再次查看訂單詳情
```

**預期結果**:
- ✅ 訂單狀態顯示「已配對」（藍色）
- ✅ **不顯示「確認接單」按鈕**
- ✅ 可能顯示其他操作按鈕（如「開始行程」）

### 案例 2.3: 已完成的訂單

**前置條件**:
- 訂單狀態: `completed`
- 已分配司機: `driverId != null`

**測試步驟**:
```
1. 查看歷史訂單
2. 點擊已完成的訂單
```

**預期結果**:
- ✅ 訂單狀態顯示「已完成」（灰色）
- ✅ **不顯示「確認接單」按鈕**
- ✅ 不顯示任何操作按鈕

---

## 🐛 問題排查指南

### 問題 1: 按鈕仍然不顯示

**檢查清單**:
```
□ Flutter APP 是否重新編譯？
  → 執行 flutter clean && flutter pub get

□ 訂單狀態是否正確？
  → 檢查 Firestore: status = 'pending'

□ 司機是否已分配？
  → 檢查 Firestore: driverId != null

□ 是否使用正確的司機帳號登入？
  → 檢查 driverId 是否匹配當前登入的司機

□ Edge Function 是否正常同步？
  → 檢查 Supabase outbox 表的 processed_at
```

**調試步驟**:
```dart
// 在 driver_order_detail_page.dart 添加日誌
print('========== 按鈕顯示調試 ==========');
print('訂單 ID: ${order.id}');
print('訂單狀態: ${order.status}');
print('訂單狀態名稱: ${order.status.name}');
print('司機 ID: ${order.driverId}');
print('當前用戶 ID: ${FirebaseAuth.instance.currentUser?.uid}');
print('是否顯示按鈕: ${order.status == BookingStatus.pending && order.driverId != null}');
print('================================');
```

### 問題 2: 按鈕顯示但點擊無反應

**檢查清單**:
```
□ Backend API 是否運行？
  → curl http://localhost:3000/health

□ 網路連接是否正常？
  → 檢查模擬器網路設置

□ API URL 是否正確？
  → 檢查 mobile/.env 中的 BACKEND_URL

□ 是否有錯誤日誌？
  → 查看 Flutter 控制台輸出
```

### 問題 3: 狀態不更新

**檢查清單**:
```
□ Supabase Trigger 是否觸發？
  → 檢查 outbox 表是否有新記錄

□ Edge Function 是否處理？
  → 檢查 outbox.processed_at 是否不為 NULL

□ Firestore 是否更新？
  → 在 Firebase Console 檢查文檔更新時間

□ Flutter APP 是否監聽變更？
  → 檢查 StreamProvider 是否正常工作
```

---

## 📊 測試結果記錄表

### 測試案例 1: 正常流程
| 步驟 | 預期結果 | 實際結果 | 狀態 | 備註 |
|------|----------|----------|------|------|
| 創建訂單 | 成功 | | ⏳ | |
| 手動派單 | 成功 | | ⏳ | |
| Supabase 狀態 | matched | | ⏳ | |
| Firestore 狀態 | pending | | ⏳ | |
| 按鈕顯示 | 顯示 | | ⏳ | ⭐ 關鍵 |
| 按鈕功能 | 成功 | | ⏳ | |
| 最終狀態 | 正確 | | ⏳ | |

### 測試案例 2: 邊界情況
| 案例 | 預期結果 | 實際結果 | 狀態 | 備註 |
|------|----------|----------|------|------|
| 未分配司機 | 不顯示 | | ⏳ | |
| 已確認訂單 | 不顯示 | | ⏳ | |
| 已完成訂單 | 不顯示 | | ⏳ | |

---

## ✅ 測試通過標準

### 必須通過的測試
- ✅ 測試案例 1 的所有步驟
- ✅ 按鈕在正確的情況下顯示
- ✅ 按鈕功能正常工作
- ✅ 狀態正確更新

### 可選測試
- ⭐ 測試案例 2 的所有邊界情況
- ⭐ 多次重複測試確保穩定性
- ⭐ 不同網路環境測試

---

## 🎯 測試完成後

### 如果測試通過
1. ✅ 標記所有測試案例為「通過」
2. ✅ 記錄測試時間和測試人員
3. ✅ 準備部署到生產環境
4. ✅ 更新文檔和發布說明

### 如果測試失敗
1. ❌ 記錄失敗的測試案例
2. ❌ 記錄錯誤訊息和截圖
3. ❌ 參考「問題排查指南」
4. ❌ 修復問題後重新測試

---

## 📝 測試報告模板

```
測試報告 - 司機端「確認接單」按鈕

測試日期: 2025-10-13
測試人員: [您的名字]
測試環境: 
  - Flutter: [版本]
  - Android: [版本]
  - Backend: localhost:3000
  - Supabase: [項目 ID]

測試結果:
  - 測試案例 1: [通過/失敗]
  - 測試案例 2.1: [通過/失敗]
  - 測試案例 2.2: [通過/失敗]
  - 測試案例 2.3: [通過/失敗]

問題記錄:
  - [如有問題，詳細描述]

結論:
  - [整體評估]
```

---

## 🎉 預期結果

**測試通過後，您應該看到**:
1. ✅ 手動派單後，司機端立即顯示「確認接單」按鈕
2. ✅ 按鈕為綠色，全寬，文字清晰
3. ✅ 點擊按鈕後流程順暢
4. ✅ 確認後按鈕消失，狀態更新
5. ✅ 所有邊界情況正確處理

**開始測試吧！** 🚀

