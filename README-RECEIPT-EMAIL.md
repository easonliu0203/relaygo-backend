# RelayGo 電子收據郵件功能

## 🎯 功能簡介

當用戶完成支付後，系統會自動發送電子收據到客戶的郵箱。

- ✅ 訂金支付完成 → 發送訂金收據
- ✅ 尾款支付完成 → 發送完整收據
- ✅ 支持多語言（繁中、簡中、英文）
- ✅ 響應式設計，手機和電腦都能正常顯示

## 📁 相關文件

### 核心代碼
- `src/services/email/resendService.ts` - Resend 郵件服務封裝
- `src/services/email/receiptTemplate.ts` - 收據模板生成
- `src/services/email/receiptEmailService.ts` - 收據郵件發送服務
- `src/routes/gomypay.ts` - 支付回調整合（已修改）

### 文檔
- `RECEIPT-EMAIL-DEPLOYMENT.md` - 📘 部署指南（必讀）
- `EMAIL-TESTING-GUIDE.md` - 🧪 測試指南
- `IMPLEMENTATION-SUMMARY.md` - 📊 實作總結
- `GIT-COMMIT-GUIDE.md` - 📝 提交指南
- `FINAL-CHECKLIST.md` - ✅ 檢查清單

### 測試工具
- `test-email.js` - 郵件發送測試腳本
- `.env.example` - 環境變數範例

## 🚀 快速開始

### 1. 安裝依賴
```bash
npm install
```

### 2. 配置環境變數
在 `.env` 文件中添加：
```bash
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxx
RESEND_FROM_EMAIL=send@relaygo.pro
```

### 3. 測試郵件發送
```bash
node test-email.js
```

### 4. 編譯代碼
```bash
npm run build:min
```

### 5. 部署到 Railway
```bash
git add .
git commit -m "feat: 實作電子收據郵件自動發送功能"
git push origin main
```

## 📋 Railway 環境變數配置

在 Railway Dashboard 中設置：

| 變數名 | 值 | 說明 |
|--------|-----|------|
| `RESEND_API_KEY` | `re_xxx...` | 從 Resend Dashboard 獲取 |
| `RESEND_FROM_EMAIL` | `send@relaygo.pro` | 發送郵件的域名 |

## 🧪 測試流程

### 本地測試
1. 運行 `node test-email.js`
2. 檢查郵箱是否收到測試郵件

### 生產環境測試
1. 創建測試訂單
2. 完成支付（GoMyPay 測試環境）
3. 等待 5 分鐘（GoMyPay 回調延遲）
4. 檢查客戶郵箱

## 📊 監控

### Railway 日誌關鍵字
- `[Resend]` - 郵件服務相關
- `[ReceiptEmail]` - 收據郵件處理
- `[GOMYPAY Callback]` - 支付回調

### Resend Dashboard
訪問 https://resend.com/dashboard 查看：
- 郵件發送狀態
- 送達率統計
- 錯誤報告

## 🔍 故障排除

### 郵件未發送
1. 檢查 Railway 環境變數是否設置
2. 查看 Railway 日誌中的錯誤訊息
3. 確認客戶有郵箱地址

### 郵件進入垃圾郵件
1. 驗證 Resend 域名 DNS 設置
2. 檢查 SPF、DKIM、DMARC 記錄

### 支付流程異常
- 郵件發送失敗不會影響支付成功
- 郵件發送是異步的，不阻塞主流程

## 📞 技術支援

- Email: dev@relaygo.com
- 客服: support@relaygo.pro

## 📚 詳細文檔

請查看以下文檔獲取更多資訊：

1. **部署指南** - `RECEIPT-EMAIL-DEPLOYMENT.md`
   - 完整的部署步驟
   - 環境變數配置
   - 故障排除

2. **測試指南** - `EMAIL-TESTING-GUIDE.md`
   - 測試步驟
   - 驗證檢查點
   - 常見問題

3. **實作總結** - `IMPLEMENTATION-SUMMARY.md`
   - 技術架構
   - 實作細節
   - 後續計劃

4. **提交指南** - `GIT-COMMIT-GUIDE.md`
   - Git 提交步驟
   - 部署流程
   - 驗證方法

---

**版本**: v1.0.0  
**更新日期**: 2025-01-15  
**狀態**: ✅ 開發完成，待部署測試

