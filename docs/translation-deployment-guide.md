# 聊天翻譯功能部署指南

**版本**: 1.0  
**日期**: 2025-10-17  
**預計部署時間**: 30-45 分鐘

---

## 📋 部署前檢查清單

### 必要條件

- [ ] Firebase CLI 已安裝（`npm install -g firebase-tools`）
- [ ] Firebase 專案已建立（Project ID: `ride-platform-f1676`）
- [ ] OpenAI API 金鑰已取得
- [ ] Node.js 18+ 已安裝
- [ ] 已登入 Firebase CLI（`firebase login`）

### 權限檢查

- [ ] Firebase 專案擁有者或編輯者權限
- [ ] 可以部署 Cloud Functions
- [ ] 可以更新 Firestore 規則

---

## 🚀 部署步驟

### 步驟 1: 準備環境

#### 1.1 確認專案設定

```bash
# 切換到專案根目錄
cd d:/repo

# 確認 Firebase 專案
firebase use ride-platform-f1676

# 查看當前專案
firebase projects:list
```

#### 1.2 安裝 Functions 依賴

```bash
cd firebase/functions
npm install
```

**預期輸出**:
```
added 150 packages in 30s
```

---

### 步驟 2: 設定環境變數

#### 2.1 設定 OpenAI API 金鑰

```bash
# 設定 OpenAI API 金鑰
firebase functions:config:set openai.api_key="sk-proj-YOUR_ACTUAL_KEY_HERE"
```

#### 2.2 設定翻譯配置

```bash
# 啟用自動翻譯
firebase functions:config:set translation.auto_translate="true"

# 設定目標語言（逗號分隔）
firebase functions:config:set translation.target_languages="zh-TW,en,ja"

# 設定 OpenAI 模型
firebase functions:config:set translation.model="gpt-4o-mini"

# 設定成本控制參數
firebase functions:config:set translation.max_length="500"
firebase functions:config:set translation.max_concurrent="2"
```

#### 2.3 驗證配置

```bash
# 查看所有配置
firebase functions:config:get
```

**預期輸出**:
```json
{
  "openai": {
    "api_key": "sk-proj-xxxxx"
  },
  "translation": {
    "auto_translate": "true",
    "target_languages": "zh-TW,en,ja",
    "model": "gpt-4o-mini",
    "max_length": "500",
    "max_concurrent": "2"
  }
}
```

---

### 步驟 3: 部署 Cloud Functions

#### 3.1 部署所有 Functions

```bash
# 從專案根目錄
cd d:/repo

# 部署 Functions
firebase deploy --only functions
```

**預期輸出**:
```
=== Deploying to 'ride-platform-f1676'...

i  deploying functions
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing codebase default for deployment
i  functions: packaged /path/to/functions (XX MB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: creating Node.js 18 function onMessageCreate(asia-east1)...
i  functions: creating Node.js 18 function translateMessage(asia-east1)...
✔  functions[onMessageCreate(asia-east1)] Successful create operation.
✔  functions[translateMessage(asia-east1)] Successful create operation.

✔  Deploy complete!
```

#### 3.2 驗證部署

```bash
# 列出已部署的 Functions
firebase functions:list
```

**預期輸出**:
```
┌──────────────────┬────────────┬─────────────┐
│ Name             │ Region     │ Trigger     │
├──────────────────┼────────────┼─────────────┤
│ onMessageCreate  │ asia-east1 │ Firestore   │
│ translateMessage │ asia-east1 │ HTTPS       │
└──────────────────┴────────────┴─────────────┘
```

---

### 步驟 4: 部署 Firestore 規則

#### 4.1 檢查規則檔案

```bash
# 查看規則檔案
cat firebase/firestore.rules
```

確認包含翻譯相關的規則（第 96-125 行）。

#### 4.2 部署規則

```bash
# 部署 Firestore 規則
firebase deploy --only firestore:rules
```

**預期輸出**:
```
=== Deploying to 'ride-platform-f1676'...

i  deploying firestore
i  firestore: checking firestore.rules for compilation errors...
✔  firestore: rules file firestore.rules compiled successfully
i  firestore: uploading rules firestore.rules...
✔  firestore: released rules firestore.rules to cloud.firestore

✔  Deploy complete!
```

#### 4.3 驗證規則

```bash
# 在 Firebase Console 中查看規則
# https://console.firebase.google.com/project/ride-platform-f1676/firestore/rules
```

---

### 步驟 5: 測試部署

#### 5.1 測試自動翻譯

1. 在 Flutter App 中發送一則訊息
2. 等待 3-5 秒
3. 在 Firestore Console 中檢查 `translations` 欄位

#### 5.2 測試按需翻譯 API

```bash
# 獲取測試用的 ID Token（從 Flutter App）
# 然後執行：

curl -X POST \
  https://asia-east1-ride-platform-f1676.cloudfunctions.net/translateMessage \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "roomId": "test_room",
    "messageId": "test_message",
    "targetLang": "ko"
  }'
```

