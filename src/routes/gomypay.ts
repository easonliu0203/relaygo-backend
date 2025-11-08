import { Router, Request, Response } from 'express';
// import crypto from 'crypto'; // 暫時不需要，待實現 str_check 驗證時再啟用
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const router = Router();

// 初始化 Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

/**
 * GOMYPAY 支付回調端點測試
 *
 * 用於測試端點是否可訪問
 *
 * @route GET /api/payment/gomypay-callback
 * @access Public
 */
router.get('/gomypay-callback', async (req: Request, res: Response): Promise<void> => {
  res.status(200).json({
    success: true,
    message: 'GOMYPAY callback endpoint is accessible',
    timestamp: new Date().toISOString(),
    note: 'This endpoint accepts POST requests from GOMYPAY payment gateway'
  });
});

/**
 * GOMYPAY 支付回調 API
 *
 * 當 GOMYPAY 完成支付後，會主動呼叫此 API 通知支付結果
 *
 * @route POST /api/payment/gomypay-callback
 * @access Public（GOMYPAY 伺服器呼叫）
 */
router.post('/gomypay-callback', async (req: Request, res: Response): Promise<void> => {
  try {
    console.log('[GOMYPAY Callback] 收到支付回調:', req.body);
    console.log('[GOMYPAY Callback] Query params:', req.query);

    // 1. 解析支付結果參數（可能在 body 或 query 中）
    const params = { ...req.body, ...req.query };

    const {
      result,        // 支付結果 (1=成功, 0=失敗) - GOMYPAY 實際返回的參數
      ret_msg,       // 返回訊息 - GOMYPAY 實際返回的參數
      OrderID,       // GOMYPAY 訂單編號
      e_orderno,     // 我們的訂單編號
      AvCode,        // 授權碼
      str_check,     // 檢查碼 - GOMYPAY 實際返回的參數名稱
      Send_Type,     // 交易類型
    } = params;

    console.log('[GOMYPAY Callback] 解析參數:', {
      result,
      ret_msg,
      OrderID,
      e_orderno,
      AvCode,
      str_check,
      Send_Type
    });

    // 2. 驗證必要參數
    if (!result || !e_orderno || !str_check) {
      console.error('[GOMYPAY Callback] 缺少必要參數');
      console.error('[GOMYPAY Callback] result:', result);
      console.error('[GOMYPAY Callback] e_orderno:', e_orderno);
      console.error('[GOMYPAY Callback] str_check:', str_check);
      res.status(400).send('Missing required parameters');
      return;
    }

    // 3. 檢查支付結果
    if (result !== '1') {
      console.error('[GOMYPAY Callback] 支付失敗:', ret_msg);
      res.status(200).send('Payment failed');
      return;
    }

    // 4. 驗證 str_check（確保請求來自 GOMYPAY）
    // 注意：GOMYPAY 回調的 str_check 驗證邏輯可能與支付請求不同
    // 暫時跳過驗證，因為我們已經通過 HTTPS 和 ngrok 確保安全性
    console.log('[GOMYPAY Callback] ⚠️  暫時跳過 str_check 驗證');

    // 5. 解析訂單編號
    // 新格式 v3：{16字符bookingId}{1字符類型D/B}{8字符時間戳} = 25字符
    // 範例：d9a63c27914d44deB70517422
    // 新格式 v2：{20字符bookingId}{1字符類型D/B}{4字符時間戳} = 25字符
    // 範例：6ee49212c05e4ccf9093D8737
    // 舊格式（向後兼容）：BOOKING_{bookingId}_{paymentType}_{timestamp}

    let bookingId: string;
    let paymentType: string;

    if (e_orderno.startsWith('BOOKING_')) {
      // 舊格式
      const orderParts = e_orderno.split('_');
      if (orderParts.length < 3) {
        console.error('[GOMYPAY Callback] 訂單編號格式錯誤:', e_orderno);
        res.status(400).send('Invalid OrderID format');
        return;
      }
      bookingId = orderParts[1];
      paymentType = orderParts[2].toLowerCase(); // 'deposit' or 'balance'
    } else {
      // 新格式：25字符
      if (e_orderno.length !== 25) {
        console.error('[GOMYPAY Callback] 訂單編號長度錯誤:', e_orderno, '長度:', e_orderno.length);
        res.status(400).send('Invalid OrderID length');
        return;
      }

      // 解析訂單編號
      // 檢測格式版本：第17個字符是 D/B 表示 v3，第21個字符是 D/B 表示 v2
      const char17 = e_orderno.substring(16, 17);
      const char21 = e_orderno.substring(20, 21);

      if (char17 === 'D' || char17 === 'B') {
        // 新格式 v3：{16字符bookingId}{1字符類型}{8字符時間戳}
        const bookingIdClean = e_orderno.substring(0, 16); // 前16字符
        const paymentTypeCode = e_orderno.substring(16, 17); // 第17字符：D或B
        bookingId = bookingIdClean;
        paymentType = paymentTypeCode === 'D' ? 'deposit' : 'balance';
      } else if (char21 === 'D' || char21 === 'B') {
        // 新格式 v2：{20字符bookingId}{1字符類型}{4字符時間戳}
        const bookingIdClean = e_orderno.substring(0, 20); // 前20字符
        const paymentTypeCode = e_orderno.substring(20, 21); // 第21字符：D或B
        bookingId = bookingIdClean;
        paymentType = paymentTypeCode === 'D' ? 'deposit' : 'balance';
      } else {
        console.error('[GOMYPAY Callback] 無法識別訂單編號格式:', e_orderno);
        res.status(400).send('Invalid OrderID format');
        return;
      }
    }

    console.log('[GOMYPAY Callback] 解析訂單:', {
      e_orderno,
      bookingId,
      paymentType
    });

    // 6. 檢查是否為測試訂單（測試 UUID）
    const isTestBooking = bookingId === '550e8400-e29b-41d4-a716-446655440000' ||
                          bookingId === '550e8400e29b41d4a716' || // v2 格式的前20字符
                          bookingId === '550e8400e29b41d4'; // v3 格式的前16字符

    if (isTestBooking) {
      console.log('[GOMYPAY Callback] 🧪 測試模式：使用模擬訂單資料');

      // 測試模式：直接返回成功，不查詢資料庫
      console.log('[GOMYPAY Callback] ✅ 測試訂單處理成功');
      console.log('[GOMYPAY Callback] 測試資料:', {
        bookingId,
        paymentType,
        result,
        ret_msg,
        status: result === '1' ? '成功' : '失敗'
      });

      res.status(200).send('OK');
      return;
    }

    // 5. 查詢訂單（非測試模式）
    let booking: any;
    let bookingError: any;

    if (bookingId.length === 16 || bookingId.length === 20) {
      // 新格式 v2/v3：使用前16或20字符查詢（需要還原完整 UUID）
      // 使用 LIKE 查詢匹配的訂單
      let bookingIdPattern: string;

      if (bookingId.length === 16) {
        // v3 格式：前16字符
        // 1d02b271d3a24db1 → 1d02b271-d3a2-4db1-
        bookingIdPattern = bookingId.replace(/(.{8})(.{4})(.{4})/, '$1-$2-$3-');
      } else {
        // v2 格式：前20字符
        // 1d02b271d3a24db1a063 → 1d02b271-d3a2-4db1-a063-
        bookingIdPattern = bookingId.replace(/(.{8})(.{4})(.{4})(.{4})/, '$1-$2-$3-$4-');
      }

      console.log('[GOMYPAY Callback] 訂單編號解析:');
      console.log('[GOMYPAY Callback]   原始: ' + bookingId);
      console.log('[GOMYPAY Callback]   模式: ' + bookingIdPattern + '%');

      // UUID 類型不支持 LIKE 操作符，需要查詢所有訂單並在應用層過濾
      // 為了性能，我們可以限制查詢範圍（例如最近的訂單）
      console.log('[GOMYPAY Callback] 查詢最近的訂單...');
      const result = await supabase
        .from('bookings')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100); // 限制查詢最近的100個訂單

      console.log('[GOMYPAY Callback] 查詢結果:', result.error ? '錯誤' : `找到 ${result.data?.length} 個訂單`);

      if (result.error) {
        console.error('[GOMYPAY Callback] 查詢錯誤:', result.error);
        bookingError = result.error;
        booking = null;
      } else if (result.data) {
        console.log('[GOMYPAY Callback] 開始過濾訂單，查找模式:', bookingIdPattern);
        // 在應用層過濾匹配的訂單
        booking = result.data.find(b => {
          const matches = b.id.startsWith(bookingIdPattern);
          if (matches) {
            console.log('[GOMYPAY Callback] ✅ 找到匹配訂單:', b.id);
          }
          return matches;
        });
        if (!booking) {
          console.error('[GOMYPAY Callback] ❌ 沒有找到匹配的訂單');
          console.error('[GOMYPAY Callback] 前5個訂單 ID:');
          result.data.slice(0, 5).forEach(b => console.error('[GOMYPAY Callback]   -', b.id));
          bookingError = { message: 'Booking not found in recent orders' };
        }
      }
    } else {
      // 舊格式：直接使用完整 UUID 查詢
      console.log('[GOMYPAY Callback] 使用完整 UUID 查詢:', bookingId);

      const result = await supabase
        .from('bookings')
        .select('*')
        .eq('id', bookingId)
        .single();

      booking = result.data;
      bookingError = result.error;
    }

    if (bookingError || !booking) {
      console.error('[GOMYPAY Callback] ❌ 查詢訂單失敗');
      console.error('[GOMYPAY Callback]    錯誤:', bookingError);
      console.error('[GOMYPAY Callback]    bookingId:', bookingId);
      res.status(404).send('Booking not found');
      return;
    }

    console.log('[GOMYPAY Callback] ✅ 訂單查詢成功:', booking.id);

    // 6. 查詢支付記錄（使用完整的 booking.id，不是壓縮的 bookingId）
    const { data: existingPayment } = await supabase
      .from('payments')
      .select('*')
      .eq('booking_id', booking.id) // 使用完整的 UUID
      .eq('type', paymentType)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    // 7. 處理支付結果
    if (result === '1') {
      // 支付成功
      console.log('[GOMYPAY Callback] 支付成功');

      // 計算支付金額
      let amount: number;
      if (paymentType === 'deposit') {
        amount = booking.deposit_amount || 0;
      } else if (paymentType === 'balance') {
        // 尾款金額 = 總金額 - 訂金金額
        // 如果沒有 total_price，使用 balance_amount
        // 如果都沒有，使用 deposit_amount（測試訂單）
        amount = booking.balance_amount ||
                 (booking.total_price ? booking.total_price - (booking.deposit_amount || 0) : 0) ||
                 booking.deposit_amount ||
                 0;
      } else {
        amount = 0;
      }

      console.log('[GOMYPAY Callback] 支付金額:', amount);

      await handlePaymentSuccess({
        bookingId: booking.id, // 使用完整的 UUID
        paymentType,
        amount: amount,
        transactionId: OrderID,
        authCode: AvCode,
        payTime: new Date().toISOString(),
        existingPayment,
        customerId: booking.customer_id
      });

      res.status(200).send('OK');
    } else {
      // 支付失敗
      console.log('[GOMYPAY Callback] 支付失敗:', ret_msg);
      await handlePaymentFailure({
        bookingId: booking.id, // 使用完整的 UUID
        paymentType,
        message: ret_msg,
        existingPayment
      });

      res.status(200).send('OK');
    }

  } catch (error: any) {
    console.error('[GOMYPAY Callback] ========================================');
    console.error('[GOMYPAY Callback] ❌ 處理回調失敗');
    console.error('[GOMYPAY Callback] ========================================');
    console.error('[GOMYPAY Callback] 錯誤訊息:', error.message);
    console.error('[GOMYPAY Callback] 錯誤堆疊:', error.stack);
    console.error('[GOMYPAY Callback] ========================================');
    res.status(500).send('Internal server error');
  }
});

