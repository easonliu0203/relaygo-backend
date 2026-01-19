# 推薦系統佣金記錄問題修復報告

## 📋 問題描述

測試訂單 `c8641468-4989-4146-8a1b-8784c370b7bb` 使用了優惠碼 `QQQ111`，但系統存在以下問題：

### 1. 推薦關係記錄缺失
- `referrals` 表中沒有該訂單對應的推薦關係記錄
- 應該在訂單創建時自動建立，但沒有執行

### 2. 佣金資訊不完整
- `promo_code_usage` 表有該訂單的優惠碼使用記錄
- 但缺少完整的佣金相關欄位資料：
  - `commission_type` = NULL（應該是 'percent'）
  - `commission_rate` = NULL（應該是 5.0）
  - `commission_amount` = 0.00（應該是 140.00）
  - `order_amount` = NULL（應該是 2800.00）
  - `referee_id` = NULL（應該是客戶的 users.id）

---

## 🔍 根本原因分析

### 問題根源：使用錯誤的 ID 類型

在 `backend/src/routes/bookings.ts` 第 326-370 行，推薦關係建立邏輯中存在嚴重錯誤：

**錯誤代碼**（第 330-334 行）：
```typescript
// 檢查用戶是否已有推薦人
const { data: existingReferral } = await supabase
  .from('referrals')
  .select('id')
  .eq('referee_id', customerUid)  // ❌ 錯誤：customerUid 是 Firebase UID
  .single();
```

**錯誤代碼**（第 353 行）：
```typescript
.insert({
  referrer_id: influencerData.user_id,
  referee_id: customerUid,  // ❌ 錯誤：應該使用 customer.id（users.id）
  influencer_id: influencerId,
  promo_code: promoCode,
  first_booking_id: booking.id
});
```

### 問題說明

1. **`customerUid`** 是 Firebase Authentication 的 UID（28 字符的字符串）
2. **`referrals.referee_id`** 欄位是 UUID 類型，指向 `users.id`（PostgreSQL UUID）
3. **類型不匹配**導致：
   - 查詢永遠找不到現有的推薦關係
   - 插入推薦關係時會失敗（外鍵約束錯誤）

### 影響範圍

- 所有使用客戶推廣人優惠碼的訂單
- 推薦關係沒有建立
- 佣金資訊沒有記錄
- 佣金計算觸發器無法執行（因為依賴 `referrals` 表）

---

## ✅ 修復方案

### 1. 後端代碼修復

**文件**: `backend/src/routes/bookings.ts`

**修改內容**:
- 使用 `customer.id`（users.id）而不是 `customerUid`（firebase_uid）
- 添加佣金資訊查詢和記錄邏輯
- 在建立推薦關係後立即更新 `promo_code_usage` 記錄

**關鍵修改**:
```typescript
// ✅ 正確：使用 users.id
const { data: existingReferral } = await supabase
  .from('referrals')
  .select('id')
  .eq('referee_id', customer.id)  // 使用 customer.id
  .single();

// ✅ 正確：插入時使用 users.id
.insert({
  referrer_id: influencerData.user_id,
  referee_id: customer.id,  // 使用 customer.id
  influencer_id: influencerId,
  promo_code: promoCode,
  first_booking_id: booking.id
});

// ✅ 新增：立即更新佣金資訊
const commissionType = influencerData.is_commission_fixed_active ? 'fixed' : 
                      influencerData.is_commission_percent_active ? 'percent' : null;
const commissionRate = influencerData.is_commission_fixed_active ? influencerData.commission_fixed :
                      influencerData.is_commission_percent_active ? influencerData.commission_percent : 0;

await supabase
  .from('promo_code_usage')
  .update({
    referee_id: customer.id,
    commission_type: commissionType,
    commission_rate: commissionRate,
    order_amount: actualFinalPrice
  })
  .eq('booking_id', booking.id);
```

### 2. 歷史資料修復

**文件**: `backend/FIX_REFERRAL_COMMISSION_DATA.sql`

