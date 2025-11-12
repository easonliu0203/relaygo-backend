# 手動部署指南 - Edge Function 修復

**狀態**：⚠️ Supabase CLI 未安裝 - 需要手動部署  
**預計時間**：10 分鐘

---

## 🔧 部署方法選擇

### 方法 A：使用 Supabase Dashboard（推薦 - 最簡單）

**優點**：
- 不需要安裝 CLI
- 視覺化介面
- 立即生效

**步驟**：

#### 1. 打開 Supabase Dashboard
```
https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/functions
```

#### 2. 找到 `sync-to-firestore` Function
- 在 Edge Functions 列表中找到 `sync-to-firestore`
- 點擊進入

#### 3. 更新 Function 代碼
- 點擊「Edit」或「Update」按鈕
- 複製修復後的代碼（見下方）
- 貼上並保存

#### 4. 部署
- 點擊「Deploy」按鈕
- 等待部署完成（約 30 秒）
- 確認狀態顯示「Deployed」

---

### 方法 B：安裝 Supabase CLI 後部署

**步驟**：

#### 1. 安裝 Supabase CLI

**Windows (使用 Scoop)**：
```bash
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**或使用 npm**：
```bash
npm install -g supabase
```

#### 2. 登入 Supabase
```bash
supabase login
```

#### 3. 部署 Function
```bash
cd d:\repo
supabase functions deploy sync-to-firestore --project-ref vlyhwegpvpnjyocqmfqc
```

---

### 方法 C：使用 Git Push 部署（如果已設置）

如果您的專案已連接到 Supabase Git 整合：

```bash
git add supabase/functions/sync-to-firestore/index.ts
git commit -m "fix: 修復 Edge Function 同步問題"
git push
```

Supabase 會自動部署。

---

## 📝 修復後的完整代碼

**檔案**：`supabase/functions/sync-to-firestore/index.ts`

這個檔案已經在本地修復完成，位於：
```
d:\repo\supabase\functions\sync-to-firestore\index.ts
```

**關鍵修改**：
1. 第 100 行：`'order'` → `'booking'`
2. 第 101 行：`syncOrderToFirestore` → `syncBookingToFirestore`
3. 第 129-174 行：完整重寫 payload 映射

---

## ✅ 部署後驗證

### 1. 檢查部署狀態

**在 Supabase Dashboard**：
- Edge Functions → sync-to-firestore
- 確認狀態顯示「Deployed」
- 查看「Last deployed」時間是最近的

### 2. 手動觸發測試

**在 Supabase Dashboard**：
1. Edge Functions → sync-to-firestore
2. 點擊「Invoke」按鈕
3. 查看返回結果

**預期結果**：
```json
{
  "message": "事件處理完成",
  "total": 1,
  "success": 1,
  "failure": 0
}
```

### 3. 檢查日誌

**在 Supabase Dashboard**：
- Edge Functions → sync-to-firestore → Logs
- 查找：
  - `✅ Firestore 文檔已更新`
  - 或錯誤訊息

---

## 🔍 驗證同步狀態（自動化）

部署完成後，我會自動執行以下驗證查詢。

---

## 📊 部署檢查清單

- [ ] 打開 Supabase Dashboard
- [ ] 找到 sync-to-firestore Function
- [ ] 確認代碼已更新（檢查第 100 行是否為 `'booking'`）
- [ ] 點擊 Deploy
- [ ] 等待部署完成
- [ ] 點擊 Invoke 測試
- [ ] 檢查返回結果（success: 1）
- [ ] 查看日誌確認無錯誤

---

## ⏭️ 完成部署後

**請告訴我**：
1. 部署是否成功？
2. 手動觸發的返回結果是什麼？
3. 日誌中是否有錯誤？

然後我會繼續執行自動化驗證步驟。

---

## 🆘 如果遇到問題

### 問題：找不到 sync-to-firestore Function

**可能原因**：Function 尚未創建

**解決方案**：
1. 在 Supabase Dashboard 中創建新的 Edge Function
2. 名稱：`sync-to-firestore`
3. 複製 `d:\repo\supabase\functions\sync-to-firestore\index.ts` 的內容
4. 貼上並部署

### 問題：部署失敗

**檢查**：
1. 代碼語法是否正確
2. 環境變數是否設置（FIREBASE_PROJECT_ID, FIREBASE_API_KEY 等）
3. 查看錯誤訊息

### 問題：Invoke 返回錯誤

**檢查**：
1. 查看 Edge Function 日誌
2. 確認環境變數正確
3. 確認 Firestore 權限

---

**下一步**：請選擇一個部署方法並執行，完成後告訴我結果。

