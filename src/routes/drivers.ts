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
        vehicle_type: 'small', // ⚠️ 臨時設定為 small，方便封測人員快速測試建立訂單功能
                               // TODO: 封測結束後移除此預設值（允許 NULL）
        rating: 0,
        total_trips: 0,
        total_reviews: 0,
        average_rating: 0,
        background_check_status: 'approved', // ⚠️ 臨時改為 approved，方便封測人員快速測試建立訂單功能
                                             // TODO: 封測結束後改回 pending，需要人工審核
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

/**
 * POST /api/drivers/submit-for-review
 * 提交文件審核申請
 *
 * 功能：
 * - 驗證司機是否已上傳所有必要文件
 * - 更新 drivers 表的 review_status 為 'pending_review'
 * - 記錄提交時間
 *
 * Request Body:
 * - firebaseUid: Firebase 用戶 UID
 *
 * Response:
 * - success: boolean
 * - message: 成功或錯誤訊息
 * - missingDocuments: 缺少的文件列表（如果有）
 */
router.post('/submit-for-review', async (req: Request, res: Response) => {
  try {
    const { firebaseUid } = req.body;

    if (!firebaseUid) {
      return res.status(400).json({
        success: false,
        error: '缺少 firebaseUid 參數',
      });
    }

    console.log('📥 [DriverService] 提交文件審核:', { firebaseUid });

    // 1. 根據 Firebase UID 查找 Supabase user_id
    const { data: user, error: userError } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('firebase_uid', firebaseUid)
      .maybeSingle();

    if (userError || !user) {
      console.error('❌ [DriverService] 用戶不存在:', userError);
      return res.status(404).json({
        success: false,
        error: '用戶不存在',
      });
    }

    const userId = user.id;

    // 2. 檢查 drivers 表中是否有記錄
    const { data: driver, error: driverError } = await supabaseAdmin
      .from('drivers')
      .select('id, review_status')
      .eq('user_id', userId)
      .maybeSingle();

    if (driverError || !driver) {
      console.error('❌ [DriverService] 司機記錄不存在:', driverError);
      return res.status(404).json({
        success: false,
        error: '請先完成車輛管理頁面的基本設定',
      });
    }

    // 3. 檢查是否已經在審核中或已通過
    if (driver.review_status === 'pending_review') {
      return res.status(400).json({
        success: false,
        error: '您的申請已在審核中，請耐心等待',
      });
    }

    if (driver.review_status === 'approved') {
      return res.status(400).json({
        success: false,
        error: '您的資格已通過審核',
      });
    }

    // 4. 檢查必要文件是否已上傳
    // 必要文件：自拍照、身分證正反面、駕照、行照
    const requiredDocuments = [
      'selfie_photo',
      'id_card_front',
      'id_card_back',
      'drivers_license',
      'vehicle_registration',
    ];

    const { data: documents, error: docError } = await supabaseAdmin
      .from('driver_documents')
      .select('type')
      .eq('driver_id', firebaseUid);

    if (docError) {
      console.error('❌ [DriverService] 查詢文件失敗:', docError);
      return res.status(500).json({
        success: false,
        error: '查詢文件失敗',
      });
    }

    const uploadedTypes = documents?.map((d: any) => d.type) || [];
    const missingDocuments = requiredDocuments.filter(
      (type) => !uploadedTypes.includes(type)
    );

    // 文件類型中文名稱對照
    const documentNames: Record<string, string> = {
      selfie_photo: '自拍照片',
      id_card_front: '身分證（正面）',
      id_card_back: '身分證（背面）',
      drivers_license: '駕照',
      vehicle_registration: '行照',
    };

    if (missingDocuments.length > 0) {
      const missingNames = missingDocuments.map((type) => documentNames[type] || type);
      console.log('⚠️ [DriverService] 缺少必要文件:', missingNames);
      return res.status(400).json({
        success: false,
        error: '請先上傳所有必要文件',
        missingDocuments: missingNames,
      });
    }

    // 5. 更新 review_status 為 pending_review
    const { error: updateError } = await supabaseAdmin
      .from('drivers')
      .update({
        review_status: 'pending_review',
        review_submitted_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);

    if (updateError) {
      console.error('❌ [DriverService] 更新審核狀態失敗:', updateError);
      return res.status(500).json({
        success: false,
        error: '提交審核失敗，請稍後再試',
      });
    }

    console.log('✅ [DriverService] 文件審核申請已提交:', { firebaseUid, userId });

    return res.json({
      success: true,
      message: '已提交審核，請等待工作人員審核',
    });
  } catch (error: any) {
    console.error('❌ [DriverService] API 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
    });
  }
});

/**
 * GET /api/drivers/review-status
 * 獲取司機的審核狀態
 *
 * Query Parameters:
 * - firebaseUid: Firebase 用戶 UID
 *
 * Response:
 * - success: boolean
 * - reviewStatus: 審核狀態
 * - reviewNotes: 審核備註（如果有）
 */
router.get('/review-status', async (req: Request, res: Response) => {
  try {
    const firebaseUid = req.query.firebaseUid as string;

    if (!firebaseUid) {
      return res.status(400).json({
        success: false,
        error: '缺少 firebaseUid 參數',
      });
    }

    // 1. 根據 Firebase UID 查找 Supabase user_id
    const { data: user, error: userError } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('firebase_uid', firebaseUid)
      .maybeSingle();

    if (userError || !user) {
      return res.status(404).json({
        success: false,
        error: '用戶不存在',
      });
    }

    // 2. 獲取司機的審核狀態
    const { data: driver, error: driverError } = await supabaseAdmin
      .from('drivers')
      .select('review_status, review_notes, review_submitted_at, review_completed_at')
      .eq('user_id', user.id)
      .maybeSingle();

    if (driverError || !driver) {
      return res.json({
        success: true,
        reviewStatus: 'not_submitted',
        reviewNotes: null,
      });
    }

    return res.json({
      success: true,
      reviewStatus: driver.review_status || 'not_submitted',
      reviewNotes: driver.review_notes,
      reviewSubmittedAt: driver.review_submitted_at,
      reviewCompletedAt: driver.review_completed_at,
    });
  } catch (error: any) {
    console.error('❌ [DriverService] API 錯誤:', error);
    return res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message,
    });
  }
});

export default router;