**功能**:
- 自動查找所有缺少推薦關係的訂單
- 為客戶推廣人的訂單補充 `referrals` 記錄
- 更新 `promo_code_usage` 記錄，填寫佣金相關欄位
- 保護歷史資料完整性（使用當時的佣金比例）

**執行方式**:
```bash
# 在 Supabase SQL Editor 中執行
# 或使用 psql 命令
psql -h <host> -U <user> -d <database> -f FIX_REFERRAL_COMMISSION_DATA.sql
```

### 3. 測試訂單修復結果

**訂單 ID**: `c8641468-4989-4146-8a1b-8784c370b7bb`

**修復前**:
```sql
-- referrals 表：無記錄
-- promo_code_usage 表：
{
  "commission_type": null,
  "commission_rate": null,
  "commission_amount": "0.00",
  "order_amount": null,
  "referee_id": null
}
```

**修復後**:
```sql
-- referrals 表：
{
  "id": "dc9452cd-55d5-427f-8602-1da2b0ca1a6a",
  "referrer_id": "c03f0310-d3c8-44ab-8aec-1a4a858c52cb",
  "referee_id": "aa5cf574-2394-4258-aceb-471fcf80f49c",
  "influencer_id": "61d72f11-0b75-4eb1-8dd9-c25893b84e09",
  "promo_code": "QQQ111",
  "first_booking_id": "c8641468-4989-4146-8a1b-8784c370b7bb"
}

-- promo_code_usage 表：
{
  "commission_type": "percent",
  "commission_rate": 5.0,
  "commission_amount": "140.00",
  "order_amount": "2800.00",
  "referee_id": "aa5cf574-2394-4258-aceb-471fcf80f49c"
}
```

---

## 🛡️ 歷史資料保護機制

### 重要原則

⚠️ **任何修復都不能影響現有的歷史資料**

### 實現方式

1. **佣金比例快照**:
   - 在 `promo_code_usage` 表中記錄當時的佣金比例
   - 使用 `commission_type` 和 `commission_rate` 欄位
   - 即使推廣人的佣金設定改變，歷史記錄保持不變

2. **修復腳本保護**:
   - 只修復缺失的記錄
   - 使用當時推廣人的佣金設定
   - 不修改已有的完整記錄

3. **觸發器設計**:
   - 佣金計算觸發器在訂單完成時執行
   - 使用當時的佣金設定
   - 不會因為未來的設定變更而改變

### 示例

```
昨天：推廣人佣金 = 5%
今天：推廣人佣金改為 3%

結果：
- 昨天的訂單：佣金 = 5%（保持不變）
- 今天的訂單：佣金 = 3%（使用新設定）
```

---

## 📊 驗證步驟

### 1. 驗證推薦關係
```sql
SELECT * FROM referrals 
WHERE promo_code = 'QQQ111';
```

### 2. 驗證佣金資訊
```sql
SELECT 
  booking_id,
  promo_code,
  commission_type,
  commission_rate,
  commission_amount,
  order_amount,
  referee_id
FROM promo_code_usage
WHERE booking_id = 'c8641468-4989-4146-8a1b-8784c370b7bb';
```

### 3. 驗證所有記錄完整性
```sql
SELECT 
  COUNT(*) as total,
  COUNT(CASE WHEN commission_type IS NOT NULL THEN 1 END) as with_commission_type,
  COUNT(CASE WHEN referee_id IS NOT NULL THEN 1 END) as with_referee_id
FROM promo_code_usage;
```

---

## 🚀 部署步驟

1. **提交後端代碼修復**
2. **執行歷史資料修復腳本**
3. **驗證修復結果**
4. **測試新訂單流程**

---

## ✅ 修復狀態

- [x] 問題根源分析完成
- [x] 後端代碼修復完成
- [x] 測試訂單資料修復完成
- [x] 歷史資料修復腳本創建完成
- [ ] 後端代碼已推送到 GitHub
- [ ] 歷史資料修復腳本已執行
- [ ] 新訂單流程測試完成

