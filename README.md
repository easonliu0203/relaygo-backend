# RelayGo Backend API

包車/接送叫車服務後端 API 伺服器

## 技術棧

- **Runtime**: Node.js 18+
- **Framework**: Express + TypeScript
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Firebase Auth
- **Real-time**: Firebase Realtime Database
- **File Storage**: Firebase Storage
- **Push Notifications**: Firebase Cloud Messaging
- **Payment**: GoMyPay
- **Translation**: OpenAI GPT-4o mini
- **Deployment**: Railway

## 專案結構

```
backend/
├── src/                      # 核心程式碼
│   ├── config/              # 配置檔案
│   ├── controllers/         # 控制器
│   ├── routes/              # 路由
│   ├── services/            # 服務層
│   ├── minimal-server.ts    # Railway 使用的精簡伺服器
│   └── server.ts            # 完整伺服器
├── shared/                  # 共用程式碼
│   ├── constants/
│   └── types/
├── scripts/                 # 實用腳本
├── package.json
├── tsconfig.json
├── railway.json             # Railway 部署配置
└── README.md
```

## 環境變數

需要在 Railway 中設定以下環境變數：

### Supabase
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

### Firebase
- `FIREBASE_PROJECT_ID`
- `FIREBASE_PRIVATE_KEY`
- `FIREBASE_CLIENT_EMAIL`

### GoMyPay (支付)
- `GOMYPAY_MERCHANT_ID`
- `GOMYPAY_HASH_KEY`
- `GOMYPAY_HASH_IV`

### OpenAI (翻譯)
- `OPENAI_API_KEY`

### 其他
- `PORT` (預設: 8080)
## 本地開發

```bash
# 安裝依賴
npm install

# 開發模式
npm run dev

# 建置
npm run build

# 啟動生產版本
npm start
```

## 部署

### Railway 部署

專案已配置自動部署到 Railway：

1. 推送到 `main` 分支自動觸發部署
2. Railway 會自動執行建置命令：`npm install && npm run build:min`
3. 啟動命令：`node dist/minimal-server.js`

**正式域名**：
- `https://api.relaygo.pro`
- `https://relaygo-backend-production.up.railway.app`

### 環境變數檢查

確保 Railway 中已設定所有必要的環境變數（見上方列表）。

## API 端點

### 健康檢查
- `GET /health` - 伺服器健康狀態

### 訂單相關
- `POST /api/bookings` - 創建訂單
- `GET /api/bookings/:id` - 獲取訂單詳情
- `PUT /api/bookings/:id` - 更新訂單

### 支付相關
- `POST /api/gomypay/create-payment` - 創建支付
- `POST /api/gomypay/callback` - 支付回調

### 個人資料
- `GET /api/profile` - 獲取個人資料
- `PUT /api/profile` - 更新個人資料

### 評價系統
- `POST /api/reviews` - 提交評價
- `GET /api/reviews/:bookingId` - 獲取評價

## 系統架構

### CQRS 模式
- **Command**: Supabase/PostgreSQL（單一真實來源）
- **Query**: Firebase Realtime Database（即時查詢）
- **同步**: 自動同步機制確保資料一致性

### 資料流向
1. 寫入操作 → Supabase
2. Supabase Trigger → 同步到 Firebase
3. 讀取操作 → Firebase（即時）

## 授權

MIT License
