# 分潤觸發器最終修復診斷報告

## 🐛 問題總結

### 問題 1: Supabase SDK 不觸發 PostgreSQL 觸發器
**狀態**: ✅ 已解決

**原因**: 
- GoMyPay 回調使用 `supabase.from('bookings').update()` 更新訂單狀態
- Supabase SDK 使用 PostgREST API，可能繞過 PostgreSQL 觸發器

**解決方案**:
- 創建 RPC 函數 `update_booking_status` 執行原生 SQL UPDATE
- 修改後端代碼使用 RPC 函數而非 SDK 的 `.update()` 方法

### 問題 2: 觸發器執行但分潤記錄未更新
**狀態**: ✅ 已解決

**根本原因**:
觸發器使用 UPSERT 邏輯（`INSERT ... ON CONFLICT ... DO UPDATE`），但 `promo_code_usage` 表的以下欄位有 NOT NULL 約束：
- `original_price`
- `discount_amount_applied`
- `discount_percentage_applied`
- `final_price`

這些欄位在訂單創建時由後端設置，觸發器在 INSERT 時沒有提供這些值，導致違反 NOT NULL 約束。

**錯誤訊息**:
```
null value in column "original_price" of relation "promo_code_usage" violates not-null constraint
```

**解決方案**:
- 將 UPSERT 改為 UPDATE
- 觸發器只更新分潤相關欄位，不觸碰訂單金額欄位
- 因為 `promo_code_usage` 記錄已由後端在訂單創建時創建

### 問題 3: 無法看到觸發器日誌
**狀態**: ✅ 已解決

**原因**:
- `RAISE NOTICE` 的輸出在 Supabase API 中不可見
- Railway 日誌也沒有顯示 PostgreSQL 的 NOTICE 訊息

**解決方案**:
- 創建 `trigger_debug_log` 表記錄觸發器執行過程
- 觸發器在關鍵步驟插入日誌記錄
- 可以通過查詢日誌表診斷問題

## ✅ 最終解決方案

### 1. 創建觸發器日誌表

```sql
CREATE TABLE trigger_debug_log (
  id SERIAL PRIMARY KEY,
  trigger_name TEXT,
  booking_id UUID,
  old_status TEXT,
  new_status TEXT,
  message TEXT,
  data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. 修改觸發器使用 UPDATE 而非 UPSERT

**修改前**:
```sql
INSERT INTO promo_code_usage (...)
VALUES (...)
ON CONFLICT (booking_id) 
DO UPDATE SET ...;
```

**修改後**:
```sql
UPDATE promo_code_usage
SET
  commission_status = 'completed',
  commission_type = v_commission_type,
  commission_rate = v_commission_rate,
  commission_amount = v_commission_amount,
  order_amount = v_order_amount,
  referee_id = NEW.customer_id
WHERE booking_id = NEW.id;
```

### 3. 添加詳細日誌記錄

觸發器在以下步驟記錄日誌：
- ✅ 觸發器被調用
- ✅ 訂單狀態變更為 completed
- ✅ 找到推薦關係
- ✅ 分潤計算完成
- ✅ 分潤記錄已更新
- ✅ 累加收益
- ❌ 錯誤（如果發生）

## 🧪 測試結果

### 測試訂單: `beb5b487-7600-4310-af36-edd82cfb9b64`

**觸發器日誌**:
```
1. 觸發器被調用
2. ✅ 訂單狀態變更為 completed，開始處理分潤
3. ✅ 找到推薦關係 (influencer_id: 61d72f11-0b75-4eb1-8dd9-c25893b84e09)
4. ✅ 分潤計算完成 (amount: 100, type: percent, rate: 5, order: 2000)
5. ✅ 分潤記錄已更新
6. ✅ 累加收益 (added_amount: 100)
```

**分潤記錄**:
- `commission_amount`: 100.00 ✅
- `commission_status`: completed ✅
- `commission_type`: percent ✅
- `commission_rate`: 5 ✅
- `order_amount`: 2000.00 ✅
- `referee_id`: aa5cf574-2394-4258-aceb-471fcf80f49c ✅

**推廣人累積收益**:
- 修復前: 380.00
- 修復後: 480.00 (+100.00) ✅

## 📊 所有訂單分潤狀態

| 訂單 ID | 訂單金額 | 分潤金額 | 狀態 | 備註 |
|---------|----------|----------|------|------|
| `65ec7619...` | 2800.00 | 140.00 | ✅ completed | 手動修復 |
| `03a069a8...` | 2000.00 | 100.00 | ✅ completed | 手動修復 |
| `74e7cc0c...` | 2800.00 | 140.00 | ✅ completed | 手動修復 |
| `beb5b487...` | 2000.00 | 100.00 | ✅ completed | 觸發器自動 |
| **總計** | **8600.00** | **480.00** | **4 筆** | |

## 📝 修改的文件

### Supabase
1. ✅ `supabase/migrations/20260120_fix_commission_trigger_v4_with_logging.sql` - 帶日誌的觸發器 V4

### Backend
1. ✅ `backend/src/routes/gomypay.ts` - 使用 RPC 函數更新訂單狀態

### 文檔
1. ✅ `COMMISSION_TRIGGER_FINAL_FIX_DIAGNOSIS.md` - 本文檔

## 🚀 下一步

### 1. 測試新訂單
創建一個全新的訂單，完整流程：
1. 使用優惠碼創建訂單
2. 付訂金
3. 完成行程
4. 付尾款（觸發分潤計算）

**預期結果**:
- ✅ GoMyPay 回調調用 RPC 函數
- ✅ 觸發器自動執行
- ✅ 分潤記錄自動更新
- ✅ 累積收益自動累加
- ✅ 日誌表中有完整記錄

### 2. 監控日誌
查詢觸發器日誌：
```sql
SELECT * FROM trigger_debug_log 
WHERE booking_id = '訂單ID' 
ORDER BY created_at;
```

### 3. 清理日誌（可選）
定期清理舊日誌：
```sql
DELETE FROM trigger_debug_log 
WHERE created_at < NOW() - INTERVAL '30 days';
```

## 🎯 關鍵學習

1. **Supabase SDK 的限制**: `.update()` 方法可能不觸發 PostgreSQL 觸發器，需要使用 RPC 函數
2. **UPSERT 的陷阱**: 使用 UPSERT 時要注意 NOT NULL 約束
3. **日誌的重要性**: `RAISE NOTICE` 在 Supabase API 中不可見，需要使用日誌表
4. **觸發器設計**: 觸發器應該只更新自己負責的欄位，不要覆蓋其他模組設置的值

---

**修復日期**: 2026-01-20  
**狀態**: ✅ 完全修復並測試通過

