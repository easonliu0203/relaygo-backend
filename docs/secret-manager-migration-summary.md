# Secret Manager 遷移完成總結

**遷移日期**: 2025-10-17  
**遷移原因**: Firebase Functions Config (`functions.config()`) 將於 2026 年 3 月停用  
**新方案**: Google Cloud Secret Manager

---

## ✅ 已完成的變更

### 1. 程式碼更新

#### 📄 `firebase/functions/index.js`
**變更內容**:
- ✅ 從 `firebase-functions` v1 遷移到 v2
- ✅ 使用 `defineSecret('OPENAI_API_KEY')` 定義 Secret
- ✅ 在 `onDocumentCreated` 中綁定 Secret
- ✅ 在 `onRequest` 中綁定 Secret
- ✅ 透過 `openaiApiKey.value()` 讀取 Secret 值
- ✅ 將 API 金鑰傳遞給 TranslationService

**關鍵變更**:
```javascript
// 舊方式（已棄用）
const apiKey = process.env.OPENAI_API_KEY;

// 新方式（Secret Manager）
const openaiApiKey = defineSecret('OPENAI_API_KEY');
const apiKey = openaiApiKey.value();
```

#### 📄 `firebase/functions/src/services/translationService.js`
**變更內容**:
- ✅ 修改 constructor 接受 `apiKey` 參數
- ✅ 移除從 `process.env` 讀取 API 金鑰
- ✅ 更新 `getTranslationService()` 工廠函數
- ✅ 移除單例模式（因為需要傳入 API 金鑰）

**關鍵變更**:
```javascript
// 舊方式
class TranslationService {
  constructor() {
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }
}

// 新方式
class TranslationService {
  constructor(apiKey) {
    if (!apiKey) {
      throw new Error('OpenAI API key is required');
    }
    this.openai = new OpenAI({
      apiKey: apiKey,
    });
  }
}
```

#### 📄 `firebase/functions/package.json`
**變更內容**:
- ✅ 更新 `firebase-functions` 從 `^4.5.0` 到 `^5.0.0`
- ✅ 支援 v2 Cloud Functions 和 Secret Manager

---

### 2. 新增文檔

#### 📄 `docs/secret-manager-migration-guide.md`
**內容**:
- ✅ Secret Manager 優勢對比表
- ✅ 詳細的遷移步驟（7 個步驟）
- ✅ 三種設定方法（Firebase CLI / gcloud CLI / Console）
- ✅ 進階配置（版本管理、回滾）
- ✅ 故障排除指南
- ✅ 成本估算

#### 📄 `docs/secret-manager-quick-start.md`
**內容**:
- ✅ 快速開始指南（10-15 分鐘）
- ✅ 兩種設定方法（自動化腳本 / 手動設定）
- ✅ 部署步驟
- ✅ 驗證步驟
- ✅ 常見問題 FAQ

---

### 3. 自動化腳本

#### 📄 `firebase/functions/setup-secrets.sh` (Mac/Linux)
**功能**:
- ✅ 自動檢查 Firebase CLI 和 gcloud CLI
- ✅ 啟用 Secret Manager API
- ✅ 創建 OPENAI_API_KEY Secret
- ✅ 驗證 Secret 創建成功
- ✅ 生成 .env 檔案（用於本地測試）

#### 📄 `firebase/functions/setup-secrets.bat` (Windows)
**功能**:
- ✅ Windows 版本的自動化腳本
- ✅ 與 .sh 腳本功能相同
- ✅ 適用於 Windows 命令提示字元

---

### 4. 測試更新

#### 📄 `firebase/functions/test/test-translation.js`
**變更內容**:
- ✅ 所有測試函數更新為接受 API 金鑰參數
- ✅ 從 `process.env.OPENAI_API_KEY` 讀取金鑰（本地測試）
- ✅ 新增金鑰檢查邏輯

---

### 5. 配置文件更新

#### 📄 `firebase/functions/.env.example`
**變更內容**:
- ✅ 新增 Secret Manager 使用說明
- ✅ 區分本地測試和生產環境配置
- ✅ 新增設定指令範例

---

## 📊 變更對比

