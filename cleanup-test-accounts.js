const { createClient } = require('@supabase/supabase-js');

// Supabase 配置
const SUPABASE_URL = 'https://yfkzacfavkeqzpjhzwqo.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlma3phY2ZhdmtlcXpwamh6d3FvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNzY4MzI0NCwiZXhwIjoyMDQzMjU5MjQ0fQ.yaIUUniLXyT-ST5xlKhLhwxd-kYdvVLVHqLNTE_Wkxo';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// 保留的測試帳號
const KEEP_ACCOUNTS = [
  'customer.test@relaygo.com',
  'driver.test@relaygo.com'
];

async function listAllTestAccounts() {
  console.log('\n========================================');
  console.log('步驟 1: 檢查所有測試帳號');
  console.log('========================================\n');

  // 查詢所有用戶
  const { data: users, error } = await supabase
    .from('users')
    .select(`
      id,
      email,
      firebase_uid,
      role,
      status,
      user_profiles (
        first_name,
        last_name,
        phone
      )
    `)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('❌ 查詢用戶失敗:', error);
    return [];
  }

  console.log(`✅ 找到 ${users.length} 個用戶帳號\n`);

  // 分類帳號
  const keepAccounts = [];
  const deleteAccounts = [];

  users.forEach(user => {
    const profile = user.user_profiles?.[0] || user.user_profiles;
    const name = profile ? `${profile.first_name || ''} ${profile.last_name || ''}`.trim() : '未知';
    
    const accountInfo = {
      id: user.id,
      email: user.email,
      firebase_uid: user.firebase_uid,
      role: user.role,
      status: user.status,
      name: name
    };

    if (KEEP_ACCOUNTS.includes(user.email)) {
      keepAccounts.push(accountInfo);
    } else {
      deleteAccounts.push(accountInfo);
    }
  });

  console.log('📌 保留的帳號 (2個):');
  console.log('─────────────────────────────────────────\n');
  keepAccounts.forEach((account, index) => {
    console.log(`${index + 1}. ${account.name}`);
    console.log(`   Email: ${account.email}`);
    console.log(`   角色: ${account.role}`);
    console.log(`   狀態: ${account.status}`);
    console.log(`   ID: ${account.id}\n`);
  });

  console.log('🗑️  需要刪除的帳號 (' + deleteAccounts.length + '個):');
  console.log('─────────────────────────────────────────\n');
  deleteAccounts.forEach((account, index) => {
    console.log(`${index + 1}. ${account.name}`);
    console.log(`   Email: ${account.email}`);
    console.log(`   角色: ${account.role}`);
    console.log(`   狀態: ${account.status}`);
    console.log(`   ID: ${account.id}\n`);
  });

  return deleteAccounts;
}

async function deleteAccount(account) {
  console.log(`\n正在刪除帳號: ${account.name} (${account.email})...`);
  
  const results = {
    email: account.email,
    name: account.name,
    userId: account.id,
    firebaseUid: account.firebase_uid,
    deletedRecords: {
      bookings: 0,
      drivers: 0,
      userProfiles: 0,
      users: 0,
      firebase: false
    },
    errors: []
  };

  try {
    // 1. 刪除相關的訂單（作為客戶）
    const { data: customerBookings, error: customerBookingsError } = await supabase
      .from('bookings')
      .delete()
      .eq('customer_id', account.id)
      .select();

    if (customerBookingsError) {
      results.errors.push(`刪除客戶訂單失敗: ${customerBookingsError.message}`);
    } else {
      results.deletedRecords.bookings += customerBookings?.length || 0;
      console.log(`   ✅ 刪除 ${customerBookings?.length || 0} 筆客戶訂單`);
    }

    // 2. 刪除相關的訂單（作為司機）
    const { data: driverBookings, error: driverBookingsError } = await supabase
      .from('bookings')
      .delete()
      .eq('driver_id', account.id)
      .select();

    if (driverBookingsError) {
      results.errors.push(`刪除司機訂單失敗: ${driverBookingsError.message}`);
    } else {
      results.deletedRecords.bookings += driverBookings?.length || 0;
      console.log(`   ✅ 刪除 ${driverBookings?.length || 0} 筆司機訂單`);
    }

    // 3. 刪除司機資料（如果是司機）
    if (account.role === 'driver') {
      const { data: driverData, error: driverError } = await supabase
        .from('drivers')
        .delete()
        .eq('user_id', account.id)
        .select();

      if (driverError) {
        results.errors.push(`刪除司機資料失敗: ${driverError.message}`);
      } else {
        results.deletedRecords.drivers = driverData?.length || 0;
        console.log(`   ✅ 刪除 ${driverData?.length || 0} 筆司機資料`);
      }
    }

    // 4. 刪除用戶資料
    const { data: profileData, error: profileError } = await supabase
      .from('user_profiles')
      .delete()
      .eq('user_id', account.id)
      .select();

    if (profileError) {
      results.errors.push(`刪除用戶資料失敗: ${profileError.message}`);
    } else {
      results.deletedRecords.userProfiles = profileData?.length || 0;
      console.log(`   ✅ 刪除 ${profileData?.length || 0} 筆用戶資料`);
    }

    // 5. 刪除用戶帳號
    const { data: userData, error: userError } = await supabase
      .from('users')
      .delete()
      .eq('id', account.id)
      .select();

    if (userError) {
      results.errors.push(`刪除用戶帳號失敗: ${userError.message}`);
    } else {
      results.deletedRecords.users = userData?.length || 0;
      console.log(`   ✅ 刪除 ${userData?.length || 0} 筆用戶帳號`);
    }

    // 6. Firebase Authentication 帳號需要手動刪除
    if (account.firebase_uid) {
      console.log(`   ⚠️  Firebase UID: ${account.firebase_uid} (需要手動刪除)`);
      results.deletedRecords.firebase = false;
    }

    if (results.errors.length === 0) {
      console.log(`   ✅ 帳號刪除完成`);
    } else {
      console.log(`   ⚠️  帳號刪除完成，但有 ${results.errors.length} 個錯誤`);
    }

  } catch (error) {
    console.error(`   ❌ 刪除帳號時發生錯誤:`, error);
    results.errors.push(`刪除帳號時發生錯誤: ${error.message}`);
  }

  return results;
}

