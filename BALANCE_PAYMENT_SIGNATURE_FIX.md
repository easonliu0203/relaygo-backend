# 支付尾款簽名功能 404 錯誤修復報告

## 📋 問題描述

**日期**：2026-01-17  
**問題**：客戶端支付尾款時，簽名儲存 API 返回 404 錯誤

### 錯誤詳情
```
HTTP Status: 404
Method: POST
Path: /api/signatures/balance-payment
Host: api.relaygo.pro
Error: DioException [bad response]: status code 404
```

### Railway 日誌
```
requestId: U8lEWOKVSz2hvAOnDcO5xA
timestamp: 2026-01-17T03:59:08.734915412Z
method: POST
path: /api/signatures/balance-payment
httpStatus: 404
upstreamAddress: http://[fd12:c8e0:646e:1:9000:1e:d1a:2ad1]:8080
```

---

## 🔍 根本原因分析

### 問題定位
1. **後端代碼已存在**：`src/routes/signatures.ts` 文件已正確實現
2. **路由已註冊**：`server.ts` 中已正確導入和註冊路由
3. **代碼已推送**：GitHub 上已有最新代碼（commit: 2beb928）

### 真正原因
**`tsconfig.min.json` 的 `include` 列表中缺少 `src/routes/signatures.ts`**

Railway 使用 Dockerfile 構建，執行 `npm run build:min`，該命令使用 `tsconfig.min.json` 進行編譯。由於 `signatures.ts` 不在 include 列表中，導致：
- TypeScript 編譯時跳過該文件
- `dist/routes/signatures.js` 未生成
- 運行時找不到路由，返回 404

---

## ✅ 修復方案

### 修改文件：`backend/tsconfig.min.json`

**修改前**：
```json
"include": [
  "src/minimal-server.ts",
  "src/config/**/*.ts",
  "src/utils/**/*.ts",
  "src/types/**/*.ts",
  "src/services/payment/**/*.ts",
  "src/routes/pricing.ts",
  "src/routes/reviews.ts",
  "src/routes/gomypay.ts",
  "src/routes/bookings.ts",
  "src/routes/bookingFlow-minimal.ts",
  "src/routes/test-firebase.ts",
  "src/routes/profile.ts",
  "src/routes/ratings.ts",
  "src/routes/auth.ts",
  "src/routes/drivers.ts",
  "src/routes/tourPackages.ts",
  "src/routes/influencers.ts",
  "src/routes/promoCodes.ts"
],
```

**修改後**：
```json
"include": [
  "src/minimal-server.ts",
  "src/config/**/*.ts",
  "src/utils/**/*.ts",
  "src/types/**/*.ts",
  "src/services/payment/**/*.ts",
  "src/services/email/**/*.ts",        // ✅ 新增：郵件服務
  "src/routes/pricing.ts",
  "src/routes/reviews.ts",
  "src/routes/gomypay.ts",
  "src/routes/bookings.ts",
  "src/routes/bookingFlow-minimal.ts",
  "src/routes/test-firebase.ts",
  "src/routes/profile.ts",
  "src/routes/ratings.ts",
  "src/routes/auth.ts",
  "src/routes/drivers.ts",
  "src/routes/tourPackages.ts",
  "src/routes/influencers.ts",
  "src/routes/promoCodes.ts",
  "src/routes/signatures.ts"            // ✅ 新增：簽名路由
],
```

### 提交記錄
```bash
git add tsconfig.min.json
git commit -m "fix: 添加 signatures.ts 和 email 服務到 tsconfig.min.json 以修復 Railway 部署 404 錯誤"
git push origin main
```

**Commit Hash**: `fd27f4e`

---

## 🧪 測試驗證

### 1. 等待 Railway 自動部署
- Railway 會自動檢測 GitHub 推送並觸發重新部署
- 預計部署時間：3-5 分鐘

### 2. 測試步驟
1. 打開客戶端 App
2. 進入支付尾款頁面
3. 在簽名板上簽名
4. 點擊「確認送出」按鈕
5. 驗證：
   - ✅ 簽名成功儲存（無 404 錯誤）
   - ✅ 支付流程正常進行
   - ✅ 收到電子收據郵件
   - ✅ 郵件中顯示客戶簽名

### 3. 驗證 API 端點
```bash
# 使用 curl 測試（需要有效的 Firebase Token）
curl -X POST https://api.relaygo.pro/api/signatures/balance-payment \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "YOUR_BOOKING_ID",
    "signatureBase64": "data:image/png;base64,iVBORw0KG...",
    "customerUid": "YOUR_CUSTOMER_UID"
  }'
```

預期回應：
```json
{
  "success": true,
  "data": {
    "signatureId": "uuid",
    "bookingId": "booking_id",
    "bookingNumber": "RG20260117001"
  }
}
```

---

## 📊 影響範圍

### 受影響功能
- ✅ 支付尾款簽名儲存
- ✅ 電子收據簽名顯示

### 不受影響功能
- ✅ 支付訂金流程
- ✅ 其他 API 端點
- ✅ 客戶端其他功能

---

## 🔒 預防措施

### 建議改進
1. **自動化測試**：添加 CI/CD 檢查，確保所有路由文件都在 tsconfig.min.json 中
2. **部署驗證**：部署後自動測試關鍵 API 端點
3. **監控告警**：設置 404 錯誤監控，及時發現問題

### 檢查清單
當添加新路由時，確保：
- [ ] 路由文件已創建（`src/routes/*.ts`）
- [ ] 路由已在 `server.ts` 中導入和註冊
- [ ] 路由已添加到 `tsconfig.min.json` 的 `include` 列表
- [ ] 代碼已推送到 GitHub
- [ ] Railway 部署成功
- [ ] API 端點測試通過

---

## 📝 相關文件

- `backend/src/routes/signatures.ts` - 簽名 API 路由
- `backend/src/server.ts` - 路由註冊
- `backend/tsconfig.min.json` - TypeScript 編譯配置
- `backend/Dockerfile` - Railway 部署配置
- `mobile/lib/apps/customer/presentation/pages/payment_balance_page.dart` - 客戶端簽名邏輯

