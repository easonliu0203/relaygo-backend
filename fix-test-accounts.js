/**
 * 自動修復測試帳號
 * 
 * 用途：為測試帳號創建缺失的 users、user_profiles 和 drivers 記錄
 * 
 * 執行方式：
 *   node fix-test-accounts.js
 */

const { createClient } = require('@supabase/supabase-js');

// Supabase 配置
const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

// 測試帳號資訊
const TEST_ACCOUNTS = {
  customer: {
    email: 'customer.test@relaygo.com',
    role: 'customer',
    firebase_uid: 'customer_test_uid_' + Date.now(),
    profile: {
      first_name: '測試',
      last_name: '客戶',
      phone: '0912345678',
    },
  },
  driver: {
    email: 'driver.test@relaygo.com',
    role: 'driver',
    firebase_uid: 'CMfTxhJFlUVDkosJPyUoJvKjCQk1',
    profile: {
      first_name: '測試',
      last_name: '司機',
      phone: '0987654321',
    },
    driver: {
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
    },
  },
};

console.log('========================================');
console.log('自動修復測試帳號');
console.log('========================================');
console.log('');

async function main() {
  try {
    // 初始化 Supabase
    console.log('[1/5] 初始化 Supabase...');
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    console.log('✅ Supabase 初始化成功');
    console.log('');

    // 修復客戶測試帳號
    console.log('[2/5] 修復客戶測試帳號...');
    await fixCustomerAccount(supabase);
    console.log('');

    // 修復司機測試帳號
    console.log('[3/5] 修復司機測試帳號...');
    await fixDriverAccount(supabase);
    console.log('');

    // 驗證修復結果
    console.log('[4/5] 驗證修復結果...');
    await verifyAccounts(supabase);
    console.log('');

    // 測試 API 查詢
    console.log('[5/5] 測試 API 查詢...');
    await testApiQueries(supabase);
    console.log('');

    console.log('========================================');
    console.log('✅ 修復完成！');
    console.log('========================================');
    console.log('');
    console.log('下一步：');
    console.log('1. 訪問 http://localhost:3001/customers');
    console.log('2. 搜尋 customer.test@relaygo.com');
    console.log('3. 訪問 http://localhost:3001/drivers');
    console.log('4. 搜尋 driver.test@relaygo.com');

  } catch (error) {
    console.error('❌ 修復過程中發生錯誤:', error);
    console.error(error.stack);
  }
}

async function fixCustomerAccount(supabase) {
  const account = TEST_ACCOUNTS.customer;

  // 檢查是否已存在
  const { data: existingUser } = await supabase
    .from('users')
    .select('*')
    .eq('email', account.email)
    .single();

  let userId;

  if (!existingUser) {
    console.log('創建客戶 users 記錄...');
    const { data: newUser, error: userError } = await supabase
      .from('users')
      .insert({
        firebase_uid: account.firebase_uid,
        email: account.email,
        role: account.role,
        status: 'active',
      })
      .select()
      .single();

    if (userError) {
      console.error('❌ 創建 users 記錄失敗:', userError.message);
      return;
    }

    userId = newUser.id;
    console.log('✅ 創建 users 記錄成功');
  } else {
    userId = existingUser.id;
    console.log('✅ users 記錄已存在');
  }

  // 檢查 user_profiles
  const { data: existingProfile } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (!existingProfile) {
    console.log('創建客戶 user_profiles 記錄...');
    const { error: profileError } = await supabase
      .from('user_profiles')
      .insert({
        user_id: userId,
        ...account.profile,
      });

    if (profileError) {
      console.error('❌ 創建 user_profiles 記錄失敗:', profileError.message);
      return;
    }

    console.log('✅ 創建 user_profiles 記錄成功');
  } else {
    console.log('✅ user_profiles 記錄已存在');
  }
}

