import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import bookingFlowRoutes from './routes/bookingFlow-minimal';
import bookingsRoutes from './routes/bookings';
import gomypayRoutes from './routes/gomypay';
import pricingRoutes from './routes/pricing';
import { initializeFirebase } from './config/firebase';
import { initializePaymentProviders } from './services/payment';

// 載入環境變數
dotenv.config();

// 檢查關鍵環境變數
console.log('=== 環境變數檢查 ===');
console.log(`NODE_ENV: ${process.env.NODE_ENV || 'development'}`);
console.log(`PORT: ${process.env.PORT || 3000}`);
console.log(`FIREBASE_PROJECT_ID: ${process.env.FIREBASE_PROJECT_ID ? '✅ 已設置' : '❌ 未設置'}`);
console.log(`FIREBASE_CLIENT_EMAIL: ${process.env.FIREBASE_CLIENT_EMAIL ? '✅ 已設置' : '❌ 未設置'}`);
console.log(`FIREBASE_PRIVATE_KEY: ${process.env.FIREBASE_PRIVATE_KEY ? `✅ 已設置 (長度: ${process.env.FIREBASE_PRIVATE_KEY.length})` : '❌ 未設置'}`);
console.log('');

// 初始化 Firebase Admin SDK
console.log('=== 開始初始化 Firebase Admin SDK ===');
try {
  const firebaseApp = initializeFirebase();
  console.log('=== Firebase Admin SDK 初始化完成 ===');
  console.log(`Firebase App Name: ${firebaseApp.name}`);
  console.log(`Firebase Project ID: ${firebaseApp.options.projectId}`);
} catch (error) {
  console.error('=== ❌ Firebase Admin SDK 初始化失敗 ===');
  if (error instanceof Error) {
    console.error(`錯誤訊息: ${error.message}`);
    console.error(`錯誤堆棧: ${error.stack}`);
  } else {
    console.error(`錯誤: ${String(error)}`);
  }
  console.error('⚠️  聊天室功能將無法使用');
  console.error('請檢查 Railway 環境變數：');
  console.error('  - FIREBASE_PROJECT_ID');
  console.error('  - FIREBASE_PRIVATE_KEY');
  console.error('  - FIREBASE_CLIENT_EMAIL');
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
app.use('/api/payment', gomypayRoutes); // GoMyPay 回調路由（公開，不需要認證）
app.use('/api/pricing', pricingRoutes); // 價格路由（公開）

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

