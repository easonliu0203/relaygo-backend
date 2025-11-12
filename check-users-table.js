const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function checkUsersTable() {
  console.log('========== 檢查 users 表 ==========\n');

  // 查詢所有用戶
  const { data: users, error } = await supabase
    .from('users')
    .select('*')
    .limit(5);

  if (error) {
    console.error('❌ 查詢失敗:', error);
    return;
  }

  if (!users || users.length === 0) {
    console.log('⚠️ users 表中沒有資料');
    return;
  }

  console.log(`✅ 找到 ${users.length} 個用戶\n`);

  users.forEach((user, index) => {
    console.log(`用戶 ${index + 1}:`);
    console.log('  欄位:', Object.keys(user));
    console.log('  資料:', user);
    console.log('');
  });
}

checkUsersTable();

