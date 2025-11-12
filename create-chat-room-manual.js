/**
 * 手動創建聊天室到 Firestore
 * 
 * 使用方法：
 * node create-chat-room-manual.js <booking_id> <customer_firebase_uid> <driver_firebase_uid> <customer_name> <driver_name> <pickup_address>
 * 
 * 範例：
 * node create-chat-room-manual.js "booking-123" "cust-uid-123" "driver-uid-456" "張三" "李四" "台北車站"
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

async function createChatRoom(bookingId, customerId, driverId, customerName, driverName, pickupAddress) {
  console.log('='.repeat(80));
  console.log('手動創建聊天室');
  console.log('='.repeat(80));
  console.log('');

  console.log('參數：');
  console.log(`  訂單 ID: ${bookingId}`);
  console.log(`  客戶 Firebase UID: ${customerId}`);
  console.log(`  司機 Firebase UID: ${driverId}`);
  console.log(`  客戶姓名: ${customerName}`);
  console.log(`  司機姓名: ${driverName}`);
  console.log(`  上車地點: ${pickupAddress}`);
  console.log('');

  try {
    // 檢查聊天室是否已存在
    const chatRoomDoc = await firestore.collection('chat_rooms').doc(bookingId).get();
    
    if (chatRoomDoc.exists) {
      console.log('⚠️ 聊天室已存在');
      console.log('');
      const data = chatRoomDoc.data();
      console.log('現有聊天室資料：');
      console.log(`  客戶 UID: ${data.customerId}`);
      console.log(`  司機 UID: ${data.driverId}`);
      console.log(`  客戶姓名: ${data.customerName}`);
      console.log(`  司機姓名: ${data.driverName}`);
      console.log('');
      console.log('如果需要更新，請先刪除現有聊天室');
      return;
    }

    // 創建聊天室
    const chatRoomData = {
      bookingId: bookingId,
      customerId: customerId,
      driverId: driverId,
      customerName: customerName,
      driverName: driverName,
      pickupAddress: pickupAddress,
      bookingTime: admin.firestore.Timestamp.now(),
      lastMessage: null,
      lastMessageTime: null,
      customerUnreadCount: 0,
      driverUnreadCount: 0,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    };

    await firestore.collection('chat_rooms').doc(bookingId).set(chatRoomData);

    console.log('✅ 聊天室創建成功！');
    console.log('');
    console.log('聊天室資料：');
    console.log(JSON.stringify(chatRoomData, null, 2));
    console.log('');
    console.log('下一步：');
    console.log('1. 在客戶端 APP 中重新載入聊天室列表');
    console.log('2. 在司機端 APP 中重新載入聊天室列表');
    console.log('3. 嘗試發送訊息測試');

  } catch (error) {
    console.error('❌ 創建聊天室失敗:', error);
  }
}

// 從命令列參數獲取資訊
const args = process.argv.slice(2);

if (args.length < 6) {
  console.log('使用方法：');
  console.log('node create-chat-room-manual.js <booking_id> <customer_firebase_uid> <driver_firebase_uid> <customer_name> <driver_name> <pickup_address>');
  console.log('');
  console.log('範例：');
  console.log('node create-chat-room-manual.js "booking-123" "cust-uid-123" "driver-uid-456" "張三" "李四" "台北車站"');
  console.log('');
  console.log('提示：');
  console.log('1. 先執行 quick-diagnose.sql 查詢訂單資訊');
  console.log('2. 從查詢結果中獲取 booking_id, customer_firebase_uid, driver_firebase_uid 等資訊');
  console.log('3. 然後執行此腳本創建聊天室');
  process.exit(1);
}

const [bookingId, customerId, driverId, customerName, driverName, pickupAddress] = args;

// 執行創建
createChatRoom(bookingId, customerId, driverId, customerName, driverName, pickupAddress)
  .then(() => {
    console.log('');
    console.log('='.repeat(80));
    console.log('完成');
    console.log('='.repeat(80));
    process.exit(0);
  })
  .catch(error => {
    console.error('執行失敗:', error);
    process.exit(1);
  });

