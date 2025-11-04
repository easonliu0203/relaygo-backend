/**
 * 更新用戶個人資料（用於測試聊天室姓名顯示）
 * 
 * 用法：
 * node update-user-profile.js <email> <firstName> <lastName>
 * 
 * 範例：
 * node update-user-profile.js customer.test@relaygo.com 三 張
 * node update-user-profile.js driver.test@relaygo.com 四 李
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// 初始化 Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function updateUserProfile(email, firstName, lastName) {
  console.log('========================================');
  console.log('更新用戶個人資料');
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

    if (existingProfile) {
      // 更新現有個人資料
      console.log('更新現有個人資料...');
      const { error: updateError } = await supabase
        .from('user_profiles')
        .update({
          first_name: firstName,
          last_name: lastName,
          updated_at: new Date().toISOString()
        })
        .eq('user_id', user.id);

      if (updateError) {
        console.log(`❌ 更新失敗: ${updateError.message}`);
        return;
      }

      console.log('✅ 個人資料已更新');
    } else {
      // 創建新個人資料
      console.log('創建新個人資料...');
      const { error: insertError } = await supabase
        .from('user_profiles')
        .insert({
          user_id: user.id,
          first_name: firstName,
          last_name: lastName,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        });

      if (insertError) {
        console.log(`❌ 創建失敗: ${insertError.message}`);
        return;
      }

      console.log('✅ 個人資料已創建');
    }

    // 3. 查詢更新後的個人資料
    const { data: updatedProfile } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', user.id)
      .single();

    console.log('');
    console.log('更新後的個人資料:');
    console.log(`  姓氏 (Last Name): ${updatedProfile.last_name}`);
    console.log(`  名字 (First Name): ${updatedProfile.first_name}`);
    console.log(`  完整姓名: ${updatedProfile.last_name}${updatedProfile.first_name}`);
    console.log('');

    console.log('========================================');
    console.log('更新完成');
    console.log('========================================');

  } catch (error) {
    console.error('❌ 執行失敗:', error);
  }
}

// 從命令行參數獲取資訊
const email = process.argv[2];
const firstName = process.argv[3];
const lastName = process.argv[4];

if (!email || !firstName || !lastName) {
  console.log('用法: node update-user-profile.js <email> <firstName> <lastName>');
  console.log('');
  console.log('範例:');
  console.log('  node update-user-profile.js customer.test@relaygo.com 三 張');
  console.log('  node update-user-profile.js driver.test@relaygo.com 四 李');
  console.log('');
  console.log('說明:');
  console.log('  - email: 用戶的 Email 地址');
  console.log('  - firstName: 名字（例如：三、San）');
  console.log('  - lastName: 姓氏（例如：張、Zhang）');
  console.log('  - 完整姓名會組合成：lastName + firstName（例如：張三、Zhang San）');
  process.exit(1);
}

// 執行更新
updateUserProfile(email, firstName, lastName)
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ 執行失敗:', error);
    process.exit(1);
  });

