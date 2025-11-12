/**
 * 執行 Supabase Migration
 * 用於修復缺少的資料庫欄位
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Supabase 配置
const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

async function runMigration() {
  console.log('🚀 開始執行 Migration...\n');

  // 創建 Supabase 客戶端（使用 service_role key 以獲得完整權限）
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  });

  try {
    // 讀取 migration 文件
    const migrationPath = path.join(__dirname, '..', 'supabase', 'migrations', '20250103_fix_missing_fields.sql');
    console.log(`📄 讀取 Migration 文件: ${migrationPath}`);
    
    const sql = fs.readFileSync(migrationPath, 'utf8');
    console.log(`✅ Migration 文件讀取成功 (${sql.length} 字元)\n`);

    // 執行 SQL
    console.log('⚙️  執行 SQL...');
    const { data, error } = await supabase.rpc('exec_sql', { sql_query: sql });

    if (error) {
      console.error('❌ Migration 執行失敗:', error);
      
      // 如果 exec_sql 函數不存在，嘗試直接執行
      console.log('\n⚠️  嘗試使用替代方法...');
      await runMigrationDirect(supabase, sql);
    } else {
      console.log('✅ Migration 執行成功!');
      if (data) {
        console.log('📊 結果:', data);
      }
    }

    // 驗證欄位是否存在
    console.log('\n🔍 驗證資料庫結構...');
    await verifyColumns(supabase);

  } catch (error) {
    console.error('❌ 發生錯誤:', error);
    process.exit(1);
  }
}

async function runMigrationDirect(supabase, sql) {
  // 將 SQL 分割成多個語句
  const statements = sql
    .split(';')
    .map(s => s.trim())
    .filter(s => s.length > 0 && !s.startsWith('--'));

  console.log(`📝 找到 ${statements.length} 個 SQL 語句\n`);

  for (let i = 0; i < statements.length; i++) {
    const statement = statements[i];
    if (statement.length === 0) continue;

    console.log(`執行語句 ${i + 1}/${statements.length}...`);
    
    try {
      // 使用 from() 和 select() 來執行 SQL（這是一個 workaround）
      // 實際上我們需要使用 Supabase Dashboard 或 psql 來執行 DDL 語句
      console.log(`⚠️  無法直接執行 DDL 語句，請使用 Supabase Dashboard 執行`);
      break;
    } catch (error) {
      console.error(`❌ 語句 ${i + 1} 執行失敗:`, error.message);
    }
  }
}

async function verifyColumns(supabase) {
  try {
    // 查詢 bookings 表的結構
    const { data, error } = await supabase
      .from('bookings')
      .select('*')
      .limit(1);

    if (error) {
      console.error('❌ 無法查詢 bookings 表:', error);
      return;
    }

    if (data && data.length > 0) {
      const columns = Object.keys(data[0]);
      console.log('📋 bookings 表的欄位:');
      columns.forEach(col => console.log(`  - ${col}`));

      // 檢查必要的欄位
      const hasCancel = columns.includes('cancellation_reason');
      const hasCancelledAt = columns.includes('cancelled_at');

      console.log('\n✅ 驗證結果:');
      console.log(`  - cancellation_reason: ${hasCancel ? '✅ 存在' : '❌ 缺少'}`);
      console.log(`  - cancelled_at: ${hasCancelledAt ? '✅ 存在' : '❌ 缺少'}`);

      if (hasCancel && hasCancelledAt) {
        console.log('\n🎉 所有必要欄位都已存在！');
      } else {
        console.log('\n⚠️  仍有欄位缺少，請手動執行 Migration');
      }
    } else {
      console.log('⚠️  bookings 表為空，無法驗證欄位');
    }
  } catch (error) {
    console.error('❌ 驗證失敗:', error);
  }
}

// 執行
runMigration().then(() => {
  console.log('\n✅ 完成');
  process.exit(0);
}).catch(error => {
  console.error('\n❌ 失敗:', error);
  process.exit(1);
});

