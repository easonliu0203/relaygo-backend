/**
 * 診斷聊天室問題
 * 
 * 問題：客戶端看不到聊天室
 * 原因：Firestore 中的 customerId 是 Supabase UUID，但應該是 Firebase UID
 * 
 * 此腳本會：
 * 1. 列出所有聊天室
 * 2. 檢查 customerId 和 driverId 是否為 Firebase UID
 * 3. 提供修復建議
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

async function diagnoseChatRooms() {
  console.log('========================================');
  console.log('診斷聊天室問題');
  console.log('========================================\n');

  try {
    // 1. 列出所有聊天室
    const chatRoomsSnapshot = await firestore.collection('chat_rooms').get();
    
    console.log(`找到 ${chatRoomsSnapshot.size} 個聊天室\n`);

    if (chatRoomsSnapshot.empty) {
      console.log('⚠️  沒有聊天室');
      return;
    }

    // 2. 檢查每個聊天室
    for (const doc of chatRoomsSnapshot.docs) {
      const data = doc.data();
      console.log('----------------------------------------');
      console.log(`聊天室 ID: ${doc.id}`);
      console.log(`Customer ID: ${data.customerId}`);
      console.log(`Driver ID: ${data.driverId}`);
      console.log(`Customer Name: ${data.customerName}`);
      console.log(`Driver Name: ${data.driverName}`);
      console.log(`Pickup Address: ${data.pickupAddress}`);
      console.log(`Created At: ${data.createdAt?.toDate()}`);

      // 檢查 customerId 是否為 Firebase UID
      const isCustomerIdFirebaseUid = await checkIfFirebaseUid(data.customerId);
      const isDriverIdFirebaseUid = await checkIfFirebaseUid(data.driverId);

      console.log(`\n檢查結果:`);
      console.log(`  Customer ID 是 Firebase UID: ${isCustomerIdFirebaseUid ? '✅' : '❌'}`);
      console.log(`  Driver ID 是 Firebase UID: ${isDriverIdFirebaseUid ? '✅' : '❌'}`);

      // 如果 customerId 不是 Firebase UID，查詢對應的 Firebase UID
      if (!isCustomerIdFirebaseUid) {
        const { data: customer } = await supabase
          .from('users')
          .select('firebase_uid, email')
          .eq('id', data.customerId)
          .single();

        if (customer) {
          console.log(`\n修復建議:`);
          console.log(`  將 customerId 從 ${data.customerId} 改為 ${customer.firebase_uid}`);
          console.log(`  客戶 Email: ${customer.email}`);
        }
      }

      // 如果 driverId 不是 Firebase UID，查詢對應的 Firebase UID
      if (!isDriverIdFirebaseUid) {
        const { data: driver } = await supabase
          .from('users')
          .select('firebase_uid, email')
          .eq('id', data.driverId)
          .single();

        if (driver) {
          console.log(`\n修復建議:`);
          console.log(`  將 driverId 從 ${data.driverId} 改為 ${driver.firebase_uid}`);
          console.log(`  司機 Email: ${driver.email}`);
        }
      }

      console.log('');
    }

    console.log('========================================');
    console.log('診斷完成');
    console.log('========================================');

  } catch (error) {
    console.error('❌ 診斷失敗:', error);
  }
}

/**
 * 檢查 ID 是否為 Firebase UID
 * Firebase UID 通常是 28 個字符的字母數字字符串
 * Supabase UUID 是 36 個字符的 UUID 格式（包含連字符）
 */
function checkIfFirebaseUid(id) {
  // Firebase UID 通常是 28 個字符，沒有連字符
  // Supabase UUID 是 36 個字符，格式為 xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return !uuidPattern.test(id);
}

// 執行診斷
diagnoseChatRooms()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ 執行失敗:', error);
    process.exit(1);
  });

