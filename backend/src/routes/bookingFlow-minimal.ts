import { Router, Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { createChatRoomInFirestore, chatRoomExists, sendSystemMessage } from '../config/firebase';

dotenv.config();

const router = Router();

// 初始化 Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

/**
 * @route POST /api/booking-flow/bookings/:bookingId/accept
 * @desc 司機確認接單（完整實現）
 * @access Driver
 */
router.post('/bookings/:bookingId/accept', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { driverUid } = req.body;

    console.log(`[API] 司機確認接單: bookingId=${bookingId}, driverUid=${driverUid}`);

    // 1. 查詢訂單資料
    let booking;
    let bookingError;

    try {
      const result = await supabase
        .from('bookings')
        .select('*')
        .eq('id', bookingId)
        .single();

      booking = result.data;
      bookingError = result.error;
    } catch (error: any) {
      console.error('[API] ❌ Supabase 查詢異常:', {
        message: error.message,
        stack: error.stack,
        cause: error.cause,
        code: error.code,
        errno: error.errno,
        syscall: error.syscall
      });
      res.status(500).json({
        success: false,
        error: 'Supabase 連接失敗，請檢查網絡或配置'
      });
      return;
    }

    if (bookingError || !booking) {
      console.error('[API] 查詢訂單失敗:', bookingError);
      res.status(404).json({
        success: false,
        error: '訂單不存在'
      });
      return;
    }

    console.log('[API] 訂單資料:', booking);

    // 2. 查詢司機資料（通過 Firebase UID 獲取 Supabase user ID）
    const { data: driver, error: driverError } = await supabase
      .from('users')
      .select('id, firebase_uid, email')
      .eq('firebase_uid', driverUid)
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

    console.log('[API] 司機資料:', driver);

    // 3. 驗證司機權限（檢查 driver_id 是否匹配）
    if (booking.driver_id !== driver.id) {
      console.error('[API] 司機權限驗證失敗: booking.driver_id=', booking.driver_id, 'driver.id=', driver.id);
      res.status(403).json({
        success: false,
        error: '無權限操作此訂單'
      });
      return;
    }

    // 4. 檢查訂單狀態
    if (booking.status !== 'matched') {
      console.error('[API] 訂單狀態不正確:', booking.status);
      res.status(400).json({
        success: false,
        error: `訂單狀態不正確（當前: ${booking.status}，需要: matched）`
      });
      return;
    }

    // 5. 更新訂單狀態為 driver_confirmed
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'driver_confirmed',
        updated_at: new Date().toISOString()
      })
      .eq('id', bookingId);

    if (updateError) {
      console.error('[API] 更新訂單狀態失敗:', updateError);
      res.status(500).json({
        success: false,
        error: '更新訂單狀態失敗'
      });
      return;
    }

    console.log('[API] ✅ 訂單狀態已更新為 driver_confirmed');

    // 6. 查詢客戶資訊（用於聊天室顯示）
    // 注意：booking.customer_id 是 Supabase UUID，需要查詢對應的 Firebase UID
    const { data: customer } = await supabase
      .from('users')
      .select('firebase_uid, email')
      .eq('id', booking.customer_id)
      .single();

    if (!customer || !customer.firebase_uid) {
      console.error('[API] ⚠️  客戶資訊不完整，無法創建聊天室');
      res.status(500).json({
        success: false,
        error: '客戶資訊不完整'
      });
      return;
    }

    // 7. 查詢客戶和司機的個人資料（真實姓名）
    // 優先使用真實姓名，如果未填寫則降級到 Email 截取

    // 7.1 查詢客戶個人資料
    const { data: customerProfile } = await supabase
      .from('user_profiles')
      .select('first_name, last_name')
      .eq('user_id', booking.customer_id)
      .single();

    // 7.2 查詢司機個人資料
    const { data: driverProfile } = await supabase
      .from('user_profiles')
      .select('first_name, last_name')
      .eq('user_id', driver.id)
      .single();

    // 7.3 組合客戶姓名（優先使用真實姓名）
    let customerName = '客戶';
    if (customerProfile?.first_name && customerProfile?.last_name) {
      // 如果有完整姓名，組合成 "姓 名" 格式
      customerName = `${customerProfile.last_name}${customerProfile.first_name}`;
    } else if (customerProfile?.first_name) {
      // 只有名字
      customerName = customerProfile.first_name;
    } else if (customerProfile?.last_name) {
      // 只有姓氏
      customerName = customerProfile.last_name;
    } else if (customer.email) {
      // 降級：從 Email 截取
      customerName = customer.email.split('@')[0];
    }

    // 7.4 組合司機姓名（優先使用真實姓名）
    let driverName = '司機';
    if (driverProfile?.first_name && driverProfile?.last_name) {
      // 如果有完整姓名，組合成 "姓 名" 格式
      driverName = `${driverProfile.last_name}${driverProfile.first_name}`;
    } else if (driverProfile?.first_name) {
      // 只有名字
      driverName = driverProfile.first_name;
    } else if (driverProfile?.last_name) {
      // 只有姓氏
      driverName = driverProfile.last_name;
    } else if (driver.email) {
      // 降級：從 Email 截取
      driverName = driver.email.split('@')[0];
    }

    console.log('[API] 用戶姓名:', {
      customerName,
      customerProfile: customerProfile || '未填寫',
      driverName,
      driverProfile: driverProfile || '未填寫'
    });

    // 8. 自動創建聊天室到 Firestore
    // 重要：customerId 和 driverId 必須使用 Firebase UID，不是 Supabase UUID
    const chatRoomData = {
      id: bookingId,
      bookingId,
      customerId: customer.firebase_uid,  // 使用 Firebase UID
      driverId: driverUid,                // 已經是 Firebase UID
      customerName,                       // 使用真實姓名或 Email 截取
      driverName,                         // 使用真實姓名或 Email 截取
      pickupAddress: booking.pickup_location || '',
      bookingTime: booking.start_date
    };

    console.log('[API] 聊天室資料:', {
      bookingId,
      customerFirebaseUid: customer.firebase_uid,
      customerSupabaseUuid: booking.customer_id,
      driverFirebaseUid: driverUid,
      driverSupabaseUuid: booking.driver_id
    });

    try {
      // 檢查聊天室是否已存在
      const exists = await chatRoomExists(bookingId);

      if (!exists) {
        console.log('[API] 開始創建聊天室到 Firestore...');
        await createChatRoomInFirestore(chatRoomData);

        // 發送系統歡迎訊息
        await sendSystemMessage(
          bookingId,
          '聊天室已開啟，您可以與司機/客戶開始溝通'
        );

        console.log('[API] ✅ 聊天室創建成功');
      } else {
        console.log('[API] ℹ️  聊天室已存在，跳過創建');
      }
    } catch (firebaseError) {
      // Firebase 錯誤不應該影響主流程
      console.error('[API] ⚠️  創建聊天室失敗（不影響接單）:', firebaseError);
    }

    // 8. 返回成功響應（包含聊天室資訊）
    res.json({
      success: true,
      data: {
        bookingId,
        status: 'driver_confirmed',
        chatRoom: chatRoomData,
        nextStep: 'driver_depart'
      },
      message: '接單成功'
    });

  } catch (error: any) {
    console.error('[API] 司機確認接單失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '確認接單失敗'
    });
  }
});

