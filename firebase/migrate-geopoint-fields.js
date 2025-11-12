/**
 * Firestore GeoPoint 欄位遷移腳本
 * 
 * 功能: 將 Map 格式的地理位置欄位轉換為 Firestore GeoPoint 格式
 * 
 * 背景:
 * - 舊版 Edge Function 將地理位置存儲為 Map 格式
 * - 新版 Edge Function 使用正確的 GeoPoint 格式
 * - 客戶端期望 GeoPoint 格式,遇到 Map 會報錯
 * 
 * 使用方法:
 * 1. 安裝依賴: npm install firebase-admin
 * 2. 設置環境變數: export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
 * 3. 運行腳本: node firebase/migrate-geopoint-fields.js
 */

const admin = require('firebase-admin');

// 初始化 Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// 需要遷移的集合
const COLLECTIONS = ['orders_rt', 'bookings'];

// 需要遷移的 GeoPoint 欄位
const GEOPOINT_FIELDS = ['pickupLocation', 'dropoffLocation'];

/**
 * 檢查欄位是否是 Map 格式的 GeoPoint
 */
function isMapGeoPoint(value) {
  if (typeof value !== 'object' || value === null) return false;
  
  // 檢查是否包含 latitude 和 longitude 欄位
  if ('latitude' in value && 'longitude' in value) {
    return typeof value.latitude === 'number' && typeof value.longitude === 'number';
  }
  
  // 檢查是否包含 _latitude 和 _longitude 欄位
  if ('_latitude' in value && '_longitude' in value) {
    return typeof value._latitude === 'number' && typeof value._longitude === 'number';
  }
  
  return false;
}

/**
 * 將 Map 轉換為 Firestore GeoPoint
 */
function convertToGeoPoint(value) {
  if (value instanceof admin.firestore.GeoPoint) {
    return value;
  }
  
  if (typeof value === 'object' && value !== null) {
    // 嘗試從 latitude/longitude 欄位提取
    if ('latitude' in value && 'longitude' in value) {
      return new admin.firestore.GeoPoint(value.latitude, value.longitude);
    }
    
    // 嘗試從 _latitude/_longitude 欄位提取
    if ('_latitude' in value && '_longitude' in value) {
      return new admin.firestore.GeoPoint(value._latitude, value._longitude);
    }
  }
  
  return value;
}

/**
 * 遷移單個文檔
 */
async function migrateDocument(collectionName, docRef) {
  try {
    const doc = await docRef.get();
    
    if (!doc.exists) {
      console.log(`  ⚠️  文檔不存在: ${doc.id}`);
      return { success: false, reason: 'not_exists' };
    }
    
    const data = doc.data();
    const updates = {};
    let hasMapGeoPoint = false;
    
    // 檢查每個 GeoPoint 欄位
    for (const field of GEOPOINT_FIELDS) {
      const value = data[field];
      
      // 跳過 null 或 undefined
      if (value === null || value === undefined) {
        continue;
      }
      
      // 如果是 Map 格式,轉換為 GeoPoint
      if (isMapGeoPoint(value)) {
        hasMapGeoPoint = true;
        const geoPoint = convertToGeoPoint(value);
        updates[field] = geoPoint;
        console.log(`  🔄 ${field}: Map → GeoPoint (${geoPoint.latitude}, ${geoPoint.longitude})`);
      }
    }
    
    // 如果有需要更新的欄位,執行更新
    if (hasMapGeoPoint) {
      await docRef.update(updates);
      console.log(`  ✅ 已更新: ${collectionName}/${doc.id}`);
      return { success: true, updated: true };
    } else {
      console.log(`  ⏭️  跳過 (已是正確格式): ${collectionName}/${doc.id}`);
      return { success: true, updated: false };
    }
  } catch (error) {
    console.error(`  ❌ 錯誤: ${docRef.id}`, error.message);
    return { success: false, error: error.message };
  }
}

/**
 * 遷移整個集合
 */
