// 測試個人資料 API 端點
// 用於診斷中台 API 是否正常工作

const http = require('http');

// 測試配置
const API_BASE_URL = 'http://localhost:3001';
const TEST_FIREBASE_UID = 'CMfTxhJFlUVDkosJPyUoJvKjCQk1'; // 客戶測試帳號的 Firebase UID

console.log('========================================');
console.log('個人資料 API 診斷工具');
console.log('========================================');
console.log('');

// 測試 1: 檢查 API 是否運行
console.log('測試 1: 檢查 API 是否運行');
console.log('URL:', `${API_BASE_URL}/api/profile/upsert`);
console.log('');

const testData = {
  firebaseUid: TEST_FIREBASE_UID,
  firstName: '測試',
  lastName: '客戶',
  phone: '0912345678',
};

const postData = JSON.stringify(testData);

const options = {
  hostname: 'localhost',
  port: 3001,
  path: '/api/profile/upsert',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData),
  },
};

console.log('發送請求...');
console.log('數據:', testData);
console.log('');

const req = http.request(options, (res) => {
  console.log('========================================');
  console.log('響應狀態碼:', res.statusCode);
  console.log('響應頭:', res.headers);
  console.log('========================================');
  console.log('');

  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('響應內容:');
    try {
      const jsonData = JSON.parse(data);
      console.log(JSON.stringify(jsonData, null, 2));
      
      console.log('');
      console.log('========================================');
      if (res.statusCode === 200 && jsonData.success) {
        console.log('✅ 測試成功！API 正常工作');
        console.log('');
        console.log('返回的資料:');
        console.log('- ID:', jsonData.data?.id);
        console.log('- 姓名:', jsonData.data?.firstName, jsonData.data?.lastName);
        console.log('- 電話:', jsonData.data?.phone);
      } else {
        console.log('❌ 測試失敗！');
        console.log('');
        console.log('錯誤訊息:', jsonData.error || jsonData.message);
        if (jsonData.details) {
          console.log('詳細資訊:', jsonData.details);
        }
      }
      console.log('========================================');
    } catch (e) {
      console.log('原始響應:', data);
      console.log('');
      console.log('========================================');
      console.log('❌ 無法解析 JSON 響應');
      console.log('錯誤:', e.message);
      console.log('========================================');
    }
  });
});

req.on('error', (e) => {
  console.log('========================================');
  console.log('❌ 請求失敗！');
  console.log('錯誤:', e.message);
  console.log('========================================');
  console.log('');
  console.log('可能的原因:');
  console.log('1. web-admin 未啟動');
  console.log('2. 端口 3001 被其他程序佔用');
  console.log('3. 防火牆阻止連接');
  console.log('');
  console.log('解決方案:');
  console.log('1. 啟動 web-admin: cd web-admin && npm run dev');
  console.log('2. 檢查端口: netstat -ano | findstr :3001');
  console.log('3. 檢查防火牆設置');
});

req.write(postData);
req.end();

