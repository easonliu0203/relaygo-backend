/**
 * 檢查聊天室狀態診斷腳本
 * 
 * 功能：
 * 1. 檢查 Supabase bookings 表中的訂單狀態
 * 2. 檢查 Firestore chat_rooms collection 是否有對應的聊天室
 * 3. 檢查用戶 Firebase UID 是否正確
 * 4. 診斷聊天室列表為空的原因
 * 
 * 使用方法：
 * node diagnose-chat-rooms-issue.js
 */

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');

// 初始化 Firebase Admin
const serviceAccount = require('./ride-platform-f1676-firebase-adminsdk-fbsvc-8fad5fdb15.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const firestore = admin.firestore();

// 初始化 Supabase
const supabaseUrl = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'YOUR_SERVICE_ROLE_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function checkChatRoomStatus() {
  console.log('='.repeat(80));
  console.log('聊天室狀態診斷');
  console.log('='.repeat(80));
  console.log('');

  try {
    // 1. 檢查 Supabase bookings 表中的訂單
    console.log('📋 步驟 1: 檢查 Supabase bookings 表中的訂單');
    console.log('-'.repeat(80));
    
    const { data: bookings, error: bookingsError } = await supabase
      .from('bookings')
      .select(`
        id,
        customer_id,
        driver_id,
        status,
        pickup_time,
        created_at,
        updated_at
      `)
      .not('driver_id', 'is', null)
      .order('created_at', { ascending: false })
      .limit(10);

    if (bookingsError) {
      console.error('❌ 查詢訂單失敗:', bookingsError);
      return;
    }

    console.log(`✅ 找到 ${bookings.length} 筆已配對的訂單`);
    console.log('');

    if (bookings.length === 0) {
      console.log('⚠️ 沒有已配對的訂單（driver_id 不為 null）');
      console.log('');
      console.log('建議：創建一個新訂單並分配司機');
      return;
    }

    // 顯示訂單詳情
    for (const booking of bookings) {
      console.log(`訂單 ID: ${booking.id}`);
      console.log(`  狀態: ${booking.status}`);
      console.log(`  客戶 ID: ${booking.customer_id}`);
      console.log(`  司機 ID: ${booking.driver_id}`);
      console.log(`  預約時間: ${booking.pickup_time}`);
      console.log(`  創建時間: ${booking.created_at}`);
      console.log('');
    }

    // 2. 檢查用戶的 Firebase UID
    console.log('👤 步驟 2: 檢查用戶的 Firebase UID');
    console.log('-'.repeat(80));

    const userIds = new Set();
    bookings.forEach(booking => {
      userIds.add(booking.customer_id);
      if (booking.driver_id) {
        userIds.add(booking.driver_id);
      }
    });

    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('id, firebase_uid, full_name, role')
      .in('id', Array.from(userIds));

    if (usersError) {
      console.error('❌ 查詢用戶失敗:', usersError);
      return;
    }

    console.log(`✅ 找到 ${users.length} 個用戶`);
    console.log('');

    const userMap = new Map();
    for (const user of users) {
      userMap.set(user.id, user);
      console.log(`用戶 ID: ${user.id}`);
      console.log(`  Firebase UID: ${user.firebase_uid}`);
      console.log(`  姓名: ${user.full_name}`);
      console.log(`  角色: ${user.role}`);
      console.log('');
    }

    // 3. 檢查 Firestore chat_rooms collection
    console.log('💬 步驟 3: 檢查 Firestore chat_rooms collection');
    console.log('-'.repeat(80));

    const chatRoomsSnapshot = await firestore.collection('chat_rooms').get();
    console.log(`✅ Firestore 中有 ${chatRoomsSnapshot.size} 個聊天室`);
    console.log('');

    if (chatRoomsSnapshot.empty) {
      console.log('⚠️ Firestore 中沒有聊天室');
      console.log('');
      console.log('可能原因：');
      console.log('1. 聊天室只在訂單狀態為 "driver_confirmed" 時創建');
      console.log('2. Edge Function 沒有正確同步聊天室到 Firestore');
      console.log('3. 訂單狀態還沒有達到 "driver_confirmed"');
      console.log('');
    } else {
      chatRoomsSnapshot.forEach(doc => {
        const data = doc.data();
        console.log(`聊天室 ID: ${doc.id}`);
        console.log(`  客戶 Firebase UID: ${data.customerId}`);
        console.log(`  司機 Firebase UID: ${data.driverId}`);
        console.log(`  客戶姓名: ${data.customerName || 'N/A'}`);
        console.log(`  司機姓名: ${data.driverName || 'N/A'}`);
        console.log(`  最後訊息: ${data.lastMessage || 'N/A'}`);
        console.log(`  最後訊息時間: ${data.lastMessageTime ? data.lastMessageTime.toDate() : 'N/A'}`);
        console.log(`  客戶未讀數: ${data.customerUnreadCount || 0}`);
        console.log(`  司機未讀數: ${data.driverUnreadCount || 0}`);
        console.log('');
      });
    }

    // 4. 診斷聊天室列表為空的原因
    console.log('🔍 步驟 4: 診斷聊天室列表為空的原因');
    console.log('-'.repeat(80));

    for (const booking of bookings) {
      const customer = userMap.get(booking.customer_id);
      const driver = userMap.get(booking.driver_id);

      console.log(`訂單 ${booking.id}:`);
      console.log(`  狀態: ${booking.status}`);
      
      if (!customer) {
        console.log(`  ❌ 找不到客戶資料 (ID: ${booking.customer_id})`);
      } else if (!customer.firebase_uid) {
        console.log(`  ❌ 客戶沒有 Firebase UID (ID: ${booking.customer_id})`);
      } else {
        console.log(`  ✅ 客戶 Firebase UID: ${customer.firebase_uid}`);
      }

      if (!driver) {
        console.log(`  ❌ 找不到司機資料 (ID: ${booking.driver_id})`);
      } else if (!driver.firebase_uid) {
        console.log(`  ❌ 司機沒有 Firebase UID (ID: ${booking.driver_id})`);
      } else {
        console.log(`  ✅ 司機 Firebase UID: ${driver.firebase_uid}`);
      }

      // 檢查 Firestore 中是否有對應的聊天室
      const chatRoomDoc = await firestore.collection('chat_rooms').doc(booking.id).get();
      
      if (!chatRoomDoc.exists) {
        console.log(`  ❌ Firestore 中沒有對應的聊天室`);
        console.log(`  原因: 訂單狀態為 "${booking.status}"，聊天室只在狀態為 "driver_confirmed" 時創建`);
      } else {
        const chatRoomData = chatRoomDoc.data();
        console.log(`  ✅ Firestore 中有對應的聊天室`);
        console.log(`     客戶 UID: ${chatRoomData.customerId}`);
        console.log(`     司機 UID: ${chatRoomData.driverId}`);
        
        // 檢查 UID 是否匹配
        if (customer && chatRoomData.customerId !== customer.firebase_uid) {
          console.log(`     ⚠️ 客戶 UID 不匹配！`);
          console.log(`        Firestore: ${chatRoomData.customerId}`);
          console.log(`        Supabase: ${customer.firebase_uid}`);
        }
        
        if (driver && chatRoomData.driverId !== driver.firebase_uid) {
          console.log(`     ⚠️ 司機 UID 不匹配！`);
          console.log(`        Firestore: ${chatRoomData.driverId}`);
          console.log(`        Supabase: ${driver.firebase_uid}`);
        }
      }
      
      console.log('');
    }

    // 5. 總結和建議
    console.log('📝 總結和建議');
    console.log('-'.repeat(80));
    
    if (chatRoomsSnapshot.empty) {
      console.log('❌ 問題：Firestore 中沒有聊天室');
      console.log('');
      console.log('解決方案：');
      console.log('1. 確認訂單狀態是否為 "driver_confirmed"');
      console.log('2. 如果訂單狀態不是 "driver_confirmed"，需要更新訂單狀態');
      console.log('3. 或者手動觸發聊天室創建（發送第一則訊息）');
      console.log('');
      console.log('訂單狀態流程：');
      console.log('  pending → paid_deposit → assigned → driver_confirmed → ...');
      console.log('');
      console.log('聊天室創建時機：');
      console.log('  當訂單狀態變更為 "driver_confirmed" 時，系統會自動創建聊天室');
    } else {
      console.log('✅ Firestore 中有聊天室');
      console.log('');
      console.log('如果 APP 中仍然看不到聊天室，請檢查：');
      console.log('1. APP 登入的用戶 UID 是否與 Firestore 中的 customerId 或 driverId 一致');
      console.log('2. Firestore 索引是否已經創建完成（檢查 Firebase Console）');
      console.log('3. Firestore Security Rules 是否正確');
      console.log('4. APP 中的查詢邏輯是否正確');
    }

  } catch (error) {
    console.error('❌ 診斷過程中發生錯誤:', error);
  }
}

// 執行診斷
checkChatRoomStatus()
  .then(() => {
    console.log('');
    console.log('='.repeat(80));
    console.log('診斷完成');
    console.log('='.repeat(80));
    process.exit(0);
  })
  .catch(error => {
    console.error('執行失敗:', error);
    process.exit(1);
  });

