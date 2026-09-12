/**
 * 聊天室「呼叫對方」API（2026-09-12）
 *
 * 客戶或司機在聊天室按「呼叫對方」→ 對方手機響鈴 30 秒，
 * 直到對方點響鈴通知、在聊天室按「正準備回覆」、響鈴中送出訊息，或 30 秒逾時。
 *
 * - 呼叫狀態寫在 chat_rooms/{bookingId}.activeCall（Admin SDK 寫入，App 只讀，不需改 Firestore rules）
 * - 聊天紀錄留一則 messageType='call' 的系統訊息：
 *   senderId='system' → Cloud Function onNewChatMessage 會跳過（不會多發「XXX 發送了新訊息」）
 *   預先帶 translations → Cloud Function onMessageCreate 會跳過（不花 OpenAI 翻譯費）
 * - 推播：Android 送 data-only，由 App 自己顯示「持續響鈴」通知（手機預設鈴聲）；
 *         iOS 由系統顯示通知並播放 App 內附的 30 秒鈴聲 ring30.wav
 * - 被呼叫方回覆（正準備回覆）時，推播通知呼叫方；因送出訊息而回覆時不推播（訊息本身會通知）
 * - 聊天室開放前（上車前 24 小時才開放）不能呼叫；行程結束（或取消）後也不能再呼叫
 *
 * 失敗回應帶 code，App 依此顯示對應提示：
 *   ROOM_NOT_FOUND / NOT_MEMBER / CHAT_NOT_OPEN / TRIP_ENDED / COOLDOWN / OTHER_PARTY_CALLING
 */
import { Router, Request, Response } from 'express';
import admin from 'firebase-admin';
import { createClient } from '@supabase/supabase-js';
import { requireAuth } from '../middleware/auth';
import { getFirebaseApp, getFirestore } from '../config/firebase';
import { pushI18n } from '../services/i18n/PushI18nService';

const router = Router();

/** 響鈴時間（mobile ChatCall.ringSeconds 要一致） */
const RING_DURATION_MS = 30 * 1000;
/** 同一個人再按「呼叫對方」的冷卻時間，比響鈴多 2 秒避免重疊（mobile ChatCall.cooldownSeconds 要一致） */
const RING_COOLDOWN_MS = 32 * 1000;
/** 按「正準備回覆」的網路延遲寬限 */
const ACK_GRACE_MS = 5 * 1000;
/** 「對方正準備回覆」推播的有效時間：呼叫方太久沒上線就不送了 */
const ACK_PUSH_TTL_MS = 10 * 60 * 1000;
/** iOS 響鈴音檔（mobile/ios/Runner/ring30.wav，iOS 通知音上限 30 秒） */
const IOS_RING_SOUND = 'ring30.wav';
/** 「對方正準備回覆」的 Android 通知頻道（mobile ChatRingNotifier 會建立） */
const ACK_CHANNEL_ID = 'chat_ring_ack';
/** 行程已結束（或取消）的訂單狀態：不能再呼叫 */
const ENDED_BOOKING_STATUSES = ['trip_ended', 'pending_balance', 'completed', 'cancelled', 'refunded'];

const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

type Role = 'customer' | 'driver';

interface RingCreated {
  ok: true;
  callId: string;
  calleeId: string;
  callerName: string;
  callerRole: Role;
  expiresAtMs: number;
}

interface Rejected {
  ok: false;
  status: number;
  code: string;
  error: string;
  retryAfterMs?: number;
}

interface AckResult {
  status: number;
  error?: string;
  /** 這次請求才把呼叫改成已回覆（重複回覆為 false，不再推播） */
  newlyAcked?: boolean;
  callId?: string;
  callerId?: string;
  calleeName?: string;
}

/**
 * @route POST /api/chat-calls/:bookingId/ring
 * @desc 呼叫聊天室的另一方（對方手機響鈴 30 秒）
 * @access 聊天室的客戶或司機（需要認證），行程結束後不能呼叫
 */
