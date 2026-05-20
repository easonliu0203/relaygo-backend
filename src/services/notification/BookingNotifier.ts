/**
 * BookingNotifier
 *
 * 發送 booking lifecycle 推播給客戶或司機的統一進入點。
 *
 * 為什麼要這個 service？
 *   既有 NotificationService 撈 FCM token 時把 Supabase UUID 當 Firebase UID 用
 *   （`firestore.collection('users').doc(<Supabase-UUID>)`），所以從來抓不到 token，
 *   booking 相關推播實際從未送達。本 service 把「Supabase users.id → users.firebase_uid
 *   → Firestore users/{firebase_uid}.fcmToken」這條鏈路修正並集中管理。
 *
 * 用法：
 *   await notifyBookingEvent({
 *     bookingId,
 *     recipientUserId: '<Supabase UUID>',  // 不是 Firebase UID
 *     eventType: 'driver_arrived',
 *     vars: { driverName: '金城武', shortId: 'ABC123' }
 *   });
 *
 * 故障策略：所有錯誤皆 try/catch + log，**永遠不拋出**，避免擋住主流程。
 */
import admin from 'firebase-admin';
import { createClient } from '@supabase/supabase-js';
import { getFirebaseApp, getFirestore } from '../../config/firebase';
import { pushI18n } from '../i18n/PushI18nService';

type EventType = 'driver_assigned' | 'driver_confirmed' | 'driver_departed' | 'driver_arrived' | 'driver_changed';

interface NotifyArgs {
  bookingId: string;
  recipientUserId: string; // Supabase users.id (UUID)
  eventType: EventType;
  vars?: Record<string, string>;
}

const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function notifyBookingEvent(args: NotifyArgs): Promise<void> {
  const { bookingId, recipientUserId, eventType, vars = {} } = args;
  const logPrefix = `[BookingNotifier ${eventType} booking=${bookingId.slice(0, 8)}]`;

  try {
    // 1. Supabase → 取 firebase_uid + preferred_language
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('firebase_uid, preferred_language')
      .eq('id', recipientUserId)
      .single();

    if (userError || !user) {
      console.warn(`${logPrefix} 找不到收件人 user：`, userError?.message || 'no row');
      return;
    }

    if (!user.firebase_uid) {
      console.warn(`${logPrefix} 收件人沒有 firebase_uid，跳過推播`);
      return;
    }

    // 2. Firestore → 取 fcmToken
    const firestore = getFirestore();
    const userDoc = await firestore.collection('users').doc(user.firebase_uid).get();

    if (!userDoc.exists) {
      console.warn(`${logPrefix} Firestore 沒有 users/${user.firebase_uid} 文件`);
      return;
    }

    const fcmToken = userDoc.data()?.fcmToken as string | undefined;
    if (!fcmToken) {
      console.warn(`${logPrefix} 收件人沒有 fcmToken（可能沒裝 app 或沒授權通知）`);
      return;
    }

    // 3. i18n → 取本地化文案
    await pushI18n.ensureLoaded();
    const { title, body } = pushI18n.get(eventType, user.preferred_language, vars);

    // 4. 發 FCM
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: { title, body },
      data: {
        type: eventType,
        bookingId,
        ...(vars.driverName ? { driverName: vars.driverName } : {}),
        ...(vars.shortId ? { shortId: vars.shortId } : {}),
      },
      android: {
        priority: 'high',
        notification: {
          // 用 AndroidManifest 註冊的預設 channel，Firebase Messaging 會自動建立並帶聲音/震動。
          // 若想為訂單事件單獨建一個 channel（如 'booking_events'），mobile 端要先在
          // foreground_notification_service.dart 用 AndroidNotificationChannel 註冊好聲音設定，
          // 否則 Android 會 fallback 出一個無聲版本。
          channelId: 'high_importance_channel',
          priority: 'high',
          sound: 'default',
          defaultVibrateTimings: true,
          defaultLightSettings: true,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1,
            contentAvailable: true,
            category: 'BOOKING_EVENT',
          },
        },
        headers: { 'apns-priority': '10' },
      },
    };

    const messaging = admin.messaging(getFirebaseApp());
    const response = await messaging.send(message);
    console.log(`${logPrefix} ✅ FCM sent:`, response);
  } catch (error: any) {
    console.error(`${logPrefix} ❌ 推播失敗：`, error?.message || error);

    // 處理失效 token：從 Firestore 刪掉
    if (
      error?.code === 'messaging/invalid-registration-token' ||
      error?.code === 'messaging/registration-token-not-registered'
    ) {
      try {
        const { data: user } = await supabase
          .from('users')
          .select('firebase_uid')
          .eq('id', recipientUserId)
          .single();
        if (user?.firebase_uid) {
          await getFirestore().collection('users').doc(user.firebase_uid).update({
            fcmToken: admin.firestore.FieldValue.delete(),
            fcmTokenDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
            fcmTokenDeleteReason: 'Invalid or unregistered token',
          });
          console.log(`${logPrefix} 🧹 已清理失效 fcmToken`);
        }
      } catch (cleanupErr) {
        console.error(`${logPrefix} 清理失效 token 失敗：`, cleanupErr);
      }
    }
  }
}
