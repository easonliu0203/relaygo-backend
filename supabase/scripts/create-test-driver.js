/**
 * 創建測試司機帳號
 * 
 * 使用方法:
 * cd web-admin && node ../supabase/scripts/create-test-driver.js
 */

const { createClient } = require('../../web-admin/node_modules/@supabase/supabase-js');

// Supabase 配置
const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

const TEST_DRIVER_EMAIL = 'driver.test@gelaygo.com';
const TEST_DRIVER_PASSWORD = 'Test123456!';

// 創建 Supabase 客戶端
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function checkExistingUsers() {
  console.log('\n=== 檢查現有用戶 ===\n');

  const { data: users, error } = await supabase
    .from('users')
    .select('id, email, role')
    .limit(10);

  if (error) {
    console.log('❌ 查詢失敗:', error.message);
    return;
  }

  console.log(`找到 ${users?.length || 0} 位用戶:`);
  users?.forEach((u, i) => {
    console.log(`   ${i + 1}. ${u.email} (${u.role})`);
  });
}

async function createTestDriver() {
  console.log('\n=== 創建測試司機帳號 ===\n');

  // 1. 檢查用戶是否已存在
  console.log('1️⃣ 檢查用戶是否已存在...');
  const { data: existingUser } = await supabase
    .from('users')
    .select('id, email, role')
    .eq('email', TEST_DRIVER_EMAIL)
    .maybeSingle();

  let userId;

  if (existingUser) {
    console.log('✅ 用戶已存在:', existingUser.id);
    userId = existingUser.id;

    // 確保角色為 driver
    if (existingUser.role !== 'driver') {
      console.log('⚠️  更新角色為 driver...');
      const { error: updateError } = await supabase
        .from('users')
        .update({ role: 'driver' })
        .eq('id', userId);

      if (updateError) {
        console.log('❌ 更新角色失敗:', updateError.message);
        return false;
      }
      console.log('✅ 已更新角色');
    }
  } else {
    console.log('⚠️  用戶不存在，正在創建...');
    
    // 創建用戶
    const { data: newUser, error: createError } = await supabase
      .from('users')
      .insert({
        email: TEST_DRIVER_EMAIL,
        role: 'driver',
        firebase_uid: `test-driver-${Date.now()}`, // 臨時 UID
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (createError) {
      console.log('❌ 創建用戶失敗:', createError.message);
      console.log('   詳細:', createError);
      return false;
    }

    console.log('✅ 已創建用戶:', newUser.id);
    userId = newUser.id;
  }

  // 2. 創建或更新 user_profiles
  console.log('\n2️⃣ 處理 user_profiles...');
  const { data: existingProfile } = await supabase
    .from('user_profiles')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  if (existingProfile) {
    console.log('✅ user_profile 已存在，正在更新...');
    const { error: updateError } = await supabase
      .from('user_profiles')
      .update({
        first_name: '測試',
        last_name: '司機',
        phone: '0912345678',
        updated_at: new Date().toISOString()
      })
      .eq('user_id', userId);

    if (updateError) {
      console.log('❌ 更新 user_profile 失敗:', updateError.message);
    } else {
      console.log('✅ 已更新 user_profile');
    }
  } else {
    console.log('⚠️  user_profile 不存在，正在創建...');
    const { data: newProfile, error: createError } = await supabase
      .from('user_profiles')
      .insert({
        user_id: userId,
        first_name: '測試',
        last_name: '司機',
        phone: '0912345678',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (createError) {
      console.log('❌ 創建 user_profile 失敗:', createError.message);
      console.log('   詳細:', createError);
      return false;
    }

    console.log('✅ 已創建 user_profile:', newProfile.id);
  }

  // 3. 創建或更新 drivers
  console.log('\n3️⃣ 處理 drivers...');
  const { data: existingDriver } = await supabase
    .from('drivers')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();

  if (existingDriver) {
    console.log('✅ driver 記錄已存在，正在更新...');

    // 設定駕照到期日為一年後
    const licenseExpiry = new Date();
    licenseExpiry.setFullYear(licenseExpiry.getFullYear() + 1);

    const { error: updateError } = await supabase
      .from('drivers')
      .update({
        license_number: 'TEST-LICENSE-001',
        license_expiry: licenseExpiry.toISOString().split('T')[0],
        vehicle_type: 'A',
        vehicle_plate: 'TEST-001',
        vehicle_model: 'Toyota Alphard',
        vehicle_year: 2023,
        insurance_number: 'TEST-INS-001',
        insurance_expiry: licenseExpiry.toISOString().split('T')[0],
        background_check_status: 'approved',
        is_available: true,
        rating: 5.0,
        total_trips: 0,
        languages: ['zh-TW', 'en'],
        updated_at: new Date().toISOString()
      })
      .eq('user_id', userId);

    if (updateError) {
      console.log('❌ 更新 driver 失敗:', updateError.message);
      return false;
    }

    console.log('✅ 已更新 driver 記錄');
  } else {
    console.log('⚠️  driver 記錄不存在，正在創建...');

    // 設定駕照到期日為一年後
    const licenseExpiry = new Date();
    licenseExpiry.setFullYear(licenseExpiry.getFullYear() + 1);

    const { data: newDriver, error: createError } = await supabase
      .from('drivers')
      .insert({
        user_id: userId,
        license_number: 'TEST-LICENSE-001',
        license_expiry: licenseExpiry.toISOString().split('T')[0], // YYYY-MM-DD
        vehicle_type: 'A',
        vehicle_plate: 'TEST-001',
        vehicle_model: 'Toyota Alphard',
        vehicle_year: 2023,
        insurance_number: 'TEST-INS-001',
        insurance_expiry: licenseExpiry.toISOString().split('T')[0],
        background_check_status: 'approved',
        background_check_date: new Date().toISOString().split('T')[0],
        is_available: true,
        rating: 5.0,
        total_trips: 0,
        languages: ['zh-TW', 'en'],
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (createError) {
      console.log('❌ 創建 driver 失敗:', createError.message);
      console.log('   詳細:', createError);
      return false;
    }

    console.log('✅ 已創建 driver 記錄:', newDriver.id);
  }

  return true;
}

async function verifyDriver() {
  console.log('\n=== 驗證測試司機帳號 ===\n');

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
    .maybeSingle();

  if (error || !result) {
    console.log('❌ 驗證失敗:', error?.message);
    return false;
  }

  const profile = result.user_profiles?.[0] || result.user_profiles;
  const driver = result.drivers?.[0] || result.drivers;

  console.log('📊 測試司機帳號資訊:');
  console.log('   ✅ Email:', result.email);
  console.log('   ✅ Role:', result.role);
  console.log('   ✅ 姓名:', profile?.first_name, profile?.last_name);
  console.log('   ✅ 電話:', profile?.phone);
  console.log('   ✅ 車型:', driver?.vehicle_type);
  console.log('   ✅ 車牌:', driver?.vehicle_plate);
  console.log('   ✅ 車款:', driver?.vehicle_model);
  console.log('   ✅ 可用:', driver?.is_available);
  console.log('   ✅ 評分:', driver?.rating);

  const isValid = 
    result.role === 'driver' &&
    profile &&
    driver &&
    driver.is_available === true &&
    driver.vehicle_type;

  if (isValid) {
    console.log('\n✅ 測試司機帳號已完全設置！');
    console.log('   現在應該可以在司機列表中看到此司機了。');
    console.log('\n📝 測試帳號資訊:');
    console.log('   Email:', TEST_DRIVER_EMAIL);
    console.log('   Password:', TEST_DRIVER_PASSWORD);
  } else {
    console.log('\n❌ 設置可能不完整，請檢查上述資訊');
  }

  return isValid;
}

async function main() {
  try {
    // 檢查現有用戶
    await checkExistingUsers();

    // 創建測試司機
    const createResult = await createTestDriver();

    if (!createResult) {
      console.log('\n❌ 創建失敗');
      process.exit(1);
    }

    // 驗證
    const verifyResult = await verifyDriver();

    if (verifyResult) {
      console.log('\n🎉 完成！請重新測試手動派單功能。');
      console.log('\n📋 測試步驟:');
      console.log('   1. 訪問 http://localhost:3001/orders/pending');
      console.log('   2. 點擊訂單的「手動派單」按鈕');
      console.log('   3. 應該能看到「測試 司機」在司機列表中');
      process.exit(0);
    } else {
      console.log('\n⚠️  創建完成但驗證未通過，請手動檢查');
      process.exit(1);
    }

  } catch (error) {
    console.error('\n❌ 執行錯誤:', error);
    console.error('   Stack:', error.stack);
    process.exit(1);
  }
}

// 執行
main();

