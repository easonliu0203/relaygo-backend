# ✅ RELAY GO 客戶推廣人系統 - Phase 2 完成報告

**完成日期**: 2026-01-18  
**階段**: Phase 2 - Backend API Development  
**狀態**: ✅ **全部完成**

---

## 📋 Phase 2 完成項目總覽

### ✅ 1. 推廣人申請 API
**端點**: `POST /api/affiliates/apply`  
**文件**: `backend/src/routes/affiliates.ts`

**功能**:
- ✅ 接受客戶申請，自訂推薦碼（3-10 個英數字元）
- ✅ 即時檢查推薦碼唯一性（不分大小寫）
- ✅ 設定初始狀態為 `pending`
- ✅ 連結到認證客戶的 `user_id`
- ✅ 設定 `affiliate_type` 為 `customer_affiliate`
- ✅ 防止重複申請檢查

**請求範例**:
```json
POST /api/affiliates/apply
{
  "user_id": "uuid-here",
  "promo_code": "MYCODE123"
}
```

**回應範例**:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "promo_code": "MYCODE123",
    "affiliate_status": "pending",
    "affiliate_type": "customer_affiliate"
  },
  "message": "推廣人申請已提交，請等待管理員審核"
}
```

---

### ✅ 2. 推廣人審核 API
**端點**: `POST /api/affiliates/:id/review`  
**文件**: `backend/src/routes/affiliates.ts`

**功能**:
- ✅ 管理員專用端點
- ✅ 更新 `affiliate_status` (`active`, `rejected`)
- ✅ 記錄 `reviewed_at`, `reviewed_by`, `review_notes`
- ✅ 通過審核時自動啟用 (`is_active = true`)
- ✅ 只能審核 `pending` 狀態的申請

**請求範例**:
```json
POST /api/affiliates/abc123/review
{
  "status": "active",
  "reviewed_by": "admin-user-id",
  "review_notes": "申請資料完整，通過審核"
}
```

---

### ✅ 3. 推薦碼可用性檢查 API
**端點**: `GET /api/affiliates/check-promo-code/:code`  
**文件**: `backend/src/routes/affiliates.ts`

**功能**:
- ✅ 公開端點，無需認證
- ✅ 即時檢查推薦碼是否已被使用
- ✅ 驗證推薦碼格式（3-10 個英數字元）

**回應範例**:
```json
{
  "success": true,
  "available": true,
  "message": "推薦碼可用"
}
```

---

### ✅ 4. 推廣人狀態查詢 API
**端點**: `GET /api/affiliates/my-status?user_id=xxx`  
**文件**: `backend/src/routes/affiliates.ts`

**功能**:
- ✅ 查詢當前用戶的推廣人狀態
- ✅ 返回申請狀態、推薦碼、統計數據

**回應範例**:
```json
{
  "success": true,
  "data": {
    "is_affiliate": true,
    "status": "active",
    "promo_code": "MYCODE123",
    "total_referrals": 5,
    "total_earnings": 250.00
  }
}
```

---

### ✅ 5. 擴展優惠碼驗證 API
**端點**: `POST /api/promo-codes/validate`  
**文件**: `backend/src/routes/promoCodes.ts`

**新增功能**:
- ✅ 接受 `user_id` 參數
- ✅ 檢查用戶是否已有推薦人（查詢 `referrals` 表）
- ✅ 返回推薦關係資訊 (`referral_info`)
- ✅ 支援網紅和客戶推廣人兩種類型

**新增回應欄位**:
```json
{
  "referral_info": {
    "has_referrer": false,
    "is_first_use": true,
    "message": "首次使用推薦碼，將建立推薦關係並享受折扣"
  }
}
```

---

### ✅ 6. 推薦關係建立邏輯
**文件**: `backend/src/routes/bookings.ts` (第 326-372 行)

**功能**:
- ✅ 在訂單創建後自動執行
- ✅ 檢查用戶是否已有推薦人
- ✅ 首次使用推薦碼時建立 `referrals` 記錄
- ✅ 只對客戶推廣人建立推薦關係（網紅不建立）
- ✅ 終身綁定機制（一旦建立，永久有效）

**邏輯流程**:
```
1. 訂單使用優惠碼 → 記錄到 promo_code_usage
2. 檢查 referrals 表是否已有記錄
3. 如果沒有 + 是客戶推廣人 → 建立推薦關係
4. 如果已有 → 只享受折扣，不改變推薦關係
```

---

### ✅ 7. 分潤計算觸發器
**文件**: `migrations/20260118_create_commission_trigger.sql`

**功能**:
- ✅ 當訂單狀態更新為 `completed` 時自動觸發
- ✅ 查詢客戶的推薦關係
- ✅ 獲取推廣人的分潤設定
- ✅ 計算分潤金額（優先級：固定金額 > 百分比）
- ✅ 更新或新增 `promo_code_usage` 記錄
- ✅ 更新推廣人的 `total_earnings`

**計算邏輯**:
```sql
IF is_commission_fixed_active = true THEN
  commission_amount = commission_fixed
