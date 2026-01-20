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

    // 如果用戶已存在，檢查是否需要添加新角色
    if (existingUser) {
      // ✅ 檢查帳號狀態
      if (existingUser.status === 'deleted') {
        console.warn('⚠️ 用戶帳號已刪除:', {
          id: existingUser.id,
          email: existingUser.email,
          deletedAt: existingUser.deleted_at,
        });
        return res.status(403).json({
          success: false,
          error: '此帳號已申請刪除，無法登入',
          message: '如需恢復請聯繫客服：kyle5916263@gmail.com',
          message_en: 'This account has been deleted. Please contact support at kyle5916263@gmail.com to restore.',
        });
      }

      const currentRoles = existingUser.roles || [];

      console.log('✅ 用戶已存在:', {
        id: existingUser.id,
        email: existingUser.email,
        currentRoles: currentRoles,
        requestedRole: role,
      });

      // 檢查角色是否已存在
      if (!currentRoles.includes(role)) {
        // 添加新角色
        const updatedRoles = [...currentRoles, role];

        console.log('📝 添加新角色:', {
          oldRoles: currentRoles,
          newRoles: updatedRoles,
        });

        const { data: updatedUser, error: updateError } = await supabaseAdmin
          .from('users')
          .update({
            roles: updatedRoles,
            role: role, // 同時更新 role 欄位（向後兼容）
          })
          .eq('id', existingUser.id)
          .select()
          .single();

        if (updateError) {
          console.error('❌ 添加角色失敗:', updateError);
          return res.status(500).json({
            success: false,
            error: '添加角色失敗',
            details: updateError.message,
          });
        }

        console.log('✅ 角色添加成功:', {
          id: updatedUser.id,
          roles: updatedUser.roles,
        });

        return res.status(200).json({
          success: true,
          data: updatedUser,
          message: `角色 ${role} 已添加`,
        });
      }

      // 角色已存在，直接返回
      return res.status(200).json({
        success: true,
        data: existingUser,
        message: '用戶已存在',
      });
    }

    // 創建新用戶（包含 roles 陣列）
    console.log('📝 創建新用戶...');
    const { data: newUser, error: insertError } = await supabaseAdmin
      .from('users')
      .insert({
        firebase_uid: firebaseUid,
        email: email,
        role: role, // 保留 role 欄位（向後兼容）
        roles: [role], // ✅ 使用 roles 陣列
        status: 'active',
        // 注意：display_name 不在 users 表中，應該存儲在 user_profiles 表
      })
      .select()
      .single();

    if (insertError) {
      console.error('❌ 創建用戶失敗:', insertError);

      // ✅ 特殊處理：如果是 email 重複錯誤，檢查是否為同一用戶
      if (insertError.code === '23505' && insertError.message.includes('users_email_key')) {
        console.log('⚠️ Email 已存在，檢查是否為同一用戶...');

        // 根據 email 查找現有用戶
        const { data: existingUserByEmail, error: emailQueryError } = await supabaseAdmin
          .from('users')
          .select('*')
          .eq('email', email)
          .maybeSingle();

        if (emailQueryError || !existingUserByEmail) {
          console.error('❌ 無法找到 email 對應的用戶:', emailQueryError);
          return res.status(500).json({
            success: false,
            error: '資料庫錯誤',
            details: insertError.message,
          });
        }

        console.log('📋 現有用戶資訊:', {
          id: existingUserByEmail.id,
          email: existingUserByEmail.email,
          firebase_uid: existingUserByEmail.firebase_uid,
          roles: existingUserByEmail.roles,
        });

        // ⚠️ 安全檢查：Firebase UID 不匹配
        if (existingUserByEmail.firebase_uid && existingUserByEmail.firebase_uid !== firebaseUid) {
          console.error('❌ Firebase UID 不匹配:', {
            existingFirebaseUid: existingUserByEmail.firebase_uid,
            requestFirebaseUid: firebaseUid,
          });

          return res.status(409).json({
            success: false,
            error: '此 Email 已被其他帳號使用',
            message: '此 Email 已與另一個 Google 帳號綁定。請使用原本的 Google 帳號登入，或使用其他 Email。',
            message_en: 'This email is already associated with another Google account. Please sign in with your original Google account or use a different email.',
          });
        }

        // ✅ Firebase UID 匹配或為空，可以安全更新
        const currentRoles = existingUserByEmail.roles || [];
        const updatedRoles = currentRoles.includes(role) ? currentRoles : [...currentRoles, role];

        console.log('📝 更新現有用戶的角色:', {
          id: existingUserByEmail.id,
          oldRoles: currentRoles,
          newRoles: updatedRoles,
        });

        const { data: updatedUser, error: updateError } = await supabaseAdmin
          .from('users')
          .update({
            firebase_uid: firebaseUid, // 更新或設置 Firebase UID
            roles: updatedRoles,
            role: role,
            status: 'active',
          })
          .eq('id', existingUserByEmail.id)
          .select()
          .single();

        if (updateError) {
          console.error('❌ 更新用戶失敗:', updateError);
          return res.status(500).json({
            success: false,
            error: '更新用戶失敗',
            details: updateError.message,
          });
        }

        console.log('✅ 用戶更新成功:', {
          id: updatedUser.id,
          email: updatedUser.email,
          firebase_uid: updatedUser.firebase_uid,
          roles: updatedUser.roles,
        });

        return res.status(200).json({
          success: true,
          data: updatedUser,
          message: '登入成功',
        });
      }

      // 其他錯誤
      return res.status(500).json({
        success: false,
        error: '資料庫錯誤',
        details: insertError.message,
      });
    }

    console.log('✅ 用戶創建成功:', {
      id: newUser.id,
      email: newUser.email,
      role: newUser.role,
      roles: newUser.roles,
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

