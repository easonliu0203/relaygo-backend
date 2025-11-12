# 多語言翻譯系統實施計劃

**創建日期**: 2025-10-17  
**狀態**: 規劃中  
**預計工期**: 3-4 週

---

## 📋 目錄

1. [當前系統分析](#當前系統分析)
2. [新系統架構](#新系統架構)
3. [實施階段](#實施階段)
4. [技術細節](#技術細節)
5. [測試計劃](#測試計劃)
6. [部署策略](#部署策略)

---

## 🔍 當前系統分析

### 已實現的功能

**Cloud Functions (Firebase Functions v2)**:
- ✅ `onMessageCreate`: 自動翻譯所有訊息到預設語言（zh-TW, en, ja）
- ✅ `translateMessage`: HTTPS 端點，按需翻譯到指定語言
- ✅ Secret Manager 整合（OPENAI_API_KEY）
- ✅ 翻譯結果存儲在 `translations` 欄位
- ✅ `translatedText` 欄位設置為英文翻譯

**Flutter App**:
- ✅ `ChatMessage` 模型：包含 `translatedText` 欄位
- ✅ `MessageBubble` UI：顯示 `translatedText`（固定顯示英文翻譯）
- ✅ `ChatRoom` 模型：基本聊天室資訊
- ✅ `UserProfile` 模型：用戶個人資料（無語言偏好欄位）
- ✅ `LocaleNotifier`: 本地語言設定（僅用於 App UI 語言）

**Firestore 數據結構**:
```
chat_rooms/{roomId}/
  ├── customerId: string
  ├── driverId: string
  ├── lastMessage: string
  └── messages/{messageId}/
      ├── messageText: string (原文)
      ├── translatedText: string (英文翻譯)
      └── translations: map
          ├── en: {text, model, at, tokensUsed}
          ├── ja: {text, model, at, tokensUsed}
          └── zh-TW: {text, model, at, tokensUsed}
```

### 當前系統的限制

1. **自動翻譯所有訊息** - 成本高，不必要
2. **固定顯示英文翻譯** - 無法根據用戶偏好調整
3. **無用戶語言偏好設定** - 無法記住用戶的語言選擇
4. **無聊天室語言覆蓋** - 無法為特定聊天室設置語言
5. **無本地語言偵測** - 無法自動偵測訊息語言
6. **無客戶端快取** - 重複翻譯相同內容
7. **UI 功能有限** - 無法切換原文/翻譯、無折疊功能

---

## 🏗️ 新系統架構

### 核心設計原則

1. **按需翻譯** - 只翻譯用戶需要看的訊息
2. **用戶為中心** - 根據用戶語言偏好自動調整
3. **智能快取** - 減少重複翻譯，降低成本
4. **靈活顯示** - 支持原文/翻譯切換、折疊等

### 數據模型變更

#### 1. Firestore 用戶文檔（`users/{uid}`）

**新增欄位**:
```typescript
{
  preferredLang: string,      // 用戶偏好語言（zh-TW, en, ja, ko, etc.）
  inputLangHint: string,      // 輸入語言提示（用於語言偵測）
  hasCompletedLanguageWizard: boolean  // 是否完成語言精靈
}
```

#### 2. Firestore 聊天室文檔（`chat_rooms/{roomId}`）

**新增欄位**:
```typescript
{
  memberIds: string[],        // 成員 Firebase UID 列表 [customerId, driverId]
  roomLangOverride: string?,  // 聊天室語言覆蓋（可選）
}
```

#### 3. Firestore 訊息文檔（`messages/{msgId}`）

**修改欄位**:
```typescript
{
  messageText: string,        // 原文（保持不變）
  detectedLang: string,       // 偵測到的語言（新增）
  // 移除 translatedText（改為客戶端按需翻譯）
  // 移除 translations（改為客戶端快取）
}
```

### 翻譯流程

#### 舊流程（自動翻譯）
```
用戶發送訊息 → Firestore onCreate 觸發 → Cloud Function 自動翻譯到所有語言 → 寫回 Firestore
```

#### 新流程（按需翻譯）
```
用戶發送訊息 → 寫入 Firestore（只有原文）
                ↓
接收者打開聊天室 → 客戶端偵測語言 → 判斷是否需要翻譯
                ↓
需要翻譯 → 檢查本地快取 → 未命中 → 調用 /translate 端點 → 快取結果 → 顯示翻譯
```

---

## 📅 實施階段

### 階段 0: 前置準備（1 天）

**任務**:
- [x] 確認 Firebase 專案別名與 ID
- [x] 確認 Secret Manager 設定（OPENAI_API_KEY）
- [x] 確認 Functions 採用 v2 API
- [ ] 創建實施計劃文檔
- [ ] 設置開發分支

**交付物**:
- 實施計劃文檔
- 開發分支（`feature/multi-language-translation`）

---

### 階段 1: 資料模型與安全規則（2-3 天）

#### 1.1 Firestore 數據模型更新

**任務**:
- [ ] 更新 `users/{uid}` 文檔結構（添加 `preferredLang`, `inputLangHint`, `hasCompletedLanguageWizard`）
- [ ] 更新 `chat_rooms/{roomId}` 文檔結構（添加 `memberIds`, `roomLangOverride`）
- [ ] 更新 `messages/{msgId}` 文檔結構（添加 `detectedLang`，移除 `translatedText` 和 `translations`）
- [ ] 創建數據遷移腳本（為現有用戶設置默認語言）

**文件**:
- `database/migrations/add-user-language-preferences.sql`（Supabase）
- `firebase/migrations/add-language-fields.js`（Firestore）

#### 1.2 Firestore 安全規則更新

**任務**:
- [ ] 更新 `users/{uid}` 規則：允許讀取自己的語言設定，禁止他人修改
- [ ] 更新 `chat_rooms/{roomId}` 規則：允許成員讀取和更新 `roomLangOverride`
- [ ] 更新 `messages/{msgId}` 規則：允許創建時設置 `detectedLang`

**文件**:
- `firebase/firestore.rules`

**交付物**:
- 更新的 Firestore 規則
- 數據遷移腳本
- 遷移測試報告

---

### 階段 2: 首次登入語言選擇（3-4 天）

#### 2.1 語言精靈畫面

**任務**:
- [ ] 創建 `LanguageWizardPage`（Flutter）
- [ ] 偵測系統語言並預選
- [ ] 顯示支持的語言清單（zh-TW, en, ja, ko, th, vi, id, ms）
- [ ] 完成後寫入 `users/{uid}.preferredLang` 和 `hasCompletedLanguageWizard`
- [ ] 設置本地緩存旗標

**文件**:
- `mobile/lib/shared/pages/language_wizard_page.dart`
- `mobile/lib/shared/widgets/language_selector.dart`

#### 2.2 登入流程整合

**任務**:
- [ ] 修改登入後導航邏輯
- [ ] 檢查 `hasCompletedLanguageWizard`
- [ ] 未完成則導向語言精靈
- [ ] 完成後導向主頁

**文件**:
- `mobile/lib/shared/providers/auth_provider.dart`
- `mobile/lib/apps/customer/presentation/pages/login_page.dart`
- `mobile/lib/apps/driver/presentation/pages/login_page.dart`

**交付物**:
- 語言精靈畫面
- 登入流程整合
- 單元測試

---

### 階段 3: 個人檔案設定頁面（2-3 天）

#### 3.1 設定頁面 UI

**任務**:
- [ ] 創建 `SettingsPage`（客戶端和司機端）
- [ ] 添加「顯示語言」欄位（下拉選單）
- [ ] 添加「輸入語言提示」欄位（下拉選單）
- [ ] 添加說明文字：「此為全域設定，影響所有聊天室預設語言」

**文件**:
- `mobile/lib/apps/customer/presentation/pages/settings_page.dart`
- `mobile/lib/apps/driver/presentation/pages/settings_page.dart`

#### 3.2 設定更新邏輯

**任務**:
- [ ] 創建 `UserLanguagePreferencesNotifier`
- [ ] 實現語言切換邏輯
- [ ] 更新 Firestore `users/{uid}.preferredLang`
- [ ] 觸發全域重渲染

**文件**:
- `mobile/lib/shared/providers/user_language_preferences_provider.dart`

**交付物**:
- 設定頁面 UI
- 語言偏好更新邏輯
- 單元測試

---

### 階段 4: 聊天室語言快速切換（2-3 天）

#### 4.1 地球按鈕 UI

**任務**:
- [ ] 在聊天室視圖右上角添加地球圖標按鈕
- [ ] 點擊開啟底部選單（Bottom Sheet）
- [ ] 選單選項：「跟隨個人設定」+ 語言清單
- [ ] 選擇後寫入本地狀態 `roomViewLang`

**文件**:
- `mobile/lib/shared/pages/chat_room_page.dart`
- `mobile/lib/shared/widgets/language_switcher_bottom_sheet.dart`

#### 4.2 聊天室語言狀態管理

**任務**:
- [ ] 創建 `ChatRoomLanguageNotifier`
- [ ] 管理每個聊天室的 `roomViewLang` 狀態
- [ ] 離開房間保留選擇（使用 SharedPreferences）
- [ ] 重進沿用上次選擇

**文件**:
- `mobile/lib/shared/providers/chat_room_language_provider.dart`

**交付物**:
- 地球按鈕 UI
- 聊天室語言狀態管理
- 單元測試

---

### 階段 5: 顯示邏輯（按需翻譯）（4-5 天）

#### 5.1 語言優先順序邏輯

**任務**:
- [ ] 實現語言優先順序：`roomViewLang > preferredLang > 系統語言`
- [ ] 比較 `detectedLang` 與目標語言
- [ ] 相同 → 顯示原文
- [ ] 不同 → 觸發翻譯

**文件**:
- `mobile/lib/core/services/translation_display_service.dart`

#### 5.2 可視區翻譯觸發

**任務**:
- [ ] 使用 `ListView.builder` 的 `itemBuilder`
- [ ] 只翻譯可視區的訊息
- [ ] 滾動時動態加載翻譯

**文件**:
- `mobile/lib/shared/pages/chat_room_page.dart`

#### 5.3 翻譯結果快取

**任務**:
- [ ] 創建本地快取服務（使用 Hive 或 SharedPreferences）
- [ ] 快取鍵：`sha256(messageText + targetLang)`
- [ ] 快取過期時間：7 天
- [ ] 切換 `roomViewLang` 時刷新快取鍵

**文件**:
- `mobile/lib/core/services/translation_cache_service.dart`

#### 5.4 UI 切換原文/翻譯

**任務**:
- [ ] 添加「顯示原文」按鈕
- [ ] 點擊切換顯示原文或翻譯
- [ ] 狀態保存到本地

**文件**:
- `mobile/lib/shared/widgets/message_bubble.dart`

**交付物**:
- 語言優先順序邏輯
- 可視區翻譯觸發
- 翻譯快取服務
- UI 切換功能
- 單元測試

---

### 階段 6: 本機語言偵測（3-4 天）

#### 6.1 Android 語言偵測（ML Kit）

**任務**:
- [ ] 整合 Google ML Kit Language Identification
- [ ] 實現語言偵測方法
- [ ] 極短訊息（< 10 字元）略過偵測

**文件**:
- `mobile/android/app/build.gradle`（添加依賴）
- `mobile/lib/core/services/language_detection_service_android.dart`

#### 6.2 iOS 語言偵測（系統 API）

**任務**:
- [ ] 使用 `NaturalLanguage` framework
- [ ] 實現語言偵測方法
- [ ] 極短訊息（< 10 字元）略過偵測

**文件**:
- `mobile/ios/Runner/Info.plist`（添加權限）
- `mobile/lib/core/services/language_detection_service_ios.dart`

#### 6.3 Web 語言偵測（cld3 或 franc）

**任務**:
- [ ] 整合 `cld3` 或 `franc` JavaScript 庫
- [ ] 實現語言偵測方法
- [ ] 極短訊息（< 10 字元）略過偵測

**文件**:
- `mobile/web/index.html`（添加腳本）
- `mobile/lib/core/services/language_detection_service_web.dart`

#### 6.4 語言偵測服務整合

**任務**:
- [ ] 創建統一的 `LanguageDetectionService` 介面
- [ ] 根據平台選擇實現
- [ ] 發送訊息時偵測語言並寫入 `detectedLang`

**文件**:
- `mobile/lib/core/services/language_detection_service.dart`

**交付物**:
- Android 語言偵測
- iOS 語言偵測
- Web 語言偵測
- 統一服務介面
- 單元測試

---

### 階段 7: 翻譯端點（Proxy + 快取）（3-4 天）

#### 7.1 翻譯端點實現

**任務**:
- [ ] 創建 `/translate` Cloud Function（HTTPS）
- [ ] 輸入：`text`, `targetLang`
- [ ] 輸出：`translatedText`
- [ ] 添加 Firebase Auth 檢查

**文件**:
- `firebase/functions/src/endpoints/translate.js`

#### 7.2 Firestore 快取實現

**任務**:
- [ ] 創建 `translation_cache` 集合
- [ ] 快取鍵：`sha256(text + targetLang)`
- [ ] 快取過期時間：30 天
- [ ] 查詢快取 → 未命中 → 調用 OpenAI → 寫入快取

**文件**:
- `firebase/functions/src/services/translationCacheService.js`

#### 7.3 錯誤處理與重試

**任務**:
- [ ] 添加指數退避重試邏輯
- [ ] 處理 429 錯誤（配額超限）
- [ ] 設置 `maxInstances` 限制（防止成本失控）
- [ ] 設置區域為 `asia-east1`

**文件**:
- `firebase/functions/src/endpoints/translate.js`

**交付物**:
- 翻譯端點
- Firestore 快取
- 錯誤處理與重試
- 單元測試

---

### 階段 8: 客戶端快取與批次（2-3 天）

#### 8.1 客戶端快取

**任務**:
- [ ] 使用 Hive 創建持久快取
- [ ] 快取鍵：`(messageText, targetLang)`
- [ ] 快取過期時間：7 天
- [ ] 切換 `roomViewLang` 時刷新快取鍵

**文件**:
- `mobile/lib/core/services/translation_cache_service.dart`

#### 8.2 批次翻譯請求

**任務**:
- [ ] 同屏多條待翻譯訊息合併為單個請求
- [ ] 使用 `debounce` 延遲 300ms
- [ ] 批次大小限制：10 條訊息

**文件**:
- `mobile/lib/core/services/translation_batch_service.dart`

**交付物**:
- 客戶端快取
- 批次翻譯邏輯
- 單元測試

---

### 階段 9: 聊天泡泡 UI 行為（2-3 天）

#### 9.1 翻譯版為主列

**任務**:
- [ ] 翻譯版顯示為主要文字（正常字體）
- [ ] 原文顯示為灰色小字（置底）
- [ ] 可折疊原文（點擊展開/收起）

**文件**:
- `mobile/lib/shared/widgets/message_bubble.dart`

#### 9.2 長按選單

**任務**:
- [ ] 添加長按選單
- [ ] 選項：「複製原文」「複製翻譯」「切換顯示」

**文件**:
- `mobile/lib/shared/widgets/message_bubble.dart`

#### 9.3 大量連續訊息優化

**任務**:
- [ ] 保持一致語言，避免頻繁閃爍
- [ ] 使用 `AnimatedSwitcher` 平滑過渡

**文件**:
- `mobile/lib/shared/widgets/message_bubble.dart`

**交付物**:
- 翻譯版為主列 UI
- 長按選單
- 動畫優化
- UI 測試

---

### 階段 10: 測試計劃（3-4 天）

詳見 [測試計劃](#測試計劃) 章節

---

### 階段 11: 部署與回滾（2-3 天）

詳見 [部署策略](#部署策略) 章節

---

### 階段 12: 文件與開關（1-2 天）

#### 12.1 文件撰寫

**任務**:
- [ ] 撰寫「多語翻譯架構說明」
- [ ] 撰寫「最佳化策略」
- [ ] 撰寫「用戶使用指南」

**文件**:
- `docs/multi-language-translation-architecture.md`
- `docs/translation-optimization-strategies.md`
- `docs/user-guide-translation.md`

#### 12.2 遠端配置開關

**任務**:
- [ ] 添加「全域停用翻譯」開關
- [ ] 添加「僅按鈕觸發翻譯」開關
- [ ] 整合 Firebase Remote Config

**文件**:
- `firebase/remoteconfig.template.json`
- `mobile/lib/core/services/remote_config_service.dart`

**交付物**:
- 架構文檔
- 優化策略文檔
- 用戶指南
- 遠端配置開關

---

## 🧪 測試計劃

### 測試環境準備

**測試帳號**:
- 帳號 A：語言偏好 zh-TW（張三）
- 帳號 B：語言偏好 ja-JP（田中太郎）
- 帳號 C：語言偏好 ko-KR（김철수）

### 測試場景

#### 場景 1: 私聊測試（A × B）

**測試步驟**:
1. A 發送中文訊息：「你好，今天天氣很好」
2. B 接收並查看（應顯示日文翻譯）
3. B 發送日文訊息：「こんにちは、元気ですか？」
4. A 接收並查看（應顯示中文翻譯）

**預期結果**:
- ✅ A 看到 B 的訊息翻譯為中文
- ✅ B 看到 A 的訊息翻譯為日文
- ✅ 翻譯結果快取到本地

#### 場景 2: 私聊測試（A × C）

**測試步驟**:
1. A 發送中文訊息：「你好，今天天氣很好」
2. C 接收並查看（應顯示韓文翻譯）
3. C 發送韓文訊息：「안녕하세요, 잘 지내세요?」
4. A 接收並查看（應顯示中文翻譯）

**預期結果**:
- ✅ A 看到 C 的訊息翻譯為中文
- ✅ C 看到 A 的訊息翻譯為韓文
- ✅ 翻譯結果快取到本地

#### 場景 3: 特殊內容測試

**測試內容**:
- 短訊息：「好」（< 10 字元，略過偵測）
- 連結：「https://example.com」（保持原樣）
- @mention：「@張三 你好」（保持 @mention 原樣）
- 長文：200 字的段落
- 表情：「😀😁😂」（略過翻譯）
- 混語：「Hello 你好 こんにちは」（偵測主要語言）

**預期結果**:
- ✅ 短訊息不翻譯
- ✅ 連結保持原樣
- ✅ @mention 保持原樣
- ✅ 長文正確翻譯
- ✅ 表情不翻譯
- ✅ 混語偵測主要語言

#### 場景 4: 離線與恢復測試

**測試步驟**:
1. A 發送訊息
2. B 離線
3. B 恢復在線
4. B 查看訊息

**預期結果**:
- ✅ B 恢復在線後正確翻譯訊息
- ✅ 快取正常工作

#### 場景 5: 地球切換測試

**測試步驟**:
1. A 打開與 B 的聊天室
2. 點擊地球按鈕
3. 切換語言為日文
4. 查看訊息（應顯示日文翻譯）
5. 離開聊天室
6. 重新進入聊天室

**預期結果**:
- ✅ 切換語言後訊息重新翻譯
- ✅ 離開後重進保留語言選擇
- ✅ 快取正確更新

#### 場景 6: 快取命中測試

**測試步驟**:
1. A 發送訊息：「你好」
2. B 查看（觸發翻譯）
3. B 離開聊天室
4. B 重新進入聊天室
5. B 查看相同訊息

**預期結果**:
- ✅ 第二次查看時快取命中（無需調用 API）
- ✅ 翻譯結果立即顯示

---

## 🚀 部署策略

### 部署前檢查

- [ ] 所有單元測試通過
- [ ] 所有整合測試通過
- [ ] 代碼審查完成
- [ ] 文檔更新完成
- [ ] Secret Manager 配置正確

### 部署步驟

#### 1. 更新 Secrets

```bash
# 確認 OPENAI_API_KEY 正確
firebase functions:secrets:access OPENAI_API_KEY
```

#### 2. 部署 Firestore 規則

```bash
firebase deploy --only firestore:rules
```

#### 3. 部署 Cloud Functions

```bash
firebase deploy --only functions
```

#### 4. 數據遷移

```bash
# 執行數據遷移腳本
node firebase/migrations/add-language-fields.js
```

#### 5. 部署 Flutter App

```bash
# 客戶端
cd mobile
flutter build apk --flavor customer
flutter build ios --flavor customer

# 司機端
flutter build apk --flavor driver
flutter build ios --flavor driver
```

### 部署後監測

**監測指標**:
- 錯誤率（Cloud Functions）
- 翻譯請求次數
- 翻譯延遲（P50, P95, P99）
- OpenAI API 成本
- 快取命中率

**監測工具**:
- Firebase Console（Functions 日誌）
- Google Cloud Monitoring
- OpenAI Dashboard（API 使用量）

### 回滾方案

**如果出現問題**:

1. **回滾 Cloud Functions**:
   ```bash
   # 查看版本
   gcloud functions list --region=asia-east1
   
   # 回滾到上一版本
   gcloud functions deploy translate --region=asia-east1 --source=<previous-version>
   ```

2. **回滾 Firestore 規則**:
   ```bash
   # 使用 Firebase Console 回滾到上一版本
   ```

3. **回滾 Flutter App**:
   - 發布上一版本的 APK/IPA

---

## 📊 預期成果

### 成本優化

**當前系統**（自動翻譯）:
- 每條訊息翻譯到 3 種語言
- 成本：~$0.0003 USD/訊息
- 月成本（10,000 訊息）：~$3 USD

**新系統**（按需翻譯）:
- 只翻譯用戶需要看的訊息
- 快取命中率：~70%
- 成本：~$0.00003 USD/訊息（降低 90%）
- 月成本（10,000 訊息）：~$0.3 USD

### 用戶體驗提升

- ✅ 根據用戶語言偏好自動調整
- ✅ 支持聊天室語言快速切換
- ✅ 支持原文/翻譯切換
- ✅ 翻譯結果快取，響應更快
- ✅ 支持折疊原文，UI 更簡潔

---

## 📝 總結

這是一個大規模的系統重構，預計需要 **3-4 週**完成。建議分階段實施，每個階段完成後進行測試和驗證，確保系統穩定性。

**關鍵里程碑**:
- 第 1 週：階段 1-3（數據模型、語言精靈、設定頁面）
- 第 2 週：階段 4-6（聊天室切換、顯示邏輯、語言偵測）
- 第 3 週：階段 7-9（翻譯端點、客戶端快取、UI 優化）
- 第 4 週：階段 10-12（測試、部署、文檔）

**下一步行動**:
1. 確認實施計劃
2. 創建開發分支
3. 開始階段 1 實施

---

**文檔創建時間**: 2025-10-17  
**最後更新**: 2025-10-17  
**狀態**: 規劃中

