# 快速測試指南 - 司機確認接單功能

**日期**: 2025-10-13  
**功能**: 司機端「確認接單」按鈕  
**狀態**: ✅ 已自動化完成

---

## 🚀 快速測試（5 分鐘）

### 前提條件
- ✅ SQL 錯誤已修復
- ✅ Flutter APP 已實作完成
- ✅ Backend API 已部署
- ✅ Edge Function 已部署

### 測試步驟

#### 1. 創建測試訂單（客戶端 APP）
```
1. 打開客戶端 APP
2. 登入測試客戶帳號
3. 創建新訂單
4. 完成訂金支付
```

#### 2. 手動派單（公司端 Web Admin）
```
1. 打開 Web Admin: http://localhost:3001
2. 登入管理員帳號
3. 進入「訂單管理」>「待處理訂單」
4. 找到剛創建的訂單
5. 點擊「手動派單」
6. 選擇測試司機
7. 確認派單
```

#### 3. 確認接單（司機端 APP）
```
1. 打開司機端 APP
2. 登入測試司機帳號
3. 進入「我的訂單」>「進行中」
4. 點擊訂單查看詳情
5. 確認顯示「確認接單」按鈕 ✅
6. 點擊「確認接單」
7. 確認對話框點擊「確認接單」
8. 等待處理完成
9. 確認顯示成功訊息 ✅
10. 確認訂單狀態更新為「已配對」✅
```

---

## 🔍 驗證檢查點

### 檢查點 1: SQL 腳本
```bash
# 在 Supabase SQL Editor 執行
supabase/diagnose-driver-accept-button-issue.sql
```

**預期結果**:
- ✅ 步驟 2 顯示已派單的訂單
- ✅ 司機姓名正確顯示（不是錯誤訊息）
- ✅ 訂單狀態為 'matched'

### 檢查點 2: Firestore 狀態
```
1. 打開 Firebase Console
2. 進入 Firestore Database
3. 查看 orders_rt/{bookingId}
```

**預期結果**:
- ✅ status: 'pending'（手動派單後）
- ✅ driverId: 司機的 Firebase UID
- ✅ driverName: 司機姓名

### 檢查點 3: Flutter APP 按鈕
```
司機端 APP > 訂單詳情頁面
```

**預期結果**:
- ✅ 顯示「確認接單」按鈕（綠色）
- ✅ 按鈕可點擊
- ✅ 點擊後顯示確認對話框

### 檢查點 4: API 調用
```
Backend 日誌
```

**預期結果**:
- ✅ 收到 POST /api/booking-flow/bookings/:bookingId/accept
- ✅ 驗證司機權限成功
- ✅ 更新訂單狀態為 'driver_confirmed'
- ✅ 創建聊天室成功

### 檢查點 5: 最終狀態
```
1. Supabase: bookings 表
2. Firestore: orders_rt 集合
3. Flutter APP: 訂單詳情頁面
```

**預期結果**:
- ✅ Supabase status: 'driver_confirmed'
- ✅ Firestore status: 'matched'
- ✅ Flutter APP 顯示「已配對」
- ✅ 「確認接單」按鈕消失

---

## 🐛 常見問題排查

### 問題 1: SQL 錯誤 - 列 u.first_name 不存在
**原因**: SQL 腳本未更新  
**解決**: 已修復，重新執行 SQL 腳本

### 問題 2: 按鈕不顯示
**可能原因**:
1. 訂單狀態不是 'matched'
2. Firestore 同步延遲
3. Flutter APP 未刷新

**排查步驟**:
```dart
// 在 driver_order_detail_page.dart 添加日誌
print('訂單狀態: ${order.status}');
print('訂單 ID: ${order.id}');
print('司機 ID: ${order.driverId}');
```

### 問題 3: API 調用失敗
**可能原因**:
1. Backend 未啟動
2. URL 配置錯誤
3. 司機權限驗證失敗

**排查步驟**:
```bash
# 檢查 Backend 是否運行
curl http://localhost:3000/health

# 檢查 Flutter 配置
mobile/.env
BACKEND_URL=http://10.0.2.2:3000/api  # Android 模擬器
```

### 問題 4: Firestore 狀態不更新
**可能原因**:
1. Edge Function 未部署
2. Outbox 記錄未處理
3. Trigger 未觸發

**排查步驟**:
```sql
-- 檢查 outbox 記錄
SELECT * FROM outbox 
WHERE aggregate_type = 'booking' 
ORDER BY created_at DESC 
LIMIT 10;

-- 檢查是否已處理
SELECT 
    processed_at,
    error_message
FROM outbox 
WHERE aggregate_id = 'YOUR_BOOKING_ID';
```

---

## 📝 測試帳號

### 客戶端
- Email: `customer.test@relaygo.com`
- Password: `Test1234!`

### 司機端
- Email: `driver.test@relaygo.com`
- Password: `Test1234!`

### 管理員
- Email: `admin@relaygo.com`
- Password: `Admin1234!`

---

## 🎯 成功標準

### 完整流程測試通過
- ✅ 客戶端創建訂單成功
- ✅ 公司端手動派單成功
- ✅ 司機端顯示「確認接單」按鈕
- ✅ 司機點擊按鈕成功確認接單
- ✅ 訂單狀態正確更新
- ✅ 聊天室自動創建
- ✅ 所有資料庫狀態一致

### 自動化程度
- ✅ 100% 自動化 - 無需手動編寫代碼
- ✅ 自動顯示 - 按鈕根據狀態自動顯示/隱藏
- ✅ 自動刷新 - 訂單狀態自動更新
- ✅ 自動同步 - 多資料庫自動同步

---

## 🎉 總結

**所有功能已自動化完成！**

只需按照測試步驟操作，即可驗證功能是否正常運作。

如果遇到問題，請參考「常見問題排查」部分。

