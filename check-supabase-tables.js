/**
 * 檢查 Supabase 表結構
 */

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function checkTables() {
  console.log('========== 檢查 Supabase 表結構 ==========\n');

  // 檢查 chat_messages 表
  console.log('1. 檢查 chat_messages 表...');
  const { data: messages, error: messagesError } = await supabase
    .from('chat_messages')
    .select('*')
    .limit(1);

  if (messagesError) {
    console.log('❌ chat_messages 表不存在或查詢失敗:', messagesError.message);
  } else {
    console.log('✅ chat_messages 表存在');
    if (messages && messages.length > 0) {
      console.log('   示例記錄:', messages[0]);
    }
  }
  console.log('');

  // 檢查 bookings 表
  console.log('2. 檢查 bookings 表...');
  const { data: bookings, error: bookingsError } = await supabase
    .from('bookings')
    .select('*')
    .limit(1);

  if (bookingsError) {
    console.log('❌ bookings 表不存在或查詢失敗:', bookingsError.message);
  } else {
    console.log('✅ bookings 表存在');
    if (bookings && bookings.length > 0) {
      console.log('   示例記錄欄位:', Object.keys(bookings[0]));
    }
  }
  console.log('');

  // 檢查 outbox 表
  console.log('3. 檢查 outbox 表...');
  const { data: outbox, error: outboxError } = await supabase
    .from('outbox')
    .select('*')
    .limit(1);

  if (outboxError) {
    console.log('❌ outbox 表不存在或查詢失敗:', outboxError.message);
  } else {
    console.log('✅ outbox 表存在');
    if (outbox && outbox.length > 0) {
      console.log('   示例記錄欄位:', Object.keys(outbox[0]));
    }
  }
  console.log('');

  console.log('========== 檢查完成 ==========');
}

checkTables();

