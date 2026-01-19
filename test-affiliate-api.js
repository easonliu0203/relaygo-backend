// 測試客戶推廣人 API
const API_BASE_URL = 'https://api.relaygo.pro';
const FIREBASE_UID = 'hUu4fH5dTlW9VUYm6GojXvRLdni2'; // customer.test@relaygo.com
const TEST_PROMO_CODE = 'TEST123ABC';

async function testCheckPromoCode() {
  console.log('\n=== 測試 1: 檢查推薦碼可用性 ===');
  try {
    const response = await fetch(`${API_BASE_URL}/api/affiliates/check-promo-code/${TEST_PROMO_CODE}`);
    const result = await response.json();
    console.log('狀態碼:', response.status);
    console.log('回應:', JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('錯誤:', error.message);
  }
}

async function testApplyAffiliate() {
  console.log('\n=== 測試 2: 申請推廣人 ===');
  try {
    const response = await fetch(`${API_BASE_URL}/api/affiliates/apply`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user_id: FIREBASE_UID,
        promo_code: TEST_PROMO_CODE
      })
    });
    const result = await response.json();
    console.log('狀態碼:', response.status);
    console.log('回應:', JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('錯誤:', error.message);
  }
}

async function testGetMyStatus() {
  console.log('\n=== 測試 3: 查詢推廣人狀態 ===');
  try {
    const response = await fetch(`${API_BASE_URL}/api/affiliates/my-status?user_id=${FIREBASE_UID}`);
    const result = await response.json();
    console.log('狀態碼:', response.status);
    console.log('回應:', JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('錯誤:', error.message);
  }
}

async function runTests() {
  console.log('開始測試客戶推廣人 API...');
  console.log('API Base URL:', API_BASE_URL);
  console.log('Firebase UID:', FIREBASE_UID);
  console.log('測試推薦碼:', TEST_PROMO_CODE);
  
  await testCheckPromoCode();
  await testApplyAffiliate();
  await testGetMyStatus();
  
  console.log('\n測試完成！');
}

runTests();

