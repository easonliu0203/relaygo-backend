/// GOMYPAY 參數驗證腳本
/// 
/// 用途：驗證支付請求參數是否正確，特別是 return_url 參數名稱
/// 
/// 運行方式：
/// ```bash
/// dart mobile/scripts/verify-gomypay-params.dart
/// ```

import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  print('');
  print('🔍 GOMYPAY 參數驗證腳本');
  print('=' * 60);
  print('');

  // 模擬支付請求參數
  final testParams = createTestPaymentRequest();

  // 驗證參數
  verifyParameters(testParams);

  // 顯示完整 URL
  displayPaymentUrl(testParams);

  print('');
  print('=' * 60);
  print('✅ 驗證完成！');
  print('');
}

/// 創建測試支付請求
Map<String, String> createTestPaymentRequest() {
  // 測試配置
  const merchantId = '478A0C2370B2C364AACB347DE0754E14';
  const apiKey = 'f0qbvm3c0qb2qdjxwku59wimwh495271';
  const orderNo = '6ee49212c05e4ccfD76192886';
  const amount = 10000; // 100 元 = 10000 分

  // 計算 ChkValue
  final chkValue = calculateChkValue(
    customerId: merchantId,
    orderNo: orderNo,
    amount: amount,
    sendType: '0',
    apiKey: apiKey,
  );

  // 構建參數
  return {
    'Send_Type': '0',
    'Pay_Mode_No': '2',
    'CustomerId': merchantId,
    'Order_No': orderNo,
    'Amount': amount.toString(),
    'TransMode': '1',
    'Buyer_Name': '測試用戶',
    'Buyer_Telm': '0912345678',
    'Buyer_Mail': 'test@example.com',
    'Buyer_Memo': '訂金支付',
    'Return_url': 'ridebooking://payment-result',  // ✅ 首字母大寫（根據官方文檔）
    'Callback_Url': 'https://prudish-voncile-bindingly.ngrok-free.dev/api/payment/gomypay-callback',  // ✅ 首字母大寫（根據官方文檔）
    'ChkValue': chkValue,
  };
}

/// 計算 MD5 檢查碼
String calculateChkValue({
  required String customerId,
  required String orderNo,
  required int amount,
  required String sendType,
  required String apiKey,
}) {
  final rawString = '$customerId$orderNo$amount$sendType$apiKey';
  final bytes = utf8.encode(rawString);
  final digest = md5.convert(bytes);
  return digest.toString().toUpperCase();
}

/// 驗證參數
void verifyParameters(Map<String, String> params) {
  print('📋 參數驗證結果：');
  print('');

  var hasErrors = false;

  // 檢查必要參數
  final requiredParams = [
    'Send_Type',
    'Pay_Mode_No',
    'CustomerId',
    'Order_No',
    'Amount',
    'TransMode',
    'Buyer_Name',
    'Buyer_Telm',
    'Buyer_Mail',
    'Return_url',  // ✅ 首字母大寫（根據官方文檔）
    'Callback_Url',  // ✅ 首字母大寫（根據官方文檔）
    'ChkValue',
  ];

  for (final param in requiredParams) {
    if (params.containsKey(param)) {
      print('  ✅ $param: ${params[param]}');
    } else {
      print('  ❌ $param: 缺少此參數');
      hasErrors = true;
    }
  }

  print('');

  // 檢查 Return_url 參數名稱
  if (params.containsKey('Return_url')) {
    print('✅ Return_url 參數名稱正確（首字母大寫，符合 GOMYPAY 官方文檔）');
  } else if (params.containsKey('return_url')) {
    print('❌ Return_url 參數名稱錯誤（應為首字母大寫 Return_url，而非 return_url）');
    hasErrors = true;
  } else {
    print('❌ 缺少 Return_url 參數');
    hasErrors = true;
  }

  print('');

  // 檢查 Return_url 值
  final returnUrl = params['Return_url'] ?? params['return_url'];
  if (returnUrl != null) {
    if (returnUrl.startsWith('ridebooking://')) {
      print('✅ Return_url 值正確（Deep Link 格式）');
      print('   值: $returnUrl');
    } else {
      print('⚠️  Return_url 值可能不正確');
      print('   預期: ridebooking://payment-result');
      print('   實際: $returnUrl');
    }
  }

  print('');

  // 檢查 Callback_Url 值
  final callbackUrl = params['Callback_Url'];
  if (callbackUrl != null) {
    if (callbackUrl.startsWith('http://') || callbackUrl.startsWith('https://')) {
      print('✅ Callback_Url 值正確（HTTP/HTTPS URL）');
      print('   值: $callbackUrl');
    } else {
      print('❌ Callback_Url 值不正確（必須是 HTTP/HTTPS URL）');
      print('   實際: $callbackUrl');
      hasErrors = true;
    }
  }

  print('');

  if (hasErrors) {
    print('❌ 發現錯誤！請修正後重新測試。');
  } else {
    print('✅ 所有參數驗證通過！');
  }

  print('');
}

/// 顯示完整支付 URL
void displayPaymentUrl(Map<String, String> params) {
  print('🔗 完整支付 URL：');
  print('');

  const baseUrl = 'https://n.gomypay.asia/TestShuntClass.aspx';
  final queryString = params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
  final fullUrl = '$baseUrl?$queryString';

  print('  Base URL: $baseUrl');
  print('');
  print('  Query String:');
  print('  $queryString');
  print('');
  print('  Full URL:');
  print('  $fullUrl');
  print('');

  // 檢查 URL 中是否包含 Return_url
  if (fullUrl.contains('Return_url=')) {
    print('✅ URL 包含 Return_url 參數（首字母大寫，符合官方文檔）');
  } else if (fullUrl.contains('return_url=')) {
    print('❌ URL 包含錯誤的 return_url 參數（應為首字母大寫 Return_url）');
  } else {
    print('❌ URL 缺少 Return_url 參數');
  }

  print('');
}

