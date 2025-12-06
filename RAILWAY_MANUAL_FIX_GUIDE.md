# Railway 部署卡住 - 手動修復指南

**日期**: 2025-11-22  
**問題**: 部署持續卡在 "load build definition from ./railpack-plan.json"  
**狀態**: 需要在 Railway Dashboard 手動操作

---

## 🚨 問題說明

經過多次自動修復嘗試（刪除 nixpacks.toml、更新 railway.json、推送空 commit、修改 Procfile），部署仍然卡在同一個地方。

**這是 Railway 平台的內部問題，需要手動清除緩存並重新部署。**

---

## 📋 手動修復步驟（詳細版）

### 步驟 1: 登入 Railway Dashboard

1. 打開瀏覽器
2. 訪問: **https://railway.app**
3. 使用您的帳號登入
4. 等待 Dashboard 載入

---

### 步驟 2: 選擇專案和服務

1. 在 Dashboard 首頁，找到 **"RelayGo Backend"** 專案
2. 點擊專案卡片進入專案頁面
3. 您應該會看到一個或多個服務（Services）
4. 找到並點擊 **backend** 服務（或您的主要服務）

---

### 步驟 3: 清除構建緩存（重要！）

1. 在服務頁面，點擊頂部的 **"Settings"** 標籤
2. 向下滾動到頁面底部
3. 尋找以下區域之一：
   - **"Danger Zone"** 區域
   - **"Advanced"** 區域
   - **"Build Settings"** 區域

4. 尋找以下選項之一：
   - **"Clear Build Cache"** 按鈕
   - **"Reset Build Cache"** 按鈕
   - **"Delete Build Cache"** 按鈕

5. 點擊該按鈕
6. 確認操作（可能會彈出確認對話框）
7. 等待緩存清除完成（通常幾秒鐘）

**為什麼要清除緩存？**
- Railway 可能緩存了舊的 NIXPACKS 配置
- 清除緩存強制 Railway 重新評估所有構建配置

---

### 步驟 4: 取消卡住的部署

1. 點擊頂部的 **"Deployments"** 標籤
2. 您應該會看到部署列表
3. 找到狀態為 **"Building"** 或 **"In Progress"** 的部署
   - 通常是最上面的一個
   - Commit 訊息可能是 "Force Railway rebuild: add comment to Procfile"

4. 點擊該部署右側的 **⋮** (三個點圖標)
5. 在下拉選單中選擇 **"Cancel Deployment"** 或 **"Cancel"**
6. 確認取消操作
7. 等待部署狀態變為 **"Cancelled"**

---

### 步驟 5: 手動觸發重新部署

**選項 A: 從 Deployments 頁面重新部署**

1. 仍然在 **"Deployments"** 標籤
2. 點擊右上角的 **"Deploy"** 按鈕（或 "New Deployment"）
3. 選擇以下選項之一：
   - **"Redeploy"** - 重新部署最新的 commit
   - **"Deploy Latest"** - 部署最新的 commit
   - **"Deploy from Branch"** - 選擇 main 分支

4. 點擊確認
5. 等待新的部署開始

**選項 B: 從 Settings 頁面重新部署**

1. 回到 **"Settings"** 標籤
2. 尋找 **"Redeploy"** 或 **"Trigger Deploy"** 按鈕
3. 點擊該按鈕
4. 確認操作

---

### 步驟 6: 監控新的部署

1. 回到 **"Deployments"** 標籤
2. 您應該會看到一個新的部署開始
3. 點擊該部署查看詳細日誌
4. 觀察構建過程：

**預期的正常流程**:
```
✓ scheduling build on Metal builder
✓ fetched snapshot
✓ using build driver railpack-v0.13.0
✓ Detected Node
✓ Using npm package manager
✓ install: npm ci
  → 下載依賴...
  → 安裝依賴...
✓ build: npm run build:min
  → 編譯 TypeScript...
✓ Deploy: node dist/minimal-server.js
  → 服務啟動...
✓ Deployment successful
```

**如果再次卡住**:
- 記錄卡住的確切位置
- 截圖保存
- 準備聯繫 Railway 支援

---

## 🔧 如果手動操作後仍然失敗

### 選項 1: 檢查 Railway 平台狀態

1. 訪問: **https://status.railway.app**
2. 查看是否有正在進行的事件或維護
3. 如果有問題，等待 Railway 修復

### 選項 2: 聯繫 Railway 支援

1. 在 Railway Dashboard 右下角，點擊 **"Help"** 或 **"Support"** 圖標
2. 選擇 **"Contact Support"** 或 **"Submit Ticket"**
3. 提供以下資訊：
   - 專案名稱: RelayGo Backend
   - 問題描述: Deployment stuck at "load build definition from ./railpack-plan.json"
   - 已嘗試的修復: 刪除 nixpacks.toml, 更新 railway.json, 清除緩存
   - 附上部署日誌截圖

### 選項 3: 加入 Railway Discord 社群

1. 訪問: **https://discord.gg/railway**
2. 加入 Discord 伺服器
3. 在 **#help** 頻道發問
4. 提供專案資訊和問題描述
5. 社群成員或 Railway 團隊可能會提供幫助

### 選項 4: 創建新的 Railway 服務（最後手段）

如果以上所有方法都失敗，可以考慮：

1. 在同一個專案中創建一個新的服務
2. 連接到同一個 GitHub 倉庫
3. 配置環境變數
4. 部署新服務
5. 如果成功，刪除舊服務
6. 更新域名指向新服務

---

## 📊 故障排除檢查清單

### 在 Railway Dashboard 檢查

- [ ] 構建緩存已清除
- [ ] 舊的部署已取消
- [ ] 新的部署已觸發
- [ ] 部署日誌顯示正常進度
- [ ] 沒有卡在 "load build definition"

### 在本地檢查

- [ ] `nixpacks.toml` 已刪除
- [ ] `railway.json` 不包含 "builder" 配置
- [ ] `Procfile` 存在且正確
- [ ] `package.json` 包含正確的 scripts 和 engines
- [ ] 所有更改已推送到 GitHub

### 環境變數檢查

- [ ] 所有必要的環境變數已在 Railway 設定
- [ ] Firebase 憑證已正確配置
- [ ] Supabase URL 和 Key 已設定
- [ ] 其他 API Keys 已設定

---

## 🎯 預期結果

成功部署後，您應該看到：

1. **部署狀態**: ✅ Success
2. **服務狀態**: 🟢 Running
3. **健康檢查**: `GET https://api.relaygo.pro/health` 返回 200 OK
4. **日誌**: 顯示 "Server is running on port XXXX"

---

## 📞 需要幫助？

如果您在執行這些步驟時遇到困難：

1. **截圖保存**每一步的畫面
2. **記錄**任何錯誤訊息
3. **聯繫** Railway 支援或在 Discord 尋求幫助
4. **提供**本文檔作為參考

---

**文檔版本**: 1.0  
**最後更新**: 2025-11-22  
**適用於**: Railway Railpack 0.13.0

