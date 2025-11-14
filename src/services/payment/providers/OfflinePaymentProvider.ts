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

// 線下支付提供者 - 用於封測階段需要人工確認的支付
export class OfflinePaymentProvider implements PaymentProvider {
  readonly name = 'Offline Payment Provider';
  readonly type = PaymentProviderType.OFFLINE;
  readonly isTestMode = true;

  private offlineTransactions: Map<string, OfflineTransaction> = new Map();

  async initiatePayment(request: PaymentRequest): Promise<PaymentResponse> {
    // 生成線下交易 ID
    const transactionId = `offline_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 儲存線下交易
    const offlineTransaction: OfflineTransaction = {
      transactionId,
      orderId: request.orderId,
      amount: request.amount,
      currency: request.currency,
      customerInfo: request.customerInfo,
      status: PaymentStatusType.PENDING,
      createdAt: new Date(),
      paymentInstructions: this.generatePaymentInstructions(request)
    };
    
    this.offlineTransactions.set(transactionId, offlineTransaction);

    // 發送通知給管理員 (實際實作中會發送郵件或推播)
    await this.notifyAdminForPayment(offlineTransaction);

    return {
      success: true,
      transactionId,
      instructions: offlineTransaction.paymentInstructions,
      expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24小時後過期
      metadata: {
        provider: 'offline',
        requiresManualConfirmation: true,
        customerInfo: request.customerInfo
      }
    };
  }

  async confirmPayment(transactionId: string): Promise<PaymentConfirmation> {
    const transaction = this.offlineTransactions.get(transactionId);
    
    if (!transaction) {
      return {
        success: false,
        transactionId,
        status: PaymentStatusType.FAILED,
        amount: 0,
        error: 'Transaction not found'
      };
    }

    // 線下支付需要等待管理員確認，所以這裡只返回當前狀態
    return {
      success: transaction.status === PaymentStatusType.COMPLETED,
      transactionId,
      status: transaction.status,
      amount: transaction.amount,
      paidAt: transaction.confirmedAt || new Date(),
      metadata: {
        provider: 'offline',
        requiresManualConfirmation: transaction.status === PaymentStatusType.PENDING,
        confirmedBy: transaction.confirmedBy
      }
    };
  }

  async refundPayment(transactionId: string, amount: number): Promise<RefundResponse> {
    const transaction = this.offlineTransactions.get(transactionId);
    
    if (!transaction || transaction.status !== PaymentStatusType.COMPLETED) {
      return {
        success: false,
        refundId: '',
        transactionId,
        amount: 0,
        error: 'Cannot refund: transaction not found or not completed'
      };
    }

    const refundId = `offline_refund_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // 線下退款需要人工處理
    transaction.status = PaymentStatusType.REFUNDED;
    transaction.refundId = refundId;
    transaction.refundAmount = amount;
    transaction.refundedAt = new Date();

    // 通知管理員處理退款
    await this.notifyAdminForRefund(transaction, amount);

    return {
      success: true,
      refundId,
      transactionId,
      amount,
      refundedAt: new Date(),
      metadata: {
        provider: 'offline',
        requiresManualProcessing: true,
        originalAmount: transaction.amount
      }
    };
  }

  async getPaymentStatus(transactionId: string): Promise<PaymentStatus> {
    const transaction = this.offlineTransactions.get(transactionId);
    
    if (!transaction) {
      throw new Error('Transaction not found');
    }

    return {
      transactionId,
      status: transaction.status,
      amount: transaction.amount,
      currency: transaction.currency,
      createdAt: transaction.createdAt,
      updatedAt: transaction.confirmedAt || transaction.createdAt,
      metadata: {
        provider: 'offline',
        orderId: transaction.orderId,
        requiresManualConfirmation: transaction.status === PaymentStatusType.PENDING
      }
    };
  }