async function verifyCleanup() {
  console.log('\n========================================');
  console.log('步驟 3: 驗證清理結果');
  console.log('========================================\n');

  // 查詢剩餘的用戶
  const { data: remainingUsers, error } = await supabase
    .from('users')
    .select(`
      id,
      email,
      role,
      status,
      user_profiles (
        first_name,
        last_name
      )
    `)
    .order('email', { ascending: true });

  if (error) {
    console.error('❌ 查詢剩餘用戶失敗:', error);
    return;
  }

  console.log(`✅ 資料庫中剩餘 ${remainingUsers.length} 個用戶帳號\n`);

  remainingUsers.forEach((user, index) => {
    const profile = user.user_profiles?.[0] || user.user_profiles;
    const name = profile ? `${profile.first_name || ''} ${profile.last_name || ''}`.trim() : '未知';
    
    console.log(`${index + 1}. ${name}`);
    console.log(`   Email: ${user.email}`);
    console.log(`   角色: ${user.role}`);
    console.log(`   狀態: ${user.status}\n`);
  });

  // 驗證是否只剩下保留的帳號
  const unexpectedAccounts = remainingUsers.filter(
    user => !KEEP_ACCOUNTS.includes(user.email)
  );

  if (unexpectedAccounts.length > 0) {
    console.log('⚠️  警告：發現非預期的帳號：');
    unexpectedAccounts.forEach(user => {
      console.log(`   - ${user.email}`);
    });
  } else {
    console.log('✅ 驗證通過：只剩下保留的測試帳號');
  }
}

async function main() {
  console.log('\n');
  console.log('========================================');
  console.log('測試帳號清理工具');
  console.log('========================================');
  console.log('保留帳號:');
  console.log('  1. customer.test@relaygo.com (王小明)');
  console.log('  2. driver.test@relaygo.com (李小花)');
  console.log('========================================\n');

  try {
    // 步驟 1: 列出所有測試帳號
    const accountsToDelete = await listAllTestAccounts();

    if (accountsToDelete.length === 0) {
      console.log('✅ 沒有需要刪除的帳號');
      return;
    }

    // 步驟 2: 刪除帳號
    console.log('\n========================================');
    console.log('步驟 2: 刪除測試帳號');
    console.log('========================================');

    const deleteResults = [];
    for (const account of accountsToDelete) {
      const result = await deleteAccount(account);
      deleteResults.push(result);
    }

    // 步驟 3: 驗證清理結果
    await verifyCleanup();

    // 步驟 4: 生成報告
    console.log('\n========================================');
    console.log('清理報告');
    console.log('========================================\n');

    let totalBookings = 0;
    let totalDrivers = 0;
    let totalProfiles = 0;
    let totalUsers = 0;
    let totalFirebase = 0;
    let totalErrors = 0;

    deleteResults.forEach(result => {
      totalBookings += result.deletedRecords.bookings;
      totalDrivers += result.deletedRecords.drivers;
      totalProfiles += result.deletedRecords.userProfiles;
      totalUsers += result.deletedRecords.users;
      totalFirebase += result.deletedRecords.firebase ? 1 : 0;
      totalErrors += result.errors.length;
    });

    console.log(`刪除的帳號數量: ${deleteResults.length}`);
    console.log(`刪除的訂單記錄: ${totalBookings}`);
    console.log(`刪除的司機資料: ${totalDrivers}`);
    console.log(`刪除的用戶資料: ${totalProfiles}`);
    console.log(`刪除的用戶帳號: ${totalUsers}`);
    console.log(`刪除的 Firebase 帳號: ${totalFirebase}`);
    console.log(`錯誤數量: ${totalErrors}\n`);

    if (totalErrors > 0) {
      console.log('⚠️  錯誤詳情:');
      deleteResults.forEach(result => {
        if (result.errors.length > 0) {
          console.log(`\n${result.name} (${result.email}):`);
          result.errors.forEach(error => {
            console.log(`   - ${error}`);
          });
        }
      });
    }

    console.log('\n========================================');
    console.log('✅ 清理完成！');
    console.log('========================================\n');

  } catch (error) {
    console.error('\n❌ 清理過程中發生錯誤:', error);
    process.exit(1);
  }
}

main();

