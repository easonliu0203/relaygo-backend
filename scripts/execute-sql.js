#!/usr/bin/env node

/**
 * 執行 SQL 腳本到 Supabase 遠程數據庫
 * 使用方式: node scripts/execute-sql.js <sql-file-path>
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// Supabase 專案配置
const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_PROJECT_REF = 'vlyhwegpvpnjyocqmfqc';

// 從環境變數或 .env 文件讀取 Service Role Key
// 注意：這需要 Service Role Key，不是 Anon Key
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ 錯誤: 未設置 SUPABASE_SERVICE_ROLE_KEY 環境變數');
  console.error('');
  console.error('請設置環境變數:');
  console.error('  Windows (CMD): set SUPABASE_SERVICE_ROLE_KEY=your_key_here');
  console.error('  Windows (PowerShell): $env:SUPABASE_SERVICE_ROLE_KEY="your_key_here"');
  console.error('  Linux/Mac: export SUPABASE_SERVICE_ROLE_KEY=your_key_here');
  console.error('');
  console.error('您可以在 Supabase Dashboard 的 Settings > API 中找到 Service Role Key');
  process.exit(1);
}

// 獲取 SQL 文件路徑
const sqlFilePath = process.argv[2];

if (!sqlFilePath) {
  console.error('❌ 錯誤: 請提供 SQL 文件路徑');
  console.error('使用方式: node scripts/execute-sql.js <sql-file-path>');
  process.exit(1);
}

// 讀取 SQL 文件
const fullPath = path.resolve(sqlFilePath);
if (!fs.existsSync(fullPath)) {
  console.error(`❌ 錯誤: 文件不存在: ${fullPath}`);
  process.exit(1);
}

const sqlContent = fs.readFileSync(fullPath, 'utf8');

console.log(`📄 讀取 SQL 文件: ${path.basename(sqlFilePath)}`);
console.log(`📏 文件大小: ${sqlContent.length} 字符`);
console.log('');

// 執行 SQL
console.log('🚀 執行 SQL...');
console.log('');

// 使用 Supabase REST API 執行 SQL
const postData = JSON.stringify({
  query: sqlContent
});

const options = {
  hostname: `${SUPABASE_PROJECT_REF}.supabase.co`,
  port: 443,
  path: '/rest/v1/rpc/exec_sql',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData),
    'apikey': SUPABASE_SERVICE_ROLE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log(`📊 HTTP 狀態碼: ${res.statusCode}`);
    console.log('');
    
    if (res.statusCode === 200 || res.statusCode === 201) {
      console.log('✅ SQL 執行成功！');
      console.log('');
      console.log('📋 執行結果:');
      try {
        const result = JSON.parse(data);
        console.log(JSON.stringify(result, null, 2));
      } catch (e) {
        console.log(data);
      }
    } else {
      console.error('❌ SQL 執行失敗！');
      console.error('');
      console.error('錯誤訊息:');
      console.error(data);
      process.exit(1);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ 請求失敗:', error.message);
  process.exit(1);
});

req.write(postData);
req.end();

