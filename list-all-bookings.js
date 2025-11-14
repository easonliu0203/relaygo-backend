// 列出所有訂單
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function listAllBookings() {
  console.log('========================================');
  console.log('列出所有訂單');
  console.log('========================================');
  
  const { data: bookings, error } = await supabase
    .from('bookings')
    .select('id, booking_number, status, created_at, updated_at')
    .order('created_at', { ascending: false })
    .limit(10);
  
  if (error) {
    console.error('❌ 查詢失敗:', error);
    return;
  }
  
  if (bookings && bookings.length > 0) {
    console.log(`找到 ${bookings.length} 個訂單：`);
    console.log('');
    
    bookings.forEach((booking, index) => {
      console.log(`${index + 1}. ${booking.booking_number}`);
      console.log(`   ID: ${booking.id}`);
      console.log(`   狀態: ${booking.status}`);
      console.log(`   創建: ${booking.created_at}`);
      console.log(`   更新: ${booking.updated_at}`);
      console.log('');
    });
  } else {
    console.log('⚠️  沒有找到任何訂單');
  }
  
  console.log('========================================');
}

listAllBookings().catch(console.error);

