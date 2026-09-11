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

/**
 * 管理員身份驗證 middleware
 *
 * - 驗證 Firebase ID Token，且帳號必須帶有 admin custom claim
 *   （與 web-admin 登入 /api/auth/admin/google-login 的 verifyAdminToken 同一套規則）
 * - 沒 token 或驗證失敗 → 401；已登入但不是管理員 → 403
 * - CORS 預檢（OPTIONS）不帶憑證，直接放行交給 cors 處理，否則瀏覽器的後台請求會全部失敗
 *
 * 用於後台 API（/api/admin/*、推廣人審核、司機推廣人管理）
 */
export async function requireAdmin(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  if (req.method === 'OPTIONS') {
    next();
    return;
  }

  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : '';
  if (!token) {
    res.status(401).json({ success: false, error: '未提供管理員身份驗證 token' });
    return;
  }

  try {
    getFirebaseApp(); // 確保 Firebase 已初始化
    const decoded = await admin.auth().verifyIdToken(token);

    if (!decoded.admin) {
      console.warn(`[Auth] 非管理員嘗試呼叫後台 API: ${decoded.email || decoded.uid} ${req.method} ${req.originalUrl}`);
      res.status(403).json({ success: false, error: '此帳號沒有管理員權限' });
      return;
    }

    req.user = {
      uid: decoded.uid,
      email: decoded.email,
    };
  } catch (error) {
    console.warn('[Auth] 管理員 Token 驗證失敗（requireAdmin）:', (error as Error).message);
    res.status(401).json({ success: false, error: '身份驗證失敗，請重新登入' });
    return;
  }

  // 放在 try 外面：後續路由的錯誤不可被當成驗證失敗
  next();
}
