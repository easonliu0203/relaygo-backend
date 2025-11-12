/**
 * 測試司機/客戶姓名顯示修復
 * 
 * 測試內容：
 * 1. 公司端可用司機 API - 檢查司機姓名是否正確返回
 * 2. 檢查 Firestore 中的訂單資料是否包含司機/客戶資訊
 */

const BASE_URL = 'http://localhost:3001';

async function testAvailableDriversAPI() {
  console.log('\n========================================');
  console.log('測試 1: 公司端可用司機 API');
  console.log('========================================\n');

  try {
    const response = await fetch(`${BASE_URL}/api/admin/drivers/available?vehicleType=A`);
    const data = await response.json();

    console.log('API 響應狀態:', response.status);
    console.log('API 響應:', JSON.stringify(data, null, 2));

    if (data.success && data.data && data.data.length > 0) {
      console.log('\n✅ API 調用成功');
      console.log(`找到 ${data.data.length} 個可用司機\n`);

      data.data.forEach((driver, index) => {
        console.log(`司機 ${index + 1}:`);
        console.log(`  - ID: ${driver.id}`);
        console.log(`  - 姓名: ${driver.name || '❌ 未顯示'}`);
        console.log(`  - 電話: ${driver.phone || '未提供'}`);
        console.log(`  - Email: ${driver.email}`);
        console.log(`  - 車型: ${driver.vehicleType || '未提供'}`);
        console.log(`  - 車牌: ${driver.vehiclePlate || '未提供'}`);
        console.log(`  - 評分: ${driver.rating || 0}`);
        console.log('');
      });

      // 檢查是否所有司機都有姓名
      const driversWithoutName = data.data.filter(d => !d.name || d.name === '未知司機');
      if (driversWithoutName.length > 0) {
        console.log(`⚠️ 警告: ${driversWithoutName.length} 個司機沒有姓名`);
        return false;
      } else {
        console.log('✅ 所有司機都有姓名');
        return true;
      }
    } else {
      console.log('❌ API 調用失敗或沒有可用司機');
      return false;
    }
  } catch (error) {
    console.error('❌ 測試失敗:', error.message);
    return false;
  }
}

async function main() {
  console.log('開始測試司機/客戶姓名顯示修復...\n');

  const results = {
    availableDriversAPI: false,
  };

  // 測試 1: 可用司機 API
  results.availableDriversAPI = await testAvailableDriversAPI();

  // 總結
  console.log('\n========================================');
  console.log('測試總結');
  console.log('========================================\n');

  console.log('測試結果:');
  console.log(`  1. 可用司機 API: ${results.availableDriversAPI ? '✅ 通過' : '❌ 失敗'}`);

  const allPassed = Object.values(results).every(r => r === true);

  console.log('\n' + (allPassed ? '✅ 所有測試通過！' : '❌ 部分測試失敗'));

  console.log('\n========================================');
  console.log('下一步操作');
  console.log('========================================\n');

  console.log('1. 執行 SQL migration 更新 Supabase trigger:');
  console.log('   - 打開 Supabase SQL Editor');
  console.log('   - 執行文件: supabase/migrations/20251011_update_outbox_trigger_with_user_info.sql');
  console.log('');
  console.log('2. 測試訂單創建/更新，確認 Firestore 同步包含司機/客戶資訊');
  console.log('');
  console.log('3. 在客戶端 APP 和司機端 APP 中測試訂單詳情頁面顯示');
  console.log('');
}

main().catch(console.error);

