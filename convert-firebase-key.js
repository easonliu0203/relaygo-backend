/**
 * 轉換 Firebase Service Account JSON 為 Railway 環境變數格式
 * 
 * 使用方法：
 * 1. 從 Firebase Console 下載 Service Account JSON 文件
 * 2. 將文件放在 backend 目錄下
 * 3. 運行：node convert-firebase-key.js <json-file-path>
 * 
 * 例如：
 * node convert-firebase-key.js ride-platform-f1676-firebase-adminsdk-xxxxx.json
 */

const fs = require('fs');
const path = require('path');

// 獲取命令行參數
const args = process.argv.slice(2);

if (args.length === 0) {
  console.error('❌ 錯誤：請提供 Service Account JSON 文件路徑');
  console.error('');
  console.error('使用方法：');
  console.error('  node convert-firebase-key.js <json-file-path>');
  console.error('');
  console.error('例如：');
  console.error('  node convert-firebase-key.js ride-platform-f1676-firebase-adminsdk-xxxxx.json');
  process.exit(1);
}

const jsonFilePath = args[0];

// 檢查文件是否存在
if (!fs.existsSync(jsonFilePath)) {
  console.error(`❌ 錯誤：文件不存在: ${jsonFilePath}`);
  process.exit(1);
}

try {
  // 讀取 JSON 文件
  console.log(`📖 讀取文件: ${jsonFilePath}`);
  const serviceAccount = JSON.parse(fs.readFileSync(jsonFilePath, 'utf8'));
  
  // 提取必要信息
  const projectId = serviceAccount.project_id;
  const clientEmail = serviceAccount.client_email;
  const privateKey = serviceAccount.private_key;
  
  if (!projectId || !clientEmail || !privateKey) {
    console.error('❌ 錯誤：JSON 文件格式不正確');
    console.error('請確認文件包含以下欄位：');
    console.error('  - project_id');
    console.error('  - client_email');
    console.error('  - private_key');
    process.exit(1);
  }
  
  console.log('✅ JSON 文件讀取成功');
  console.log('');
  
  // 轉換私鑰格式：將實際換行符替換為 \n 字符串
  const formattedPrivateKey = privateKey.replace(/\n/g, '\\n');
  
  console.log('='.repeat(80));
  console.log('Railway 環境變數配置');
  console.log('='.repeat(80));
  console.log('');
  
  console.log('請將以下內容複製到 Railway 環境變數中：');
  console.log('');
  console.log('-'.repeat(80));
  console.log('變數名稱: FIREBASE_PROJECT_ID');
  console.log('變數值:');
  console.log(projectId);
  console.log('-'.repeat(80));
  console.log('');
  
  console.log('-'.repeat(80));
  console.log('變數名稱: FIREBASE_CLIENT_EMAIL');
  console.log('變數值:');
  console.log(clientEmail);
  console.log('-'.repeat(80));
  console.log('');
  
  console.log('-'.repeat(80));
  console.log('變數名稱: FIREBASE_PRIVATE_KEY');
  console.log('變數值:');
  console.log(formattedPrivateKey);
  console.log('-'.repeat(80));
  console.log('');
  
  console.log('='.repeat(80));
  console.log('');
  
  // 驗證私鑰格式
  console.log('🔍 私鑰格式驗證:');
  console.log(`  - 長度: ${formattedPrivateKey.length} 字符`);
  console.log(`  - 包含 BEGIN PRIVATE KEY: ${formattedPrivateKey.includes('BEGIN PRIVATE KEY') ? '✅' : '❌'}`);
  console.log(`  - 包含 END PRIVATE KEY: ${formattedPrivateKey.includes('END PRIVATE KEY') ? '✅' : '❌'}`);
  console.log(`  - 包含 \\n 字符串: ${formattedPrivateKey.includes('\\n') ? '✅' : '❌'}`);
  console.log(`  - 不包含實際換行符: ${!formattedPrivateKey.includes('\n') ? '✅' : '❌'}`);
  console.log('');
  
  // 保存到文件
  const outputFile = 'railway-env-vars.txt';
  const output = `# Railway 環境變數配置
# 生成時間: ${new Date().toISOString()}

FIREBASE_PROJECT_ID=${projectId}

FIREBASE_CLIENT_EMAIL=${clientEmail}

FIREBASE_PRIVATE_KEY=${formattedPrivateKey}
`;
  
  fs.writeFileSync(outputFile, output, 'utf8');
  console.log(`✅ 環境變數已保存到文件: ${outputFile}`);
  console.log('');
  console.log('📋 下一步操作：');
  console.log('1. 訪問 Railway Dashboard');
  console.log('2. selfless-surprise > Settings > Variables');
  console.log('3. 更新以上三個環境變數');
  console.log('4. Railway 會自動重新部署');
  console.log('');
  
} catch (error) {
  console.error('❌ 錯誤:', error.message);
  process.exit(1);
}