/**
 * @route POST /api/booking-flow/bookings/:bookingId/depart
 * @desc 司機出發前往載客
 * @access Driver
 */
router.post('/bookings/:bookingId/depart', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { driverUid } = req.body;

    console.log(`[API] 司機出發: bookingId=${bookingId}, driverUid=${driverUid}`);

    // 1. 查詢訂單資料
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('*')
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

    // 2. 查詢司機資料並驗證權限
    const { data: driver, error: driverError } = await supabase
      .from('users')
      .select('id, firebase_uid')
      .eq('firebase_uid', driverUid)
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

    // 3. 驗證司機權限
    if (booking.driver_id !== driver.id) {
      console.error('[API] 司機權限驗證失敗');
      res.status(403).json({
        success: false,
        error: '無權限操作此訂單'
      });
      return;
    }

    // 4. 檢查訂單狀態
    if (booking.status !== 'driver_confirmed') {
      console.error('[API] 訂單狀態不正確:', booking.status);
      res.status(400).json({
        success: false,
        error: `訂單狀態不正確（當前: ${booking.status}，需要: driver_confirmed）`
      });
      return;
    }

    // 5. 更新訂單狀態為 driver_departed
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'driver_departed',
        updated_at: new Date().toISOString()
      })
      .eq('id', bookingId);

    if (updateError) {
      console.error('[API] 更新訂單狀態失敗:', updateError);
      res.status(500).json({
        success: false,
        error: '更新訂單狀態失敗'
      });
      return;
    }

    console.log('[API] ✅ 訂單狀態已更新為 driver_departed');

    // 6. 發送系統訊息到聊天室
    try {
      await sendSystemMessage(
        bookingId,
        '司機已出發，正在前往上車地點 🚗'
      );
      console.log('[API] ✅ 系統訊息已發送');
    } catch (messageError) {
      console.error('[API] ⚠️  發送系統訊息失敗（不影響主流程）:', messageError);
    }

    // 7. 返回成功響應
    res.json({
      success: true,
      data: {
        bookingId,
        status: 'driver_departed',
        nextStep: 'driver_arrive'
      },
      message: '已出發'
    });

  } catch (error: any) {
    console.error('[API] 司機出發失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '出發失敗'
    });
  }
});

