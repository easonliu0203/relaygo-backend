import { Resend } from 'resend';

/**
 * Resend 郵件服務
 * 用於發送電子收據和其他通知郵件
 */
export class ResendService {
  private resend: Resend;
  private fromEmail: string;

  constructor() {
    const apiKey = process.env.RESEND_API_KEY;
    if (!apiKey) {
      console.warn('[Resend] ⚠️  RESEND_API_KEY 未設定，郵件功能將無法使用');
    }
    this.resend = new Resend(apiKey);
    this.fromEmail = process.env.RESEND_FROM_EMAIL || 'send@relaygo.pro';
  }

  /**
   * 發送郵件
   */
  async sendEmail(params: {
    to: string;
    subject: string;
    html: string;
    replyTo?: string;
  }): Promise<{ success: boolean; messageId?: string; error?: string }> {
    try {
      if (!process.env.RESEND_API_KEY) {
        console.log('[Resend] ⚠️  郵件功能未啟用（缺少 API Key）');
        return { success: false, error: 'Email service not configured' };
      }

      console.log('[Resend] 發送郵件:', {
        from: this.fromEmail,
        to: params.to,
        subject: params.subject
      });

      const { data, error } = await this.resend.emails.send({
        from: `RelayGo <${this.fromEmail}>`,
        to: params.to,
        subject: params.subject,
        html: params.html,
        replyTo: params.replyTo || 'support@relaygo.pro'
      });

      if (error) {
        console.error('[Resend] 發送失敗:', error);
        return { success: false, error: error.message };
      }

      console.log('[Resend] ✅ 發送成功:', data?.id);
      return { success: true, messageId: data?.id };
    } catch (error: any) {
      console.error('[Resend] 發送異常:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * 發送收據郵件
   */
  async sendReceipt(params: {
    to: string;
    receiptHtml: string;
    subject: string;
    bookingId: string;
  }): Promise<{ success: boolean; messageId?: string; error?: string }> {
    console.log('[Resend] 發送收據郵件:', {
      bookingId: params.bookingId,
      to: params.to
    });

    return this.sendEmail({
      to: params.to,
      subject: params.subject,
      html: params.receiptHtml
    });
  }
}

// 單例模式
export const resendService = new ResendService();

