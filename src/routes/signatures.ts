import { Router, Request, Response } from 'express';
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
 * 獲取客戶端真實 IP 地址
 */
function getClientIp(req: Request): string {
  const forwardedFor = req.headers['x-forwarded-for'];
  if (forwardedFor) {
    const ips = (typeof forwardedFor === 'string' ? forwardedFor : forwardedFor[0]).split(',');
    return ips[0].trim();
  }
  const realIp = req.headers['x-real-ip'];
  if (realIp) {
    return typeof realIp === 'string' ? realIp : realIp[0];
  }
  const cfIp = req.headers['cf-connecting-ip'];
  if (cfIp) {
    return typeof cfIp === 'string' ? cfIp : cfIp[0];
  }
  return req.ip || req.socket.remoteAddress || 'unknown';
}

/**
 * @route POST /api/signatures/balance-payment
 * @desc 儲存支付尾款的數位簽名
 * @access Customer
 */
router.post('/balance-payment', async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      bookingId,
      paymentId,
      signatureBase64,
      customerUid
    } = req.body;

    console.log('[API] 儲存支付尾款簽名:', { bookingId, paymentId, customerUid });

    // 1. 驗證必填欄位
    if (!bookingId || !signatureBase64) {
      res.status(400).json({
        success: false,
        error: '缺少必填欄位：bookingId 或 signatureBase64'
      });
      return;
    }

    // 2. 驗證訂單存在
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('id, customer_id, booking_number, balance_amount')
      .eq('id', bookingId)
      .single();

    if (bookingError || !booking) {
      console.error('[API] 查詢訂單失敗:', bookingError);
      res.status(404).json({
        success: false,
        error: '訂單不存在'
      });
      return;
    }

    // 3. 上傳簽名圖片到 Supabase Storage
    let signatureUrl = '';
    try {
      // 移除 Base64 前綴（如果存在）
      const base64Data = signatureBase64.replace(/^data:image\/\w+;base64,/, '');
      const imageBuffer = Buffer.from(base64Data, 'base64');

      // 生成唯一文件名：booking_number-timestamp.png
      const timestamp = Date.now();
      const fileName = `${booking.booking_number}-${timestamp}.png`;

      console.log('[API] 上傳簽名圖片到 Storage:', fileName);

      // 上傳到 Supabase Storage
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('payment-signatures')
        .upload(fileName, imageBuffer, {
          contentType: 'image/png',
          cacheControl: '31536000', // 1 年緩存
          upsert: false
        });

      if (uploadError) {
        console.error('[API] 上傳簽名圖片失敗:', uploadError);
        throw new Error('上傳簽名圖片失敗: ' + uploadError.message);
      }

      // 獲取公開 URL
      const { data: publicUrlData } = supabase.storage
        .from('payment-signatures')
        .getPublicUrl(fileName);

      signatureUrl = publicUrlData.publicUrl;
      console.log('[API] ✅ 簽名圖片上傳成功:', signatureUrl);

    } catch (uploadError: any) {
      console.error('[API] 上傳簽名圖片異常:', uploadError);
      // 如果上傳失敗，仍然繼續儲存 Base64（向後兼容）
      console.log('[API] ⚠️  將使用 Base64 格式儲存簽名');
    }

    // 4. 獲取客戶端資訊
    const clientIp = getClientIp(req);
    const userAgent = req.headers['user-agent'] || 'unknown';

    console.log('[API] 客戶端資訊:', { clientIp, userAgent });

    // 5. 儲存簽名記錄
    const { data: signature, error: signatureError } = await supabase
      .from('payment_signatures')
      .insert({
        booking_id: bookingId,
        payment_id: paymentId || null,
        signature_base64: signatureBase64, // 保留 Base64 以向後兼容
        signature_url: signatureUrl || null, // 新增：Storage URL
        signed_at: new Date().toISOString(),
        client_ip: clientIp,
        user_agent: userAgent,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (signatureError) {
      console.error('[API] 儲存簽名失敗:', signatureError);
      res.status(500).json({
        success: false,
        error: '儲存簽名失敗: ' + signatureError.message
      });
      return;
    }

    console.log('[API] ✅ 簽名儲存成功:', signature.id);

    res.json({
      success: true,
      data: {
        signatureId: signature.id,
        bookingId: booking.id,
        bookingNumber: booking.booking_number,
        signatureUrl: signatureUrl || undefined
      }
    });

  } catch (error: any) {
    console.error('[API] 儲存簽名異常:', error);
    res.status(500).json({
      success: false,
      error: error.message || '儲存簽名失敗'
    });
  }
});

/**
 * @route GET /api/signatures/booking/:bookingId
 * @desc 獲取訂單的簽名記錄
 * @access Customer/Admin
 */
router.get('/booking/:bookingId', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;

    const { data: signatures, error } = await supabase
      .from('payment_signatures')
      .select('*')
      .eq('booking_id', bookingId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('[API] 查詢簽名失敗:', error);
      res.status(500).json({
        success: false,
        error: '查詢簽名失敗'
      });
      return;
    }

    res.json({
      success: true,
      data: signatures
    });

  } catch (error: any) {
    console.error('[API] 查詢簽名異常:', error);
    res.status(500).json({
      success: false,
      error: error.message || '查詢簽名失敗'
    });
  }
});

export default router;

