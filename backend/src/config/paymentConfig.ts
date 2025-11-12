import { PaymentProviderType, PaymentConfig } from '../services/payment/PaymentProvider';

// 支付配置管理
export class PaymentConfigManager {
  private static instance: PaymentConfigManager;
  private currentConfig: PaymentConfig;

  private constructor() {
    this.currentConfig = this.loadConfigFromEnv();
  }

  public static getInstance(): PaymentConfigManager {
    if (!PaymentConfigManager.instance) {
      PaymentConfigManager.instance = new PaymentConfigManager();
    }
    return PaymentConfigManager.instance;
  }

  // 從環境變數載入配置
  private loadConfigFromEnv(): PaymentConfig {
    const provider = (process.env.PAYMENT_PROVIDER as PaymentProviderType) || PaymentProviderType.MOCK;
    const isTestMode = process.env.NODE_ENV !== 'production' || process.env.PAYMENT_TEST_MODE === 'true';

    let config: Record<string, any> = {};

    switch (provider) {
      case PaymentProviderType.MOCK:
        config = {
          successRate: parseFloat(process.env.MOCK_PAYMENT_SUCCESS_RATE || '0.9'),
          processingDelay: parseInt(process.env.MOCK_PAYMENT_DELAY || '2000'),
          enableFailureSimulation: process.env.MOCK_PAYMENT_ENABLE_FAILURE === 'true'
        };
        break;

      case PaymentProviderType.OFFLINE:
        config = {
          adminNotificationEmail: process.env.ADMIN_NOTIFICATION_EMAIL,
          paymentExpiryHours: parseInt(process.env.OFFLINE_PAYMENT_EXPIRY_HOURS || '24'),
          autoReminderEnabled: process.env.OFFLINE_AUTO_REMINDER === 'true'
        };
        break;

      case PaymentProviderType.GOMYPAY:
        config = {
          merchantId: process.env.GOMYPAY_MERCHANT_ID,
          apiKey: process.env.GOMYPAY_API_KEY,
          isTestMode: process.env.GOMYPAY_TEST_MODE === 'true',
          returnUrl: process.env.GOMYPAY_RETURN_URL,
          callbackUrl: process.env.GOMYPAY_CALLBACK_URL
        };
        break;

      case PaymentProviderType.CREDIT_CARD:
        config = {
          merchantId: process.env.CREDIT_CARD_MERCHANT_ID,
          apiKey: process.env.CREDIT_CARD_API_KEY,
          apiSecret: process.env.CREDIT_CARD_API_SECRET,
          webhookSecret: process.env.CREDIT_CARD_WEBHOOK_SECRET,
          currency: process.env.DEFAULT_CURRENCY || 'TWD'
        };
        break;

      case PaymentProviderType.DIGITAL_WALLET:
        config = {
          appId: process.env.DIGITAL_WALLET_APP_ID,
          appSecret: process.env.DIGITAL_WALLET_APP_SECRET,
          merchantId: process.env.DIGITAL_WALLET_MERCHANT_ID,
          notifyUrl: process.env.DIGITAL_WALLET_NOTIFY_URL
        };
        break;

      case PaymentProviderType.BANK_TRANSFER:
        config = {
          bankCode: process.env.BANK_TRANSFER_BANK_CODE,
          accountNumber: process.env.BANK_TRANSFER_ACCOUNT_NUMBER,
          accountName: process.env.BANK_TRANSFER_ACCOUNT_NAME,
          autoVerificationEnabled: process.env.BANK_TRANSFER_AUTO_VERIFY === 'true'
        };
        break;
    }

    return {
      provider,
      isTestMode,
      config
    };
  }

  // 獲取當前配置
  public getCurrentConfig(): PaymentConfig {
    return { ...this.currentConfig };
  }

  // 更新配置 (用於動態切換)
  public updateConfig(newConfig: Partial<PaymentConfig>): void {
    this.currentConfig = {
      ...this.currentConfig,
      ...newConfig
    };
  }

  // 切換到封測模式
  public switchToBetaMode(): void {
    this.updateConfig({
      provider: PaymentProviderType.MOCK,
      isTestMode: true,
      config: {
        successRate: 0.95,
        processingDelay: 1000,
        enableFailureSimulation: true
      }
    });
  }

  // 切換到線下支付模式
  public switchToOfflineMode(): void {
    this.updateConfig({
      provider: PaymentProviderType.OFFLINE,
      isTestMode: true,
      config: {
        adminNotificationEmail: process.env.ADMIN_NOTIFICATION_EMAIL,
        paymentExpiryHours: 24,
        autoReminderEnabled: true
      }
    });
  }

