# 階段 0: 前置準備 - 完成總結

**完成日期**: 2025-10-17  
**狀態**: ✅ 完成  
**預計時間**: 1 天  
**實際時間**: 1 小時

---

## 📋 任務清單

### ✅ 已完成的任務

1. **確認 Firebase 專案別名與 ID**
   - ✅ 專案別名：`prod`
   - ✅ 專案 ID：`ride-platform-f1676`
   - ✅ 當前活動專案：`prod (ride-platform-f1676)`

2. **確認 Secret Manager 設定**
   - ✅ Secret 名稱：`OPENAI_API_KEY`
   - ✅ Secret 版本：2（無換行符）
   - ✅ Secret 值：`sk-proj-xxx...`（已驗證可訪問）

3. **確認 Functions 採用 v2 API**
   - ✅ `firebase-functions` 版本：`^5.0.0`（v2 API）
   - ✅ Node.js 版本：20
   - ✅ 修復 `firebase.json` 中的 runtime 設置（從 `nodejs18` 改為 `nodejs20`）

4. **創建實施計劃文檔**
   - ✅ `docs/multi-language-translation-implementation-plan.md`（300 行）
   - ✅ 包含 12 個階段的詳細任務
   - ✅ 包含測試計劃和部署策略

5. **設置任務追蹤**
   - ✅ 創建主任務：「多語言翻譯系統重構」
   - ✅ 創建 13 個子任務（階段 0 到階段 12）
   - ✅ 當前任務狀態：階段 0 進行中

---

## 🔍 發現的問題與修復

### 問題 1: Node.js 版本不一致

**問題描述**:
- `firebase.json` 中的 `runtime` 設置為 `nodejs18`
- `package.json` 中的 `engines.node` 設置為 `20`

**修復方案**:
- 更新 `firebase.json` 中的 `runtime` 為 `nodejs20`

**修復狀態**: ✅ 已修復

### 問題 2: 工作區未初始化 Git 倉庫

**問題描述**:
- 工作區 `d:\repo` 未初始化 Git 倉庫
- 無法創建開發分支

**決策**:
- 暫時跳過創建開發分支
- 建議用戶手動初始化 Git 倉庫（如果需要版本控制）

**狀態**: ⚠️ 待用戶決定

---

## 📊 當前系統狀態

### Firebase 專案配置

**專案資訊**:
- 專案 ID: `ride-platform-f1676`
- 專案別名: `prod`
- 區域: `asia-east1`（推測，基於之前的部署）

**Cloud Functions**:
- Runtime: Node.js 20
- Functions v2 API
- 已部署的 Functions:
  - `onMessageCreate`: 自動翻譯新訊息
  - `translateMessage`: 按需翻譯端點

**Secret Manager**:
- `OPENAI_API_KEY`: 版本 2（無換行符）

**Firestore**:
- 規則文件: `firebase/firestore.rules`
- 索引文件: `firebase/firestore.indexes.json`

### 當前翻譯系統

**數據模型**:
```
chat_rooms/{roomId}/messages/{messageId}
  ├── messageText: string (原文)
  ├── translatedText: string (英文翻譯)
  ├── translations: map
  │   ├── en: {text, model, at, tokensUsed}
  │   ├── ja: {text, model, at, tokensUsed}
  │   └── zh-TW: {text, model, at, tokensUsed}
  ├── senderId: string
  ├── receiverId: string
  ├── createdAt: timestamp
  └── translatedAt: timestamp
```

**翻譯流程**:
1. 用戶發送訊息 → Firestore
2. `onMessageCreate` 觸發 → 自動翻譯到 3 種語言
3. 寫回 Firestore（`translations` 和 `translatedText`）
4. Flutter App 顯示 `translatedText`（固定顯示英文）

**成本**:
- 每條訊息翻譯到 3 種語言
- 成本：~$0.0003 USD/訊息
- 月成本（10,000 訊息）：~$3 USD

---

## 🎯 下一步行動

### 階段 1: 資料模型與安全規則（預計 2-3 天）

**主要任務**:

