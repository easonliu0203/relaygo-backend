import express, { Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

const router = express.Router();

// Supabase 配置 - 使用 service_role key
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

// 創建 Supabase Admin 客戶端（繞過 RLS）
const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

/**
 * GET /api/profile/upsert?firebaseUid=xxx
 * 獲取用戶個人資料
 */
router.get('/upsert', async (req: Request, res: Response) => {
  try {
    const firebaseUid = req.query.firebaseUid as string;

    if (!firebaseUid) {
      return res.status(400).json({
        error: '缺少 firebaseUid 參數',
      });
    }

    console.log('📥 收到個人資料查詢請求:', { firebaseUid });

    // 根據 Firebase UID 查找 Supabase user_id 和 email
    const { data: user, error: userError } = await supabaseAdmin
      .from('users')
      .select('id, email')
      .eq('firebase_uid', firebaseUid)
      .maybeSingle();

    if (userError || !user) {
      return res.status(404).json({
        error: '用戶不存在',
        message: '請確保用戶已在 Supabase users 表中創建',
        firebaseUid: firebaseUid,
      });
    }

    const userId = user.id;
    const userEmail = user.email;

    // 查詢個人資料
    const { data: profile, error } = await supabaseAdmin
      .from('user_profiles')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

    if (error) {
      console.error('❌ 查詢個人資料失敗:', error);
      return res.status(500).json({
        error: '查詢個人資料失敗',
        message: error.message,
      });
    }

    // 如果沒有資料，返回 null
    if (!profile) {
      return res.json({
        success: true,
        data: null,
      });
    }

    // 返回資料（轉換為 camelCase，包含 email）
    return res.json({
      success: true,
      data: {
        id: profile.id,
        userId: profile.user_id,
        email: userEmail, // ✅ 添加 email 欄位（從 users 表獲取）
        firstName: profile.first_name,
        lastName: profile.last_name,
        phone: profile.phone,
        avatarUrl: profile.avatar_url,
        dateOfBirth: profile.date_of_birth,
        gender: profile.gender,
        address: profile.address,
        emergencyContactName: profile.emergency_contact_name,
        emergencyContactPhone: profile.emergency_contact_phone,
        createdAt: profile.created_at,
        updatedAt: profile.updated_at,
      },
    });
  } catch (error: any) {
    console.error('❌ API 錯誤:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message,
    });
  }
});

/**
 * POST /api/profile/upsert
 * 創建或更新用戶個人資料
 */
router.post('/upsert', async (req: Request, res: Response) => {
  try {
    const {
      firebaseUid,
      firstName,
      lastName,
      phone,
      avatarUrl,
      dateOfBirth,
      gender,
      address,
      emergencyContactName,
      emergencyContactPhone,
    } = req.body;

    console.log('📥 收到個人資料更新請求:', {
      firebaseUid,
      firstName,
      lastName,
      phone,
    });

    // 驗證必填欄位
    if (!firebaseUid) {
      return res.status(400).json({
        error: '缺少 firebaseUid 參數',
      });
    }

    // 根據 Firebase UID 查找 Supabase user_id
    const { data: user, error: userError } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('firebase_uid', firebaseUid)
      .maybeSingle();

    if (userError || !user) {
      return res.status(404).json({
        error: '用戶不存在',
        message: '請確保用戶已在 Supabase users 表中創建',
        firebaseUid: firebaseUid,
      });
    }

    const userId = user.id;

    console.log('✅ 找到用戶 ID:', userId);

    // 準備資料
    const profileData: any = {
      user_id: userId,
    };

    if (firstName !== undefined) profileData.first_name = firstName;
    if (lastName !== undefined) profileData.last_name = lastName;
    if (phone !== undefined) profileData.phone = phone;
    if (avatarUrl !== undefined) profileData.avatar_url = avatarUrl;
    if (dateOfBirth !== undefined) profileData.date_of_birth = dateOfBirth;
    if (gender !== undefined) profileData.gender = gender;
    if (address !== undefined) profileData.address = address;
    if (emergencyContactName !== undefined)
      profileData.emergency_contact_name = emergencyContactName;
    if (emergencyContactPhone !== undefined)
      profileData.emergency_contact_phone = emergencyContactPhone;

    console.log('📝 準備保存資料:', profileData);

    // 使用 upsert 創建或更新資料
    const { data: profile, error } = await supabaseAdmin
      .from('user_profiles')
      .upsert(profileData, {
        onConflict: 'user_id', // 根據 user_id 判斷是插入還是更新
      })
      .select()
      .single();

    if (error) {
      console.error('❌ 保存個人資料失敗:', {
        error,
        message: error.message,
        details: error.details,
        hint: error.hint,
        code: error.code,
      });

      return res.status(500).json({
        error: '保存個人資料失敗',
        message: error.message,
        details: error.details,
        hint: error.hint,
      });
    }

    console.log('✅ 個人資料保存成功:', {
      id: profile.id,
      user_id: profile.user_id,
      first_name: profile.first_name,
      last_name: profile.last_name,
    });

    // 返回資料（轉換為 camelCase）
    return res.json({
      success: true,
      data: {
        id: profile.id,
        userId: profile.user_id,
        firstName: profile.first_name,
        lastName: profile.last_name,
        phone: profile.phone,
        avatarUrl: profile.avatar_url,
        dateOfBirth: profile.date_of_birth,
        gender: profile.gender,
        address: profile.address,
        emergencyContactName: profile.emergency_contact_name,
        emergencyContactPhone: profile.emergency_contact_phone,
        createdAt: profile.created_at,
        updatedAt: profile.updated_at,
      },
    });
  } catch (error: any) {
    console.error('❌ API 錯誤:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message,
    });
  }
});

export default router;

