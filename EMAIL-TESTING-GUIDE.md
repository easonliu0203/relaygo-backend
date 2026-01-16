# RelayGo 電子收據郵件測試指南

## 📋 測試前準備

### 1. 獲取 Resend API Key

1. 訪問 Resend Dashboard: https://resend.com/dashboard
2. 登入您的帳號
3. 進入 "API Keys" 頁面
4. 點擊 "Create API Key"
5. 複製生成的 API Key（格式：`re_xxxxxxxxxxxxxxxxxxxxxxxxxx`）

### 2. 配置本地環境變數

在項目根目錄創建或編輯 `.env` 文件：

```bash
# Resend 郵件服務配置
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxx
RESEND_FROM_EMAIL=send@relaygo.pro

# 其他必要的環境變數（用於完整測試）
SUPABASE_URL=your-supabase-url
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
```

## 🧪 測試步驟

### 測試 1: 基本郵件發送測試

這個測試驗證 Resend 服務是否正常工作。

```powershell
# 運行測試腳本
node test-email.js
```

**預期結果**：
```
開始測試郵件發送...

✅ 找到 RESEND_API_KEY
   Key 前綴: re_xxxxxxxx...

發送測試郵件...
收件人: dev@relaygo.com

✅ 郵件發送成功！
   Message ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

請檢查您的郵箱（包括垃圾郵件資料夾）
```

### 測試 2: 收據模板測試

創建一個測試腳本來驗證收據模板生成：

```javascript
// test-receipt-template.js
require('dotenv').config();
const { generateReceiptHtml } = require('./dist/services/email/receiptTemplate');
const fs = require('fs');

const testData = {
  bookingNumber: 'BK20250115001',
  bookingDate: '2025-01-20',
  bookingTime: '09:00',
  customerName: '測試客戶',
  customerEmail: 'test@example.com',
  customerPhone: '+886912345678',
  pickupLocation: '台北車站',
  dropoffLocation: '桃園機場',
  vehicleType: 'A型車（4人座）',
  durationHours: 8,
  paymentType: 'deposit',
  basePrice: 3200,
  depositAmount: 1600,
  totalAmount: 3200,
  paidAmount: 1600,
  transactionId: 'TXN20250115001',
  paymentMethod: 'GoMyPay',
  paymentDate: '2025-01-15 14:30:00',
  language: 'zh-TW'
};

const html = generateReceiptHtml(testData);
fs.writeFileSync('test-receipt.html', html);
console.log('✅ 收據模板已生成：test-receipt.html');
console.log('請在瀏覽器中打開查看');
```

運行測試：
```powershell
npm run build:min
node test-receipt-template.js
```

### 測試 3: 完整流程測試（需要資料庫）

這個測試需要連接到 Supabase 資料庫。

**前提條件**：
- 資料庫中有測試訂單
- 訂單有關聯的客戶資料
- 客戶有郵箱地址

**測試步驟**：

1. 在 Supabase 中創建測試訂單
2. 使用 GoMyPay 測試環境完成支付
3. 檢查 Railway 日誌中的郵件發送記錄
4. 驗證客戶郵箱收到收據

## 📊 驗證檢查點

### ✅ 郵件發送成功
- [ ] 測試腳本顯示發送成功
- [ ] 獲得 Message ID
- [ ] Resend Dashboard 顯示郵件已發送

### ✅ 郵件內容正確
- [ ] 收據包含正確的訂單號
- [ ] 金額顯示正確
- [ ] 日期時間正確
- [ ] 客戶資訊正確
- [ ] 服務詳情正確

### ✅ 郵件格式美觀
- [ ] 在桌面郵件客戶端顯示正常
- [ ] 在手機郵件客戶端顯示正常（響應式）
- [ ] 顏色和排版符合品牌風格
- [ ] 中文字體顯示正常

### ✅ 多語言支持
- [ ] 繁體中文收據正確
- [ ] 簡體中文收據正確
- [ ] 英文收據正確

## 🔍 常見問題排除

### 問題 1: "RESEND_API_KEY 未設置"

**解決方法**：
1. 確認 `.env` 文件存在於項目根目錄
2. 確認文件中有 `RESEND_API_KEY=...` 這一行
3. 確認沒有多餘的空格或引號

### 問題 2: "Authentication failed"

**可能原因**：
- API Key 錯誤或已過期
- API Key 權限不足

**解決方法**：
1. 重新生成 API Key
2. 確認使用的是正確的 API Key
3. 檢查 Resend Dashboard 中的 API Key 狀態

### 問題 3: 郵件未收到

**檢查步驟**：
1. 查看垃圾郵件資料夾
2. 檢查 Resend Dashboard 中的發送狀態
3. 驗證收件人郵箱地址正確
4. 檢查域名 DNS 設置（SPF、DKIM、DMARC）

### 問題 4: 郵件格式錯亂

**可能原因**：
- 郵件客戶端不支持某些 CSS
- HTML 結構問題

**解決方法**：
1. 使用內聯樣式（已實作）
2. 避免使用複雜的 CSS
3. 在多個郵件客戶端測試

## 📝 測試記錄模板

```
測試日期：2025-01-15
測試人員：[您的名字]
測試環境：[開發/測試/正式]

測試項目 1: 基本郵件發送
- 狀態：✅ 通過 / ❌ 失敗
- Message ID：xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
- 備註：

測試項目 2: 訂金收據
- 狀態：✅ 通過 / ❌ 失敗
- 訂單號：BK20250115001
- 收件人：test@example.com
- 備註：

測試項目 3: 完整收據
- 狀態：✅ 通過 / ❌ 失敗
- 訂單號：BK20250115002
- 收件人：test@example.com
- 備註：

測試項目 4: 多語言
- 繁體中文：✅ 通過 / ❌ 失敗
- 簡體中文：✅ 通過 / ❌ 失敗
- 英文：✅ 通過 / ❌ 失敗
- 備註：

整體評估：
- 功能完整性：
- 穩定性：
- 用戶體驗：
- 建議改進：
```

## 🚀 部署到 Railway 後的測試

### 1. 驗證環境變數

在 Railway Dashboard 中確認：
- `RESEND_API_KEY` 已設置
- `RESEND_FROM_EMAIL` 已設置

### 2. 查看部署日誌

```bash
# 在 Railway Dashboard 中查看日誌
# 搜索關鍵字：
- [Resend]
- [ReceiptEmail]
- [GOMYPAY Callback]
```

### 3. 端到端測試

1. 使用 Mobile App 創建真實訂單
2. 完成支付（使用 GoMyPay 測試環境）
3. 等待約 5 分鐘（GoMyPay 回調延遲）
4. 檢查客戶郵箱
5. 驗證收據內容

## 📞 需要幫助？

如果測試過程中遇到問題：

1. 查看 Railway 部署日誌
2. 查看 Resend Dashboard 中的郵件狀態
3. 檢查本文檔的「常見問題排除」部分
4. 聯繫技術支援：dev@relaygo.com

