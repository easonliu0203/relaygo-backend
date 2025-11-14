// 測試訂單查詢
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function testQuery() {
  console.log('========================================');
  console.log('測試訂單查詢');
  console.log('========================================');
  
  const e_orderno = '1d02b271d3a24db1B78747097';
  const bookingId = e_orderno.substring(0, 16); // 前16字符
  const bookingIdPattern = bookingId.replace(/(.{8})(.{4})(.{4})/, '$1-$2-$3-');
  
  console.log('訂單編號:', e_orderno);
  console.log('bookingId (16字符):', bookingId);
  console.log('查詢模式:', bookingIdPattern + '%');
  console.log('');
  
  // 測試查詢 - 查詢所有訂單並在應用層過濾
  console.log('執行查詢（查詢所有訂單）...');
  const { data: allBookings, error } = await supabase
    .from('bookings')
    .select('*');

  if (error) {
    console.log('❌ 查詢失敗');
    console.log('錯誤:', error);
  } else if (allBookings && allBookings.length > 0) {
    console.log(`✅ 查詢成功，找到 ${allBookings.length} 個訂單`);

    // 在應用層過濾
    const matchedBooking = allBookings.find(b => b.id.startsWith(bookingIdPattern));

    if (matchedBooking) {
      console.log('✅ 找到匹配的訂單');
      console.log('訂單 ID:', matchedBooking.id);
      console.log('訂單狀態:', matchedBooking.status);
      console.log('客戶 ID:', matchedBooking.customer_id);
    } else {
      console.log('⚠️  沒有找到匹配的訂單');
      console.log('前5個訂單 ID:');
      allBookings.slice(0, 5).forEach(b => console.log('  -', b.id));
    }
  } else {
    console.log('⚠️  資料庫中沒有任何訂單');
  }
  
  console.log('');
  console.log('========================================');
}

testQuery().catch(console.error);

