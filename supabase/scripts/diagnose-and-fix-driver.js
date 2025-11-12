/**
 * 診斷並修復測試司機帳號
 *
 * 使用方法:
 * cd web-admin && node ../supabase/scripts/diagnose-and-fix-driver.js
 */

const { createClient } = require('../../web-admin/node_modules/@supabase/supabase-js');

// Supabase 配置
const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

const TEST_DRIVER_EMAIL = 'driver.test@gelaygo.com';

// 創建 Supabase 客戶端
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function diagnoseDriver() {
  console.log('\n=== 開始診斷測試司機帳號 ===\n');

  // 1. 檢查用戶是否存在
  console.log('1️⃣ 檢查用戶是否存在...');
  const { data: user, error: userError } = await supabase
    .from('users')
    .select('id, email, role, created_at')
    .eq('email', TEST_DRIVER_EMAIL)
    .single();

  if (userError || !user) {
    console.log('❌ 用戶不存在:', TEST_DRIVER_EMAIL);
    console.log('   錯誤:', userError?.message);
    return null;
  }

  console.log('✅ 用戶存在:');
  console.log('   ID:', user.id);
  console.log('   Email:', user.email);
  console.log('   Role:', user.role);
  console.log('   Created:', user.created_at);

  // 2. 檢查 user_profiles
  console.log('\n2️⃣ 檢查 user_profiles...');
  const { data: profile, error: profileError } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('user_id', user.id)
    .single();

  if (profileError || !profile) {
    console.log('❌ user_profile 不存在');
    console.log('   錯誤:', profileError?.message);
  } else {
    console.log('✅ user_profile 存在:');
    console.log('   姓名:', profile.first_name, profile.last_name);
    console.log('   電話:', profile.phone);
  }

  // 3. 檢查 drivers
  console.log('\n3️⃣ 檢查 drivers...');
  const { data: driver, error: driverError } = await supabase
    .from('drivers')
    .select('*')
    .eq('user_id', user.id)
    .single();

  if (driverError || !driver) {
    console.log('❌ driver 記錄不存在');
    console.log('   錯誤:', driverError?.message);
  } else {
    console.log('✅ driver 記錄存在:');
    console.log('   車型:', driver.vehicle_type);
    console.log('   車牌:', driver.vehicle_plate);
    console.log('   車款:', driver.vehicle_model);
    console.log('   可用:', driver.is_available);
    console.log('   評分:', driver.rating);
    console.log('   總趟次:', driver.total_trips);
  }

  // 4. 檢查所有司機
  console.log('\n4️⃣ 檢查所有司機角色的用戶...');
  const { data: allDrivers, error: allDriversError } = await supabase
    .from('users')
    .select(`
      id,
      email,
      role,
      user_profiles!user_id (first_name, last_name),
      drivers!user_id (vehicle_type, is_available)
    `)
    .eq('role', 'driver');

  if (allDriversError) {
    console.log('❌ 查詢失敗:', allDriversError.message);
  } else {
    console.log(`✅ 找到 ${allDrivers?.length || 0} 位司機角色的用戶`);
    allDrivers?.forEach((d, i) => {
      const driverInfo = d.drivers?.[0] || d.drivers;
      const profileInfo = d.user_profiles?.[0] || d.user_profiles;
      console.log(`   ${i + 1}. ${d.email}`);
      console.log(`      - 有 profile: ${!!profileInfo}`);
      console.log(`      - 有 driver: ${!!driverInfo}`);
      console.log(`      - 可用: ${driverInfo?.is_available}`);
      console.log(`      - 車型: ${driverInfo?.vehicle_type}`);
    });
  }

  return { user, profile, driver };
}

