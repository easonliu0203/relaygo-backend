const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://yfkzacfavkeqzpjhzwqo.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlma3phY2ZhdmtlcXpwamh6d3FvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNzY4MzI0NCwiZXhwIjoyMDQzMjU5MjQ0fQ.yaIUUniLXyT-ST5xlKhLhwxd-kYdvVLVHqLNTE_Wkxo';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function checkFirebaseUIDs() {
  console.log('\n========================================');
  console.log('檢查 Firebase UID');
  console.log('========================================\n');

  try {
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
          last_name
        )
      `)
      .order('email', { ascending: true });

    if (error) {
      console.error('❌ 查詢失敗:', error);
      return;
    }

    console.log(`✅ 找到 ${users.length} 個用戶帳號\n`);

    users.forEach((user, index) => {
      const profile = user.user_profiles?.[0] || user.user_profiles;
      const name = profile 
        ? `${profile.first_name || ''} ${profile.last_name || ''}`.trim() 
        : '未知';

      console.log(`${index + 1}. ${name}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Firebase UID: ${user.firebase_uid}`);
      console.log(`   角色: ${user.role}`);
      console.log(`   狀態: ${user.status}`);
      console.log(`   Supabase ID: ${user.id}\n`);
    });

    // 檢查需要保留的帳號
    console.log('========================================');
    console.log('驗證需要保留的帳號');
    console.log('========================================\n');

    const requiredAccounts = [
      { 
        email: 'customer.test@relaygo.com', 
        name: '王小明', 
        expectedFirebaseUID: 'hUu4fH5dTlW9VUYm6GojXvRLdni2',
        role: 'customer' 
      },
      { 
        email: 'driver.test@relaygo.com', 
        name: '李小花', 
        expectedFirebaseUID: 'CMfTxhJFlUVDkosJPyUoJvKjCQk1',
        role: 'driver' 
      },
      { 
        email: 'admin@example.com', 
        name: '管理員', 
        expectedFirebaseUID: null,
        role: 'admin' 
      }
    ];

    requiredAccounts.forEach(required => {
      const found = users.find(u => u.email === required.email);
      
      if (found) {
        const uidMatch = !required.expectedFirebaseUID || 
                        found.firebase_uid === required.expectedFirebaseUID;
        
        console.log(`${uidMatch ? '✅' : '⚠️'} ${required.name} (${required.email})`);
        console.log(`   狀態: 存在`);
        console.log(`   Firebase UID: ${found.firebase_uid}`);
        
        if (required.expectedFirebaseUID) {
          console.log(`   預期 UID: ${required.expectedFirebaseUID}`);
          console.log(`   UID 匹配: ${uidMatch ? '是' : '否'}`);
        }
        
        console.log('');
      } else {
        console.log(`❌ ${required.name} (${required.email})`);
        console.log(`   狀態: 不存在\n`);
      }
    });

  } catch (error) {
    console.error('❌ 查詢失敗:', error);
  }
}

checkFirebaseUIDs();