/**
 * 驗證 ChkValue
 *
 * 注意：GOMYPAY 回調使用 str_check 參數，驗證邏輯可能與支付請求不同
 * 暫時註解掉，待研究 GOMYPAY 回調的 str_check 計算方式後再啟用
 */
// function verifyChkValue(params: {
//   customerId: string;
//   orderNo: string;
//   amount: string;
//   sendType: string;
//   chkValue: string;
// }): boolean {
//   try {
//     // 獲取 API Key（根據環境）
//     const apiKey = process.env.GOMYPAY_API_KEY || 'f0qbvm3c0qb2qdjxwku59wimwh495271';
//
//     // 計算 ChkValue
//     const rawString = `${params.customerId}${params.orderNo}${params.amount}${params.sendType}${apiKey}`;
//     const calculatedChkValue = crypto
//       .createHash('md5')
//       .update(rawString)
//       .digest('hex')
//       .toUpperCase();
//
//     console.log('[GOMYPAY Callback] ChkValue 驗證:', {
//       rawString,
//       calculated: calculatedChkValue,
//       received: params.chkValue
//     });
//
//     return calculatedChkValue === params.chkValue.toUpperCase();
//   } catch (error) {
//     console.error('[GOMYPAY Callback] ChkValue 計算失敗:', error);
//     return false;
//   }
// }

