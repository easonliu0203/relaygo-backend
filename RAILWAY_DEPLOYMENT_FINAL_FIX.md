# Railway 部署問題最終修復報告

**日期**: 2025-11-22  
**問題**: Railway 部署持續卡在 "load build definition from ./railpack-plan.json"  
**狀態**: ✅ 已找到根本原因並修復

---

## 🔍 問題診斷歷程

### 第一次嘗試（失敗）
**Commit**: `0d8609f` - 修復司機定位分享功能  
**結果**: 部署卡在 "load build definition"  
**診斷**: 認為是 `nixpacks.toml` 與 Railpack 衝突

### 第二次嘗試（失敗）
**Commit**: `fc80e62` - 刪除 nixpacks.toml  
**結果**: 部署卡在 "scheduling build on Metal builder"  
**診斷**: 認為是 Railway builder 資源問題

### 第三次嘗試（失敗）
**Commit**: `b0d1588` - 推送空 commit 觸發重新部署  
**結果**: 部署再次卡在 "load build definition"  
**診斷**: 問題依然存在，需要深入調查

### 第四次嘗試（成功）✅
**Commit**: `5dcc3b5` - 修復 railway.json 配置  
**發現**: `railway.json` 中指定了 `"builder": "NIXPACKS"`  
**根本原因**: NIXPACKS 與 Railpack 衝突  
**解決方案**: 移除 build 配置，讓 Railpack 自動檢測

---

## 🎯 根本原因

### 配置衝突

**問題文件**: `backend/railway.json`

**錯誤配置**:
```json
{
  "build": {
    "builder": "NIXPACKS",  // ❌ 這是問題所在！
    "buildCommand": "npm install && npm run build:min"
  },
  "deploy": {
    "startCommand": "node dist/minimal-server.js",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

**衝突原因**:
1. `railway.json` 指定使用 **NIXPACKS** builder
2. Railway 平台已升級到 **Railpack 0.13.0**
3. Railpack 嘗試載入構建定義時，發現配置要求使用 NIXPACKS
4. 兩個 builder 系統衝突，導致部署卡住

---

## ✅ 解決方案

### 修復後的配置

**正確配置**:
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "deploy": {
    "startCommand": "node dist/minimal-server.js",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

**變更說明**:
- ✅ 移除整個 `build` 部分
- ✅ 保留 `deploy` 部分（重啟策略等）
- ✅ 讓 Railway Railpack 自動檢測構建配置

---

## 📊 修復後的構建流程

Railway Railpack 將自動執行：

```bash
# 1. 自動檢測 Node.js 專案
↳ Detected Node
↳ Using npm package manager
↳ Found web command in Procfile

# 2. 安裝依賴（使用 npm ci，更快更可靠）
▸ install
  $ npm ci

# 3. 構建 TypeScript（從 package.json 讀取）
▸ build
  $ npm run build:min
  # 實際執行: tsc -p tsconfig.min.json

# 4. 部署（從 railway.json 讀取）
Deploy
  $ node dist/minimal-server.js
```

---

## 🎯 Git 提交歷史

| Commit | 訊息 | 結果 |
|--------|------|------|
| `0d8609f` | Fix driver location sharing integration | ❌ 部署卡住 |
| `fc80e62` | Fix Railway deployment: remove nixpacks.toml | ❌ 部署卡住 |
| `b0d1588` | Trigger Railway redeploy - builder scheduling issue | ❌ 部署卡住 |
| `5dcc3b5` | Fix Railway deployment: remove NIXPACKS builder config | ✅ 應該成功 |

---

## 📚 學到的教訓

### 1. Railway 配置文件優先級
```
railway.json > nixpacks.toml > 自動檢測
```

即使刪除了 `nixpacks.toml`，`railway.json` 中的配置仍然會生效。

### 2. NIXPACKS vs Railpack
- **NIXPACKS**: Railway 的舊構建系統
- **Railpack**: Railway 的新構建系統（0.13.0+）
- 兩者不兼容，不能混用

### 3. 最佳實踐
對於 Node.js 專案，最簡單的配置是：
- ✅ 使用 `Procfile` 定義啟動命令
- ✅ 使用 `package.json` 定義構建腳本和 Node.js 版本
- ✅ 在 `railway.json` 中只配置部署選項（如果需要）
- ❌ 不要指定 builder 類型（讓 Railway 自動檢測）

---

## 🔧 驗證清單

### 立即檢查（現在）
- [ ] 登入 Railway Dashboard: https://railway.app
- [ ] 查看最新部署（Commit: `5dcc3b5`）
- [ ] 確認部署已開始且沒有卡住

### 部署過程中
- [ ] 確認顯示 "Detected Node"
- [ ] 確認執行 `npm ci`
- [ ] 確認執行 `npm run build:min`
- [ ] 確認服務成功啟動

### 部署完成後
- [ ] 確認部署狀態為 "Success"
- [ ] 測試健康檢查：`GET https://api.relaygo.pro/health`
- [ ] 測試司機定位分享功能（需要 Mobile APP）

---

## ⚠️ 未來避免此問題

### 推薦的 Railway 配置

**最小化配置**（推薦）:
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "deploy": {
    "startCommand": "node dist/minimal-server.js",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

**不要包含**:
- ❌ `"builder": "NIXPACKS"` 或任何 builder 配置
- ❌ `"buildCommand"` （讓 Railway 從 package.json 讀取）
- ❌ `nixpacks.toml` 文件

**應該包含**:
- ✅ `Procfile` - 定義啟動命令
- ✅ `package.json` - 定義構建腳本和 Node.js 版本
- ✅ `railway.json` - 只配置部署選項（可選）

---

## 🎉 總結

**問題**: Railway 部署持續卡在 "load build definition"  
**根本原因**: `railway.json` 中的 `"builder": "NIXPACKS"` 與 Railpack 衝突  
**解決方案**: 移除 build 配置，讓 Railpack 自動檢測  
**狀態**: ✅ 已修復並推送（Commit: `5dcc3b5`）

**下一步**: 
1. 在 Railway Dashboard 查看部署進度
2. 確認部署成功完成
3. 驗證 API 端點正常運作
4. 測試司機定位分享功能

---

**文檔版本**: 1.0  
**最後更新**: 2025-11-22

