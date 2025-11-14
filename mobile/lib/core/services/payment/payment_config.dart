/// GOMYPAY 支付配置管理
/// 
/// 功能：
/// 1. 管理測試/正式環境的切換
/// 2. 安全地儲存商店代號和交易密碼
/// 3. 提供 API 端點 URL
/// 4. 提供環境相關的配置參數
class PaymentConfig {
  /// 是否為測試環境
  /// 
  /// true: 使用測試環境 API 和測試憑證
  /// false: 使用正式環境 API 和正式憑證
  static const bool isTestMode = true;

  /// 測試環境配置
  static const _TestConfig _testConfig = _TestConfig(
    apiUrl: 'https://n.gomypay.asia/TestShuntClass.aspx',
    merchantId: '478A0C2370B2C364AACB347DE0754E14',
    apiKey: 'f0qbvm3c0qb2qdjxwku59wimwh495271',
  );

  /// 正式環境配置
  /// 
  /// ⚠️ 注意：正式環境的憑證需要在上線前更新
  static const _ProductionConfig _productionConfig = _ProductionConfig(
    apiUrl: 'https://n.gomypay.asia/ShuntClass.aspx',
    merchantId: 'YOUR_PRODUCTION_MERCHANT_ID',  // ⚠️ 需要更新
    apiKey: 'YOUR_PRODUCTION_API_KEY',  // ⚠️ 需要更新
  );

  /// 獲取當前環境的 API URL
  static String get apiUrl => isTestMode ? _testConfig.apiUrl : _productionConfig.apiUrl;

  /// 獲取當前環境的商店代號 (CustomerId)
  static String get merchantId => isTestMode ? _testConfig.merchantId : _productionConfig.merchantId;

  /// 獲取當前環境的交易密碼 (API Key)
  static String get apiKey => isTestMode ? _testConfig.apiKey : _productionConfig.apiKey;

  /// 支付方式代碼
  static const String payModeCredit = '2';  // 信用卡

  /// 交易類型 (Send_Type)
  static const String sendTypeAuth = '0';  // 0: 信用卡

  /// 交易類別 (TransCode)
  static const String transCodeAuth = '00';  // 00: 授權

  /// 交易模式 (TransMode)
  /// 1: 一般交易（無分期）
  /// 2: 分期交易
  static const String transMode = '1';  // 一般交易（無分期）

  /// 分期期數 (Installment)
  /// 無分期請填 0
  static const String installment = '0';  // 無分期

  /// 支付完成後的返回 URL
  /// 
  /// 這個 URL 會在支付完成後，GOMYPAY 跳轉回 App 時使用
  /// 使用 Deep Link 方式讓 GOMYPAY 能夠跳轉回 Flutter App
  static String get returnUrl {
    // 使用 App 的 Deep Link Scheme
    // 格式：ridebooking://payment-result
    return 'ridebooking://payment-result';
  }

  /// 支付結果回調 URL (後端接收)
  ///
  /// GOMYPAY 會在支付完成後，主動呼叫這個 URL 通知後端支付結果
  /// 這個 URL 必須是公開可訪問的後端 API
  ///
  /// ✅ 修復：使用 Railway 部署的正式 Backend URL
  /// 測試環境和正式環境都使用同一個 URL（Railway 24/7 運行）
  static String get callbackUrl {
    // 使用 Railway 部署的 Backend API
    // 測試環境和正式環境共用同一個 URL
    return 'https://api.relaygo.pro/api/payment/gomypay-callback';
  }

  /// 支付超時時間（秒）
  static const int paymentTimeoutSeconds = 600;  // 10 分鐘

  /// 環境名稱（用於日誌）
  static String get environmentName => isTestMode ? '測試環境' : '正式環境';

  /// 打印當前配置（用於調試）
  static void printConfig() {
    print('=== GOMYPAY 支付配置 ===');
    print('環境: $environmentName');
    print('API URL: $apiUrl');
    print('商店代號: $merchantId');
    print('交易模式: $transMode');
    print('返回 URL: $returnUrl');
    print('回調 URL: $callbackUrl');
    print('=======================');
  }
}

/// 測試環境配置
class _TestConfig {
  final String apiUrl;
  final String merchantId;
  final String apiKey;

  const _TestConfig({
    required this.apiUrl,
    required this.merchantId,
    required this.apiKey,
  });
}

/// 正式環境配置
class _ProductionConfig {
  final String apiUrl;
  final String merchantId;
  final String apiKey;

  const _ProductionConfig({
    required this.apiUrl,
    required this.merchantId,
    required this.apiKey,
  });
}

