# 電子收據簽名顯示修復指南

## 📋 問題描述

**問題**：電子收據郵件中顯示破損的圖片符號和「客戶數位簽名」文字，而不是實際的簽名圖片。

**原因**：某些郵件客戶端（如 Gmail）出於安全考慮，不支援顯示長 Base64 字串作為圖片。

## ✅ 解決方案

將簽名圖片上傳到 **Supabase Storage**，並在郵件中使用**公開 URL** 而非 Base64 編碼。

---

## 🔧 實施的修改

### 1. **資料庫更新**
- **表名**：`payment_signatures`
- **新增欄位**：`signature_url TEXT`
- **Migration 文件**：`supabase/migrations/20260117_add_signature_url_to_payment_signatures.sql`

### 2. **Supabase Storage**
- **Bucket 名稱**：`payment-signatures`
- **訪問權限**：公開（public）
- **文件大小限制**：5MB
- **允許的文件類型**：`image/png`, `image/jpeg`, `image/jpg`
- **公開 URL 格式**：
  ```
  https://vlyhwegpvpnjyocqmfqc.supabase.co/storage/v1/object/public/payment-signatures/{filename}
  ```

### 3. **API 更新** (`backend/src/routes/signatures.ts`)

**修改內容**：
- 將 Base64 簽名轉換為圖片 Buffer
- 上傳到 Supabase Storage（文件名格式：`{booking_number}-{timestamp}.png`）
- 獲取公開 URL 並儲存到 `signature_url` 欄位
- 保留 `signature_base64` 以向後兼容

**關鍵代碼**：
```typescript
// 移除 Base64 前綴
const base64Data = signatureBase64.replace(/^data:image\/\w+;base64,/, '');
const imageBuffer = Buffer.from(base64Data, 'base64');

// 生成唯一文件名
const fileName = `${booking.booking_number}-${timestamp}.png`;

// 上傳到 Supabase Storage
const { data: uploadData, error: uploadError } = await supabase.storage
  .from('payment-signatures')
  .upload(fileName, imageBuffer, {
    contentType: 'image/png',
    cacheControl: '31536000', // 1 年緩存
    upsert: false
  });

// 獲取公開 URL
const { data: publicUrlData } = supabase.storage
  .from('payment-signatures')
  .getPublicUrl(fileName);

signatureUrl = publicUrlData.publicUrl;
```

### 4. **郵件服務更新** (`backend/src/services/email/receiptEmailService.ts`)

**修改內容**：
- 查詢 `signature_url` 和 `signature_base64`
- 優先使用 `signature_url`
- 如果不存在則使用 `signature_base64`（向後兼容）

**關鍵代碼**：
```typescript
const { data: signature } = await supabase
  .from('payment_signatures')
  .select('signature_url, signature_base64')
  .eq('booking_id', params.bookingId)
  .order('created_at', { ascending: false })
  .limit(1)
  .single();

if (signature) {
  if (signature.signature_url) {
    receiptData.signatureUrl = signature.signature_url;
  } else if (signature.signature_base64) {
    receiptData.signatureBase64 = signature.signature_base64;
  }
}
```

### 5. **郵件模板更新** (`backend/src/services/email/receiptTemplate.ts`)

**修改內容**：
- 添加 `signatureUrl` 欄位到 `ReceiptData` 介面
- 優先使用 `signatureUrl` 顯示簽名圖片
- 支援 Base64 fallback

**關鍵代碼**：
```typescript
${data.signatureUrl ? `
  <!-- 使用 Supabase Storage URL（推薦） -->
  <img src="${data.signatureUrl}" alt="Customer Signature" />
` : data.signatureBase64 ? `
  <!-- 向後兼容：使用 Base64 -->
  <img src="${data.signatureBase64}" alt="Customer Signature" />
` : ''}
```

---

## 🧪 測試步驟

### 前置條件
1. ✅ Railway 部署完成（約 3-5 分鐘）
2. ✅ Supabase Storage bucket 已創建
3. ✅ 資料庫 migration 已執行

### 測試流程

#### 1. **簽名捕獲和儲存**
- 打開客戶端 App
- 進入支付尾款頁面
- 在簽名板上完成簽名
- 點擊「確認送出」按鈕

**預期結果**：
- ✅ 簽名成功儲存（無 404 錯誤）
- ✅ API 返回 `signatureUrl`
- ✅ 資料庫中 `signature_url` 欄位有值

#### 2. **驗證 Storage 上傳**
- 登入 Supabase Dashboard
- 進入 Storage → `payment-signatures` bucket
- 確認簽名圖片已上傳

**預期結果**：
- ✅ 文件名格式：`RG20260117001-1768632502832.png`
- ✅ 文件大小：< 5MB
- ✅ 文件類型：`image/png`

#### 3. **驗證公開 URL**
- 複製 `signature_url` 的值
- 在瀏覽器中打開 URL

**預期結果**：
- ✅ 圖片正常顯示
- ✅ URL 格式正確

#### 4. **驗證電子收據郵件**
- 完成支付尾款流程
- 檢查客戶郵箱

**預期結果**：
- ✅ 收到電子收據郵件
- ✅ 郵件中顯示「客戶數位簽名」區塊
- ✅ 簽名圖片正常顯示（不是破損符號）
- ✅ 在 Gmail、Outlook 等不同郵件客戶端測試

---

## 🔍 故障排除

### 問題 1：簽名上傳失敗
**症狀**：API 返回錯誤或 `signatureUrl` 為空

**檢查**：
1. Supabase Storage bucket 是否存在
2. Bucket 權限是否設置為公開
3. 文件大小是否超過 5MB
4. 文件類型是否為 `image/png`

**解決方案**：
```bash
# 重新創建 bucket
node scripts/create-signature-bucket.js
```

### 問題 2：郵件中簽名仍然不顯示
**症狀**：郵件中顯示破損圖片符號

**檢查**：
1. `signature_url` 是否有值
2. URL 是否可訪問
3. 郵件模板是否正確使用 `signatureUrl`

**解決方案**：
- 檢查 Railway 日誌
- 驗證 Supabase Storage 配置
- 測試公開 URL 訪問

---

## 📊 部署狀態

**GitHub 推送**：✅ 完成
- Backend Repository: `easonliu0203/relaygo-backend`
- Supabase Repository: `easonliu0203/relaygo-supabase`
- Latest Commit: `152a445`

**Railway 自動部署**：🔄 進行中
- 預計完成時間：3-5 分鐘

**Supabase Storage**：✅ 已配置
- Bucket: `payment-signatures`
- 公開訪問：已啟用

---

## 📝 向後兼容性

此修復完全向後兼容：
- ✅ 保留 `signature_base64` 欄位
- ✅ 如果 `signature_url` 不存在，自動使用 `signature_base64`
- ✅ 舊的簽名記錄仍然可以正常顯示

---

## 🎯 預期效果

**修復前**：
- ❌ Gmail 中顯示破損圖片符號
- ❌ 郵件中只顯示「客戶數位簽名」文字

**修復後**：
- ✅ 所有郵件客戶端正常顯示簽名圖片
- ✅ 圖片載入速度快（使用 CDN）
- ✅ 圖片永久儲存（不會過期）

