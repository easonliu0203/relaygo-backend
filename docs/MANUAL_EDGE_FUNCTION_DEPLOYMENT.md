# 🚀 手動部署 Edge Function 指南

**日期**：2025-01-12  
**目的**：部署 `sync-to-firestore` Edge Function  
**預計時間**：5 分鐘

---

## ✅ Backend API 已成功啟動

**狀態**：✅ 已完成

```
✅ Server is running on port 3000
   Health check: http://localhost:3000/health
   API endpoints:
     - POST /api/bookings (創建訂單)
     - POST /api/bookings/:id/pay-deposit (支付訂金)
     - POST /api/booking-flow/bookings/:id/accept (司機確認接單)
```

**Terminal ID**：3

---

## 📋 Edge Function 部署選項

由於 Supabase CLI 未安裝，您有兩個選項來部署 Edge Function：

### 選項 1：使用 Supabase Dashboard（推薦）⭐

**優點**：
- ✅ 不需要安裝 Supabase CLI
- ✅ 直接在瀏覽器中操作
- ✅ 立即生效

**步驟**：

1. **打開 Supabase Dashboard**
   - 網址：https://supabase.com/dashboard
   - 登入您的帳號
   - 選擇您的專案

2. **進入 Edge Functions**
   - 左側選單 > Edge Functions
   - 找到 `sync-to-firestore` 函數
   - 如果沒有，點擊「Create a new function」

3. **更新函數代碼**
   - 點擊 `sync-to-firestore` 函數
   - 點擊「Edit」或「Code」標籤
   - 刪除現有代碼
   - 複製 `supabase/functions/sync-to-firestore/index.ts` 的全部內容
   - 貼上到編輯器中

4. **保存並部署**
   - 點擊「Save」
   - 點擊「Deploy」
   - 等待部署完成（約 30 秒）

5. **驗證部署**
   - 查看部署狀態：應該顯示「Deployed」
   - 查看函數日誌：確認沒有錯誤

---

### 選項 2：安裝 Supabase CLI 並部署

**優點**：
- ✅ 可以使用命令行部署
- ✅ 適合頻繁更新

**步驟**：

1. **安裝 Supabase CLI**
   ```bash
   npm install -g supabase
   ```

2. **登入 Supabase**
   ```bash
   supabase login
   ```

3. **連結專案**
   ```bash
   cd d:\repo
   supabase link
   ```
   
   選擇您的專案（會提示輸入專案 ID 或從列表中選擇）

4. **部署 Edge Function**
   ```bash
   cd supabase
   supabase functions deploy sync-to-firestore
   ```

5. **驗證部署**
   ```bash
   supabase functions list
   ```
   
   應該看到 `sync-to-firestore` 的狀態為「Deployed」

---

## 🔍 Edge Function 代碼修改摘要

**文件**：`supabase/functions/sync-to-firestore/index.ts`

**修改內容**：添加狀態映射邏輯（第 320-343 行）

**修改前**：
```typescript
status: bookingData.status || 'pending',
```

**修改後**：
```typescript
// 狀態映射：將 Supabase 狀態轉換為 Flutter APP 期望的狀態
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

**修改效果**：
- ✅ Firestore 中的訂單狀態會被轉換為 Flutter APP 期望的格式
- ✅ 「進行中」頁面應該可以顯示訂單

---

## ✅ 部署後驗證步驟

### 步驟 1：檢查 Edge Function 狀態

**使用 Supabase Dashboard**：
1. 進入 Edge Functions
2. 查看 `sync-to-firestore` 的狀態
3. 確認狀態為「Deployed」
4. 查看最後部署時間（應該是剛剛）

### 步驟 2：測試訂單同步

1. **創建新的測試訂單**
   - 打開客戶端 APP
   - 創建一個新的訂單
   - 完成付款（測試模式）

2. **檢查 Firestore**
   - 打開 Firebase Console
   - 進入 Firestore Database
   - 查看 `orders_rt` collection
   - 找到剛創建的訂單

3. **驗證訂單狀態**
   ```json
   {
     "status": "pending",  // ✅ 應該是 'pending'，不是 'pending_payment'
     "customerId": "...",
     "bookingTime": "...",
     ...
   }
   ```

### 步驟 3：測試「進行中」頁面

1. 打開客戶端 APP
2. 進入「我的訂單」>「進行中」頁面
3. ✅ 確認可以看到剛創建的訂單

---

## 🎉 完成檢查清單

完成部署後，請確認以下項目：

- [ ] **Backend API**：✅ 已重新啟動（Terminal 3，端口 3000）
- [ ] **Edge Function**：已部署（使用 Dashboard 或 CLI）
- [ ] **Edge Function 狀態**：Deployed
- [ ] **測試訂單**：已創建
- [ ] **Firestore 狀態**：訂單狀態是 `'pending'`
- [ ] **進行中頁面**：可以看到訂單

---

## 🚨 常見問題

### Q1：Supabase Dashboard 找不到 sync-to-firestore 函數

**解決方案**：
1. 點擊「Create a new function」
2. 函數名稱：`sync-to-firestore`
3. 複製 `supabase/functions/sync-to-firestore/index.ts` 的內容
4. 貼上並保存
5. 點擊「Deploy」

---

### Q2：部署後訂單狀態仍然是 'pending_payment'

**可能原因**：
1. Edge Function 沒有被觸發
2. 舊訂單沒有重新同步

**解決方案**：
1. 創建新的測試訂單（舊訂單不會自動更新）
2. 檢查 Edge Function 日誌（Supabase Dashboard > Edge Functions > Logs）
3. 確認 Edge Function 有被觸發

---

### Q3：如何查看 Edge Function 日誌？

**步驟**：
1. 打開 Supabase Dashboard
2. 進入 Edge Functions
3. 點擊 `sync-to-firestore`
4. 點擊「Logs」標籤
5. 查看最近的執行日誌

**預期日誌**：
```
處理事件: xxx, 類型: created, 聚合: xxx
同步訂單到 Firestore: xxx
轉換後的 Firestore 資料: { status: 'pending', ... }
✅ 雙寫成功: orders_rt/xxx 和 bookings/xxx
事件 xxx 處理成功
```

---

## 📞 需要幫助？

如果您在部署過程中遇到任何問題，請提供以下資訊：

1. **使用的部署方式**：Dashboard 或 CLI
2. **錯誤訊息**：完整的錯誤訊息（如果有）
3. **Edge Function 日誌**：最近的執行日誌
4. **Firestore 資料**：訂單的實際狀態

我會立即協助您解決！🎉

---

**修復完成時間**：2025-01-12  
**修復者**：Augment Agent  
**狀態**：Backend API 已重新啟動，等待 Edge Function 部署

