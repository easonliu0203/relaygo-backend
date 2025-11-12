# 數據遷移腳本

此目錄包含階段 1（多語言翻譯系統）的數據遷移腳本。

---

## 📋 遷移腳本列表

### 1. `add-user-language-preferences.js`

**目的**: 為現有用戶添加語言偏好設定

**新增欄位**:
- `preferredLang`: `'zh-TW'` (默認繁體中文)
- `inputLangHint`: `'zh-TW'` (默認繁體中文)
- `hasCompletedLanguageWizard`: `false` (未完成語言精靈)

**執行方式**:
```bash
cd firebase
node migrations/add-user-language-preferences.js
```

**預計時間**: 1-2 分鐘（取決於用戶數量）

**Firestore 配額消耗**:
- 讀取：1 次 / 用戶
- 寫入：1 次 / 用戶（如果需要更新）

---

### 2. `add-chat-room-member-ids.js`

**目的**: 為現有聊天室添加 `memberIds` 欄位

**新增欄位**:
- `memberIds`: `[customerId, driverId]`

**執行方式**:
```bash
cd firebase
node migrations/add-chat-room-member-ids.js
```

**預計時間**: 1-2 分鐘（取決於聊天室數量）

**Firestore 配額消耗**:
- 讀取：1 次 / 聊天室
- 寫入：1 次 / 聊天室（如果需要更新）

---

### 3. `add-message-detected-lang.js` (可選)

**目的**: 為現有訊息添加 `detectedLang` 欄位

**新增欄位**:
- `detectedLang`: `'zh-TW'` (默認繁體中文)

**執行方式**:
```bash
cd firebase
node migrations/add-message-detected-lang.js
```

**預計時間**: 5-30 分鐘（取決於訊息數量）

**Firestore 配額消耗**:
- 讀取：1 次 / 聊天室 + 1 次 / 訊息
- 寫入：1 次 / 訊息（如果需要更新）

**注意**:
- ⚠️ 這個遷移是**可選的**，因為舊訊息可以在客戶端動態偵測語言
- ⚠️ 如果訊息數量很大（>10,000），建議跳過此遷移
- ⚠️ 腳本限制最多處理 100 個聊天室，避免處理過多數據

---

## 🚀 執行順序

建議按照以下順序執行遷移腳本：

1. **`add-user-language-preferences.js`** (必須)
2. **`add-chat-room-member-ids.js`** (必須)
3. **`add-message-detected-lang.js`** (可選，建議跳過)

---

## 📋 前置準備

### 1. 安裝依賴

確保已安裝 Firebase Admin SDK：

```bash
cd firebase
npm install
```

### 2. 準備 Service Account Key

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 選擇專案 `ride-platform-f1676`
3. 前往 **專案設定 > 服務帳戶**
4. 點擊 **產生新的私密金鑰**
5. 下載 JSON 文件並重命名為 `service-account-key.json`
6. 將文件放置在 `firebase/` 目錄中

**重要**: `service-account-key.json` 包含敏感資訊，請勿提交到 Git！

### 3. 確認 `.gitignore`

確保 `firebase/.gitignore` 包含以下內容：

```
service-account-key.json
```

---

## 🧪 測試環境執行

建議先在測試環境中執行遷移腳本，確認無誤後再在生產環境執行。

### 修改腳本以使用測試專案

在每個遷移腳本中，修改 `serviceAccountPath` 以使用測試專案的 Service Account Key：

```javascript
const serviceAccountPath = path.join(__dirname, '../service-account-key-test.json');
```

---

## 📊 遷移腳本功能

每個遷移腳本都包含以下功能：

1. **批次處理**: 每批處理 500 個文檔，避免超過 Firestore 限制
2. **跳過已遷移**: 自動跳過已經有新欄位的文檔
3. **錯誤處理**: 捕獲並記錄錯誤，不會中斷整個遷移
4. **統計輸出**: 輸出詳細的遷移統計（成功、跳過、錯誤）
5. **驗證功能**: 遷移完成後自動驗證結果

---

## ⚠️ 注意事項

### Firestore 配額限制

- **免費方案**: 每天 50,000 次讀取 + 20,000 次寫入
- **Blaze 方案**: 無限制，但會收費

如果用戶或訊息數量很大，請注意配額限制。

### 遷移時間

- **用戶語言偏好**: 1-2 分鐘（假設 1,000 個用戶）
- **聊天室成員列表**: 1-2 分鐘（假設 1,000 個聊天室）
- **訊息 detectedLang**: 5-30 分鐘（假設 10,000 條訊息）

### 回滾策略

如果遷移出現問題，可以手動刪除新增的欄位：

```javascript
// 刪除用戶語言偏好
db.collection('users').get().then(snapshot => {
  const batch = db.batch();
  snapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      preferredLang: admin.firestore.FieldValue.delete(),
      inputLangHint: admin.firestore.FieldValue.delete(),
      hasCompletedLanguageWizard: admin.firestore.FieldValue.delete(),
    });
  });
  return batch.commit();
});
```

---

## 📚 相關文檔

- ✅ `docs/multi-language-translation-implementation-plan.md` - 完整實施計劃
- ✅ `docs/phase-0-preparation-summary.md` - 階段 0 總結
- ✅ `docs/phase-1-data-model-summary.md` - 階段 1 總結

---

## 🆘 常見問題

### Q1: 遷移腳本執行失敗，提示 "service-account-key.json not found"

**A**: 請確保已下載 Service Account Key 並放置在 `firebase/` 目錄中。

### Q2: 遷移腳本執行很慢

**A**: 這是正常的，因為 Firestore 有速率限制。如果數據量很大，可能需要等待較長時間。

### Q3: 遷移腳本執行後，部分文檔沒有更新

**A**: 檢查日誌輸出，查看是否有錯誤訊息。可能是因為文檔缺少必要欄位（如 `customerId` 或 `driverId`）。

### Q4: 是否需要執行 `add-message-detected-lang.js`？

**A**: 不需要。這個遷移是可選的，因為舊訊息可以在客戶端動態偵測語言。建議跳過此遷移以節省時間和配額。

---

**創建時間**: 2025-10-17  
**最後更新**: 2025-10-17  
**階段**: 階段 1 - 資料模型與安全規則

