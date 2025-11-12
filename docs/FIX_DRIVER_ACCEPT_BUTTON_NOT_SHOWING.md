# 🔧 修復司機端「確認接單」按鈕不顯示問題

**日期**：2025-01-12  
**問題**：手動派單後，司機端沒有顯示「確認接單」按鈕  
**預計修復時間**：10 分鐘

---

## 🔍 根本原因

### 最可能的原因：Edge Function 未部署 ⚠️

**問題分析**：
- 您已經修改了 Edge Function 的狀態映射（`'matched'` → `'pending'`）
- 但**尚未部署** Edge Function 到 Supabase
- 因此 Firestore 中的訂單狀態仍然是 `'matched'`（使用舊的映射）
- Flutter APP 的按鈕顯示邏輯檢查訂單狀態是否為 `'pending'`
- 由於狀態是 `'matched'`，按鈕不顯示

**當前狀態流程**（使用舊的 Edge Function）：
```
手動派單
  ↓
Supabase: status = 'matched'
  ↓
Edge Function（舊版本）: 'matched' → 'matched'
  ↓
Firestore: status = 'matched' ❌
  ↓
Flutter APP: 檢查 status == 'pending' → false
  ↓
按鈕不顯示 ❌
```

**預期狀態流程**（部署新的 Edge Function 後）：
```
手動派單
  ↓
Supabase: status = 'matched'
  ↓
Edge Function（新版本）: 'matched' → 'pending'
  ↓
Firestore: status = 'pending' ✅
  ↓
Flutter APP: 檢查 status == 'pending' → true
  ↓
按鈕顯示 ✅
```

---

## ✅ 快速修復步驟

### 步驟 1：診斷當前狀態（5 分鐘）

#### 1.1 執行診斷 SQL 腳本

**文件**：`supabase/diagnose-driver-accept-button-issue.sql`

**執行步驟**：
1. 打開 Supabase Dashboard
2. 進入 SQL Editor
3. 複製 `supabase/diagnose-driver-accept-button-issue.sql` 的內容
4. 貼上並執行

**重點檢查**：
- **步驟 2**：確認訂單狀態是否為 `'matched'` 或 `'assigned'`
- **步驟 2**：記下司機的 Firebase UID（用於 Flutter APP 測試）
- **步驟 3**：確認 outbox 記錄是否已處理（`processed_at` 不為 NULL）
- **步驟 5**：確認 Edge Function 處理延遲是否正常（< 60 秒）

#### 1.2 檢查 Firestore 訂單狀態

**Firebase Console**：
1. 打開 Firebase Console
2. 進入 Firestore Database
3. 查看 `orders_rt` collection
4. 找到測試訂單
5. 檢查 `status` 欄位的值

**預期結果**：
- 如果 Edge Function 未部署：`status: 'matched'` ❌
- 如果 Edge Function 已部署：`status: 'pending'` ✅

---

### 步驟 2：部署 Edge Function（5 分鐘）⚠️ **必須執行**

#### 2.1 使用 Supabase Dashboard 部署

**步驟**：
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

4. **確認狀態映射已修改**
   - 找到第 327-344 行
   - 確認包含以下內容：
     ```typescript
     'assigned': 'pending',          // ✅ 修改
     'matched': 'pending',            // ✅ 修改
     'driver_confirmed': 'matched',   // ✅ 保持
     ```

5. **部署函數**
   - 點擊「Deploy」或「Save」
   - 等待部署完成（約 10-30 秒）

6. **驗證部署**
   - 檢查部署狀態是否為「Active」
   - 查看最近的日誌，確認沒有錯誤

---

### 步驟 3：手動觸發 Edge Function 處理現有訂單（可選）

如果您想立即更新現有訂單的狀態，可以手動觸發 Edge Function：

#### 3.1 手動觸發 Edge Function

**方法 1：使用 Supabase Dashboard**
1. 進入 Edge Functions
2. 找到 `sync-to-firestore` 函數
3. 點擊「Invoke」或「Test」
4. 輸入測試參數（如果需要）
5. 點擊「Run」

**方法 2：更新訂單觸發 Trigger**
1. 打開 Supabase Dashboard
2. 進入 SQL Editor
3. 執行以下 SQL（更新訂單的 `updated_at` 欄位）：
   ```sql
   UPDATE bookings
   SET updated_at = NOW()
   WHERE status = 'matched'
     AND driver_id IS NOT NULL;
   ```
4. 這會觸發 Trigger，寫入新的 outbox 記錄
5. Edge Function 會自動處理新的 outbox 記錄
6. Firestore 中的訂單狀態會更新為 `'pending'`

---

### 步驟 4：驗證修復（2 分鐘）

#### 4.1 檢查 Firestore 訂單狀態

**Firebase Console**：
1. 刷新 Firestore Database
2. 查看測試訂單的 `status` 欄位
3. 確認狀態已更新為 `'pending'`

