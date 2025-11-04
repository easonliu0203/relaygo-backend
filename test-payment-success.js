// 測試支付成功處理
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function testPaymentSuccess() {
  console.log('========================================');
  console.log('測試支付成功處理');
  console.log('========================================');
  
  const bookingId = '1d02b271-d3a2-4db1-a063-c094ba83e9bf';
  const paymentType = 'balance';
  const amount = 1000;
  const transactionId = '2025110100000000009';
  const authCode = '123456';
  const payTime = new Date().toISOString();
  const customerId = 'c03f0310-d3c8-44ab-8aec-1a4a858c52cb';
  
  console.log('參數:');
  console.log('  bookingId:', bookingId);
  console.log('  paymentType:', paymentType);
  console.log('  amount:', amount);
  console.log('');
  
  try {
    // 1. 查詢現有支付記錄
    console.log('1. 查詢現有支付記錄...');
    const { data: existingPayment } = await supabase
      .from('payments')
      .select('*')
      .eq('booking_id', bookingId)
      .eq('type', paymentType)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();
    
    console.log('現有支付記錄:', existingPayment ? existingPayment.id : '無');
    console.log('');
    
    // 2. 更新或創建支付記錄
    const now = new Date().toISOString();
    
    if (existingPayment) {
      console.log('2. 更新現有支付記錄...');
      const { error: updateError } = await supabase
        .from('payments')
        .update({
          status: 'completed',
          external_transaction_id: authCode,
          confirmed_at: payTime || now,
          processed_at: now,
          updated_at: now
        })
        .eq('id', existingPayment.id);
      
      if (updateError) {
        console.error('❌ 更新支付記錄失敗:', updateError);
        throw updateError;
      }
      
      console.log('✅ 支付記錄已更新');
    } else {
      console.log('2. 創建新的支付記錄...');
      const paymentData = {
        booking_id: bookingId,
        customer_id: customerId,
        transaction_id: transactionId,
        type: paymentType,
        amount: amount,
        currency: 'TWD',
        status: 'completed',
        payment_provider: 'gomypay',
        payment_method: 'credit_card',
        is_test_mode: true,
        external_transaction_id: authCode,
        confirmed_at: payTime || now,
        processed_at: now,
        created_at: now,
        updated_at: now
      };
      
      const { error: insertError } = await supabase
        .from('payments')
        .insert(paymentData);
      
      if (insertError) {
        console.error('❌ 創建支付記錄失敗:', insertError);
        throw insertError;
      }
      
      console.log('✅ 支付記錄已創建');
    }
    
    console.log('');
    
    // 3. 更新訂單狀態
    console.log('3. 更新訂單狀態...');
    const newStatus = paymentType === 'deposit' ? 'paid_deposit' : 'completed';
    
    const { error: bookingUpdateError } = await supabase
      .from('bookings')
      .update({
        status: newStatus,
        updated_at: now
      })
      .eq('id', bookingId);
    
    if (bookingUpdateError) {
      console.error('❌ 更新訂單狀態失敗:', bookingUpdateError);
      throw bookingUpdateError;
    }
    
    console.log('✅ 訂單狀態已更新為:', newStatus);
    console.log('');
    console.log('========================================');
    console.log('✅ 測試成功！');
    console.log('========================================');
    
  } catch (error) {
    console.error('');
    console.error('========================================');
    console.error('❌ 測試失敗');
    console.error('========================================');
    console.error('錯誤:', error);
    console.error('========================================');
  }
}

testPaymentSuccess().catch(console.error);

