/// GOMYPAY 支付相關資料模型
/// 
/// 包含：
/// 1. 支付請求模型
/// 2. 支付回應模型
/// 3. 支付錯誤模型

/// GOMYPAY 支付請求模型
class GomypayPaymentRequest {
  /// 交易類型 (Send_Type)
  /// 0: 授權
  final String sendType;

  /// 付款方式代碼 (Pay_Mode_No)
  /// 2: 信用卡
  final String payModeNo;

  /// 商店代號 (CustomerId)
  final String customerId;

  /// 訂單編號 (Order_No)
  /// 建議格式：BOOKING_{bookingId}_{timestamp}
  final String orderNo;

  /// 交易金額 (Amount)
  /// ⚠️ 注意：以「分」為單位（例如：100元 = 10000）
  final int amount;

  /// 交易模式 (TransMode)
  /// 1: 一般交易（無分期）
  /// 2: 分期交易
  final String transMode;

  /// 交易類別 (TransCode)
  /// 00: 授權
  final String transCode;

  /// 分期期數 (Installment)
  /// 無分期請填 0
  final String installment;

  /// 買方姓名 (Buyer_Name)
  final String buyerName;

  /// 買方電話 (Buyer_Telm)
  final String buyerTelm;

  /// 買方郵件 (Buyer_Mail)
  final String buyerMail;

  /// 備註 (Buyer_Memo)
  final String? buyerMemo;

  /// 返回網址 (Return_url)
  /// 支付完成後跳轉回 App 的 Deep Link
  final String returnUrl;

  /// 回調網址 (Callback_Url)
  /// 後端接收支付結果的 API
  final String callbackUrl;

  /// 檢查碼 (ChkValue)
  /// MD5(CustomerId + Order_No + Amount + Send_Type + API_Key)
  final String chkValue;

  GomypayPaymentRequest({
    required this.sendType,
    required this.payModeNo,
    required this.customerId,
    required this.orderNo,
    required this.amount,
    required this.transMode,
    required this.transCode,
    required this.installment,
    required this.buyerName,
    required this.buyerTelm,
    required this.buyerMail,
    this.buyerMemo,
    required this.returnUrl,
    required this.callbackUrl,
    required this.chkValue,
  });

  /// 轉換為 URL 參數 Map
  Map<String, String> toUrlParameters() {
    final params = {
      'Send_Type': sendType,
      'Pay_Mode_No': payModeNo,
      'CustomerId': customerId,
      'Order_No': orderNo,
      'Amount': amount.toString(),
      'TransCode': transCode,  // ✅ 新增：交易類別（必填參數）
      'TransMode': transMode,
      'Installment': installment,  // ✅ 新增：分期期數（必填參數）
      'Buyer_Name': buyerName,
      'Buyer_Telm': buyerTelm,
      'Buyer_Mail': buyerMail,
      'Return_url': returnUrl,  // ✅ 修正：首字母大寫（根據 GOMYPAY 官方文檔）
      'Callback_Url': callbackUrl,  // ✅ 首字母大寫（根據 GOMYPAY 官方文檔）
      'ChkValue': chkValue,
    };

    // 如果有備註，加入參數
    if (buyerMemo != null && buyerMemo!.isNotEmpty) {
      params['Buyer_Memo'] = buyerMemo!;
    }

    return params;
  }

  /// 轉換為 Form Data 格式的字串
  String toFormData() {
    final params = toUrlParameters();
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  String toString() {
    return 'GomypayPaymentRequest(orderNo: $orderNo, amount: $amount, buyerName: $buyerName)';
  }
}

/// GOMYPAY 支付回應模型
class GomypayPaymentResponse {
  /// 回應代碼 (ret)
  /// OK: 成功
  /// ERROR: 失敗
  final String ret;

  /// 交易狀態 (Status)
  /// S: 成功
  /// F: 失敗
  final String? status;

  /// 訊息 (Message)
  final String? message;

  /// 訂單編號 (OrderID)
  final String? orderId;

  /// 交易金額 (Amount)
  final String? amount;

  /// 支付時間 (PayTime)
  final String? payTime;

