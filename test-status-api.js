const https = require('https');

const API_BASE_URL = 'https://relaygo-backend-production.up.railway.app';
const FIREBASE_UID = 'hUu4fH5dTlW9VUYm6GojXvRLdni2';

async function testStatusAPI() {
  console.log('🧪 測試推廣人狀態 API\n');
  console.log(`Firebase UID: ${FIREBASE_UID}\n`);

  const url = `${API_BASE_URL}/api/affiliates/my-status?user_id=${FIREBASE_UID}`;
  
  console.log(`📡 GET ${url}\n`);

  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        console.log(`✅ Status: ${res.statusCode}\n`);
        
        try {
          const result = JSON.parse(data);
          console.log('📦 Response:');
          console.log(JSON.stringify(result, null, 2));
          console.log('\n');
          
          if (result.success && result.data) {
            console.log('📊 解析結果:');
            console.log(`  - is_affiliate: ${result.data.is_affiliate}`);
            console.log(`  - affiliate_status: ${result.data.affiliate_status || 'null'}`);
            console.log(`  - is_active: ${result.data.is_active || 'null'}`);
            console.log(`  - promo_code: ${result.data.promo_code || 'null'}`);
          }
          
          resolve(result);
        } catch (error) {
          console.error('❌ JSON 解析錯誤:', error.message);
          console.log('原始響應:', data);
          reject(error);
        }
      });
    }).on('error', (error) => {
      console.error('❌ 請求錯誤:', error.message);
      reject(error);
    });
  });
}

testStatusAPI()
  .then(() => {
    console.log('\n✅ 測試完成');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ 測試失敗:', error);
    process.exit(1);
  });

