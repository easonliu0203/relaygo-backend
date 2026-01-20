# 推薦系統業務邏輯分析報告

## 📋 業務邏輯要求回顧

### 場景 1: 客戶 B 第一次使用推廣人 A 的優惠碼
- ✅ 在 `referrals` 表中建立 A→B 的推薦關係（終身綁定）
- ✅ B 享受折扣
- ✅ 當 B 的訂單完成時，A 獲得分潤

### 場景 2: 客戶 B 後續繼續使用推廣人 A 的優惠碼
- ✅ 不改變現有的 A→B 推薦關係
- ✅ B 享受折扣
- ✅ 當 B 的訂單完成時，A 獲得分潤

### 場景 3: 客戶 B 使用其他推廣人 C 的優惠碼
- ✅ 不改變現有的 A→B 推薦關係（終身綁定）
- ✅ B 享受 C 的優惠碼折扣
- ✅ 當 B 的訂單完成時，**A（而非 C）獲得分潤**

## 🔍 代碼實現分析

### 1. 推薦關係建立邏輯 (`backend/src/routes/bookings.ts` 第 326-391 行)

#### ✅ 正確實現的部分

**使用正確的 ID**:
```typescript
// 第 333 行：正確使用 customer.id (users.id)
.eq('referee_id', customer.id)

// 第 353 行：正確使用 customer.id
referee_id: customer.id, // ✅ 使用 users.id，不是 firebase_uid
```

**終身綁定邏輯**:
```typescript
// 第 330-334 行：檢查是否已有推薦關係
const { data: existingReferral } = await supabase
  .from('referrals')
  .select('id')
  .eq('referee_id', customer.id)
  .single();

// 第 336 行：只在沒有推薦關係時才建立
if (!existingReferral) {
  // 建立推薦關係
}
```

**場景 1 & 2**: ✅ **正確實現**
- 首次使用優惠碼時建立推薦關係
- 後續使用相同優惠碼時不改變推薦關係

### 2. 分潤觸發器邏輯 (`supabase/migrations/20260120_fix_commission_trigger_v4_with_logging.sql`)

#### ✅ 正確實現的部分

**查找推薦關係**:
```sql
-- 第 45 行：根據客戶 ID 查找推薦關係
SELECT * INTO v_referral FROM referrals WHERE referee_id = NEW.customer_id LIMIT 1;
```

**使用推薦關係中的推廣人**:
```sql
-- 第 59 行：使用推薦關係中的 influencer_id，而非訂單的 influencer_id
SELECT * INTO v_influencer FROM influencers WHERE id = v_referral.influencer_id AND is_active = true LIMIT 1;
```

**更新分潤記錄**:
```sql
-- 第 92-100 行：更新分潤記錄
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

**累加收益給推薦關係中的推廣人**:
```sql
-- 第 107 行：給 v_influencer（來自推薦關係）累加收益
UPDATE influencers SET total_earnings = total_earnings + v_commission_amount WHERE id = v_influencer.id;
```

**場景 3**: ✅ **正確實現**
- 觸發器查找 `referrals` 表中的推薦關係
- 使用推薦關係中的 `influencer_id`（A），而非訂單的 `influencer_id`（C）
- 分潤給 A，而非 C

## ⚠️ 發現的問題

### 問題 1: 數據一致性問題

**現象**:
在場景 3 中，會出現以下數據不一致：

| 欄位 | 值 | 說明 |
|------|-----|------|
| `bookings.influencer_id` | C | 訂單使用的優惠碼屬於 C |
| `bookings.promo_code` | C 的優惠碼 | 客戶使用的優惠碼 |
| `promo_code_usage.influencer_id` | C | 後端創建記錄時使用訂單的 influencer_id |
| **實際分潤對象** | **A** | 觸發器根據推薦關係給 A 分潤 |

**問題**:
- `promo_code_usage.influencer_id` 記錄的是 C
- 但實際分潤給的是 A
- 這會導致報表和統計數據混亂

### 問題 2: 後端創建 promo_code_usage 記錄的邏輯

**當前實現** (`backend/src/routes/bookings.ts` 第 306-317 行):
```typescript
const { error: usageError } = await supabase
  .from('promo_code_usage')
  .insert({
    influencer_id: influencerId,  // ⚠️ 使用訂單的 influencer_id（C）
    booking_id: booking.id,
    promo_code: promoCode,
    original_price: actualOriginalPrice,
    discount_amount_applied: actualDiscountAmount,
    discount_percentage_applied: 0,
    final_price: actualFinalPrice,
    commission_amount: influencerCommission || 0,
  });
