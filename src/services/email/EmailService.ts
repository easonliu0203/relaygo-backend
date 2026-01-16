/**
 * 電子郵件服務
 * 負責發送交易郵件（收據、通知等）
 */

import { Resend } from 'resend';
import { createClient } from '@supabase/supabase-js';

// 初始化 Resend 客戶端
const resend = new Resend(process.env.RESEND_API_KEY);

// 初始化 Supabase 客戶端
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// 郵件類型
export type EmailType = 'deposit_receipt' | 'balance_receipt';

// 郵件狀態
export type EmailStatus = 'pending' | 'sent' | 'failed' | 'bounced';

// 郵件發送結果
export interface EmailResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

// 收據資料介面
export interface ReceiptData {
  bookingNumber: string;
  customerName: string;
  customerEmail: string;
  paymentType: 'deposit' | 'balance';
  amount: number;
  paymentMethod: string;
  transactionId: string;
  paymentDate: string;
  bookingDetails: {
    pickupLocation: string;
    destination?: string;
    startDate: string;
    startTime: string;
    vehicleType: string;
    durationHours: number;
  };
  pricing: {
    basePrice: number;
    foreignLanguageSurcharge?: number;
    overtimeFee?: number;
    tipAmount?: number;
    totalAmount: number;
    depositAmount: number;
    balanceAmount: number;
  };
}

/**
 * 電子郵件服務類別
 */
export class EmailService {
  private fromEmail: string;
  private fromName: string;
  private enabled: boolean;
  private testMode: boolean;
  private testRecipient: string;

  constructor() {
    this.fromEmail = process.env.RESEND_FROM_EMAIL || 'noreply@relaygo.pro';
    this.fromName = process.env.RESEND_FROM_NAME || 'RelayGo 包車服務';
    this.enabled = process.env.EMAIL_ENABLED === 'true';
    this.testMode = process.env.EMAIL_TEST_MODE === 'true';
    this.testRecipient = process.env.EMAIL_TEST_RECIPIENT || '';
  }

