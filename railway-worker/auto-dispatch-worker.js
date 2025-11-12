/**
 * 24/7 全自動派單背景服務
 * 部署在 Railway，每 30 秒執行一次自動派單
 */

const { createClient } = require('@supabase/supabase-js');

// ============================================
// 環境變數配置
// ============================================
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
const INTERVAL_SECONDS = parseInt(process.env.INTERVAL_SECONDS || '30');
const BATCH_SIZE = parseInt(process.env.BATCH_SIZE || '10');

// ============================================
// Supabase 客戶端
// ============================================
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// ============================================
// 自動派單邏輯
// ============================================
async function autoDispatchOrders() {
  console.log(`[${new Date().toISOString()}] 開始執行自動派單...`);

  try {
    // 1. 檢查是否啟用自動派單
    const { data: settings, error: settingsError } = await supabase
      .from('system_settings')
      .select('value')
      .eq('key', 'auto_dispatch_24_7')
      .single();

    if (settingsError) {
      console.error('❌ 無法讀取系統設定:', settingsError);
      return;
    }

    const config = settings.value;
    
    if (!config.enabled) {
      console.log('⏸️  自動派單已停用，跳過本次執行');
      return;
    }

    console.log(`✅ 自動派單已啟用，批次大小: ${config.batch_size || BATCH_SIZE}`);

    // 2. 查詢待派單的訂單
    const { data: pendingBookings, error: bookingsError } = await supabase
      .from('bookings')
      .select(`
        id,
        pickup_location,
        dropoff_location,
        pickup_time,
        vehicle_type,
        estimated_price,
        status
      `)
      .eq('status', 'pending')
      .is('driver_id', null)
      .order('pickup_time', { ascending: true })
      .limit(config.batch_size || BATCH_SIZE);

    if (bookingsError) {
      console.error('❌ 查詢待派單訂單失敗:', bookingsError);
      return;
    }

    if (!pendingBookings || pendingBookings.length === 0) {
      console.log('📭 目前沒有待派單的訂單');
      await updateStats(config, 0, 0, 0);
      return;
    }

    console.log(`📦 找到 ${pendingBookings.length} 筆待派單訂單`);

    // 3. 為每筆訂單尋找合適的司機並派單
    let successCount = 0;
    let failCount = 0;

    for (const booking of pendingBookings) {
      try {
        const assigned = await assignDriverToBooking(booking);
        if (assigned) {
          successCount++;
          console.log(`✅ 訂單 ${booking.id} 派單成功`);
        } else {
          failCount++;
          console.log(`⚠️  訂單 ${booking.id} 找不到合適的司機`);
        }
      } catch (error) {
        failCount++;
        console.error(`❌ 訂單 ${booking.id} 派單失敗:`, error);
      }
    }

    // 4. 更新統計數據
    await updateStats(config, pendingBookings.length, successCount, failCount);

    console.log(`
📊 本次執行結果:
   - 處理訂單: ${pendingBookings.length} 筆
   - 成功派單: ${successCount} 筆
   - 派單失敗: ${failCount} 筆
    `);

  } catch (error) {
    console.error('❌ 自動派單執行失敗:', error);
  }
}

// ============================================
// 為訂單分配司機
// ============================================
async function assignDriverToBooking(booking) {
  // 1. 查詢可用的司機
  const { data: availableDrivers, error: driversError } = await supabase
    .from('drivers')
    .select('id, name, vehicle_type, current_location, status')
    .eq('status', 'available')
    .eq('vehicle_type', booking.vehicle_type);

  if (driversError || !availableDrivers || availableDrivers.length === 0) {
    return false;
  }

  // 2. 選擇最近的司機（簡化版，實際應該計算距離）
  const selectedDriver = availableDrivers[0];

  // 3. 更新訂單狀態
  const { error: updateError } = await supabase
    .from('bookings')
    .update({
      driver_id: selectedDriver.id,
      status: 'assigned',
      assigned_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    })
    .eq('id', booking.id);

  if (updateError) {
    console.error(`❌ 更新訂單 ${booking.id} 失敗:`, updateError);
    return false;
  }

  // 4. 更新司機狀態
  await supabase
    .from('drivers')
    .update({
      status: 'busy',
      updated_at: new Date().toISOString()
    })
    .eq('id', selectedDriver.id);

  return true;
}

// ============================================
// 更新統計數據
// ============================================
async function updateStats(currentConfig, processed, assigned, failed) {
  const updatedConfig = {
    ...currentConfig,
    last_run_at: new Date().toISOString(),
    total_processed: (currentConfig.total_processed || 0) + processed,
    total_assigned: (currentConfig.total_assigned || 0) + assigned,
    total_failed: (currentConfig.total_failed || 0) + failed
  };

  await supabase
    .from('system_settings')
    .update({
      value: updatedConfig,
      updated_at: new Date().toISOString()
    })
    .eq('key', 'auto_dispatch_24_7');
}

// ============================================
// 主程序
// ============================================
async function main() {
  console.log('🚀 24/7 自動派單服務啟動');
  console.log(`⏱️  執行間隔: ${INTERVAL_SECONDS} 秒`);
  console.log(`📦 批次大小: ${BATCH_SIZE} 筆`);
  console.log('─'.repeat(50));

  // 立即執行一次
  await autoDispatchOrders();

  // 設定定時執行
  setInterval(async () => {
    await autoDispatchOrders();
  }, INTERVAL_SECONDS * 1000);
}

// 啟動服務
main().catch(console.error);

// 優雅關閉
process.on('SIGTERM', () => {
  console.log('🛑 收到 SIGTERM 信號，正在關閉服務...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 收到 SIGINT 信號，正在關閉服務...');
  process.exit(0);
});

