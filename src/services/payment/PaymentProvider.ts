// 支付提供者抽象介面
export interface PaymentProvider {
  readonly name: string;
  readonly type: PaymentProviderType;
  readonly isTestMode: boolean;

  // 初始化支付
  initiatePayment(request: PaymentRequest): Promise<PaymentResponse>;
  
  // 確認支付
  confirmPayment(transactionId: string): Promise<PaymentConfirmation>;
  
  // 退款
  refundPayment(transactionId: string, amount: number): Promise<RefundResponse>;
  
  // 查詢支付狀態
  getPaymentStatus(transactionId: string): Promise<PaymentStatus>;
  
  // 處理回調
  handleCallback(callbackData: any): Promise<CallbackResult>;
}

// 支付提供者類型
export enum PaymentProviderType {
  MOCK = 'mock',
  OFFLINE = 'offline',
  GOMYPAY = 'gomypay',              // GoMyPay 信用卡支付
  CREDIT_CARD = 'credit_card',
  DIGITAL_WALLET = 'digital_wallet',
  BANK_TRANSFER = 'bank_transfer'
}

// 支付請求
export interface PaymentRequest {
  orderId: string;
  amount: number;
  currency: string;
  description: string;
  customerInfo: {
    id: string;
    email: string;
    phone?: string;
    name?: string;
  };
  metadata?: Record<string, any>;
  returnUrl?: string;
  notifyUrl?: string;
}

// 支付回應
export interface PaymentResponse {
  success: boolean;
  transactionId: string;
  paymentUrl?: string;
  qrCode?: string;
  instructions?: string;
  expiresAt?: Date;
  metadata?: Record<string, any>;
  error?: string;
}

// 支付確認
export interface PaymentConfirmation {
  success: boolean;
  transactionId: string;
  status: PaymentStatusType;
  amount: number;
  paidAt?: Date;
  metadata?: Record<string, any>;
  error?: string;
}

// 退款回應
export interface RefundResponse {
  success: boolean;
  refundId: string;
  transactionId: string;
  amount: number;
  refundedAt?: Date;
  metadata?: Record<string, any>;
  error?: string;
}

// 支付狀態
export interface PaymentStatus {
  transactionId: string;
  status: PaymentStatusType;
  amount: number;
  currency: string;
  createdAt: Date;
  updatedAt: Date;
  metadata?: Record<string, any>;
}

// 支付狀態類型
export enum PaymentStatusType {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
  REFUNDED = 'refunded',
  EXPIRED = 'expired'
}

// 回調結果
export interface CallbackResult {
  success: boolean;
  transactionId: string;
  status: PaymentStatusType;
  shouldUpdateOrder: boolean;
  metadata?: Record<string, any>;
  error?: string;
}

// 支付配置
export interface PaymentConfig {
  provider: PaymentProviderType;
  isTestMode: boolean;
  config: Record<string, any>;
}

// 支付工廠
export class PaymentProviderFactory {
  private static providers: Map<PaymentProviderType, PaymentProvider> = new Map();

  static registerProvider(type: PaymentProviderType, provider: PaymentProvider): void {
    this.providers.set(type, provider);
  }

  static createProvider(config: PaymentConfig): PaymentProvider {
    const provider = this.providers.get(config.provider);
    if (!provider) {
      throw new Error(`Payment provider ${config.provider} not found`);
    }
    return provider;
  }

  static getAvailableProviders(): PaymentProviderType[] {
    return Array.from(this.providers.keys());
  }
}

// 支付服務
export class PaymentService {
  private provider: PaymentProvider;

  constructor(config: PaymentConfig) {
    this.provider = PaymentProviderFactory.createProvider(config);
  }

  async processPayment(request: PaymentRequest): Promise<PaymentResponse> {
    try {
      const response = await this.provider.initiatePayment(request);
      
      // 記錄支付請求到資料庫
      await this.savePaymentRecord(request, response);
      
      return response;
    } catch (error) {
      console.error('Payment processing failed:', error);
      throw error;
    }
  }

  async confirmPayment(transactionId: string): Promise<PaymentConfirmation> {
    const confirmation = await this.provider.confirmPayment(transactionId);
    
    // 更新支付記錄
    await this.updatePaymentRecord(transactionId, confirmation);
    
    return confirmation;
  }

  async refundPayment(transactionId: string, amount: number): Promise<RefundResponse> {
    const refund = await this.provider.refundPayment(transactionId, amount);
    
    // 記錄退款
    await this.saveRefundRecord(refund);
    
    return refund;
  }

  private async savePaymentRecord(_request: PaymentRequest, _response: PaymentResponse): Promise<void> {
    // 實作資料庫記錄邏輯
    // 這裡會調用資料庫服務保存支付記錄
  }

  private async updatePaymentRecord(_transactionId: string, _confirmation: PaymentConfirmation): Promise<void> {
    // 實作資料庫更新邏輯
  }

  private async saveRefundRecord(_refund: RefundResponse): Promise<void> {
    // 實作退款記錄邏輯
  }
}
