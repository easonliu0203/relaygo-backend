# 🚨 支付訂金錯誤 - 快速修復

**錯誤**: `Could not find the 'payment_type' column of 'payments' in the schema cache`  
**狀態**: ✅ 已修復

---

## ⚡ 立即執行步驟

### 步驟 1: 重新啟動管理後台

```bash
cd web-admin
npm run dev
```

### 步驟 2: 測試支付訂金功能

**使用客戶端應用**:
1. 啟動客戶端應用
2. 創建新訂單
3. 完成支付訂金
4. ✅ 應該不再出現錯誤

**使用 curl 測試**:
```bash
curl -X POST http://localhost:3001/api/bookings/YOUR_BOOKING_ID/pay-deposit \
  -H "Content-Type: application/json" \
  -d '{
    "paymentMethod": "credit_card",
    "customerUid": "YOUR_FIREBASE_UID"
  }' \
  -v
```

**預期結果**:
```json
{
  "success": true,
  "data": {
    "paymentId": "...",
    "transactionId": "mock_...",
    "amount": 15,
    "status": "processing",
    "isAutoPayment": true,
    "estimatedProcessingTime": 5,
    "expiresAt": "..."
  }
}
```

---

## 🔧 已完成的修復

### 修復的文件

**`web-admin/src/app/api/bookings/[id]/pay-deposit/route.ts`**

**修改 1** (第 98 行):
```typescript
// ❌ 修復前
.eq('payment_type', 'deposit')

// ✅ 修復後
.eq('type', 'deposit')
```

**修改 2** (第 133 行):
```typescript
// ❌ 修復前
const paymentData = {
  booking_id: bookingId,
  payment_type: 'deposit',  // ❌ 欄位名稱錯誤
  amount: booking.deposit_amount,
  ...
};

// ✅ 修復後
const paymentData = {
  booking_id: bookingId,
  customer_id: booking.customer.id,  // ✅ 添加必填欄位
  type: 'deposit',  // ✅ 正確的欄位名稱
  amount: booking.deposit_amount,
  currency: 'TWD',  // ✅ 添加 currency 欄位
  ...
};
```

---

## 🔍 問題根源

### Supabase Schema

**文件**: `supabase/fix-schema-complete.sql`

```sql
CREATE TABLE IF NOT EXISTS payments (
  ...
  type VARCHAR(20) NOT NULL CHECK (type IN ('deposit', 'balance', 'refund')),
  -- ✅ 欄位名稱是 'type'，不是 'payment_type'
  ...
);
```

### 後端 API（修復前）

**文件**: `web-admin/src/app/api/bookings/[id]/pay-deposit/route.ts`

```typescript
// ❌ 使用 'payment_type'（錯誤）
payment_type: 'deposit'
```

### 不匹配導致錯誤

- Supabase Schema: `type`
- 後端 API: `payment_type`
- 結果: `Could not find the 'payment_type' column`

---

## ✅ 驗證修復

### 方法 1: 使用測試腳本

```bash
chmod +x test-payment-fix.sh
./test-payment-fix.sh
```

### 方法 2: 檢查 Supabase 資料庫

**在 Supabase SQL Editor 中執行**:
```sql
-- 執行驗證腳本
\i supabase/verify-payments-schema.sql

-- 或手動檢查
SELECT * FROM payments 
WHERE booking_id = 'YOUR_BOOKING_ID' 
ORDER BY created_at DESC 
LIMIT 1;
```

**預期結果**:
- ✅ 有一筆支付記錄
- ✅ `type` 欄位值為 `'deposit'`
- ✅ `customer_id` 欄位有值
- ✅ `status` 欄位值為 `'processing'` 或 `'completed'`

### 方法 3: 檢查管理後台日誌

**啟動管理後台並查看日誌**:
```
✅ 查詢到訂單: { id: '...', status: 'pending', ... }
✅ 客戶身份驗證通過
✅ 訂單狀態檢查通過
✅ 支付檢查通過，準備創建支付記錄
✅ 支付記錄創建成功: { id: '...', transaction_id: 'mock_...', ... }
⏱️  模擬支付將在 5 秒後完成
✅ 支付 API 處理完成，返回結果
```

**不應該看到**:
```
❌ 創建支付記錄失敗: Could not find the 'payment_type' column
```

---

## 🔍 如果仍有問題

### 問題 1: 仍然出現 `payment_type` 錯誤

**可能原因**: 管理後台沒有重新啟動

**解決**:
```bash
# 停止管理後台 (Ctrl+C)
# 重新啟動
cd web-admin
npm run dev
```

### 問題 2: 出現 `customer_id` 錯誤

**錯誤訊息**: `null value in column "customer_id" violates not-null constraint`

**可能原因**: `booking.customer` 是 null

**解決**: 檢查訂單查詢是否正確包含客戶資訊
```typescript
.select(`
  id,
  status,
  deposit_amount,
  total_amount,
  customer:customer_id (
    id,
    firebase_uid
  )
`)
```

### 問題 3: 訂單不存在

**錯誤訊息**: `訂單不存在`

**可能原因**: 訂單 ID 錯誤或訂單已被刪除

**解決**: 
1. 創建新訂單
2. 使用新訂單的 ID 測試支付

---

## 📊 修復對比

| 項目 | 修復前 | 修復後 |
|------|--------|--------|
| **欄位名稱** | `payment_type` ❌ | `type` ✅ |
| **customer_id** | 缺少 ❌ | 已添加 ✅ |
| **currency** | 缺少 ❌ | 已添加 ✅ |
| **API 狀態** | HTTP 500 ❌ | HTTP 200 ✅ |
| **支付記錄** | 創建失敗 ❌ | 創建成功 ✅ |

---

## 📚 詳細文檔

查看完整說明: `docs/20251009_0000_19_支付訂金API欄位名稱錯誤修復.md`

---

## 🎉 預期效果

1. ✅ 支付訂金 API 正常工作
2. ✅ 支付記錄成功創建在 Supabase
3. ✅ 訂單狀態正確更新為 `'confirmed'`
4. ✅ 客戶端應用不出現錯誤
5. ✅ 導航到預約成功頁面

---

## 💡 為什麼會出現這個錯誤?

**Schema 不一致**:
- 不同的 schema 文件使用不同的欄位名稱
- `database/schema.sql` 使用 `payment_type`
- `supabase/fix-schema-complete.sql` 使用 `type`
- Supabase 實際使用的是後者

**教訓**:
- 確保代碼和資料庫 schema 一致
- 使用單一的 schema 定義文件
- 定期檢查和驗證

---

**需要幫助?** 查看 `docs/20251009_0000_19_支付訂金API欄位名稱錯誤修復.md` 獲取詳細說明!

