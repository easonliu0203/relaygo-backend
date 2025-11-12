# 後台翻譯配置管理指南

## 📋 概述

本文檔說明如何在管理後台配置和管理 AI 翻譯功能的相關設定，包括 API 金鑰管理、翻譯開關、目標語言等。

---

## 🔑 API 金鑰管理

### 支援的 AI 平台

系統設計為支援多個 AI 翻譯平台，方便未來擴展：

- **OpenAI** (gpt-4o-mini) - 目前使用
- **Google Gemini** - 預留
- **Anthropic Claude** - 預留
- **其他平台** - 可擴展

### 金鑰儲存架構

#### 1. Supabase `system_settings` 表

在 Supabase 的 `system_settings` 表中儲存 API 金鑰：

```sql
-- 查看現有設定
SELECT * FROM system_settings WHERE key LIKE 'ai.%';

-- 新增 OpenAI API 金鑰
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'ai.openai.api_key',
  '{"key": "sk-proj-xxxxxxxxxxxxx", "encrypted": false}',
  'OpenAI API 金鑰（用於聊天翻譯）',
  true
);

-- 新增 Gemini API 金鑰（預留）
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'ai.gemini.api_key',
  '{"key": "AIzaSyXXXXXXXXXXXXXXXXXX", "encrypted": false}',
  'Google Gemini API 金鑰（預留）',
  false
);
```

#### 2. Firebase Functions 環境變數

API 金鑰需要同步到 Firebase Functions 的環境變數：

```bash
# 設定 OpenAI API 金鑰
firebase functions:config:set openai.api_key="sk-proj-xxxxxxxxxxxxx"

# 查看當前配置
firebase functions:config:get

# 部署後生效
firebase deploy --only functions
```

---

## ⚙️ 翻譯功能配置

### 1. 自動翻譯開關

控制是否在新訊息創建時自動翻譯。

#### Supabase 設定

```sql
-- 啟用自動翻譯
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'translation.auto_translate.enabled',
  'true',
  '是否啟用自動翻譯（onCreate 觸發）',
  true
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 停用自動翻譯
UPDATE system_settings
SET value = 'false'
WHERE key = 'translation.auto_translate.enabled';
```

#### Firebase Functions 環境變數

```bash
# 啟用自動翻譯
firebase functions:config:set translation.auto_translate="true"

# 停用自動翻譯
firebase functions:config:set translation.auto_translate="false"
```

### 2. 目標語言清單

設定自動翻譯的目標語言。

#### 支援的語言碼

| 語言碼 | 語言名稱 |
|--------|----------|
| zh-TW  | 繁體中文 |
| en     | English  |
| ja     | 日本語   |
| ko     | 한국어   |
| th     | ไทย      |
| vi     | Tiếng Việt |
| id     | Bahasa Indonesia |
| ms     | Bahasa Melayu |

#### Supabase 設定

```sql
-- 設定目標語言清單
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'translation.target_languages',
  '["zh-TW", "en", "ja"]',
  '自動翻譯的目標語言清單',
  true
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
```

#### Firebase Functions 環境變數

```bash
# 設定目標語言（逗號分隔）
firebase functions:config:set translation.target_languages="zh-TW,en,ja"
```

### 3. 成本控制設定

#### 長訊息截斷閾值

```sql
-- 設定自動翻譯的最大字元數
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'translation.max_auto_translate_length',
  '500',
  '自動翻譯的最大字元數（超過則需按需翻譯）',
  true
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
```

```bash
firebase functions:config:set translation.max_length="500"
```

#### 併發控制

```sql
-- 設定最大併發翻譯數
INSERT INTO system_settings (key, value, description, is_active)
VALUES (
  'translation.max_concurrent',
  '2',
  '單訊息最大併發翻譯數',
  true
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
```

```bash
firebase functions:config:set translation.max_concurrent="2"
```

---

## 🖥️ 管理後台 UI 實作建議

### 1. API 金鑰管理頁面

路徑：`/settings/ai-services`

**功能需求：**

- 顯示已配置的 AI 平台清單
- 新增/編輯/刪除 API 金鑰
- 測試 API 金鑰有效性
- 顯示金鑰狀態（啟用/停用）
- 金鑰遮罩顯示（僅顯示前後幾位）

**範例 UI 結構：**

