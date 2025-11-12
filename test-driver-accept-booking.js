/**
 * 測試司機確認接單 API
 * 
 * 測試流程：
 * 1. 查詢現有的 matched 狀態訂單
 * 2. 調用司機確認接單 API
 * 3. 驗證訂單狀態是否更新為 driver_confirmed
 * 4. 驗證聊天室是否創建成功
 */

const { createClient } = require('@supabase/supabase-js');

// Supabase 配置
const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function testDriverAcceptBooking() {
  console.log('========== 測試司機確認接單 API ==========\n');

  try {
    // 1. 查詢 matched 狀態的訂單
    console.log('1. 查詢 matched 狀態的訂單...');
    const { data: bookings, error: queryError } = await supabase
      .from('bookings')
      .select('*')
      .eq('status', 'matched')
      .limit(1);

    if (queryError) {
      console.error('❌ 查詢訂單失敗:', queryError);
      return;
    }

    if (!bookings || bookings.length === 0) {
      console.log('⚠️ 沒有找到 matched 狀態的訂單');
      console.log('   請先在管理後台配對一個訂單');
      return;
    }

    const booking = bookings[0];
    console.log('✅ 找到訂單:');
    console.log('   - ID:', booking.id);
    console.log('   - 狀態:', booking.status);
    console.log('   - 客戶 ID:', booking.customer_id);
    console.log('   - 司機 ID:', booking.driver_id);
    console.log('');

    // 2. 調用司機確認接單 API
    console.log('2. 調用司機確認接單 API...');
    const response = await fetch(`http://localhost:3000/api/booking-flow/bookings/${booking.id}/accept`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        driverUid: booking.driver_id
      })
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

    // 3. 驗證訂單狀態
    console.log('3. 驗證訂單狀態...');
    const { data: updatedBooking, error: verifyError } = await supabase
      .from('bookings')
      .select('*')
      .eq('id', booking.id)
      .single();

    if (verifyError) {
      console.error('❌ 查詢更新後的訂單失敗:', verifyError);
      return;
    }

    console.log('   訂單狀態:', updatedBooking.status);
    if (updatedBooking.status === 'driver_confirmed') {
      console.log('✅ 訂單狀態已更新為 driver_confirmed');
    } else {
      console.log('❌ 訂單狀態未更新（當前:', updatedBooking.status, '）');
    }
    console.log('');

    // 4. 驗證聊天室
    console.log('4. 驗證聊天室...');
    const { data: chatRooms, error: chatRoomError } = await supabase
      .from('chat_rooms')
      .select('*')
      .eq('booking_id', booking.id);

    if (chatRoomError) {
      console.error('❌ 查詢聊天室失敗:', chatRoomError);
      return;
    }

    if (chatRooms && chatRooms.length > 0) {
      console.log('✅ 聊天室已創建:');
      chatRooms.forEach(room => {
        console.log('   - ID:', room.id);
        console.log('   - 訂單 ID:', room.booking_id);
        console.log('   - 客戶 ID:', room.customer_id);
        console.log('   - 司機 ID:', room.driver_id);
      });
    } else {
      console.log('❌ 聊天室未創建');
    }
    console.log('');

    // 5. 總結
    console.log('========== 測試完成 ==========');
    console.log('');
    console.log('測試結果:');
    console.log('  ✅ API 調用成功');
    console.log('  ' + (updatedBooking.status === 'driver_confirmed' ? '✅' : '❌') + ' 訂單狀態更新');
    console.log('  ' + (chatRooms && chatRooms.length > 0 ? '✅' : '❌') + ' 聊天室創建');

  } catch (error) {
    console.error('❌ 測試失敗:', error);
  }
}

// 執行測試
testDriverAcceptBooking();

