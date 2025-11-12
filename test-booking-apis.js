const API_BASE_URL = 'http://localhost:3001';

async function testBookingsList() {
  console.log('========================================');
  console.log('測試 1: 獲取訂單列表');
  console.log('========================================\n');

  try {
    const url = `${API_BASE_URL}/api/admin/bookings`;
    console.log(`URL: ${url}\n`);

    const response = await fetch(url);
    console.log(`響應狀態碼: ${response.status}\n`);

    if (!response.ok) {
      const errorText = await response.text();
      console.log(`❌ 請求失敗: ${errorText}\n`);
      return null;
    }

    const data = await response.json();

    if (data.success) {
      console.log('✅ 訂單列表獲取成功\n');
      console.log(`總數: ${data.total}`);
      console.log(`返回數量: ${data.data?.length || 0}\n`);

      if (data.data && data.data.length > 0) {
        console.log('第一筆訂單資訊:');
        const firstBooking = data.data[0];
        console.log(`   訂單 ID: ${firstBooking.id}`);
        console.log(`   訂單編號: ${firstBooking.bookingNumber}`);
        console.log(`   狀態: ${firstBooking.status}`);
        console.log(`   客戶姓名: ${firstBooking.customer?.name || '未知'}`);
        console.log(`   客戶電話: ${firstBooking.customer?.phone || '未知'}`);
        console.log(`   司機姓名: ${firstBooking.driver?.name || '未配對'}`);
        console.log(`   司機電話: ${firstBooking.driver?.phone || '未配對'}`);
        console.log(`   上車地點: ${firstBooking.pickupLocation}`);
        console.log(`   下車地點: ${firstBooking.dropoffLocation}\n`);

        return firstBooking.id; // 返回第一筆訂單 ID 用於詳情測試
      } else {
        console.log('⚠️ 沒有訂單資料\n');
        return null;
      }
    } else {
      console.log(`❌ 獲取失敗: ${data.error}\n`);
      return null;
    }

  } catch (error) {
    console.error('❌ 測試失敗:', error.message);
    console.error(error.stack);
    console.log('\n');
    return null;
  }
}

async function testBookingDetail(bookingId) {
  console.log('========================================');
  console.log('測試 2: 獲取訂單詳情');
  console.log('========================================\n');

  if (!bookingId) {
    console.log('⚠️ 跳過測試：沒有訂單 ID\n');
    return;
  }

  try {
    const url = `${API_BASE_URL}/api/admin/bookings/${bookingId}`;
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
      console.log('✅ 訂單詳情獲取成功\n');
      console.log('訂單資訊:');
      console.log(`   訂單 ID: ${data.data.id}`);
      console.log(`   訂單編號: ${data.data.bookingNumber}`);
      console.log(`   狀態: ${data.data.status}`);
      console.log(`   車型: ${data.data.vehicleType}\n`);

      console.log('客戶資訊:');
      console.log(`   姓名: ${data.data.customer?.name || '未知'}`);
      console.log(`   Email: ${data.data.customer?.email || '未知'}`);
      console.log(`   電話: ${data.data.customer?.phone || '未知'}\n`);

      if (data.data.driver) {
        console.log('司機資訊:');
        console.log(`   姓名: ${data.data.driver.name}`);
        console.log(`   Email: ${data.data.driver.email}`);
        console.log(`   電話: ${data.data.driver.phone}`);
        console.log(`   車型: ${data.data.driver.vehicleType}`);
        console.log(`   車牌: ${data.data.driver.vehiclePlate}`);
        console.log(`   評分: ${data.data.driver.rating}\n`);
      } else {
        console.log('司機資訊: 未配對\n');
      }

      console.log('行程資訊:');
      console.log(`   上車地點: ${data.data.pickupLocation}`);
      console.log(`   下車地點: ${data.data.dropoffLocation}`);
      console.log(`   預定日期: ${data.data.scheduledDate}`);
      console.log(`   預定時間: ${data.data.scheduledTime}`);
      console.log(`   時長: ${data.data.durationHours} 小時`);
      console.log(`   乘客數: ${data.data.passengerCount}`);
      console.log(`   行李數: ${data.data.luggageCount}\n`);

      console.log('價格資訊:');
      console.log(`   總金額: NT$ ${data.data.pricing?.totalAmount || 0}`);
      console.log(`   訂金: NT$ ${data.data.pricing?.depositAmount || 0}`);
      console.log(`   基本價格: NT$ ${data.data.pricing?.basePrice || 0}\n`);

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
  console.log('公司端訂單 API 測試工具');
  console.log('========================================\n');

  const bookingId = await testBookingsList();
  await testBookingDetail(bookingId);

  console.log('========================================');
  console.log('測試完成！');
  console.log('========================================\n');
}

runTests();

