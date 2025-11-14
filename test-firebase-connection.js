/**
 * 測試 Firebase Admin SDK 連接和權限
 * 
 * 用途：診斷 Firebase Firestore UNAUTHENTICATED 錯誤
 */

import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

async function testFirebaseConnection() {
  console.log('========================================');
  console.log('Firebase Admin SDK 連接測試');
  console.log('========================================\n');

  // 1. 檢查環境變數
  console.log('1️⃣  檢查環境變數:');
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

  console.log(`   FIREBASE_PROJECT_ID: ${projectId ? '✅ 已設置' : '❌ 未設置'}`);
  console.log(`   FIREBASE_CLIENT_EMAIL: ${clientEmail ? '✅ 已設置' : '❌ 未設置'}`);
  console.log(`   FIREBASE_PRIVATE_KEY: ${privateKey ? '✅ 已設置 (長度: ' + privateKey.length + ')' : '❌ 未設置'}`);

  if (!projectId || !privateKey || !clientEmail) {
    console.error('\n❌ 環境變數配置不完整，無法繼續測試');
    process.exit(1);
  }

  console.log(`\n   Project ID: ${projectId}`);
  console.log(`   Client Email: ${clientEmail}`);
  console.log(`   Private Key (前50字符): ${privateKey.substring(0, 50)}...`);

  // 2. 初始化 Firebase Admin SDK
  console.log('\n2️⃣  初始化 Firebase Admin SDK:');
  try {
    const app = admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        privateKey,
        clientEmail,
      }),
      projectId,
    });
    console.log('   ✅ Firebase Admin SDK 初始化成功');
    console.log(`   App Name: ${app.name}`);
  } catch (error) {
    console.error('   ❌ Firebase Admin SDK 初始化失敗:', error.message);
    process.exit(1);
  }

  // 3. 測試 Firestore 讀取權限
  console.log('\n3️⃣  測試 Firestore 讀取權限:');
  try {
    const firestore = admin.firestore();
    console.log('   ✅ Firestore 實例創建成功');

    // 嘗試讀取一個測試集合
    console.log('   正在嘗試讀取 chat_rooms 集合...');
    const snapshot = await firestore.collection('chat_rooms').limit(1).get();
    console.log(`   ✅ Firestore 讀取成功 (找到 ${snapshot.size} 個文檔)`);
  } catch (error) {
    console.error('   ❌ Firestore 讀取失敗:');
    console.error(`      錯誤代碼: ${error.code}`);
    console.error(`      錯誤訊息: ${error.message}`);
    console.error(`      詳細信息: ${error.details || 'N/A'}`);
    
    if (error.code === 16 || error.code === 'UNAUTHENTICATED') {
      console.error('\n   ⚠️  這是一個身份驗證錯誤！');
      console.error('   可能的原因：');
      console.error('   1. Service Account 沒有 Firestore 訪問權限');
      console.error('   2. Private Key 格式不正確');
      console.error('   3. Service Account 已被禁用或刪除');
      console.error('   4. Firebase 項目配置錯誤');
    }
    
    process.exit(1);
  }

  // 4. 測試 Firestore 寫入權限
  console.log('\n4️⃣  測試 Firestore 寫入權限:');
  try {
    const firestore = admin.firestore();
    const testDocId = `test_${Date.now()}`;
    
    console.log(`   正在嘗試寫入測試文檔: ${testDocId}...`);
    await firestore.collection('_test_connection').doc(testDocId).set({
      timestamp: admin.firestore.Timestamp.now(),
      message: 'Connection test',
    });
    console.log('   ✅ Firestore 寫入成功');

    // 清理測試文檔
    console.log('   正在清理測試文檔...');
    await firestore.collection('_test_connection').doc(testDocId).delete();
    console.log('   ✅ 測試文檔已清理');
  } catch (error) {
    console.error('   ❌ Firestore 寫入失敗:');
    console.error(`      錯誤代碼: ${error.code}`);
    console.error(`      錯誤訊息: ${error.message}`);
    console.error(`      詳細信息: ${error.details || 'N/A'}`);
    process.exit(1);
  }

  // 5. 測試聊天室創建
  console.log('\n5️⃣  測試聊天室創建:');
  try {
    const firestore = admin.firestore();
    const testBookingId = `test_booking_${Date.now()}`;
    
    const chatRoom = {
      bookingId: testBookingId,
      customerId: 'test_customer',
      driverId: 'test_driver',
      customerName: '測試客戶',
      driverName: '測試司機',
      pickupAddress: '測試地址',
      bookingTime: admin.firestore.Timestamp.now(),
      lastMessage: null,
      lastMessageTime: null,
      customerUnreadCount: 0,
      driverUnreadCount: 0,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    };

    console.log(`   正在創建測試聊天室: ${testBookingId}...`);
    await firestore.collection('chat_rooms').doc(testBookingId).set(chatRoom);
    console.log('   ✅ 聊天室創建成功');

    // 驗證聊天室是否存在
    console.log('   正在驗證聊天室是否存在...');
    const doc = await firestore.collection('chat_rooms').doc(testBookingId).get();
    if (doc.exists) {
      console.log('   ✅ 聊天室驗證成功');
    } else {
      console.error('   ❌ 聊天室驗證失敗：文檔不存在');
    }

    // 清理測試聊天室
    console.log('   正在清理測試聊天室...');
    await firestore.collection('chat_rooms').doc(testBookingId).delete();
    console.log('   ✅ 測試聊天室已清理');
  } catch (error) {
    console.error('   ❌ 聊天室創建失敗:');
    console.error(`      錯誤代碼: ${error.code}`);
    console.error(`      錯誤訊息: ${error.message}`);
    console.error(`      詳細信息: ${error.details || 'N/A'}`);
    process.exit(1);
  }

  // 6. 總結
  console.log('\n========================================');
  console.log('✅ 所有測試通過！');
  console.log('========================================');
  console.log('\nFirebase Admin SDK 配置正確，Firestore 權限正常。');
  console.log('如果生產環境仍然出現 UNAUTHENTICATED 錯誤，請檢查：');
  console.log('1. Railway 環境變數是否與本地 .env 一致');
  console.log('2. Private Key 中的換行符是否正確處理');
  console.log('3. Firebase 項目的 IAM 權限設置');
  
  process.exit(0);
}

// 執行測試
testFirebaseConnection().catch((error) => {
  console.error('\n❌ 測試過程中發生未預期的錯誤:');
  console.error(error);
  process.exit(1);
});

