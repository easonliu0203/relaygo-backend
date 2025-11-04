/**
 * 診斷司機端「確認接單」按鈕不顯示問題
 * 
 * 檢查：
 * 1. Supabase 中的訂單狀態
 * 2. Firestore 中的訂單狀態
 * 3. 狀態映射是否正確
 */

const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

// Supabase 配置
const supabaseUrl = process.env.SUPABASE_URL || 'https://ygdcqpqfqxqxqxqxqxqx.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'your-service-role-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// Firebase 配置
let db;
try {
  const serviceAccount = require('./serviceAccountKey.json');
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
  }
  db = admin.firestore();
} catch (error) {
  console.log('⚠️  無法載入 Firebase 配置，將跳過 Firestore 檢查');
  console.log('   如需檢查 Firestore，請確保 serviceAccountKey.json 存在\n');
}

async function checkDriverButtonIssue() {
  console.log('========================================');
  console.log('診斷司機端「確認接單」按鈕不顯示問題');
  console.log('========================================\n');

  try {
    // 1. 查詢最近的訂單（Supabase）
    console.log('步驟 1：查詢 Supabase 中最近的訂單...\n');
    const { data: bookings, error } = await supabase
      .from('bookings')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);

    if (error) {
      console.error('❌ 查詢 Supabase 失敗:', error);
      return;
    }

    console.log(`✅ 找到 ${bookings.length} 個訂單\n`);

    // 2. 檢查每個訂單的狀態
    for (const booking of bookings) {
      console.log('----------------------------------------');
      console.log(`訂單 ID: ${booking.id}`);
      console.log(`訂單編號: ${booking.booking_number || 'N/A'}`);
      console.log(`Supabase 狀態: ${booking.status}`);
      console.log(`司機 ID: ${booking.driver_id || '未分配'}`);
      console.log(`創建時間: ${booking.created_at}`);

      // 3. 查詢 Firestore 中的對應訂單
      if (db) {
        try {
          const firestoreDoc = await db.collection('bookings').doc(booking.id).get();

          if (firestoreDoc.exists) {
            const firestoreData = firestoreDoc.data();
            console.log(`Firestore 狀態: ${firestoreData.status}`);

            // 4. 檢查狀態映射是否正確
            const expectedFirestoreStatus = getExpectedFirestoreStatus(booking.status);
            console.log(`預期 Firestore 狀態: ${expectedFirestoreStatus}`);

            if (firestoreData.status !== expectedFirestoreStatus) {
              console.log('⚠️  狀態映射不一致！');
              console.log(`   Supabase: ${booking.status} → 預期 Firestore: ${expectedFirestoreStatus}`);
              console.log(`   實際 Firestore: ${firestoreData.status}`);
            } else {
              console.log('✅ 狀態映射正確');
            }

            // 5. 檢查「確認接單」按鈕顯示條件
            if (booking.status === 'matched' && booking.driver_id) {
              console.log('\n📋 「確認接單」按鈕顯示條件檢查:');
              console.log(`   Supabase 狀態 = 'matched': ✅`);
              console.log(`   已分配司機: ✅`);
              console.log(`   預期 Firestore 狀態: 'awaitingDriver'`);
              console.log(`   實際 Firestore 狀態: '${firestoreData.status}'`);

              if (firestoreData.status === 'awaitingDriver') {
                console.log('   ✅ 按鈕應該顯示');
              } else {
                console.log('   ❌ 按鈕不會顯示（Firestore 狀態不是 awaitingDriver）');
              }
            }
          } else {
            console.log('❌ Firestore 中找不到此訂單');
          }
        } catch (firestoreError) {
          console.error('❌ 查詢 Firestore 失敗:', firestoreError.message);
        }
      } else {
        // 只檢查 Supabase 狀態
        const expectedFirestoreStatus = getExpectedFirestoreStatus(booking.status);
        console.log(`預期 Firestore 狀態: ${expectedFirestoreStatus}`);

        // 檢查「確認接單」按鈕顯示條件
        if (booking.status === 'matched' && booking.driver_id) {
          console.log('\n📋 「確認接單」按鈕顯示條件檢查:');
          console.log(`   Supabase 狀態 = 'matched': ✅`);
          console.log(`   已分配司機: ✅`);
          console.log(`   預期 Firestore 狀態: 'awaitingDriver'`);
          console.log('   ⚠️  無法檢查實際 Firestore 狀態（Firebase 配置未載入）');
        }
      }

      console.log('');
    }

    console.log('========================================');
    console.log('診斷完成');
    console.log('========================================\n');

    // 6. 提供修復建議
    console.log('📝 修復建議:\n');
    console.log('如果發現狀態映射不一致，請執行以下步驟：');
    console.log('1. 檢查 Edge Function 是否已部署最新版本');
    console.log('2. 手動觸發 Firestore 同步（更新訂單的 updated_at 欄位）');
    console.log('3. 或者直接在 Firestore 中手動更新訂單狀態');
    console.log('');
    console.log('SQL 命令（手動觸發同步）：');
    console.log('UPDATE bookings SET updated_at = NOW() WHERE status = \'matched\' AND driver_id IS NOT NULL;');
    console.log('');

  } catch (error) {
    console.error('❌ 診斷過程中發生錯誤:', error);
  }
}

/**
 * 根據 Supabase 狀態獲取預期的 Firestore 狀態
 */
function getExpectedFirestoreStatus(supabaseStatus) {
  const statusMapping = {
    'pending_payment': 'pending',
    'paid_deposit': 'pending',
    'assigned': 'awaitingDriver',
    'matched': 'awaitingDriver',        // ✅ 手動派單 → 待司機確認
    'driver_confirmed': 'matched',      // ✅ 司機確認後 → 已配對
    'driver_departed': 'inProgress',
    'driver_arrived': 'inProgress',
    'trip_started': 'inProgress',
    'trip_ended': 'awaitingBalance',
    'pending_balance': 'awaitingBalance',
    'in_progress': 'inProgress',
    'completed': 'completed',
    'cancelled': 'cancelled',
  };

  return statusMapping[supabaseStatus] || 'pending';
}

// 執行診斷
checkDriverButtonIssue()
  .then(() => {
    console.log('✅ 診斷腳本執行完成');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ 診斷腳本執行失敗:', error);
    process.exit(1);
  });

