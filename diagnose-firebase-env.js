/**
 * Firebase 環境變數診斷腳本
 * 用於檢查 Railway 上的 Firebase 環境變數是否正確配置
 */

require('dotenv').config();

console.log('=== Firebase 環境變數診斷 ===\n');

// 檢查環境變數是否存在
const projectId = process.env.FIREBASE_PROJECT_ID;
const privateKey = process.env.FIREBASE_PRIVATE_KEY;
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

console.log('1. 環境變數存在性檢查:');
console.log(`   FIREBASE_PROJECT_ID: ${projectId ? '✅ 存在' : '❌ 不存在'}`);
console.log(`   FIREBASE_PRIVATE_KEY: ${privateKey ? '✅ 存在' : '❌ 不存在'}`);
console.log(`   FIREBASE_CLIENT_EMAIL: ${clientEmail ? '✅ 存在' : '❌ 不存在'}`);
console.log('');

if (projectId) {
  console.log('2. FIREBASE_PROJECT_ID:');
  console.log(`   值: ${projectId}`);
  console.log('');
}

if (clientEmail) {
  console.log('3. FIREBASE_CLIENT_EMAIL:');
  console.log(`   值: ${clientEmail}`);
  console.log('');
}

if (privateKey) {
  console.log('4. FIREBASE_PRIVATE_KEY 格式檢查:');
  console.log(`   長度: ${privateKey.length} 字符`);
  console.log(`   前 50 字符: ${privateKey.substring(0, 50)}...`);
  console.log(`   後 50 字符: ...${privateKey.substring(privateKey.length - 50)}`);
  console.log('');
  
  console.log('5. FIREBASE_PRIVATE_KEY 內容檢查:');
  console.log(`   包含 "BEGIN PRIVATE KEY": ${privateKey.includes('BEGIN PRIVATE KEY') ? '✅' : '❌'}`);
  console.log(`   包含 "END PRIVATE KEY": ${privateKey.includes('END PRIVATE KEY') ? '✅' : '❌'}`);
  console.log(`   包含 \\\\n (雙反斜杠): ${privateKey.includes('\\\\n') ? '✅' : '❌'}`);
  console.log(`   包含 \\n (單反斜杠): ${privateKey.includes('\\n') ? '✅' : '❌'}`);
  console.log(`   包含實際換行符: ${privateKey.includes('\n') ? '✅' : '❌'}`);
  console.log('');
  
  // 處理私鑰格式
  let processedKey = privateKey;
  
  // 如果包含雙反斜杠，先轉換為單反斜杠
  if (privateKey.includes('\\\\n')) {
    console.log('6. 私鑰格式轉換（雙反斜杠 → 單反斜杠）:');
    processedKey = processedKey.replace(/\\\\n/g, '\\n');
    console.log(`   轉換後長度: ${processedKey.length}`);
    console.log(`   轉換後前 50 字符: ${processedKey.substring(0, 50)}...`);
    console.log('');
  }
  
  // 如果包含單反斜杠字符串，轉換為實際換行符
  if (processedKey.includes('\\n') && !processedKey.includes('\n')) {
    console.log('7. 私鑰格式轉換（單反斜杠 → 實際換行符）:');
    processedKey = processedKey.replace(/\\n/g, '\n');
    console.log(`   轉換後長度: ${processedKey.length}`);
    console.log(`   轉換後包含實際換行符: ${processedKey.includes('\n') ? '✅' : '❌'}`);
    console.log('');
  }
  
  console.log('8. 最終私鑰格式驗證:');
  console.log(`   包含實際換行符: ${processedKey.includes('\n') ? '✅' : '❌'}`);
  console.log(`   包含 BEGIN PRIVATE KEY: ${processedKey.includes('BEGIN PRIVATE KEY') ? '✅' : '❌'}`);
  console.log(`   包含 END PRIVATE KEY: ${processedKey.includes('END PRIVATE KEY') ? '✅' : '❌'}`);
  console.log('');
  
  // 計算換行符數量
  const newlineCount = (processedKey.match(/\n/g) || []).length;
  console.log(`   換行符數量: ${newlineCount}`);
  console.log(`   預期換行符數量: 26-28（標準 RSA 私鑰）`);
  console.log(`   換行符數量檢查: ${newlineCount >= 20 && newlineCount <= 35 ? '✅ 正常' : '❌ 異常'}`);
  console.log('');
  
  // 分割私鑰行
  const lines = processedKey.split('\n');
  console.log('9. 私鑰行結構:');
  console.log(`   總行數: ${lines.length}`);
  console.log(`   第一行: ${lines[0]}`);
  console.log(`   最後一行: ${lines[lines.length - 1]}`);
  console.log('');
  
  // 檢查私鑰格式是否正確
  const isValidFormat = 
    processedKey.includes('\n') &&
    processedKey.includes('BEGIN PRIVATE KEY') &&
    processedKey.includes('END PRIVATE KEY') &&
    newlineCount >= 20 &&
    newlineCount <= 35;
  
  console.log('10. 私鑰格式總結:');
  console.log(`    格式是否正確: ${isValidFormat ? '✅ 正確' : '❌ 錯誤'}`);
  console.log('');
  
  if (!isValidFormat) {
    console.log('⚠️  警告：私鑰格式可能不正確！');
    console.log('');
    console.log('建議檢查：');
    console.log('1. 確認 Railway 環境變數中的 FIREBASE_PRIVATE_KEY 包含完整的私鑰');
    console.log('2. 確認私鑰以 -----BEGIN PRIVATE KEY----- 開頭');
    console.log('3. 確認私鑰以 -----END PRIVATE KEY----- 結尾');
    console.log('4. 確認私鑰中的換行符格式正確（\\n 或實際換行符）');
    console.log('');
  }
}

