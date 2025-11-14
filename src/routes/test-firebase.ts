import { Router, Request, Response } from 'express';
import { getFirestore, getFirebaseApp } from '../config/firebase';
import admin from 'firebase-admin';

const router = Router();

/**
 * 測試 Firebase 連接
 * GET /api/test-firebase
 */
router.get('/', async (_req: Request, res: Response) => {
  try {
    console.log('[Test] 開始測試 Firebase 連接...');
    
    // 1. 檢查 Firebase App
    const app = getFirebaseApp();
    console.log('[Test] Firebase App 狀態:');
    console.log(`  - Name: ${app.name}`);
    console.log(`  - Project ID: ${app.options.projectId}`);
    
    // 2. 獲取 Firestore 實例
    const firestore = getFirestore();
    console.log('[Test] Firestore 實例已獲取');
    
    // 3. 測試讀取操作
    console.log('[Test] 測試 Firestore 讀取操作...');
    const testDoc = await firestore.collection('_test').doc('connection_test').get();
    console.log('[Test] ✅ Firestore 讀取成功');
    console.log(`  - 文檔存在: ${testDoc.exists}`);
    
    // 4. 測試寫入操作
    console.log('[Test] 測試 Firestore 寫入操作...');
    await firestore.collection('_test').doc('connection_test').set({
      timestamp: admin.firestore.Timestamp.now(),
      message: 'Connection test successful',
      testId: Math.random().toString(36).substring(7),
    });
    console.log('[Test] ✅ Firestore 寫入成功');
    
    // 5. 測試讀取剛寫入的數據
    console.log('[Test] 測試讀取剛寫入的數據...');
    const verifyDoc = await firestore.collection('_test').doc('connection_test').get();
    const data = verifyDoc.data();
    console.log('[Test] ✅ Firestore 讀取驗證成功');
    console.log(`  - 數據: ${JSON.stringify(data)}`);
    
    // 6. 測試 chat_rooms collection 讀取
    console.log('[Test] 測試 chat_rooms collection 讀取...');
    const chatRoomsSnapshot = await firestore.collection('chat_rooms').limit(1).get();
    console.log('[Test] ✅ chat_rooms collection 讀取成功');
    console.log(`  - 文檔數量: ${chatRoomsSnapshot.size}`);
    
    // 7. 測試創建 chat_room 文檔
    console.log('[Test] 測試創建 chat_room 文檔...');
    const testChatRoomId = `test_${Date.now()}`;
    await firestore.collection('chat_rooms').doc(testChatRoomId).set({
      bookingId: testChatRoomId,
      customerId: 'test_customer',
      driverId: 'test_driver',
      customerName: '測試客戶',
      driverName: '測試司機',
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    });
    console.log('[Test] ✅ chat_room 文檔創建成功');
    console.log(`  - 文檔 ID: ${testChatRoomId}`);
    
    // 8. 清理測試數據
    console.log('[Test] 清理測試數據...');
    await firestore.collection('chat_rooms').doc(testChatRoomId).delete();
    console.log('[Test] ✅ 測試數據已清理');
    
    res.status(200).json({
      success: true,
      message: 'Firebase 連接測試成功',
      details: {
        firebaseApp: {
          name: app.name,
          projectId: app.options.projectId,
        },
        firestoreTests: {
          read: '✅ 成功',
          write: '✅ 成功',
          chatRoomsRead: '✅ 成功',
          chatRoomCreate: '✅ 成功',
        },
        testData: data,
      },
    });
  } catch (error: unknown) {
    console.error('[Test] ❌ Firebase 連接測試失敗:');
    if (error instanceof Error) {
      console.error(`  - 錯誤訊息: ${error.message}`);
      console.error(`  - 錯誤名稱: ${error.name}`);
      console.error(`  - 錯誤堆棧: ${error.stack}`);
    } else {
      console.error(`  - 錯誤: ${String(error)}`);
    }
    
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : String(error),
      details: {
        name: error instanceof Error ? error.name : 'Unknown',
        stack: error instanceof Error ? error.stack : undefined,
      },
    });
  }
});

export default router;

