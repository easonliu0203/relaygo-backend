# 修復：重新部署 Edge Function

**目的**: 部署最新的 Edge Function 代碼，包含狀態映射日誌

---

## 🚀 部署步驟

### 方法 1: 使用 Supabase CLI（推薦）

#### 1. 安裝 Supabase CLI（如果未安裝）

```bash
npm install -g supabase
```

#### 2. 登入 Supabase

```bash
supabase login
```

會打開瀏覽器，登入你的 Supabase 帳號。

#### 3. 連結專案（如果未連結）

```bash
cd supabase
supabase link --project-ref {YOUR_PROJECT_REF}
```

專案 REF 可以在 Supabase Dashboard 的 Settings → General → Reference ID 找到。

#### 4. 部署 Edge Function

```bash
supabase functions deploy sync-to-firestore
```

#### 5. 驗證部署

```bash
# 查看 Edge Function 列表
supabase functions list

# 查看 Edge Function 日誌
supabase functions logs sync-to-firestore
```

---

### 方法 2: 使用 Supabase Dashboard（手動）

#### 1. 打開 Supabase Dashboard

進入你的專案 → Edge Functions

#### 2. 找到 sync-to-firestore 函數

點擊函數名稱進入詳情頁面

#### 3. 更新代碼

1. 點擊「Edit Function」
2. 複製 `supabase/functions/sync-to-firestore/index.ts` 的完整內容
3. 貼上到編輯器中
4. 點擊「Deploy」

#### 4. 驗證部署

1. 點擊「Logs」標籤
2. 觸發一次訂單更新（例如：手動更新訂單狀態）
3. 查看日誌中是否出現新的狀態映射日誌：
   ```
   [狀態映射] Supabase 狀態: xxx
   [狀態映射] Firestore 狀態: xxx
   ```

---

### 方法 3: 使用部署腳本（Windows）

#### 1. 執行部署腳本

```bash
cd supabase
deploy-sync-function.bat
```

#### 2. 按照提示操作

腳本會自動檢查 Supabase CLI 是否安裝，並執行部署。

---

## ✅ 驗證部署成功

### 1. 檢查 Edge Function 版本

在 Supabase Dashboard 中：
1. 進入 Edge Functions → sync-to-firestore
2. 查看「Last deployed」時間
3. 確認是最近的時間

### 2. 觸發測試事件

在 Supabase SQL Editor 中執行：

```sql
-- 手動觸發訂單更新
UPDATE bookings
SET updated_at = NOW()
WHERE id = (
  SELECT id FROM bookings 
  WHERE status = 'driver_confirmed' 
  LIMIT 1
);
```

### 3. 查看 Edge Function 日誌

在 Supabase Dashboard 中：
1. 進入 Edge Functions → sync-to-firestore → Logs
2. 查找最新的日誌
3. 確認看到：
   ```
   [狀態映射] Supabase 狀態: driver_confirmed
   [狀態映射] Firestore 狀態: matched
   ```

如果看到這些日誌，說明部署成功！

---

## 🐛 常見問題

### Q1: Supabase CLI 未安裝

**錯誤訊息**:
```
bash: supabase: command not found
```

**解決方法**:
```bash
npm install -g supabase
```

### Q2: 未登入 Supabase

**錯誤訊息**:
```
Error: Not logged in
```

**解決方法**:
```bash
supabase login
```

### Q3: 專案未連結

**錯誤訊息**:
```
Error: Project not linked
```

**解決方法**:
```bash
supabase link --project-ref {YOUR_PROJECT_REF}
```

### Q4: 部署失敗

**錯誤訊息**:
```
Error: Failed to deploy function
```

**可能原因**:
1. 代碼有語法錯誤
2. 環境變數未設置
3. 權限不足

**解決方法**:
1. 檢查代碼語法
2. 確認環境變數已設置（FIREBASE_SERVICE_ACCOUNT 等）
3. 確認帳號有部署權限

---

## 📝 部署後的測試

### 1. 測試開始行程功能

1. 使用客戶帳號登入 Flutter 應用
2. 找到一個狀態為「已配對」的訂單
3. 點擊「開始行程」按鈕
4. 等待 5-30 秒
5. 檢查訂單狀態是否變為「進行中」

### 2. 檢查日誌

**Backend 日誌**:
```
[API] 客戶開始行程: bookingId=xxx
[API] ✅ 訂單狀態已更新為 trip_started
```

**Edge Function 日誌**:
```
[狀態映射] Supabase 狀態: trip_started
[狀態映射] Firestore 狀態: inProgress
✅ 雙寫成功: orders_rt/xxx 和 bookings/xxx
```

### 3. 檢查 Firestore

在 Firebase Console 中：
1. 打開 `orders_rt/{bookingId}` 文檔
2. 確認 `status` 欄位為 `inProgress`

---

## 🎯 預期結果

部署成功後：

1. ✅ Edge Function 日誌中出現狀態映射日誌
2. ✅ 客戶點擊「開始行程」後，訂單狀態變為「進行中」
3. ✅ Firestore 狀態正確同步為 `inProgress`
4. ✅ 客戶端和司機端都顯示「進行中」

---

## 🔗 相關文件

- **診斷文檔**: `docs/診斷-客戶端開始行程狀態同步問題.md`
- **Edge Function 代碼**: `supabase/functions/sync-to-firestore/index.ts`
- **部署腳本**: `supabase/deploy-sync-function.bat`

---

**文檔版本**: 1.0  
**最後更新**: 2025-10-15