// 測試 Firebase Admin SDK 初始化
console.log('11. 測試 Firebase Admin SDK 初始化:');
try {
  const admin = require('firebase-admin');
  
  if (!projectId || !privateKey || !clientEmail) {
    console.log('   ❌ 環境變數不完整，無法初始化');
  } else {
    // 處理私鑰格式
    let processedKey = privateKey;
    if (privateKey.includes('\\\\n')) {
      processedKey = processedKey.replace(/\\\\n/g, '\\n');
    }
    if (processedKey.includes('\\n') && !processedKey.includes('\n')) {
      processedKey = processedKey.replace(/\\n/g, '\n');
    }
    
    console.log('   正在初始化 Firebase Admin SDK...');
    
    const app = admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        privateKey: processedKey,
        clientEmail,
      }),
      projectId,
      databaseURL: `https://${projectId}.firebaseio.com`,
    });
    
    console.log('   ✅ Firebase Admin SDK 初始化成功');
    console.log(`   App Name: ${app.name}`);
    console.log(`   Project ID: ${app.options.projectId}`);
    console.log('');
    
    // 測試 Firestore 連接
    console.log('12. 測試 Firestore 連接:');
    const firestore = admin.firestore();
    console.log('   ✅ Firestore 實例創建成功');
    console.log('');
    
    // 測試寫入權限（不實際寫入）
    console.log('13. 測試 Firestore 權限:');
    console.log('   正在測試讀取權限...');
    
    firestore.collection('_test_connection').limit(1).get()
      .then(() => {
        console.log('   ✅ Firestore 讀取權限正常');
        console.log('');
        console.log('=== 診斷完成 ===');
        console.log('結論: Firebase 配置正確，應該可以正常使用');
        process.exit(0);
      })
      .catch((error) => {
        console.log('   ❌ Firestore 讀取權限測試失敗');
        console.log(`   錯誤: ${error.message}`);
        console.log('');
        console.log('=== 診斷完成 ===');
        console.log('結論: Firebase 配置有問題，請檢查 Service Account 權限');
        process.exit(1);
      });
  }
} catch (error) {
  console.log(`   ❌ 初始化失敗: ${error.message}`);
  console.log('');
  console.log('=== 診斷完成 ===');
  console.log('結論: Firebase 配置有問題');
  process.exit(1);
}