  // 切換到生產模式
  public switchToProductionMode(provider: PaymentProviderType): void {
    if (provider === PaymentProviderType.MOCK || provider === PaymentProviderType.OFFLINE) {
      throw new Error('Cannot use mock or offline provider in production mode');
    }

    this.updateConfig({
      provider,
      isTestMode: false
    });
  }

  // 驗證配置
  public validateConfig(): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];
    const config = this.currentConfig;

    // 基本驗證
    if (!config.provider) {
      errors.push('Payment provider is required');
    }

    // 根據提供者類型進行特定驗證
    switch (config.provider) {
      case PaymentProviderType.CREDIT_CARD:
        if (!config.config.merchantId) errors.push('Credit card merchant ID is required');
        if (!config.config.apiKey) errors.push('Credit card API key is required');
        if (!config.config.apiSecret) errors.push('Credit card API secret is required');
        break;

      case PaymentProviderType.DIGITAL_WALLET:
        if (!config.config.appId) errors.push('Digital wallet app ID is required');
        if (!config.config.appSecret) errors.push('Digital wallet app secret is required');
        break;

      case PaymentProviderType.BANK_TRANSFER:
        if (!config.config.bankCode) errors.push('Bank code is required');
        if (!config.config.accountNumber) errors.push('Account number is required');
        break;

      case PaymentProviderType.OFFLINE:
        if (!config.config.adminNotificationEmail) {
          errors.push('Admin notification email is required for offline payments');
        }
        break;
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // 獲取支付方式的顯示名稱
  public getProviderDisplayName(provider?: PaymentProviderType): string {
    const targetProvider = provider || this.currentConfig.provider;
    
    const displayNames = {
      [PaymentProviderType.MOCK]: '模擬支付',
      [PaymentProviderType.OFFLINE]: '線下支付',
      [PaymentProviderType.GOMYPAY]: 'GoMyPay 信用卡支付',
      [PaymentProviderType.CREDIT_CARD]: '信用卡支付',
      [PaymentProviderType.DIGITAL_WALLET]: '電子錢包',
      [PaymentProviderType.BANK_TRANSFER]: '銀行轉帳'
    };

    return displayNames[targetProvider] || '未知支付方式';
  }

  // 檢查是否為測試模式
  public isTestMode(): boolean {
    return this.currentConfig.isTestMode;
  }

  // 檢查是否為封測階段
  public isBetaStage(): boolean {
    return this.currentConfig.provider === PaymentProviderType.MOCK || 
           this.currentConfig.provider === PaymentProviderType.OFFLINE;
  }

  // 獲取支援的支付方式列表
  public getSupportedProviders(): PaymentProviderType[] {
    if (process.env.NODE_ENV === 'production') {
      // 生產環境只支援真實支付方式
      return [
        PaymentProviderType.CREDIT_CARD,
        PaymentProviderType.DIGITAL_WALLET,
        PaymentProviderType.BANK_TRANSFER
      ];
    } else {
      // 開發/測試環境支援所有方式
      return Object.values(PaymentProviderType);
    }
  }

  // 匯出配置 (用於備份或遷移)
  public exportConfig(): string {
    return JSON.stringify(this.currentConfig, null, 2);
  }

  // 匯入配置 (用於恢復或遷移)
  public importConfig(configJson: string): void {
    try {
      const importedConfig = JSON.parse(configJson) as PaymentConfig;
      const validation = this.validateImportedConfig(importedConfig);
      
      if (!validation.isValid) {
        throw new Error(`Invalid config: ${validation.errors.join(', ')}`);
      }

      this.currentConfig = importedConfig;
    } catch (error: any) {
      throw new Error(`Failed to import config: ${error.message}`);
    }
  }

  // 驗證匯入的配置
  private validateImportedConfig(config: any): { isValid: boolean; errors: string[] } {
    const errors: string[] = [];

    if (!config.provider || !Object.values(PaymentProviderType).includes(config.provider)) {
      errors.push('Invalid or missing provider');
    }

    if (typeof config.isTestMode !== 'boolean') {
      errors.push('isTestMode must be a boolean');
    }

    if (!config.config || typeof config.config !== 'object') {
      errors.push('config must be an object');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

// 預設配置實例
export const paymentConfig = PaymentConfigManager.getInstance();