router.post('/:bookingId/ring', requireAuth, async (req: Request, res: Response) => {
  const uid = req.user!.uid; // 身分一律取自已驗證的登入憑證，不相信請求裡帶的 ID
  const { bookingId } = req.params;
  const logPrefix = `[ChatCall ring booking=${bookingId.slice(0, 8)}]`;

  try {
    const firestore = getFirestore();
    const roomRef = firestore.collection('chat_rooms').doc(bookingId);

    const result: RingCreated | Rejected = await firestore.runTransaction(async (tx) => {
      const snap = await tx.get(roomRef);
      if (!snap.exists) {
        return { ok: false, status: 404, code: 'ROOM_NOT_FOUND', error: '聊天室不存在' };
      }
      const room = snap.data()!;

      let callerRole: Role;
      if (room.customerId === uid) {
        callerRole = 'customer';
      } else if (room.driverId === uid) {
        callerRole = 'driver';
      } else {
        return { ok: false, status: 403, code: 'NOT_MEMBER', error: '你不是這個聊天室的成員' };
      }

      const chatOpensAtMs: number | undefined = room.chatOpensAt?.toMillis?.();
      if (chatOpensAtMs !== undefined && Date.now() < chatOpensAtMs) {
        return { ok: false, status: 403, code: 'CHAT_NOT_OPEN', error: '聊天室尚未開放（上車前 24 小時開放）' };
      }

      if (await isTripEnded(bookingId, logPrefix)) {
        return { ok: false, status: 403, code: 'TRIP_ENDED', error: '行程已結束，無法呼叫' };
      }

      const now = admin.firestore.Timestamp.now();
      const last = room.activeCall;
      const lastCreatedMs: number | undefined = last?.createdAt?.toMillis?.();
      if (lastCreatedMs !== undefined) {
        const elapsed = now.toMillis() - lastCreatedMs;
        if (last.callerId === uid && elapsed < RING_COOLDOWN_MS) {
          return {
            ok: false,
            status: 429,
            code: 'COOLDOWN',
            error: '呼叫太頻繁，請稍後再試',
            retryAfterMs: RING_COOLDOWN_MS - elapsed,
          };
        }
        // 對方正在呼叫你（還在響），不能蓋掉對方的呼叫，直接按「正準備回覆」即可
        const lastExpiresMs: number | undefined = last.expiresAt?.toMillis?.();
        if (
          last.callerId !== uid &&
          last.status === 'ringing' &&
          lastExpiresMs !== undefined &&
          now.toMillis() < lastExpiresMs
        ) {
          return { ok: false, status: 409, code: 'OTHER_PARTY_CALLING', error: '對方正在呼叫你' };
        }
      }

      const isCustomer = callerRole === 'customer';
      const calleeId: string = isCustomer ? room.driverId : room.customerId;
      const callerName: string = (isCustomer ? room.customerName : room.driverName) || (isCustomer ? '客戶' : '司機');
      const calleeName: string = (isCustomer ? room.driverName : room.customerName) || (isCustomer ? '司機' : '客戶');
      const callId = roomRef.collection('messages').doc().id;
      const expiresAt = admin.firestore.Timestamp.fromMillis(now.toMillis() + RING_DURATION_MS);
      // App 會依使用者語言顯示；這段中文給舊版 App 與聊天列表用
      const logText = isCustomer ? '📞 客戶呼叫了司機' : '📞 司機呼叫了客戶';

      tx.set(roomRef.collection('messages').doc(callId), {
        senderId: 'system',
        receiverId: calleeId,
        senderName: '系統',
        receiverName: calleeName,
        messageText: logText,
        translatedText: null,
        translations: { 'zh-TW': { text: logText } },
        detectedLang: 'zh-TW',
        createdAt: now,
        readAt: null,
        messageType: 'call',
        callId,
        callerId: uid,
        callerRole,
      });

      tx.update(roomRef, {
        activeCall: {
          callId,
          callerId: uid,
          calleeId,
          callerRole,
          status: 'ringing',
          createdAt: now,
          expiresAt,
        },
        lastMessage: logText,
        lastMessageTime: now,
        updatedAt: now,
        [isCustomer ? 'driverUnreadCount' : 'customerUnreadCount']: admin.firestore.FieldValue.increment(1),
      });

      return {
        ok: true,
        callId,
        calleeId,
        callerName,
        callerRole,
        expiresAtMs: expiresAt.toMillis(),
      };
    });

    if (!result.ok) {
      return res.status(result.status).json({
        success: false,
        code: result.code,
        error: result.error,
        ...(result.retryAfterMs !== undefined ? { retryAfterMs: result.retryAfterMs } : {}),
      });
    }

    const pushSent = await sendRingPush(bookingId, result, logPrefix);
    console.log(`${logPrefix} ✅ ${result.callerRole} 呼叫對方 callId=${result.callId} pushSent=${pushSent}`);

    return res.json({
      success: true,
      callId: result.callId,
      expiresAt: result.expiresAtMs,
      pushSent,
    });
  } catch (error: any) {
    console.error(`${logPrefix} ❌ 呼叫失敗：`, error?.message || error);
    return res.status(500).json({ success: false, error: '呼叫失敗' });
  }
});

