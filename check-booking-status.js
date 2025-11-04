// 檢查訂單狀態
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function checkBookingStatus() {
  const bookingId = '9144d669-8c84-4484-8be1-cced0040a32b';
  
  console.log('========================================');
  console.log('檢查訂單狀態');
  console.log('========================================');
  console.log('訂單 ID:', bookingId);
  console.log('');
  
  const { data: booking, error } = await supabase
    .from('bookings')
    .select('*')
    .eq('id', bookingId)
    .single();
  
  if (error) {
    console.error('❌ 查詢失敗:', error);
  } else if (booking) {
    console.log('✅ 訂單狀態:', booking.status);
    console.log('更新時間:', booking.updated_at);
  } else {
    console.log('⚠️  訂單不存在');
  }
  
  console.log('========================================');
}

checkBookingStatus().catch(console.error);

