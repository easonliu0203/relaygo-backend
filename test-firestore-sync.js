/**
 * Firestore 同步測試腳本
 * 
 * 用途：自動驗證 Firestore 同步是否正常工作
 * 
 * 使用方法：
 * 1. 安裝依賴：npm install node-fetch
 * 2. 設置環境變數：
 *    - SUPABASE_URL
 *    - SUPABASE_SERVICE_ROLE_KEY
 *    - FIREBASE_PROJECT_ID
 * 3. 執行：node test-firestore-sync.js
 */

const fetch = require('node-fetch');

// 配置
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://vlyhwegpvpnjyocqmfqc.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID;

// 顏色輸出
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function success(message) {
  log(`✅ ${message}`, 'green');
}

function error(message) {
  log(`❌ ${message}`, 'red');
}

function warning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

function info(message) {
  log(`ℹ️  ${message}`, 'blue');
}

function section(message) {
  log(`\n${'='.repeat(60)}`, 'cyan');
  log(message, 'cyan');
  log('='.repeat(60), 'cyan');
}

// 測試結果
const results = {
  total: 0,
  passed: 0,
  failed: 0,
  warnings: 0,
};

function test(name, passed, message = '') {
  results.total++;
  if (passed) {
    results.passed++;
    success(`${name}: PASS ${message}`);
  } else {
    results.failed++;
    error(`${name}: FAIL ${message}`);
  }
}

// 主測試函數
async function runTests() {
  section('🚀 開始 Firestore 同步測試');

  // 檢查環境變數
  section('1️⃣ 檢查環境變數');
  
  if (!SUPABASE_SERVICE_ROLE_KEY) {
    error('SUPABASE_SERVICE_ROLE_KEY 未設置');
    process.exit(1);
  }
  success('SUPABASE_SERVICE_ROLE_KEY 已設置');

  if (!FIREBASE_PROJECT_ID) {
    warning('FIREBASE_PROJECT_ID 未設置（可選）');
  } else {
    success(`FIREBASE_PROJECT_ID: ${FIREBASE_PROJECT_ID}`);
  }

  // 測試 Edge Function
  section('2️⃣ 測試 Edge Function');

  try {
    info('觸發 sync-to-firestore...');
    
    const response = await fetch(`${SUPABASE_URL}/functions/v1/sync-to-firestore`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();
    
    test('Edge Function 回應', response.ok, `Status: ${response.status}`);
    
    if (data.success !== undefined) {
      test('同步成功數量', data.success > 0, `成功: ${data.success}, 失敗: ${data.failure}`);
      test('同步失敗數量', data.failure === 0, `失敗: ${data.failure}`);
    }

    info(`回應: ${JSON.stringify(data, null, 2)}`);

  } catch (err) {
    error(`Edge Function 測試失敗: ${err.message}`);
    results.failed++;
  }

  // 檢查 Supabase 資料
  section('3️⃣ 檢查 Supabase 資料');

  try {
    info('查詢 bookings 表...');
    
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/bookings?select=*&limit=5`,
      {
        headers: {
          'apikey': SUPABASE_SERVICE_ROLE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );

    const bookings = await response.json();
    
    test('Bookings 資料存在', bookings.length > 0, `找到 ${bookings.length} 筆訂單`);

    if (bookings.length > 0) {
      const booking = bookings[0];
      
      test('Booking 有 ID', !!booking.id);
      test('Booking 有 customer_id', !!booking.customer_id);
      test('Booking 有 pickup_address', !!booking.pickup_address);
      test('Booking 有 destination', !!booking.destination);
      test('Booking 有 status', !!booking.status);

      info(`範例訂單: ${booking.id}`);
      info(`  - 客戶: ${booking.customer_id}`);
      info(`  - 上車: ${booking.pickup_address}`);
      info(`  - 目的地: ${booking.destination}`);
      info(`  - 狀態: ${booking.status}`);
    }

  } catch (err) {
    error(`Supabase 資料檢查失敗: ${err.message}`);
    results.failed++;
  }

  // 檢查 Outbox 事件
  section('4️⃣ 檢查 Outbox 事件');

  try {
    info('查詢 outbox 表...');
    
    const response = await fetch(
      `${SUPABASE_URL}/rest/v1/outbox?select=*&order=created_at.desc&limit=5`,
      {
        headers: {
          'apikey': SUPABASE_SERVICE_ROLE_KEY,
          'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        },
      }
    );

    const events = await response.json();
    
    test('Outbox 事件存在', events.length > 0, `找到 ${events.length} 個事件`);

    if (events.length > 0) {
      const event = events[0];
      
      test('Event 有 ID', !!event.id);
      test('Event 有 aggregate_type', event.aggregate_type === 'booking');
      test('Event 有 event_type', !!event.event_type);
      test('Event 有 payload', !!event.payload);

      info(`最新事件: ${event.id}`);
      info(`  - 類型: ${event.event_type}`);
      info(`  - 時間: ${event.created_at}`);
      info(`  - 已處理: ${event.processed ? '是' : '否'}`);

      // 檢查 payload 格式
      if (event.payload) {
        const payload = event.payload;
        
        test('Payload 有 bookingId', !!payload.bookingId);
        test('Payload 有 customerId', !!payload.customerId);
        test('Payload 有 pickupAddress', !!payload.pickupAddress);
        test('Payload 有 destination', !!payload.destination);
      }
    }

  } catch (err) {
    error(`Outbox 事件檢查失敗: ${err.message}`);
    results.failed++;
  }

  // 顯示測試結果
  section('📊 測試結果');

  info(`總測試數: ${results.total}`);
  success(`通過: ${results.passed}`);
  if (results.failed > 0) {
    error(`失敗: ${results.failed}`);
  }
  if (results.warnings > 0) {
    warning(`警告: ${results.warnings}`);
  }

  const passRate = ((results.passed / results.total) * 100).toFixed(1);
  
  if (results.failed === 0) {
    success(`\n🎉 所有測試通過！(${passRate}%)`);
  } else {
    error(`\n❌ 有 ${results.failed} 個測試失敗 (${passRate}%)`);
  }

  // 下一步建議
  section('🎯 下一步');

  if (results.failed === 0) {
    info('1. 檢查 Firebase Console 中的 Firestore 資料');
    info('2. 確認 pickupLocation 和 dropoffLocation 類型是 geopoint');
    info('3. 測試客戶端 App 是否可以正常顯示訂單');
  } else {
    info('1. 檢查 Edge Function 日誌：');
    info(`   ${SUPABASE_URL.replace('https://', 'https://supabase.com/dashboard/project/')}/functions`);
    info('2. 檢查環境變數是否正確設置');
    info('3. 確認 Service Account 格式正確');
  }

  process.exit(results.failed > 0 ? 1 : 0);
}

// 執行測試
runTests().catch(err => {
  error(`測試執行失敗: ${err.message}`);
  console.error(err);
  process.exit(1);
});

