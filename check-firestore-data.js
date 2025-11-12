/**
 * 檢查 Firestore 資料腳本
 * 
 * 用途：檢查 Firestore 中的訂單資料和司機資訊
 * 
 * 執行方式：
 *   node check-firestore-data.js
 */

const admin = require('firebase-admin');

// Firebase 配置
const serviceAccount = require('./ride-platform-f1676-firebase-adminsdk-fbsvc-8fad5fdb15.json');

// 測試司機資訊
const TEST_DRIVER_EMAIL = 'driver.test@relaygo.com';
const TEST_DRIVER_FIREBASE_UID = 'CMfTxhJFlUVDkosJPyUoJvKjCQk1';

console.log('========================================');
console.log('Firestore 資料檢查');
console.log('========================================');
console.log('');

async function main() {
  try {
    // 初始化 Firebase
    console.log('[1/4] 初始化 Firebase...');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    const firestore = admin.firestore();
    const auth = admin.auth();
    console.log('✅ Firebase 初始化成功');
    console.log('');

    // 檢查測試司機
    console.log('[2/4] 檢查測試司機...');
    console.log(`Email: ${TEST_DRIVER_EMAIL}`);
    console.log(`Firebase UID: ${TEST_DRIVER_FIREBASE_UID}`);
    
    try {
      const userRecord = await auth.getUserByEmail(TEST_DRIVER_EMAIL);
      console.log(`✅ 找到用戶: ${userRecord.uid}`);
      console.log(`  Email: ${userRecord.email}`);
      console.log(`  Email 已驗證: ${userRecord.emailVerified}`);
      console.log(`  建立時間: ${userRecord.metadata.creationTime}`);
    } catch (error) {
      console.log(`❌ 找不到用戶: ${error.message}`);
    }
    console.log('');

    // 檢查 orders_rt 集合中的所有訂單
    console.log('[3/4] 檢查 orders_rt 集合中的所有訂單...');
    const allOrdersSnapshot = await firestore
      .collection('orders_rt')
      .limit(10)
      .get();

    console.log(`總共有 ${allOrdersSnapshot.size} 個訂單`);
    console.log('');

    if (!allOrdersSnapshot.empty) {
      allOrdersSnapshot.forEach((doc, index) => {
        const data = doc.data();
        console.log(`訂單 ${index + 1}:`);
        console.log(`  ID: ${doc.id}`);
        console.log(`  狀態: ${data.status}`);
        console.log(`  司機 ID: ${data.driverId || '(未配對)'}`);
        console.log(`  客戶 ID: ${data.customerId}`);
        console.log(`  建立時間: ${data.createdAt?.toDate()}`);
        console.log('');
      });
    }

    // 檢查該司機的訂單
    console.log('[4/4] 檢查該司機的訂單...');
    const driverOrdersSnapshot = await firestore
      .collection('orders_rt')
      .where('driverId', '==', TEST_DRIVER_FIREBASE_UID)
      .get();

    if (driverOrdersSnapshot.empty) {
      console.log('⚠️  沒有找到該司機的訂單');
      console.log('');
      console.log('可能原因：');
      console.log('  1. 公司端配對時選擇了錯誤的司機');
      console.log('  2. Supabase → Firestore 同步失敗');
      console.log('  3. driverId 欄位映射錯誤');
      console.log('  4. 訂單已被刪除或取消');
    } else {
      console.log(`✅ 找到 ${driverOrdersSnapshot.size} 個訂單`);
      console.log('');
      driverOrdersSnapshot.forEach((doc, index) => {
        const data = doc.data();
        console.log(`訂單 ${index + 1}:`);
        console.log(`  ID: ${doc.id}`);
        console.log(`  狀態: ${data.status}`);
        console.log(`  司機 ID: ${data.driverId}`);
        console.log(`  客戶 ID: ${data.customerId}`);
        console.log(`  建立時間: ${data.createdAt?.toDate()}`);
        console.log(`  上車地點: ${data.pickupAddress}`);
        console.log(`  目的地: ${data.dropoffAddress}`);
        console.log('');
      });
    }

    console.log('========================================');
    console.log('檢查完成');
    console.log('========================================');

  } catch (error) {
    console.error('❌ 檢查過程中發生錯誤:', error);
    console.error(error.stack);
  }
}

main();

