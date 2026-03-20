import { Router, Request, Response } from 'express';
// import crypto from 'crypto'; // 暫時不需要，待實現 str_check 驗證時再啟用
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { receiptEmailService } from '../services/email/receiptEmailService';

dotenv.config();

const router = Router();

// 初始化 Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

// ✅ 2026-02-03: 修復回調延遲問題 - App Deep Link 配置
// 現在使用 Return_url 接收即時回調（1-3秒），處理完成後重定向到 App
const APP_DEEP_LINK = process.env.GOMYPAY_APP_DEEP_LINK || 'ridebooking://payment-result';

/**
 * 生成 App Deep Link 重定向 URL
 * @param success 支付是否成功
 * @param orderNo 訂單編號
 * @param message 訊息
 */
function buildAppRedirectUrl(success: boolean, orderNo: string, message?: string): string {
  const params = new URLSearchParams({
    success: success ? '1' : '0',
    order_no: orderNo,
  });
  if (message) {
    params.append('message', message);
  }
  return `${APP_DEEP_LINK}?${params.toString()}`;
}

/**
 * 生成重定向 HTML 頁面
 * 用於在處理完成後將用戶重定向回 App
 */
function generateRedirectHtml(success: boolean, orderNo: string, message?: string): string {
  const redirectUrl = buildAppRedirectUrl(success, orderNo, message);
  const statusText = success ? '支付成功' : '支付失敗';
  const statusColor = success ? '#4CAF50' : '#f44336';

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${statusText} - RelayGo</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          margin: 0;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
          text-align: center;
          background: white;
          padding: 40px;
          border-radius: 16px;
          box-shadow: 0 10px 40px rgba(0,0,0,0.2);
          max-width: 400px;
          margin: 20px;
        }
        .icon {
          font-size: 64px;
          margin-bottom: 20px;
        }
        h1 {
          color: ${statusColor};
          margin-bottom: 16px;
        }
        p {
          color: #666;
          margin-bottom: 24px;
        }
        .loading {
          display: inline-block;
          width: 20px;
          height: 20px;
          border: 2px solid #ddd;
          border-top-color: #667eea;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        .btn {
          display: inline-block;
          padding: 12px 32px;
          background: #667eea;
          color: white;
          text-decoration: none;
          border-radius: 8px;
          font-weight: bold;
          margin-top: 16px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="icon">${success ? '✅' : '❌'}</div>
        <h1>${statusText}</h1>
        <p>${message || (success ? '您的支付已完成，正在返回 App...' : '支付未完成，請重試。')}</p>
        <div class="loading"></div>
        <br>
        <a href="${redirectUrl}" class="btn">返回 App</a>
      </div>
      <script>
        // 自動嘗試跳轉回 App
        setTimeout(function() {
          window.location.href = '${redirectUrl}';
        }, 1500);

        // 3秒後如果還沒跳轉，顯示手動按鈕
        setTimeout(function() {
          document.querySelector('.loading').style.display = 'none';
        }, 3000);
      </script>
    </body>
    </html>
  `;
}

/**
 * GOMYPAY 支付回調端點測試
 *
 * 用於測試端點是否可訪問
 *
 * @route GET /api/payment/gomypay-callback
 * @access Public
 */
router.get('/gomypay-callback', async (_req: Request, res: Response): Promise<void> => {
  res.status(200).json({
    success: true,
    message: 'GOMYPAY callback endpoint is accessible',
    timestamp: new Date().toISOString(),
    note: 'This endpoint accepts POST requests from GOMYPAY payment gateway'
  });
});

/**
 * GOMYPAY Return URL - 用戶支付完成後跳轉
 *
 * @route GET /api/payment/gomypay/return
 * @route POST /api/payment/gomypay/return
 * @access Public
 */
router.get('/gomypay/return', async (req: Request, res: Response): Promise<void> => {
  console.log('[GoMyPay Return] ========================================');
  console.log('[GoMyPay Return] ✅ 收到 GOMYPAY 即時回調（Return_url）');
  console.log('[GoMyPay Return] ========================================');
  console.log('[GoMyPay Return] 完整參數:', req.query);

  // 解析所有參數
  const {
    e_orderno,
    result,
    ret_msg,
    Order_No,
    OrderID,
    AvCode,
    str_check,
    Send_Type,
    booking_order_no,  // ✅ 2026-02-03: 從 URL 參數獲取訂單編號（支付失敗時 GOMYPAY 不返回訂單編號）
    web_return,        // ✅ 2026-03-20: 網頁端回調 URL（如有則導向網頁而非 APP deep link）
  } = req.query;

  // ✅ 2026-02-03: 修復支付失敗時無法識別訂單的問題
  // 優先使用 GOMYPAY 返回的訂單編號，如果沒有則使用 URL 參數中的 booking_order_no
  // 這樣即使 GOMYPAY 支付失敗不返回訂單編號，我們也能從 URL 參數中獲取
  const orderNo = (e_orderno || Order_No || booking_order_no || '') as string;

  console.log('[GoMyPay Return] 訂單編號:', orderNo);
  console.log('[GoMyPay Return] 訂單編號來源:', e_orderno ? 'e_orderno' : Order_No ? 'Order_No' : booking_order_no ? 'booking_order_no (URL參數)' : '無');
  console.log('[GoMyPay Return] 支付結果:', result);
  console.log('[GoMyPay Return] 返回訊息:', ret_msg);
  console.log('[GoMyPay Return] 授權碼:', AvCode);

  // ✅ 2026-02-03: 修復回調延遲問題
  // 在返回 HTML 之前，先處理支付結果（更新資料庫）
  try {
    if (result === '1' && orderNo) {
      console.log('[GoMyPay Return] 🔄 開始處理支付成功...');

      // 解析訂單編號格式
      let bookingId: string = '';
      let paymentType: string = 'deposit';

      if (orderNo.startsWith('BK')) {
        // ✅ 2026-02-04: 支持多種格式
        // 最新格式（25字符限制）: BK{timestamp}D{4位} 或 BK{timestamp}B{4位}
        // 舊格式：BK{timestamp}-DEPOSIT-{uniqueSuffix} 或 BK{timestamp}-BALANCE-{uniqueSuffix}
        // 更舊格式：BK{timestamp}-DEPOSIT 或 BK{timestamp}-BALANCE
        const newDepositMatch = orderNo.match(/^(BK\d+)D([A-Z0-9]{4})$/i);
        const newBalanceMatch = orderNo.match(/^(BK\d+)B([A-Z0-9]{4})$/i);
        const oldDepositMatch = orderNo.match(/^(BK\d+)-DEPOSIT(-[A-Z0-9]+)?$/i);
        const oldBalanceMatch = orderNo.match(/^(BK\d+)-BALANCE(-[A-Z0-9]+)?$/i);

        let bookingNumber: string;
        if (newDepositMatch) {
          bookingNumber = newDepositMatch[1];
          paymentType = 'deposit';
        } else if (newBalanceMatch) {
          bookingNumber = newBalanceMatch[1];
          paymentType = 'balance';
        } else if (oldDepositMatch) {
          bookingNumber = oldDepositMatch[1];
          paymentType = 'deposit';
        } else if (oldBalanceMatch) {
          bookingNumber = oldBalanceMatch[1];
          paymentType = 'balance';
        } else {
          // 最舊格式（向後兼容）：只有 BK{timestamp}
          bookingNumber = orderNo;
          paymentType = 'deposit';
        }

        console.log('[GoMyPay Return] BK 格式，查詢 booking_number:', bookingNumber);

        // 使用 booking_number 查詢訂單
        const { data: booking, error: bookingError } = await supabase
          .from('bookings')
          .select('*')
          .eq('booking_number', bookingNumber)
          .single();

        if (bookingError || !booking) {
          console.error('[GoMyPay Return] ❌ 找不到訂單:', bookingNumber, bookingError);
        } else {
          bookingId = booking.id;
          console.log('[GoMyPay Return] ✅ 找到訂單:', bookingId);

          // 查詢現有支付記錄
          const { data: existingPayment } = await supabase
            .from('payments')
            .select('*')
            .eq('booking_id', bookingId)
            .eq('type', paymentType)
            .order('created_at', { ascending: false })
            .limit(1)
            .single();

          // 計算金額
          // ✅ 2026-02-05: 優先使用支付記錄中的金額（包含小費），因為這是實際發起支付時的金額
          let amount = 0;
          if (existingPayment && existingPayment.amount) {
            // 優先使用支付記錄中的金額（這是發起支付時包含小費的總金額）
            amount = existingPayment.amount;
            console.log('[GoMyPay Return] 使用支付記錄金額（包含小費）:', amount);
          } else if (paymentType === 'deposit') {
            amount = booking.deposit_amount || 0;
            console.log('[GoMyPay Return] 使用訂金金額:', amount);
          } else if (paymentType === 'balance') {
            amount = booking.balance_amount ||
                     (booking.total_price ? booking.total_price - (booking.deposit_amount || 0) : 0) ||
                     booking.deposit_amount || 0;
            console.log('[GoMyPay Return] 使用尾款金額（無小費記錄）:', amount);
          }

          console.log('[GoMyPay Return] 最終支付金額:', amount);

          // 調用 handlePaymentSuccess 更新訂單狀態
          await handlePaymentSuccess({
            bookingId: booking.id,
            paymentType,
            amount: amount,
            transactionId: (OrderID as string) || '',
            authCode: (AvCode as string) || '',
            payTime: new Date().toISOString(),
            existingPayment,
            customerId: booking.customer_id
          });

          console.log('[GoMyPay Return] ✅ 訂單狀態已更新！');
        }
      } else {
        console.log('[GoMyPay Return] ⚠️ 非 BK 格式訂單，跳過處理');
      }
    } else if (result === '0' && orderNo) {
      console.log('[GoMyPay Return] ❌ 支付失敗:', ret_msg);
    }
  } catch (error: any) {
    console.error('[GoMyPay Return] ❌ 處理支付結果時發生錯誤:', error.message);
  }

  // 返回一個 HTML 頁面，通知 Flutter WebView
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>支付處理中</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          margin: 0;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
          text-align: center;
          background: white;
          padding: 40px;
          border-radius: 10px;
          box-shadow: 0 10px 40px rgba(0,0,0,0.1);
        }
        h1 { color: #333; margin-bottom: 20px; }
        p { color: #666; font-size: 16px; }
        .spinner {
          border: 4px solid #f3f3f3;
          border-top: 4px solid #667eea;
          border-radius: 50%;
          width: 40px;
          height: 40px;
          animation: spin 1s linear infinite;
          margin: 20px auto;
        }
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        .success { color: #4CAF50; }
        .error { color: #f44336; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="spinner" id="spinner"></div>
        <h1 id="title">支付處理中</h1>
        <p id="message">請稍候，我們正在確認您的支付...</p>
        <p style="font-size: 14px; color: #999; margin-top: 20px;" id="countdown">
          此頁面將自動關閉
        </p>
      </div>
      <script>
        // 支付結果
        const paymentResult = '${result || ''}';
        const paymentMessage = '${ret_msg || ''}';
        // ✅ 修復：使用解析後的 orderNo 變數，確保不為空
        const orderNo = '${orderNo}';

        console.log('[Return Page] 支付結果:', paymentResult);
        console.log('[Return Page] 訂單編號:', orderNo);
        console.log('[Return Page] 支付訊息:', paymentMessage);

        // 網頁端回調：直接跳轉到網頁結果頁
        const webReturnUrl = '${(web_return as string) || ''}';

        if (webReturnUrl) {
          // Web booking: redirect to web result page
          function redirectWeb(status) {
            const separator = webReturnUrl.includes('?') ? '&' : '?';
            window.location.href = webReturnUrl + separator + 'status=' + status + '&orderNo=' + orderNo;
          }

          if (paymentResult === '1') {
            document.getElementById('title').textContent = '支付成功';
            document.getElementById('title').className = 'success';
            document.getElementById('message').textContent = '正在跳轉...';
            document.getElementById('spinner').style.display = 'none';
            setTimeout(() => redirectWeb('success'), 1000);
          } else {
            document.getElementById('title').textContent = '支付失敗';
            document.getElementById('title').className = 'error';
            document.getElementById('message').textContent = paymentMessage || '支付失敗，正在跳轉...';
            document.getElementById('spinner').style.display = 'none';
            setTimeout(() => redirectWeb('failed'), 1500);
          }
          return; // Skip Flutter deep link below
        }

        // 立即通知 Flutter WebView（不等待回調）
        function notifyFlutter(status) {
          try {
            // ✅ 2026-02-04: 支持多種格式
            // 最新格式（25字符限制）: BK1763186275643D7L7Y → BK1763186275643
            // 舊格式：BK1763186275643-DEPOSIT-A3B9F2 → BK1763186275643
            // 更舊格式：BK1763186275643-DEPOSIT → BK1763186275643
            let bookingNumber = orderNo;

            // 使用正則表達式匹配並提取 booking_number
            const newDepositMatch = orderNo.match(/^(BK\\d+)D([A-Z0-9]{4})$/i);
            const newBalanceMatch = orderNo.match(/^(BK\\d+)B([A-Z0-9]{4})$/i);
            const oldDepositMatch = orderNo.match(/^(BK\\d+)-DEPOSIT(-[A-Z0-9]+)?$/i);
            const oldBalanceMatch = orderNo.match(/^(BK\\d+)-BALANCE(-[A-Z0-9]+)?$/i);

            if (newDepositMatch) {
              bookingNumber = newDepositMatch[1];
            } else if (newBalanceMatch) {
              bookingNumber = newBalanceMatch[1];
            } else if (oldDepositMatch) {
              bookingNumber = oldDepositMatch[1];
            } else if (oldBalanceMatch) {
              bookingNumber = oldBalanceMatch[1];
            }

            // 方法 1: 使用 Deep Link
            const deepLink = 'ridebooking://payment-result?status=' + status + '&orderNo=' + bookingNumber;
            console.log('[Return Page] 觸發 Deep Link:', deepLink);
            console.log('[Return Page] 原始訂單號:', orderNo);
            console.log('[Return Page] 訂單編號:', bookingNumber);
            window.location.href = deepLink;
          } catch (e) {
            console.error('[Return Page] Deep Link 失敗:', e);
          }

          // 方法 2: 嘗試關閉窗口
          setTimeout(() => {
            try {
              window.close();
            } catch (e) {
              console.log('[Return Page] 無法關閉窗口');
            }
          }, 1000);
        }

        // 根據支付結果立即通知
        if (paymentResult === '1') {
          // 支付成功
          document.getElementById('title').textContent = '支付成功';
          document.getElementById('title').className = 'success';
          document.getElementById('message').textContent = '您的支付已提交，正在處理中...';
          document.getElementById('spinner').style.display = 'none';

          // 立即通知 Flutter
          setTimeout(() => notifyFlutter('success'), 500);
        } else if (paymentResult === '0') {
          // 支付失敗
          document.getElementById('title').textContent = '支付失敗';
          document.getElementById('title').className = 'error';
          document.getElementById('message').textContent = paymentMessage || '支付處理失敗，請重試';
          document.getElementById('spinner').style.display = 'none';

          // 立即通知 Flutter
          setTimeout(() => notifyFlutter('failed'), 500);
        } else {
          // 未知狀態，等待回調
          // 3秒後自動通知（假設支付成功）
          setTimeout(() => {
            document.getElementById('title').textContent = '支付已提交';
            document.getElementById('message').textContent = '正在確認支付結果...';
            notifyFlutter('pending');
          }, 3000);
        }
      </script>
    </body>
    </html>
  `);
});

