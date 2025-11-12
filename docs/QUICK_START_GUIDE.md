# 🚀 快速啟動指南

> **目標**：幫助新開發者在 30 分鐘內完成環境配置並運行專案

**更新日期**：2025-01-12  
**適用對象**：新加入的開發者、AI 助理

---

## 📋 前置要求

### 必需安裝的軟體

- [ ] **Node.js** 18+ （Backend API）
- [ ] **Flutter** 3.16+ （Mobile APP）
- [ ] **Firebase CLI** （部署 Firestore 規則和索引）
- [ ] **Git** （版本控制）
- [ ] **Android Studio** 或 **Xcode**（移動開發）

### 必需的帳號

- [ ] **Supabase** 帳號（已有專案：`vlyhwegpvpnjyocqmfqc`）
- [ ] **Firebase** 帳號（已有專案：`ride-platform-f1676`）
- [ ] **Google Cloud** 帳號（Google Maps API）

---

## 🎯 30 分鐘快速啟動

### 步驟 1：克隆專案（2 分鐘）

```bash
# 克隆專案
git clone <repository-url>
cd <project-directory>

# 查看專案結構
ls -la
```

**預期結果**：
```
backend/          # Node.js 後端 API
mobile/           # Flutter 移動應用
web-admin/        # Next.js 管理後台
firebase/         # Firebase 配置
supabase/         # Supabase 配置
docs/             # 開發文檔
```

---

### 步驟 2：閱讀核心文檔（10 分鐘）

**必讀文檔**（按順序）：

1. **DOCS_README.md**（3 分鐘）
   - 了解文檔結構
   - 了解使用流程

2. **QUICK_REFERENCE.md**（5 分鐘）
   - 記住 ID 使用規則
   - 記住固定端口配置
   - 記住 RLS 和 Firestore 規則

3. **DEVELOPMENT_CHECKLIST.md**（2 分鐘）
   - 瀏覽檢查清單
   - 保存以備後用

**⚠️ 重要**：不要跳過這一步！這些文檔包含關鍵的架構約束。

---

### 步驟 3：配置環境變數（8 分鐘）

#### 3.1 Backend API 環境變數

```bash
cd backend
cp .env.example .env
```

**編輯 `backend/.env`**：

```bash
# ⚠️ 固定配置 - 不可更改
NODE_ENV=development
PORT=3000  # ← 固定端口
API_BASE_URL=http://localhost:3000
WEB_ADMIN_URL=http://localhost:3001  # ← 固定端口
CORS_ORIGIN=http://localhost:3001,http://localhost:3000

# Supabase 配置（從 Supabase Dashboard 獲取）
SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
SUPABASE_ANON_KEY=<從 Supabase Dashboard 複製>
SUPABASE_SERVICE_ROLE_KEY=<從 Supabase Dashboard 複製>

# Firebase 配置（從 Firebase Console 下載 Service Account JSON）
FIREBASE_PROJECT_ID=ride-platform-f1676
FIREBASE_PRIVATE_KEY="<從 Service Account JSON 複製>"
FIREBASE_CLIENT_EMAIL=<從 Service Account JSON 複製>
```

**如何獲取 Supabase Keys**：
1. 前往 https://app.supabase.com/project/vlyhwegpvpnjyocqmfqc/settings/api
2. 複製 `anon` `public` key → `SUPABASE_ANON_KEY`
3. 複製 `service_role` `secret` key → `SUPABASE_SERVICE_ROLE_KEY`

**如何獲取 Firebase Service Account**：
1. 前往 https://console.firebase.google.com/project/ride-platform-f1676/settings/serviceaccounts/adminsdk
2. 點擊「產生新的私密金鑰」
3. 下載 JSON 文件
4. 複製 `private_key`、`client_email` 等欄位

#### 3.2 Flutter APP 環境變數

```bash
cd mobile
cp .env.example .env
```

**編輯 `mobile/.env`**：

```bash
# ⚠️ 固定配置 - 不可更改
API_BASE_URL=http://localhost:3000/api  # ← 固定端口
WS_BASE_URL=ws://localhost:3000

# Firebase 配置
FIREBASE_PROJECT_ID=ride-platform-f1676
FIREBASE_API_KEY=AIzaSyC9HGGFyVONzKcjTNAr1FQo_ivGyrByQz4
FIREBASE_AUTH_DOMAIN=ride-platform-f1676.firebaseapp.com
FIREBASE_STORAGE_BUCKET=ride-platform-f1676.firebasestorage.app

# Supabase 配置
SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
SUPABASE_ANON_KEY=<從 Supabase Dashboard 複製>
```

#### 3.3 Web Admin 環境變數

```bash
cd web-admin
cp .env.example .env.local
```

**編輯 `web-admin/.env.local`**：

```bash
# ⚠️ 固定配置 - 不可更改
NEXT_PUBLIC_API_URL=http://localhost:3000  # ← 固定端口
NEXT_PUBLIC_PORT=3001  # ← 固定端口

# Supabase 配置
NEXT_PUBLIC_SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<從 Supabase Dashboard 複製>
```

---

### 步驟 4：安裝依賴（5 分鐘）

