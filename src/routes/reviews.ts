import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const router = Router();

// 初始化 Supabase 客戶端（使用 service_role_key 繞過 RLS）
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

/**
 * @route POST /api/reviews
 * @desc 客戶提交評價
 * @access Customer
 */
router.post('/', async (req: Request, res: Response): Promise<void> => {
  try {
    const { customerUid, bookingId, rating, comment, isAnonymous } = req.body;

    console.log('[API] 客戶提交評價:', {
      customerUid,
      bookingId,
      rating,
      isAnonymous,
    });

    // 1. 驗證必填欄位
    if (!customerUid || !bookingId || !rating) {
      res.status(400).json({
        success: false,
        error: '缺少必填欄位 (customerUid, bookingId, rating)',
      });
      return;
    }

    // 2. 驗證評分範圍
    if (rating < 1 || rating > 5 || !Number.isInteger(rating)) {
      res.status(400).json({
        success: false,
        error: '評分必須是 1-5 之間的整數',
      });
      return;
    }

    // 3. 查詢客戶 ID（Firebase UID → Supabase UUID）
    const { data: customer, error: customerError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', customerUid)
      .single();

    if (customerError || !customer) {
      console.error('[API] 查詢客戶失敗:', customerError);
      res.status(404).json({
        success: false,
        error: '客戶不存在',
      });
      return;
    }

    // 4. 查詢訂單資訊
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('id, customer_id, driver_id, status')
      .eq('id', bookingId)
      .single();

    if (bookingError || !booking) {
      console.error('[API] 查詢訂單失敗:', bookingError);
      res.status(404).json({
        success: false,
        error: '訂單不存在',
      });
      return;
    }

    // 5. 驗證權限（只有訂單的客戶可以評價）
    if (booking.customer_id !== customer.id) {
      console.error('[API] 權限驗證失敗: 客戶 ID 不匹配');
      res.status(403).json({
        success: false,
        error: '無權限評價此訂單',
      });
      return;
    }

    // 6. 驗證訂單狀態
    // ✅ 修改：允許以下狀態提交評價
    // - trip_ended (行程結束)
    // - pending_balance (待付尾款)
    // - completed (訂單完成)
    // 原因：用戶支付尾款後應該可以立即評價，無需等待 GOMYPAY 回調更新訂單狀態為 'completed'
    const allowedStatuses = ['trip_ended', 'pending_balance', 'completed'];

    if (!allowedStatuses.includes(booking.status)) {
      console.error('[API] 訂單狀態不允許評價:', booking.status);
      res.status(400).json({
        success: false,
        error: `訂單狀態不允許評價（當前狀態: ${booking.status}）`,
      });
      return;
    }

    console.log('[API] ✅ 訂單狀態允許評價:', booking.status);

    // 7. 檢查是否已評價
    const { data: existingReview, error: checkError } = await supabase
      .from('reviews')
      .select('id')
      .eq('booking_id', bookingId)
      .eq('reviewer_id', customer.id)
      .maybeSingle();

    if (checkError) {
      console.error('[API] 檢查重複評價失敗:', checkError);
    }

    if (existingReview) {
      res.status(400).json({
        success: false,
        error: '此訂單已評價',
      });
      return;
    }

    // 8. 創建評價
    const { data: review, error: createError } = await supabase
      .from('reviews')
      .insert({
        booking_id: bookingId,
        reviewer_id: customer.id,
        reviewee_id: booking.driver_id,
        rating: rating,
        comment: comment || null,
        is_anonymous: isAnonymous || false,
        status: 'pending', // 待審核
        helpful_count: 0,
        report_count: 0,
      })
      .select()
      .single();

    if (createError) {
      console.error('[API] 創建評價失敗:', createError);
      res.status(500).json({
        success: false,
        error: '創建評價失敗',
      });
      return;
    }

    console.log('[API] ✅ 評價創建成功:', review.id);

    // 9. 返回成功響應（201 Created）
    // 返回完整的評價數據（camelCase 格式）
    res.status(201).json({
      success: true,
      data: {
        id: review.id,
        bookingId: review.booking_id,
        reviewerId: review.reviewer_id,
        revieweeId: review.reviewee_id,
        rating: review.rating,
        comment: review.comment,
        isAnonymous: review.is_anonymous,
        status: review.status,
        adminNotes: review.admin_notes,
        createdAt: review.created_at,
        updatedAt: review.updated_at,
        reviewedAt: review.reviewed_at,
        reviewedBy: review.reviewed_by,
        helpfulCount: review.helpful_count || 0,
        reportCount: review.report_count || 0,
      },
    });
  } catch (error) {
    console.error('[API] ❌ 創建評價異常:', error);
    res.status(500).json({
      success: false,
      error: '創建評價失敗',
    });
  }
});

/**
 * @route GET /api/reviews/driver
 * @desc 司機查看自己收到的評價列表
 * @access Driver
 * @query driverUid - 司機的 Firebase UID
 * @query page - 頁碼（預設 1）
 * @query limit - 每頁數量（預設 20）
 * @query status - 評價狀態（預設 approved）
 */
router.get('/driver', async (req: Request, res: Response): Promise<void> => {
  try {
    const { driverUid, page = '1', limit = '20', status = 'approved' } = req.query;

    console.log('[API] 司機查看評價:', {
      driverUid,
      page,
      limit,
      status,
    });

    // 1. 驗證必填參數
    if (!driverUid) {
      res.status(400).json({
        success: false,
        error: '缺少司機 UID',
      });
      return;
    }

    // 2. 查詢司機 ID（Firebase UID → Supabase UUID）
    const { data: driver, error: driverError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', driverUid)
      .single();

    if (driverError || !driver) {
      console.error('[API] 查詢司機失敗:', driverError);
      res.status(404).json({
        success: false,
        error: '司機不存在',
      });
      return;
    }

    // 3. 計算分頁參數
    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);
    const offset = (pageNum - 1) * limitNum;

    // 4. 構建查詢
    let query = supabase
      .from('reviews')
      .select(
        `
        *,
        reviewer:users!reviewer_id(
          id,
          email,
          user_profiles(first_name, last_name)
        ),
        booking:bookings(id, booking_number, start_date)
      `,
        { count: 'exact' }
      )
      .eq('reviewee_id', driver.id)
      .order('created_at', { ascending: false })
      .range(offset, offset + limitNum - 1);

    // 5. 狀態篩選
    if (status && status !== 'all') {
      query = query.eq('status', status);
    }

    const { data: reviews, error: reviewsError, count } = await query;

    if (reviewsError) {
      console.error('[API] 查詢評價失敗:', reviewsError);
      res.status(500).json({
        success: false,
        error: '查詢評價失敗',
      });
      return;
    }

    // 6. 查詢司機統計數據
    const { data: driverStats, error: statsError } = await supabase
      .from('drivers')
      .select('total_reviews, average_rating, rating_distribution')
      .eq('user_id', driver.id)
      .single();

    if (statsError) {
      console.error('[API] 查詢統計數據失敗:', statsError);
    }

    // 7. 處理評價數據（隱藏匿名評價者資訊，轉換為 camelCase）
    const processedReviews = reviews?.map((review) => {
      // 處理 reviewer 數據（可能是數組或對象）
      const reviewerData = Array.isArray(review.reviewer) ? review.reviewer[0] : review.reviewer;
      const userProfile = Array.isArray(reviewerData?.user_profiles)
        ? reviewerData?.user_profiles[0]
        : reviewerData?.user_profiles;

      // 構建顯示名稱
      let displayName = '未知用戶';
      if (review.is_anonymous) {
        displayName = '匿名用戶';
      } else if (userProfile) {
        const firstName = userProfile.first_name || '';
        const lastName = userProfile.last_name || '';
        displayName = `${firstName} ${lastName}`.trim() || reviewerData?.email || '未知用戶';
      } else if (reviewerData?.email) {
        displayName = reviewerData.email;
      }

      // 處理 booking 數據
      const bookingData = Array.isArray(review.booking) ? review.booking[0] : review.booking;

      // 轉換為 camelCase 格式
      return {
        id: review.id,
        bookingId: review.booking_id,
        reviewerId: review.reviewer_id,
        revieweeId: review.reviewee_id,
        rating: review.rating,
        comment: review.comment,
        isAnonymous: review.is_anonymous,
        status: review.status,
        adminNotes: review.admin_notes,
        createdAt: review.created_at,
        updatedAt: review.updated_at,
        reviewedAt: review.reviewed_at,
        reviewedBy: review.reviewed_by,
        helpfulCount: review.helpful_count || 0,
        reportCount: review.report_count || 0,
        reviewerName: displayName,
        booking: bookingData
          ? {
              id: bookingData.id,
              bookingNumber: bookingData.booking_number,
              startDate: bookingData.start_date,
            }
          : null,
      };
    });

    console.log('[API] ✅ 查詢成功，共 %d 條評價', count);

    // 8. 返回響應
    res.json({
      success: true,
      data: {
        reviews: processedReviews || [],
        pagination: {
          page: pageNum,
          limit: limitNum,
          total: count || 0,
          totalPages: Math.ceil((count || 0) / limitNum),
        },
        statistics: driverStats
          ? {
              averageRating: parseFloat(driverStats.average_rating) || 0,
              totalReviews: driverStats.total_reviews || 0,
              ratingDistribution: driverStats.rating_distribution || {
                1: 0,
                2: 0,
                3: 0,
                4: 0,
                5: 0,
              },
            }
          : null,
      },
    });
  } catch (error) {
    console.error('[API] ❌ 查詢評價異常:', error);
    res.status(500).json({
      success: false,
      error: '查詢評價失敗',
    });
  }
});

/**
 * @route GET /api/reviews/driver/statistics
 * @desc 獲取司機評價統計數據
 * @access Driver
 * @query driverUid - 司機的 Firebase UID
 */
router.get('/driver/statistics', async (req: Request, res: Response): Promise<void> => {
  try {
    const { driverUid } = req.query;

    console.log('[API] 查詢司機評價統計:', { driverUid });

    // 1. 驗證必填參數
    if (!driverUid) {
      res.status(400).json({
        success: false,
        error: '缺少司機 UID',
      });
      return;
    }

    // 2. 查詢司機 ID
    const { data: driver, error: driverError } = await supabase
      .from('users')
      .select('id')
      .eq('firebase_uid', driverUid)
      .single();

    if (driverError || !driver) {
      console.error('[API] 查詢司機失敗:', driverError);
      res.status(404).json({
        success: false,
        error: '司機不存在',
      });
      return;
    }

    // 3. 查詢統計數據
    const { data: stats, error: statsError } = await supabase
      .from('drivers')
      .select('total_reviews, average_rating, rating_distribution, last_review_at')
      .eq('user_id', driver.id)
      .single();

    if (statsError) {
      console.error('[API] 查詢統計失敗:', statsError);
      res.status(500).json({
        success: false,
        error: '查詢統計失敗',
      });
      return;
    }

    // 4. 查詢最近 5 條評價
    const { data: recentReviews, error: recentError } = await supabase
      .from('reviews')
      .select(
        `
        id,
        rating,
        comment,
        is_anonymous,
        created_at,
        reviewer:users!reviewer_id(
          id,
          email,
          user_profiles(first_name, last_name)
        )
      `
      )
      .eq('reviewee_id', driver.id)
      .eq('status', 'approved')
      .order('created_at', { ascending: false })
      .limit(5);

    if (recentError) {
      console.error('[API] 查詢最近評價失敗:', recentError);
    }

    console.log('[API] ✅ 統計查詢成功');

    // 5. 返回響應
    res.json({
      success: true,
      data: {
        averageRating: parseFloat(stats?.average_rating) || 0,
        totalReviews: stats?.total_reviews || 0,
        ratingDistribution: stats?.rating_distribution || {
          1: 0,
          2: 0,
          3: 0,
          4: 0,
          5: 0,
        },
        lastReviewAt: stats?.last_review_at || null,
        recentReviews:
          recentReviews?.map((review: any) => {
            // 處理 reviewer 數據
            const reviewerData = Array.isArray(review.reviewer) ? review.reviewer[0] : review.reviewer;
            const userProfile = Array.isArray(reviewerData?.user_profiles)
              ? reviewerData?.user_profiles[0]
              : reviewerData?.user_profiles;

            // 構建顯示名稱
            let reviewerName = '未知用戶';
            if (review.is_anonymous) {
              reviewerName = '匿名用戶';
            } else if (userProfile) {
              const firstName = userProfile.first_name || '';
              const lastName = userProfile.last_name || '';
              reviewerName = `${firstName} ${lastName}`.trim() || reviewerData?.email || '未知用戶';
            } else if (reviewerData?.email) {
              reviewerName = reviewerData.email;
            }

            return {
              id: review.id,
              rating: review.rating,
              comment: review.comment,
              isAnonymous: review.is_anonymous,
              createdAt: review.created_at,
              reviewerName,
            };
          }) || [],
      },
    });
  } catch (error) {
    console.error('[API] ❌ 查詢統計異常:', error);
    res.status(500).json({
      success: false,
      error: '查詢統計失敗',
    });
  }
});

/**
 * @route GET /api/reviews/check/:bookingId
 * @desc 檢查訂單是否已評價
 * @access Customer
 * @param bookingId - 訂單 ID
 */
router.get('/check/:bookingId', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;

    console.log('[API] 檢查訂單是否已評價:', { bookingId });

    // 1. 驗證必填參數
    if (!bookingId) {
      res.status(400).json({
        success: false,
        error: '缺少訂單 ID',
      });
      return;
    }

    // 2. 查詢評價記錄
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .select('id, rating, comment, created_at, status')
      .eq('booking_id', bookingId)
      .maybeSingle();

    if (reviewError) {
      console.error('[API] 查詢評價失敗:', reviewError);
      res.status(500).json({
        success: false,
        error: '查詢評價失敗',
      });
      return;
    }

    console.log('[API] ✅ 查詢成功:', review ? '已評價' : '未評價');

    // 3. 返回結果
    res.json({
      success: true,
      data: {
        hasReviewed: !!review,
        review: review
          ? {
              id: review.id,
              rating: review.rating,
              comment: review.comment,
              createdAt: review.created_at,
              status: review.status,
            }
          : null,
      },
    });
  } catch (error) {
    console.error('[API] ❌ 檢查評價異常:', error);
    res.status(500).json({
      success: false,
      error: '檢查評價失敗',
    });
  }
});

export default router;

