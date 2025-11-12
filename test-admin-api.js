// 測試公司端 API 端點
// 用於診斷公司端管理頁面是否能正確獲取測試帳號

const http = require('http');

const API_BASE_URL = 'http://localhost:3001';

console.log('========================================');
console.log('公司端 API 診斷工具');
console.log('========================================');
console.log('');

// 測試 1: 獲取客戶列表
console.log('測試 1: 獲取客戶列表');
console.log('URL:', `${API_BASE_URL}/api/admin/customers`);
console.log('');

const testCustomers = () => {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3001,
      path: '/api/admin/customers?limit=100&offset=0',
      method: 'GET',
    };

    const req = http.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        console.log('響應狀態碼:', res.statusCode);
        console.log('');

        try {
          const jsonData = JSON.parse(data);
          
          if (res.statusCode === 200 && jsonData.success) {
            console.log('✅ 客戶列表獲取成功');
            console.log(`   總數: ${jsonData.total}`);
            console.log(`   返回數量: ${jsonData.data?.length || 0}`);
            console.log('');

            // 查找測試帳號
            const testCustomer = jsonData.data?.find(c => c.email === 'customer.test@relaygo.com');
            if (testCustomer) {
              console.log('✅ 找到客戶測試帳號:');
              console.log(`   ID: ${testCustomer.id}`);
              console.log(`   Email: ${testCustomer.email}`);
              console.log(`   姓名: ${testCustomer.name}`);
              console.log(`   電話: ${testCustomer.phone}`);
              console.log(`   狀態: ${testCustomer.status}`);
              console.log('');
              console.log('原始資料:');
              console.log(JSON.stringify(testCustomer, null, 2));
            } else {
              console.log('❌ 未找到客戶測試帳號');
              console.log('');
              console.log('返回的客戶列表:');
              jsonData.data?.forEach((c, i) => {
                console.log(`   ${i + 1}. ${c.email} - ${c.name}`);
              });
            }
          } else {
            console.log('❌ 客戶列表獲取失敗');
            console.log('錯誤:', jsonData.error || jsonData.message);
          }

          console.log('');
          console.log('========================================');
          console.log('');
          resolve();
        } catch (e) {
          console.log('❌ 無法解析 JSON 響應');
          console.log('原始響應:', data);
          console.log('');
          console.log('========================================');
          console.log('');
          reject(e);
        }
      });
    });

    req.on('error', (e) => {
      console.log('❌ 請求失敗:', e.message);
      console.log('');
      console.log('========================================');
      console.log('');
      reject(e);
    });

    req.end();
  });
};

// 測試 2: 獲取司機列表
const testDrivers = () => {
  return new Promise((resolve, reject) => {
    console.log('測試 2: 獲取司機列表');
    console.log('URL:', `${API_BASE_URL}/api/admin/drivers`);
    console.log('');

    const options = {
      hostname: 'localhost',
      port: 3001,
      path: '/api/admin/drivers?limit=100&offset=0',
      method: 'GET',
    };

    const req = http.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        console.log('響應狀態碼:', res.statusCode);
        console.log('');

        try {
          const jsonData = JSON.parse(data);
          
          if (res.statusCode === 200 && jsonData.success) {
            console.log('✅ 司機列表獲取成功');
            console.log(`   總數: ${jsonData.total}`);
            console.log(`   返回數量: ${jsonData.data?.length || 0}`);
            console.log('');

            // 查找測試帳號
            const testDriver = jsonData.data?.find(d => d.email === 'driver.test@relaygo.com');
            if (testDriver) {
              console.log('✅ 找到司機測試帳號:');
              console.log(`   ID: ${testDriver.id}`);
              console.log(`   Email: ${testDriver.email}`);
              console.log(`   姓名: ${testDriver.name}`);
              console.log(`   電話: ${testDriver.phone}`);
              console.log(`   狀態: ${testDriver.status}`);
              console.log(`   駕照: ${testDriver.licenseNumber}`);
              console.log(`   車型: ${testDriver.vehicleType}`);
              console.log(`   車牌: ${testDriver.vehiclePlate}`);
            } else {
              console.log('❌ 未找到司機測試帳號');
              console.log('');
              console.log('返回的司機列表:');
              jsonData.data?.forEach((d, i) => {
                console.log(`   ${i + 1}. ${d.email} - ${d.name}`);
              });
            }
          } else {
            console.log('❌ 司機列表獲取失敗');
            console.log('錯誤:', jsonData.error || jsonData.message);
          }

          console.log('');
          console.log('========================================');
          console.log('');
          resolve();
        } catch (e) {
          console.log('❌ 無法解析 JSON 響應');
          console.log('原始響應:', data);
          console.log('');
          console.log('========================================');
          console.log('');
          reject(e);
        }
      });
    });

    req.on('error', (e) => {
      console.log('❌ 請求失敗:', e.message);
      console.log('');
      console.log('========================================');
      console.log('');
      reject(e);
    });

    req.end();
  });
};

// 執行測試
async function main() {
  try {
    await testCustomers();
    await testDrivers();
    
    console.log('診斷完成！');
    console.log('');
    console.log('如果測試帳號都找到了，請訪問:');
    console.log('- 客戶管理: http://localhost:3001/customers');
    console.log('- 司機管理: http://localhost:3001/drivers');
    console.log('');
    console.log('如果頁面上仍然看不到測試帳號，請檢查:');
    console.log('1. 瀏覽器控制台的錯誤訊息');
    console.log('2. 前端的篩選條件（狀態、搜尋等）');
    console.log('3. 清除瀏覽器快取並重新整理');
  } catch (error) {
    console.error('測試失敗:', error.message);
  }
}

main();

