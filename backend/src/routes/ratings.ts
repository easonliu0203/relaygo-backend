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
 * @route POST /api/bookings/:bookingId/rating
 * @desc 提交訂單評價
 * @access Customer
 */
router.post('/:bookingId/rating', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { customerUid, rating, comment } = req.body;

    console.log('[API] 提交評價:', {
      bookingId,
      customerUid,
      rating,
      comment: comment ? `${comment.substring(0, 20)}...` : null
    });

    // 1. 驗證必填欄位
    if (!customerUid) {
      res.status(400).json({
        success: false,
        error: '缺少客戶 UID'
      });
      return;
    }

    if (!rating || rating < 1 || rating > 5) {
      res.status(400).json({
        success: false,
        error: '評分必須在 1-5 之間'
      });
      return;
    }

    // 2. 驗證客戶是否存在
    const { data: customer, error: customerError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', customerUid)
      .eq('role', 'customer')
      .single();

    if (customerError || !customer) {
      console.error('[API] 查詢客戶失敗:', customerError);
      res.status(404).json({
        success: false,
        error: '客戶不存在'
      });
      return;
    }

    // 3. 查詢訂單資料
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('id, customer_id, driver_id, status')
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

    // 4. 驗證訂單是否屬於該客戶
    if (booking.customer_id !== customer.id) {
      res.status(403).json({
        success: false,
        error: '無權評價此訂單'
      });
      return;
    }

    // 5. 驗證訂單狀態是否允許評價
    const allowedStatuses = ['trip_ended', 'pending_balance', 'completed'];
    if (!allowedStatuses.includes(booking.status)) {
      res.status(400).json({
        success: false,
        error: `訂單狀態不允許評價（當前狀態: ${booking.status}）`
      });
      return;
    }

    // 6. 檢查是否已評價過
    const { data: existingRating, error: checkError } = await supabase
      .from('ratings')
      .select('id')
      .eq('booking_id', bookingId)
      .maybeSingle();

    if (checkError) {
      console.error('[API] 檢查評價失敗:', checkError);
      res.status(500).json({
        success: false,
        error: '檢查評價失敗'
      });
      return;
    }

    if (existingRating) {
      res.status(400).json({
        success: false,
        error: '此訂單已評價過，不能重複評價'
      });
      return;
    }

    // 7. 創建評價記錄
    const { data: newRating, error: ratingError } = await supabase
      .from('ratings')
      .insert({
        booking_id: bookingId,
        customer_id: customer.id,
        driver_id: booking.driver_id,
        rating: rating,
        comment: comment || null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (ratingError) {
      console.error('[API] 創建評價失敗:', ratingError);
      res.status(500).json({
        success: false,
        error: '創建評價失敗: ' + ratingError.message
      });
      return;
    }

    console.log('[API] ✅ 評價創建成功:', newRating.id);

    res.status(200).json({
      success: true,
      data: {
        ratingId: newRating.id,
        rating: newRating.rating,
        comment: newRating.comment,
        createdAt: newRating.created_at
      },
      message: '評價提交成功'
    });

  } catch (error: any) {
    console.error('[API] 提交評價失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '提交評價失敗'
    });
  }
});

/**
 * @route GET /api/bookings/:bookingId/rating
 * @desc 查詢訂單評價
 * @access Public
 */
router.get('/:bookingId/rating', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;

    console.log('[API] 查詢訂單評價:', bookingId);

    // 查詢評價記錄
    const { data: rating, error: ratingError } = await supabase
      .from('ratings')
      .select(`
        id,
        booking_id,
        rating,
        comment,
        created_at,
        customer:users!ratings_customer_id_fkey(id, firebase_uid),
        driver:users!ratings_driver_id_fkey(id, firebase_uid)
      `)
      .eq('booking_id', bookingId)
      .maybeSingle();

    if (ratingError) {
      console.error('[API] 查詢評價失敗:', ratingError);
      res.status(500).json({
        success: false,
        error: '查詢評價失敗'
      });
      return;
    }

    if (!rating) {
      res.status(404).json({
        success: false,
        error: '此訂單尚未評價'
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: rating
    });

  } catch (error: any) {
    console.error('[API] 查詢評價失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '查詢評價失敗'
    });
  }
});

/**
 * @route GET /api/drivers/:driverId/ratings
 * @desc 查詢司機的所有評價
 * @access Public
 */
router.get('/drivers/:driverId/ratings', async (req: Request, res: Response): Promise<void> => {
  try {
    const { driverId } = req.params;
    const { limit = 10, offset = 0 } = req.query;

    console.log('[API] 查詢司機評價:', driverId);

    // 1. 驗證司機是否存在
    const { data: driver, error: driverError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', driverId)
      .eq('role', 'driver')
      .single();

    if (driverError || !driver) {
      console.error('[API] 查詢司機失敗:', driverError);
      res.status(404).json({
        success: false,
        error: '司機不存在'
      });
      return;
    }

    // 2. 查詢司機的所有評價
    const { data: ratings, error: ratingsError, count } = await supabase
      .from('ratings')
      .select(`
        id,
        booking_id,
        rating,
        comment,
        created_at,
        customer:users!ratings_customer_id_fkey(id, firebase_uid)
      `, { count: 'exact' })
      .eq('driver_id', driver.id)
      .order('created_at', { ascending: false })
      .range(Number(offset), Number(offset) + Number(limit) - 1);

    if (ratingsError) {
      console.error('[API] 查詢評價失敗:', ratingsError);
      res.status(500).json({
        success: false,
        error: '查詢評價失敗'
      });
      return;
    }

    // 3. 計算平均評分
    const avgRating = ratings && ratings.length > 0
      ? ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length
      : 0;

    res.status(200).json({
      success: true,
      data: {
        ratings: ratings || [],
        total: count || 0,
        averageRating: Math.round(avgRating * 10) / 10, // 保留一位小數
        limit: Number(limit),
        offset: Number(offset)
      }
    });

  } catch (error: any) {
    console.error('[API] 查詢司機評價失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '查詢司機評價失敗'
    });
  }
});

export default router;

