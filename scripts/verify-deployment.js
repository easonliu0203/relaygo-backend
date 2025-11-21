#!/usr/bin/env node

/**
 * 驗證即時同步部署狀態
 * 使用 Supabase JavaScript 客戶端
 */

const { createClient } = require('@supabase/supabase-js');

// Supabase 配置
const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ 錯誤: 未設置 SUPABASE_SERVICE_ROLE_KEY 環境變數');
  console.error('');
  console.error('請從 Supabase Dashboard > Settings > API 獲取 Service Role Key');
  console.error('然後設置環境變數:');
  console.error('  set SUPABASE_SERVICE_ROLE_KEY=your_key_here');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function verifyDeployment() {
  console.log('========================================');
  console.log('即時同步部署驗證');
  console.log('========================================');
  console.log('');

  try {
    // 檢查 1: Trigger Function
    console.log('[1/6] 檢查 Trigger Function...');
    const { data: funcData, error: funcError } = await supabase
      .rpc('exec_sql', {
        query: `
          SELECT proname 
          FROM pg_proc 
          WHERE proname = 'notify_edge_function_realtime'
        `
      });
    
    if (funcError) {
      console.log('   ⚠️  無法檢查（可能需要手動驗證）');
    } else if (funcData && funcData.length > 0) {
      console.log('   ✅ Trigger Function 存在');
    } else {
      console.log('   ❌ Trigger Function 不存在');
    }

    // 檢查 2: 配置
    console.log('[2/6] 檢查配置...');
    const { data: configData, error: configError } = await supabase
      .from('system_settings')
      .select('*')
      .eq('key', 'realtime_sync_config')
      .single();
    
    if (configError) {
      console.log('   ❌ 配置不存在:', configError.message);
    } else {
      console.log('   ✅ 配置已創建');
      console.log('   📋 配置內容:', JSON.stringify(configData.value, null, 2));
    }

    // 檢查 3: pg_net 擴展
    console.log('[3/6] 檢查 pg_net 擴展...');
    console.log('   ⚠️  需要手動檢查（訪問 Dashboard > Database > Extensions）');

    // 檢查 4: Edge Function
    console.log('[4/6] 檢查 Edge Function...');
    console.log('   ⚠️  需要手動檢查（訪問 Dashboard > Edge Functions）');

    // 檢查 5: Cron Job
    console.log('[5/6] 檢查 Cron Job...');
    console.log('   ⚠️  需要手動檢查（執行 SQL: SELECT * FROM cron.job）');

    // 檢查 6: Outbox 表
    console.log('[6/6] 檢查 Outbox 表...');
    const { data: outboxData, error: outboxError } = await supabase
      .from('outbox')
      .select('id, created_at, processed_at')
      .order('created_at', { ascending: false })
      .limit(5);
    
    if (outboxError) {
      console.log('   ❌ Outbox 表不存在或無法訪問:', outboxError.message);
    } else {
      console.log(`   ✅ Outbox 表存在（最近 ${outboxData.length} 條記錄）`);
      const pending = outboxData.filter(r => !r.processed_at).length;
      const processed = outboxData.filter(r => r.processed_at).length;
      console.log(`   📊 待處理: ${pending}, 已處理: ${processed}`);
    }

    console.log('');
    console.log('========================================');
    console.log('驗證完成');
    console.log('========================================');

  } catch (error) {
    console.error('❌ 驗證過程中發生錯誤:', error.message);
    process.exit(1);
  }
}

verifyDeployment();

