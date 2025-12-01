import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

const router = Router();

// 初始化 Supabase Admin 客戶端
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
 * POST /api/auth/register-or-login
 * 用戶註冊或登入（自動創建 Supabase 用戶記錄）
 * 
 * 功能：
 * 1. 檢查用戶是否已存在於 Supabase users 表
 * 2. 如果不存在，創建新用戶記錄
 * 3. 如果已存在，返回現有用戶資料
 * 4. 支持 Google 一鍵登入和其他認證方式
 * 
 * Request Body:
 * - firebaseUid: string (必填) - Firebase Authentication UID
 * - email: string (必填) - 用戶 Email
 * - role: 'customer' | 'driver' (必填) - 用戶角色
 * - displayName?: string (選填) - 用戶顯示名稱
 * 
 * Response:
 * - success: boolean
 * - data: { id, firebase_uid, email, role, status, created_at, updated_at }
 * - message: string
 */
router.post('/register-or-login', async (req: Request, res: Response) => {
  try {
    const { firebaseUid, email, role, displayName } = req.body;

    console.log('📥 收到用戶註冊/登入請求:', {
      firebaseUid,
      email,
      role,
      displayName,
    });

    // 驗證必填欄位
    if (!firebaseUid) {
      return res.status(400).json({
        success: false,
        error: '缺少 firebaseUid 參數',
      });
    }

    if (!email) {
      return res.status(400).json({
        success: false,
        error: '缺少 email 參數',
      });
    }

    if (!role || (role !== 'customer' && role !== 'driver')) {
      return res.status(400).json({
        success: false,
        error: 'role 必須是 customer 或 driver',
      });
    }

    // 檢查用戶是否已存在
    const { data: existingUser, error: queryError } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('firebase_uid', firebaseUid)
      .maybeSingle();

    if (queryError) {
      console.error('❌ 查詢用戶失敗:', queryError);
      return res.status(500).json({
        success: false,
        error: '查詢用戶失敗',
        details: queryError.message,
      });
    }

    // 如果用戶已存在，直接返回
    if (existingUser) {
      console.log('✅ 用戶已存在，返回現有資料:', {
        id: existingUser.id,
        email: existingUser.email,
        role: existingUser.role,
      });

      return res.status(200).json({
        success: true,
        data: existingUser,
        message: '用戶已存在',
      });
    }

    // 創建新用戶
    console.log('📝 創建新用戶...');
    const { data: newUser, error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        firebase_uid: firebaseUid,
        email: email,
        role: role,
        status: 'active',
        // 注意：display_name 不在 users 表中，應該存儲在 user_profiles 表
      })
      .select()
      .single();

    if (insertError) {
      console.error('❌ 創建用戶失敗:', insertError);
      return res.status(500).json({
        success: false,
        error: '創建用戶失敗',
        details: insertError.message,
      });
    }

    console.log('✅ 用戶創建成功:', {
      id: newUser.id,
      email: newUser.email,
      role: newUser.role,
    });

    return res.status(201).json({
      success: true,
      data: newUser,
      message: '用戶創建成功',
    });
  } catch (error: any) {
    console.error('❌ 處理用戶註冊/登入時發生錯誤:', error);
    return res.status(500).json({
      success: false,
      error: '伺服器錯誤',
      details: error.message,
    });
  }
});

export default router;