async function fixDriverAccount(supabase) {
  const account = TEST_ACCOUNTS.driver;

  // 檢查是否已存在
  const { data: existingUser } = await supabase
    .from('users')
    .select('*')
    .eq('email', account.email)
    .single();

  let userId;

  if (!existingUser) {
    console.log('創建司機 users 記錄...');
    const { data: newUser, error: userError } = await supabase
      .from('users')
      .insert({
        firebase_uid: account.firebase_uid,
        email: account.email,
        role: account.role,
        status: 'active',
      })
      .select()
      .single();

    if (userError) {
      console.error('❌ 創建 users 記錄失敗:', userError.message);
      return;
    }

    userId = newUser.id;
    console.log('✅ 創建 users 記錄成功');
  } else {
    userId = existingUser.id;
    console.log('✅ users 記錄已存在');

    // 確保 firebase_uid 正確
    if (existingUser.firebase_uid !== account.firebase_uid) {
      console.log('更新 firebase_uid...');
      await supabase
        .from('users')
        .update({ firebase_uid: account.firebase_uid })
        .eq('id', userId);
      console.log('✅ firebase_uid 已更新');
    }
  }

  // 檢查 user_profiles
  const { data: existingProfile } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (!existingProfile) {
    console.log('創建司機 user_profiles 記錄...');
    const { error: profileError } = await supabase
      .from('user_profiles')
      .insert({
        user_id: userId,
        ...account.profile,
      });

    if (profileError) {
      console.error('❌ 創建 user_profiles 記錄失敗:', profileError.message);
      return;
    }

    console.log('✅ 創建 user_profiles 記錄成功');
  } else {
    console.log('✅ user_profiles 記錄已存在');
  }

  // 檢查 drivers
  const { data: existingDriver } = await supabase
    .from('drivers')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (!existingDriver) {
    console.log('創建 drivers 記錄...');
    const { error: driverError } = await supabase
      .from('drivers')
      .insert({
        user_id: userId,
        ...account.driver,
      });

    if (driverError) {
      console.error('❌ 創建 drivers 記錄失敗:', driverError.message);
      return;
    }

    console.log('✅ 創建 drivers 記錄成功');
  } else {
    console.log('✅ drivers 記錄已存在');
  }
}

async function verifyAccounts(supabase) {
  // 驗證客戶帳號
  const { data: customer } = await supabase
    .from('users')
    .select(`
      *,
      user_profiles!user_id (*)
    `)
    .eq('email', TEST_ACCOUNTS.customer.email)
    .single();

  if (customer && customer.user_profiles?.length > 0) {
    console.log('✅ 客戶測試帳號資料完整');
    console.log(`   Email: ${customer.email}`);
    console.log(`   姓名: ${customer.user_profiles[0].first_name} ${customer.user_profiles[0].last_name}`);
  } else {
    console.log('❌ 客戶測試帳號資料不完整');
  }

  // 驗證司機帳號
  const { data: driver } = await supabase
    .from('users')
    .select(`
      *,
      user_profiles!user_id (*),
      drivers!user_id (*)
    `)
    .eq('email', TEST_ACCOUNTS.driver.email)
    .single();

  if (driver && driver.user_profiles?.length > 0 && driver.drivers?.length > 0) {
    console.log('✅ 司機測試帳號資料完整');
    console.log(`   Email: ${driver.email}`);
    console.log(`   姓名: ${driver.user_profiles[0].first_name} ${driver.user_profiles[0].last_name}`);
    console.log(`   車型: ${driver.drivers[0].vehicle_type}`);
    console.log(`   車牌: ${driver.drivers[0].vehicle_plate}`);
  } else {
    console.log('❌ 司機測試帳號資料不完整');
  }
}

async function testApiQueries(supabase) {
  // 測試客戶查詢
  const { data: customers, error: customersError } = await supabase
    .from('users')
    .select(`
      *,
      user_profiles!user_id (
        first_name,
        last_name,
        phone,
        avatar_url
      )
    `)
    .eq('role', 'customer');

  if (!customersError && customers) {
    console.log(`✅ 客戶查詢成功，找到 ${customers.length} 位客戶`);
    const testCustomer = customers.find(c => c.email === TEST_ACCOUNTS.customer.email);
    if (testCustomer) {
      console.log('✅ 測試客戶在查詢結果中');
    } else {
      console.log('❌ 測試客戶不在查詢結果中');
    }
  } else {
    console.log('❌ 客戶查詢失敗:', customersError?.message);
  }

  // 測試司機查詢
  const { data: drivers, error: driversError } = await supabase
    .from('users')
    .select(`
      *,
      user_profiles!user_id (
        first_name,
        last_name,
        phone,
        avatar_url
      ),
      drivers!user_id (
        id,
        license_number,
        vehicle_type,
        vehicle_plate,
        vehicle_model,
        is_available,
        background_check_status,
        rating,
        total_trips
      )
    `)
    .eq('role', 'driver');

  if (!driversError && drivers) {
    console.log(`✅ 司機查詢成功，找到 ${drivers.length} 位司機`);
    const testDriver = drivers.find(d => d.email === TEST_ACCOUNTS.driver.email);
    if (testDriver) {
      console.log('✅ 測試司機在查詢結果中');
    } else {
      console.log('❌ 測試司機不在查詢結果中');
    }
  } else {
    console.log('❌ 司機查詢失敗:', driversError?.message);
  }
}

main();

