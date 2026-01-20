import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import { createServer } from 'http';
import { Server } from 'socket.io';
import dotenv from 'dotenv';

import { errorHandler } from './middleware/errorHandler';
import { notFoundHandler } from './middleware/notFoundHandler';
import { authMiddleware } from './middleware/authMiddleware';
import { logger } from './utils/logger';

// 路由導入
import authRoutes from './routes/auth';
import profileRoutes from './routes/profile';
import bookingRoutes from './routes/bookings';
import bookingFlowRoutes from './routes/bookingFlow';
import tripRoutes from './routes/trips';
import paymentRoutes from './routes/payments';
import driverRoutes from './routes/drivers';
import adminRoutes from './routes/admin';
import chatRoutes from './routes/chat';
import locationRoutes from './routes/location';
import referralRoutes from './routes/referral';
import reviewRoutes from './routes/reviews';
import gomypayRoutes from './routes/gomypay';
import pricingRoutes from './routes/pricing';
import signatureRoutes from './routes/signatures';
import affiliatesRoutes from './routes/affiliates';

// 服務導入
import { initializeFirebase } from './config/firebase';
import { initializeSupabase } from './config/supabase';
import { initializeRedis } from './config/redis';
import { setupSocketHandlers } from './services/socketService';

// 載入環境變數
dotenv.config();

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || "*",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// 基礎中間件
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.CORS_ORIGIN || "*",
  credentials: true
}));

// 請求日誌
if (NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined', {
    stream: {
      write: (message: string) => logger.info(message.trim())
    }
  }));
}

// 速率限制
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 分鐘
  max: 100, // 限制每個 IP 100 次請求
  message: {
    error: 'Too many requests from this IP, please try again later.'
  }
});
app.use('/api/', limiter);

// 解析請求體
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 健康檢查
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: NODE_ENV
  });
});

// API 路由
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes); // 個人資料路由（包含刪除帳號功能）
app.use('/api/bookings', authMiddleware, bookingRoutes);
app.use('/api/booking-flow', bookingFlowRoutes);
app.use('/api/trips', authMiddleware, tripRoutes);
app.use('/api/payments', authMiddleware, paymentRoutes);
app.use('/api/payment', gomypayRoutes); // GOMYPAY 回調路由（公開，不需要 authMiddleware）
app.use('/api/drivers', authMiddleware, driverRoutes);
app.use('/api/admin', authMiddleware, adminRoutes);
app.use('/api/chat', authMiddleware, chatRoutes);
app.use('/api/location', authMiddleware, locationRoutes);
app.use('/api/referral', authMiddleware, referralRoutes);
app.use('/api/reviews', reviewRoutes); // 評價路由（暫不使用 authMiddleware，在路由內部處理）
app.use('/api/pricing', pricingRoutes); // 價格路由（公開，供客戶端 APP 獲取價格方案）
app.use('/api/signatures', authMiddleware, signatureRoutes); // 數位簽名路由（需要認證）
app.use('/api/affiliates', affiliatesRoutes); // 客戶推廣人路由（部分公開，部分需要認證）

// ✅ ✅ ✅ 在這裡插入 ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
app.get('/', (req, res) => {
  res.status(200).json({ success: true, message: 'RelayGo API Connected' });
});

app.get('/api', (req, res) => {
  res.status(200).json({ success: true, message: 'RelayGo API Root' });
});
// ✅ ✅ ✅ 插在這裡 ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

// 錯誤處理中間件
app.use(notFoundHandler);
app.use(errorHandler);

// 初始化服務
async function initializeServices() {
  try {
    // 初始化 Firebase
    await initializeFirebase();
    logger.info('Firebase initialized successfully');

    // 初始化 Supabase
    await initializeSupabase();
    logger.info('Supabase initialized successfully');

    // 初始化 Redis
    await initializeRedis();
    logger.info('Redis initialized successfully');

    // 設定 Socket.IO 處理器
    setupSocketHandlers(io);
    logger.info('Socket.IO handlers set up successfully');

  } catch (error) {
    logger.error('Failed to initialize services:', error);
    process.exit(1);
  }
}

// 啟動伺服器
async function startServer() {
  try {
    await initializeServices();
    
    server.listen(PORT, () => {
      logger.info(`Server is running on port ${PORT} in ${NODE_ENV} mode`);
      logger.info(`Health check available at http://localhost:${PORT}/health`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

// 優雅關閉
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

// 未捕獲的異常處理
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// 啟動應用
startServer();

export { app, io };