async function migrateCollection(collectionName) {
  console.log(`\n========================================`);
  console.log(`開始遷移集合: ${collectionName}`);
  console.log(`========================================\n`);
  
  const collectionRef = db.collection(collectionName);
  const snapshot = await collectionRef.get();
  
  console.log(`📊 總文檔數: ${snapshot.size}\n`);
  
  const stats = {
    total: snapshot.size,
    updated: 0,
    skipped: 0,
    failed: 0,
  };
  
  // 批次處理 (每批 10 個文檔)
  const batchSize = 10;
  const docs = snapshot.docs;
  
  for (let i = 0; i < docs.length; i += batchSize) {
    const batch = docs.slice(i, i + batchSize);
    
    console.log(`\n處理批次 ${Math.floor(i / batchSize) + 1}/${Math.ceil(docs.length / batchSize)} (文檔 ${i + 1}-${Math.min(i + batchSize, docs.length)})`);
    console.log(`----------------------------------------`);
    
    // 並行處理批次中的文檔
    const results = await Promise.all(
      batch.map(doc => migrateDocument(collectionName, doc.ref))
    );
    
    // 統計結果
    results.forEach(result => {
      if (result.success) {
        if (result.updated) {
          stats.updated++;
        } else {
          stats.skipped++;
        }
      } else {
        stats.failed++;
      }
    });
    
    // 避免超過 Firestore 配額,每批次之間暫停 1 秒
    if (i + batchSize < docs.length) {
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }
  
  // 顯示統計結果
  console.log(`\n========================================`);
  console.log(`集合 ${collectionName} 遷移完成`);
  console.log(`========================================`);
  console.log(`📊 統計:`);
  console.log(`  總文檔數: ${stats.total}`);
  console.log(`  ✅ 已更新: ${stats.updated}`);
  console.log(`  ⏭️  已跳過: ${stats.skipped}`);
  console.log(`  ❌ 失敗: ${stats.failed}`);
  console.log(`========================================\n`);
  
  return stats;
}

/**
 * 驗證遷移結果
 */
async function verifyMigration(collectionName) {
  console.log(`\n🔍 驗證集合: ${collectionName}`);
  console.log(`----------------------------------------`);
  
  const collectionRef = db.collection(collectionName);
  const snapshot = await collectionRef.get();
  
  const issues = [];
  
  for (const doc of snapshot.docs) {
    const data = doc.data();
    
    for (const field of GEOPOINT_FIELDS) {
      const value = data[field];
      
      // 跳過 null 或 undefined
      if (value === null || value === undefined) {
        continue;
      }
      
      // 檢查是否是 Map 格式
      if (isMapGeoPoint(value)) {
        issues.push({
          docId: doc.id,
          field: field,
          value: value,
        });
      }
    }
  }
  
  if (issues.length === 0) {
    console.log(`✅ 驗證通過: 所有 GeoPoint 欄位都是正確格式`);
  } else {
    console.log(`⚠️  發現 ${issues.length} 個問題:`);
    issues.forEach(issue => {
      console.log(`  - ${issue.docId}.${issue.field}: Map 格式`);
    });
  }
  
  console.log(`----------------------------------------\n`);
  
  return issues;
}

/**
 * 主函數
 */
async function main() {
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  Firestore GeoPoint 欄位遷移腳本       ║`);
  console.log(`╚════════════════════════════════════════╝\n`);
  
  console.log(`📋 遷移計劃:`);
  console.log(`  集合: ${COLLECTIONS.join(', ')}`);
  console.log(`  欄位: ${GEOPOINT_FIELDS.join(', ')}`);
  console.log(`  操作: Map → Firestore GeoPoint\n`);
  
  console.log(`⚠️  警告: 此操作將修改 Firestore 資料`);
  console.log(`請確認您已備份資料並了解操作風險\n`);
  
  const allStats = {};
  
  // 遷移每個集合
  for (const collectionName of COLLECTIONS) {
    const stats = await migrateCollection(collectionName);
    allStats[collectionName] = stats;
  }
  
  // 驗證遷移結果
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  驗證遷移結果                          ║`);
  console.log(`╚════════════════════════════════════════╝`);
  
  const allIssues = {};
  for (const collectionName of COLLECTIONS) {
    const issues = await verifyMigration(collectionName);
    allIssues[collectionName] = issues;
  }
  
  // 最終總結
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  遷移完成總結                          ║`);
  console.log(`╚════════════════════════════════════════╝\n`);
  
  for (const collectionName of COLLECTIONS) {
    const stats = allStats[collectionName];
    const issues = allIssues[collectionName];
    
    console.log(`${collectionName}:`);
    console.log(`  總文檔數: ${stats.total}`);
    console.log(`  已更新: ${stats.updated}`);
    console.log(`  已跳過: ${stats.skipped}`);
    console.log(`  失敗: ${stats.failed}`);
    console.log(`  剩餘問題: ${issues.length}`);
    console.log(``);
  }
  
  const totalIssues = Object.values(allIssues).reduce((sum, issues) => sum + issues.length, 0);
  
  if (totalIssues === 0) {
    console.log(`🎉 遷移成功! 所有 GeoPoint 欄位都已轉換為正確格式`);
  } else {
    console.log(`⚠️  遷移完成,但仍有 ${totalIssues} 個問題需要處理`);
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