```tsx
// web-admin/src/app/settings/ai-services/page.tsx
export default function AIServicesPage() {
  return (
    <div>
      <h1>AI 服務配置</h1>
      
      {/* OpenAI 配置 */}
      <Card title="OpenAI">
        <Form>
          <Form.Item label="API 金鑰">
            <Input.Password placeholder="sk-proj-xxxxx" />
          </Form.Item>
          <Form.Item label="模型">
            <Select defaultValue="gpt-4o-mini">
              <Option value="gpt-4o-mini">GPT-4o Mini</Option>
              <Option value="gpt-4">GPT-4</Option>
            </Select>
          </Form.Item>
          <Button type="primary">測試連接</Button>
          <Button>儲存</Button>
        </Form>
      </Card>

      {/* Gemini 配置（預留） */}
      <Card title="Google Gemini（預留）">
        <Alert message="此功能尚未啟用" type="info" />
      </Card>
    </div>
  );
}
```

### 2. 翻譯設定頁面

路徑：`/settings/translation`

**功能需求：**

- 自動翻譯開關
- 目標語言多選
- 成本控制參數設定
- 翻譯統計資訊（總翻譯次數、Token 使用量）

**範例 UI 結構：**

```tsx
// web-admin/src/app/settings/translation/page.tsx
export default function TranslationSettingsPage() {
  return (
    <div>
      <h1>翻譯設定</h1>
      
      <Card title="基本設定">
        <Form>
          <Form.Item label="自動翻譯" valuePropName="checked">
            <Switch />
          </Form.Item>
          
          <Form.Item label="目標語言">
            <Checkbox.Group>
              <Checkbox value="zh-TW">繁體中文</Checkbox>
              <Checkbox value="en">English</Checkbox>
              <Checkbox value="ja">日本語</Checkbox>
              <Checkbox value="ko">한국어</Checkbox>
            </Checkbox.Group>
          </Form.Item>
        </Form>
      </Card>

      <Card title="成本控制">
        <Form>
          <Form.Item label="自動翻譯最大字元數">
            <InputNumber min={100} max={1000} defaultValue={500} />
          </Form.Item>
          
          <Form.Item label="最大併發翻譯數">
            <InputNumber min={1} max={5} defaultValue={2} />
          </Form.Item>
        </Form>
      </Card>

      <Card title="翻譯統計">
        <Statistic title="本月翻譯次數" value={1234} />
        <Statistic title="本月 Token 使用" value={56789} />
      </Card>
    </div>
  );
}
```

---

## 🔄 配置同步流程

### 方案 1：手動同步（推薦用於初期）

1. 在 Supabase 更新 `system_settings`
2. 手動執行 Firebase Functions 配置命令
3. 重新部署 Functions

```bash
# 1. 從 Supabase 讀取配置
# 2. 設定到 Firebase Functions
firebase functions:config:set \
  openai.api_key="sk-proj-xxxxx" \
  translation.auto_translate="true" \
  translation.target_languages="zh-TW,en,ja"

# 3. 部署
firebase deploy --only functions
```

### 方案 2：自動同步（未來擴展）

建立 Cloud Function 定期從 Supabase 讀取配置並更新環境變數。

---

## 📊 監控與日誌

### 查看翻譯日誌

```bash
# 查看 Cloud Functions 日誌
firebase functions:log

# 過濾翻譯相關日誌
firebase functions:log --only onMessageCreate,translateMessage
```

### 監控指標

在 Firebase Console > Functions 中查看：

- 執行次數
- 錯誤率
- 執行時間
- 記憶體使用

---

## 🔒 安全注意事項

1. **API 金鑰加密**：未來應實作金鑰加密儲存
2. **存取控制**：僅管理員可查看/編輯 API 金鑰
3. **金鑰輪換**：定期更換 API 金鑰
4. **審計日誌**：記錄所有配置變更

---

## 📝 快速參考

### 常用 SQL 查詢

```sql
-- 查看所有翻譯相關設定
SELECT * FROM system_settings WHERE key LIKE 'translation.%' OR key LIKE 'ai.%';

-- 啟用/停用自動翻譯
UPDATE system_settings SET value = 'true' WHERE key = 'translation.auto_translate.enabled';
UPDATE system_settings SET value = 'false' WHERE key = 'translation.auto_translate.enabled';

-- 更新目標語言
UPDATE system_settings 
SET value = '["zh-TW", "en", "ja", "ko"]' 
WHERE key = 'translation.target_languages';
```

### 常用 Firebase 命令

```bash
# 查看配置
firebase functions:config:get

# 設定配置
firebase functions:config:set key="value"

# 刪除配置
firebase functions:config:unset key

# 部署
firebase deploy --only functions
```

