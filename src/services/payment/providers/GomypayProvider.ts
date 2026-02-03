import crypto from 'crypto';
import {
  PaymentProvider, 
  PaymentProviderType, 
  PaymentRequest, 
  PaymentResponse, 
  PaymentConfirmation, 
  RefundResponse, 
  PaymentStatus, 
  PaymentStatusType,
  CallbackResult 
} from '../PaymentProvider';

/**
 * GoMyPay 支付提供者
 * 
 * 功能：
 * 1. 整合 GoMyPay 信用卡支付 API
 * 2. 支持測試環境和正式環境切換
 * 3. 自動生成交易驗證密碼（MD5）
 * 4. 處理支付回調和驗證
 */
export class GomypayProvider implements PaymentProvider {
  readonly name = 'GoMyPay Payment Provider';
  readonly type = PaymentProviderType.CREDIT_CARD;
  readonly isTestMode: boolean;

  private config: GomypayConfig;
  private apiUrl: string;

  constructor(config: GomypayConfig) {
    this.config = config;
    this.isTestMode = config.isTestMode;
    
    // 根據環境選擇 API URL
    this.apiUrl = config.isTestMode
      ? 'https://n.gomypay.asia/TestShuntClass.aspx'  // 測試環境
      : 'https://n.gomypay.asia/ShuntClass.aspx';     // 正式環境
    
    console.log(`[GoMyPay] 初始化完成 - 環境: ${this.isTestMode ? '測試' : '正式'}`);
    console.log(`[GoMyPay] API URL: ${this.apiUrl}`);
  }

