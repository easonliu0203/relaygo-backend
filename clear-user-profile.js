/**
 * 清除用戶個人資料（用於測試降級策略）
 * 
 * 用法：
 * node clear-user-profile.js <email>
 * 
 * 範例：
 * node clear-user-profile.js customer.test@relaygo.com
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// 初始化 Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function clearUserProfile(email) {
  console.log('========================================');
  console.log('清除用戶個人資料');
  console.log('========================================\n');

  try {
    // 1. 查詢用戶
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, email, role')
      .eq('email', email)
      .single();

    if (userError || !user) {
      console.log(`❌ 用戶不存在: ${email}`);
      return;
    }

    console.log(`用戶資訊:`);
    console.log(`  Email: ${user.email}`);
    console.log(`  Role: ${user.role}`);
    console.log(`  User ID: ${user.id}`);
    console.log('');

    // 2. 檢查個人資料是否存在
    const { data: existingProfile } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (!existingProfile) {
      console.log('⚠️  個人資料不存在，無需清除');
      return;
    }

    console.log('當前個人資料:');
    console.log(`  姓氏 (Last Name): ${existingProfile.last_name || '未填寫'}`);
    console.log(`  名字 (First Name): ${existingProfile.first_name || '未填寫'}`);
    console.log('');

    // 3. 清除個人資料（設置為 NULL）
    console.log('清除個人資料...');
    const { error: updateError } = await supabase
      .from('user_profiles')
      .update({
        first_name: null,
        last_name: null,
        updated_at: new Date().toISOString()
      })
      .eq('user_id', user.id);

    if (updateError) {
      console.log(`❌ 清除失敗: ${updateError.message}`);
      return;
    }

    console.log('✅ 個人資料已清除');
    console.log('');
    console.log('降級策略測試:');
    console.log(`  聊天室將顯示: ${user.email.split('@')[0]} (從 Email 截取)`);
    console.log('');

    console.log('========================================');
    console.log('清除完成');
    console.log('========================================');

  } catch (error) {
    console.error('❌ 執行失敗:', error);
  }
}

// 從命令行參數獲取資訊
const email = process.argv[2];

if (!email) {
  console.log('用法: node clear-user-profile.js <email>');
  console.log('');
  console.log('範例:');
  console.log('  node clear-user-profile.js customer.test@relaygo.com');
  console.log('  node clear-user-profile.js driver.test@relaygo.com');
  console.log('');
  console.log('說明:');
  console.log('  - 清除用戶的個人資料（first_name, last_name）');
  console.log('  - 用於測試聊天室姓名顯示的降級策略');
  console.log('  - 清除後，聊天室將顯示從 Email 截取的用戶名');
  process.exit(1);
}

// 執行清除
clearUserProfile(email)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ 執行失敗:', error);
    process.exit(1);
  });

