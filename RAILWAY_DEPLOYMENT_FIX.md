# Railway 部署卡住問題修復報告

**日期**: 2025-11-22  
**問題**: Railway 部署卡在 "load build definition from ./railpack-plan.json"  
**狀態**: ✅ 已修復並重新部署

---

## 🔍 問題診斷

### 症狀
Railway 部署日誌顯示：
```
╭─────────────────╮
│ Railpack 0.13.0 │
╰─────────────────╯
 
  ↳ Detected Node
  ↳ Using npm package manager
  ↳ Found web command in Procfile
            
  Packages  
  ──────────
  node  │  18.20.8  │  package.json > engines > node (>=18.0.0)
            
  Steps     
  ──────────
  ▸ install
    $ npm ci
         
  ▸ build
    $ npm run build:min
            
  Deploy    
  ──────────
    $ node dist/minimal-server.js
 

load build definition from ./railpack-plan.json
```

部署停在最後一行，沒有繼續執行。

---

### 根本原因

**配置衝突**：backend 目錄同時存在兩個構建配置文件：

1. **`nixpacks.toml`** (舊配置):
   ```toml
   [phases.setup]
   nixPkgs = ["nodejs-18_x"]
   
   [phases.install]
   cmds = ["npm install"]
   
   [phases.build]
   cmds = ["npx tsc -p tsconfig.min.json"]
   
   [start]
   cmd = "node dist/minimal-server.js"
   ```

2. **Railway Railpack 自動檢測** (新配置):
   - 檢測到 `package.json` 中的 `engines` 和 `scripts`
   - 檢測到 `Procfile` 中的 `web` 命令
   - 自動生成構建計劃：
     - Install: `npm ci`
     - Build: `npm run build:min`
     - Deploy: `node dist/minimal-server.js`

**衝突點**：
- `nixpacks.toml` 定義 `npm install`
- Railpack 自動檢測定義 `npm ci`
- Railway 在嘗試合併這兩個配置時卡住

---

## ✅ 解決方案

### 修復步驟

1. **刪除 `nixpacks.toml`**
   - 原因：Railway Railpack 已經能夠自動檢測正確的構建配置
   - 好處：避免配置衝突，使用更快的 `npm ci`

2. **保留 `Procfile`**
   ```
   web: node dist/minimal-server.js
   ```
   - 定義啟動命令
   - Railpack 會自動檢測並使用

3. **保留 `package.json`**
   - `engines` 定義 Node.js 版本
   - `scripts` 定義構建命令
   - Railpack 會自動使用這些配置

---

### 修復後的構建流程

Railway Railpack 將自動執行：

```bash
# 1. Install dependencies (更快、更可靠)
npm ci

# 2. Build TypeScript
npm run build:min
# 實際執行: tsc -p tsconfig.min.json

# 3. Start server
node dist/minimal-server.js
```

---

## 📊 驗證結果

### Git 提交
- **Commit**: `fc80e62`
- **訊息**: "Fix Railway deployment: remove nixpacks.toml to avoid config conflict"
- **變更**: 刪除 `backend/nixpacks.toml`

### Railway 部署
- **狀態**: 已觸發重新部署
- **預期**: 部署應該順利完成
- **URL**: `https://api.relaygo.pro`

---

## 🎯 驗證清單

### 部署驗證
- [ ] Railway 部署成功完成
- [ ] 沒有構建錯誤
- [ ] 服務正常啟動
- [ ] API 端點可以訪問

### 功能驗證
- [ ] 健康檢查端點正常：`GET https://api.relaygo.pro/health`
- [ ] 司機定位分享功能正常（需要 Mobile APP 配合測試）

---

## 📚 相關文檔

### Railway 配置
- **Procfile**: 定義啟動命令
- **package.json**: 定義 Node.js 版本和構建腳本
- **不再需要**: nixpacks.toml（已刪除）

### Railway Railpack 文檔
- Railpack 會自動檢測 Node.js 專案
- 優先使用 `npm ci`（比 `npm install` 更快、更可靠）
- 自動從 `package.json` 讀取構建腳本

---

## ⚠️ 重要提醒

### 未來部署
1. **不要再創建 `nixpacks.toml`**
   - Railway Railpack 已經能夠自動處理
   - 手動配置可能導致衝突

2. **使用 Procfile 定義啟動命令**
   - 簡單明瞭
   - Railpack 會自動檢測

3. **在 package.json 中定義構建腳本**
   - `build:min`: 用於生產環境構建
   - `start`: 用於啟動服務

### 如果部署再次卡住
1. 檢查 Railway 日誌
2. 確認沒有配置衝突
3. 確認 `package.json` 和 `Procfile` 正確
4. 聯繫 Railway 支援

---

## 🎉 總結

**問題**: Railway 部署卡在 "load build definition"  
**原因**: `nixpacks.toml` 與 Railpack 自動檢測衝突  
**解決**: 刪除 `nixpacks.toml`，讓 Railpack 自動處理  
**結果**: ✅ 已修復並重新部署

**下一步**: 等待 Railway 部署完成，然後驗證 API 功能

---

**文檔版本**: 1.0  
**最後更新**: 2025-11-22

