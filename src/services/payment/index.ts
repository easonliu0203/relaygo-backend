// 支付服務統一入口
import { PaymentProviderFactory, PaymentProviderType, PaymentService } from './PaymentProvider';
import { MockPaymentProvider } from './providers/MockPaymentProvider';
import { OfflinePaymentProvider } from './providers/OfflinePaymentProvider';
import { GomypayProvider } from './providers/GomypayProvider';
import { paymentConfig } from '../../config/paymentConfig';

// 註冊所有支付提供者
export function initializePaymentProviders(): void {
  // 註冊模擬支付提供者 (封測階段)
  // ✅ 修復：設置 autoMarkAsPaid: false，需要跳轉到 GoMyPay 支付頁面
  PaymentProviderFactory.registerProvider(
    PaymentProviderType.MOCK,
    new MockPaymentProvider({
      autoMarkAsPaid: false,  // ❌ 不自動標記為已付款，需要跳轉到 GoMyPay
      successRate: 0.95,      // 95% 成功率
      processingDelay: 1500,  // 1.5秒延遲
      enableFailureSimulation: true,
      realAmountTesting: true,
      logTransactions: true
    })
  );

  // 註冊線下支付提供者 (封測階段)
  PaymentProviderFactory.registerProvider(
    PaymentProviderType.OFFLINE,
    new OfflinePaymentProvider()
  );

  // 註冊 GoMyPay 支付提供者
  PaymentProviderFactory.registerProvider(
    PaymentProviderType.GOMYPAY,
    new GomypayProvider({
      merchantId: process.env.GOMYPAY_MERCHANT_ID || '478A0C2370B2C364AACB347DE0754E14',
      apiKey: process.env.GOMYPAY_API_KEY || 'f0qbvm3c0qb2qdjxwku59wimwh495271',
      isTestMode: process.env.GOMYPAY_TEST_MODE === 'true',
      returnUrl: process.env.GOMYPAY_RETURN_URL || 'https://api.relaygo.pro/api/payment/gomypay/return',
      callbackUrl: process.env.GOMYPAY_CALLBACK_URL || 'https://api.relaygo.pro/api/payment/gomypay/callback'
    })
  );

  console.log('Payment providers initialized:', PaymentProviderFactory.getAvailableProviders());
}

// 獲取當前支付服務實例
export function getPaymentService() {
  const config = paymentConfig.getCurrentConfig();
  return new PaymentService(config);
}

// 支付相關工具函數
export class PaymentUtils {
  // 生成訂單編號
  static generateOrderId(): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substr(2, 6).toUpperCase();
    return `ORD${timestamp}${random}`;
  }

  // 計算訂金
  static calculateDeposit(totalAmount: number, depositRate: number = 0.25): number {
    return Math.round(totalAmount * depositRate);
  }

  // 計算平台手續費
  static calculatePlatformFee(amount: number, feeRate: number = 0.25): number {
    return Math.round(amount * feeRate);
  }

  // 驗證金額
  static validateAmount(amount: number): boolean {
    return amount > 0 && amount <= 1000000 && Number.isInteger(amount);
  }

  // 格式化金額顯示
  static formatAmount(amount: number, currency: string = 'TWD'): string {
    const formatter = new Intl.NumberFormat('zh-TW', {
      style: 'currency',
      currency: currency,
      minimumFractionDigits: 0
    });
    return formatter.format(amount);
  }

  // 檢查支付是否過期
  static isPaymentExpired(expiresAt: Date): boolean {
    return new Date() > expiresAt;
  }

  // 生成支付描述
  static generatePaymentDescription(bookingInfo: any): string {
    const { bookingNumber, vehicleType, duration, startDate } = bookingInfo;
    return `包車服務 - 訂單 ${bookingNumber} (${vehicleType}型車, ${duration}小時, ${startDate})`;
  }
}

// 支付狀態檢查器
export class PaymentStatusChecker {
  private static instance: PaymentStatusChecker;
  private checkInterval: NodeJS.Timeout | null = null;

  private constructor() {}

  public static getInstance(): PaymentStatusChecker {
    if (!PaymentStatusChecker.instance) {
      PaymentStatusChecker.instance = new PaymentStatusChecker();
    }
    return PaymentStatusChecker.instance;
  }

  // 開始定期檢查支付狀態
  public startStatusChecking(intervalMs: number = 60000): void {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
    }

    this.checkInterval = setInterval(async () => {
      await this.checkPendingPayments();
    }, intervalMs);

    console.log(`Payment status checker started with ${intervalMs}ms interval`);
  }

  // 停止狀態檢查
  public stopStatusChecking(): void {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
      this.checkInterval = null;
      console.log('Payment status checker stopped');
    }
  }

  // 檢查待處理的支付
  private async checkPendingPayments(): Promise<void> {
    try {
      // 這裡會查詢資料庫中狀態為 pending 的支付記錄
      // 並調用對應的支付提供者檢查狀態
      
      // TODO: 實作資料庫查詢邏輯
      console.log('Checking pending payments...');
      
    } catch (error) {
      console.error('Error checking payment status:', error);
    }
  }
}

// 支付事件處理器
export class PaymentEventHandler {
  // 處理支付成功事件
  static async handlePaymentSuccess(transactionId: string, paymentData: any): Promise<void> {
    try {
      console.log(`Payment successful: ${transactionId}`, paymentData);
      
      // TODO: 實作支付成功後的業務邏輯
      // 1. 更新訂單狀態
      // 2. 發送通知
      // 3. 記錄日誌
      
    } catch (error) {
      console.error('Error handling payment success:', error);
    }
  }

  // 處理支付失敗事件
  static async handlePaymentFailure(transactionId: string, error: any): Promise<void> {
    try {
      console.log(`Payment failed: ${transactionId}`, error);
      
      // TODO: 實作支付失敗後的業務邏輯
      // 1. 更新訂單狀態
      // 2. 發送通知
      // 3. 記錄錯誤日誌
      
    } catch (error) {
      console.error('Error handling payment failure:', error);
    }
  }

  // 處理退款事件
  static async handleRefund(transactionId: string, refundData: any): Promise<void> {
    try {
      console.log(`Refund processed: ${transactionId}`, refundData);
      
      // TODO: 實作退款後的業務邏輯
      // 1. 更新訂單狀態
      // 2. 更新用戶餘額
      // 3. 發送通知
      
    } catch (error) {
      console.error('Error handling refund:', error);
    }
  }
}

// 匯出主要介面
export {
  PaymentProviderType,
  PaymentProviderFactory,
  PaymentService
} from './PaymentProvider';

export {
  MockPaymentProvider
} from './providers/MockPaymentProvider';

export {
  OfflinePaymentProvider
} from './providers/OfflinePaymentProvider';

// 匯出支付配置
export { paymentConfig } from '../../config/paymentConfig';
