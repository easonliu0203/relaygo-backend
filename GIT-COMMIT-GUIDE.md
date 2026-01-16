# Git 提交和部署指南

## 📋 提交前檢查清單

在提交代碼之前，請確認：

- [x] 代碼編譯成功（`npm run build:min`）
- [x] 沒有 TypeScript 錯誤
- [x] 環境變數範例文件已更新（`.env.example`）
- [x] 文檔已完成（部署指南、測試指南等）
- [x] 敏感資訊已移除（API Keys、密碼等）

## 🔍 檢查修改的文件

```powershell
# 查看所有修改的文件
git status

# 查看具體修改內容
git diff
```

**預期修改的文件**：
```
新增文件：
  src/services/email/resendService.ts
  src/services/email/receiptTemplate.ts
  src/services/email/receiptEmailService.ts
  .env.example
  test-email.js
  RECEIPT-EMAIL-DEPLOYMENT.md
  EMAIL-TESTING-GUIDE.md
  IMPLEMENTATION-SUMMARY.md
  GIT-COMMIT-GUIDE.md

修改文件：
  src/routes/gomypay.ts
  package.json
  package-lock.json
```

## 📝 提交步驟（PowerShell）

### 步驟 1: 添加新文件

```powershell
# 添加郵件服務模組
git add src/services/email/

# 添加修改的路由文件
git add src/routes/gomypay.ts

# 添加依賴文件
git add package.json
git add package-lock.json

# 添加環境變數範例
git add .env.example

# 添加測試腳本
git add test-email.js

# 添加文檔
git add RECEIPT-EMAIL-DEPLOYMENT.md
git add EMAIL-TESTING-GUIDE.md
git add IMPLEMENTATION-SUMMARY.md
git add GIT-COMMIT-GUIDE.md
```

### 步驟 2: 檢查暫存區

```powershell
# 查看已暫存的文件
git status
```

確認所有需要的文件都已添加。

### 步驟 3: 提交

```powershell
git commit -m "feat: 實作電子收據郵件自動發送功能

- 整合 Resend 郵件服務
- 創建多語言收據模板（繁中、簡中、英文）
- 在支付成功回調中自動發送收據
- 支持訂金收據和完整收據
- 異步處理確保不影響支付流程
- 添加錯誤處理和日誌記錄
- 包含完整的部署和測試文檔

新增文件：
- src/services/email/resendService.ts
- src/services/email/receiptTemplate.ts
- src/services/email/receiptEmailService.ts
- .env.example
- test-email.js
- RECEIPT-EMAIL-DEPLOYMENT.md
- EMAIL-TESTING-GUIDE.md
- IMPLEMENTATION-SUMMARY.md

修改文件：
- src/routes/gomypay.ts (添加郵件發送邏輯)
- package.json (添加 resend 依賴)

技術細節：
- 使用 Resend.com 作為郵件服務提供商
- 發送域名：send@relaygo.pro
- 支持多語言（zh-TW, zh-CN, en）
- 響應式 HTML 郵件模板
- 異步發送，不阻塞支付流程
- 完善的錯誤處理和日誌記錄

測試：
- 本地編譯測試通過
- 郵件模板生成正常
- 待部署後進行端到端測試"
```

### 步驟 4: 推送到遠端

```powershell
# 推送到 main 分支
git push origin main
```

## 🚀 Railway 自動部署

推送後，Railway 會自動：

1. **檢測推送**
   - 監聽 GitHub main 分支
   - 觸發新的部署

2. **執行建置**
   ```bash
   npm install
   npm run build:min
   ```

3. **啟動服務**
   ```bash
   node dist/minimal-server.js
   ```

4. **健康檢查**
   - 確認服務正常運行
   - 檢查環境變數

## 📊 部署後驗證

### 1. 檢查 Railway 部署狀態

1. 登入 Railway Dashboard
2. 選擇 RelayGo Backend 項目
3. 查看 Deployments 標籤
4. 確認最新部署狀態為 "Success"

### 2. 查看部署日誌

在 Railway Dashboard 中：
- 點擊最新的 Deployment
- 查看 Build Logs
- 查看 Deploy Logs
- 確認沒有錯誤

### 3. 驗證環境變數

在 Railway Dashboard 的 Variables 標籤中確認：
- `RESEND_API_KEY` 已設置
- `RESEND_FROM_EMAIL` = `send@relaygo.pro`

### 4. 測試 API 端點

```powershell
# 測試健康檢查端點
curl https://api.relaygo.pro/health

# 預期回應
{
  "status": "ok",
  "timestamp": "2025-01-15T..."
}
```

## 🧪 功能測試

### 測試場景 1: 訂金支付

1. 使用 Mobile App 創建新訂單
2. 完成訂金支付（GoMyPay 測試環境）
3. 等待約 5 分鐘（GoMyPay 回調延遲）
4. 檢查 Railway 日誌：
   ```
   [GOMYPAY Callback] 支付成功
   [GOMYPAY Callback] 準備發送收據郵件
   [ReceiptEmail] 開始發送收據郵件
   [Resend] 發送郵件
   [Resend] ✅ 發送成功
   ```
5. 檢查客戶郵箱是否收到訂金收據

### 測試場景 2: 尾款支付

1. 使用已支付訂金的訂單
2. 完成尾款支付
3. 等待約 5 分鐘
4. 檢查日誌和郵箱

## 🔍 故障排除

### 問題 1: 部署失敗

**檢查步驟**：
1. 查看 Railway Build Logs
2. 確認 TypeScript 編譯成功
3. 檢查依賴安裝是否正常

**常見原因**：
- 編譯錯誤
- 依賴版本衝突
- 環境變數缺失

### 問題 2: 郵件未發送

**檢查步驟**：
1. 查看 Railway Deploy Logs
2. 搜索 `[Resend]` 關鍵字
3. 檢查錯誤訊息

**常見原因**：
- RESEND_API_KEY 未設置
- API Key 錯誤或過期
- 客戶沒有郵箱地址

### 問題 3: 支付流程異常

**檢查步驟**：
1. 查看 `[GOMYPAY Callback]` 日誌
2. 確認支付記錄已更新
3. 確認訂單狀態已更新

**注意**：
- 郵件發送失敗不應影響支付成功
- 郵件發送是異步的

## 📞 需要幫助？

如果遇到問題：

1. 查看本文檔的「故障排除」部分
2. 查看 `RECEIPT-EMAIL-DEPLOYMENT.md`
3. 查看 Railway 部署日誌
4. 聯繫技術支援：dev@relaygo.com

## ✅ 提交檢查清單

提交前請確認：

- [ ] 所有新文件已添加到 Git
- [ ] 提交訊息清晰明確
- [ ] 沒有提交敏感資訊（API Keys、密碼等）
- [ ] 代碼編譯成功
- [ ] 文檔完整

部署後請確認：

- [ ] Railway 部署成功
- [ ] 環境變數已設置
- [ ] 日誌沒有錯誤
- [ ] 功能測試通過
- [ ] 郵件成功發送

---

**準備好了嗎？開始提交吧！** 🚀

