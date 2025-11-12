# 包車/接送叫車 APP 專案

## 專案概述

這是一個預約為主的包車/接送叫車服務平台，包含乘客端、司機端和公司後台管理系統。

### 主要功能
- 🚗 預約包車服務 (6h/8h)
- 👥 三角色系統：乘客、司機、公司後台
- 💰 訂金支付與每日結帳
- 📍 即時定位追蹤
- 💬 即時翻譯聊天
- ⭐ 評價與推薦系統
- 🌍 多語言國際化支援

## 技術架構

### 前端
- **Mobile App**: Flutter (Android/iOS)
- **Web Admin**: Next.js + React + TypeScript
- **UI Framework**: Material Design 3

### 後端
- **API Server**: Node.js + Express + TypeScript
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Firebase Auth
- **Real-time**: Firebase Realtime Database
- **File Storage**: Firebase Storage
- **Push Notifications**: Firebase Cloud Messaging

### 第三方服務
- **Translation**: GPT-4o mini
- **Maps**: Google Maps API
- **Payment**: 串接台灣金流服務

## 專案結構

```
├── mobile/                 # Flutter 移動應用
│   ├── lib/
│   │   ├── apps/
│   │   │   ├── customer/   # 乘客端
│   │   │   └── driver/     # 司機端
│   │   ├── shared/         # 共用組件
│   │   └── core/           # 核心功能
│   └── assets/             # 資源檔案
├── web-admin/              # Web 後台管理
│   ├── src/
│   │   ├── pages/          # 頁面
│   │   ├── components/     # 組件
│   │   └── services/       # API 服務
├── backend/                # 後端 API 服務
│   ├── src/
│   │   ├── routes/         # 路由
│   │   ├── controllers/    # 控制器
│   │   ├── services/       # 業務邏輯
│   │   └── models/         # 資料模型
├── database/               # 資料庫設計
│   ├── migrations/         # 遷移檔案
│   ├── seeds/              # 初始資料
│   └── schema.sql          # 資料庫結構
├── shared/                 # 共用檔案
│   ├── types/              # 類型定義
│   └── constants/          # 常數
├── docs/                   # 文檔
│   ├── api/                # API 文檔
│   ├── database/           # 資料庫文檔
│   └── development/        # 開發歷程
└── scripts/                # 工具腳本
```

## 快速開始

### 🚀 封測版本 (推薦)
快速啟動封測版本，跳過複雜的金流整合：

```bash
# 1. 一鍵設定封測環境
./scripts/setup.sh

# 2. 啟動封測版本
./scripts/dev.sh --beta
```

**封測特色**:
- ✅ 模擬支付系統 (無需真實金流)
- ✅ 完整業務邏輯驗證
- ✅ 快速部署測試
- ✅ 平滑升級到正式版

詳細說明請參考：[封測版本快速啟動指南](./docs/guides/封測版本快速啟動.md)

### 🔧 完整安裝 (開發者)

#### 環境需求
- Node.js 18+
- Flutter 3.16+
- PostgreSQL 15+
- Firebase 專案

#### 安裝步驟

1. **複製專案**
```bash
git clone <repository-url>
cd ride-booking-app
```

2. **環境設定**
```bash
cp .env.example .env
# 編輯 .env 檔案，選擇支付模式：
# PAYMENT_PROVIDER=mock (封測模式)
# PAYMENT_PROVIDER=credit_card (正式模式)
```

3. **自動安裝**
```bash
# 執行自動設定腳本
./scripts/setup.sh
```

4. **手動安裝** (可選)
```bash
# 後端依賴
cd backend && npm install

# Web 後台依賴
cd ../web-admin && npm install

# Flutter 依賴
cd ../mobile && flutter pub get

# 資料庫設定
docker-compose up -d postgres redis
```

5. **啟動服務**
```bash
# 一鍵啟動所有服務
./scripts/dev.sh

# 或分別啟動
cd backend && npm run dev      # 後端 API (Port 3000)
cd web-admin && npm run dev    # Web 後台 (Port 3001)
cd mobile && flutter run       # Flutter 應用
```

## 開發規範

### Git 工作流程
- `main`: 生產環境分支
- `develop`: 開發分支
- `feature/*`: 功能分支
- `hotfix/*`: 緊急修復分支

### 提交訊息格式
```
type(scope): description

feat(auth): add user login functionality
fix(payment): resolve payment calculation bug
docs(api): update API documentation
```

### 程式碼風格
- **TypeScript**: ESLint + Prettier
- **Dart**: dart format + dart analyze
- **Git Hooks**: pre-commit 檢查

## 部署

### 開發環境
- 使用 Docker Compose 進行本地開發

### 生產環境
- **Mobile**: App Store / Google Play
- **Web**: Vercel / Netlify
- **Backend**: Railway / Render
- **Database**: Supabase Cloud

## 📚 文檔

### 快速指南
- [封測版本快速啟動](./docs/guides/封測版本快速啟動.md)
- [MVP 功能規劃](./docs/development/MVP_功能規劃.md)
- [升級路徑規劃](./docs/development/升級路徑規劃.md)

### 技術文檔
- [API 文檔](./docs/api/README.md)
- [資料庫設計](./docs/database/README.md)
- [開發歷程](./docs/README.md)

### 分階段策略
- **階段一**: 封測版本 (模擬支付 + 核心功能)
- **階段二**: 正式版本 (真實金流 + 完整功能)

## 授權

MIT License

## 聯絡資訊

如有問題請聯絡開發團隊。
