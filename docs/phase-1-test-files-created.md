# 階段 1: 測試檔案創建總結

**日期**: 2025-10-17  
**狀態**: 已完成  
**目的**: 為階段 1 創建完整的測試用例和部署腳本

---

## ✅ 已創建的檔案

### 1. Flutter 測試用例

**檔案**: `mobile/test/models/phase1_data_model_test.dart`

**測試內容**:
- **UserProfile 測試** (6 個測試用例)
  - 預設語言偏好測試
  - 自定義語言偏好測試
  - JSON 序列化測試
  - JSON 反序列化測試
  - 缺失欄位預設值測試

- **ChatRoom 測試** (6 個測試用例)
  - 預設 memberIds 測試
  - 自定義 memberIds 和 roomLangOverride 測試
  - Firestore 序列化測試
  - Firestore 反序列化測試（包含 memberIds）
  - 從 customerId/driverId 生成 memberIds 測試

- **ChatMessage 測試** (5 個測試用例)
  - 預設 detectedLang 測試
  - 自定義 detectedLang 測試
  - Firestore 序列化測試
  - Firestore 反序列化測試
  - 缺失 detectedLang 預設值測試

**執行命令**:
```bash
cd mobile
flutter test test/models/phase1_data_model_test.dart
```

---

### 2. Firestore 安全規則測試

**檔案**: `firebase/test/firestore-rules-phase1.test.js`

**測試內容**:
- **用戶語言偏好測試** (6 個測試用例)
  - 用戶可以讀取自己的語言偏好
  - 用戶可以更新自己的語言偏好
  - 用戶無法讀取其他用戶的語言偏好
  - 用戶無法更新其他用戶的語言偏好
  - 用戶無法創建新用戶文檔
  - 用戶無法刪除用戶文檔

- **聊天室語言覆蓋測試** (6 個測試用例)
  - 聊天室成員可以讀取 roomLangOverride
  - 聊天室成員可以更新 roomLangOverride
  - 非成員無法讀取聊天室
  - 非成員無法更新 roomLangOverride
  - 成員無法創建聊天室
  - 成員無法刪除聊天室

- **訊息語言偵測測試** (3 個測試用例)
  - 新訊息必須包含 detectedLang 欄位
  - 訊息可以有不同的 detectedLang 值（zh-TW, en, ja）
  - 非成員無法發送訊息

**執行命令**:
```bash
cd firebase
npm install  # 首次執行需要安裝依賴
npm run test:rules
```

---

### 3. Firebase 專案配置

**檔案**: `firebase/package.json`

**功能**:
- 定義測試腳本
- 定義遷移腳本
- 定義部署腳本
- 配置 Jest 測試環境

**可用命令**:
```bash
# 測試
npm test                  # 運行所有測試
npm run test:rules        # 運行 Firestore 安全規則測試
npm run test:watch        # 監視模式運行測試

# 遷移
npm run migrate:users     # 遷移用戶語言偏好
npm run migrate:rooms     # 遷移聊天室成員列表
npm run migrate:messages  # 遷移訊息語言偵測
npm run migrate:all       # 運行所有遷移（users + rooms）

# 部署
npm run deploy:rules      # 部署 Firestore 安全規則
npm run deploy:indexes    # 部署 Firestore 索引
npm run deploy:all        # 部署所有 Firestore 配置
```

---

### 4. 部署腳本 (Windows)

**檔案**: `firebase/deploy-phase1.bat`

**功能**:
1. 部署 Firestore 安全規則
2. 執行資料遷移腳本
3. 安裝測試依賴
4. 運行測試用例

**執行方式**:
```bash
cd firebase
deploy-phase1.bat
```

**特點**:
- 自動檢查 Service Account Key
- 提供互動式確認
- 可選擇是否執行訊息語言偵測遷移
- 顯示詳細的執行進度
- 提供錯誤處理和回滾建議

---

### 5. 部署腳本 (Linux/Mac)

**檔案**: `firebase/deploy-phase1.sh`

**功能**:
1. 部署 Firestore 安全規則
2. 執行資料遷移腳本
3. 安裝測試依賴
4. 運行測試用例

