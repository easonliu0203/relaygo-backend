# 訂單促成費計算邏輯重構

## 📋 修改摘要

將訂單促成費從**固定 500 元**改為**5% 比例制**，並將計算邏輯從前端移至後端。

## 🎯 修改目標

### 修改前
- **計算位置**: 前端計算後傳遞 `influencerCommission` 參數
- **計算方式**: 固定 500 元
- **問題**: 
  - 客戶端可篡改金額
  - 業務邏輯分散在前端
  - 修改比例需更新所有客戶端

### 修改後
- **計算位置**: 後端自動計算
- **計算方式**: 折後最終金額 × 5%
- **優點**:
  - ✅ 數據安全，無法篡改
  - ✅ 業務邏輯集中管理
  - ✅ 符合 CQRS 架構原則
  - ✅ 便於維護和擴展

## 💰 計算邏輯

### 情境 1：無優惠碼/無推薦關係
```
消費者支付：$1000
公司抽成 (25%)：$250
司機收入 (75%)：$750
推廣人分潤：$0
```

### 情境 2：有優惠碼（或符合終身綁定關係）
```
消費者支付：$900（假設優惠碼折扣 $100）
計算基準：以「折後最終金額」$900 為準

公司總扣 (30%)：$270
  - 公司淨收 (25%)：$225
  - 促成費 (5%，給推廣人)：$45

司機收入 (70%)：$630
推廣人實拿：$45
```

## 🔧 技術實現

### 修改文件
- `backend/src/routes/bookings.ts`

### 核心代碼
```typescript
// ✅ 計算訂單促成費（5% 比例制）
// 情境 1：無優惠碼/無推薦關係 → 促成費 = 0
// 情境 2：有優惠碼（或符合終身綁定關係）→ 促成費 = 折後最終金額 × 5%
const COMMISSION_RATE = 0.05; // 5% 促成費比例
let calculatedInfluencerCommission = 0;

if (promoCode && influencerId) {
  // 使用折扣後的最終金額作為計算基準
  calculatedInfluencerCommission = Math.round(actualFinalPrice * COMMISSION_RATE);
  console.log('[API] ✅ 計算訂單促成費 (5%):', {
    finalPrice: actualFinalPrice,
    commissionRate: COMMISSION_RATE,
    commission: calculatedInfluencerCommission
  });
}
```

### 數據庫欄位
- `bookings.influencer_commission`: 訂單促成費快照（後端計算）
- `promo_code_usage.commission_amount`: 分潤記錄（初始值為訂單促成費）

## 📊 計算範例

| 原價 | 折扣 | 折後價 | 促成費 (5%) | 公司淨收 (25%) | 司機收入 (70%) |
|------|------|--------|-------------|----------------|----------------|
| $1000 | $0 | $1000 | $0 | $250 | $750 |
| $1000 | $100 | $900 | $45 | $225 | $630 |
| $2000 | $200 | $1800 | $90 | $450 | $1260 |
| $3800 | $1000 | $2800 | $140 | $700 | $1960 |

## 🔄 前端適配

### 需要修改的前端代碼
前端**不再需要**傳遞 `influencerCommission` 參數：

**修改前**:
```typescript
const influencerCommission = 500; // 固定 500 元
await createBooking({
  // ...
  influencerCommission,
});
```

**修改後**:
```typescript
// 移除 influencerCommission 參數
await createBooking({
  // ...
  // influencerCommission 已由後端自動計算
});
```

### 前端顯示預覽
前端可以在 UI 中顯示**預估**促成費（僅供參考）：
```typescript
const estimatedCommission = Math.round(finalPrice * 0.05);
// 顯示：「預估推廣人分潤：$${estimatedCommission}」
```

## 🧪 測試案例

### 測試 1: 無優惠碼
```json
{
  "estimatedFare": 1000,
  "promoCode": null,
  "influencerId": null
}
```
**預期結果**:
- `total_amount`: 1000
- `influencer_commission`: 0

### 測試 2: 有優惠碼
```json
{
  "originalPrice": 1000,
  "discountAmount": 100,
  "finalPrice": 900,
  "promoCode": "QQQ111",
  "influencerId": "61d72f11-0b75-4eb1-8dd9-c25893b84e09"
}
```
**預期結果**:
- `total_amount`: 900
- `influencer_commission`: 45 (900 × 5%)

## 📝 部署注意事項

1. **後端部署**: Railway 會自動部署
2. **前端適配**: 需要更新 Mobile App 和 Web Admin（移除 `influencerCommission` 參數）
3. **向後兼容**: 後端仍接受 `influencerCommission` 參數（但會被忽略）
4. **數據遷移**: 現有訂單的 `influencer_commission` 保持不變

## 🎯 優勢總結

1. **安全性**: 金額計算邏輯在後端，無法被篡改
2. **一致性**: 所有訂單使用相同的計算邏輯
3. **可維護性**: 修改比例只需改後端一處
4. **可擴展性**: 未來可根據不同條件調整比例（如 VIP 推廣人）
5. **符合架構**: 遵循 CQRS 原則，業務邏輯在後端

---

**修改日期**: 2026-01-21  
**修改人**: RelayGo Dev Team  
**狀態**: ✅ 已完成並測試

