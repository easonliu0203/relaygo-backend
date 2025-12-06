# Railway Builder 調度問題診斷報告

**日期**: 2025-11-22  
**問題**: Railway 部署卡在 "scheduling build on Metal builder"  
**狀態**: ✅ 已觸發重新部署

---

## 🔍 問題診斷

### 症狀
Railway 部署日誌顯示：
```
scheduling build on Metal builder "builder-xiyxqt"
[snapshot] received sha256:1c3a70dad41a060bf75f9495c17aa78a76099aa17bc1190c8563f25146c3336c
[snapshot] receiving snapshot, complete 189 kB [took 1.344152992s]
[snapshot] analyzing snapshot, complete 189 kB [took 8.453418ms]
[snapshot] uploading snapshot, complete 189 kB [took 683.29µs]
scheduling build on Metal builder "builder-ytybgh"
```

部署停在最後一行，沒有繼續執行構建步驟。

---

### 問題分析

#### 與上次問題的對比

| 對比項目 | 第一次問題 | 第二次問題（本次） |
|---------|-----------|------------------|
| **Commit** | `0d8609f` | `fc80e62` |
| **卡住位置** | `load build definition` | `scheduling build on Metal builder` |
| **問題類型** | 配置衝突 | 基礎設施/資源問題 |
| **原因** | `nixpacks.toml` 衝突 | Railway builder 調度問題 |
| **責任方** | 我們的配置錯誤 | Railway 平台問題 |
| **解決方案** | 刪除 `nixpacks.toml` | 觸發重新部署 |

#### 根本原因

**這是 Railway 平台的基礎設施問題，不是代碼或配置問題！**

可能的原因：
1. **Builder 資源不足**: Metal builder "builder-ytybgh" 可能正在處理其他任務
2. **Builder 冷啟動**: Builder 可能需要時間啟動
3. **排隊等待**: 可能有其他部署正在排隊
4. **平台暫時性問題**: Railway 平台可能有暫時性問題

---

## ✅ 解決方案

### 採取的行動

**推送空 commit 觸發重新部署**

```bash
git commit --allow-empty -m "Trigger Railway redeploy - builder scheduling issue"
git push origin main
```

**原理**:
- 空 commit 不改變任何代碼
- 但會觸發 Railway 開始新的部署流程
- 新的部署可能會被分配到不同的 builder
- 避免卡在同一個 builder 上

---

### Git 提交記錄

| Commit | 訊息 | 目的 |
|--------|------|------|
| `0d8609f` | Fix driver location sharing integration | 修復定位分享功能 |
| `fc80e62` | Fix Railway deployment: remove nixpacks.toml | 修復配置衝突 |
| `b0d1588` | Trigger Railway redeploy - builder scheduling issue | 觸發重新部署 |

---

## 📊 預期結果

### Railway 應該執行的步驟

```bash
# 1. 調度到新的 builder（可能不是 builder-ytybgh）
scheduling build on Metal builder "builder-xxxxx"

# 2. 檢測 Node.js 專案
↳ Detected Node
↳ Using npm package manager
↳ Found web command in Procfile

# 3. 安裝依賴
▸ install
  $ npm ci

# 4. 構建 TypeScript
▸ build
  $ npm run build:min

# 5. 部署
Deploy
  $ node dist/minimal-server.js
```

---

## 🎯 驗證清單

### 立即檢查（現在）
- [ ] 登入 Railway Dashboard: https://railway.app
- [ ] 查看最新部署（Commit: `b0d1588`）
- [ ] 確認部署已開始（不再卡在 scheduling）

### 部署過程中
- [ ] 確認 `npm ci` 成功執行
- [ ] 確認 `npm run build:min` 成功執行
- [ ] 確認服務成功啟動

### 部署完成後
- [ ] 確認部署狀態為 "Success"
- [ ] 測試 API 端點：`GET https://api.relaygo.pro/health`
- [ ] 確認服務正常運作

---

## 🔧 如果問題再次發生

### 方案 1: 等待
- 等待 5-10 分鐘
- Railway builder 可能正在啟動
- 刷新 Dashboard 查看進展

### 方案 2: 手動取消並重新部署
1. 在 Railway Dashboard 取消當前部署
2. 點擊 "Redeploy" 重新部署

### 方案 3: 再次推送空 commit
```bash
cd backend
./trigger-redeploy.ps1
# 或
git commit --allow-empty -m "Trigger Railway redeploy - attempt 2"
git push origin main
```

### 方案 4: 檢查 Railway 狀態
- 訪問: https://status.railway.app
- 確認平台是否正常
- 查看是否有正在進行的事件

### 方案 5: 聯繫 Railway 支援
- 如果問題持續超過 30 分鐘
- 在 Railway Dashboard 提交支援票證
- 或在 Railway Discord 尋求幫助: https://discord.gg/railway

---

## 📚 相關資源

### Railway 文檔
- **部署指南**: https://docs.railway.app/deploy/deployments
- **Builder 說明**: https://docs.railway.app/deploy/builds
- **故障排除**: https://docs.railway.app/troubleshoot/fixing-common-errors

### Railway 狀態
- **狀態頁面**: https://status.railway.app
- **Discord 社群**: https://discord.gg/railway

### 本專案文檔
- `RAILWAY_DEPLOYMENT_FIX.md` - 第一次部署問題修復
- `DRIVER_LOCATION_SHARING_COMPLETE_SUMMARY.md` - 定位功能總結

---

## ⚠️ 重要提醒

### 這不是您的錯！
- ✅ 您的代碼沒有問題
- ✅ 您的配置沒有問題（已修復 nixpacks.toml）
- ✅ 這是 Railway 平台的暫時性問題

### 未來遇到類似問題
1. **不要恐慌** - 這是正常的雲端平台問題
2. **先等待 5 分鐘** - 很多時候會自動恢復
3. **推送空 commit** - 簡單有效的解決方案
4. **檢查狀態頁面** - 確認是否是平台問題
5. **聯繫支援** - 如果問題持續

---

## 🎉 總結

**問題**: Railway 部署卡在 builder 調度階段  
**原因**: Railway 平台基礎設施問題（不是代碼問題）  
**解決**: 推送空 commit 觸發重新部署  
**狀態**: ✅ 已觸發，等待 Railway 執行

**下一步**: 
1. 登入 Railway Dashboard 查看部署狀態
2. 確認新的部署正常進行
3. 驗證 API 端點正常運作

---

**文檔版本**: 1.0  
**最後更新**: 2025-11-22