**執行方式**:
```bash
cd firebase
chmod +x deploy-phase1.sh
./deploy-phase1.sh
```

**特點**:
- 與 Windows 版本功能相同
- 使用 Bash 腳本語法
- 支持 Linux 和 macOS

---

## 📋 測試覆蓋率

### Flutter 資料模型測試
- **UserProfile**: 6 個測試用例
- **ChatRoom**: 6 個測試用例
- **ChatMessage**: 5 個測試用例
- **總計**: 17 個測試用例

### Firestore 安全規則測試
- **用戶語言偏好**: 6 個測試用例
- **聊天室語言覆蓋**: 6 個測試用例
- **訊息語言偵測**: 3 個測試用例
- **總計**: 15 個測試用例

### 總測試用例數
- **32 個測試用例**

---

## 🚀 執行順序

### 方式 1: 使用部署腳本（推薦）

**Windows**:
```bash
cd firebase
deploy-phase1.bat
```

**Linux/Mac**:
```bash
cd firebase
chmod +x deploy-phase1.sh
./deploy-phase1.sh
```

### 方式 2: 手動執行

**步驟 1: 部署 Firestore 安全規則**
```bash
cd firebase
firebase deploy --only firestore:rules
```

**步驟 2: 執行資料遷移**
```bash
cd firebase
node migrations/add-user-language-preferences.js
node migrations/add-chat-room-member-ids.js
# 可選
node migrations/add-message-detected-lang.js
```

**步驟 3: 運行 Firestore 安全規則測試**
```bash
cd firebase
npm install  # 首次執行
npm run test:rules
```

**步驟 4: 運行 Flutter 資料模型測試**
```bash
cd mobile
flutter test test/models/phase1_data_model_test.dart
```

---

## ⚠️ 注意事項

### 1. Service Account Key

在執行資料遷移之前，需要設置 Firebase Service Account Key：

1. 前往 Firebase Console > Project Settings > Service Accounts
2. 點擊 "Generate New Private Key"
3. 下載 JSON 檔案並保存為 `firebase/service-account-key.json`
4. 確保 `.gitignore` 包含 `service-account-key.json`

詳細說明請參考：`firebase/migrations/README.md`

### 2. Firebase Emulator (可選)

如果要在本地測試 Firestore 安全規則，可以使用 Firebase Emulator：

```bash
cd firebase
firebase emulators:start --only firestore
```

然後在另一個終端運行測試：

```bash
npm run test:rules
```

### 3. 測試失敗處理

如果測試失敗：

1. **檢查錯誤訊息**: 查看測試輸出中的錯誤詳情
2. **驗證資料模型**: 確認 Freezed 代碼已重新生成
3. **檢查安全規則**: 確認 Firestore 規則已正確部署
4. **查看文檔**: 參考 `docs/phase-1-deployment-and-testing-plan.md`

---

## 📊 測試結果記錄

### Flutter 資料模型測試

**執行時間**: _待填寫_  
**測試結果**: _待填寫_  
**通過/失敗**: _待填寫_  
**錯誤訊息**: _待填寫_

### Firestore 安全規則測試

**執行時間**: _待填寫_  
**測試結果**: _待填寫_  
**通過/失敗**: _待填寫_  
**錯誤訊息**: _待填寫_

---

## ✅ 下一步

完成測試後：

1. **檢查測試結果**: 確認所有測試用例都通過
2. **驗證 Firestore 資料**: 檢查遷移後的資料完整性
3. **更新文檔**: 記錄測試結果到本文檔
4. **準備階段 2**: 開始實施語言精靈畫面

---

## 📚 相關文檔

- `docs/phase-1-deployment-and-testing-plan.md` - 部署與測試計劃
- `docs/phase-1-data-model-summary.md` - 資料模型總結
- `docs/phase-1-completion-report.md` - 階段 1 完成報告
- `firebase/migrations/README.md` - 遷移腳本文檔
- `docs/multi-language-translation-implementation-plan.md` - 完整實施計劃

---

**創建日期**: 2025-10-17  
**最後更新**: 2025-10-17  
**狀態**: 等待 Git commit 完成後執行測試

