import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Firebase Admin SDK 初始化
 * 用於 Backend 直接操作 Firestore（創建聊天室等）
 */

let firebaseApp: admin.app.App | null = null;

export function initializeFirebase(): admin.app.App {
  if (firebaseApp) {
    return firebaseApp;
  }

  try {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

    if (!projectId || !privateKey || !clientEmail) {
      console.warn('⚠️  Firebase Admin SDK 配置不完整，使用模擬模式');
      console.warn('   請在 .env 文件中設置：');
      console.warn('   - FIREBASE_PROJECT_ID');
      console.warn('   - FIREBASE_PRIVATE_KEY');
      console.warn('   - FIREBASE_CLIENT_EMAIL');
      
      // 返回一個模擬的 app（用於開發環境）
      // 在生產環境中應該拋出錯誤
      if (process.env.NODE_ENV === 'production') {
        throw new Error('Firebase Admin SDK 配置不完整');
      }
      
      // 開發環境：使用應用默認憑證（如果可用）
      try {
        firebaseApp = admin.initializeApp({
          projectId: projectId || 'ride-platform-f1676',
        });
        console.log('✅ Firebase Admin SDK 已初始化（使用應用默認憑證）');
      } catch (error) {
        console.error('❌ Firebase Admin SDK 初始化失敗:', error);
        throw error;
      }
    } else {
      // 使用服務帳戶憑證初始化
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          privateKey,
          clientEmail,
        }),
        projectId,
      });
      console.log('✅ Firebase Admin SDK 已初始化');
    }

    return firebaseApp;
  } catch (error) {
    console.error('❌ Firebase Admin SDK 初始化失敗:', error);
    throw error;
  }
}

/**
 * 獲取 Firestore 實例
 */
export function getFirestore(): admin.firestore.Firestore {
  if (!firebaseApp) {
    initializeFirebase();
  }
  return admin.firestore();
}

/**
 * 獲取 Firebase Admin App 實例
 */
export function getFirebaseApp(): admin.app.App {
  if (!firebaseApp) {
    initializeFirebase();
  }
  return firebaseApp!;
}

/**
 * 創建聊天室到 Firestore
 * 
 * @param chatRoomData 聊天室資料
 * @returns 創建的聊天室 ID
 */
export async function createChatRoomInFirestore(chatRoomData: {
  bookingId: string;
  customerId: string;
  driverId: string;
  customerName?: string;
  driverName?: string;
  pickupAddress?: string;
  bookingTime?: string;
}): Promise<string> {
  try {
    const firestore = getFirestore();
    const { bookingId } = chatRoomData;

    console.log('[Firebase] 開始創建聊天室到 Firestore:', bookingId);

    // 準備聊天室資料
    const chatRoom = {
      bookingId,
      customerId: chatRoomData.customerId,
      driverId: chatRoomData.driverId,
      customerName: chatRoomData.customerName || '客戶',
      driverName: chatRoomData.driverName || '司機',
      pickupAddress: chatRoomData.pickupAddress || '',
      bookingTime: chatRoomData.bookingTime 
        ? admin.firestore.Timestamp.fromDate(new Date(chatRoomData.bookingTime))
        : admin.firestore.Timestamp.now(),
      lastMessage: null,
      lastMessageTime: null,
      customerUnreadCount: 0,
      driverUnreadCount: 0,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    };

    // 寫入 Firestore（使用 bookingId 作為文檔 ID）
    await firestore.collection('chat_rooms').doc(bookingId).set(chatRoom);

    console.log('[Firebase] ✅ 聊天室創建成功:', bookingId);
    console.log('[Firebase] 聊天室資料:', JSON.stringify(chatRoom, null, 2));

    return bookingId;
  } catch (error) {
    console.error('[Firebase] ❌ 創建聊天室失敗:', error);
    throw error;
  }
}

/**
 * 檢查聊天室是否存在
 * 
 * @param bookingId 訂單 ID
 * @returns 是否存在
 */
export async function chatRoomExists(bookingId: string): Promise<boolean> {
  try {
    const firestore = getFirestore();
    const doc = await firestore.collection('chat_rooms').doc(bookingId).get();
    return doc.exists;
  } catch (error) {
    console.error('[Firebase] 檢查聊天室失敗:', error);
    return false;
  }
}

/**
 * 發送系統訊息到聊天室
 *
 * @param bookingId 訂單 ID
 * @param message 訊息內容
 */
export async function sendSystemMessage(
  bookingId: string,
  message: string
): Promise<void> {
  try {
    const firestore = getFirestore();

    const systemMessage = {
      senderId: 'system',
      receiverId: 'all',
      senderName: '系統',
      receiverName: '所有人',
      messageText: message,
      translatedText: null,
      createdAt: admin.firestore.Timestamp.now(),
      readAt: null,
    };

    await firestore
      .collection('chat_rooms')
      .doc(bookingId)
      .collection('messages')
      .add(systemMessage);

    // 更新聊天室的最後訊息
    await firestore.collection('chat_rooms').doc(bookingId).update({
      lastMessage: message,
      lastMessageTime: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log('[Firebase] ✅ 系統訊息已發送:', message);
  } catch (error) {
    console.error('[Firebase] ❌ 發送系統訊息失敗:', error);
    // 不拋出錯誤，避免影響主流程
  }
}

/**
 * 儲存司機位置歷史記錄到 Firestore
 *
 * @param bookingId 訂單 ID
 * @param status 狀態（driver_departed 或 driver_arrived）
 * @param latitude 緯度
 * @param longitude 經度
 */
export async function saveDriverLocationHistory(
  bookingId: string,
  status: 'driver_departed' | 'driver_arrived',
  latitude: number,
  longitude: number
): Promise<void> {
  try {
    const firestore = getFirestore();

    const locationData = {
      status,
      latitude,
      longitude,
      googleMapsUrl: `https://www.google.com/maps?q=${latitude},${longitude}`,
      appleMapsUrl: `https://maps.apple.com/?q=${latitude},${longitude}`,
      timestamp: admin.firestore.Timestamp.now(),
    };

    await firestore
      .collection('bookings')
      .doc(bookingId)
      .collection('location_history')
      .add(locationData);

    console.log(`[Firebase] ✅ 司機位置歷史記錄已儲存: ${status}`, { latitude, longitude });
  } catch (error) {
    console.error('[Firebase] ❌ 儲存司機位置歷史記錄失敗:', error);
    throw error;
  }
}

