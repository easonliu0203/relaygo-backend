import { Router, Request, Response } from 'express';
import admin from 'firebase-admin';
import { requireAuth } from '../middleware/auth';
import { getFirestore } from '../config/firebase';
import { chat } from '../services/ai-travel-planner/geminiService';
import { Content } from '@google/generative-ai';

const router = Router();

// 所有端點都需要登入
router.use(requireAuth);

// ============================================
// POST /api/ai-travel-planner/chat
// 發送訊息給 AI，取得回應
// ============================================
router.post('/chat', async (req: Request, res: Response) => {
  try {
    const userId = req.user!.uid;
    const { sessionId, message, language } = req.body;

    if (!message || typeof message !== 'string' || !message.trim()) {
      return res.status(400).json({ error: 'message is required' });
    }

    const firestore = getFirestore();
    let currentSessionId = sessionId as string | undefined;

    // 1. 建立或載入 session
    if (!currentSessionId) {
      // 建立新 session
      const sessionRef = firestore.collection('ai_travel_sessions').doc();
      currentSessionId = sessionRef.id;

      await sessionRef.set({
        userId,
        title: message.trim().substring(0, 50),
        language: language || 'zh-TW',
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      console.log(`[AI Travel] 📝 New session: ${currentSessionId} for user: ${userId}`);
    }

    const sessionRef = firestore.collection('ai_travel_sessions').doc(currentSessionId);
    const messagesRef = sessionRef.collection('messages');

    // 2. 載入歷史訊息（轉換為 Gemini Content 格式）
    const historySnap = await messagesRef.orderBy('timestamp', 'asc').get();
    const history: Content[] = historySnap.docs.map(doc => {
      const data = doc.data();
      return {
        role: data.role === 'user' ? 'user' : 'model',
        parts: [{ text: data.content }],
      };
    });

    // 3. 呼叫 Gemini（帶入用戶語言以選擇對應聯盟連結）
    const userLang = (language as string) || 'zh-TW';
    console.log(`[AI Travel] 💬 User (${userId}) [${userLang}]: ${message.substring(0, 80)}...`);
    const reply = await chat(history, message.trim(), userLang);

    // 4. 存入 user message + AI response
    const now = admin.firestore.Timestamp.now();
    const batch = firestore.batch();

    batch.create(messagesRef.doc(), {
      role: 'user',
      content: message.trim(),
      timestamp: now,
    });

    batch.create(messagesRef.doc(), {
      role: 'model',
      content: reply,
      timestamp: admin.firestore.Timestamp.fromMillis(now.toMillis() + 1),
    });

    // 更新 session 的 updatedAt
    batch.update(sessionRef, {
      updatedAt: now,
    });

    await batch.commit();

    console.log(`[AI Travel] ✅ Reply stored for session: ${currentSessionId}`);

    return res.json({
      sessionId: currentSessionId,
      reply,
    });
  } catch (error) {
    console.error('[AI Travel] ❌ Chat error:', error);
    return res.status(500).json({
      error: 'AI 處理失敗，請稍後再試',
      details: (error as Error).message,
    });
  }
});

// ============================================
// GET /api/ai-travel-planner/sessions
// 列出使用者的所有 session
// ============================================
router.get('/sessions', async (req: Request, res: Response) => {
  try {
    const userId = req.user!.uid;
    const firestore = getFirestore();

    // 只用 where 查詢，不加 orderBy 避免需要 Firestore 複合索引
    const snap = await firestore
      .collection('ai_travel_sessions')
      .where('userId', '==', userId)
      .get();

    const sessions = snap.docs
      .map(doc => ({
        id: doc.id,
        title: doc.data().title,
        language: doc.data().language,
        createdAt: doc.data().createdAt?.toDate?.()?.toISOString(),
        updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString(),
      }))
      // 在記憶體中按 updatedAt 排序（最新在前）
      .sort((a, b) => (b.updatedAt || '').localeCompare(a.updatedAt || ''))
      .slice(0, 20);

    return res.json({ sessions });
  } catch (error) {
    console.error('[AI Travel] ❌ List sessions error:', error);
    return res.status(500).json({ error: 'Failed to list sessions' });
  }
});

// ============================================
// GET /api/ai-travel-planner/sessions/:sessionId/messages
// 取得指定 session 的訊息歷史
// ============================================
router.get('/sessions/:sessionId/messages', async (req: Request, res: Response) => {
  try {
    const userId = req.user!.uid;
    const { sessionId } = req.params;
    const firestore = getFirestore();

    // 驗證 session 歸屬
    const sessionDoc = await firestore.collection('ai_travel_sessions').doc(sessionId).get();
    if (!sessionDoc.exists || sessionDoc.data()?.userId !== userId) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const messagesSnap = await firestore
      .collection('ai_travel_sessions')
      .doc(sessionId)
      .collection('messages')
      .orderBy('timestamp', 'asc')
      .get();

    const messages = messagesSnap.docs.map(doc => ({
      id: doc.id,
      role: doc.data().role,
      content: doc.data().content,
      timestamp: doc.data().timestamp?.toDate?.()?.toISOString(),
    }));

    return res.json({ messages });
  } catch (error) {
    console.error('[AI Travel] ❌ Get messages error:', error);
    return res.status(500).json({ error: 'Failed to get messages' });
  }
});

// ============================================
// DELETE /api/ai-travel-planner/sessions/:sessionId
// 刪除指定 session
// ============================================
router.delete('/sessions/:sessionId', async (req: Request, res: Response) => {
  try {
    const userId = req.user!.uid;
    const { sessionId } = req.params;
    const firestore = getFirestore();

    const sessionRef = firestore.collection('ai_travel_sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists || sessionDoc.data()?.userId !== userId) {
      return res.status(404).json({ error: 'Session not found' });
    }

    // 刪除所有子訊息
    const messagesSnap = await sessionRef.collection('messages').get();
    const batch = firestore.batch();
    messagesSnap.docs.forEach(doc => batch.delete(doc.ref));
    batch.delete(sessionRef);
    await batch.commit();

    console.log(`[AI Travel] 🗑️ Deleted session: ${sessionId}`);
    return res.json({ success: true });
  } catch (error) {
    console.error('[AI Travel] ❌ Delete session error:', error);
    return res.status(500).json({ error: 'Failed to delete session' });
  }
});

export default router;
