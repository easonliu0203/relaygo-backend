/**
 * Firestore 缺失 Timestamp 檢查腳本
 * 
 * 功能: 檢查 Firestore 中有多少訂單缺少必填的時間戳欄位
 * 
 * 使用方法:
 * 1. 安裝依賴: npm install firebase-admin
 * 2. 設置環境變數: export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
 * 3. 運行腳本: node firebase/check-missing-timestamps.js
 */

const admin = require('firebase-admin');

// 初始化 Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// 需要檢查的集合
const COLLECTIONS = ['orders_rt', 'bookings'];

// 需要檢查的時間戳欄位
const REQUIRED_TIMESTAMP_FIELDS = ['bookingTime', 'createdAt'];
const OPTIONAL_TIMESTAMP_FIELDS = ['matchedAt', 'completedAt'];

/**
 * 檢查單個文檔
 */
async function checkDocument(collectionName, doc) {
  const data = doc.data();
  const missingRequired = [];
  const info = {
    id: doc.id,
    status: data.status || 'N/A',
    pickupAddress: data.pickupAddress || 'N/A',
    createdAt: data.createdAt ? (data.createdAt.toDate ? data.createdAt.toDate().toISOString() : data.createdAt) : 'NULL',
    bookingTime: data.bookingTime ? (data.bookingTime.toDate ? data.bookingTime.toDate().toISOString() : data.bookingTime) : 'NULL',
  };
  
  // 檢查必填的時間戳欄位
  for (const field of REQUIRED_TIMESTAMP_FIELDS) {
    const value = data[field];
    
    if (value === null || value === undefined) {
      missingRequired.push(field);
    }
  }
  
  return { info, missingRequired };
}

/**
 * 檢查整個集合
 */
async function checkCollection(collectionName) {
  console.log(`\n========================================`);
  console.log(`檢查集合: ${collectionName}`);
  console.log(`========================================\n`);
  
  const collectionRef = db.collection(collectionName);
  const snapshot = await collectionRef.get();
  
  console.log(`📊 總文檔數: ${snapshot.size}\n`);
  
  if (snapshot.size === 0) {
    console.log(`⚠️  集合為空\n`);
    return {
      total: 0,
      missingTimestamps: [],
      stats: {
        bookingTime: { missing: 0, present: 0 },
        createdAt: { missing: 0, present: 0 },
      },
    };
  }
  
  const missingTimestamps = [];
  const stats = {
    bookingTime: { missing: 0, present: 0 },
    createdAt: { missing: 0, present: 0 },
  };
  
  // 檢查每個文檔
  for (const doc of snapshot.docs) {
    const { info, missingRequired } = await checkDocument(collectionName, doc);
    
    // 更新統計
    for (const field of REQUIRED_TIMESTAMP_FIELDS) {
      if (missingRequired.includes(field)) {
        stats[field].missing++;
      } else {
        stats[field].present++;
      }
    }
    
    // 收集缺失時間戳的文檔
    if (missingRequired.length > 0) {
      missingTimestamps.push({
        ...info,
        missingFields: missingRequired,
      });
    }
  }
  
  // 顯示統計結果
  console.log(`📊 時間戳欄位統計:\n`);
  
  for (const field of REQUIRED_TIMESTAMP_FIELDS) {
    const missing = stats[field].missing;
    const present = stats[field].present;
    const total = missing + present;
    const missingPercentage = total > 0 ? ((missing / total) * 100).toFixed(1) : 0;
    
    console.log(`${field}:`);
    console.log(`  ✅ 有值: ${present}`);
    console.log(`  ❌ 缺少: ${missing} (${missingPercentage}%)`);
    console.log(``);
  }
  
  // 顯示缺失時間戳的文檔
  if (missingTimestamps.length > 0) {
    console.log(`⚠️  發現 ${missingTimestamps.length} 個訂單缺少必填的時間戳:\n`);
    
    // 只顯示前 10 個
    const samplesToShow = Math.min(10, missingTimestamps.length);
    for (let i = 0; i < samplesToShow; i++) {
      const doc = missingTimestamps[i];
      console.log(`${i + 1}. ${doc.id}`);
      console.log(`   上車地點: ${doc.pickupAddress}`);
      console.log(`   狀態: ${doc.status}`);
      console.log(`   缺少欄位: ${doc.missingFields.join(', ')}`);
      console.log(`   createdAt: ${doc.createdAt}`);
      console.log(`   bookingTime: ${doc.bookingTime}`);
      console.log(``);
    }
    
    if (missingTimestamps.length > 10) {
      console.log(`   ... 還有 ${missingTimestamps.length - 10} 個訂單缺少時間戳\n`);
    }
  } else {
    console.log(`✅ 所有訂單都有完整的必填時間戳!\n`);
  }
  
  console.log(`========================================\n`);
  
  return {
    total: snapshot.size,
    missingTimestamps: missingTimestamps,
    stats: stats,
  };
}

