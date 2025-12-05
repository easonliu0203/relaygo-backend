import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth'; // ✅ 新增：添加 auth 路由（2025-12-01）
import bookingFlowRoutes from './routes/bookingFlow-minimal';
import bookingsRoutes from './routes/bookings';
import gomypayRoutes from './routes/gomypay';
import pricingRoutes from './routes/pricing';
import testFirebaseRoutes from './routes/test-firebase';
import profileRoutes from './routes/profile';
import ratingsRoutes from './routes/ratings';
import reviewRoutes from './routes/reviews'; // ✅ 修復：添加 reviews 路由（2025-11-30）
import tourPackagesRoutes from './routes/tourPackages'; // ✅ 新增：添加 tour packages 路由（2025-11-30）
import driversRoutes from './routes/drivers'; // ✅ 新增：添加 drivers 路由（2025-12-02）
import influencersRoutes from './routes/influencers'; // ✅ 新增：添加 influencers 路由（2025-12-05）
import promoCodesRoutes from './routes/promoCodes'; // ✅ 新增：添加 promo codes 路由（2025-12-05）
// import translationRoutes from './routes/translation'; // TODO: 翻譯路由檔案不存在，暫時註解
import { initializeFirebase } from './config/firebase';
import { initializePaymentProviders } from './services/payment';

// Load environment variables
dotenv.config();

// Check critical environment variables
console.log('=== Environment Variables Check ===');
console.log(`NODE_ENV: ${process.env.NODE_ENV || 'development'}`);
console.log(`PORT: ${process.env.PORT || 3000}`);
console.log(`FIREBASE_PROJECT_ID: ${process.env.FIREBASE_PROJECT_ID ? 'SET' : 'NOT SET'}`);
console.log(`FIREBASE_CLIENT_EMAIL: ${process.env.FIREBASE_CLIENT_EMAIL ? 'SET' : 'NOT SET'}`);
console.log(`FIREBASE_PRIVATE_KEY: ${process.env.FIREBASE_PRIVATE_KEY ? `SET (length: ${process.env.FIREBASE_PRIVATE_KEY.length})` : 'NOT SET'}`);
console.log(`OPENAI_API_KEY: ${process.env.OPENAI_API_KEY ? 'SET' : 'NOT SET'}`);
console.log('');

// Initialize Firebase Admin SDK
console.log('=== Initializing Firebase Admin SDK ===');
try {
  const firebaseApp = initializeFirebase();
  console.log('=== Firebase Admin SDK Initialized ===');
  console.log(`Firebase App Name: ${firebaseApp.name}`);
  console.log(`Firebase Project ID: ${firebaseApp.options.projectId}`);
} catch (error) {
  console.error('=== Firebase Admin SDK Initialization Failed ===');
  if (error instanceof Error) {
    console.error(`Error message: ${error.message}`);
    console.error(`Error stack: ${error.stack}`);
  } else {
    console.error(`Error: ${String(error)}`);
  }
  console.error('Chat room features will not work');
  console.error('Please check Railway environment variables:');
  console.error('  - FIREBASE_PROJECT_ID');
  console.error('  - FIREBASE_PRIVATE_KEY');
  console.error('  - FIREBASE_CLIENT_EMAIL');
}

// Initialize payment providers
try {
  initializePaymentProviders();
  console.log('Payment providers initialized successfully');
} catch (error) {
  console.error('Payment providers initialization failed:', error);
}

const app = express();
const PORT = process.env.PORT || 3000;

// Basic middleware
app.use(cors({
  origin: "*",
  credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check
app.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'Ride Booking Backend API'
  });
});

// Test translation route loading
app.get('/api/translation/test', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'Translation route is loaded!',
    timestamp: new Date().toISOString()
  });
});

// API routes
app.use('/api/auth', authRoutes); // ✅ 新增：註冊 auth 路由（2025-12-01）
app.use('/api/bookings', ratingsRoutes);
app.use('/api/bookings', bookingsRoutes);
app.use('/api/booking-flow', bookingFlowRoutes);
app.use('/api/payment', gomypayRoutes);
app.use('/api/pricing', pricingRoutes);
app.use('/api/test-firebase', testFirebaseRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/drivers', driversRoutes); // ✅ 新增：註冊 drivers 路由（2025-12-02）
app.use('/api/reviews', reviewRoutes); // ✅ 修復：註冊 reviews 路由（2025-11-30）
app.use('/api/tour-packages', tourPackagesRoutes); // ✅ 新增：註冊 tour packages 路由（2025-11-30）
app.use('/api/admin/influencers', influencersRoutes); // ✅ 新增：註冊 influencers 路由（2025-12-05）
app.use('/api/promo-codes', promoCodesRoutes); // ✅ 新增：註冊 promo codes 路由（2025-12-05）
app.use('/api', ratingsRoutes); // 保留舊的 ratings 路由以向後兼容
// app.use('/api/translation', translationRoutes); // TODO: 翻譯路由檔案不存在，暫時註解

// 404 handler
app.use((_req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// Error handler
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    error: err.message || 'Internal server error'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`   Health check: http://localhost:${PORT}/health`);
  console.log(`   API endpoints:`);
  console.log(`     - POST /api/bookings`);
  console.log(`     - POST /api/bookings/:id/pay-deposit`);
  console.log(`     - POST /api/booking-flow/bookings/:id/accept`);
  console.log(`     - POST /api/translation/translate`);
  console.log(`     - GET /api/translation/test`);
});

