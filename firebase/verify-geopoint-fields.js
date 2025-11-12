/**
 * Firestore GeoPoint 欄位驗證腳本
 * 
 * 功能: 檢查 Firestore 中的 GeoPoint 欄位格式
 * 
 * 使用方法:
 * 1. 安裝依賴: npm install firebase-admin
 * 2. 設置環境變數: export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
 * 3. 運行腳本: node firebase/verify-geopoint-fields.js
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
 * 獲取欄位的類型
 */
function getFieldType(value) {
  if (value === null || value === undefined) {
    return 'null';
  }
  
  if (value instanceof admin.firestore.GeoPoint) {
    return 'GeoPoint';
  }
  
  if (typeof value === 'object') {
    // 檢查是否是 Map 格式的 GeoPoint
    if ('latitude' in value && 'longitude' in value) {
      return 'Map (latitude/longitude)';
    }
    if ('_latitude' in value && '_longitude' in value) {
      return 'Map (_latitude/_longitude)';
    }
    return 'Map (other)';
  }
  
  return typeof value;
}

/**
 * 檢查單個文檔
 */
async function checkDocument(collectionName, doc) {
  const data = doc.data();
  const issues = [];
  const info = {
    id: doc.id,
    fields: {},
  };
  
  for (const field of GEOPOINT_FIELDS) {
    const value = data[field];
    const type = getFieldType(value);
    
    info.fields[field] = {
      type: type,
      value: value,
    };
    
    // 如果不是 GeoPoint 或 null,記錄為問題
    if (type !== 'GeoPoint' && type !== 'null') {
      issues.push({
        docId: doc.id,
        field: field,
        type: type,
        value: value,
      });
    }
  }
  
  return { info, issues };
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
      issues: [],
      stats: {},
    };
  }
  
  const allIssues = [];
  const typeStats = {};
  
  // 初始化統計
  for (const field of GEOPOINT_FIELDS) {
    typeStats[field] = {
      GeoPoint: 0,
      'Map (latitude/longitude)': 0,
      'Map (_latitude/_longitude)': 0,
      'Map (other)': 0,
      null: 0,
      other: 0,
    };
  }
  
  // 檢查每個文檔
  for (const doc of snapshot.docs) {
    const { info, issues } = await checkDocument(collectionName, doc);
    
    // 更新統計
    for (const field of GEOPOINT_FIELDS) {
      const type = info.fields[field].type;
      if (typeStats[field][type] !== undefined) {
        typeStats[field][type]++;
      } else {
        typeStats[field].other++;
      }
    }
    
    // 收集問題
    if (issues.length > 0) {
      allIssues.push(...issues);
    }
  }
  
  // 顯示統計結果
  console.log(`📊 欄位類型統計:\n`);
  
  for (const field of GEOPOINT_FIELDS) {
    console.log(`${field}:`);
    console.log(`  ✅ GeoPoint: ${typeStats[field].GeoPoint}`);
    console.log(`  ⚠️  Map (latitude/longitude): ${typeStats[field]['Map (latitude/longitude)']}`);
    console.log(`  ⚠️  Map (_latitude/_longitude): ${typeStats[field]['Map (_latitude/_longitude)']}`);
    console.log(`  ❌ Map (other): ${typeStats[field]['Map (other)']}`);
    console.log(`  ⏭️  null: ${typeStats[field].null}`);
    console.log(`  ❓ other: ${typeStats[field].other}`);
    console.log(``);
  }
  
  // 顯示問題
  if (allIssues.length > 0) {
    console.log(`⚠️  發現 ${allIssues.length} 個問題:\n`);
    
    // 按欄位分組顯示
    const issuesByField = {};
    for (const issue of allIssues) {
      if (!issuesByField[issue.field]) {
        issuesByField[issue.field] = [];
      }
      issuesByField[issue.field].push(issue);
    }
    
    for (const field of GEOPOINT_FIELDS) {
      if (issuesByField[field] && issuesByField[field].length > 0) {
        console.log(`${field} (${issuesByField[field].length} 個問題):`);
        
        // 只顯示前 5 個
        const samplesToShow = Math.min(5, issuesByField[field].length);
        for (let i = 0; i < samplesToShow; i++) {
          const issue = issuesByField[field][i];
          console.log(`  - ${issue.docId}: ${issue.type}`);
        }
        
        if (issuesByField[field].length > 5) {
          console.log(`  ... 還有 ${issuesByField[field].length - 5} 個問題`);
        }
        
        console.log(``);
      }
    }
  } else {
    console.log(`✅ 沒有發現問題! 所有 GeoPoint 欄位都是正確格式\n`);
  }
  
  console.log(`========================================\n`);
  
  return {
    total: snapshot.size,
    issues: allIssues,
    stats: typeStats,
  };
}

/**
 * 主函數
 */
async function main() {
  console.log(`\n╔════════════════════════════════════════╗`);
  console.log(`║  Firestore GeoPoint 欄位驗證腳本       ║`);
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
  let totalIssues = 0;
  
  for (const collectionName of COLLECTIONS) {
    const result = allResults[collectionName];
    totalDocs += result.total;
    totalIssues += result.issues.length;
    
    console.log(`${collectionName}:`);
    console.log(`  總文檔數: ${result.total}`);
    console.log(`  問題數: ${result.issues.length}`);
    
    if (result.issues.length > 0) {
      const percentage = ((result.issues.length / result.total) * 100).toFixed(1);
      console.log(`  問題比例: ${percentage}%`);
    }
    
    console.log(``);
  }
  
  console.log(`總計:`);
  console.log(`  總文檔數: ${totalDocs}`);
  console.log(`  總問題數: ${totalIssues}`);
  console.log(``);
  
  if (totalIssues === 0) {
    console.log(`🎉 驗證通過! 所有 GeoPoint 欄位都是正確格式`);
  } else {
    console.log(`⚠️  發現問題! 需要運行遷移腳本修復`);
    console.log(`\n執行以下命令進行修復:`);
    console.log(`  node firebase/migrate-geopoint-fields.js`);
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

