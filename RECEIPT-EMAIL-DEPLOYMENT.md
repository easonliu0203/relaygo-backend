# RelayGo 電子收據郵件功能部署指南

## 📋 功能概述

本功能實現了在用戶完成支付後自動發送電子收據郵件的功能。

### 觸發時機
- **訂金支付完成**：發送訂金收據
- **尾款支付完成**：發送完整收據（包含小費等所有費用）

### 技術架構
- **郵件服務**：Resend.com
- **發送域名**：send@relaygo.pro
- **模板引擎**：自定義 HTML 模板
- **多語言支持**：繁中、簡中、英文

## 🔧 Railway 環境變數配置

### 必要環境變數

在 Railway Dashboard 中添加以下環境變數：

```bash
# Resend 郵件服務配置
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxxxxxxx
RESEND_FROM_EMAIL=send@relaygo.pro
```

### 獲取 Resend API Key

1. 登入 Resend Dashboard: https://resend.com/dashboard
2. 進入 API Keys 頁面
3. 創建新的 API Key 或使用現有的
4. 複製 API Key 並添加到 Railway 環境變數

## 📁 新增文件說明

### 1. 郵件服務模組
**文件**: `src/services/email/resendService.ts`
- Resend SDK 封裝
- 郵件發送核心邏輯
- 錯誤處理和日誌記錄

### 2. 收據模板
**文件**: `src/services/email/receiptTemplate.ts`
- 多語言收據模板
- HTML 郵件生成
- 響應式設計

### 3. 收據郵件服務
**文件**: `src/services/email/receiptEmailService.ts`
- 從資料庫獲取訂單資料
- 組裝收據資料
- 調用郵件服務發送
- 記錄發送日誌

### 4. GoMyPay 回調整合
**修改文件**: `src/routes/gomypay.ts`
- 在支付成功後觸發郵件發送
- 異步處理，不阻塞支付流程
- 錯誤處理確保支付流程穩定

## 🚀 部署步驟

### 步驟 1: 配置環境變數

1. 登入 Railway Dashboard
2. 選擇 RelayGo Backend 項目
3. 進入 Variables 標籤
4. 添加以下環境變數：
   - `RESEND_API_KEY`: 從 Resend Dashboard 獲取
   - `RESEND_FROM_EMAIL`: `send@relaygo.pro`

### 步驟 2: 推送代碼到 GitHub

```powershell
# 檢查修改的文件
git status

# 添加新文件和修改
git add src/services/email/
git add src/routes/gomypay.ts
git add package.json
git add package-lock.json
git add .env.example
git add RECEIPT-EMAIL-DEPLOYMENT.md

# 提交
git commit -m "feat: 實作電子收據郵件自動發送功能

- 整合 Resend 郵件服務
- 創建多語言收據模板（繁中、簡中、英文）
- 在支付成功回調中自動發送收據
- 支持訂金收據和完整收據
- 異步處理確保不影響支付流程
- 添加錯誤處理和日誌記錄"

# 推送到遠端
git push origin main
```

### 步驟 3: 驗證部署

1. Railway 會自動檢測到推送並開始部署
2. 查看部署日誌確認沒有錯誤
3. 檢查環境變數是否正確設置

## 🧪 測試驗證

### 測試場景 1: 訂金支付
1. 創建新訂單
2. 完成訂金支付
3. 檢查客戶郵箱是否收到訂金收據

### 測試場景 2: 尾款支付
1. 使用已支付訂金的訂單
2. 完成尾款支付
3. 檢查客戶郵箱是否收到完整收據

### 測試場景 3: 多語言
1. 測試不同語言設置的用戶
2. 驗證收據郵件使用正確的語言

### 檢查點
- ✅ 郵件成功送達
- ✅ 收據內容正確（訂單號、金額、日期等）
- ✅ 多語言顯示正確
- ✅ 郵件格式美觀（響應式設計）
- ✅ 支付流程不受影響

## 📊 監控和日誌

### Railway 日誌
查看以下日誌關鍵字：
- `[Resend]`: 郵件服務相關日誌
- `[ReceiptEmail]`: 收據郵件處理日誌
- `[GOMYPAY Callback]`: 支付回調日誌

### Resend Dashboard
1. 登入 Resend Dashboard
2. 查看 Emails 頁面
3. 監控郵件發送狀態和送達率

## 🔍 故障排除

### 問題 1: 郵件未發送
**可能原因**:
- RESEND_API_KEY 未設置或錯誤
- 客戶沒有郵箱地址

**解決方法**:
1. 檢查 Railway 環境變數
2. 查看日誌中的錯誤訊息
3. 驗證客戶資料中有郵箱

### 問題 2: 郵件進入垃圾郵件
**可能原因**:
- DNS 記錄未正確設置
- 郵件內容觸發垃圾郵件過濾器

**解決方法**:
1. 驗證 Resend 域名 DNS 設置
2. 檢查 SPF、DKIM、DMARC 記錄

### 問題 3: 支付流程受影響
**可能原因**:
- 郵件發送阻塞了主流程

**解決方法**:
- 代碼已使用 setTimeout 異步處理
- 郵件發送錯誤不會影響支付成功

## 📝 後續優化建議

### 1. 郵件日誌表
創建專門的 `email_logs` 表記錄所有郵件發送：
```sql
CREATE TABLE email_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES bookings(id),
  customer_id UUID REFERENCES users(id),
  email_type VARCHAR(50),
  recipient_email VARCHAR(255),
  subject TEXT,
  status VARCHAR(20),
  message_id VARCHAR(255),
  error_message TEXT,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. 重試機制
實作郵件發送失敗的重試邏輯：
- 使用 Bull Queue 管理郵件發送任務
- 失敗後自動重試 3 次
- 記錄重試次數和結果

### 3. 手動重發功能
在管理後台添加手動重發收據的功能：
- 查看郵件發送歷史
- 一鍵重發收據
- 批量發送功能

### 4. 更多郵件類型
擴展郵件服務支持更多場景：
- 訂單確認郵件
- 司機分配通知
- 行程提醒郵件
- 評價邀請郵件

## 🔐 安全注意事項

1. **API Key 保護**
   - 絕不在代碼中硬編碼 API Key
   - 只在 Railway 環境變數中設置
   - 定期輪換 API Key

2. **郵件內容**
   - 不包含敏感的支付資訊（如完整卡號）
   - 只顯示必要的交易資訊
   - 遵守隱私保護法規

3. **發送頻率**
   - 避免重複發送
   - 實作發送頻率限制
   - 監控異常發送行為

## 📞 聯絡資訊

如有問題或需要協助，請聯繫：
- Email: support@relaygo.pro
- 技術支援: dev@relaygo.com

