# 🔍 Railway 部署診斷清單

**日期**: 2025-11-12  
**問題**: Railway 仍然報告 "Missing script: build:min"  
**狀態**: 🔍 診斷中

---

## ✅ 已驗證的項目

### 1. 本地構建 ✅

```bash
cd d:\repo\backend
npm run build:min
```

**結果**: ✅ 構建成功，生成了 21 個 .js 文件

**生成的關鍵文件**:
- ✅ `dist/minimal-server.js` (2.6K)
- ✅ `dist/routes/gomypay.js` (16K)
- ✅ `dist/routes/pricing.js` (7.6K)
- ✅ `dist/routes/bookings.js` (11K)

---

### 2. GitHub 上的 package.json ✅

```bash
git show HEAD:backend/package.json | grep -A 15 "scripts"
```

**結果**: ✅ `build:min` 腳本存在

```json
{
  "scripts": {
    "dev": "nodemon src/minimal-server.ts",
    "build": "tsc -p tsconfig.min.json",
    "build:min": "tsc -p tsconfig.min.json",
    "build:full": "tsc",
    "start": "node dist/minimal-server.js"
  }
}
```

---

### 3. GitHub 上的 railway.json ✅

```bash
git show HEAD:backend/railway.json
```

**結果**: ✅ `railway.json` 存在於 `backend/` 目錄

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm install && npm run build:min"
  },
  "deploy": {
    "startCommand": "node dist/minimal-server.js",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

---

### 4. Git 分支狀態 ✅

```bash
git branch -vv
git log --oneline -5
```

**結果**: ✅ 在 `clean-payment-fix` 分支，已推送到 GitHub

```
* bed94b6 (HEAD -> clean-payment-fix, origin/clean-payment-fix) fix: add railway.json with explicit build command
* bb3f2d0 docs: add final deployment ready report
* c74be4d fix: add build:min script to package.json for Railway deployment
```

---

## ⚠️ 可能的問題

### 問題 1: Railway Root Directory 設置錯誤

**症狀**: Railway 找不到 `package.json` 或 `railway.json`

**檢查方法**:
1. 訪問 Railway Dashboard
2. 進入 Settings → Source
3. 檢查 "Root Directory" 設置

**可能的配置**:
- ❌ **錯誤**: Root Directory = `/` (根目錄)
- ✅ **正確**: Root Directory = `backend` 或 `/backend`

**如果 Root Directory 是根目錄**:
Railway 會在根目錄尋找 `package.json`，但我們的 `package.json` 在 `backend/` 目錄中。

---

### 問題 2: Railway 監聽錯誤的分支

**症狀**: Railway 部署的是舊代碼

**檢查方法**:
1. 訪問 Railway Dashboard
2. 進入 Settings → Source
3. 檢查 "Branch" 設置

**可能的配置**:
- ❌ **錯誤**: Branch = `main`
- ✅ **正確**: Branch = `clean-payment-fix`

---

### 問題 3: Railway 緩存了舊的 package.json

**症狀**: Railway 使用的是沒有 `build:min` 腳本的舊版本

**解決方法**:
1. 在 Railway Dashboard 中清除構建緩存
2. 手動觸發重新部署

---

### 問題 4: railway.json 位置錯誤

**症狀**: Railway 沒有讀取 `railway.json` 配置

**當前狀態**: `railway.json` 在 `backend/` 目錄

**可能的問題**:
- 如果 Railway 的 Root Directory 設置為 `backend`，那麼 `railway.json` 應該在 `backend/` 目錄 ✅
- 如果 Railway 的 Root Directory 設置為 `/`（根目錄），那麼 `railway.json` 應該在根目錄 ❌

---

## 🔧 解決方案

### 方案 A: 設置 Railway Root Directory（推薦）⭐

**步驟**:
1. 訪問 Railway Dashboard: https://railway.app/dashboard
2. 選擇後端服務
3. 進入 **Settings** → **Source**
4. 找到 **"Root Directory"** 設置
5. 設置為 `backend` 或 `/backend`
6. 點擊 **"Save"**
7. 手動觸發重新部署

**為什麼這樣可以解決問題**:
- Railway 會在 `backend/` 目錄中尋找 `package.json`
- Railway 會在 `backend/` 目錄中尋找 `railway.json`
- 所有路徑都會相對於 `backend/` 目錄

---

### 方案 B: 將 railway.json 移到根目錄（備選）

**步驟**:
1. 在根目錄創建 `railway.json`
2. 修改 `buildCommand` 和 `startCommand` 以包含 `backend/` 路徑
3. 推送到 GitHub

**railway.json 內容**（根目錄版本）:
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "cd backend && npm install && npm run build:min"
  },
  "deploy": {
    "startCommand": "cd backend && node dist/minimal-server.js",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

**缺點**: 需要在所有命令前加 `cd backend &&`

---

### 方案 C: 使用 Nixpacks 配置文件（高級）

**步驟**:
1. 在 `backend/` 目錄創建 `nixpacks.toml`
2. 明確指定構建和啟動命令

**nixpacks.toml 內容**:
```toml
[phases.setup]
nixPkgs = ["nodejs-18_x"]

[phases.install]
cmds = ["npm install"]

[phases.build]
cmds = ["npm run build:min"]

[start]
cmd = "node dist/minimal-server.js"
```

---

## 📋 Railway Dashboard 檢查清單

請在 Railway Dashboard 中檢查以下設置：

### Settings → Source

- [ ] **Branch**: 設置為 `clean-payment-fix`
- [ ] **Root Directory**: 設置為 `backend` 或 `/backend`
- [ ] **Auto Deploy**: 啟用（自動部署新的 commits）

### Settings → Build

- [ ] **Build Command**: 應該顯示 `npm install && npm run build:min`（來自 railway.json）
- [ ] **Start Command**: 應該顯示 `node dist/minimal-server.js`（來自 railway.json）

### Variables

- [ ] `PAYMENT_PROVIDER=gomypay`
- [ ] `GOMYPAY_MERCHANT_ID=478A0C2370B2C364AACB347DE0754E14`
- [ ] `GOMYPAY_API_KEY=f0qbvm3c0qb2qdjxwku59wimwh495271`
- [ ] `GOMYPAY_TEST_MODE=true`
- [ ] `GOMYPAY_RETURN_URL=https://api.relaygo.pro/api/payment/gomypay/return`
- [ ] `GOMYPAY_CALLBACK_URL=https://api.relaygo.pro/api/payment/gomypay/callback`
- [ ] `SUPABASE_URL=<your-url>`
- [ ] `SUPABASE_SERVICE_ROLE_KEY=<your-key>`

---

## 🚨 Railway 部署日誌分析

請提供 Railway 部署日誌的**完整輸出**，特別是：

1. **構建階段**:
   ```
   Building...
   Installing dependencies...
   > npm install
   ...
   ```

2. **錯誤訊息**:
   ```
   npm error Missing script: "build:min"
   ```

3. **Railway 使用的路徑**:
   - Railway 在哪個目錄執行 `npm install`？
   - Railway 在哪個目錄執行 `npm run build:min`？

---

## 🎯 下一步行動

### 立即執行（最可能的解決方案）:

1. **訪問 Railway Dashboard**
2. **進入 Settings → Source**
3. **設置 Root Directory = `backend`**
4. **保存並觸發重新部署**

### 如果仍然失敗:

1. **提供 Railway 部署日誌的完整輸出**
2. **提供 Railway Settings → Source 的截圖**
3. **提供 Railway Settings → Build 的截圖**

---

## 📞 需要的信息

請提供以下信息以便進一步診斷：

1. **Railway Root Directory 設置**: 
   - 當前值: `_______`
   - 是否為空: `_______`

2. **Railway Branch 設置**:
   - 當前值: `_______`

3. **Railway 部署日誌**:
   - 構建命令: `_______`
   - 錯誤發生在哪個目錄: `_______`
   - 完整錯誤訊息: `_______`

---

**最可能的問題**: Railway 的 Root Directory 沒有設置為 `backend`，導致 Railway 在根目錄尋找 `package.json`，而不是在 `backend/` 目錄中。

**最快的解決方案**: 在 Railway Dashboard 中設置 Root Directory = `backend`