```

**問題**:
- 在場景 3 中，`influencer_id` 會是 C
- 但觸發器會給 A 分潤
- 導致 `promo_code_usage.influencer_id` 與實際分潤對象不一致

## ✅ 建議的修復方案

### 方案 1: 修改後端邏輯，創建 promo_code_usage 時使用推薦關係中的推廣人

**修改位置**: `backend/src/routes/bookings.ts` 第 306-317 行

**修改前**:
```typescript
const { error: usageError } = await supabase
  .from('promo_code_usage')
  .insert({
    influencer_id: influencerId,  // ⚠️ 問題：使用訂單的 influencer_id
    // ...
  });
```

**修改後**:
```typescript
// 查找推薦關係，確定實際分潤對象
const { data: existingReferral } = await supabase
  .from('referrals')
  .select('influencer_id')
  .eq('referee_id', customer.id)
  .single();

// 使用推薦關係中的 influencer_id，如果沒有推薦關係則使用訂單的 influencer_id
const actualCommissionInfluencerId = existingReferral?.influencer_id || influencerId;

const { error: usageError } = await supabase
  .from('promo_code_usage')
  .insert({
    influencer_id: actualCommissionInfluencerId,  // ✅ 使用實際分潤對象
    booking_id: booking.id,
    promo_code: promoCode,
    // ...
  });
```

### 方案 2: 添加新欄位區分優惠碼提供者和分潤對象

**修改 promo_code_usage 表結構**:
```sql
ALTER TABLE promo_code_usage 
ADD COLUMN promo_code_provider_id UUID REFERENCES influencers(id);

-- influencer_id: 實際分潤對象（來自推薦關係）
-- promo_code_provider_id: 優惠碼提供者（訂單的 influencer_id）
```

**優點**:
- 數據完整，可以追蹤優惠碼提供者和分潤對象
- 便於統計和報表

**缺點**:
- 需要修改表結構
- 需要更新現有數據

## 📊 當前數據驗證

**測試客戶**: `aa5cf574-2394-4258-aceb-471fcf80f49c`

**推薦關係**:
- `influencer_id`: `61d72f11-0b75-4eb1-8dd9-c25893b84e09` (推廣人 A)
- `promo_code`: `QQQ111`

**所有訂單**:
| 訂單 | order_influencer_id | commission_influencer_id | 一致性 |
|------|---------------------|--------------------------|--------|
| 1 | A | A | ✅ |
| 2 | A | A | ✅ |
| 3 | A | A | ✅ |
| 4 | A | A | ✅ |
| 5 | A | A | ✅ |

**結論**: 目前所有訂單都使用相同推廣人的優惠碼，沒有出現場景 3 的情況。

## 🎯 總結

### ✅ 正確實現的部分
1. **推薦關係終身綁定**: 只在首次使用優惠碼時建立，後續不改變
2. **分潤邏輯**: 觸發器正確查找推薦關係，給推薦關係中的推廣人分潤
3. **ID 使用**: 正確使用 `users.id` 而非 `firebase_uid`

### ⚠️ 需要修復的問題
1. **數據一致性**: 場景 3 中 `promo_code_usage.influencer_id` 與實際分潤對象不一致
2. **建議**: 修改後端邏輯，創建 `promo_code_usage` 時使用推薦關係中的推廣人 ID

### 📝 推薦行動
1. 實施方案 1：修改後端邏輯
2. 測試場景 3：創建一個使用不同推廣人優惠碼的訂單
3. 驗證數據一致性

---

**分析日期**: 2026-01-20  
**狀態**: 發現數據一致性問題，建議修復

