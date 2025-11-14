import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Firebase Admin SDK 初始化
 * 用於 Backend 直接操作 Firestore（創建聊天室等）
 */

let firebaseApp: admin.app.App | null = null;

/**
 * 處理私鑰格式
 * 支持三種格式：
 * 1. 包含 \\n 字符串的格式（雙反斜杠，需要替換為實際換行符）
 * 2. 包含 \n 字符串的格式（單反斜杠，需要替換為實際換行符）
 * 3. 已經包含實際換行符的格式（不需要處理）
 */
function processPrivateKey(privateKey: string | undefined): string | undefined {
  if (!privateKey) {
    return undefined;
  }

  // 檢查私鑰格式
  const hasDoubleBackslash = privateKey.includes('\\\\n');
  const hasSingleBackslash = privateKey.includes('\\n');
  const hasActualNewline = privateKey.includes('\n');

  console.log('[Firebase] 私鑰格式檢查:');
  console.log(`  - 包含 \\\\n (雙反斜杠): ${hasDoubleBackslash}`);
  console.log(`  - 包含 \\n (單反斜杠): ${hasSingleBackslash}`);
  console.log(`  - 包含實際換行符: ${hasActualNewline}`);

  // 如果私鑰包含 \\n（雙反斜杠），先替換為單反斜杠
  let processedKey = privateKey;
  if (hasDoubleBackslash) {
    console.log('[Firebase] 檢測到私鑰包含 \\\\n，正在轉換...');
    processedKey = processedKey.replace(/\\\\n/g, '\\n');
  }

  // 如果私鑰包含 \n 字符串（而不是實際換行符），則替換
  if (processedKey.includes('\\n') && !processedKey.includes('\n')) {
    console.log('[Firebase] 檢測到私鑰包含 \\n 字符串，正在轉換為實際換行符...');
    processedKey = processedKey.replace(/\\n/g, '\n');
  }

  // 驗證轉換後的私鑰格式
  const finalHasNewline = processedKey.includes('\n');
  const finalHasBegin = processedKey.includes('BEGIN PRIVATE KEY');
  const finalHasEnd = processedKey.includes('END PRIVATE KEY');

  console.log('[Firebase] 轉換後的私鑰格式:');
  console.log(`  - 包含實際換行符: ${finalHasNewline}`);
  console.log(`  - 包含 BEGIN PRIVATE KEY: ${finalHasBegin}`);
  console.log(`  - 包含 END PRIVATE KEY: ${finalHasEnd}`);

  if (!finalHasNewline || !finalHasBegin || !finalHasEnd) {
    console.error('[Firebase] ⚠️  私鑰格式可能不正確！');
  }

  return processedKey;
}

