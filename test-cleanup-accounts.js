const API_BASE_URL = 'http://localhost:3001';

async function checkAccounts() {
  console.log('\n========================================');
  console.log('步驟 1: 檢查當前帳號狀態');
  console.log('========================================\n');

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/cleanup-test-accounts`);
    const data = await response.json();

    if (!data.success) {
      console.error('❌ 查詢失敗:', data.error);
      return false;
    }

    console.log(`✅ 找到 ${data.total} 個用戶帳號\n`);

    console.log('📌 保留的帳號 (' + data.keepAccounts.length + '個):');
    console.log('─────────────────────────────────────────\n');
    data.keepAccounts.forEach((account, index) => {
      console.log(`${index + 1}. ${account.name}`);
      console.log(`   Email: ${account.email}`);
      console.log(`   角色: ${account.role}`);
      console.log(`   狀態: ${account.status}\n`);
    });

    console.log('🗑️  需要刪除的帳號 (' + data.deleteAccounts.length + '個):');
    console.log('─────────────────────────────────────────\n');
    data.deleteAccounts.forEach((account, index) => {
      console.log(`${index + 1}. ${account.name}`);
      console.log(`   Email: ${account.email}`);
      console.log(`   角色: ${account.role}`);
      console.log(`   狀態: ${account.status}\n`);
    });

    if (data.deleteAccounts.length === 0) {
      console.log('✅ 沒有需要刪除的帳號\n');
      return false;
    }

    return true;

  } catch (error) {
    console.error('❌ 查詢失敗:', error.message);
    return false;
  }
}

async function cleanupAccounts() {
  console.log('\n========================================');
  console.log('步驟 2: 執行清理操作');
  console.log('========================================\n');

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/cleanup-test-accounts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const data = await response.json();

    if (!data.success) {
      console.error('❌ 清理失敗:', data.error);
      if (data.details) {
        console.error('詳情:', data.details);
      }
      return;
    }

    console.log('✅ 清理完成！\n');

    console.log('========================================');
    console.log('清理報告');
    console.log('========================================\n');

    console.log(`總帳號數: ${data.summary.total}`);
    console.log(`保留帳號: ${data.summary.kept}`);
    console.log(`刪除帳號: ${data.summary.deleted}`);
    console.log(`剩餘帳號: ${data.summary.remaining}\n`);

    console.log('刪除的記錄:');
    console.log(`  - 訂單: ${data.summary.deletedRecords.bookings}`);
    console.log(`  - 司機資料: ${data.summary.deletedRecords.drivers}`);
    console.log(`  - 用戶資料: ${data.summary.deletedRecords.userProfiles}`);
    console.log(`  - 用戶帳號: ${data.summary.deletedRecords.users}\n`);

    if (data.summary.errors > 0) {
      console.log(`⚠️  錯誤數量: ${data.summary.errors}\n`);
      
      console.log('錯誤詳情:');
      data.deleteResults.forEach(result => {
        if (result.errors.length > 0) {
          console.log(`\n${result.email}:`);
          result.errors.forEach(error => {
            console.log(`   - ${error}`);
          });
        }
      });
      console.log('');
    }

    console.log('剩餘的帳號:');
    console.log('─────────────────────────────────────────\n');
    data.remainingUsers.forEach((user, index) => {
      console.log(`${index + 1}. ${user.email} (${user.role})`);
    });
    console.log('');

    // 顯示需要手動刪除的 Firebase 帳號
    const firebaseUids = data.deleteResults
      .filter(r => r.firebaseUid)
      .map(r => ({ email: r.email, uid: r.firebaseUid }));

    if (firebaseUids.length > 0) {
      console.log('========================================');
      console.log('⚠️  需要手動刪除的 Firebase 帳號');
      console.log('========================================\n');
      console.log('請在 Firebase Console 中手動刪除以下帳號：');
      console.log('https://console.firebase.google.com/project/relaygo-app/authentication/users\n');
      
      firebaseUids.forEach((item, index) => {
        console.log(`${index + 1}. ${item.email}`);
        console.log(`   UID: ${item.uid}\n`);
      });
    }

  } catch (error) {
    console.error('❌ 清理失敗:', error.message);
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
  console.log('  3. admin@example.com (管理員)');
  console.log('========================================\n');

  // 步驟 1: 檢查帳號
  const hasAccountsToDelete = await checkAccounts();

  if (!hasAccountsToDelete) {
    console.log('========================================');
    console.log('✅ 清理完成！');
    console.log('========================================\n');
    return;
  }

  // 步驟 2: 執行清理
  await cleanupAccounts();

  console.log('========================================');
  console.log('✅ 清理完成！');
  console.log('========================================\n');
}

main();