**預期回應**:
```json
{
  "success": true,
  "translation": {
    "text": "번역된 텍스트",
    "model": "gpt-4o-mini",
    "at": "2025-10-17T10:00:00Z"
  }
}
```

#### 5.3 查看日誌

```bash
# 查看 Cloud Functions 日誌
firebase functions:log

# 只查看翻譯相關日誌
firebase functions:log --only onMessageCreate,translateMessage

# 查看最近 10 分鐘的日誌
firebase functions:log --since 10m
```

---

## 🔧 後台配置（Supabase）

### 在 Supabase 中儲存配置

```sql
-- 連接到 Supabase SQL Editor
-- https://supabase.com/dashboard/project/YOUR_PROJECT/sql

-- 1. 新增 OpenAI API 金鑰
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'ai.openai.api_key',
  '{"key": "sk-proj-xxxxx", "encrypted": false}',
  'OpenAI API 金鑰（用於聊天翻譯）',
  true
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 2. 新增自動翻譯開關
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'translation.auto_translate.enabled',
  'true',
  '是否啟用自動翻譯',
  true
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 3. 新增目標語言清單
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'translation.target_languages',
  '["zh-TW", "en", "ja"]',
  '自動翻譯的目標語言清單',
  true
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 4. 新增成本控制設定
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'translation.max_auto_translate_length',
  '500',
  '自動翻譯的最大字元數',
  true
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 5. 驗證設定
SELECT * FROM system_settings WHERE key LIKE 'translation.%' OR key LIKE 'ai.%';
```

---

## 📊 監控設定

### 1. 設定 Cloud Logging

在 Google Cloud Console 中設定日誌過濾器：

```
resource.type="cloud_function"
resource.labels.function_name=~"onMessageCreate|translateMessage"
severity>=DEFAULT
```

### 2. 設定告警

建立告警規則：

- **錯誤率告警**: 錯誤率 > 5%
- **執行時間告警**: P95 延遲 > 5 秒
- **成本告警**: 每日 Token 使用量 > 100,000

### 3. 建立儀表板

在 Firebase Console > Functions 中查看：

- 執行次數
- 錯誤率
- 執行時間
- 記憶體使用

---

## 🔄 更新與回滾

### 更新 Functions

```bash
# 修改程式碼後重新部署
firebase deploy --only functions

# 只部署特定函數
firebase deploy --only functions:onMessageCreate
```

### 更新環境變數

```bash
# 更新配置
firebase functions:config:set translation.auto_translate="false"

# 重新部署以套用變更
firebase deploy --only functions
```

### 回滾部署

```bash
# 查看部署歷史
firebase functions:log

# 回滾到上一個版本（需要在 Google Cloud Console 中操作）
# https://console.cloud.google.com/functions/list
```

---

## 🐛 故障排除

### 問題 1: Functions 部署失敗

**錯誤訊息**: `Error: HTTP Error: 403, Permission denied`

**解決方案**:
1. 檢查 Firebase 專案權限
2. 啟用必要的 API：
   ```bash
   gcloud services enable cloudfunctions.googleapis.com
   gcloud services enable cloudbuild.googleapis.com
   ```

### 問題 2: 環境變數未生效

**症狀**: Functions 讀取不到環境變數

**解決方案**:
1. 確認配置已設定：
   ```bash
   firebase functions:config:get
   ```
2. 重新部署 Functions：
   ```bash
   firebase deploy --only functions
   ```

### 問題 3: OpenAI API 呼叫失敗

**錯誤訊息**: `Invalid API key`

**解決方案**:
1. 檢查 API 金鑰是否正確
2. 確認 API 金鑰有足夠的額度
3. 檢查 OpenAI 帳戶狀態

---

## ✅ 部署檢查清單

### 部署前

- [ ] 已安裝 Firebase CLI
- [ ] 已取得 OpenAI API 金鑰
- [ ] 已確認 Firebase 專案權限
- [ ] 已備份現有配置

### 部署中

- [ ] Functions 依賴已安裝
- [ ] 環境變數已設定
- [ ] Cloud Functions 已部署
- [ ] Firestore 規則已部署
- [ ] 部署日誌無錯誤

### 部署後

- [ ] 自動翻譯功能正常
- [ ] 按需翻譯 API 正常
- [ ] Firestore 規則正確限制寫入
- [ ] 日誌正常記錄
- [ ] 監控告警已設定
- [ ] 後台配置已同步

---

## 📞 支援聯絡

如遇到部署問題，請聯絡：

- **技術支援**: [您的聯絡方式]
- **Firebase 文檔**: https://firebase.google.com/docs/functions
- **OpenAI 文檔**: https://platform.openai.com/docs

---

**部署完成後，請執行驗收測試並更新部署記錄。**

