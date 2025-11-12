/**
 * 測試聊天 API
 * 
 * 測試內容：
 * 1. 發送訊息 API
 * 2. 獲取聊天室列表 API
 * 3. 獲取聊天訊息 API
 * 4. 標記訊息為已讀 API
 */

const BASE_URL = 'http://localhost:3001';

// 測試帳號
const CUSTOMER_UID = 'hUu4fH5dTlW9VUYm6GojXvRLdni2'; // 王小明
const DRIVER_UID = 'CMfTxhJFlUVDkosJPyUoJvKjCQk1';   // 李小花

async function testSendMessage() {
  console.log('\n========================================');
  console.log('測試 1: 發送訊息 API');
  console.log('========================================\n');

  try {
    // 首先需要有一個已配對的訂單
    // 這裡假設已經有訂單，需要先創建一個測試訂單
    console.log('⚠️ 此測試需要先有一個已配對的訂單');
    console.log('請先在公司端創建訂單並分配司機');
    
    return false;
  } catch (error) {
    console.error('❌ 測試失敗:', error.message);
    return false;
  }
}

async function testGetChatRooms() {
  console.log('\n========================================');
  console.log('測試 2: 獲取聊天室列表 API');
  console.log('========================================\n');

  try {
    // 測試客戶端獲取聊天室
    console.log('測試客戶端獲取聊天室...');
    const customerResponse = await fetch(`${BASE_URL}/api/chat/rooms?userId=${CUSTOMER_UID}`);
    const customerData = await customerResponse.json();

    console.log('客戶端響應:', JSON.stringify(customerData, null, 2));

    // 測試司機端獲取聊天室
    console.log('\n測試司機端獲取聊天室...');
    const driverResponse = await fetch(`${BASE_URL}/api/chat/rooms?userId=${DRIVER_UID}`);
    const driverData = await driverResponse.json();

    console.log('司機端響應:', JSON.stringify(driverData, null, 2));

    if (customerData.success && driverData.success) {
      console.log('\n✅ 獲取聊天室列表 API 測試通過');
      return true;
    } else {
      console.log('\n❌ 獲取聊天室列表 API 測試失敗');
      return false;
    }
  } catch (error) {
    console.error('❌ 測試失敗:', error.message);
    return false;
  }
}

async function main() {
  console.log('開始測試聊天 API...\n');

  const results = {
    sendMessage: false,
    getChatRooms: false,
  };

  // 測試 1: 發送訊息（需要先有訂單）
  results.sendMessage = await testSendMessage();

  // 測試 2: 獲取聊天室列表
  results.getChatRooms = await testGetChatRooms();

  // 總結
  console.log('\n========================================');
  console.log('測試總結');
  console.log('========================================\n');

  console.log('測試結果:');
  console.log(`  1. 發送訊息 API: ${results.sendMessage ? '✅ 通過' : '⚠️ 跳過（需要先創建訂單）'}`);
  console.log(`  2. 獲取聊天室列表 API: ${results.getChatRooms ? '✅ 通過' : '❌ 失敗'}`);

  console.log('\n========================================');
  console.log('下一步操作');
  console.log('========================================\n');

  console.log('1. 執行 SQL migration 創建 chat_messages 表:');
  console.log('   - 打開 Supabase SQL Editor');
  console.log('   - 執行文件: supabase/migrations/20251011_create_chat_messages_table.sql');
  console.log('');
  console.log('2. 在公司端創建一個測試訂單並分配司機');
  console.log('');
  console.log('3. 測試發送訊息功能');
  console.log('');
  console.log('4. 實作 Flutter UI 頁面');
  console.log('');
}

main().catch(console.error);

