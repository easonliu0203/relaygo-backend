const API_BASE_URL = 'http://localhost:3001';

async function checkCurrentAccounts() {
  console.log('\n========================================');
  console.log('檢查當前資料庫帳號狀態');
  console.log('========================================\n');

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/cleanup-test-accounts`);
    const data = await response.json();

    if (!data.success) {
      console.error('❌ 查詢失敗:', data.error);
      return;
    }

    console.log(`✅ 找到 ${data.total} 個用戶帳號\n`);

    console.log('所有帳號列表:');
    console.log('─────────────────────────────────────────\n');

    // 合併所有帳號
    const allAccounts = [...data.keepAccounts, ...data.deleteAccounts];

    allAccounts.forEach((account, index) => {
      console.log(`${index + 1}. ${account.name}`);
      console.log(`   Email: ${account.email}`);
      console.log(`   角色: ${account.role}`);
      console.log(`   狀態: ${account.status}`);
      console.log(`   ID: ${account.id}\n`);
    });

    // 檢查需要保留的帳號
    const requiredAccounts = [
      { email: 'customer.test@relaygo.com', name: '王小明', role: 'customer' },
      { email: 'driver.test@relaygo.com', name: '李小花', role: 'driver' },
      { email: 'admin@example.com', name: '管理員', role: 'admin' }
    ];

    console.log('========================================');
    console.log('檢查需要保留的帳號');
    console.log('========================================\n');

    requiredAccounts.forEach(required => {
      const found = allAccounts.find(acc => acc.email === required.email);
      if (found) {
        console.log(`✅ ${required.name} (${required.email})`);
        console.log(`   狀態: 存在`);
        console.log(`   角色: ${found.role}`);
        console.log(`   ID: ${found.id}\n`);
      } else {
        console.log(`❌ ${required.name} (${required.email})`);
        console.log(`   狀態: 不存在（可能已被刪除）\n`);
      }
    });

    // 檢查是否有誤刪
    const missingAccounts = requiredAccounts.filter(
      required => !allAccounts.find(acc => acc.email === required.email)
    );

    if (missingAccounts.length > 0) {
      console.log('========================================');
      console.log('⚠️  警告：發現缺失的帳號');
      console.log('========================================\n');
      console.log('以下帳號需要重新創建：\n');
      missingAccounts.forEach(account => {
        console.log(`- ${account.name} (${account.email})`);
      });
      console.log('');
    }

  } catch (error) {
    console.error('❌ 查詢失敗:', error.message);
  }
}

checkCurrentAccounts();

