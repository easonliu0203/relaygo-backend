# ⚡ Railway 快速修復指南

**問題**: Railway 報告 "Missing script: build:min"  
**根本原因**: Railway Root Directory 設置錯誤  
**解決時間**: 2 分鐘

---

## 🎯 最可能的問題

**Railway 的 Root Directory 沒有設置為 `backend`**

這導致 Railway 在**根目錄**尋找 `package.json`，而不是在 `backend/` 目錄中。

---

## ⚡ 快速修復步驟

### 步驟 1: 訪問 Railway Dashboard

打開瀏覽器，訪問：
```
https://railway.app/dashboard
```

---

### 步驟 2: 選擇後端服務

在 Dashboard 中找到您的後端項目，點擊進入

---

### 步驟 3: 設置 Root Directory ⭐

1. 點擊 **"Settings"** 標籤
2. 找到 **"Source"** 部分
3. 找到 **"Root Directory"** 設置
4. 設置為 `backend` 或 `/backend`
5. 點擊 **"Save"** 或 **"Update"**

**重要**: 確保 Root Directory 設置為 `backend`，而不是空白或 `/`

---

### 步驟 4: 觸發重新部署

1. 點擊 **"Deployments"** 標籤
2. 點擊 **"Deploy"** 或 **"Redeploy"** 按鈕
3. 選擇最新的 commit (`bed94b6`)

---

### 步驟 5: 監控部署日誌

在 "Deployments" 標籤中，查看最新部署的日誌

**預期的成功日誌**:
```
Building...
Root Directory: backend
Installing dependencies...
> npm install
✅ Dependencies installed

Running build command...
> npm run build:min
> tsc -p tsconfig.min.json
✅ TypeScript compilation successful

Starting server...
> node dist/minimal-server.js
✅ Firebase Admin SDK 已初始化
[GoMyPay] 初始化完成 - 環境: 測試
✅ Server is running on port 3000
```

---

## ✅ 驗證修復成功

### 1. 檢查部署狀態

在 Railway Dashboard 中，確認：
- ✅ 部署狀態為 "Success"
- ✅ 沒有 "Missing script: build:min" 錯誤
- ✅ 服務正在運行

### 2. 測試 API 端點

```bash
curl https://api.relaygo.pro/api/payment/gomypay/return
```

**預期**: 返回 HTML 頁面（不是 404）

---

## 🚨 如果仍然失敗

### 檢查 1: 確認 Branch 設置

在 Settings → Source 中，確認：
- **Branch**: `clean-payment-fix`（不是 `main`）

### 檢查 2: 清除緩存

1. 在 Railway Dashboard 中找到 "Clear Cache" 選項
2. 清除緩存後重新部署

### 檢查 3: 查看完整日誌

在部署日誌中，查找：
- Railway 在哪個目錄執行命令？
- 是否顯示 "Root Directory: backend"？
- 錯誤發生在哪個階段？

---

## 📋 Railway 設置檢查清單

確認以下設置：

### Settings → Source
- [ ] Branch = `clean-payment-fix`
- [ ] Root Directory = `backend`
- [ ] Auto Deploy = 啟用

### Settings → Build（應該自動從 railway.json 讀取）
- [ ] Build Command = `npm install && npm run build:min`
- [ ] Start Command = `node dist/minimal-server.js`

---

## 🎯 總結

**問題**: Railway 找不到 `build:min` 腳本  
**根本原因**: Root Directory 沒有設置為 `backend`  
**解決方案**: 在 Railway Dashboard 中設置 Root Directory = `backend`  
**預計時間**: 2 分鐘

---

**立即行動**: 在 Railway Dashboard 中設置 Root Directory = `backend`，然後重新部署！

