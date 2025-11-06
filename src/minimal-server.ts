import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import bookingFlowRoutes from './routes/bookingFlow-minimal';
import bookingsRoutes from './routes/bookings';
import reviewRoutes from './routes/reviews';
import gomypayRoutes from './routes/gomypay';
import { initializeFirebase } from './config/firebase';

// 載入環境變數
dotenv.config();

// 初始化 Firebase Admin SDK
try {
  initializeFirebase();
} catch (error) {
  console.error('⚠️  Firebase Admin SDK 初始化失敗，聊天室功能可能無法使用');
}

const app = express();
const PORT = parseInt(process.env.PORT || '3000', 10);

// 基礎中間件
app.use(cors({
  origin: "*",
  credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 健康檢查
app.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'Ride Booking Backend API'
  });
});

// ✅ 根路由與 API 根路由（請插在這裡！）
app.get('/', (req, res) => {
  res.status(200).json({ success: true, message: 'RelayGo API Connected (Minimal)' });
});

app.get('/api', (req, res) => {
  res.status(200).json({ success: true, message: 'RelayGo API Root (Minimal)' });
});

// API 路由
app.use('/api/bookings', bookingsRoutes);
app.use('/api/booking-flow', bookingFlowRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/payment', gomypayRoutes); // GOMYPAY 回調路由（公開，不需要認證）

// 404 處理
app.use((_req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// 錯誤處理
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    error: err.message || 'Internal server error'
  });
});

// 啟動伺服器
// 監聽 0.0.0.0 以允許區域網訪問（實機測試需要）
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server is running on port ${PORT}`);
  console.log(`   Local: http://localhost:${PORT}/health`);
  console.log(`   Network: http://0.0.0.0:${PORT}/health`);
  console.log(`   API endpoints:`);
  console.log(`     - POST /api/bookings (創建訂單)`);
  console.log(`     - POST /api/bookings/:id/pay-deposit (支付訂金)`);
  console.log(`     - POST /api/booking-flow/bookings/:id/accept (司機確認接單)`);
  console.log(`     - POST /api/payment/gomypay-callback (GOMYPAY 支付回調)`);
  console.log(`     - POST /api/reviews (提交評價)`);
  console.log(`     - GET /api/reviews/check/:bookingId (檢查評價狀態)`);
});