| 項目 | 舊方式 (functions.config) | 新方式 (Secret Manager) |
|------|--------------------------|------------------------|
| **設定指令** | `firebase functions:config:set openai.api_key="xxx"` | `firebase functions:secrets:set OPENAI_API_KEY` |
| **讀取方式** | `process.env.OPENAI_API_KEY` | `openaiApiKey.value()` |
| **安全性** | ⚠️ 中等 | ✅ 高（加密儲存） |
| **版本控制** | ❌ 無 | ✅ 完整版本歷史 |
| **審計日誌** | ❌ 無 | ✅ 完整審計追蹤 |
| **棄用警告** | ⚠️ 2026/03 停用 | ✅ 長期支援 |

---

## 🚀 部署步驟

### 步驟 1: 設定 Secret

**選項 A: 使用自動化腳本（推薦）**
```bash
# Windows
cd firebase\functions
setup-secrets.bat

# Mac/Linux
cd firebase/functions
chmod +x setup-secrets.sh
./setup-secrets.sh
```

**選項 B: 手動設定**
```bash
firebase use ride-platform-f1676
echo "sk-proj-YOUR_KEY" | firebase functions:secrets:set OPENAI_API_KEY
```

### 步驟 2: 安裝依賴

```bash
cd firebase/functions
npm install
cd ../..
```

### 步驟 3: 部署

```bash
firebase deploy --only functions
```

### 步驟 4: 驗證

```bash
# 檢查 Secret
firebase functions:secrets:access OPENAI_API_KEY

# 查看日誌
firebase functions:log --only onMessageCreate
```

---

## ✅ 驗收檢查清單

### 部署前

- [ ] 已創建 OPENAI_API_KEY Secret
- [ ] 已更新 `firebase-functions` 到 v5.0.0
- [ ] 已執行 `npm install`
- [ ] 已備份現有配置

### 部署後

- [ ] Functions 部署成功（無錯誤）
- [ ] 自動翻譯功能正常
- [ ] 按需翻譯 API 正常
- [ ] 日誌無權限錯誤
- [ ] 無棄用警告

### 清理（選用）

- [ ] 已刪除舊的 functions.config()
- [ ] 已更新相關文檔

---

## 🔧 故障排除

### 問題 1: 權限錯誤

**錯誤**: `Permission denied on secret OPENAI_API_KEY`

**解決方案**:
```bash
gcloud secrets add-iam-policy-binding OPENAI_API_KEY \
  --member="serviceAccount:ride-platform-f1676@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### 問題 2: Secret 不存在

**錯誤**: `Secret OPENAI_API_KEY not found`

**解決方案**:
```bash
# 檢查 Secret 列表
gcloud secrets list

# 重新創建
echo "sk-proj-YOUR_KEY" | firebase functions:secrets:set OPENAI_API_KEY
```

### 問題 3: 部署失敗

**錯誤**: `Function failed on loading user code`

**解決方案**:
```bash
# 查看詳細日誌
firebase functions:log --only onMessageCreate

# 檢查語法錯誤
cd firebase/functions
npm run lint
```

---

## 📈 成本影響

### Secret Manager 定價

- **前 6 個 active secrets**: 免費
- **每個額外 secret**: $0.06/月
- **每 10,000 次存取**: $0.03

### 我們的使用場景

- **Secrets 數量**: 1 個（OPENAI_API_KEY）
- **預估存取次數**: ~10,000 次/月
- **每月成本**: **$0.00**（在免費額度內）

---

## 📚 相關文檔

- [Secret Manager 遷移指南](./secret-manager-migration-guide.md) - 詳細的遷移步驟
- [Secret Manager 快速開始](./secret-manager-quick-start.md) - 10 分鐘快速設定
- [翻譯功能架構](./chat-translate-architecture.md) - 整體架構說明
- [部署指南](./translation-deployment-guide.md) - 完整部署流程

---

## 🎉 遷移完成！

所有程式碼和文檔已更新完成，你現在可以：

1. ✅ 使用最安全的方式儲存 API 金鑰
2. ✅ 不再收到 `functions.config()` 棄用警告
3. ✅ 享受 Secret Manager 的版本控制和審計功能
4. ✅ 輕鬆更新和回滾 API 金鑰

**下一步**: 執行部署並驗證功能正常運作！