/**
 * 主函數
 */
async function main() {
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  Firestore 缺失 Timestamp 檢查腳本     ║`);
  console.log(`╚════════════════════════════════════════╝\n`);
  
  console.log(`📋 檢查計劃:`);
  console.log(`  集合: ${COLLECTIONS.join(', ')}`);
  console.log(`  必填欄位: ${REQUIRED_TIMESTAMP_FIELDS.join(', ')}`);
  console.log(`  可選欄位: ${OPTIONAL_TIMESTAMP_FIELDS.join(', ')}\n`);
  
  const allResults = {};
  
  // 檢查每個集合
  for (const collectionName of COLLECTIONS) {
    const result = await checkCollection(collectionName);
    allResults[collectionName] = result;
  }
  
  // 最終總結
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  檢查完成總結                          ║`);
  console.log(`╚════════════════════════════════════════╝\n`);
  
  let totalDocs = 0;
  let totalMissing = 0;
  
  for (const collectionName of COLLECTIONS) {
    const result = allResults[collectionName];
    totalDocs += result.total;
    totalMissing += result.missingTimestamps.length;
    
    console.log(`${collectionName}:`);
    console.log(`  總文檔數: ${result.total}`);
    console.log(`  缺少時間戳的訂單: ${result.missingTimestamps.length}`);
    
    if (result.total > 0) {
      const percentage = ((result.missingTimestamps.length / result.total) * 100).toFixed(1);
      console.log(`  缺失比例: ${percentage}%`);
    }
    
    console.log(``);
  }
  
  console.log(`總計:`);
  console.log(`  總文檔數: ${totalDocs}`);
  console.log(`  缺少時間戳的訂單: ${totalMissing}`);
  
  if (totalDocs > 0) {
    const percentage = ((totalMissing / totalDocs) * 100).toFixed(1);
    console.log(`  缺失比例: ${percentage}%`);
  }
  
  console.log(``);
  
  if (totalMissing === 0) {
    console.log(`🎉 太好了! 所有訂單都有完整的必填時間戳`);
  } else {
    console.log(`⚠️  發現問題! 有 ${totalMissing} 個訂單缺少必填時間戳`);
    console.log(`\n建議:`);
    console.log(`  1. Flutter 代碼已修改為使用 createdAt 作為 bookingTime 的後備值`);
    console.log(`  2. 檢查 Edge Function 的 bookingTime 組合邏輯`);
    console.log(`  3. 確認 Supabase 中的 start_date 和 start_time 欄位是否正確`);
    console.log(`  4. 考慮修復 Edge Function 確保未來不會出現此問題`);
  }
  
  console.log(``);
}

// 執行主函數
main()
  .then(() => {
    console.log(`✅ 腳本執行完成`);
    process.exit(0);
  })
  .catch(error => {
    console.error(`❌ 腳本執行失敗:`, error);
    process.exit(1);
  });