#### 4.1 Backend API

```bash
cd backend
npm install
```

#### 4.2 Flutter APP

```bash
cd mobile
flutter pub get
```

#### 4.3 Web Admin

```bash
cd web-admin
npm install
```

---

### 步驟 5：啟動服務（5 分鐘）

#### 5.1 啟動 Backend API

```bash
cd backend
npm run dev
```

**預期輸出**：
```
Server is running on port 3000 in development mode
Health check available at http://localhost:3000/health
```

**驗證**：
```bash
curl http://localhost:3000/health
```

#### 5.2 啟動 Flutter APP（客戶端）

```bash
cd mobile
flutter run --flavor customer --target lib/apps/customer/main_customer.dart
```

**或使用腳本**：
```bash
# Windows
scripts\run-customer.bat

# Linux/Mac
./scripts/run-customer.sh
```

#### 5.3 啟動 Flutter APP（司機端）

```bash
cd mobile
flutter run --flavor driver --target lib/apps/driver/main_driver.dart
```

**或使用腳本**：
```bash
# Windows
scripts\run-driver.bat

# Linux/Mac
./scripts/run-driver.sh
```

#### 5.4 啟動 Web Admin（可選）

```bash
cd web-admin
npm run dev
```

**預期輸出**：
```
ready - started server on 0.0.0.0:3001, url: http://localhost:3001
```

---

## ✅ 驗證安裝

### 檢查清單

- [ ] Backend API 運行在 `http://localhost:3000`
- [ ] Backend API `/health` 端點返回 200
- [ ] Flutter APP 成功啟動（客戶端或司機端）
- [ ] Flutter APP 可以連接到 Backend API
- [ ] Flutter APP 可以連接到 Firebase
- [ ] Web Admin 運行在 `http://localhost:3001`（可選）

### 常見問題

#### 問題 1：Backend API 無法啟動

**錯誤訊息**：`Error: Cannot find module ...`

**解決方案**：
```bash
cd backend
rm -rf node_modules package-lock.json
npm install
```

#### 問題 2：Flutter APP 無法連接 Backend API

**錯誤訊息**：`SocketException: Failed to connect to localhost:3000`

**解決方案**：
1. 確認 Backend API 正在運行
2. 確認 `mobile/.env` 中的 `API_BASE_URL` 正確
3. 如果使用 Android 模擬器，使用 `http://10.0.2.2:3000/api` 而不是 `http://localhost:3000/api`

#### 問題 3：Flutter APP 無法連接 Firebase

**錯誤訊息**：`FirebaseException: [core/no-app]`

**解決方案**：
1. 確認 `mobile/.env` 中的 Firebase 配置正確
2. 確認已執行 `flutter pub get`
3. 重新啟動 APP

---

## 📚 下一步

### 開發前準備

1. **閱讀完整架構文檔**：
   - [ARCHITECTURE.md](../ARCHITECTURE.md)

2. **了解開發流程**：
   - [DEVELOPMENT_CHECKLIST.md](../DEVELOPMENT_CHECKLIST.md)

3. **部署 Firestore 規則和索引**：
   ```bash
   # 部署安全規則
   firebase deploy --only firestore:rules
   
   # 部署索引
   firebase deploy --only firestore:indexes
   ```

### 開始開發

1. **選擇一個任務**：
   - 查看專案的 Issue 或 Task Board

2. **創建分支**：
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **開發前檢查**：
   - 複製 `DEVELOPMENT_CHECKLIST.md` 中的相關清單
   - 逐項檢查

4. **開始開發**：
   - 參考 `QUICK_REFERENCE.md` 中的代碼範本
   - 遵循架構約束

5. **測試**：
   - 運行單元測試
   - 運行整合測試
   - 手動測試

6. **提交代碼**：
   ```bash
   git add .
   git commit -m "feat: your feature description"
   git push origin feature/your-feature-name
   ```

---

## 🆘 需要幫助？

### 文檔資源

- **完整架構文檔**：[ARCHITECTURE.md](../ARCHITECTURE.md)
- **快速參考卡片**：[QUICK_REFERENCE.md](../QUICK_REFERENCE.md)
- **開發檢查清單**：[DEVELOPMENT_CHECKLIST.md](../DEVELOPMENT_CHECKLIST.md)
- **文檔更新總結**：[DOCUMENTATION_UPDATES_SUMMARY.md](./DOCUMENTATION_UPDATES_SUMMARY.md)

### 常見問題

1. **Q: 我應該使用哪個 ID？**
   - A: 查閱 [QUICK_REFERENCE.md](../QUICK_REFERENCE.md) 的「ID 使用規則」章節

2. **Q: 我可以直接從 Flutter APP 寫入 Firestore 嗎？**
   - A: 不可以！違反 CQRS 架構。必須通過 Backend API 寫入 Supabase。

3. **Q: 我可以修改端口配置嗎？**
   - A: 不可以！端口是固定的（Backend 3000、Web Admin 3001）。

4. **Q: 我需要部署 Firestore 規則嗎？**
   - A: 是的！必須部署安全規則和索引，否則查詢會失敗。

---

**最後更新**：2025-01-12  
**維護者**：開發團隊

