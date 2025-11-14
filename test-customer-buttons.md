# 客戶端按鈕顯示測試指南

## 快速測試步驟

### 1. 重新編譯 Flutter App

```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

### 2. 測試場景

#### 場景 A: 司機已出發（driver_departed）

**預期 Firestore 狀態**: `ON_THE_WAY`

**預期客戶端顯示**:
- ✅ 司機資訊卡片
- ✅ **「開始行程 🚀」按鈕**（綠色）
- ❌ 「結束行程」按鈕（不顯示）

**測試方法**:
1. 司機端點擊「出發前往載客」
2. 等待 3-5 秒讓 Firestore 同步
3. 檢查客戶端訂單詳情頁面

---

#### 場景 B: 司機已到達（driver_arrived）

**預期 Firestore 狀態**: `ON_THE_WAY`

**預期客戶端顯示**:
- ✅ 司機資訊卡片
- ✅ **「開始行程 🚀」按鈕**（綠色）
- ❌ 「結束行程」按鈕（不顯示）

**測試方法**:
1. 司機端點擊「抵達上車地點」
2. 等待 3-5 秒讓 Firestore 同步
3. 檢查客戶端訂單詳情頁面

---

#### 場景 C: 行程已開始（trip_started）

**預期 Firestore 狀態**: `inProgress`

**預期客戶端顯示**:
- ✅ 司機資訊卡片
- ❌ 「開始行程」按鈕（不顯示）
- ✅ **「結束行程 🏁」按鈕**（橙色）

**測試方法**:
1. 客戶端點擊「開始行程」
2. 等待 3-5 秒讓 Firestore 同步
3. 檢查客戶端訂單詳情頁面

---

## 調試工具

### 檢查 Firestore 狀態

在 Firebase Console 中查看：
1. 打開 Firestore
2. 進入 `orders_rt` 集合
3. 找到對應的訂單文檔
4. 檢查 `status` 欄位

### 檢查 Supabase 狀態

運行 SQL 查詢：
```sql
SELECT 
  id,
  booking_number,
  status,
  updated_at
FROM bookings
WHERE booking_number = '<你的訂單編號>'
ORDER BY updated_at DESC
LIMIT 1;
```

### 檢查 Outbox 事件

運行 SQL 查詢：
```sql
SELECT 
  id,
  aggregate_type,
  event_type,
  payload->>'status' as status,
  created_at,
  processed_at,
  error_message
FROM outbox
WHERE aggregate_id = '<訂單 ID>'
ORDER BY created_at DESC
LIMIT 5;
```

---

## 常見問題排查

### Q1: 按鈕沒有顯示

**可能原因**:
1. Flutter App 沒有重新編譯
2. Firestore 狀態沒有正確同步
3. 訂單狀態不正確

**解決方法**:
1. 完全停止並重新啟動 Flutter App
2. 檢查 Firestore 中的訂單狀態
3. 檢查 Supabase 中的訂單狀態
4. 檢查 outbox 表中是否有未處理的事件

### Q2: 按鈕顯示錯誤

**可能原因**:
1. 狀態映射不正確
2. Firestore 數據過期

**解決方法**:
1. 檢查 `supabase/functions/sync-to-firestore/index.ts` 中的狀態映射
2. 手動觸發同步：`node force-sync-order.js <訂單編號>`

### Q3: 點擊按鈕後沒有反應

**可能原因**:
1. Backend API 沒有運行
2. 網絡連接問題
3. 權限驗證失敗

**解決方法**:
1. 檢查 Backend 是否正在運行
2. 檢查 Flutter App 的網絡連接
3. 查看 Backend 日誌中的錯誤訊息

---

## 完整測試流程

### 步驟 1: 準備環境

```bash
# 1. 啟動 Backend
cd backend
npm run dev

# 2. 重新編譯 Flutter App
cd ../mobile
flutter clean
flutter pub get
flutter run
```

### 步驟 2: 創建測試訂單

1. 客戶端創建新訂單
2. 支付訂金
3. 公司端派單給司機

### 步驟 3: 測試司機操作

1. 司機端確認接單
2. 司機端點擊「出發前往載客」
3. 檢查客戶端是否顯示「開始行程」按鈕
4. 司機端點擊「抵達上車地點」
5. 檢查客戶端是否仍然顯示「開始行程」按鈕

### 步驟 4: 測試客戶操作

1. 客戶端點擊「開始行程」
2. 檢查是否成功開始行程
3. 檢查是否顯示「結束行程」按鈕
4. 客戶端點擊「結束行程」
5. 檢查是否成功結束行程
6. 檢查是否顯示「支付尾款」按鈕

---

## 預期結果

| 訂單狀態 (Supabase) | Firestore 狀態 | 客戶端顯示 |
|-------------------|---------------|----------|
| `driver_confirmed` | `matched` | 司機資訊 |
| `driver_departed` | `ON_THE_WAY` | 司機資訊 + **開始行程按鈕** |
| `driver_arrived` | `ON_THE_WAY` | 司機資訊 + **開始行程按鈕** |
| `trip_started` | `inProgress` | 司機資訊 + **結束行程按鈕** |
| `trip_ended` | `awaitingBalance` | 司機資訊 + **支付尾款按鈕** |

---

## 成功標準

- ✅ 所有按鈕在正確的狀態下顯示
- ✅ 點擊按鈕後狀態正確更新
- ✅ Firestore 狀態與 Supabase 狀態保持同步
- ✅ 聊天室收到系統訊息
- ✅ 沒有錯誤訊息

