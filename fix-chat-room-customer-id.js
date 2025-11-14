/**
 * 修復聊天室的 customerId
 * 
 * 將 Supabase UUID 改為 Firebase UID
 */

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// 初始化 Firebase Admin SDK
const serviceAccount = {
  projectId: process.env.FIREBASE_PROJECT_ID,
  privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
};

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: process.env.FIREBASE_PROJECT_ID,
});

const firestore = admin.firestore();

// 初始化 Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function fixChatRoomCustomerId(chatRoomId) {
  console.log('========================================');
  console.log('修復聊天室 customerId');
  console.log('========================================\n');

  try {
    // 1. 獲取聊天室資料
    const chatRoomRef = firestore.collection('chat_rooms').doc(chatRoomId);
    const chatRoomDoc = await chatRoomRef.get();

    if (!chatRoomDoc.exists) {
      console.log(`❌ 聊天室不存在: ${chatRoomId}`);
      return;
    }

    const data = chatRoomDoc.data();
    console.log(`聊天室 ID: ${chatRoomId}`);
    console.log(`當前 Customer ID: ${data.customerId}`);
    console.log(`當前 Driver ID: ${data.driverId}`);

    // 2. 檢查 customerId 是否為 UUID
    const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isCustomerIdUuid = uuidPattern.test(data.customerId);

    if (!isCustomerIdUuid) {
      console.log('\n✅ Customer ID 已經是 Firebase UID，無需修復');
      return;
    }

    // 3. 查詢對應的 Firebase UID
    const { data: customer, error } = await supabase
      .from('users')
      .select('firebase_uid, email')
      .eq('id', data.customerId)
      .single();

    if (error || !customer) {
      console.log(`\n❌ 無法查詢客戶資訊: ${error?.message}`);
      return;
    }

    console.log(`\n客戶 Email: ${customer.email}`);
    console.log(`Firebase UID: ${customer.firebase_uid}`);

    // 4. 更新聊天室
    console.log(`\n開始更新聊天室...`);
    await chatRoomRef.update({
      customerId: customer.firebase_uid,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`✅ 聊天室已更新`);
    console.log(`   舊 Customer ID: ${data.customerId}`);
    console.log(`   新 Customer ID: ${customer.firebase_uid}`);

    console.log('\n========================================');
    console.log('修復完成');
    console.log('========================================');

  } catch (error) {
    console.error('❌ 修復失敗:', error);
  }
}

// 從命令行參數獲取聊天室 ID
const chatRoomId = process.argv[2];

if (!chatRoomId) {
  console.log('用法: node fix-chat-room-customer-id.js <chatRoomId>');
  console.log('例如: node fix-chat-room-customer-id.js 3af3509e-3c5b-4367-aa54-a3b23703b28e');
  process.exit(1);
}

// 執行修復
fixChatRoomCustomerId(chatRoomId)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ 執行失敗:', error);
    process.exit(1);
  });

