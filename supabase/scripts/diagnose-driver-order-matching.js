/**
 * 司機端訂單配對問題診斷腳本
 * 
 * 用途：診斷司機端訂單配對問題
 * 
 * 執行方式：
 *   node supabase/scripts/diagnose-driver-order-matching.js
 */

const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

// Supabase 配置
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://rvqxqxqxqxqxqxqx.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// Firebase 配置
const serviceAccount = require('../../ride-platform-f1676-firebase-adminsdk-fbsvc-8fad5fdb15.json');

// 測試司機資訊
const TEST_DRIVER_EMAIL = 'driver.test@relaygo.com';
const TEST_DRIVER_FIREBASE_UID = 'CMfTxhJFlUVDkosJPyUoJvKjCQk1'; // 從終端機日誌獲取

console.log('========================================');
console.log('司機端訂單配對問題診斷');
console.log('========================================');
console.log('');

async function main() {
  try {
    // 初始化 Supabase
    console.log('[1/6] 初始化 Supabase...');
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    console.log('✅ Supabase 初始化成功');
    console.log('');

    // 初始化 Firebase
    console.log('[2/6] 初始化 Firebase...');
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    const firestore = admin.firestore();
    const auth = admin.auth();
    console.log('✅ Firebase 初始化成功');
    console.log('');

    // 檢查測試司機的 Firebase UID
    console.log('[3/6] 檢查測試司機的 Firebase UID...');
    console.log(`測試司機 Email: ${TEST_DRIVER_EMAIL}`);
    console.log(`預期 Firebase UID: ${TEST_DRIVER_FIREBASE_UID}`);
    
    try {
      const userRecord = await auth.getUserByEmail(TEST_DRIVER_EMAIL);
      console.log(`實際 Firebase UID: ${userRecord.uid}`);
      
      if (userRecord.uid === TEST_DRIVER_FIREBASE_UID) {
        console.log('✅ Firebase UID 匹配');
      } else {
        console.log('❌ Firebase UID 不匹配！');
        console.log(`  預期: ${TEST_DRIVER_FIREBASE_UID}`);
        console.log(`  實際: ${userRecord.uid}`);
      }
    } catch (error) {
      console.log(`❌ 找不到測試司機: ${error.message}`);
    }
    console.log('');

    // 檢查 Supabase 中最近配對的訂單
    console.log('[4/6] 檢查 Supabase 中最近配對的訂單...');
    const { data: bookings, error: bookingsError } = await supabase
      .from('bookings')
      .select('*')
      .eq('driver_id', TEST_DRIVER_FIREBASE_UID)
      .order('created_at', { ascending: false })
      .limit(5);

    if (bookingsError) {
      console.log(`❌ 查詢失敗: ${bookingsError.message}`);
    } else if (!bookings || bookings.length === 0) {
      console.log('⚠️  沒有找到配對給該司機的訂單');
      console.log('');
      console.log('可能原因：');
      console.log('  1. 公司端配對時選擇了錯誤的司機');
      console.log('  2. driver_id 欄位沒有正確設置');
      console.log('  3. 訂單已被刪除或取消');
    } else {
      console.log(`✅ 找到 ${bookings.length} 個配對的訂單`);
      console.log('');
      bookings.forEach((booking, index) => {
        console.log(`訂單 ${index + 1}:`);
        console.log(`  ID: ${booking.id}`);
        console.log(`  狀態: ${booking.status}`);
        console.log(`  司機 ID: ${booking.driver_id}`);
        console.log(`  客戶 ID: ${booking.customer_id}`);
        console.log(`  建立時間: ${booking.created_at}`);
        console.log(`  更新時間: ${booking.updated_at}`);
        console.log('');
      });
    }

    // 檢查 Firestore 中的訂單資料
    console.log('[5/6] 檢查 Firestore 中的訂單資料...');
    const ordersSnapshot = await firestore
      .collection('orders_rt')
      .where('driverId', '==', TEST_DRIVER_FIREBASE_UID)
      .orderBy('createdAt', 'desc')
      .limit(5)
      .get();

    if (ordersSnapshot.empty) {
      console.log('⚠️  Firestore 中沒有找到該司機的訂單');
      console.log('');
      console.log('可能原因：');
      console.log('  1. Supabase → Firestore 同步失敗');
      console.log('  2. Edge Function 沒有正確執行');
      console.log('  3. driverId 欄位映射錯誤');
      console.log('  4. 同步延遲（最多 30 秒）');
    } else {
      console.log(`✅ 找到 ${ordersSnapshot.size} 個訂單`);
      console.log('');
      ordersSnapshot.forEach((doc, index) => {
        const data = doc.data();
        console.log(`訂單 ${index + 1}:`);
        console.log(`  ID: ${doc.id}`);
        console.log(`  狀態: ${data.status}`);
        console.log(`  司機 ID: ${data.driverId}`);
        console.log(`  客戶 ID: ${data.customerId}`);
        console.log(`  建立時間: ${data.createdAt?.toDate()}`);
        console.log('');
      });
    }

    // 檢查索引狀態
    console.log('[6/6] 檢查 Firestore 索引狀態...');
    console.log('請訪問 Firebase 控制台確認索引狀態：');
    console.log('https://console.firebase.google.com/project/ride-platform-f1676/firestore/indexes');
    console.log('');
    console.log('需要的索引：');
    console.log('  1. orders_rt: driverId (ASC) + createdAt (DESC)');
    console.log('  2. orders_rt: driverId (ASC) + status (ASC) + createdAt (DESC)');
    console.log('');

    // 總結
    console.log('========================================');
    console.log('診斷總結');
    console.log('========================================');
    console.log('');
    
    if (bookings && bookings.length > 0 && !ordersSnapshot.empty) {
      console.log('✅ Supabase 和 Firestore 都有訂單資料');
      console.log('✅ 資料同步正常');
      console.log('');
      console.log('如果司機端仍看不到訂單，可能原因：');
      console.log('  1. 索引尚未建立完成（等待 2-5 分鐘）');
      console.log('  2. 應用未重新啟動');
      console.log('  3. 權限規則未生效');
    } else if (bookings && bookings.length > 0 && ordersSnapshot.empty) {
      console.log('⚠️  Supabase 有訂單，但 Firestore 沒有');
      console.log('❌ 資料同步失敗');
      console.log('');
      console.log('建議檢查：');
      console.log('  1. Edge Function 執行日誌');
      console.log('  2. Supabase Trigger 是否正常');
      console.log('  3. Outbox 表中是否有待處理的事件');
    } else if (!bookings || bookings.length === 0) {
      console.log('⚠️  Supabase 中沒有配對的訂單');
      console.log('');
      console.log('建議操作：');
      console.log('  1. 在公司端重新配對訂單');
      console.log('  2. 確認選擇了正確的司機');
      console.log('  3. 檢查公司端的配對 API');
    }

  } catch (error) {
    console.error('❌ 診斷過程中發生錯誤:', error);
    console.error(error.stack);
  }
}

main();