/**
 * @route POST /api/booking-flow/bookings/:bookingId/arrive
 * @desc 司機到達上車地點
 * @access Driver
 */
router.post('/bookings/:bookingId/arrive', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { driverUid } = req.body;

    console.log(`[API] 司機到達: bookingId=${bookingId}, driverUid=${driverUid}`);

    // 1. 查詢訂單資料
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('*')
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

    // 2. 查詢司機資料並驗證權限
    const { data: driver, error: driverError } = await supabase
      .from('users')
      .select('id, firebase_uid')
      .eq('firebase_uid', driverUid)
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

    // 3. 驗證司機權限
    if (booking.driver_id !== driver.id) {
      console.error('[API] 司機權限驗證失敗');
      res.status(403).json({
        success: false,
        error: '無權限操作此訂單'
      });
      return;
    }

    // 4. 檢查訂單狀態
    if (booking.status !== 'driver_departed') {
      console.error('[API] 訂單狀態不正確:', booking.status);
      res.status(400).json({
        success: false,
        error: `訂單狀態不正確（當前: ${booking.status}，需要: driver_departed）`
      });
      return;
    }

    // 5. 更新訂單狀態為 driver_arrived
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'driver_arrived',
        updated_at: new Date().toISOString()
      })
      .eq('id', bookingId);

    if (updateError) {
      console.error('[API] 更新訂單狀態失敗:', updateError);
      res.status(500).json({
        success: false,
        error: '更新訂單狀態失敗'
      });
      return;
    }

    console.log('[API] ✅ 訂單狀態已更新為 driver_arrived');

    // 6. 發送系統訊息到聊天室
    try {
      await sendSystemMessage(
        bookingId,
        '司機已到達上車地點，請準備上車 📍'
      );
      console.log('[API] ✅ 系統訊息已發送');
    } catch (messageError) {
      console.error('[API] ⚠️  發送系統訊息失敗（不影響主流程）:', messageError);
    }

    // 7. 返回成功響應
    res.json({
      success: true,
      data: {
        bookingId,
        status: 'driver_arrived',
        nextStep: 'start_trip'
      },
      message: '已到達'
    });

  } catch (error: any) {
    console.error('[API] 司機到達失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '到達失敗'
    });
  }
});

/**
 * @route POST /api/booking-flow/bookings/:bookingId/start-trip
 * @desc 客戶開始行程
 * @access Customer
 */
