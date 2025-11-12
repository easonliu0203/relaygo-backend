// 診斷並修復測試帳號問題
// 此腳本會檢查測試帳號是否存在，並創建缺失的資料

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// 讀取 .env.local 文件
const envPath = path.join(__dirname, 'web-admin', '.env.local');
let supabaseUrl, supabaseServiceKey;

try {
  const envContent = fs.readFileSync(envPath, 'utf8');
  const lines = envContent.split('\n');

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('NEXT_PUBLIC_SUPABASE_URL=')) {
      supabaseUrl = trimmed.split('=')[1].trim();
    } else if (trimmed.startsWith('SUPABASE_SERVICE_ROLE_KEY=')) {
      supabaseServiceKey = trimmed.split('=')[1].trim();
    }
  }
} catch (error) {
  console.error('❌ 無法讀取 .env.local 文件:', error.message);
  process.exit(1);
}

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ 缺少 Supabase 配置');
  console.error('請確保 web-admin/.env.local 包含:');
  console.error('- NEXT_PUBLIC_SUPABASE_URL');
  console.error('- SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// 測試帳號配置
const TEST_ACCOUNTS = [
  {
    email: 'customer.test@relaygo.com',
    firebase_uid: 'CMfTxhJFlUVDkosJPyUoJvKjCQk1',
    role: 'customer',
    phone: '+886912345678',
    first_name: '測試',
    last_name: '客戶',
  },
  {
    email: 'driver.test@relaygo.com',
    firebase_uid: 'DRV123456789ABCDEFGHIJK',
    role: 'driver',
    phone: '+886987654321',
    first_name: '測試',
    last_name: '司機',
    // 司機特定資料
    license_number: 'DL-TEST-001',
    vehicle_type: 'C',
    vehicle_plate: 'ABC-1234',
    vehicle_model: 'Toyota Camry',
    vehicle_year: 2023,
  },
];

async function main() {
  console.log('========================================');
  console.log('測試帳號診斷與修復工具');
  console.log('========================================');
  console.log('');

  for (const account of TEST_ACCOUNTS) {
    console.log(`檢查帳號: ${account.email}`);
    console.log('----------------------------------------');

    try {
      // 步驟 1: 檢查 users 表
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('email', account.email)
        .maybeSingle();

      if (userError) {
        console.error(`❌ 查詢 users 表失敗:`, userError.message);
        continue;
      }

      let userId;

      if (!user) {
        console.log('⚠️ 用戶不存在，創建中...');
        
        // 創建用戶
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert({
            firebase_uid: account.firebase_uid,
            email: account.email,
            phone: account.phone,
            role: account.role,
            status: 'active',
          })
          .select()
          .single();

        if (createError) {
          console.error(`❌ 創建用戶失敗:`, createError.message);
          continue;
        }

        userId = newUser.id;
        console.log(`✅ 用戶已創建 (ID: ${userId})`);
      } else {
        userId = user.id;
        console.log(`✅ 用戶已存在 (ID: ${userId})`);
        console.log(`   Firebase UID: ${user.firebase_uid}`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Status: ${user.status}`);

        // 檢查並更新 role 和 status
        if (user.role !== account.role || user.status !== 'active') {
          console.log('⚠️ 更新用戶資料...');
          const { error: updateError } = await supabase
            .from('users')
            .update({
              role: account.role,
              status: 'active',
            })
            .eq('id', userId);

          if (updateError) {
            console.error(`❌ 更新用戶失敗:`, updateError.message);
          } else {
            console.log(`✅ 用戶資料已更新`);
          }
        }
      }

      // 步驟 2: 檢查 user_profiles 表
      const { data: profile, error: profileError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

      if (profileError) {
        console.error(`❌ 查詢 user_profiles 表失敗:`, profileError.message);
      } else if (!profile) {
        console.log('⚠️ 個人資料不存在，創建中...');
        
        const { error: createProfileError } = await supabase
          .from('user_profiles')
          .insert({
            user_id: userId,
            first_name: account.first_name,
            last_name: account.last_name,
            phone: account.phone,
          });

        if (createProfileError) {
          console.error(`❌ 創建個人資料失敗:`, createProfileError.message);
        } else {
          console.log(`✅ 個人資料已創建`);
        }
      } else {
        console.log(`✅ 個人資料已存在`);
        console.log(`   姓名: ${profile.first_name} ${profile.last_name}`);
        console.log(`   電話: ${profile.phone}`);
      }

      // 步驟 3: 如果是司機，檢查 drivers 表
      if (account.role === 'driver') {
        const { data: driver, error: driverError } = await supabase
          .from('drivers')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

        if (driverError) {
          console.error(`❌ 查詢 drivers 表失敗:`, driverError.message);
        } else if (!driver) {
          console.log('⚠️ 司機資料不存在，創建中...');
          
          const { error: createDriverError } = await supabase
            .from('drivers')
            .insert({
              user_id: userId,
              license_number: account.license_number,
              vehicle_type: account.vehicle_type,
              vehicle_plate: account.vehicle_plate,
              vehicle_model: account.vehicle_model,
              vehicle_year: account.vehicle_year,
              is_available: true,
              background_check_status: 'approved',
              rating: 5.0,
              total_trips: 0,
            });

          if (createDriverError) {
            console.error(`❌ 創建司機資料失敗:`, createDriverError.message);
          } else {
            console.log(`✅ 司機資料已創建`);
          }
        } else {
          console.log(`✅ 司機資料已存在`);
          console.log(`   駕照號碼: ${driver.license_number}`);
          console.log(`   車型: ${driver.vehicle_type}`);
          console.log(`   車牌: ${driver.vehicle_plate}`);
          console.log(`   審核狀態: ${driver.background_check_status}`);
        }
      }

      console.log('');

    } catch (error) {
      console.error(`❌ 處理帳號時發生錯誤:`, error.message);
      console.log('');
    }
  }

  console.log('========================================');
  console.log('驗證結果');
  console.log('========================================');
  console.log('');

  // 驗證客戶
  const { data: customers, error: customersError } = await supabase
    .from('users')
    .select(`
      *,
      user_profiles (
        first_name,
        last_name,
        phone
      )
    `)
    .eq('role', 'customer')
    .eq('email', 'customer.test@relaygo.com');

  if (customersError) {
    console.error('❌ 驗證客戶失敗:', customersError.message);
  } else if (customers && customers.length > 0) {
    const customer = customers[0];
    const profile = customer.user_profiles?.[0] || customer.user_profiles;
    console.log('✅ 客戶測試帳號驗證成功');
    console.log(`   Email: ${customer.email}`);
    console.log(`   姓名: ${profile?.first_name || '未設定'} ${profile?.last_name || ''}`);
    console.log(`   電話: ${profile?.phone || '未設定'}`);
  } else {
    console.log('❌ 客戶測試帳號不存在');
  }

  console.log('');

  // 驗證司機
  const { data: drivers, error: driversError } = await supabase
    .from('users')
    .select(`
      *,
      user_profiles (
        first_name,
        last_name,
        phone
      ),
      drivers (
        license_number,
        vehicle_type,
        vehicle_plate,
        background_check_status
      )
    `)
    .eq('role', 'driver')
    .eq('email', 'driver.test@relaygo.com');

  if (driversError) {
    console.error('❌ 驗證司機失敗:', driversError.message);
  } else if (drivers && drivers.length > 0) {
    const driver = drivers[0];
    const profile = driver.user_profiles?.[0] || driver.user_profiles;
    const driverInfo = driver.drivers?.[0] || driver.drivers;
    console.log('✅ 司機測試帳號驗證成功');
    console.log(`   Email: ${driver.email}`);
    console.log(`   姓名: ${profile?.first_name || '未設定'} ${profile?.last_name || ''}`);
    console.log(`   電話: ${profile?.phone || '未設定'}`);
    console.log(`   駕照: ${driverInfo?.license_number || '未設定'}`);
    console.log(`   車型: ${driverInfo?.vehicle_type || '未設定'}`);
    console.log(`   車牌: ${driverInfo?.vehicle_plate || '未設定'}`);
  } else {
    console.log('❌ 司機測試帳號不存在');
  }

  console.log('');
  console.log('========================================');
  console.log('完成！');
  console.log('========================================');
  console.log('');
  console.log('下一步:');
  console.log('1. 訪問公司端: http://localhost:3001/drivers');
  console.log('2. 訪問公司端: http://localhost:3001/customers');
  console.log('3. 確認可以看到測試帳號');
}

main().catch(console.error);