export function initializeFirebase(): admin.app.App {
  if (firebaseApp) {
    return firebaseApp;
  }

  try {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const privateKey = processPrivateKey(process.env.FIREBASE_PRIVATE_KEY);
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

    // 詳細日誌：檢查環境變數
    console.log('[Firebase Init] 環境變數檢查:');
    console.log(`  - FIREBASE_PROJECT_ID: ${projectId ? '✅' : '❌'}`);
    console.log(`  - FIREBASE_CLIENT_EMAIL: ${clientEmail ? '✅' : '❌'}`);
    console.log(`  - FIREBASE_PRIVATE_KEY: ${privateKey ? `✅ (長度: ${privateKey.length})` : '❌'}`);

    if (privateKey) {
      console.log(`  - Private Key 前50字符: ${privateKey.substring(0, 50)}...`);
      console.log(`  - Private Key 包含 BEGIN: ${privateKey.includes('BEGIN PRIVATE KEY') ? '✅' : '❌'}`);
      console.log(`  - Private Key 包含 END: ${privateKey.includes('END PRIVATE KEY') ? '✅' : '❌'}`);
    }

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
      console.log('[Firebase Init] 正在使用 Service Account 初始化...');
      console.log(`  - Project ID: ${projectId}`);
      console.log(`  - Client Email: ${clientEmail}`);

      try {
        // Firebase Admin SDK v12+ 需要明確的配置
        const credential = admin.credential.cert({
          projectId,
          privateKey,
          clientEmail,
        });

        // 測試憑證是否有效
        console.log('[Firebase Init] 憑證對象創建成功');
        console.log(`  - Credential type: ${typeof credential}`);

        firebaseApp = admin.initializeApp({
          credential,
          projectId,
          // Firebase Admin SDK v12+ 建議明確指定 databaseURL（即使不使用 Realtime Database）
          databaseURL: `https://${projectId}.firebaseio.com`,
        });

        console.log('✅ Firebase Admin SDK 已初始化');
        console.log(`  - App Name: ${firebaseApp.name}`);
        console.log(`  - Project ID: ${firebaseApp.options.projectId}`);

        // 測試 Firestore 連接
        try {
          const firestore = admin.firestore();
          console.log('[Firebase Init] Firestore 實例創建成功');
          console.log(`  - Firestore settings: ${JSON.stringify(firestore.settings)}`);
        } catch (firestoreError) {
          console.error('[Firebase Init] ⚠️  Firestore 實例創建失敗:', firestoreError);
        }
      } catch (credError: unknown) {
        console.error('❌ Firebase Admin SDK 憑證初始化失敗:');
        if (credError instanceof Error) {
          console.error(`  - 錯誤訊息: ${credError.message}`);
          console.error(`  - 錯誤堆棧: ${credError.stack}`);
        } else {
          console.error(`  - 錯誤: ${String(credError)}`);
        }
        throw credError;
      }
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
    console.log('[Firebase] 開始創建聊天室到 Firestore:', chatRoomData.bookingId);

    // 確保 Firebase 已初始化
    if (!firebaseApp) {
      console.log('[Firebase] Firebase App 未初始化，正在初始化...');
      initializeFirebase();
    }

    const firestore = getFirestore();
    const { bookingId } = chatRoomData;

    console.log('[Firebase] Firestore 實例已獲取');
    console.log('[Firebase] 準備寫入聊天室資料...');

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

    console.log('[Firebase] 聊天室資料已準備:', {
      bookingId,
      customerId: chatRoomData.customerId,
      driverId: chatRoomData.driverId,
    });

    // 寫入 Firestore（使用 bookingId 作為文檔 ID）
    console.log('[Firebase] 正在寫入 Firestore...');
    await firestore.collection('chat_rooms').doc(bookingId).set(chatRoom);

    console.log('[Firebase] ✅ 聊天室創建成功:', bookingId);

    return bookingId;
  } catch (error: unknown) {
    console.error('[Firebase] ❌ 創建聊天室失敗:');
    if (error instanceof Error) {
      console.error(`  - 錯誤訊息: ${error.message}`);
      console.error(`  - 錯誤名稱: ${error.name}`);
      console.error(`  - 錯誤堆棧: ${error.stack}`);
    } else {
      console.error(`  - 錯誤: ${String(error)}`);
    }

    // 檢查是否是認證錯誤
    const errorMessage = error instanceof Error ? error.message : String(error);
    if (errorMessage.includes('UNAUTHENTICATED') || errorMessage.includes('authentication')) {
      console.error('[Firebase] 🔐 這是一個認證錯誤！');
      console.error('[Firebase] 請檢查：');
      console.error('  1. FIREBASE_PRIVATE_KEY 格式是否正確');
      console.error('  2. Service Account 是否有 Firestore 權限');
      console.error('  3. Firebase Admin SDK 版本是否兼容');
    }

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
    console.log('[Firebase] 開始發送系統訊息:', { bookingId, message });

    // 確保 Firebase 已初始化
    if (!firebaseApp) {
      console.log('[Firebase] Firebase App 未初始化，正在初始化...');
      initializeFirebase();
    }

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

    console.log('[Firebase] 正在寫入訊息到 Firestore...');
    await firestore
      .collection('chat_rooms')
      .doc(bookingId)
      .collection('messages')
      .add(systemMessage);

    console.log('[Firebase] 正在更新聊天室最後訊息...');
    // 更新聊天室的最後訊息
    await firestore.collection('chat_rooms').doc(bookingId).update({
      lastMessage: message,
      lastMessageTime: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log('[Firebase] ✅ 系統訊息已發送:', message);
  } catch (error: unknown) {
    console.error('[Firebase] ❌ 發送系統訊息失敗:');
    if (error instanceof Error) {
      console.error(`  - 錯誤訊息: ${error.message}`);
      console.error(`  - 錯誤名稱: ${error.name}`);
    } else {
      console.error(`  - 錯誤: ${String(error)}`);
    }
    // 不拋出錯誤，避免影響主流程
  }
}

