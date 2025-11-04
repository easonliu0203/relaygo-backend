// 檢查 Outbox 同步狀態
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function checkOutboxSync() {
  const bookingId = '9144d669-8c84-4484-8be1-cced0040a32b';
  
  console.log('========================================');
  console.log('檢查 Outbox 同步狀態');
  console.log('========================================');
  console.log('訂單 ID:', bookingId);
  console.log('');
  
  // 1. 查詢訂單當前狀態
  const { data: booking, error: bookingError } = await supabase
    .from('bookings')
    .select('*')
    .eq('id', bookingId)
    .single();
  
  if (bookingError) {
    console.error('❌ 查詢訂單失敗:', bookingError);
    return;
  }
  
  console.log('📊 訂單狀態:', booking.status);
  console.log('更新時間:', booking.updated_at);
  console.log('');
  
  // 2. 查詢 Outbox 事件
  const { data: events, error: eventsError } = await supabase
    .from('outbox')
    .select('*')
    .eq('aggregate_id', bookingId)
    .order('created_at', { ascending: false })
    .limit(10);
  
  if (eventsError) {
    console.error('❌ 查詢 Outbox 失敗:', eventsError);
    return;
  }
  
  console.log(`📋 找到 ${events.length} 個 Outbox 事件：`);
  console.log('');
  
  events.forEach((event, index) => {
    const status = event.payload?.status || 'N/A';
    const processed = event.processed_at ? '✅ 已處理' : '⏳ 未處理';
    const error = event.error_message ? `❌ ${event.error_message}` : '';
    
    console.log(`事件 ${index + 1}:`);
    console.log(`  ID: ${event.id}`);
    console.log(`  類型: ${event.event_type}`);
    console.log(`  狀態: ${status}`);
    console.log(`  創建時間: ${event.created_at}`);
    console.log(`  處理時間: ${event.processed_at || '未處理'}`);
    console.log(`  處理狀態: ${processed}`);
    if (error) {
      console.log(`  錯誤: ${error}`);
    }
    console.log('');
  });
  
  // 3. 檢查最新事件是否已處理
  if (events.length > 0) {
    const latestEvent = events[0];
    const latestStatus = latestEvent.payload?.status;
    
    console.log('========================================');
    console.log('📊 同步狀態總結');
    console.log('========================================');
    console.log('訂單當前狀態:', booking.status);
    console.log('最新事件狀態:', latestStatus);
    console.log('最新事件處理:', latestEvent.processed_at ? '✅ 已處理' : '⏳ 未處理');
    
    if (latestStatus === booking.status && latestEvent.processed_at) {
      console.log('');
      console.log('✅ 同步正常！訂單狀態與最新事件一致，且已處理');
    } else if (latestStatus !== booking.status) {
      console.log('');
      console.log('⚠️  狀態不一致！訂單狀態與最新事件不一致');
      console.log('可能原因：訂單狀態更新後，Outbox 事件尚未創建');
    } else if (!latestEvent.processed_at) {
      console.log('');
      console.log('⏳ 等待處理！最新事件尚未同步到 Firestore');
      console.log('請等待 Edge Function 處理（通常在 1 分鐘內）');
    }
  } else {
    console.log('⚠️  沒有找到任何 Outbox 事件');
  }
  
  console.log('========================================');
}

checkOutboxSync().catch(console.error);