  /**
   * 發送訂金收據
   */
  async sendDepositReceipt(bookingId: string): Promise<EmailResult> {
    console.log('[EmailService] 準備發送訂金收據:', bookingId);

    if (!this.enabled) {
      console.log('[EmailService] 郵件功能已停用');
      return { success: false, error: 'Email service disabled' };
    }

    try {
      // 獲取訂單和客戶資料
      const receiptData = await this.fetchReceiptData(bookingId, 'deposit');
      
      if (!receiptData) {
        throw new Error('無法獲取訂單資料');
      }

      // 生成郵件內容
      const html = this.generateReceiptHTML(receiptData);
      const subject = `RelayGo 訂金收據 - 訂單 ${receiptData.bookingNumber}`;

      // 發送郵件
      const result = await this.sendEmail({
        to: this.testMode ? this.testRecipient : receiptData.customerEmail,
        subject,
        html,
        bookingId,
        customerId: receiptData.customerEmail,
        emailType: 'deposit_receipt'
      });

      return result;
    } catch (error: any) {
      console.error('[EmailService] 發送訂金收據失敗:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * 發送尾款收據
   */
  async sendBalanceReceipt(bookingId: string): Promise<EmailResult> {
    console.log('[EmailService] 準備發送尾款收據:', bookingId);

    if (!this.enabled) {
      console.log('[EmailService] 郵件功能已停用');
      return { success: false, error: 'Email service disabled' };
    }

    try {
      // 獲取訂單和客戶資料
      const receiptData = await this.fetchReceiptData(bookingId, 'balance');
      
      if (!receiptData) {
        throw new Error('無法獲取訂單資料');
      }

      // 生成郵件內容
      const html = this.generateReceiptHTML(receiptData);
      const subject = `RelayGo 尾款收據 - 訂單 ${receiptData.bookingNumber}`;

      // 發送郵件
      const result = await this.sendEmail({
        to: this.testMode ? this.testRecipient : receiptData.customerEmail,
        subject,
        html,
        bookingId,
        customerId: receiptData.customerEmail,
        emailType: 'balance_receipt'
      });

      return result;
    } catch (error: any) {
      console.error('[EmailService] 發送尾款收據失敗:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * 從資料庫獲取收據資料
   */
  private async fetchReceiptData(
    bookingId: string,
    paymentType: 'deposit' | 'balance'
  ): Promise<ReceiptData | null> {
    try {
      // 獲取訂單資料
      const { data: booking, error: bookingError } = await supabase
        .from('bookings')
        .select(`
          *,
          customer:users!customer_id (
            id,
            email,
            user_profiles!user_id (
              first_name,
              last_name,
              phone
            )
          )
        `)
        .eq('id', bookingId)
        .single();

      if (bookingError || !booking) {
        console.error('[EmailService] 獲取訂單失敗:', bookingError);
        return null;
      }

      // 獲取支付記錄
      const { data: payment } = await supabase
        .from('payments')
        .select('*')
        .eq('booking_id', bookingId)
        .eq('type', paymentType)
        .eq('status', 'completed')
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      // 組裝收據資料
      const customerProfile = booking.customer?.user_profiles?.[0];
      const customerName = customerProfile
        ? `${customerProfile.first_name || ''} ${customerProfile.last_name || ''}`.trim()
        : booking.customer?.email || '客戶';

      const receiptData: ReceiptData = {
        bookingNumber: booking.booking_number,
        customerName,
        customerEmail: booking.customer?.email || '',
        paymentType,
        amount: payment?.amount || (paymentType === 'deposit' ? booking.deposit_amount : booking.balance_amount),
        paymentMethod: payment?.payment_method || 'credit_card',
        transactionId: payment?.transaction_id || 'N/A',
        paymentDate: payment?.created_at || new Date().toISOString(),
        bookingDetails: {
          pickupLocation: booking.pickup_location,
          destination: booking.destination,
          startDate: booking.start_date,
          startTime: booking.start_time,
          vehicleType: booking.vehicle_type,
          durationHours: booking.duration_hours
        },
        pricing: {
          basePrice: booking.base_price,
          foreignLanguageSurcharge: booking.foreign_language_surcharge || 0,
          overtimeFee: booking.overtime_fee || 0,
          tipAmount: booking.tip_amount || 0,
          totalAmount: booking.total_amount,
          depositAmount: booking.deposit_amount,
          balanceAmount: booking.balance_amount
        }
      };

      return receiptData;
    } catch (error) {
      console.error('[EmailService] fetchReceiptData 錯誤:', error);
      return null;
    }
  }

  /**
   * 發送郵件（內部方法）
   */
  private async sendEmail(params: {
    to: string;
    subject: string;
    html: string;
    bookingId: string;
    customerId: string;
    emailType: EmailType;
  }): Promise<EmailResult> {
    try {
      console.log('[EmailService] 發送郵件到:', params.to);

      // 調用 Resend API
      const { data, error } = await resend.emails.send({
        from: `${this.fromName} <${this.fromEmail}>`,
        to: params.to,
        subject: params.subject,
        html: params.html
      });

      if (error) {
        console.error('[EmailService] Resend API 錯誤:', error);

        // 記錄失敗
        await this.logEmail({
          bookingId: params.bookingId,
          customerId: params.customerId,
          emailType: params.emailType,
          recipientEmail: params.to,
          subject: params.subject,
          status: 'failed',
          errorMessage: error.message
        });

        return { success: false, error: error.message };
      }

      console.log('[EmailService] 郵件發送成功:', data?.id);

      // 記錄成功
      await this.logEmail({
        bookingId: params.bookingId,
        customerId: params.customerId,
        emailType: params.emailType,
        recipientEmail: params.to,
        subject: params.subject,
        status: 'sent',
        providerMessageId: data?.id
      });

      return { success: true, messageId: data?.id };
    } catch (error: any) {
      console.error('[EmailService] sendEmail 錯誤:', error);

      // 記錄失敗
      await this.logEmail({
        bookingId: params.bookingId,
        customerId: params.customerId,
        emailType: params.emailType,
        recipientEmail: params.to,
        subject: params.subject,
        status: 'failed',
        errorMessage: error.message
      });

      return { success: false, error: error.message };
    }
  }

  /**
   * 生成收據 HTML
   */
  private generateReceiptHTML(data: ReceiptData): string {
    const paymentTypeText = data.paymentType === 'deposit' ? '訂金' : '尾款';
    const vehicleTypeMap: Record<string, string> = {
      'A': 'A型車 (1-4人)',
      'B': 'B型車 (5-7人)',
      'C': 'C型車 (8-20人)',
      'D': 'D型車 (21人以上)'
    };

    return `
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RelayGo 電子收據</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Microsoft JhengHei', Arial, sans-serif; background-color: #f5f5f5;">
  <!-- 繼續實作 HTML 模板 -->
</body>
</html>
    `.trim();
  }

  /**
   * 記錄郵件發送到資料庫
   */
  private async logEmail(log: {
    bookingId: string;
    customerId: string;
    emailType: EmailType;
    recipientEmail: string;
    subject: string;
    status: EmailStatus;
    providerMessageId?: string;
    errorMessage?: string;
  }): Promise<void> {
    try {
      const { error } = await supabase.from('email_logs').insert({
        booking_id: log.bookingId,
        customer_id: log.customerId,
        email_type: log.emailType,
        recipient_email: log.recipientEmail,
        subject: log.subject,
        status: log.status,
        provider: 'resend',
        provider_message_id: log.providerMessageId,
        error_message: log.errorMessage,
        sent_at: log.status === 'sent' ? new Date().toISOString() : null
      });

      if (error) {
        console.error('[EmailService] 記錄郵件日誌失敗:', error);
      }
    } catch (error) {
      console.error('[EmailService] logEmail 錯誤:', error);
    }
  }
}

// 導出單例
export const emailService = new EmailService();

