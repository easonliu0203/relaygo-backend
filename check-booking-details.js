// 檢查訂單詳細資訊
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function checkBookingDetails() {
  const bookingId = '9144d669-8c84-4484-8be1-cced0040a32b';
  
  console.log('========================================');
  console.log('檢查訂單詳細資訊');
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
    return;
  }
  
  console.log('訂單資訊:');
  console.log('  booking_number:', booking.booking_number);
  console.log('  status:', booking.status);
  console.log('  total_price:', booking.total_price);
  console.log('  deposit_amount:', booking.deposit_amount);
  console.log('  balance_amount:', booking.balance_amount);
  console.log('  created_at:', booking.created_at);
  console.log('  updated_at:', booking.updated_at);
  console.log('');
  console.log('========================================');
}

checkBookingDetails().catch(console.error);

