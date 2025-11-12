# API 文檔

包車/接送叫車服務 API 文檔總覽

## 基本資訊

- **Base URL**: `http://localhost:3000/api`
- **API 版本**: v1
- **認證方式**: JWT Bearer Token
- **資料格式**: JSON
- **字元編碼**: UTF-8

## 認證

所有需要認證的 API 都需要在 Header 中包含 JWT Token：

```http
Authorization: Bearer <your-jwt-token>
```

## 回應格式

### 成功回應
```json
{
  "success": true,
  "data": {
    // 回應資料
  },
  "message": "操作成功"
}
```

### 錯誤回應
```json
{
  "success": false,
  "error": "錯誤訊息",
  "errors": {
    "field": ["欄位錯誤訊息"]
  }
}
```

### 分頁回應
```json
{
  "success": true,
  "data": [
    // 資料陣列
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5,
    "hasNext": true,
    "hasPrev": false
  }
}
```

## API 端點總覽

### 認證相關 (`/api/auth`)
- `POST /register` - 用戶註冊
- `POST /login` - 用戶登入
- `POST /logout` - 用戶登出
- `POST /refresh` - 刷新 Token
- `POST /forgot-password` - 忘記密碼
- `POST /reset-password` - 重設密碼

### 用戶管理 (`/api/users`)
- `GET /profile` - 獲取用戶資料
- `PUT /profile` - 更新用戶資料
- `POST /avatar` - 上傳頭像
- `GET /preferences` - 獲取用戶偏好設定
- `PUT /preferences` - 更新用戶偏好設定

### 預約管理 (`/api/bookings`)
- `POST /` - 建立預約
- `GET /` - 獲取預約列表
- `GET /:id` - 獲取預約詳情
- `PUT /:id` - 更新預約
- `DELETE /:id` - 取消預約
- `POST /:id/reschedule` - 改期預約
- `GET /pricing` - 獲取價格資訊

### 行程管理 (`/api/trips`)
- `GET /` - 獲取行程列表
- `GET /:id` - 獲取行程詳情
- `POST /:id/start` - 開始行程
- `POST /:id/end` - 結束行程
- `GET /:id/location` - 獲取行程定位
- `POST /:id/location` - 更新定位

### 支付管理 (`/api/payments`)
- `POST /deposit` - 支付訂金
- `POST /balance` - 支付尾款
- `POST /tip` - 支付小費
- `GET /methods` - 獲取支付方式
- `POST /methods` - 新增支付方式
- `GET /history` - 支付歷史

### 司機管理 (`/api/drivers`)
- `POST /register` - 司機註冊
- `GET /profile` - 獲取司機資料
- `PUT /profile` - 更新司機資料
- `POST /documents` - 上傳證件
- `GET /earnings` - 獲取收入記錄
- `PUT /availability` - 更新可用狀態

### 聊天功能 (`/api/chat`)
- `GET /rooms` - 獲取聊天室列表
- `GET /rooms/:id` - 獲取聊天室詳情
- `POST /rooms/:id/messages` - 發送訊息
- `GET /rooms/:id/messages` - 獲取訊息歷史
- `POST /translate` - 翻譯訊息

### 定位服務 (`/api/location`)
- `POST /update` - 更新位置
- `GET /driver/:id` - 獲取司機位置
- `GET /nearby` - 搜尋附近司機
- `POST /geocode` - 地址轉座標
- `POST /reverse-geocode` - 座標轉地址

### 推薦系統 (`/api/referral`)
- `GET /code` - 獲取推薦碼
- `POST /code` - 生成推薦碼
- `POST /apply` - 使用推薦碼
- `GET /history` - 推薦歷史
- `GET /rewards` - 推薦獎勵

### 後台管理 (`/api/admin`)
- `GET /dashboard` - 儀表板資料
- `GET /bookings` - 訂單管理
- `GET /users` - 用戶管理
- `GET /drivers` - 司機管理
- `GET /payments` - 支付管理
- `GET /settings` - 系統設定
- `PUT /settings` - 更新系統設定

## 狀態碼

| 狀態碼 | 說明 |
|--------|------|
| 200 | 請求成功 |
| 201 | 資源建立成功 |
| 400 | 請求參數錯誤 |
| 401 | 未認證 |
| 403 | 權限不足 |
| 404 | 資源不存在 |
| 409 | 資源衝突 |
| 422 | 資料驗證失敗 |
| 429 | 請求頻率過高 |
| 500 | 伺服器內部錯誤 |

## 錯誤代碼

| 錯誤代碼 | 說明 |
|----------|------|
| UNAUTHORIZED | 未認證 |
| FORBIDDEN | 權限不足 |
| NOT_FOUND | 資源不存在 |
| VALIDATION_ERROR | 資料驗證錯誤 |
| BOOKING_CONFLICT | 預約衝突 |
| PAYMENT_FAILED | 支付失敗 |
| DRIVER_UNAVAILABLE | 司機不可用 |
| INSUFFICIENT_BALANCE | 餘額不足 |

## 分頁參數

所有支援分頁的 API 都接受以下查詢參數：

| 參數 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| page | integer | 1 | 頁碼 |
| limit | integer | 20 | 每頁筆數 |
| sort | string | created_at | 排序欄位 |
| order | string | desc | 排序方向 (asc/desc) |

## 過濾參數

部分 API 支援過濾參數：

| 參數 | 類型 | 說明 |
|------|------|------|
| status | string | 狀態過濾 |
| date_from | string | 開始日期 (YYYY-MM-DD) |
| date_to | string | 結束日期 (YYYY-MM-DD) |
| search | string | 關鍵字搜尋 |

## 速率限制

- 一般 API：每分鐘 100 次請求
- 認證 API：每分鐘 10 次請求
- 上傳 API：每分鐘 20 次請求

## WebSocket 連接

即時功能使用 WebSocket 連接：

```javascript
const socket = io('http://localhost:3000', {
  auth: {
    token: 'your-jwt-token'
  }
});

// 監聽事件
socket.on('location_update', (data) => {
  console.log('位置更新:', data);
});

socket.on('new_message', (data) => {
  console.log('新訊息:', data);
});
```

## 測試工具

### Postman Collection
- 下載 Postman Collection: [API Collection](./postman_collection.json)

### cURL 範例
```bash
# 用戶登入
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "password"}'

# 獲取用戶資料
curl -X GET http://localhost:3000/api/users/profile \
  -H "Authorization: Bearer your-jwt-token"
```

## 開發環境

### 本地測試
```bash
# 啟動開發伺服器
npm run dev

# 執行測試
npm test

# 檢查 API 健康狀態
curl http://localhost:3000/health
```

### 環境變數
請參考 `.env.example` 檔案設定必要的環境變數。

## 更新日誌

### v1.0.0 (2025-01-27)
- 初始 API 設計
- 基礎認證功能
- 預約管理功能
- 支付系統整合

---

更多詳細的 API 文檔請參考各個模組的專門文檔：

- [認證 API](./authentication.md)
- [預約 API](./bookings.md)
- [支付 API](./payments.md)
- [聊天 API](./chat.md)
- [後台管理 API](./admin.md)
