import { resendService } from './resendService';
import { generateReceiptHtml, ReceiptData } from './receiptTemplate';
import { createClient } from '@supabase/supabase-js';
import moment from 'moment-timezone';
import dotenv from 'dotenv';

dotenv.config();

// 初始化 Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

/**
 * 收據郵件發送服務
 */
export class ReceiptEmailService {
  /**
   * 發送收據郵件
   */
  async sendReceiptEmail(params: {
    bookingId: string;
    paymentType: 'deposit' | 'balance';
    transactionId: string;
    amount: number;
  }): Promise<{ success: boolean; error?: string }> {
    try {
      console.log('[ReceiptEmail] 開始發送收據郵件:', params);

      // 1. 從資料庫獲取訂單詳細資訊
      const { data: booking, error: bookingError } = await supabase
        .from('bookings')
        .select(`
          *,
          customer:customer_id (
            id,
            email,
            preferred_language,
            user_profiles (first_name, last_name, phone)
          ),
          driver:driver_id (
            id,
            user_profiles (first_name, last_name, phone),
            drivers (vehicle_type, vehicle_plate)
          )
        `)
        .eq('id', params.bookingId)
        .single();

      if (bookingError || !booking) {
        console.error('[ReceiptEmail] 查詢訂單失敗:', bookingError);
        return { success: false, error: '訂單不存在' };
      }

      // 2. 檢查客戶郵箱
      const customerEmail = booking.customer?.email;
      if (!customerEmail) {
        console.warn('[ReceiptEmail] 客戶沒有郵箱地址，跳過發送');
        return { success: false, error: '客戶沒有郵箱地址' };
      }

      // 3. 準備收據資料
      const customerProfile = booking.customer?.user_profiles?.[0] || {};
      const driverProfile = booking.driver?.user_profiles?.[0] || {};
      const driverInfo = booking.driver?.drivers?.[0] || {};

      // ✅ 修復：確保客戶姓名正確顯示，如果沒有姓名則使用郵箱前綴
      const customerName = `${customerProfile.first_name || ''} ${customerProfile.last_name || ''}`.trim()
        || customerEmail.split('@')[0]
        || '客戶';
      const driverName = booking.driver ? `${driverProfile.first_name || ''} ${driverProfile.last_name || ''}`.trim() : undefined;

      const language = booking.customer?.preferred_language || 'zh-TW';

      const receiptData: ReceiptData = {
        // 訂單資訊
        bookingNumber: booking.booking_number || booking.id.substring(0, 8).toUpperCase(),
        bookingDate: moment(booking.start_date).format('YYYY-MM-DD'),
        bookingTime: booking.start_time || '',

        // 客戶資訊
        customerName,
        customerEmail,
        customerPhone: customerProfile.phone,

        // 服務詳情
        pickupLocation: booking.pickup_location || '',
        dropoffLocation: booking.destination || booking.dropoff_location,
        vehicleType: booking.vehicle_type || '',
        durationHours: booking.duration_hours || booking.duration || 0,

        // 司機資訊
        driverName,
        driverPhone: driverProfile.phone,
        vehiclePlate: driverInfo.vehicle_plate,

        // 費用明細
        paymentType: params.paymentType,
        // ✅ basePrice 保持為基本費用（不含折扣）
        // 模板會根據是否有 originalPrice 來決定顯示邏輯
        basePrice: booking.base_price || 0,
        depositAmount: booking.deposit_amount || 0,
        balanceAmount: booking.balance_amount || 0,
        overtimeFee: booking.overtime_fee || 0,
        tipAmount: booking.tip_amount || 0,
        totalAmount: booking.total_amount || booking.total_price || 0,
        paidAmount: params.amount,

        // ✅ 優惠碼和折扣資訊（付訂金當下的快照）
        promoCode: booking.promo_code || undefined,
        // 如果有優惠碼，originalPrice 是折扣前的原價
        originalPrice: booking.original_price || undefined,
        // 折扣金額
        discountAmount: booking.discount_amount || undefined,
        // 折扣後的最終價格
        finalPrice: booking.final_price || undefined,

        // ✅ 新增：統一編號
        taxId: booking.tax_id || undefined,

        // ✅ 新增：取消政策同意資訊
        policyAgreedAt: booking.policy_agreed_at
          ? moment(booking.policy_agreed_at).tz('Asia/Taipei').format('YYYY/MM/DD HH:mm')
          : undefined,

        // 支付資訊
        transactionId: params.transactionId,
        paymentMethod: 'GoMyPay',
        paymentDate: moment().tz('Asia/Taipei').format('YYYY-MM-DD HH:mm:ss'),

        // 語言
        language
      };

      // 4. 生成收據 HTML
      const receiptHtml = generateReceiptHtml(receiptData);

      // 5. 準備郵件主旨
      const subjectMap: Record<string, Record<string, string>> = {
        'zh-TW': {
          deposit: `RelayGo 訂金收據 - ${receiptData.bookingNumber}`,
          balance: `RelayGo 完整收據 - ${receiptData.bookingNumber}`
        },
        'zh-CN': {
          deposit: `RelayGo 订金收据 - ${receiptData.bookingNumber}`,
          balance: `RelayGo 完整收据 - ${receiptData.bookingNumber}`
        },
        'en': {
          deposit: `RelayGo Deposit Receipt - ${receiptData.bookingNumber}`,
          balance: `RelayGo Full Receipt - ${receiptData.bookingNumber}`
        }
      };

      const langSubjects = subjectMap[language] || subjectMap['zh-TW'];
      const subject = langSubjects[params.paymentType] || langSubjects.deposit;

      // 6. 發送郵件
      const result = await resendService.sendReceipt({
        to: customerEmail,
        receiptHtml,
        subject,
        bookingId: params.bookingId
      });

      // 7. 記錄發送結果到資料庫
      await this.logEmailSent({
        bookingId: params.bookingId,
        customerId: booking.customer_id,
        email: customerEmail,
        emailType: params.paymentType === 'deposit' ? 'deposit_receipt' : 'balance_receipt',
        success: result.success,
        messageId: result.messageId,
        error: result.error
      });

      return result;
    } catch (error: any) {
      console.error('[ReceiptEmail] 發送收據郵件異常:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * 記錄郵件發送日誌
   */
  private async logEmailSent(params: {
    bookingId: string;
    customerId: string;
    email: string;
    emailType: string;
    success: boolean;
    messageId?: string;
    error?: string;
  }): Promise<void> {
    try {
      // 這裡可以記錄到專門的郵件日誌表，或者更新訂單的備註
      console.log('[ReceiptEmail] 郵件發送日誌:', params);
      
      // TODO: 如果需要，可以創建一個 email_logs 表來記錄所有郵件發送
    } catch (error) {
      console.error('[ReceiptEmail] 記錄郵件日誌失敗:', error);
    }
  }
}

// 單例模式
export const receiptEmailService = new ReceiptEmailService();

