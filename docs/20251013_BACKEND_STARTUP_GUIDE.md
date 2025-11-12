# Backend 啟動和使用指南

**日期**: 2025-10-13  
**目的**: 確保 Backend API 正常運行，支持 Flutter APP 測試

---

## 🚀 快速啟動

### 方法 1: 使用 npm（推薦）
```bash
cd backend
npm run dev
```

### 方法 2: 使用 yarn
```bash
cd backend
yarn dev
```

### 預期輸出
```
✅ Server is running on port 3000
   Health check: http://localhost:3000/health
   API endpoints:
     - POST /api/bookings (創建訂單)
     - POST /api/bookings/:id/pay-deposit (支付訂金)
     - POST /api/booking-flow/bookings/:id/accept (司機確認接單)
```

---

## ✅ 驗證 Backend 運行

### 檢查健康狀態
```bash
curl http://localhost:3000/health
```

**預期響應**:
```json
{
  "status": "OK",
  "timestamp": "2025-10-13T16:49:17.027Z",
  "service": "Ride Booking Backend API"
}
```

### 檢查 Booking Flow API
```bash
curl http://localhost:3000/api/booking-flow/test
```

**預期響應**:
```json
{
  "success": true,
  "message": "Booking Flow API is working",
  "timestamp": "2025-10-13T16:49:17.164Z"
}
```

---

## 📋 API 端點說明

### 1. 創建訂單
```bash
POST /api/bookings
Content-Type: application/json

{
  "customerUid": "firebase_uid",
  "vehicleType": "small",
  "startDate": "2025-10-14",
  "startTime": "10:00:00",
  "durationHours": 8,
  "pickupLocation": "台北車站",
  "pickupLatitude": 25.0478,
  "pickupLongitude": 121.5170,
  "destination": "桃園機場"
}
```

### 2. 支付訂金
```bash
POST /api/bookings/:bookingId/pay-deposit
Content-Type: application/json

{
  "paymentMethod": "mock"
}
```

### 3. 司機確認接單 ⭐
```bash
POST /api/booking-flow/bookings/:bookingId/accept
Content-Type: application/json

{
  "driverUid": "CMfTxhJFlUVDkosJPyUoJvKjCQk1"
}
```

**成功響應**:
```json
{
  "success": true,
  "data": {
    "bookingId": "d5352b9e-050d-42b6-8c9a-dd80a425864f",
    "status": "driver_confirmed",
    "chatRoom": {
      "id": "d5352b9e-050d-42b6-8c9a-dd80a425864f",
      "bookingId": "d5352b9e-050d-42b6-8c9a-dd80a425864f",
      "customerId": "c03f0310-d3c8-44ab-8aec-1a4a858c52cb",
      "driverId": "CMfTxhJFlUVDkosJPyUoJvKjCQk1",
      "customerName": "customer.test",
      "driverName": "driver.test",
      "pickupAddress": "台北車站",
      "bookingTime": "2025-10-13"
    },
    "nextStep": "driver_depart"
  },
  "message": "接單成功"
}
```

---

## 🔧 常見問題排查

### 問題 1: Backend 無法啟動
**錯誤**: `Error: Cannot find module 'express'`

**解決方案**:
```bash
cd backend
npm install
npm run dev
```

### 問題 2: Port 3000 已被占用
**錯誤**: `Error: listen EADDRINUSE: address already in use :::3000`

**解決方案**:
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:3000 | xargs kill -9
```

### 問題 3: Supabase 連接失敗
**錯誤**: `Error: Invalid Supabase URL`

**解決方案**:
檢查 `backend/.env` 文件：
```env
SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 問題 4: 司機確認接單失敗
**錯誤**: `訂單狀態不正確（當前: driver_confirmed，需要: matched）`

**原因**: 訂單已經被確認過了

**解決方案**: 
1. 創建新訂單
2. 手動派單
3. 再次測試確認接單

---

## 🧪 完整測試流程

### 步驟 1: 啟動 Backend
```bash
cd backend
npm run dev
```

### 步驟 2: 創建測試訂單
使用客戶端 APP 或 Web Admin 創建訂單並支付訂金

### 步驟 3: 手動派單
使用 Web Admin 將訂單派給測試司機

### 步驟 4: 測試司機確認接單
```bash
curl -X POST http://localhost:3000/api/booking-flow/bookings/<BOOKING_ID>/accept \
  -H "Content-Type: application/json" \
  -d '{"driverUid":"CMfTxhJFlUVDkosJPyUoJvKjCQk1"}'
```

### 步驟 5: 驗證結果
檢查：
- ✅ API 返回成功響應
- ✅ Supabase bookings 表狀態更新為 `driver_confirmed`
- ✅ Firestore bookings 集合狀態更新為 `matched`
- ✅ Flutter APP 按鈕消失

---

## 📊 Backend 日誌說明

### 正常日誌
```
[API] 司機確認接單: bookingId=xxx, driverUid=xxx
[API] 訂單資料: { id: 'xxx', status: 'matched', ... }
[API] 司機資料: { id: 'xxx', firebase_uid: 'xxx', email: 'xxx' }
[API] ✅ 訂單狀態已更新為 driver_confirmed
```

### 錯誤日誌
```
[API] 查詢訂單失敗: { error: 'xxx' }
[API] 查詢司機失敗: { error: 'xxx' }
[API] 司機權限驗證失敗: booking.driver_id= xxx driver.id= xxx
[API] 訂單狀態不正確: driver_confirmed
```

---

## 🔑 環境變數配置

### 必需的環境變數
```env
# Supabase 配置
SUPABASE_URL=https://vlyhwegpvpnjyocqmfqc.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 服務器配置
NODE_ENV=development
PORT=3000
CORS_ORIGIN=http://localhost:3001,http://localhost:3000
```

### 可選的環境變數
```env
# Firebase Admin SDK（生產環境需要）
FIREBASE_PROJECT_ID=ride-platform-f1676
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@ride-platform-f1676.iam.gserviceaccount.com

# Redis（生產環境需要）
REDIS_URL=redis://localhost:6379
```

---

## 🎯 下一步

### 開發環境
1. ✅ Backend 正常運行
2. ✅ 測試 API 端點
3. ✅ Flutter APP 測試

### 生產環境準備
1. ⭐ 配置 Firebase Admin SDK
2. ⭐ 配置 Redis
3. ⭐ 添加認證中間件
4. ⭐ 部署到雲端服務器

---

## 📞 需要幫助？

如果遇到問題，請檢查：
1. `docs/20251013_NETWORK_ERROR_FIX.md` - 網路錯誤修復指南
2. `docs/QUICK_TEST_GUIDE.md` - 快速測試指南
3. Backend 終端機日誌

---

**最後更新**: 2025-10-13  
**狀態**: ✅ Backend 正常運行