/**
 * @route POST /api/chat-calls/:bookingId/ack
 * @desc 被呼叫方「正準備回覆」（點響鈴通知、按按鈕、或響鈴中送出訊息）
 * @body callId（選填，沒帶就回覆目前這次呼叫）、silent（true = 不推播給呼叫方，送出訊息時用）
 * @access 被呼叫的人（需要認證）
 */
router.post('/:bookingId/ack', requireAuth, async (req: Request, res: Response) => {
  const uid = req.user!.uid;
  const { bookingId } = req.params;
  const { callId, silent } = req.body || {};
  const logPrefix = `[ChatCall ack booking=${bookingId.slice(0, 8)}]`;

  try {
    const firestore = getFirestore();
    const roomRef = firestore.collection('chat_rooms').doc(bookingId);

    const result: AckResult = await firestore.runTransaction(async (tx) => {
      const snap = await tx.get(roomRef);
      if (!snap.exists) {
        return { status: 404, error: '聊天室不存在' };
      }

      const room = snap.data()!;
      const call = room.activeCall;
      if (!call || (callId && call.callId !== callId)) {
        return { status: 404, error: '找不到這次呼叫' };
      }
      if (call.calleeId !== uid) {
        return { status: 403, error: '只有被呼叫的人可以回覆' };
      }
      if (call.status === 'acknowledged') {
        return { status: 200, newlyAcked: false };
      }

      const now = admin.firestore.Timestamp.now();
      if (now.toMillis() > call.expiresAt.toMillis() + ACK_GRACE_MS) {
        return { status: 410, error: '呼叫已逾時' };
      }

      tx.update(roomRef, {
        'activeCall.status': 'acknowledged',
        'activeCall.acknowledgedAt': now,
        updatedAt: now,
      });

      const calleeIsCustomer = room.customerId === uid;
      return {
        status: 200,
        newlyAcked: true,
        callId: call.callId,
        callerId: call.callerId,
        calleeName: (calleeIsCustomer ? room.customerName : room.driverName) || (calleeIsCustomer ? '客戶' : '司機'),
      };
    });

    if (result.status !== 200) {
      return res.status(result.status).json({ success: false, error: result.error });
    }

    let pushSent = false;
    if (result.newlyAcked && silent !== true) {
      pushSent = await sendAckPush(bookingId, result, logPrefix);
    }

    console.log(`${logPrefix} ✅ 被呼叫方已回覆 callId=${result.callId ?? callId} silent=${silent === true} pushSent=${pushSent}`);
    return res.json({ success: true, pushSent });
  } catch (error: any) {
    console.error(`${logPrefix} ❌ 回覆失敗：`, error?.message || error);
    return res.status(500).json({ success: false, error: '回覆失敗' });
  }
});

/**
 * 行程是否已結束（或取消）。
 * 查不到訂單視為已結束；查詢失敗則放行，避免 Supabase 暫時故障讓呼叫功能全壞。
 */
async function isTripEnded(bookingId: string, logPrefix: string): Promise<boolean> {
  const { data, error } = await supabase
    .from('bookings')
    .select('status')
    .eq('id', bookingId)
    .maybeSingle();

  if (error) {
    console.warn(`${logPrefix} 查詢訂單狀態失敗，先放行：`, error.message);
    return false;
  }
  if (!data) {
    return true;
  }
  return ENDED_BOOKING_STATUSES.includes(data.status);
}