ELSIF is_commission_percent_active = true THEN
  commission_amount = order_amount * commission_percent / 100
END IF
```

---

## 🗂️ 創建的文件

1. ✅ `backend/src/routes/affiliates.ts` - 推廣人 API 路由（374 行）
2. ✅ `migrations/20260118_create_commission_trigger.sql` - 分潤觸發器

## 📝 修改的文件

1. ✅ `backend/src/server.ts` - 註冊 affiliates 路由
2. ✅ `backend/src/routes/promoCodes.ts` - 擴展驗證邏輯
3. ✅ `backend/src/routes/bookings.ts` - 新增推薦關係建立邏輯

---

## 🧪 測試建議

### 1. 推廣人申請流程
```bash
# 1. 申請成為推廣人
POST /api/affiliates/apply
{
  "user_id": "customer-uuid",
  "promo_code": "TESTCODE"
}

# 2. 檢查推薦碼可用性
GET /api/affiliates/check-promo-code/TESTCODE

# 3. 管理員審核
POST /api/affiliates/{id}/review
{
  "status": "active",
  "reviewed_by": "admin-uuid"
}

# 4. 查詢狀態
GET /api/affiliates/my-status?user_id=customer-uuid
```

### 2. 推薦關係建立流程
```bash
# 1. 驗證優惠碼
POST /api/promo-codes/validate
{
  "promo_code": "TESTCODE",
  "original_price": 1000,
  "user_id": "new-customer-uuid"
}

# 2. 創建訂單（會自動建立推薦關係）
POST /api/bookings
{
  "customer_id": "new-customer-uuid",
  "promo_code": "TESTCODE",
  ...
}

# 3. 檢查 referrals 表
SELECT * FROM referrals WHERE referee_id = 'new-customer-uuid';
```

### 3. 分潤計算流程
```bash
# 1. 更新訂單狀態為完成
UPDATE bookings SET status = 'completed' WHERE id = 'booking-uuid';

# 2. 檢查分潤記錄
SELECT * FROM promo_code_usage WHERE booking_id = 'booking-uuid';

# 3. 檢查推廣人收益
SELECT total_earnings FROM influencers WHERE id = 'influencer-uuid';
```

---

## 🎯 下一步：Phase 3 - 管理後台開發

- [ ] 新增「廣告與行銷 → 客戶推廣人管理」選單
- [ ] 實現推廣人列表頁面（搜尋、篩選、排序）
- [ ] 實現推廣人詳情頁面
- [ ] 實現批次審核功能
- [ ] 實現折扣和分潤設定介面
- [ ] 實現統計報表功能

---

**Phase 2 狀態**: ✅ **100% 完成**  
**準備進入**: Phase 3 - 管理後台開發