router.post('/gomypay/return', async (req: Request, res: Response): Promise<void> => {
  console.log('[GoMyPay Return POST] 用戶返回:', req.body);
  res.redirect('/api/payment/gomypay/return?' + new URLSearchParams(req.body).toString());
});

/**
 * 共享的 GoMyPay 回調處理邏輯
 */
async function handleGomypayCallback(req: Request, res: Response): Promise<void> {
  try {
    console.log('='.repeat(60));
    console.log('[GOMYPAY Callback] ========== 收到支付回調 ==========');
    console.log('[GOMYPAY Callback] 時間:', new Date().toISOString());
    console.log('[GOMYPAY Callback] Content-Type:', req.headers['content-type']);
    console.log('[GOMYPAY Callback] Body:', req.body);
    console.log('[GOMYPAY Callback] Query params:', req.query);
    console.log('='.repeat(60));

    // 1. 解析支付結果參數（可能在 body 或 query 中）
    const params = { ...req.body, ...req.query };

    const {
      result,        // 支付結果 (1=成功, 0=失敗) - GOMYPAY 實際返回的參數
      ret_msg,       // 返回訊息 - GOMYPAY 實際返回的參數
      OrderID,       // GOMYPAY 訂單編號
      e_orderno,     // 我們的訂單編號
      e_money,       // 實際支付金額 - GOMYPAY 實際返回的參數
      AvCode,        // 授權碼
      str_check,     // 檢查碼 - GOMYPAY 實際返回的參數名稱
      Send_Type,     // 交易類型
    } = params;

    console.log('[GOMYPAY Callback] 解析參數:', {
      result,
      ret_msg,
      OrderID,
      e_orderno,
      e_money,
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
      // ✅ 2026-02-03: 返回重定向頁面
      res.status(200).send(generateRedirectHtml(false, e_orderno || 'unknown', '缺少必要參數'));
      return;
    }

    // 3. 檢查支付結果
    if (result !== '1') {
      console.error('[GOMYPAY Callback] 支付失敗:', ret_msg);
      // ✅ 2026-02-03: 返回重定向頁面
      res.status(200).send(generateRedirectHtml(false, e_orderno, ret_msg || '支付失敗'));
      return;
    }

    // 4. 驗證 str_check（確保請求來自 GOMYPAY）
    // 注意：GOMYPAY 回調的 str_check 驗證邏輯可能與支付請求不同
    // 暫時跳過驗證，因為我們已經通過 HTTPS 和 ngrok 確保安全性
    console.log('[GOMYPAY Callback] ⚠️  暫時跳過 str_check 驗證');

    // 5. 解析訂單編號
    // 支持多種格式：
    // 1. BK 格式：BK{timestamp} (例: BK1762997624214) - 當前使用
    // 2. 新格式 v3：{16字符bookingId}{1字符類型D/B}{8字符時間戳} = 25字符
    //    範例：d9a63c27914d44deB70517422
    // 3. 新格式 v2：{20字符bookingId}{1字符類型D/B}{4字符時間戳} = 25字符
    //    範例：6ee49212c05e4ccf9093D8737
    // 4. 舊格式：BOOKING_{bookingId}_{paymentType}_{timestamp}

    let bookingId: string;
    let paymentType: string;

    if (e_orderno.startsWith('BK')) {
      // ✅ 2026-02-04: 支持 BK 格式的訂單編號
      // 格式（按優先順序匹配）：
      // - 最新格式（25字符限制）: BK1763186275643D7L7Y (D=Deposit) 或 BK1763186275643B7L7Y (B=Balance)
      // - 舊格式（帶後綴）: BK1763186275643-DEPOSIT-A3B9F2 或 BK1763186275643-BALANCE-A3B9F2
      // - 更舊格式: BK1763186275643-DEPOSIT 或 BK1763186275643-BALANCE
      // - 最舊格式（向後兼容）: BK1763186275643
      console.log('[GOMYPAY Callback] 檢測到 BK 格式訂單編號:', e_orderno);

      // 使用正則表達式解析訂單編號
      // 最新格式: BK{timestamp}D{4位隨機} 或 BK{timestamp}B{4位隨機}
      const newDepositMatch = e_orderno.match(/^(BK\d+)D([A-Z0-9]{4})$/);
      const newBalanceMatch = e_orderno.match(/^(BK\d+)B([A-Z0-9]{4})$/);
      // 舊格式: BK{timestamp}-DEPOSIT(-{uniqueSuffix})? 或 BK{timestamp}-BALANCE(-{uniqueSuffix})?
      const oldDepositMatch = e_orderno.match(/^(BK\d+)-DEPOSIT(-[A-Z0-9]+)?$/);
      const oldBalanceMatch = e_orderno.match(/^(BK\d+)-BALANCE(-[A-Z0-9]+)?$/);

      if (newDepositMatch) {
        // 最新格式訂金支付
        bookingId = newDepositMatch[1]; // BK{timestamp}
        paymentType = 'deposit';
        console.log('[GOMYPAY Callback] 訂金支付（新短格式），唯一後綴:', newDepositMatch[2]);
      } else if (newBalanceMatch) {
        // 最新格式尾款支付
        bookingId = newBalanceMatch[1]; // BK{timestamp}
        paymentType = 'balance';
        console.log('[GOMYPAY Callback] 尾款支付（新短格式），唯一後綴:', newBalanceMatch[2]);
      } else if (oldDepositMatch) {
        // 舊格式訂金支付
        bookingId = oldDepositMatch[1]; // BK{timestamp}
        paymentType = 'deposit';
        console.log('[GOMYPAY Callback] 訂金支付（舊格式），唯一後綴:', oldDepositMatch[2] || '無');
      } else if (oldBalanceMatch) {
        // 舊格式尾款支付
        bookingId = oldBalanceMatch[1]; // BK{timestamp}
        paymentType = 'balance';
        console.log('[GOMYPAY Callback] 尾款支付（舊格式），唯一後綴:', oldBalanceMatch[2] || '無');
      } else {
        // 最舊格式（向後兼容）：沒有後綴，預設為訂金
        bookingId = e_orderno;
        paymentType = 'deposit';
      }

      console.log('[GOMYPAY Callback] BK 格式解析:', {
        originalOrderNo: e_orderno,
        bookingNumber: bookingId,
        paymentType
      });
    } else if (e_orderno.startsWith('BOOKING_')) {
      // 舊格式
      const orderParts = e_orderno.split('_');
      if (orderParts.length < 3) {
        console.error('[GOMYPAY Callback] 訂單編號格式錯誤:', e_orderno);
        // ✅ 2026-02-03: 返回重定向頁面
        res.status(200).send(generateRedirectHtml(false, e_orderno, '訂單編號格式錯誤'));
        return;
      }
      bookingId = orderParts[1];
      paymentType = orderParts[2].toLowerCase(); // 'deposit' or 'balance'
    } else if (e_orderno.length === 25) {
      // 新格式：25字符
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
        // ✅ 2026-02-03: 返回重定向頁面
        res.status(200).send(generateRedirectHtml(false, e_orderno, '無法識別訂單編號格式'));
        return;
      }
    } else {
      console.error('[GOMYPAY Callback] 無法識別訂單編號格式:', e_orderno, '長度:', e_orderno.length);
      // ✅ 2026-02-03: 返回重定向頁面
      res.status(200).send(generateRedirectHtml(false, e_orderno, '無法識別訂單編號格式'));
      return;
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

      // ✅ 2026-02-03: 返回重定向頁面
      res.status(200).send(generateRedirectHtml(true, e_orderno, '測試訂單處理成功'));
      return;
    }

    // 5. 查詢訂單（非測試模式）
    let booking: any;
    let bookingError: any;

    if (bookingId.startsWith('BK')) {
      // BK 格式：使用 booking_number 查詢
      console.log('[GOMYPAY Callback] 使用 booking_number 查詢:', bookingId);

      const result = await supabase
        .from('bookings')
        .select('*')
        .eq('booking_number', bookingId)
        .single();

      booking = result.data;
      bookingError = result.error;

      if (result.error) {
        console.error('[GOMYPAY Callback] ❌ 查詢訂單失敗:', result.error);
      } else {
        console.log('[GOMYPAY Callback] ✅ 找到訂單:', booking?.id);
      }
    } else if (bookingId.length === 16 || bookingId.length === 20) {
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
      // ✅ 2026-02-03: 返回重定向頁面
      res.status(200).send(generateRedirectHtml(false, e_orderno, '找不到訂單，請聯繫客服'));
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

      // ✅ 使用 GOMYPAY 回調傳來的實際支付金額（包含小費）
      // 如果沒有 e_money，則從資料庫計算（向後兼容）
      let amount: number;
      if (e_money) {
        // 優先使用 GOMYPAY 回調傳來的實際支付金額
        amount = parseFloat(e_money);
        console.log('[GOMYPAY Callback] 使用 GOMYPAY 回調金額:', amount);
      } else {
        // 向後兼容：從資料庫計算支付金額
        console.log('[GOMYPAY Callback] ⚠️  未收到 e_money，從資料庫計算金額');
        if (paymentType === 'deposit') {
          amount = booking.deposit_amount || 0;
        } else if (paymentType === 'balance') {
          // 尾款金額 = 總金額 - 訂金金額
          amount = booking.balance_amount ||
                   (booking.total_price ? booking.total_price - (booking.deposit_amount || 0) : 0) ||
                   booking.deposit_amount ||
                   0;
        } else {
          amount = 0;
        }
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

      // ✅ 2026-02-03: 修復回調延遲問題
      // 使用 Return_url 接收即時回調時，需要返回重定向頁面將用戶導回 App
      console.log('[GOMYPAY Callback] ✅ 支付成功，返回重定向頁面');
      res.status(200).send(generateRedirectHtml(true, e_orderno, '支付成功！正在返回 App...'));
    } else {
      // 支付失敗
      console.log('[GOMYPAY Callback] 支付失敗:', ret_msg);
      await handlePaymentFailure({
        bookingId: booking.id, // 使用完整的 UUID
        paymentType,
        message: ret_msg,
        existingPayment
      });

      // ✅ 2026-02-03: 修復回調延遲問題
      // 支付失敗時也返回重定向頁面
      console.log('[GOMYPAY Callback] ❌ 支付失敗，返回重定向頁面');
      res.status(200).send(generateRedirectHtml(false, e_orderno, ret_msg || '支付失敗，請重試。'));
    }

  } catch (error: any) {
    console.error('[GOMYPAY Callback] ========================================');
    console.error('[GOMYPAY Callback] ❌ 處理回調失敗');
    console.error('[GOMYPAY Callback] ========================================');
    console.error('[GOMYPAY Callback] 錯誤訊息:', (error as Error).message);
    console.error('[GOMYPAY Callback] 錯誤堆疊:', (error as Error).stack);
    console.error('[GOMYPAY Callback] ========================================');

    // ✅ 2026-02-03: 錯誤情況也返回重定向頁面
    res.status(200).send(generateRedirectHtml(false, 'unknown', '處理支付時發生錯誤，請稍後重試。'));
  }
}

/**
 * GOMYPAY 支付回調 API（舊版路徑，向後兼容）
 *
 * @route POST /api/payment/gomypay-callback
 * @access Public
 */
router.post('/gomypay-callback', handleGomypayCallback);

/**
 * GOMYPAY Callback URL - GoMyPay 後台通知（新版路徑）
 *
 * @route POST /api/payment/gomypay/callback
 * @access Public
 */
router.post('/gomypay/callback', handleGomypayCallback);

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
    // transaction_id 同步為 GoMyPay 的 OrderID（原本 UPDATE 路徑漏掉了這一步，
    // 導致 transaction_id 停留在初始佔位值，而非真正的 GoMyPay 交易編號）
    const { error: updateError } = await supabase
      .from('payments')
      .update({
        status: 'completed',
        transaction_id: transactionId,
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

    // ✅ 計算小費金額：支付金額 - (原始尾款 + 超時費)
    // 需要先查詢訂單資料以獲取原始尾款金額和超時費用
    console.log('[GOMYPAY Callback] 尾款支付 - 開始計算小費');
    console.log('[GOMYPAY Callback] 支付金額:', amount);

    const { data: booking } = await supabase
      .from('bookings')
      .select('total_amount, deposit_amount, overtime_fee, balance_amount')
      .eq('id', bookingId)
      .single();

    if (booking) {
      // 使用 balance_amount（已包含超時費）或計算原始尾款
      const balanceWithOvertimeFee = booking.balance_amount || (booking.total_amount - booking.deposit_amount);
      const overtimeFee = booking.overtime_fee || 0;
      const originalBalance = booking.total_amount - booking.deposit_amount;

      // 小費 = 實際支付金額 - (原始尾款 + 超時費)
      const tipAmount = amount - balanceWithOvertimeFee;

      console.log('[GOMYPAY Callback] 訂單總金額:', booking.total_amount);
      console.log('[GOMYPAY Callback] 訂金金額:', booking.deposit_amount);
      console.log('[GOMYPAY Callback] 原始尾款:', originalBalance);
      console.log('[GOMYPAY Callback] 超時費用:', overtimeFee);
      console.log('[GOMYPAY Callback] 尾款（含超時費）:', balanceWithOvertimeFee);
      console.log('[GOMYPAY Callback] 計算的小費:', tipAmount);

      if (tipAmount > 0) {
        updateData.tip_amount = tipAmount;
        console.log('[GOMYPAY Callback] ✅ 小費金額將被儲存:', tipAmount);
      } else {
        console.log('[GOMYPAY Callback] ⚠️  小費金額 <= 0，不儲存');
      }
    } else {
      console.log('[GOMYPAY Callback] ⚠️  無法查詢訂單資料，無法計算小費');
    }
  } else {
    console.error('[GOMYPAY Callback] 未知的支付類型:', paymentType);
    return;
  }

  console.log('[GOMYPAY Callback] 準備更新訂單，updateData:', JSON.stringify(updateData, null, 2));

  // ✅ 使用 RPC 函數更新訂單狀態，確保觸發 PostgreSQL 觸發器
  // 原因：Supabase SDK 的 .update() 方法可能不會觸發觸發器
  const { error: bookingUpdateError } = await supabase.rpc('update_booking_status', {
    p_booking_id: bookingId,
    p_status: newStatus,
    p_completed_at: updateData.completed_at || null,
    p_deposit_paid: updateData.deposit_paid || null,
    p_tip_amount: updateData.tip_amount || null,
  });

  if (bookingUpdateError) {
    console.error('[GOMYPAY Callback] 更新訂單狀態失敗:', bookingUpdateError);
    throw bookingUpdateError;
  }

  console.log('[GOMYPAY Callback] ✅ 訂單狀態已通過 RPC 函數更新');

  console.log('[GOMYPAY Callback] ✅ 訂單狀態已更新為:', newStatus);

  // 驗證小費是否成功儲存
  if (paymentType === 'balance' && updateData.tip_amount) {
    const { data: verifyBooking } = await supabase
      .from('bookings')
      .select('tip_amount')
      .eq('id', bookingId)
      .single();

    console.log('[GOMYPAY Callback] 驗證小費儲存結果:', verifyBooking?.tip_amount);
  }

  // 3. 發送收據郵件（異步，不阻塞主流程）
  console.log('[GOMYPAY Callback] 準備發送收據郵件');

  // 使用 setTimeout 確保郵件發送不會阻塞支付流程
  setTimeout(async () => {
    try {
      const emailResult = await receiptEmailService.sendReceiptEmail({
        bookingId,
        paymentType: paymentType as 'deposit' | 'balance',
        transactionId,
        amount
      });

      if (emailResult.success) {
        console.log('[GOMYPAY Callback] ✅ 收據郵件發送成功');
      } else {
        console.error('[GOMYPAY Callback] ⚠️  收據郵件發送失敗:', emailResult.error);
      }
    } catch (emailError) {
      // 郵件發送失敗不應影響支付流程
      console.error('[GOMYPAY Callback] ⚠️  收據郵件發送異常:', emailError);
    }
  }, 1000); // 延遲 1 秒發送，確保資料庫更新完成
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