/** 取得推播對象的 FCM token 與語言；沒有 token 回傳 null */
async function getPushTarget(uid: string): Promise<{ token: string; language: string | null } | null> {
  const userDoc = await getFirestore().collection('users').doc(uid).get();
  const token = userDoc.data()?.fcmToken as string | undefined;
  if (!token) {
    return null;
  }

  const { data: user } = await supabase
    .from('users')
    .select('preferred_language')
    .eq('firebase_uid', uid)
    .maybeSingle();

  return { token, language: user?.preferred_language ?? null };
}

/** 推播失敗時，失效的 token 從 Firestore 清掉 */
async function cleanupInvalidToken(uid: string, error: any, logPrefix: string): Promise<void> {
  if (
    error?.code !== 'messaging/invalid-registration-token' &&
    error?.code !== 'messaging/registration-token-not-registered'
  ) {
    return;
  }
  try {
    await getFirestore().collection('users').doc(uid).update({
      fcmToken: admin.firestore.FieldValue.delete(),
      fcmTokenDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
      fcmTokenDeleteReason: 'Invalid or unregistered token',
    });
    console.log(`${logPrefix} 🧹 已清理失效 fcmToken`);
  } catch (cleanupErr) {
    console.error(`${logPrefix} 清理失效 token 失敗：`, cleanupErr);
  }
}

/**
 * 發響鈴推播給被呼叫方。永遠不拋出，回傳是否送出。
 */
async function sendRingPush(bookingId: string, call: RingCreated, logPrefix: string): Promise<boolean> {
  try {
    const target = await getPushTarget(call.calleeId);
    if (!target) {
      console.warn(`${logPrefix} 被呼叫方沒有 fcmToken（可能沒裝 app 或沒授權通知）`);
      return false;
    }

    await pushI18n.ensureLoaded();
    const { title, body } = pushI18n.get('chat_ring', target.language, {
      callerName: call.callerName,
    });

    const ttlMs = Math.max(1000, call.expiresAtMs - Date.now());
    const message: admin.messaging.Message = {
      token: target.token,
      // Android 沒有 notification 區塊 = data-only，由 App 背景處理器顯示持續響鈴通知
      data: {
        type: 'chat_ring',
        bookingId,
        callId: call.callId,
        callerRole: call.callerRole,
        callerName: call.callerName,
        title,
        body,
        expiresAt: String(call.expiresAtMs),
      },
      // 過期不送：避免對方手機晚了才響
      android: { priority: 'high', ttl: ttlMs },
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
          'apns-expiration': String(Math.floor(call.expiresAtMs / 1000)),
        },
        payload: {
          aps: {
            alert: { title, body },
            sound: IOS_RING_SOUND,
            category: 'CHAT_RING',
          },
        },
      },
    };

    await admin.messaging(getFirebaseApp()).send(message);
    return true;
  } catch (error: any) {
    console.error(`${logPrefix} ❌ 響鈴推播失敗：`, error?.message || error);
    await cleanupInvalidToken(call.calleeId, error, logPrefix);
    return false;
  }
}

/**
 * 推播「對方正準備回覆」給呼叫方。永遠不拋出，回傳是否送出。
 */
async function sendAckPush(bookingId: string, ack: AckResult, logPrefix: string): Promise<boolean> {
  if (!ack.callerId) {
    return false;
  }
  try {
    const target = await getPushTarget(ack.callerId);
    if (!target) {
      console.warn(`${logPrefix} 呼叫方沒有 fcmToken，略過「正準備回覆」推播`);
      return false;
    }

    await pushI18n.ensureLoaded();
    const { title, body } = pushI18n.get('chat_ring_ack', target.language, {
      calleeName: ack.calleeName || '',
    });

    const message: admin.messaging.Message = {
      token: target.token,
      notification: { title, body },
      data: {
        type: 'chat_ring_ack',
        bookingId,
        callId: ack.callId || '',
      },
      android: {
        priority: 'high',
        ttl: ACK_PUSH_TTL_MS,
        notification: {
          channelId: ACK_CHANNEL_ID,
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        headers: { 'apns-priority': '10' },
        payload: { aps: { sound: 'default' } },
      },
    };

    await admin.messaging(getFirebaseApp()).send(message);
    return true;
  } catch (error: any) {
    console.error(`${logPrefix} ❌「正準備回覆」推播失敗：`, error?.message || error);
    await cleanupInvalidToken(ack.callerId, error, logPrefix);
    return false;
  }
}

export default router;