  /**
   * 發起支付
   */
  async initiatePayment(request: PaymentRequest): Promise<PaymentResponse> {
    try {
      console.log(`[GoMyPay] 發起支付 - 訂單: ${request.orderId}, 金額: ${request.amount}`);
      console.log(`[GoMyPay] Return URL (即時回調): ${this.config.returnUrl}`);
      console.log(`[GoMyPay] App Deep Link: ${this.config.appDeepLink}`);

      // 生成交易驗證密碼（MD5）
      // Send_Type = '0' 表示信用卡支付
      const sendType = '0';
      const chkValue = this.generateCheckValue(request.orderId, request.amount, sendType);

      // 構建支付 URL（使用系統預設付款頁面）
      const paymentUrl = this.buildPaymentUrl({
        orderNo: request.orderId,
        amount: request.amount,
        buyerName: request.customerInfo?.name || '客戶',
        buyerTelm: request.customerInfo?.phone || '',
        buyerMail: request.customerInfo?.email || '',
        buyerMemo: request.description || '包車服務訂金',
        chkValue
      });

      console.log(`[GoMyPay] 支付 URL 生成成功`);
      console.log(`[GoMyPay] 訂單號: ${request.orderId}`);
      console.log(`[GoMyPay] 完整支付 URL: ${paymentUrl}`);

      return {
        success: true,
        transactionId: `gomypay_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        paymentUrl,
        instructions: '請在支付頁面完成信用卡支付',
        expiresAt: new Date(Date.now() + 30 * 60 * 1000), // 30分鐘後過期
        metadata: {
          provider: 'gomypay',
          testMode: this.isTestMode,
          orderNo: request.orderId,
          amount: request.amount
        }
      };
    } catch (error: any) {
      console.error('[GoMyPay] 發起支付失敗:', error);
      throw new Error(`GoMyPay 支付發起失敗: ${error.message}`);
    }
  }

  /**
   * 確認支付狀態
   */
  async confirmPayment(transactionId: string): Promise<PaymentConfirmation> {
    // GoMyPay 通過回調通知支付結果，這裡返回待處理狀態
    return {
      success: false,
      transactionId,
      status: PaymentStatusType.PENDING,
      amount: 0,
      paidAt: new Date(),
      metadata: {
        provider: 'gomypay',
        note: '等待 GoMyPay 回調通知'
      }
    };
  }

  /**
   * 處理支付回調
   */
  async handleCallback(data: Record<string, any>): Promise<CallbackResult> {
    try {
      console.log('[GoMyPay] 收到支付回調:', data);

      // 驗證回調數據
      const isValid = this.verifyCallback(data);
      if (!isValid) {
        console.error('[GoMyPay] 回調驗證失敗');
        return {
          success: false,
          transactionId: data.OrderID || '',
          status: PaymentStatusType.FAILED,
          shouldUpdateOrder: false,
          error: '回調驗證失敗'
        };
      }

      // 解析支付結果
      const result = data.result === '1' || data.result === 1;
      const status = result ? PaymentStatusType.COMPLETED : PaymentStatusType.FAILED;

      console.log(`[GoMyPay] 支付結果: ${result ? '成功' : '失敗'}`);

      return {
        success: result,
        transactionId: data.OrderID || '',
        status,
        shouldUpdateOrder: result,
        metadata: {
          orderNo: data.e_orderno,
          amount: data.e_money,
          date: data.e_date,
          time: data.e_time,
          bankName: data.bankname,
          avCode: data.avcode,
          message: data.ret_msg || (result ? '支付成功' : '支付失敗')
        }
      };
    } catch (error: any) {
      console.error('[GoMyPay] 處理回調失敗:', error);
      return {
        success: false,
        transactionId: '',
        status: PaymentStatusType.FAILED,
        shouldUpdateOrder: false,
        error: `處理回調失敗: ${error.message}`
      };
    }
  }

  /**
   * 查詢支付狀態
   */
  async getPaymentStatus(transactionId: string): Promise<PaymentStatus> {
    // GoMyPay 不提供主動查詢 API，只能通過回調獲取狀態
    return {
      transactionId,
      status: PaymentStatusType.PENDING,
      amount: 0,
      currency: 'TWD',
      createdAt: new Date(),
      updatedAt: new Date(),
      metadata: {
        provider: 'gomypay',
        note: 'GoMyPay 不支持主動查詢，請等待回調通知'
      }
    };
  }

  /**
   * 退款（GoMyPay 需要手動處理）
   */
  async refundPayment(transactionId: string, amount: number, reason?: string): Promise<RefundResponse> {
    console.log(`[GoMyPay] 退款請求 - 交易: ${transactionId}, 金額: ${amount}`);

    // GoMyPay 不支持 API 退款，需要手動在後台操作
    return {
      success: false,
      refundId: '',
      transactionId,
      amount,
      error: 'GoMyPay 不支持 API 退款，請聯繫客服手動處理',
      metadata: {
        provider: 'gomypay',
        reason,
        note: '需要在 GoMyPay 後台手動處理退款'
      }
    };
  }

  /**
   * 生成交易驗證密碼（MD5）
   *
   * 規則：MD5(商店代號 + 交易單號 + 交易金額 + Send_Type + 交易密碼)
   *
   * 注意：根據 GOMYPAY 官方文件，ChkValue 計算必須包含 Send_Type 參數
   * Send_Type = '0' 表示信用卡支付
   */
  private generateCheckValue(orderNo: string, amount: number, sendType: string = '0'): string {
    const str = `${this.config.merchantId}${orderNo}${amount}${sendType}${this.config.apiKey}`;
    console.log(`[GoMyPay] ChkValue 計算: merchantId=${this.config.merchantId}, orderNo=${orderNo}, amount=${amount}, sendType=${sendType}`);
    console.log(`[GoMyPay] ChkValue 原始字串: ${str}`);
    const chkValue = crypto.createHash('md5').update(str).digest('hex').toUpperCase();
    console.log(`[GoMyPay] ChkValue 結果: ${chkValue}`);
    return chkValue;
  }

  /**
   * 驗證回調數據
   */
  private verifyCallback(data: Record<string, any>): boolean {
    try {
      // 檢查必要欄位
      if (!data.OrderID || !data.e_orderno || !data.e_money || !data.str_check) {
        console.error('[GoMyPay] 回調數據缺少必要欄位');
        return false;
      }

      // 驗證 MD5 簽名
      // Send_Type 可能在回調數據中，如果沒有則使用預設值 '0'
      const sendType = data.Send_Type || data.send_type || '0';
      const expectedCheckValue = this.generateCheckValue(data.e_orderno, parseFloat(data.e_money), sendType);
      const actualCheckValue = data.str_check;

      if (expectedCheckValue !== actualCheckValue) {
        console.error('[GoMyPay] MD5 簽名驗證失敗');
        console.error(`期望: ${expectedCheckValue}`);
        console.error(`實際: ${actualCheckValue}`);
        return false;
      }

      return true;
    } catch (error) {
      console.error('[GoMyPay] 驗證回調數據失敗:', error);
      return false;
    }
  }

  /**
   * 構建支付 URL（使用系統預設付款頁面）
   */
  private buildPaymentUrl(params: {
    orderNo: string;
    amount: number;
    buyerName: string;
    buyerTelm: string;
    buyerMail: string;
    buyerMemo: string;
    chkValue: string;
  }): string {
    // ✅ 2026-02-03: 修復支付失敗時無法識別訂單的問題
    // 在 Return_url 中加入訂單編號參數，確保即使 GOMYPAY 不返回訂單編號，
    // 後端也能從 URL 參數中獲取
    const returnUrlWithOrderNo = this.config.returnUrl
      ? `${this.config.returnUrl}?booking_order_no=${encodeURIComponent(params.orderNo)}`
      : '';

    console.log(`[GoMyPay] Return URL (含訂單編號): ${returnUrlWithOrderNo}`);

    const queryParams = new URLSearchParams({
      Send_Type: '0',                          // 信用卡
      Pay_Mode_No: '2',                        // 付款模式
      CustomerId: this.config.merchantId,      // 商店代號
      Order_No: params.orderNo,                // 交易單號
      Amount: params.amount.toString(),        // 交易金額
      TransCode: '00',                         // 交易類別（授權）
      TransMode: '1',                          // 交易模式（一般）
      Installment: '0',                        // 期數（無分期）
      Buyer_Name: params.buyerName,            // 消費者姓名
      Buyer_Telm: params.buyerTelm,            // 消費者手機
      Buyer_Mail: params.buyerMail,            // 消費者 Email
      Buyer_Memo: params.buyerMemo,            // 交易備註
      // ✅ 2026-02-03: 修復回調延遲問題
      // 根據 GOMYPAY 工程師建議：移除 Callback_Url（會導致 5 分鐘延遲）
      // 改用 Return_url 接收即時回調（1-3 秒內）
      // ✅ 2026-02-03: 修復支付失敗時無法識別訂單的問題
      // Return_url 現在包含 booking_order_no 參數
      Return_url: returnUrlWithOrderNo,        // 授權結果回傳網址（即時回調，含訂單編號）
      // ❌ Callback_Url: 不再使用，此參數會導致 5 分鐘延遲
      Str_Check: params.chkValue               // 交易驗證密碼
    });

    return `${this.apiUrl}?${queryParams.toString()}`;
  }
}

/**
 * GoMyPay 配置介面
 *
 * ✅ 2026-02-03: 修復回調延遲問題
 * - 移除 callbackUrl 欄位（Callback_Url 會導致 5 分鐘延遲）
 * - 現在只使用 returnUrl 接收即時回調（1-3 秒內）
 * - returnUrl 應指向後端 API 端點，處理完成後重定向到 App Deep Link
 */
export interface GomypayConfig {
  merchantId: string;      // 商店代號
  apiKey: string;          // 交易密碼
  isTestMode: boolean;     // 是否為測試環境
  returnUrl?: string;      // 授權結果回傳網址（即時回調 + 重定向）
  appDeepLink?: string;    // App Deep Link（處理完成後重定向目標）
}

