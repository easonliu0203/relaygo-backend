/**
 * 更新司機測試帳號的 drivers 記錄
 * 
 * 用途：為已存在的司機測試帳號創建或更新 drivers 記錄
 */

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

async function main() {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  console.log('查找司機測試帳號...');
  
  // 查找司機測試帳號
  const { data: driverUser, error: userError } = await supabase
    .from('users')
    .select('*')
    .eq('email', 'driver.test@relaygo.com')
    .single();

  if (userError || !driverUser) {
    console.error('❌ 找不到司機測試帳號');
    return;
  }

  console.log('✅ 找到司機測試帳號:', driverUser.id);

  // 檢查是否已有 drivers 記錄
  const { data: existingDriver } = await supabase
    .from('drivers')
    .select('*')
    .eq('user_id', driverUser.id)
    .single();

  if (existingDriver) {
    console.log('✅ drivers 記錄已存在');
    console.log('   車牌:', existingDriver.vehicle_plate);
    console.log('   車型:', existingDriver.vehicle_type);
    return;
  }

  console.log('創建 drivers 記錄...');

  // 創建 drivers 記錄
  const { data: newDriver, error: driverError } = await supabase
    .from('drivers')
    .insert({
      user_id: driverUser.id,
      license_number: 'TEST-DRIVER-001',
      license_expiry: '2025-12-31',
      vehicle_type: 'A',
      vehicle_plate: 'TEST-DRIVER-001',
      vehicle_model: 'Toyota Alphard',
      vehicle_year: 2023,
      is_available: true,
      background_check_status: 'approved',
      rating: 5.0,
      total_trips: 0,
    })
    .select()
    .single();

  if (driverError) {
    console.error('❌ 創建 drivers 記錄失敗:', driverError.message);
    return;
  }

  console.log('✅ 創建 drivers 記錄成功');
  console.log('   車牌:', newDriver.vehicle_plate);
  console.log('   車型:', newDriver.vehicle_type);
}

main();