  async handleCallback(callbackData: any): Promise<CallbackResult> {
    // 線下支付的回調通常來自管理後台的手動確認
    const { transactionId, action, adminId, notes } = callbackData;
    
    const transaction = this.offlineTransactions.get(transactionId);
    if (!transaction) {
      return {
        success: false,
        transactionId,
        status: PaymentStatusType.FAILED,
        shouldUpdateOrder: false,
        error: 'Transaction not found'
      };
    }

    let newStatus: PaymentStatusType;
    let shouldUpdateOrder = false;

    switch (action) {
      case 'confirm':
        newStatus = PaymentStatusType.COMPLETED;
        transaction.confirmedAt = new Date();
        transaction.confirmedBy = adminId;
        transaction.adminNotes = notes;
        shouldUpdateOrder = true;
        break;
      
      case 'reject':
        newStatus = PaymentStatusType.FAILED;
        transaction.rejectedAt = new Date();
        transaction.rejectedBy = adminId;
        transaction.adminNotes = notes;
        shouldUpdateOrder = true;
        break;
      
      default:
        return {
          success: false,
          transactionId,
          status: transaction.status,
          shouldUpdateOrder: false,
          error: 'Invalid action'
        };
    }

    transaction.status = newStatus;

    return {
      success: true,
      transactionId,
      status: newStatus,
      shouldUpdateOrder,
      metadata: {
        provider: 'offline',
        processedBy: adminId,
        processedAt: new Date(),
        notes
      }
    };
  }

  // 管理員手動確認支付
  async manualConfirmPayment(transactionId: string, adminId: string, notes?: string): Promise<boolean> {
    const callbackData = {
      transactionId,
      action: 'confirm',
      adminId,
      notes
    };

    const result = await this.handleCallback(callbackData);
    return result.success;
  }

  // 管理員拒絕支付
  async manualRejectPayment(transactionId: string, adminId: string, reason: string): Promise<boolean> {
    const callbackData = {
      transactionId,
      action: 'reject',
      adminId,
      notes: reason
    };

    const result = await this.handleCallback(callbackData);
    return result.success;
  }

  // 獲取待確認的支付列表
  public getPendingPayments(): OfflineTransaction[] {
    return Array.from(this.offlineTransactions.values())
      .filter(t => t.status === PaymentStatusType.PENDING);
  }

  // 生成支付說明
  private generatePaymentInstructions(request: PaymentRequest): string {
    return `
請完成以下支付步驟：

訂單編號：${request.orderId}
支付金額：${request.currency} ${request.amount}
客戶資訊：${request.customerInfo.name} (${request.customerInfo.email})

支付方式：
1. 銀行轉帳：請轉帳至指定帳戶後，聯絡客服確認
2. 現金支付：請於服務開始前支付給司機
3. 其他方式：請聯絡客服安排

注意事項：
- 請保留支付憑證
- 支付後請主動聯絡客服確認
- 24小時內未確認支付將自動取消訂單

客服聯絡方式：
電話：0800-123-456
Email：support@example.com
    `.trim();
  }

  // 通知管理員有新的支付需要確認
  private async notifyAdminForPayment(transaction: OfflineTransaction): Promise<void> {
    // 實際實作中會發送郵件、推播或其他通知方式
    console.log(`[ADMIN NOTIFICATION] New offline payment requires confirmation:`, {
      transactionId: transaction.transactionId,
      orderId: transaction.orderId,
      amount: transaction.amount,
      customer: transaction.customerInfo.email
    });
  }

  // 通知管理員處理退款
  private async notifyAdminForRefund(transaction: OfflineTransaction, amount: number): Promise<void> {
    console.log(`[ADMIN NOTIFICATION] Offline refund requires processing:`, {
      transactionId: transaction.transactionId,
      refundId: transaction.refundId,
      amount,
      customer: transaction.customerInfo.email
    });
  }
}

// 線下交易介面
interface OfflineTransaction {
  transactionId: string;
  orderId: string;
  amount: number;
  currency: string;
  customerInfo: {
    id: string;
    email: string;
    phone?: string;
    name?: string;
  };
  status: PaymentStatusType;
  createdAt: Date;
  confirmedAt?: Date;
  confirmedBy?: string;
  rejectedAt?: Date;
  rejectedBy?: string;
  refundId?: string;
  refundAmount?: number;
  refundedAt?: Date;
  adminNotes?: string;
  paymentInstructions: string;
}
