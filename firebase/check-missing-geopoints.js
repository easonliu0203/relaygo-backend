/**
 * Firestore 缺失 GeoPoint 檢查腳本
 * 
 * 功能: 檢查 Firestore 中有多少訂單缺少地理位置座標
 * 
 * 使用方法:
 * 1. 安裝依賴: npm install firebase-admin
 * 2. 設置環境變數: export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
 * 3. 運行腳本: node firebase/check-missing-geopoints.js
 */

const admin = require('firebase-admin');

// 初始化 Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// 需要檢查的集合
const COLLECTIONS = ['orders_rt', 'bookings'];

// 需要檢查的 GeoPoint 欄位
const GEOPOINT_FIELDS = ['pickupLocation', 'dropoffLocation'];

/**
 * 檢查單個文檔
 */
async function checkDocument(collectionName, doc) {
  const data = doc.data();
  const missingFields = [];
  const info = {
    id: doc.id,
    pickupAddress: data.pickupAddress || 'N/A',
    dropoffAddress: data.dropoffAddress || 'N/A',
    status: data.status || 'N/A',
    createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : 'N/A',
  };
  
  for (const field of GEOPOINT_FIELDS) {
    const value = data[field];
    
    if (value === null || value === undefined) {
      missingFields.push(field);
    }
  }
  
  return { info, missingFields };
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
      missingGeoPoints: [],
      stats: {
        pickupLocation: { missing: 0, present: 0 },
        dropoffLocation: { missing: 0, present: 0 },
      },
    };
  }
  
  const missingGeoPoints = [];
  const stats = {
    pickupLocation: { missing: 0, present: 0 },
    dropoffLocation: { missing: 0, present: 0 },
  };
  
  // 檢查每個文檔
  for (const doc of snapshot.docs) {
    const { info, missingFields } = await checkDocument(collectionName, doc);
    
    // 更新統計
    for (const field of GEOPOINT_FIELDS) {
      if (missingFields.includes(field)) {
        stats[field].missing++;
      } else {
        stats[field].present++;
      }
    }
    
    // 收集缺失 GeoPoint 的文檔
    if (missingFields.length > 0) {
      missingGeoPoints.push({
        ...info,
        missingFields: missingFields,
      });
    }
  }
  
  // 顯示統計結果
  console.log(`📊 GeoPoint 欄位統計:\n`);
  
  for (const field of GEOPOINT_FIELDS) {
    const missing = stats[field].missing;
    const present = stats[field].present;
    const total = missing + present;
    const missingPercentage = total > 0 ? ((missing / total) * 100).toFixed(1) : 0;
    
    console.log(`${field}:`);
    console.log(`  ✅ 有座標: ${present}`);
    console.log(`  ❌ 缺少座標: ${missing} (${missingPercentage}%)`);
    console.log(``);
  }
  
  // 顯示缺失 GeoPoint 的文檔
  if (missingGeoPoints.length > 0) {
    console.log(`⚠️  發現 ${missingGeoPoints.length} 個訂單缺少地理位置座標:\n`);
    
    // 只顯示前 10 個
    const samplesToShow = Math.min(10, missingGeoPoints.length);
    for (let i = 0; i < samplesToShow; i++) {
      const doc = missingGeoPoints[i];
      console.log(`${i + 1}. ${doc.id}`);
      console.log(`   上車地點: ${doc.pickupAddress}`);
      console.log(`   下車地點: ${doc.dropoffAddress}`);
      console.log(`   狀態: ${doc.status}`);
      console.log(`   缺少欄位: ${doc.missingFields.join(', ')}`);
      console.log(`   建立時間: ${doc.createdAt}`);
      console.log(``);
    }
    
    if (missingGeoPoints.length > 10) {
      console.log(`   ... 還有 ${missingGeoPoints.length - 10} 個訂單缺少座標\n`);
    }
  } else {
    console.log(`✅ 所有訂單都有完整的地理位置座標!\n`);
  }
  
  console.log(`========================================\n`);
  
  return {
    total: snapshot.size,
    missingGeoPoints: missingGeoPoints,
    stats: stats,
  };
}

/**
 * 主函數
 */
async function main() {
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  Firestore 缺失 GeoPoint 檢查腳本      ║`);
  console.log(`╚════════════════════════════════════════╝\n`);
  
  console.log(`📋 檢查計劃:`);
  console.log(`  集合: ${COLLECTIONS.join(', ')}`);
  console.log(`  欄位: ${GEOPOINT_FIELDS.join(', ')}\n`);
  
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
    totalMissing += result.missingGeoPoints.length;
    
    console.log(`${collectionName}:`);
    console.log(`  總文檔數: ${result.total}`);
    console.log(`  缺少座標的訂單: ${result.missingGeoPoints.length}`);
    
    if (result.total > 0) {
      const percentage = ((result.missingGeoPoints.length / result.total) * 100).toFixed(1);
      console.log(`  缺失比例: ${percentage}%`);
    }
    
    console.log(``);
  }
  
  console.log(`總計:`);
  console.log(`  總文檔數: ${totalDocs}`);
  console.log(`  缺少座標的訂單: ${totalMissing}`);
  
  if (totalDocs > 0) {
    const percentage = ((totalMissing / totalDocs) * 100).toFixed(1);
    console.log(`  缺失比例: ${percentage}%`);
  }
  
  console.log(``);
  
  if (totalMissing === 0) {
    console.log(`🎉 太好了! 所有訂單都有完整的地理位置座標`);
  } else {
    console.log(`⚠️  發現問題! 有 ${totalMissing} 個訂單缺少地理位置座標`);
    console.log(`\n建議:`);
    console.log(`  1. 檢查這些訂單的來源 (可能是測試資料或早期訂單)`);
    console.log(`  2. 如果是測試資料,可以考慮刪除`);
    console.log(`  3. 如果是真實訂單,需要補充座標資料`);
    console.log(`  4. Flutter 代碼已修改為支持缺少座標的訂單 (pickupLocation 和 dropoffLocation 改為可選)`);
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

