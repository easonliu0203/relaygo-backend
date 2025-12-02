import express, { Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const router = express.Router();

// 初始化 Supabase Admin 客戶端（使用 service_role key 繞過 RLS）
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

/**
 * POST /api/drivers/ensure
 * 確保 drivers 表中存在該用戶的記錄
 *
 * 功能：
 * - 如果記錄不存在，自動創建（is_available = TRUE，臨時設定方便封測）
 * - 如果記錄已存在，返回現有記錄
 * - 使用 INSERT ... ON CONFLICT DO NOTHING 確保冪等性
 *
 * Request Body:
 * - firebaseUid: Firebase 用戶 UID
 *
 * Response:
 * - success: boolean
 * - data: Driver 記錄
 *
 * TODO: 封測結束後改回 is_available = FALSE
 */
router.post('/ensure', async (req: Request, res: Response) => {
  try {
    const { firebaseUid } = req.body;

    if (!firebaseUid) {
      return res.status(400).json({
        error: '缺少 firebaseUid 參數',
      });
    }

    console.log('📥 [DriverService] 確保 driver 記錄存在:', { firebaseUid });

    // 1. 根據 Firebase UID 查找 Supabase user_id
    const { data: user, error: userError } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('firebase_uid', firebaseUid)
      .maybeSingle();

    if (userError || !user) {
      console.error('❌ [DriverService] 用戶不存在:', userError);
      return res.status(404).json({
        error: '用戶不存在',
        message: '請確保用戶已在 Supabase users 表中創建',
        firebaseUid: firebaseUid,
      });
    }

    const userId = user.id;
    console.log('✅ [DriverService] 找到用戶 ID:', userId);

    // 2. 檢查 drivers 表中是否已有記錄
    const { data: existingDriver, error: checkError } = await supabaseAdmin
      .from('drivers')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    if (checkError) {
      console.error('❌ [DriverService] 檢查 driver 記錄失敗:', checkError);
      return res.status(500).json({
        error: '檢查 driver 記錄失敗',
        message: checkError.message,
      });
    }

    // 3. 如果已存在，直接返回
    if (existingDriver) {
      console.log('✅ [DriverService] driver 記錄已存在，返回現有記錄');
      return res.json({
        success: true,
        data: {
          id: existingDriver.id,
          userId: existingDriver.user_id,
          licenseNumber: existingDriver.license_number,
          licenseExpiry: existingDriver.license_expiry,
          vehicleType: existingDriver.vehicle_type,
          vehicleModel: existingDriver.vehicle_model,
          vehicleYear: existingDriver.vehicle_year,
          vehiclePlate: existingDriver.vehicle_plate,
          insuranceNumber: existingDriver.insurance_number,
          insuranceExpiry: existingDriver.insurance_expiry,
          backgroundCheckStatus: existingDriver.background_check_status,
          backgroundCheckDate: existingDriver.background_check_date,
          rating: existingDriver.rating,
          totalTrips: existingDriver.total_trips,
          isAvailable: existingDriver.is_available,
          languages: existingDriver.languages,
          createdAt: existingDriver.created_at,
          updatedAt: existingDriver.updated_at,
          totalReviews: existingDriver.total_reviews,
          averageRating: existingDriver.average_rating,
          ratingDistribution: existingDriver.rating_distribution,
          lastReviewAt: existingDriver.last_review_at,
        },
      });
    }

    // 4. 如果不存在，創建新記錄
    console.log('📝 [DriverService] 創建新的 driver 記錄');
    const { data: newDriver, error: insertError } = await supabaseAdmin
      .from('drivers')
      .insert({
        user_id: userId,
        is_available: true, // ⚠️ 臨時改為 TRUE，方便封測人員快速測試建立訂單功能
                            // TODO: 封測結束後改回 FALSE，需要人工審核後才能接單
        rating: 0,
        total_trips: 0,
        total_reviews: 0,
        average_rating: 0,
        background_check_status: 'pending',
      })
      .select()
      .single();

    if (insertError) {
      console.error('❌ [DriverService] 創建 driver 記錄失敗:', insertError);
      return res.status(500).json({
        error: '創建 driver 記錄失敗',
        message: insertError.message,
      });
    }

    console.log('✅ [DriverService] driver 記錄創建成功:', {
      id: newDriver.id,
      user_id: newDriver.user_id,
      is_available: newDriver.is_available,
    });

    return res.json({
      success: true,
      data: {
        id: newDriver.id,
        userId: newDriver.user_id,
        licenseNumber: newDriver.license_number,
        licenseExpiry: newDriver.license_expiry,
        vehicleType: newDriver.vehicle_type,
        vehicleModel: newDriver.vehicle_model,
        vehicleYear: newDriver.vehicle_year,
        vehiclePlate: newDriver.vehicle_plate,
        insuranceNumber: newDriver.insurance_number,
        insuranceExpiry: newDriver.insurance_expiry,
        backgroundCheckStatus: newDriver.background_check_status,
        backgroundCheckDate: newDriver.background_check_date,
        rating: newDriver.rating,
        totalTrips: newDriver.total_trips,
        isAvailable: newDriver.is_available,
        languages: newDriver.languages,
        createdAt: newDriver.created_at,
        updatedAt: newDriver.updated_at,
        totalReviews: newDriver.total_reviews,
        averageRating: newDriver.average_rating,
        ratingDistribution: newDriver.rating_distribution,
        lastReviewAt: newDriver.last_review_at,
      },
    });
  } catch (error: any) {
    console.error('❌ [DriverService] API 錯誤:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message,
    });
  }
});

export default router;

