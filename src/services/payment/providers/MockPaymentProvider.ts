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

// 增強模擬支付提供者 - 專為封測階段優化
export class MockPaymentProvider implements PaymentProvider {
  readonly name = 'Enhanced Mock Payment Provider';
  readonly type = PaymentProviderType.MOCK;
  readonly isTestMode = true;

  private mockTransactions: Map<string, MockTransaction> = new Map();
  private config: MockPaymentConfig;

  constructor(config?: Partial<MockPaymentConfig>) {
    this.config = {
      successRate: config?.successRate || 0.95,           // 95% 成功率 (封測階段提高)
      processingDelay: config?.processingDelay || 1500,   // 1.5秒延遲
      enableFailureSimulation: config?.enableFailureSimulation !== false,
      autoMarkAsPaid: config?.autoMarkAsPaid !== false,   // 自動標記為已付款
      realAmountTesting: config?.realAmountTesting !== false, // 使用真實金額測試
      simulateNetworkIssues: config?.simulateNetworkIssues || false,
      logTransactions: config?.logTransactions !== false
    };
  }

  async initiatePayment(request: PaymentRequest): Promise<PaymentResponse> {
    // 記錄交易日誌
    if (this.config.logTransactions) {
      console.log(`[MockPayment] Initiating payment for order ${request.orderId}, amount: ${request.amount}`);
    }

    // 生成模擬交易 ID
    const transactionId = `mock_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // 根據配置決定支付結果
    const willSucceed = this.config.enableFailureSimulation ?
      Math.random() < this.config.successRate :
      true; // 如果不啟用失敗模擬，則總是成功
    
    // 儲存模擬交易
    const mockTransaction: MockTransaction = {
      transactionId,
      orderId: request.orderId,
      amount: request.amount,
      currency: request.currency,
      status: this.config.autoMarkAsPaid && willSucceed ?
        PaymentStatusType.COMPLETED :
        PaymentStatusType.PENDING,
      createdAt: new Date(),
      willSucceed,
      autoCompleted: this.config.autoMarkAsPaid && willSucceed,
      realAmountUsed: this.config.realAmountTesting
    };

    // 如果自動標記為已付款且會成功，則設定付款時間
    if (mockTransaction.autoCompleted) {
      mockTransaction.paidAt = new Date();
    }

    this.mockTransactions.set(transactionId, mockTransaction);

    // 模擬處理延遲 (可配置)
    await this.delay(this.config.processingDelay);

    // 生成支付說明
    const instructions = this.generatePaymentInstructions(mockTransaction);

    return {
      success: true,
      transactionId,
      paymentUrl: `https://mock-payment.example.com/pay/${transactionId}`,
      instructions,
      expiresAt: new Date(Date.now() + 30 * 60 * 1000), // 30分鐘後過期
      metadata: {
        provider: 'mock',
        testMode: true,
        autoCompleted: mockTransaction.autoCompleted,
        realAmountUsed: this.config.realAmountTesting,
        successRate: this.config.successRate,
        willSucceed: willSucceed
      }
    };
  }

  async confirmPayment(transactionId: string): Promise<PaymentConfirmation> {
    const transaction = this.mockTransactions.get(transactionId);
    
    if (!transaction) {
      return {
        success: false,
        transactionId,
        status: PaymentStatusType.FAILED,
        amount: 0,
        error: 'Transaction not found'
      };
    }

    // 模擬處理延遲
    await this.delay(2000);

    // 根據預設結果決定支付是否成功
    if (transaction.willSucceed) {
      transaction.status = PaymentStatusType.COMPLETED;
      transaction.paidAt = new Date();

      return {
        success: true,
        transactionId,
        status: PaymentStatusType.COMPLETED,
        amount: transaction.amount,
        paidAt: transaction.paidAt,
        metadata: {
          provider: 'mock',
          mockResult: 'success'
        }
      };
    } else {
      transaction.status = PaymentStatusType.FAILED;

      return {
        success: false,
        transactionId,
        status: PaymentStatusType.FAILED,
        amount: transaction.amount,
        error: 'Mock payment failed (simulated failure)',
        metadata: {
          provider: 'mock',
          mockResult: 'failure'
        }
      };
    }
  }

  async refundPayment(transactionId: string, amount: number): Promise<RefundResponse> {
    const transaction = this.mockTransactions.get(transactionId);
    
    if (!transaction || transaction.status !== PaymentStatusType.COMPLETED) {
      return {
        success: false,
        refundId: '',
        transactionId,
        amount: 0,
        error: 'Cannot refund: transaction not found or not completed'
      };
    }

    // 模擬處理延遲
    await this.delay(1500);

    const refundId = `refund_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 模擬退款成功 (95% 成功率)
    const refundSuccess = Math.random() > 0.05;

    if (refundSuccess) {
      transaction.status = PaymentStatusType.REFUNDED;
      
      return {
        success: true,
        refundId,
        transactionId,
        amount,
        refundedAt: new Date(),
        metadata: {
          provider: 'mock',
          originalAmount: transaction.amount
        }
      };
    } else {
      return {
        success: false,
        refundId,
        transactionId,
        amount: 0,
        error: 'Mock refund failed (simulated failure)'
      };
    }
  }

  async getPaymentStatus(transactionId: string): Promise<PaymentStatus> {
    const transaction = this.mockTransactions.get(transactionId);
    
    if (!transaction) {
      throw new Error('Transaction not found');
    }

    return {
      transactionId,
      status: transaction.status,
      amount: transaction.amount,
      currency: transaction.currency,
      createdAt: transaction.createdAt,
      updatedAt: transaction.paidAt || transaction.createdAt,
      metadata: {
        provider: 'mock',
        orderId: transaction.orderId
      }
    };
  }

  async handleCallback(callbackData: any): Promise<CallbackResult> {
    // 模擬回調處理
    const { transactionId, status } = callbackData;
    
    const transaction = this.mockTransactions.get(transactionId);
    if (!transaction) {
      return {
        success: false,
        transactionId,
        status: PaymentStatusType.FAILED,
        shouldUpdateOrder: false,
        error: 'Transaction not found'
      };
    }

    // 更新交易狀態
    transaction.status = status;
    if (status === PaymentStatusType.COMPLETED) {
      transaction.paidAt = new Date();
    }

    return {
      success: true,
      transactionId,
      status,
      shouldUpdateOrder: true,
      metadata: {
        provider: 'mock',
        callbackProcessedAt: new Date()
      }
    };
  }

  // 工具方法：模擬延遲
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // 工具方法：清理過期交易
  public cleanupExpiredTransactions(): void {
    const now = new Date();
    const expiredTransactions: string[] = [];

    this.mockTransactions.forEach((transaction, transactionId) => {
      const expiryTime = new Date(transaction.createdAt.getTime() + 30 * 60 * 1000);
      if (now > expiryTime && transaction.status === PaymentStatusType.PENDING) {
        transaction.status = PaymentStatusType.EXPIRED;
        expiredTransactions.push(transactionId);
      }
    });

    console.log(`Expired ${expiredTransactions.length} mock transactions`);
  }

  // 工具方法：獲取所有模擬交易 (用於測試和調試)
  public getAllMockTransactions(): MockTransaction[] {
    return Array.from(this.mockTransactions.values());
  }

  // 工具方法：重設模擬交易 (用於測試)
  public resetMockTransactions(): void {
    this.mockTransactions.clear();
  }

  // 生成支付說明
  private generatePaymentInstructions(transaction: MockTransaction): string {
    if (transaction.autoCompleted) {
      return `✅ 封測模式：支付已自動完成

訂單編號：${transaction.orderId}
支付金額：${transaction.amount} ${transaction.currency}
交易編號：${transaction.transactionId}

⚠️ 這是模擬支付，無需實際付款
✅ 系統已自動標記為「已付款」狀態
📝 所有交易記錄僅供測試使用`;
    }

    if (this.config.realAmountTesting) {
      return `🧪 封測模式：模擬真實支付流程

訂單編號：${transaction.orderId}
支付金額：${transaction.amount} ${transaction.currency}
交易編號：${transaction.transactionId}

📋 測試說明：
• 這是模擬支付，使用真實金額進行測試
• 成功率設定為 ${(this.config.successRate * 100).toFixed(0)}%
• 點擊「確認支付」完成模擬流程
• 支付結果：${transaction.willSucceed ? '✅ 預期成功' : '❌ 預期失敗'}

⚠️ 無需實際付款，僅供業務邏輯測試`;
    }

    return `🔧 封測模式：基礎支付測試

訂單編號：${transaction.orderId}
支付金額：${transaction.amount} ${transaction.currency}
交易編號：${transaction.transactionId}

📋 操作說明：
• 點擊「確認支付」模擬支付流程
• 系統將在 ${this.config.processingDelay / 1000} 秒後返回結果
• 這是純模擬環境，無需實際付款

⚠️ 僅供功能測試使用`;
  }

  // 更新配置
  public updateConfig(newConfig: Partial<MockPaymentConfig>): void {
    this.config = {
      ...this.config,
      ...newConfig
    };
  }

  // 獲取當前配置
  public getConfig(): MockPaymentConfig {
    return { ...this.config };
  }

  // 獲取統計資訊
  public getStatistics(): MockPaymentStatistics {
    const transactions = Array.from(this.mockTransactions.values());
    const total = transactions.length;
    const completed = transactions.filter(t => t.status === PaymentStatusType.COMPLETED).length;
    const failed = transactions.filter(t => t.status === PaymentStatusType.FAILED).length;
    const pending = transactions.filter(t => t.status === PaymentStatusType.PENDING).length;
    const autoCompleted = transactions.filter(t => t.autoCompleted).length;

    return {
      totalTransactions: total,
      completedTransactions: completed,
      failedTransactions: failed,
      pendingTransactions: pending,
      autoCompletedTransactions: autoCompleted,
      successRate: total > 0 ? completed / total : 0,
      averageAmount: total > 0 ?
        transactions.reduce((sum, t) => sum + t.amount, 0) / total : 0
    };
  }
}

// 模擬支付配置介面
interface MockPaymentConfig {
  successRate: number;              // 成功率 (0-1)
  processingDelay: number;          // 處理延遲 (毫秒)
  enableFailureSimulation: boolean; // 是否啟用失敗模擬
  autoMarkAsPaid: boolean;          // 是否自動標記為已付款
  realAmountTesting: boolean;       // 是否使用真實金額測試
  simulateNetworkIssues: boolean;   // 是否模擬網路問題
  logTransactions: boolean;         // 是否記錄交易日誌
}

// 模擬交易介面
interface MockTransaction {
  transactionId: string;
  orderId: string;
  amount: number;
  currency: string;
  status: PaymentStatusType;
  createdAt: Date;
  paidAt?: Date;
  willSucceed: boolean;
  autoCompleted?: boolean;          // 是否自動完成
  realAmountUsed?: boolean;         // 是否使用真實金額
}

// 模擬支付統計介面
interface MockPaymentStatistics {
  totalTransactions: number;
  completedTransactions: number;
  failedTransactions: number;
  pendingTransactions: number;
  autoCompletedTransactions: number;
  successRate: number;
  averageAmount: number;
}
