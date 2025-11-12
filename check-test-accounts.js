/**
 * 檢查測試帳號在 Supabase 中的狀態
 * 
 * 用途：診斷測試帳號是否存在於資料庫中，以及資料完整性
 * 
 * 執行方式：
 *   node check-test-accounts.js
 */

const { createClient } = require('@supabase/supabase-js');

// Supabase 配置（從 web-admin/.env.local）
const SUPABASE_URL = 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWh3ZWdwdnBuanlvY3FtZnFjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1ODk3Nzk5NiwiZXhwIjoyMDc0NTUzOTk2fQ.nQPynfQcSIZ1QPVSjDcgscugQcEgfRPUauW0psSRTQo';

// 測試帳號資訊
const TEST_ACCOUNTS = {
  customer: {
    email: 'customer.test@relaygo.com',
    role: 'customer',
    firebase_uid: null, // 待查詢
  },
  driver: {
    email: 'driver.test@relaygo.com',
    role: 'driver',
    firebase_uid: 'CMfTxhJFlUVDkosJPyUoJvKjCQk1',
  },
};

console.log('========================================');
console.log('檢查測試帳號在 Supabase 中的狀態');
console.log('========================================');
console.log('');

async function main() {
  try {
    // 初始化 Supabase
    console.log('[1/6] 初始化 Supabase...');
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    console.log('✅ Supabase 初始化成功');
    console.log('');

    // 檢查客戶測試帳號
    console.log('[2/6] 檢查客戶測試帳號...');
    console.log(`Email: ${TEST_ACCOUNTS.customer.email}`);

    const { data: customerUser, error: customerError } = await supabase
      .from('users')
      .select('*')
      .eq('email', TEST_ACCOUNTS.customer.email)
      .single();

    let customerProfile = null;

    if (customerError || !customerUser) {
      console.log('❌ 客戶測試帳號不存在於 users 表');
      console.log('需要創建客戶測試帳號');
    } else {
      console.log('✅ 找到客戶測試帳號');
      console.log(`  ID: ${customerUser.id}`);
      console.log(`  Firebase UID: ${customerUser.firebase_uid}`);
      console.log(`  Email: ${customerUser.email}`);
      console.log(`  Role: ${customerUser.role}`);
      console.log(`  Status: ${customerUser.status}`);

      // 檢查 user_profiles
      const { data: profile, error: profileError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('user_id', customerUser.id)
        .single();

      customerProfile = profile;

      if (profileError || !customerProfile) {
        console.log('⚠️  客戶測試帳號缺少 user_profiles 記錄');
      } else {
        console.log('✅ 找到 user_profiles 記錄');
        console.log(`  姓名: ${customerProfile.first_name} ${customerProfile.last_name}`);
        console.log(`  電話: ${customerProfile.phone}`);
      }
    }
    console.log('');

    // 檢查司機測試帳號
    console.log('[3/6] 檢查司機測試帳號...');
    console.log(`Email: ${TEST_ACCOUNTS.driver.email}`);
    console.log(`Firebase UID: ${TEST_ACCOUNTS.driver.firebase_uid}`);

    const { data: driverUser, error: driverError } = await supabase
      .from('users')
      .select('*')
      .eq('email', TEST_ACCOUNTS.driver.email)
      .single();

    let driverProfile = null;
    let driverInfo = null;

    if (driverError || !driverUser) {
      console.log('❌ 司機測試帳號不存在於 users 表');
      console.log('需要創建司機測試帳號');
    } else {
      console.log('✅ 找到司機測試帳號');
      console.log(`  ID: ${driverUser.id}`);
      console.log(`  Firebase UID: ${driverUser.firebase_uid}`);
      console.log(`  Email: ${driverUser.email}`);
      console.log(`  Role: ${driverUser.role}`);
      console.log(`  Status: ${driverUser.status}`);

      // 檢查 user_profiles
      const { data: profile, error: driverProfileError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('user_id', driverUser.id)
        .single();

      driverProfile = profile;

      if (driverProfileError || !driverProfile) {
        console.log('⚠️  司機測試帳號缺少 user_profiles 記錄');
      } else {
        console.log('✅ 找到 user_profiles 記錄');
        console.log(`  姓名: ${driverProfile.first_name} ${driverProfile.last_name}`);
        console.log(`  電話: ${driverProfile.phone}`);
      }

      // 檢查 drivers 表
      const { data: info, error: driverInfoError } = await supabase
        .from('drivers')
        .select('*')
        .eq('user_id', driverUser.id)
        .single();

      driverInfo = info;

      if (driverInfoError || !driverInfo) {
        console.log('⚠️  司機測試帳號缺少 drivers 記錄');
      } else {
        console.log('✅ 找到 drivers 記錄');
        console.log(`  車型: ${driverInfo.vehicle_type}`);
        console.log(`  車牌: ${driverInfo.vehicle_plate}`);
        console.log(`  狀態: ${driverInfo.background_check_status}`);
      }
    }
    console.log('');

    // 檢查所有用戶的角色分佈
    console.log('[4/6] 檢查所有用戶的角色分佈...');
    const { data: allUsers, error: allUsersError } = await supabase
      .from('users')
      .select('role');

    if (!allUsersError && allUsers) {
      const roleCounts = allUsers.reduce((acc, user) => {
        acc[user.role] = (acc[user.role] || 0) + 1;
        return acc;
      }, {});

      console.log('角色分佈:');
      Object.entries(roleCounts).forEach(([role, count]) => {
        console.log(`  ${role}: ${count}`);
      });
    }
    console.log('');

    // 測試 API 查詢
    console.log('[5/6] 測試 API 查詢...');
    
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
        console.log('  user_profiles:', testDriver.user_profiles);
        console.log('  drivers:', testDriver.drivers);
      } else {
        console.log('❌ 測試司機不在查詢結果中');
      }
    } else {
      console.log('❌ 司機查詢失敗:', driversError?.message);
    }
    console.log('');

    // 總結
    console.log('[6/6] 診斷總結');
    console.log('========================================');
    
    const issues = [];
    
    if (!customerUser) {
      issues.push('❌ 客戶測試帳號不存在於 users 表');
    } else if (!customerProfile) {
      issues.push('⚠️  客戶測試帳號缺少 user_profiles 記錄');
    }
    
    if (!driverUser) {
      issues.push('❌ 司機測試帳號不存在於 users 表');
    } else {
      if (!driverProfile) {
        issues.push('⚠️  司機測試帳號缺少 user_profiles 記錄');
      }
      if (!driverInfo) {
        issues.push('⚠️  司機測試帳號缺少 drivers 記錄');
      }
    }

    if (issues.length === 0) {
      console.log('✅ 所有測試帳號資料完整');
    } else {
      console.log('發現以下問題:');
      issues.forEach(issue => console.log(`  ${issue}`));
      console.log('');
      console.log('建議執行修復腳本創建缺失的記錄');
    }

  } catch (error) {
    console.error('❌ 診斷過程中發生錯誤:', error);
    console.error(error.stack);
  }
}

main();

