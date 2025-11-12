/**
 * 測試創建訂單 API
 */

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function testCreateBooking() {
  console.log('========== 測試創建訂單 API ==========\n');

  try {
    // 1. 查詢一個客戶
    console.log('1. 查詢客戶...');
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('*')
      .eq('role', 'customer')
      .limit(1);

    if (usersError || !users || users.length === 0) {
      console.error('❌ 查詢客戶失敗:', usersError);
      console.log('   請先在系統中創建一個客戶用戶');
      return;
    }

    const customer = users[0];
    console.log('✅ 找到客戶:');
    console.log('   - Firebase UID:', customer.firebase_uid);
    console.log('   - 姓名:', customer.name);
    console.log('   - Email:', customer.email);
    console.log('');

    // 2. 準備訂單資料
    const bookingData = {
      customerUid: customer.firebase_uid,
      pickupAddress: '台北市信義區市府路1號',
      pickupLatitude: 25.0408,
      pickupLongitude: 121.5674,
      dropoffAddress: '台北市松山區南京東路五段123號',
      dropoffLatitude: 25.0518,
      dropoffLongitude: 121.5527,
      bookingTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 明天
      passengerCount: 2,
      luggageCount: 1,
      notes: '測試訂單',
      packageId: 'standard-8h',
      packageName: '標準 8 小時包車',
      estimatedFare: 3000,
    };

    console.log('2. 調用創建訂單 API...');
    console.log('   請求資料:', JSON.stringify(bookingData, null, 2));
    console.log('');

    const response = await fetch('http://localhost:3000/api/bookings', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(bookingData)
    });

    const result = await response.json();
    console.log('   響應狀態碼:', response.status);
    console.log('   響應內容:', JSON.stringify(result, null, 2));
    console.log('');

    if (!result.success) {
      console.error('❌ API 調用失敗:', result.error);
      return;
    }

    console.log('✅ API 調用成功');
    console.log('');

    // 3. 驗證訂單資料
    const bookingId = result.data.id;
    console.log('3. 驗證訂單資料...');
    const { data: booking, error: verifyError } = await supabase
      .from('bookings')
      .select('*')
      .eq('id', bookingId)
      .single();

    if (verifyError) {
      console.error('❌ 查詢訂單失敗:', verifyError);
      return;
    }

    console.log('✅ 訂單已創建:');
    console.log('   - ID:', booking.id);
    console.log('   - 訂單編號:', booking.booking_number);
    console.log('   - 狀態:', booking.status);
    console.log('   - 客戶 ID:', booking.customer_id);
    console.log('   - 上車地點:', booking.pickup_location);
    console.log('   - 目的地:', booking.destination);
    console.log('   - 預約日期:', booking.start_date);
    console.log('   - 預約時間:', booking.start_time);
    console.log('   - 總金額:', booking.total_amount);
    console.log('   - 訂金:', booking.deposit_amount);
    console.log('');

    // 4. 測試支付訂金 API
    console.log('4. 測試支付訂金 API...');
    const paymentResponse = await fetch(`http://localhost:3000/api/bookings/${bookingId}/pay-deposit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        customerUid: customer.firebase_uid,
        paymentMethod: 'credit_card'
      })
    });

    const paymentResult = await paymentResponse.json();
    console.log('   響應狀態碼:', paymentResponse.status);
    console.log('   響應內容:', JSON.stringify(paymentResult, null, 2));
    console.log('');

    if (!paymentResult.success) {
      console.error('❌ 支付訂金失敗:', paymentResult.error);
      return;
    }

    console.log('✅ 訂金支付成功');
    console.log('');

    // 5. 驗證訂單狀態更新
    console.log('5. 驗證訂單狀態更新...');
    const { data: updatedBooking, error: updateVerifyError } = await supabase
      .from('bookings')
      .select('*')
      .eq('id', bookingId)
      .single();

    if (updateVerifyError) {
      console.error('❌ 查詢更新後的訂單失敗:', updateVerifyError);
      return;
    }

    console.log('   訂單狀態:', updatedBooking.status);
    if (updatedBooking.status === 'paid_deposit') {
      console.log('✅ 訂單狀態已更新為 paid_deposit');
    } else {
      console.log('❌ 訂單狀態未更新（當前:', updatedBooking.status, '）');
    }
    console.log('');

    // 6. 總結
    console.log('========== 測試完成 ==========');
    console.log('');
    console.log('測試結果:');
    console.log('  ✅ 創建訂單 API 調用成功');
    console.log('  ✅ 訂單資料寫入 Supabase');
    console.log('  ✅ 支付訂金 API 調用成功');
    console.log('  ' + (updatedBooking.status === 'paid_deposit' ? '✅' : '❌') + ' 訂單狀態更新');
    console.log('');
    console.log('創建的訂單 ID:', bookingId);

  } catch (error) {
    console.error('❌ 測試失敗:', error);
  }
}

// 執行測試
testCreateBooking();

