# 修復：訂單折扣金額自動計算

## 🐛 問題描述

**問題位置**：
- 客戶端 APP > 訂單詳情頁面 > 費用資訊區塊 > 「折扣金額」欄位
- 司機端 APP > 訂單詳情頁面 > 費用資訊區塊 > 「客戶折扣」欄位

**問題現象**：
當使用百分比折扣（例如 9 折優惠碼）時，費用資訊顯示異常：
- 原價：3800 TWD
- 折扣金額：-0 TWD（❌ 錯誤）
- 實付金額：3420 TWD（✅ 正確）

**預期行為**：
- 原價：3800 TWD
- 折扣金額：-380 TWD（3800 × 10% = 380）
- 實付金額：3420 TWD

---

## 🔍 根本原因

### 1. 後端 API 問題

**修改前**（`backend/src/routes/bookings.ts` 第 217 行）：
```typescript
actualDiscountAmount = discountAmount || 0;
```

**問題分析**：
- 後端依賴前端傳遞 `discountAmount` 參數
- 當前端使用百分比折扣時，可能只傳遞 `originalPrice` 和 `finalPrice`
- 如果前端沒有計算並傳遞 `discountAmount`，後端會將其設為 0
- 導致資料庫中 `discount_amount` 欄位為 0

### 2. 前端顯示問題

**客戶端**（`mobile/lib/apps/customer/presentation/pages/order_detail_page.dart` 第 370 行）：
```dart
'- NT\$ ${order.discountAmount.toStringAsFixed(0)}'
```

**司機端**（`mobile/lib/apps/driver/presentation/pages/driver_order_detail_page.dart` 第 383 行）：
```dart
'- NT\$ ${order.discountAmount.toStringAsFixed(0)}'
```

**問題分析**：
- 前端直接顯示從後端 API 獲取的 `discountAmount` 欄位
- 如果後端返回 0，前端就顯示 0

---

## ✅ 修復內容

### 修改文件：`backend/src/routes/bookings.ts`

**修改位置**：第 208-227 行

**修改前**：
```typescript
if (finalPrice && finalPrice > 0) {
  // 客戶使用了優惠碼
  actualOriginalPrice = originalPrice || totalAmount;
  actualDiscountAmount = discountAmount || 0; // ❌ 依賴前端傳遞
  actualFinalPrice = finalPrice;
  totalAmount = finalPrice;
  console.log('[API] ✅ 使用優惠碼折扣後價格:', {
    originalPrice: actualOriginalPrice,
    discountAmount: actualDiscountAmount,
    finalPrice: actualFinalPrice
  });
}
```

**修改後**：
```typescript
if (finalPrice && finalPrice > 0) {
  // 客戶使用了優惠碼
  actualOriginalPrice = originalPrice || totalAmount;
  actualFinalPrice = finalPrice;
  // ✅ 自動計算折扣金額（支援固定金額和百分比折扣）
  actualDiscountAmount = actualOriginalPrice - actualFinalPrice;
  totalAmount = finalPrice;
  console.log('[API] ✅ 使用優惠碼折扣後價格:', {
    originalPrice: actualOriginalPrice,
    discountAmount: actualDiscountAmount,
    finalPrice: actualFinalPrice,
    discountPercentage: ((actualDiscountAmount / actualOriginalPrice) * 100).toFixed(2) + '%'
  });
}
```

**修改說明**：
1. ✅ 後端自動計算 `discountAmount = originalPrice - finalPrice`
2. ✅ 支援固定金額折扣和百分比折扣
3. ✅ 新增折扣百分比日誌輸出，方便調試
4. ✅ 不再依賴前端傳遞 `discountAmount` 參數

---

## 🧪 測試案例

### 測試案例 1：固定金額折扣

**輸入**：
- `originalPrice`: 3800 TWD
- `finalPrice`: 3300 TWD（固定折扣 500 TWD）

**預期輸出**：
- `discountAmount`: 500 TWD
- 前端顯示：「折扣金額：- NT$ 500」

---

### 測試案例 2：百分比折扣（9 折）

**輸入**：
- `originalPrice`: 3800 TWD
- `finalPrice`: 3420 TWD（9 折 = 3800 × 0.9）

**預期輸出**：
- `discountAmount`: 380 TWD
- `discountPercentage`: 10.00%
- 前端顯示：「折扣金額：- NT$ 380」

---

### 測試案例 3：百分比折扣（95 折）

**輸入**：
- `originalPrice`: 10000 TWD
- `finalPrice`: 9500 TWD（95 折 = 10000 × 0.95）

**預期輸出**：
- `discountAmount`: 500 TWD
- `discountPercentage`: 5.00%
- 前端顯示：「折扣金額：- NT$ 500」

---

## 📊 影響範圍

### ✅ 修復的功能
1. 客戶端訂單詳情頁面 - 折扣金額正確顯示
2. 司機端訂單詳情頁面 - 客戶折扣正確顯示
3. 資料庫 `bookings` 表 - `discount_amount` 欄位正確記錄
4. 資料庫 `promo_code_usage` 表 - `discount_amount_applied` 欄位正確記錄

### ⚠️ 向後兼容性
- ✅ 完全向後兼容
- ✅ 前端仍可傳遞 `discountAmount` 參數（但會被忽略）
- ✅ 現有訂單不受影響（歷史數據保持不變）
- ✅ 新訂單自動計算折扣金額

---

## 🚀 部署狀態

- ✅ **Backend**: 已推送到 GitHub (`easonliu0203/relaygo-backend`)
- 🔄 **Railway**: 自動部署中...
- ✅ **Frontend**: 無需修改（直接使用後端返回的 `discountAmount`）

---

## 📝 後續建議

1. **前端優化**（可選）：
   - 可以在前端也添加折扣金額的本地計算作為備用
   - 公式：`discountAmount = (originalPrice ?? estimatedFare) - actualPrice`

2. **資料庫遷移**（可選）：
   - 可以創建一個 SQL 腳本，修復歷史訂單的 `discount_amount` 欄位
   - 對於 `discount_amount = 0` 但 `original_price` 和 `final_price` 不同的訂單

3. **監控**：
   - 監控新訂單的 `discount_amount` 欄位是否正確計算
   - 檢查日誌中的折扣百分比是否合理

---

## ✅ 修復完成

**Commit**: `fdd97c7` - "fix: 自動計算折扣金額以支援百分比折扣顯示"

**修復日期**: 2026-01-24

**修復人員**: AI Assistant