router.post('/bookings/:bookingId/start-trip', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { customerUid } = req.body;

    console.log(`[API] 客戶開始行程: bookingId=${bookingId}, customerUid=${customerUid}`);

    // 1. 查詢訂單資料
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('*')
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

    // 2. 查詢客戶資料並驗證權限
    const { data: customer, error: customerError } = await supabase
      .from('users')
      .select('id, firebase_uid')
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

    // 3. 驗證客戶權限
    if (booking.customer_id !== customer.id) {
      console.error('[API] 客戶權限驗證失敗');
      res.status(403).json({
        success: false,
        error: '無權限操作此訂單'
      });
      return;
    }

    // 4. 檢查訂單狀態（允許 driver_confirmed 或 driver_arrived）
    if (booking.status !== 'driver_confirmed' && booking.status !== 'driver_arrived') {
      console.error('[API] 訂單狀態不正確:', booking.status);
      res.status(400).json({
        success: false,
        error: `訂單狀態不正確（當前: ${booking.status}，需要: driver_confirmed 或 driver_arrived）`
      });
      return;
    }

    // 5. 更新訂單狀態為 trip_started
    const now = new Date().toISOString();
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'trip_started',
        actual_start_time: now,  // 記錄實際開始時間
        updated_at: now
      })
      .eq('id', bookingId);

    if (updateError) {
      console.error('[API] 更新訂單狀態失敗:', updateError);
      res.status(500).json({
        success: false,
        error: '更新訂單狀態失敗'
      });
      return;
    }

    console.log('[API] ✅ 訂單狀態已更新為 trip_started');

    // 6. 發送系統訊息到聊天室
    try {
      await sendSystemMessage(
        bookingId,
        '客戶已開始行程 🚀'
      );
      console.log('[API] ✅ 系統訊息已發送');
    } catch (messageError) {
      console.error('[API] ⚠️  發送系統訊息失敗（不影響主流程）:', messageError);
    }

    // 7. 返回成功響應
    res.json({
      success: true,
      data: {
        bookingId,
        status: 'trip_started',
        startedAt: now,
        nextStep: 'end_trip'
      },
      message: '行程已開始'
    });

  } catch (error: any) {
    console.error('[API] 客戶開始行程失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '開始行程失敗'
    });
  }
});

/**
 * @route POST /api/booking-flow/bookings/:bookingId/end-trip
 * @desc 客戶結束行程
 * @access Customer
 */
router.post('/bookings/:bookingId/end-trip', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { customerUid } = req.body;

    console.log(`[API] 客戶結束行程: bookingId=${bookingId}, customerUid=${customerUid}`);

    // 1. 查詢訂單資料
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('*')
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

    // 2. 查詢客戶資料並驗證權限
    const { data: customer, error: customerError } = await supabase
      .from('users')
      .select('id, firebase_uid')
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

    // 3. 驗證客戶權限
    if (booking.customer_id !== customer.id) {
      console.error('[API] 客戶權限驗證失敗');
      res.status(403).json({
        success: false,
        error: '無權限操作此訂單'
      });
      return;
    }

    // 4. 檢查訂單狀態
    if (booking.status !== 'trip_started') {
      console.error('[API] 訂單狀態不正確:', booking.status);
      res.status(400).json({
        success: false,
        error: `訂單狀態不正確（當前: ${booking.status}，需要: trip_started）`
      });
      return;
    }

    // 5. 更新訂單狀態為 trip_ended
    const now = new Date().toISOString();
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        status: 'trip_ended',
        actual_end_time: now,  // 記錄實際結束時間
        updated_at: now
      })
      .eq('id', bookingId);

    if (updateError) {
      console.error('[API] 更新訂單狀態失敗:', updateError);
      res.status(500).json({
        success: false,
        error: '更新訂單狀態失敗'
      });
      return;
    }

    console.log('[API] ✅ 訂單狀態已更新為 trip_ended');

    // 6. 發送系統訊息到聊天室
    try {
      await sendSystemMessage(
        bookingId,
        '行程已結束，請支付尾款 💰'
      );
      console.log('[API] ✅ 系統訊息已發送');
    } catch (messageError) {
      console.error('[API] ⚠️  發送系統訊息失敗（不影響主流程）:', messageError);
    }

    // 7. 返回成功響應
    res.json({
      success: true,
      data: {
        bookingId,
        status: 'trip_ended',
        endedAt: now,
        nextStep: 'pay_balance'
      },
      message: '行程已結束'
    });

  } catch (error: any) {
    console.error('[API] 客戶結束行程失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '結束行程失敗'
    });
  }
});