#### 4.2 檢查司機端 APP

**Flutter APP**：
1. 打開司機端 APP
2. 進入「我的訂單」>「進行中」
3. 點擊測試訂單
4. 確認顯示「確認接單」按鈕

**如果按鈕仍然不顯示**：
- 檢查 Flutter APP 是否已實作 `_shouldShowAcceptButton()` 方法
- 檢查按鈕顯示邏輯是否正確
- 添加日誌輸出，確認訂單狀態和司機 ID

---

## 🧪 測試完整流程

### 測試 1：新訂單的完整流程

1. **創建新訂單**
   - 在客戶端 APP 創建新訂單
   - 完成訂金支付

2. **手動派單**
   - 在公司端 Web Admin 手動派單給司機

3. **檢查 Supabase 狀態**
   - 執行診斷 SQL 腳本
   - 確認訂單狀態為 `'matched'`

4. **檢查 Firestore 狀態**
   - 打開 Firebase Console
   - 確認訂單狀態為 `'pending'`（新的 Edge Function 已部署）

5. **檢查司機端 APP**
   - 打開司機端 APP
   - 確認顯示「待配對」狀態
   - 確認顯示「確認接單」按鈕

6. **司機確認接單**
   - 點擊「確認接單」按鈕
   - 確認顯示成功訊息
   - 確認訂單狀態更新為「已配對」

---

## 📊 診斷檢查清單

### ✅ Supabase 檢查

- [ ] 訂單狀態為 `'matched'` 或 `'assigned'`
- [ ] 訂單已分配給司機（`driver_id` 不為 NULL）
- [ ] outbox 記錄已創建
- [ ] outbox 記錄已處理（`processed_at` 不為 NULL）

### ✅ Edge Function 檢查

- [ ] Edge Function 已部署最新版本
- [ ] 狀態映射已修改：`'matched'` → `'pending'`
- [ ] Edge Function 部署狀態為「Active」
- [ ] Edge Function 日誌沒有錯誤

### ✅ Firestore 檢查

- [ ] 訂單存在於 `orders_rt` collection
- [ ] 訂單狀態為 `'pending'`（新的 Edge Function）或 `'matched'`（舊的 Edge Function）
- [ ] 訂單的 `driverId` 等於司機的 Firebase UID

### ✅ Flutter APP 檢查

- [ ] `_shouldShowAcceptButton()` 方法已實作
- [ ] 按鈕顯示邏輯正確（檢查 `status == 'pending'` 和 `driverId == currentDriverId`）
- [ ] StreamBuilder 正確監聽訂單狀態變化
- [ ] 按鈕 UI 已添加到訂單詳情頁面

---

## 🚨 常見問題

### 問題 1：Edge Function 部署後，Firestore 狀態仍然是 'matched'

**可能原因**：
- Edge Function 尚未處理現有的 outbox 記錄
- 需要手動觸發 Edge Function

**解決方案**：
1. 執行步驟 3.1（手動觸發 Edge Function）
2. 或者更新訂單的 `updated_at` 欄位，觸發新的 outbox 記錄

### 問題 2：按鈕仍然不顯示

**可能原因**：
- Flutter APP 的 `_shouldShowAcceptButton()` 方法尚未實作
- 按鈕顯示邏輯錯誤
- 訂單的 `driverId` 與當前司機的 Firebase UID 不匹配

**解決方案**：
1. 檢查 Flutter APP 代碼
2. 添加日誌輸出，確認訂單狀態和司機 ID
3. 參考 `docs/FLUTTER_DRIVER_ACCEPT_BOOKING_CODE_EXAMPLE.md`

### 問題 3：outbox 記錄未處理

**可能原因**：
- Edge Function 未啟用或未部署
- Edge Function 執行失敗

**解決方案**：
1. 檢查 Edge Function 部署狀態
2. 查看 Edge Function 日誌
3. 手動觸發 Edge Function

---

## 📝 總結

**問題根本原因**：
- Edge Function 未部署，導致 Firestore 訂單狀態仍然是 `'matched'`
- Flutter APP 檢查訂單狀態是否為 `'pending'`，因此按鈕不顯示

**修復步驟**：
1. ✅ 執行診斷 SQL 腳本（確認當前狀態）
2. ⚠️ 部署 Edge Function（必須執行）
3. ✅ 手動觸發 Edge Function（可選，用於更新現有訂單）
4. ✅ 驗證修復（檢查 Firestore 和 Flutter APP）

**預期效果**：
- ✅ Firestore 訂單狀態為 `'pending'`
- ✅ 司機端 APP 顯示「待配對」狀態
- ✅ 司機端 APP 顯示「確認接單」按鈕

**下一步**：
1. 立即部署 Edge Function
2. 驗證 Firestore 訂單狀態
3. 測試司機端 APP

---

**修復完成時間**：2025-01-12  
**修復者**：Augment Agent  
**狀態**：修復指南已完成