async function fixDriver() {
  console.log('\n=== 開始修復測試司機帳號 ===\n');

  // 1. 獲取或創建用戶
  console.log('1️⃣ 檢查用戶...');
  let { data: user, error: userError } = await supabase
    .from('users')
    .select('id, email, role')
    .eq('email', TEST_DRIVER_EMAIL)
    .single();

  if (userError || !user) {
    console.log('❌ 用戶不存在，無法自動創建');
    console.log('   請先在系統中創建用戶:', TEST_DRIVER_EMAIL);
    return false;
  }

  console.log('✅ 用戶存在:', user.id);

  // 確保角色為 driver
  if (user.role !== 'driver') {
    console.log('⚠️  用戶角色不是 driver，正在更新...');
    const { error: updateError } = await supabase
      .from('users')
      .update({ role: 'driver' })
      .eq('id', user.id);

    if (updateError) {
      console.log('❌ 更新角色失敗:', updateError.message);
      return false;
    }
    console.log('✅ 已更新角色為 driver');
  }

  // 2. 創建或更新 user_profiles
  console.log('\n2️⃣ 處理 user_profiles...');
  let { data: profile } = await supabase
    .from('user_profiles')
    .select('id')
    .eq('user_id', user.id)
    .single();

  if (!profile) {
    console.log('⚠️  user_profile 不存在，正在創建...');
    const { data: newProfile, error: createError } = await supabase
      .from('user_profiles')
      .insert({
        user_id: user.id,
        first_name: '測試',
        last_name: '司機',
        phone: '0912345678'
      })
      .select()
      .single();

    if (createError) {
      console.log('❌ 創建 user_profile 失敗:', createError.message);
      return false;
    }
    console.log('✅ 已創建 user_profile:', newProfile.id);
  } else {
    console.log('✅ user_profile 已存在，正在更新...');
    const { error: updateError } = await supabase
      .from('user_profiles')
      .update({
        first_name: '測試',
        last_name: '司機',
        phone: '0912345678'
      })
      .eq('user_id', user.id);

    if (updateError) {
      console.log('❌ 更新 user_profile 失敗:', updateError.message);
    } else {
      console.log('✅ 已更新 user_profile');
    }
  }

  // 3. 創建或更新 drivers
  console.log('\n3️⃣ 處理 drivers...');
  let { data: driver } = await supabase
    .from('drivers')
    .select('id')
    .eq('user_id', user.id)
    .single();

  if (!driver) {
    console.log('⚠️  driver 記錄不存在，正在創建...');
    const { data: newDriver, error: createError } = await supabase
      .from('drivers')
      .insert({
        user_id: user.id,
        license_number: 'TEST-LICENSE-001',
        vehicle_type: 'A',
        vehicle_plate: 'TEST-001',
        vehicle_model: 'Toyota Alphard',
        is_available: true,
        rating: 5.0,
        total_trips: 0
      })
      .select()
      .single();

    if (createError) {
      console.log('❌ 創建 driver 失敗:', createError.message);
      return false;
    }
    console.log('✅ 已創建 driver 記錄:', newDriver.id);
  } else {
    console.log('✅ driver 記錄已存在，正在更新...');
    const { error: updateError } = await supabase
      .from('drivers')
      .update({
        license_number: 'TEST-LICENSE-001',
        vehicle_type: 'A',
        vehicle_plate: 'TEST-001',
        vehicle_model: 'Toyota Alphard',
        is_available: true,
        rating: 5.0,
        total_trips: 0
      })
      .eq('user_id', user.id);

    if (updateError) {
      console.log('❌ 更新 driver 失敗:', updateError.message);
      return false;
    }
    console.log('✅ 已更新 driver 記錄');
  }

  return true;
}

async function verifyFix() {
  console.log('\n=== 驗證修復結果 ===\n');

  const { data: result, error } = await supabase
    .from('users')
    .select(`
      id,
      email,
      role,
      user_profiles!user_id (first_name, last_name, phone),
      drivers!user_id (
        vehicle_type,
        vehicle_plate,
        vehicle_model,
        is_available,
        rating,
        total_trips
      )
    `)
    .eq('email', TEST_DRIVER_EMAIL)
    .single();

  if (error || !result) {
    console.log('❌ 驗證失敗:', error?.message);
    return false;
  }

  const profile = result.user_profiles?.[0] || result.user_profiles;
  const driver = result.drivers?.[0] || result.drivers;

  console.log('📊 最終結果:');
  console.log('   Email:', result.email);
  console.log('   Role:', result.role);
  console.log('   姓名:', profile?.first_name, profile?.last_name);
  console.log('   電話:', profile?.phone);
  console.log('   車型:', driver?.vehicle_type);
  console.log('   車牌:', driver?.vehicle_plate);
  console.log('   車款:', driver?.vehicle_model);
  console.log('   可用:', driver?.is_available);
  console.log('   評分:', driver?.rating);

  const isValid = 
    result.role === 'driver' &&
    profile &&
    driver &&
    driver.is_available === true &&
    driver.vehicle_type;

  if (isValid) {
    console.log('\n✅ 測試司機帳號已完全修復！');
    console.log('   現在應該可以在司機列表中看到此司機了。');
  } else {
    console.log('\n❌ 修復可能不完整，請檢查上述資訊');
  }

  return isValid;
}

async function main() {
  try {
    // 診斷
    const diagResult = await diagnoseDriver();
    
    if (!diagResult) {
      console.log('\n❌ 診斷失敗，無法繼續');
      process.exit(1);
    }

    // 詢問是否修復
    console.log('\n' + '='.repeat(50));
    console.log('是否要執行修復？(自動執行)');
    console.log('='.repeat(50) + '\n');

    // 執行修復
    const fixResult = await fixDriver();

    if (!fixResult) {
      console.log('\n❌ 修復失敗');
      process.exit(1);
    }

    // 驗證
    const verifyResult = await verifyFix();

    if (verifyResult) {
      console.log('\n🎉 完成！請重新測試手動派單功能。');
      process.exit(0);
    } else {
      console.log('\n⚠️  修復完成但驗證未通過，請手動檢查');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ 執行錯誤:', error);
    process.exit(1);
  }
}

// 執行
main();

