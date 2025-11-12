const API_BASE_URL = 'http://localhost:3001';

// 測試帳號 ID（需要從列表 API 獲取）
let customerTestId = null;
let driverTestId = null;

async function getTestAccountIds() {
  console.log('========================================');
  console.log('步驟 1: 獲取測試帳號 ID');
  console.log('========================================\n');

  try {
    // 獲取客戶列表
    const customersResponse = await fetch(`${API_BASE_URL}/api/admin/customers`);
    const customersData = await customersResponse.json();
    
    const testCustomer = customersData.data?.find(c => c.email === 'customer.test@relaygo.com');
    if (testCustomer) {
      customerTestId = testCustomer.id;
      console.log(`✅ 找到客戶測試帳號 ID: ${customerTestId}`);
      console.log(`   Email: ${testCustomer.email}`);
      console.log(`   姓名: ${testCustomer.name}\n`);
    } else {
      console.log('❌ 未找到客戶測試帳號\n');
    }

    // 獲取司機列表
    const driversResponse = await fetch(`${API_BASE_URL}/api/admin/drivers`);
    const driversData = await driversResponse.json();
    
    const testDriver = driversData.data?.find(d => d.email === 'driver.test@relaygo.com');
    if (testDriver) {
      driverTestId = testDriver.id;
      console.log(`✅ 找到司機測試帳號 ID: ${driverTestId}`);
      console.log(`   Email: ${testDriver.email}`);
      console.log(`   姓名: ${testDriver.name}\n`);
    } else {
      console.log('❌ 未找到司機測試帳號\n');
    }

  } catch (error) {
    console.error('❌ 獲取測試帳號 ID 失敗:', error.message);
  }
}

async function testCustomerDetail() {
  console.log('========================================');
  console.log('測試 2: 獲取客戶詳情');
  console.log('========================================\n');

  if (!customerTestId) {
    console.log('⚠️ 跳過測試：未找到客戶測試帳號 ID\n');
    return;
  }

  try {
    const url = `${API_BASE_URL}/api/admin/customers/${customerTestId}`;
    console.log(`URL: ${url}\n`);

    const response = await fetch(url);
    console.log(`響應狀態碼: ${response.status}\n`);

    if (!response.ok) {
      const errorText = await response.text();
      console.log(`❌ 請求失敗: ${errorText}\n`);
      return;
    }

    const data = await response.json();

    if (data.success) {
      console.log('✅ 客戶詳情獲取成功\n');
      console.log('客戶資訊:');
      console.log(`   ID: ${data.data.id}`);
      console.log(`   Email: ${data.data.email}`);
      console.log(`   姓名: ${data.data.name}`);
      console.log(`   電話: ${data.data.phone || '未設定'}`);
      console.log(`   狀態: ${data.data.status}`);
      console.log(`   VIP 等級: ${data.data.vipLevel}`);
      console.log(`   總訂單數: ${data.data.totalOrders}`);
      console.log(`   完成訂單數: ${data.data.completedOrders}`);
      console.log(`   總消費: ${data.data.totalSpent}`);
      console.log(`   最後訂單日期: ${data.data.lastOrderDate || '無'}`);
      console.log(`   註冊日期: ${data.data.joinedDate}\n`);

      console.log('完整資料:');
      console.log(JSON.stringify(data.data, null, 2));
      console.log('\n');
    } else {
      console.log(`❌ 獲取失敗: ${data.error}\n`);
    }

  } catch (error) {
    console.error('❌ 測試失敗:', error.message);
    console.error(error.stack);
    console.log('\n');
  }
}

async function testDriverDetail() {
  console.log('========================================');
  console.log('測試 3: 獲取司機詳情');
  console.log('========================================\n');

  if (!driverTestId) {
    console.log('⚠️ 跳過測試：未找到司機測試帳號 ID\n');
    return;
  }

  try {
    const url = `${API_BASE_URL}/api/admin/drivers/${driverTestId}`;
    console.log(`URL: ${url}\n`);

    const response = await fetch(url);
    console.log(`響應狀態碼: ${response.status}\n`);

    if (!response.ok) {
      const errorText = await response.text();
      console.log(`❌ 請求失敗: ${errorText}\n`);
      return;
    }

    const data = await response.json();

    if (data.success) {
      console.log('✅ 司機詳情獲取成功\n');
      console.log('司機資訊:');
      console.log(`   ID: ${data.data.id}`);
      console.log(`   Email: ${data.data.email}`);
      console.log(`   姓名: ${data.data.name}`);
      console.log(`   電話: ${data.data.phone || '未設定'}`);
      console.log(`   狀態: ${data.data.status}`);
      console.log(`   駕照號碼: ${data.data.licenseNumber}`);
      console.log(`   車型: ${data.data.vehicleType}`);
      console.log(`   車牌: ${data.data.vehiclePlate}`);
      console.log(`   車輛型號: ${data.data.vehicleModel || '未設定'}`);
      console.log(`   是否可用: ${data.data.isAvailable ? '是' : '否'}`);
      console.log(`   背景審核狀態: ${data.data.backgroundCheckStatus}`);
      console.log(`   評分: ${data.data.rating}`);
      console.log(`   總行程數: ${data.data.totalTrips}`);
      console.log(`   完成行程數: ${data.data.completedTrips}`);
      console.log(`   總收入: ${data.data.totalRevenue}`);
      console.log(`   加入日期: ${data.data.joinedDate}\n`);

      console.log('完整資料:');
      console.log(JSON.stringify(data.data, null, 2));
      console.log('\n');
    } else {
      console.log(`❌ 獲取失敗: ${data.error}\n`);
    }

  } catch (error) {
    console.error('❌ 測試失敗:', error.message);
    console.error(error.stack);
    console.log('\n');
  }
}

async function runTests() {
  console.log('\n');
  console.log('========================================');
  console.log('公司端詳情 API 測試工具');
  console.log('========================================\n');

  await getTestAccountIds();
  await testCustomerDetail();
  await testDriverDetail();

  console.log('========================================');
  console.log('測試完成！');
  console.log('========================================\n');
}

runTests();

