import { Request, Response, NextFunction } from 'express';
import admin from 'firebase-admin';
import { getFirebaseApp } from '../config/firebase';

// 擴展 Express Request 型別
declare global {
  namespace Express {
    interface Request {
      user?: {
        uid: string;
        email?: string | undefined;
      };
    }
  }
}

/**
 * 可選身份驗證 middleware
 *
 * - 有 Bearer token → 驗證並附加 req.user
 * - 沒 token 或驗證失敗 → req.user = undefined，不擋請求
 *
 * 用於全域套用，讓現有路由保持向後兼容
 */
export async function optionalAuth(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    next();
    return;
  }

  const token = authHeader.slice(7);
  if (!token) {
    next();
    return;
  }

  try {
    getFirebaseApp(); // 確保 Firebase 已初始化
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
    };
  } catch (error) {
    // token 無效，不擋請求，只記錄
    console.warn('[Auth] Token 驗證失敗（optionalAuth）:', (error as Error).message);
  }

  next();
}

/**
 * 強制身份驗證 middleware
 *
 * - 有效 Bearer token → 附加 req.user 並放行
 * - 沒 token 或驗證失敗 → 回 401
 *
 * 用於敏感路由（AI 旅遊規劃師等）
 */
export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: '未提供身份驗證 token' });
    return;
  }

  const token = authHeader.slice(7);
  if (!token) {
    res.status(401).json({ error: '未提供身份驗證 token' });
    return;
  }

  try {
    getFirebaseApp(); // 確保 Firebase 已初始化
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
    };
    next();
  } catch (error) {
    console.warn('[Auth] Token 驗證失敗（requireAuth）:', (error as Error).message);
    res.status(401).json({ error: '身份驗證失敗，請重新登入' });
  }
}