  /// 授權碼 (AuthCode)
  final String? authCode;

  /// 錯誤代碼 (errcode)
  final String? errorCode;

  /// 錯誤訊息 (errmsg)
  final String? errorMessage;

  GomypayPaymentResponse({
    required this.ret,
    this.status,
    this.message,
    this.orderId,
    this.amount,
    this.payTime,
    this.authCode,
    this.errorCode,
    this.errorMessage,
  });

  /// 從 URL 參數解析
  factory GomypayPaymentResponse.fromUrlParameters(Map<String, String> params) {
    return GomypayPaymentResponse(
      ret: params['ret'] ?? 'ERROR',
      status: params['Status'],
      message: params['Message'],
      orderId: params['OrderID'],
      amount: params['Amount'],
      payTime: params['PayTime'],
      authCode: params['AuthCode'],
      errorCode: params['errcode'],
      errorMessage: params['errmsg'],
    );
  }

  /// 從 JSON 解析
  factory GomypayPaymentResponse.fromJson(Map<String, dynamic> json) {
    return GomypayPaymentResponse(
      ret: json['ret'] ?? 'ERROR',
      status: json['Status'],
      message: json['Message'],
      orderId: json['OrderID'],
      amount: json['Amount'],
      payTime: json['PayTime'],
      authCode: json['AuthCode'],
      errorCode: json['errcode'],
      errorMessage: json['errmsg'],
    );
  }

  /// 是否成功
  bool get isSuccess => ret == 'OK' && status == 'S';

  /// 是否失敗
  bool get isFailure => ret == 'ERROR' || status == 'F';

  /// 獲取錯誤訊息
  String get errorMessageText {
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }
    if (message != null && message!.isNotEmpty) {
      return message!;
    }
    return '支付失敗，請稍後再試';
  }

  @override
  String toString() {
    return 'GomypayPaymentResponse(ret: $ret, status: $status, message: $message, orderId: $orderId)';
  }
}

/// GOMYPAY 支付錯誤模型
class GomypayPaymentError {
  /// 錯誤代碼
  final String code;

  /// 錯誤訊息
  final String message;

  /// 原始錯誤（如果有）
  final dynamic originalError;

  GomypayPaymentError({
    required this.code,
    required this.message,
    this.originalError,
  });

  /// 常見錯誤代碼
  static const String codeParameterError = '01';  // 參數錯誤
  static const String codeCheckValueError = '02';  // 檢查碼錯誤
  static const String codeDuplicateOrder = '03';  // 訂單重複
  static const String codeAmountError = '04';  // 金額錯誤
  static const String codeSystemError = '99';  // 系統錯誤
  static const String codeNetworkError = 'NETWORK';  // 網路錯誤
  static const String codeTimeout = 'TIMEOUT';  // 超時
  static const String codeUserCancelled = 'CANCELLED';  // 用戶取消

  /// 從錯誤代碼獲取友好的錯誤訊息
  static String getErrorMessage(String code) {
    switch (code) {
      case codeParameterError:
        return '支付參數錯誤，請重試';
      case codeCheckValueError:
        return '支付驗證失敗，請重試';
      case codeDuplicateOrder:
        return '訂單已存在，請勿重複支付';
      case codeAmountError:
        return '支付金額錯誤，請重試';
      case codeSystemError:
        return '支付系統錯誤，請稍後再試';
      case codeNetworkError:
        return '網路連線失敗，請檢查網路後重試';
      case codeTimeout:
        return '支付超時，請重試';
      case codeUserCancelled:
        return '已取消支付';
      default:
        return '支付失敗，請稍後再試';
    }
  }

  @override
  String toString() {
    return 'GomypayPaymentError(code: $code, message: $message)';
  }
}

/// 支付類型枚舉
enum PaymentType {
  /// 訂金
  deposit,
  /// 尾款
  balance,
}

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.deposit:
        return '訂金';
      case PaymentType.balance:
        return '尾款';
    }
  }

  String get code {
    switch (this) {
      case PaymentType.deposit:
        return 'DEPOSIT';
      case PaymentType.balance:
        return 'BALANCE';
    }
  }
}

