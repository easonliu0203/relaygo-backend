import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'payment_config.dart';
import 'payment_models.dart';

/// GOMYPAY 金流服務
/// 
/// 功能：
/// 1. 生成支付請求參數
/// 2. 計算 MD5 檢查碼 (ChkValue)
/// 3. 構建支付 URL
/// 4. 處理支付回應
/// 5. 錯誤處理
class GomypayService {
  /// 單例模式
  static final GomypayService _instance = GomypayService._internal();
  factory GomypayService() => _instance;
  GomypayService._internal();

  /// 創建支付請求
  /// 
  /// 參數：
  /// - [bookingId] 訂單 ID
  /// - [amount] 支付金額（新台幣，單位：元）
  /// - [paymentType] 支付類型（訂金/尾款）
  /// - [buyerName] 買方姓名
  /// - [buyerPhone] 買方電話
  /// - [buyerEmail] 買方郵件
  /// - [memo] 備註（可選）
  /// 
  /// 返回：
  /// - GomypayPaymentRequest 支付請求物件
  GomypayPaymentRequest createPaymentRequest({
    required String bookingId,
    required double amount,
    required PaymentType paymentType,
    required String buyerName,
    required String buyerPhone,
    required String buyerEmail,
    String? memo,
  }) {
    // 生成訂單編號
    // ⚠️ GOMYPAY 限制：訂單編號最多 25 個字符
    // ⚠️ GOMYPAY 要求：訂單編號必須唯一（不可重複）
    //
    // 新格式（v3）：使用更長的時間戳確保唯一性
    // 格式：{16字符bookingId}{1字符類型}{8字符時間戳} = 25字符
    // 範例：6ee49212c05e4ccfD76192886 (25字符)
    //
    // 時間戳使用毫秒級別的後8碼，確保在短時間內不會重複
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bookingIdClean = bookingId.replaceAll('-', ''); // 移除破折號
    final paymentTypeCode = paymentType == PaymentType.deposit ? 'D' : 'B'; // D=訂金, B=尾款
    final timestampLong = timestamp.toString().substring(timestamp.toString().length - 8); // 取後8碼

    // 確保總長度不超過 25 字符
    // bookingId (無破折號) = 32 字符，取前 16 字符
    // 格式：{16字符bookingId}{1字符類型}{8字符時間戳} = 25字符
    final orderNo = '${bookingIdClean.substring(0, 16)}$paymentTypeCode$timestampLong';

    // ⚠️ 修正：GOMYPAY 使用「元」為單位，不是「分」
    // 根據官方文檔：Amount | 交易金額 (最低金額 35 元)
    // 回傳範例："e_money":"35" (35 元，不是 3500 分)
    final amountInYuan = amount.toInt();

    // 計算 ChkValue（MD5 檢查碼）
    final chkValue = _calculateChkValue(
      customerId: PaymentConfig.merchantId,
      orderNo: orderNo,
      amount: amountInYuan,
      sendType: PaymentConfig.sendTypeAuth,
      apiKey: PaymentConfig.apiKey,
    );

    // 創建支付請求
    return GomypayPaymentRequest(
      sendType: PaymentConfig.sendTypeAuth,
      payModeNo: PaymentConfig.payModeCredit,
      customerId: PaymentConfig.merchantId,
      orderNo: orderNo,
      amount: amountInYuan,
      transMode: PaymentConfig.transMode,
      transCode: PaymentConfig.transCodeAuth,  // ✅ 新增：交易類別（必填參數）
      installment: PaymentConfig.installment,  // ✅ 新增：分期期數（必填參數）
      buyerName: buyerName,
      buyerTelm: buyerPhone,
      buyerMail: buyerEmail,
      buyerMemo: memo ?? '${paymentType.displayName}支付',
      returnUrl: PaymentConfig.returnUrl,
      callbackUrl: PaymentConfig.callbackUrl,
      chkValue: chkValue,
    );
  }

  /// 計算 ChkValue（MD5 檢查碼）
  /// 
  /// 公式：MD5(CustomerId + Order_No + Amount + Send_Type + API_Key)
  /// 
  /// 參數：
  /// - [customerId] 商店代號
  /// - [orderNo] 訂單編號
  /// - [amount] 交易金額（分）
  /// - [sendType] 交易類型
  /// - [apiKey] 交易密碼
  /// 
  /// 返回：
  /// - MD5 加密後的檢查碼（大寫）
  String _calculateChkValue({
    required String customerId,
    required String orderNo,
    required int amount,
    required String sendType,
    required String apiKey,
  }) {
    // 按照順序串接參數
    final rawString = '$customerId$orderNo$amount$sendType$apiKey';

    if (kDebugMode) {
      print('🔐 計算 ChkValue:');
      print('  CustomerId: $customerId');
      print('  Order_No: $orderNo');
      print('  Amount: $amount');
      print('  Send_Type: $sendType');
      print('  API_Key: $apiKey');
      print('  原始字串: $rawString');
    }

    // MD5 加密
    final bytes = utf8.encode(rawString);
    final digest = md5.convert(bytes);
    final chkValue = digest.toString().toUpperCase();

    if (kDebugMode) {
      print('  ChkValue: $chkValue');
    }

    return chkValue;
  }