/**
 * @route POST /api/booking-flow/bookings/:bookingId/pay-balance
 * @desc 支付尾款
 * @access Customer
 */
router.post('/bookings/:bookingId/pay-balance', async (req: Request, res: Response): Promise<void> => {
  try {
    const { bookingId } = req.params;
    const { paymentMethod, customerUid, tipAmount = 0 } = req.body;

    console.log(`[API] 支付尾款: bookingId=${bookingId}, paymentMethod=${paymentMethod}, customerUid=${customerUid}, tipAmount=${tipAmount}`);

    // 1. 查詢訂單資料
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('*')
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

    // 2. 查詢客戶資料並驗證權限（包含 user_profiles 以獲取完整資料）
    const { data: customer, error: customerError } = await supabase
      .from('users')
      .select(`
        id,
        firebase_uid,
        email,
        phone,
        user_profiles:user_profiles(first_name, last_name, phone)
      `)
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

    // 3. 驗證客戶權限
    if (booking.customer_id !== customer.id) {
      console.error('[API] 客戶權限驗證失敗');
      res.status(403).json({
        success: false,
        error: '無權限操作此訂單'
      });
      return;
    }

    // 4. 檢查訂單狀態
    if (booking.status !== 'trip_ended') {
      console.error('[API] 訂單狀態不正確:', booking.status);
      res.status(400).json({
        success: false,
        error: `訂單狀態不正確（當前: ${booking.status}，需要: trip_ended）`
      });
      return;
    }

    // 5. 計算尾款金額（包含小費）
    const balanceAmount = booking.total_amount - booking.deposit_amount;
    const totalPayable = balanceAmount + Number(tipAmount);

    if (balanceAmount <= 0) {
      console.error('[API] 尾款金額錯誤:', balanceAmount);
      res.status(400).json({
        success: false,
        error: '尾款金額錯誤，無需支付'
      });
      return;
    }

    console.log('[API] 尾款金額:', balanceAmount);
    console.log('[API] 小費金額:', tipAmount);
    console.log('[API] 總支付金額:', totalPayable);

    // 6. 構建客戶資料（從 user_profiles 獲取完整資料）
    const userProfile = Array.isArray(customer.user_profiles) ? customer.user_profiles[0] : customer.user_profiles;
    const customerName = userProfile?.first_name && userProfile?.last_name
      ? `${userProfile.last_name}${userProfile.first_name}`
      : booking.customer_name || '客戶';
    const customerPhone = customer.phone || userProfile?.phone || booking.customer_phone || '';
    const customerEmail = customer.email || '';

    console.log('[API] 客戶資料:', {
      name: customerName,
      email: customerEmail,
      phone: customerPhone
    });

    // 7. 使用 PaymentProviderFactory 創建支付提供者（與支付訂金相同的邏輯）
    const { PaymentProviderFactory, PaymentProviderType } = await import('../services/payment/PaymentProvider');

    // 決定使用哪個支付提供者
    const paymentProviderType = process.env.PAYMENT_PROVIDER === 'gomypay'
      ? PaymentProviderType.GOMYPAY
      : PaymentProviderType.MOCK;

    console.log('[API] 使用支付提供者:', paymentProviderType);

    const provider = PaymentProviderFactory.createProvider({
      provider: paymentProviderType,
      isTestMode: process.env.GOMYPAY_TEST_MODE === 'true',
      config: {}
    });

    // 8. 發起支付（使用從 user_profiles 獲取的完整客戶資料）
    // ✅ 修復：為尾款支付添加 -BALANCE 後綴，避免與訂金支付的 Order_No 重複
    // GOMYPAY 要求每筆交易的 Order_No 必須唯一
    // 訂金: BK1763186275643-DEPOSIT
    // 尾款: BK1763186275643-BALANCE
    const paymentRequest = {
      orderId: `${booking.booking_number}-BALANCE`,  // ✅ 添加 -BALANCE 後綴
      amount: totalPayable,  // ✅ 使用包含小費的總金額
      currency: 'TWD',
      description: tipAmount > 0
        ? `RelayGo 訂單尾款 + 小費 - ${booking.booking_number}`
        : `RelayGo 訂單尾款 - ${booking.booking_number}`,
      customerInfo: {
        id: customer.id,
        name: customerName,      // ✅ 使用從 user_profiles 構建的姓名
        email: customerEmail,    // ✅ 使用從 users 獲取的信箱
        phone: customerPhone     // ✅ 使用從 users/user_profiles 獲取的電話
      },
      metadata: {
        bookingId: booking.id,
        paymentType: 'balance',
        tipAmount: tipAmount
      }
    };

    console.log('[API] 發起支付請求:', {
      provider: paymentProviderType,
      orderId: paymentRequest.orderId,
      amount: paymentRequest.amount,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone
    });

    const paymentResponse = await provider.initiatePayment(paymentRequest);

    if (!paymentResponse.success) {
      res.status(400).json({
        success: false,
        error: '支付發起失敗'
      });
      return;
    }

    console.log('[API] ✅ 支付發起成功:', {
      transactionId: paymentResponse.transactionId,
      hasPaymentUrl: !!paymentResponse.paymentUrl
    });

    // 9. 創建支付記錄（狀態為 pending，等待回調確認）
    const paymentData = {
      booking_id: bookingId,
      customer_id: customer.id,
      transaction_id: paymentResponse.transactionId,
      type: 'balance',  // 尾款類型
      amount: totalPayable,  // ✅ 使用包含小費的總金額
      currency: 'TWD',
      status: 'pending', // 等待支付完成
      payment_provider: paymentProviderType,
      payment_method: paymentMethod || 'credit_card',
      is_test_mode: process.env.GOMYPAY_TEST_MODE === 'true',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .insert(paymentData)
      .select()
      .single();

    if (paymentError) {
      console.error('[API] 創建支付記錄失敗:', paymentError);
      res.status(500).json({
        success: false,
        error: '創建支付記錄失敗'
      });
      return;
    }

    console.log('[API] ✅ 支付記錄創建成功:', payment.id);

    // 9. 返回支付 URL（如果有）或成功響應
    if (paymentResponse.paymentUrl) {
      // GoMyPay 或其他需要跳轉的支付方式
      res.json({
        success: true,
        data: {
          bookingId,
          paymentId: payment.id,
          transactionId: paymentResponse.transactionId,
          paymentUrl: paymentResponse.paymentUrl,
          instructions: paymentResponse.instructions,
          expiresAt: paymentResponse.expiresAt,
          requiresRedirect: true
        }
      });
    } else {
      // Mock 或其他自動完成的支付方式
      // 更新訂單狀態為已完成，並保存小費金額
      const now = new Date().toISOString();
      const { error: updateError } = await supabase
        .from('bookings')
        .update({
          status: 'completed',
          tip_amount: tipAmount,  // ✅ 保存小費金額
          updated_at: now
        })
        .eq('id', bookingId);

      if (updateError) {
        console.error('[API] 更新訂單狀態失敗:', updateError);
      } else {
        console.log('[API] ✅ 訂單狀態已更新為 completed');
      }

      // 發送系統訊息到聊天室
      try {
        await sendSystemMessage(
          bookingId,
          '尾款支付成功，訂單已完成 ✅'
        );
        console.log('[API] ✅ 系統訊息已發送');
      } catch (messageError) {
        console.error('[API] ⚠️  發送系統訊息失敗（不影響主流程）:', messageError);
      }

      res.json({
        success: true,
        data: {
          bookingId,
          paymentId: payment.id,
          transactionId: paymentResponse.transactionId,
          amount: balanceAmount,
          status: 'completed',
          message: '尾款支付成功'
        }
      });
    }

  } catch (error: any) {
    console.error('[API] 支付尾款失敗:', error);
    res.status(500).json({
      success: false,
      error: error.message || '支付尾款失敗'
    });
  }
});

/**
 * @route GET /api/booking-flow/test
 * @desc 測試端點
 */
router.get('/test', (_req: Request, res: Response) => {
  res.json({
    success: true,
    message: 'Booking Flow API is working',
    timestamp: new Date().toISOString()
  });
});

export default router;