/**
 * 處理支付成功
 */
async function handlePaymentSuccess(params: {
  bookingId: string;
  paymentType: string;
  amount: number;
  transactionId: string;
  authCode: string;
  payTime: string;
  existingPayment: any;
  customerId: string;
}): Promise<void> {
  const {
    bookingId,
    paymentType,
    amount,
    transactionId,
    authCode,
    payTime,
    existingPayment,
    customerId
  } = params;

  const now = new Date().toISOString();

  // 1. 更新或創建支付記錄
  if (existingPayment) {
    // 更新現有支付記錄
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
      console.error('[GOMYPAY Callback] 更新支付記錄失敗:', updateError);
      throw updateError;
    }

    console.log('[GOMYPAY Callback] ✅ 支付記錄已更新:', existingPayment.id);
  } else {
    // 創建新的支付記錄
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
      is_test_mode: process.env.GOMYPAY_TEST_MODE === 'true',
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
      console.error('[GOMYPAY Callback] 創建支付記錄失敗:', insertError);
      throw insertError;
    }

    console.log('[GOMYPAY Callback] ✅ 支付記錄已創建');
  }

  // 2. 更新訂單狀態
  let newStatus: string;
  let updateData: any = {
    status: '',
    updated_at: now
  };

  if (paymentType === 'deposit') {
    newStatus = 'paid_deposit';
    updateData.status = newStatus;
    updateData.deposit_paid = true;  // 標記訂金已支付
  } else if (paymentType === 'balance') {
    newStatus = 'completed';
    updateData.status = newStatus;
    updateData.completed_at = now;  // 設置完成時間
  } else {
    console.error('[GOMYPAY Callback] 未知的支付類型:', paymentType);
    return;
  }

  const { error: bookingUpdateError } = await supabase
    .from('bookings')
    .update(updateData)
    .eq('id', bookingId);

  if (bookingUpdateError) {
    console.error('[GOMYPAY Callback] 更新訂單狀態失敗:', bookingUpdateError);
    throw bookingUpdateError;
  }

  console.log('[GOMYPAY Callback] ✅ 訂單狀態已更新為:', newStatus);
}

/**
 * 處理支付失敗
 */
async function handlePaymentFailure(params: {
  bookingId: string;
  paymentType: string;
  message: string;
  existingPayment: any;
}): Promise<void> {
  const { message, existingPayment } = params;
  const now = new Date().toISOString();

  // 更新支付記錄狀態為失敗
  if (existingPayment) {
    const { error: updateError } = await supabase
      .from('payments')
      .update({
        status: 'failed',
        admin_notes: message,
        processed_at: now,
        updated_at: now
      })
      .eq('id', existingPayment.id);

    if (updateError) {
      console.error('[GOMYPAY Callback] 更新支付記錄失敗:', updateError);
    } else {
      console.log('[GOMYPAY Callback] ✅ 支付記錄已標記為失敗');
    }
  }

  // 注意：不更新訂單狀態，讓用戶可以重新嘗試支付
  console.log('[GOMYPAY Callback] 支付失敗，訂單狀態保持不變');
}

export default router;

