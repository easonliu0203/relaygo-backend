const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function checkBookingIds() {
  console.log('========== 檢查訂單 ID 格式 ==========\n');

  const { data: bookings, error } = await supabase
    .from('bookings')
    .select('id, customer_id, driver_id')
    .limit(3);

  if (error) {
    console.error('❌ 查詢失敗:', error);
    return;
  }

  if (!bookings || bookings.length === 0) {
    console.log('⚠️ 沒有訂單資料');
    return;
  }

  console.log(`✅ 找到 ${bookings.length} 個訂單\n`);

  bookings.forEach((booking, index) => {
    console.log(`訂單 ${index + 1}:`);
    console.log('  ID:', booking.id);
    console.log('  Customer ID:', booking.customer_id);
    console.log('  Driver ID:', booking.driver_id);
    console.log('');
  });

  // 檢查這些 ID 是否是 Firebase UID
  console.log('檢查 customer_id 是否為 Firebase UID...');
  const customerId = bookings[0].customer_id;
  const { data: customer } = await supabase
    .from('users')
    .select('*')
    .eq('firebase_uid', customerId)
    .single();

  if (customer) {
    console.log('✅ customer_id 是 Firebase UID');
    console.log('   對應的用戶:', customer);
  } else {
    console.log('❌ customer_id 不是 Firebase UID，可能是 users.id');
    
    // 嘗試用 users.id 查詢
    const { data: customerById } = await supabase
      .from('users')
      .select('*')
      .eq('id', customerId)
      .single();
    
    if (customerById) {
      console.log('✅ customer_id 是 users.id');
      console.log('   對應的用戶:', customerById);
    }
  }
}

checkBookingIds();