  /// 構建支付 URL
  /// 
  /// 將支付請求參數附加到 API URL 後面
  /// 
  /// 參數：
  /// - [request] 支付請求物件
  /// 
  /// 返回：
  /// - 完整的支付 URL
  String buildPaymentUrl(GomypayPaymentRequest request) {
    final baseUrl = PaymentConfig.apiUrl;
    final params = request.toFormData();
    final fullUrl = '$baseUrl?$params';

    if (kDebugMode) {
      print('💳 構建支付 URL:');
      print('  Base URL: $baseUrl');
      print('  Parameters: $params');
      print('  Full URL: $fullUrl');
    }

    return fullUrl;
  }

  /// 解析支付回應
  /// 
  /// 從 URL 參數或 JSON 解析支付結果
  /// 
  /// 參數：
  /// - [urlOrJson] URL 查詢字串或 JSON 字串
  /// 
  /// 返回：
  /// - GomypayPaymentResponse 支付回應物件
  GomypayPaymentResponse parsePaymentResponse(String urlOrJson) {
    try {
      // 嘗試解析為 JSON
      if (urlOrJson.trim().startsWith('{')) {
        final json = jsonDecode(urlOrJson);
        return GomypayPaymentResponse.fromJson(json);
      }

      // 解析為 URL 參數
      final uri = Uri.parse('?$urlOrJson');
      final params = uri.queryParameters;
      return GomypayPaymentResponse.fromUrlParameters(params);
    } catch (e) {
      if (kDebugMode) {
        print('❌ 解析支付回應失敗: $e');
      }
      return GomypayPaymentResponse(
        ret: 'ERROR',
        errorCode: GomypayPaymentError.codeSystemError,
        errorMessage: '解析支付結果失敗',
      );
    }
  }

  /// 驗證支付回應的 ChkValue
  /// 
  /// 用於驗證回調結果的真實性
  /// 
  /// 參數：
  /// - [response] 支付回應物件
  /// - [receivedChkValue] 收到的 ChkValue
  /// 
  /// 返回：
  /// - true: 驗證通過
  /// - false: 驗證失敗
  bool verifyResponseChkValue(GomypayPaymentResponse response, String receivedChkValue) {
    if (response.orderId == null || response.amount == null) {
      return false;
    }

    try {
      // 解析金額（從字串轉為整數）
      final amount = int.parse(response.amount!);

      // 計算預期的 ChkValue
      final expectedChkValue = _calculateChkValue(
        customerId: PaymentConfig.merchantId,
        orderNo: response.orderId!,
        amount: amount,
        sendType: PaymentConfig.sendTypeAuth,
        apiKey: PaymentConfig.apiKey,
      );

      // 比較（不區分大小寫）
      final isValid = expectedChkValue.toUpperCase() == receivedChkValue.toUpperCase();

      if (kDebugMode) {
        print('🔐 驗證 ChkValue:');
        print('  預期: $expectedChkValue');
        print('  收到: $receivedChkValue');
        print('  結果: ${isValid ? '✅ 通過' : '❌ 失敗'}');
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 驗證 ChkValue 失敗: $e');
      }
      return false;
    }
  }

  /// 處理支付錯誤
  /// 
  /// 將支付回應轉換為錯誤物件
  /// 
  /// 參數：
  /// - [response] 支付回應物件
  /// 
  /// 返回：
  /// - GomypayPaymentError 錯誤物件
  GomypayPaymentError handlePaymentError(GomypayPaymentResponse response) {
    final errorCode = response.errorCode ?? GomypayPaymentError.codeSystemError;
    final errorMessage = response.errorMessageText;

    return GomypayPaymentError(
      code: errorCode,
      message: errorMessage,
      originalError: response,
    );
  }

  /// 打印支付請求資訊（用於調試）
  void printPaymentRequest(GomypayPaymentRequest request) {
    if (kDebugMode) {
      print('=== GOMYPAY 支付請求 ===');
      print('環境: ${PaymentConfig.environmentName}');
      print('訂單編號: ${request.orderNo}');
      print('金額: ${request.amount} 分 (${request.amount / 100} 元)');
      print('買方姓名: ${request.buyerName}');
      print('買方電話: ${request.buyerTelm}');
      print('買方郵件: ${request.buyerMail}');
      print('備註: ${request.buyerMemo}');
      print('Return_url: ${request.returnUrl}');
      print('Callback_Url: ${request.callbackUrl}');
      print('ChkValue: ${request.chkValue}');
      print('=======================');
    }
  }

  /// 打印支付回應資訊（用於調試）
  void printPaymentResponse(GomypayPaymentResponse response) {
    if (kDebugMode) {
      print('=== GOMYPAY 支付回應 ===');
      print('結果: ${response.ret}');
      print('狀態: ${response.status}');
      print('訊息: ${response.message}');
      print('訂單編號: ${response.orderId}');
      print('金額: ${response.amount}');
      print('支付時間: ${response.payTime}');
      print('授權碼: ${response.authCode}');
      print('錯誤代碼: ${response.errorCode}');
      print('錯誤訊息: ${response.errorMessage}');
      print('=======================');
    }
  }
}

