# 包車服務管理系統部署指南

**版本**: v1.3  
**更新日期**: 2025-09-28  
**狀態**: 封測階段  

## 📋 系統概述

包車服務管理系統是一個完整的三端應用系統：
- **管理後台** (web-admin): Next.js 14 管理介面
- **後端 API** (backend): Node.js/Express 或 Python/FastAPI
- **資料庫**: PostgreSQL (Supabase 託管) + Firebase

## 🚀 快速部署

### 前置需求
- Node.js 18+
- Git
- 網路連接

### 1. 克隆專案
```bash
git clone <repository-url>
cd ride-booking-system
```

### 2. 管理後台部署
```bash
cd web-admin
npm install
cp .env.local.example .env.local
# 編輯 .env.local 填入正確的配置
npm run dev
```

### 3. 訪問系統
- 管理後台: http://localhost:3001
- 登入帳號: admin@example.com / admin123456

## 🔧 環境配置

### 管理後台環境變數 (.env.local)
```env
# Supabase 配置
NEXT_PUBLIC_SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Firebase 配置 (可選)
NEXT_PUBLIC_FIREBASE_API_KEY=your-api-key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your-project-id

# API 配置
NEXT_PUBLIC_API_URL=http://localhost:3000

# 開發模式設定
NODE_ENV=development
NEXT_PUBLIC_DEBUG=true

# 封測階段設定
NEXT_PUBLIC_USE_MOCK_AUTH=true
```

## 📊 資料庫設定

### Supabase 設定步驟

1. **建立 Supabase 專案**
   - 訪問 https://supabase.com
   - 建立新專案
   - 選擇 Singapore 區域

2. **執行資料庫腳本**
   ```sql
   -- 在 Supabase SQL 編輯器中執行
   -- 1. 基礎架構
   \i web-admin/database/supabase-setup.sql
   
   -- 2. 價格配置
   \i web-admin/database/pricing-config.sql
   
   -- 3. 測試資料 (可選)
   \i web-admin/database/test-data.sql
   ```

3. **獲取連接資訊**
   - Project URL: 專案設定頁面
   - API Keys: API 設定頁面
   - 更新 .env.local 檔案

## 🎯 功能模組

### 1. 認證系統
- **狀態**: ✅ 完成 (模擬認證)
- **功能**: 管理員登入/登出
- **測試**: http://localhost:3001/login

### 2. 價格配置系統
- **狀態**: ✅ 完成
- **功能**: 
  - 多車型價格設定
  - 套餐時長配置
  - 超時費用計算
  - 優惠價格支援
- **測試**: http://localhost:3001/settings/pricing

### 3. 封測自動支付
- **狀態**: ✅ 完成
- **功能**:
  - 自動支付開關
  - 支付延遲設定
  - 訂單狀態更新
  - 支付記錄生成
- **測試**: http://localhost:3001/orders/create-test

### 4. 訂單管理
- **狀態**: 🚧 基礎功能
- **功能**: 訂單列表、狀態管理
- **待開發**: 完整的訂單流程

### 5. 司機管理
- **狀態**: 🚧 基礎功能
- **功能**: 司機列表、審核管理
- **待開發**: 司機派單邏輯

## 🧪 測試指南

### 1. 功能測試
```bash
# 健康檢查
curl -I http://localhost:3001/health

# 登入測試
curl -X POST http://localhost:3001/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123456"}'

# 價格計算測試
curl -X POST http://localhost:3001/api/admin/calculate-price \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-token" \
  -d '{"vehicle_type":"A","duration":8,"use_discount":false}'
```

### 2. 前端測試
- 登入功能: ✅ 正常
- 價格設定: ✅ 正常
- 訂單測試: ✅ 正常
- 響應式設計: ✅ 正常

### 3. API 測試
- 認證 API: ✅ 正常
- 系統設定 API: ✅ 正常
- 價格計算 API: ✅ 正常
- 儀表板 API: ✅ 正常

## 🔒 安全配置

### 1. 認證安全
- JWT Token 機制
- 請求攔截器
- 自動登出機制
- CORS 配置

### 2. 資料安全
- 環境變數保護
- API 金鑰加密
- 輸入驗證
- SQL 注入防護

### 3. 封測安全
- 模擬認證隔離
- 測試資料標記
- 自動支付限制
- 日誌記錄

## 📈 監控和日誌

### 1. 系統監控
- 健康檢查端點
- 效能監控
- 錯誤追蹤
- 使用統計

### 2. 日誌系統
- 操作日誌
- 錯誤日誌
- 支付日誌
- 系統日誌

### 3. 報表功能
- 營收統計
- 使用者統計
- 司機績效
- 系統效能

## 🚨 故障排除

### 常見問題

1. **管理後台無法啟動**
   ```bash
   # 檢查 Node.js 版本
   node --version  # 需要 18+
   
   # 清除快取
   rm -rf node_modules package-lock.json
   npm install
   ```

2. **登入失敗**
   - 檢查 NEXT_PUBLIC_USE_MOCK_AUTH=true
   - 確認測試帳號: admin@example.com / admin123456
   - 查看瀏覽器開發者工具網路請求

3. **價格計算錯誤**
   - 檢查車型代碼 (A, B, C, D)
   - 確認時長範圍 (1-24小時)
   - 查看 API 回應錯誤訊息

4. **資料庫連接失敗**
   - 檢查 Supabase URL 和 API Key
   - 確認網路連接
   - 驗證資料庫腳本執行狀態

## 📋 部署檢查清單

### 開發環境
- [ ] Node.js 18+ 已安裝
- [ ] 專案已克隆
- [ ] 依賴已安裝 (`npm install`)
- [ ] 環境變數已配置
- [ ] 開發伺服器已啟動
- [ ] 管理後台可正常訪問
- [ ] 登入功能正常
- [ ] 價格配置功能正常
- [ ] 自動支付測試正常

### 生產環境 (待實作)
- [ ] 生產環境配置
- [ ] SSL 憑證配置
- [ ] 域名配置
- [ ] CDN 配置
- [ ] 監控系統配置
- [ ] 備份機制配置

## 🔄 版本更新

### v1.3 (2025-09-28)
- ✅ 價格配置系統
- ✅ 封測自動支付功能
- ✅ 管理後台介面完善
- ✅ API 服務完整

### v1.2 (2025-09-28)
- ✅ 管理後台登入修復
- ✅ 模擬認證系統
- ✅ API 路由建立

### v1.1 (2025-09-28)
- ✅ Supabase 資料庫配置
- ✅ Firebase 模組修復
- ✅ 基礎管理後台

### v1.0 (2025-01-27)
- ✅ 專案初始化
- ✅ 基礎架構設計

## 📞 技術支援

### 聯絡資訊
- 開發團隊: Augment Agent
- 文檔位置: `/docs`
- 問題回報: GitHub Issues

### 有用連結
- 管理後台: http://localhost:3001
- 功能演示: file:///d:/repo/web-admin/demo-pricing-system.html
- API 文檔: 待建立
- 用戶手冊: 待建立

---

**部署指南版本**: v1.3  
**最後更新**: 2025-09-28 03:30  
**維護者**: Augment Agent
