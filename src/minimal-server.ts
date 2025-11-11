import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import bookingFlowRoutes from './routes/bookingFlow-minimal';
import bookingsRoutes from './routes/bookings';
import { initializeFirebase } from './config/firebase';
import { initializePaymentProviders } from './services/payment';

// 載入環境變數
dotenv.config();

// 初始化 Firebase Admin SDK
try {
  initializeFirebase();
} catch (error) {
  console.error('⚠️  Firebase Admin SDK 初始化失敗，聊天室功能可能無法使用');
}

// 初始化支付提供者
try {
  initializePaymentProviders();
  console.log('✅ 支付提供者初始化成功');
} catch (error) {
  console.error('⚠️  支付提供者初始化失敗:', error);
}

const app = express();
const PORT = process.env.PORT || 3000;

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

// API 路由
app.use('/api/bookings', bookingsRoutes);
app.use('/api/booking-flow', bookingFlowRoutes);

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
app.listen(PORT, () => {
  console.log(`✅ Server is running on port ${PORT}`);
  console.log(`   Health check: http://localhost:${PORT}/health`);
  console.log(`   API endpoints:`);
  console.log(`     - POST /api/bookings (創建訂單)`);
  console.log(`     - POST /api/bookings/:id/pay-deposit (支付訂金)`);
  console.log(`     - POST /api/booking-flow/bookings/:id/accept (司機確認接單)`);
});