1. **更新 Firestore 數據模型**
   - [ ] 添加 `users/{uid}.preferredLang`
   - [ ] 添加 `users/{uid}.inputLangHint`
   - [ ] 添加 `users/{uid}.hasCompletedLanguageWizard`
   - [ ] 添加 `chat_rooms/{roomId}.memberIds`
   - [ ] 添加 `chat_rooms/{roomId}.roomLangOverride`
   - [ ] 添加 `messages/{msgId}.detectedLang`
   - [ ] 移除 `messages/{msgId}.translatedText`（逐步遷移）
   - [ ] 移除 `messages/{msgId}.translations`（逐步遷移）

2. **更新 Firestore 安全規則**
   - [ ] 更新 `users/{uid}` 規則：允許讀取自己的語言設定
   - [ ] 更新 `chat_rooms/{roomId}` 規則：允許成員讀取和更新 `roomLangOverride`
   - [ ] 更新 `messages/{msgId}` 規則：允許創建時設置 `detectedLang`

3. **創建數據遷移腳本**
   - [ ] 為現有用戶設置默認語言（根據系統語言或 `zh-TW`）
   - [ ] 為現有聊天室添加 `memberIds`
   - [ ] 測試遷移腳本

4. **更新 Flutter 數據模型**
   - [ ] 更新 `UserProfile` 模型
   - [ ] 更新 `ChatRoom` 模型
   - [ ] 更新 `ChatMessage` 模型

**預期交付物**:
- 更新的 Firestore 規則
- 數據遷移腳本
- 更新的 Flutter 數據模型
- 遷移測試報告

---

## 📚 相關文檔

- ✅ `docs/multi-language-translation-implementation-plan.md` - 完整實施計劃
- ✅ `docs/phase-0-preparation-summary.md` - 階段 0 總結（本文檔）

---

## ⚠️ 重要提醒

### 關於 Git 版本控制

**當前狀態**:
- 工作區 `d:\repo` 未初始化 Git 倉庫
- 無法創建開發分支 `feature/multi-language-translation`

**建議**:
1. **如果你需要版本控制**，請手動初始化 Git 倉庫：
   ```bash
   cd d:\repo
   git init
   git add .
   git commit -m "Initial commit before multi-language translation refactor"
   git checkout -b feature/multi-language-translation
   ```

2. **如果你不需要版本控制**，可以直接在主分支上開發

**我的建議**:
- 強烈建議初始化 Git 倉庫，因為這是一個大規模重構
- 版本控制可以幫助你在出現問題時快速回滾
- 可以使用 Git 分支來隔離開發和生產環境

### 關於數據遷移

**重要**:
- 階段 1 將修改 Firestore 數據模型
- 需要為現有用戶和聊天室添加新欄位
- 建議先在測試環境中執行遷移腳本
- 確保備份 Firestore 數據

### 關於成本控制

**當前系統**:
- 自動翻譯所有訊息到 3 種語言
- 月成本：~$3 USD（10,000 訊息）

**新系統**:
- 按需翻譯（只翻譯用戶需要看的訊息）
- 預計月成本：~$0.3 USD（10,000 訊息）
- **成本降低 90%**

**建議**:
- 在階段 7 實施翻譯端點時，設置 `maxInstances` 限制
- 監測 OpenAI API 使用量
- 設置成本警報

---

## ✅ 階段 0 完成確認

**已完成的任務**:
- ✅ 確認 Firebase 專案別名與 ID
- ✅ 確認 Secret Manager 設定
- ✅ 確認 Functions 採用 v2 API
- ✅ 創建實施計劃文檔
- ✅ 設置任務追蹤
- ✅ 修復 Node.js 版本不一致問題

**待用戶決定**:
- ⚠️ 是否初始化 Git 倉庫並創建開發分支

**準備好進入階段 1**:
- ✅ Firebase 專案配置正確
- ✅ Secret Manager 配置正確
- ✅ 任務追蹤已設置
- ✅ 實施計劃已創建

---

**下一步**: 等待用戶確認後，開始實施**階段 1: 資料模型與安全規則**

---

**文檔創建時間**: 2025-10-17  
**最後更新**: 2025-10-17  
**狀態**: ✅ 完成

