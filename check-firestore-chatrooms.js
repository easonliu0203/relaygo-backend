/**
 * 檢查 Firestore chat_rooms collection
 * 
 * 使用方法：
 * node check-firestore-chatrooms.js
 */

const admin = require('firebase-admin');

// 初始化 Firebase Admin
const serviceAccount = require('./ride-platform-f1676-firebase-adminsdk-fbsvc-8fad5fdb15.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const firestore = admin.firestore();

async function checkFirestoreChatRooms() {
  console.log('='.repeat(80));
  console.log('檢查 Firestore chat_rooms Collection');
  console.log('='.repeat(80));
  console.log('');

  try {
    // 檢查 chat_rooms collection
    const chatRoomsSnapshot = await firestore.collection('chat_rooms').get();
    
    console.log(`✅ Firestore 中有 ${chatRoomsSnapshot.size} 個聊天室`);
    console.log('');

    if (chatRoomsSnapshot.empty) {
      console.log('⚠️ Firestore 中沒有聊天室');
      console.log('');
      console.log('可能原因：');
      console.log('1. 訂單狀態不是 "driver_confirmed"');
      console.log('2. 聊天室創建失敗');
      console.log('3. Firestore 同步失敗');
      console.log('');
      console.log('解決方案：');
      console.log('1. 檢查訂單狀態（使用 quick-diagnose.sql）');
      console.log('2. 手動創建聊天室（使用 create-chat-room.js）');
      console.log('3. 或發送第一則訊息觸發創建');
    } else {
      console.log('聊天室列表：');
      console.log('-'.repeat(80));
      
      chatRoomsSnapshot.forEach(doc => {
        const data = doc.data();
        console.log(`聊天室 ID (訂單 ID): ${doc.id}`);
        console.log(`  客戶 Firebase UID: ${data.customerId || 'N/A'}`);
        console.log(`  司機 Firebase UID: ${data.driverId || 'N/A'}`);
        console.log(`  客戶姓名: ${data.customerName || 'N/A'}`);
        console.log(`  司機姓名: ${data.driverName || 'N/A'}`);
        console.log(`  上車地點: ${data.pickupAddress || 'N/A'}`);
        console.log(`  預約時間: ${data.bookingTime ? data.bookingTime.toDate() : 'N/A'}`);
        console.log(`  最後訊息: ${data.lastMessage || 'N/A'}`);
        console.log(`  最後訊息時間: ${data.lastMessageTime ? data.lastMessageTime.toDate() : 'N/A'}`);
        console.log(`  客戶未讀數: ${data.customerUnreadCount || 0}`);
        console.log(`  司機未讀數: ${data.driverUnreadCount || 0}`);
        console.log(`  更新時間: ${data.updatedAt ? data.updatedAt.toDate() : 'N/A'}`);
        console.log('');
      });
    }

    // 檢查索引狀態
    console.log('📊 Firestore 索引檢查');
    console.log('-'.repeat(80));
    console.log('請前往 Firebase Console 確認索引狀態：');
    console.log('https://console.firebase.google.com/project/ride-platform-f1676/firestore/indexes');
    console.log('');
    console.log('需要的索引：');
    console.log('1. chat_rooms: customerId (ASC) + lastMessageTime (DESC)');
    console.log('2. chat_rooms: driverId (ASC) + lastMessageTime (DESC)');
    console.log('');

  } catch (error) {
    console.error('❌ 檢查 Firestore 時發生錯誤:', error);
  }
}

// 執行檢查
checkFirestoreChatRooms()
  .then(() => {
    console.log('='.repeat(80));
    console.log('檢查完成');
    console.log('='.repeat(80));
    process.exit(0);
  })
  .catch(error => {
    console.error('執行失敗:', error);
    process.exit(1);
  });

