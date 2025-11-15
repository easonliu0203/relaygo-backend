import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/payment/payment_models.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/models/booking_order.dart';

/// GOMYPAY 支付 WebView 頁面
/// 
/// 功能：
/// 1. 顯示 GOMYPAY 支付頁面
/// 2. 監聽支付結果
/// 3. 處理支付完成後的跳轉
/// 4. 處理用戶取消支付
class PaymentWebViewPage extends StatefulWidget {
  /// 支付 URL
  final String paymentUrl;

  /// 訂單 ID
  final String bookingId;

  /// 支付類型
  final PaymentType paymentType;

  const PaymentWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.bookingId,
    required this.paymentType,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  final _bookingService = BookingService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isVerifyingPayment = false; // 是否正在驗證支付狀態

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// 初始化 WebView
  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            _handleUrlChange(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // 忽略某些非關鍵錯誤
            if (error.errorType == WebResourceErrorType.unsupportedScheme) {
              // Deep link 跳轉會觸發這個錯誤，可以忽略
              print('⚠️ WebView 錯誤（已忽略）: ${error.description}');
              return;
            }

            print('❌ WebView 錯誤: ${error.description} (${error.errorCode})');
            setState(() {
              _isLoading = false;
              // 只有嚴重錯誤才顯示錯誤訊息
              if (error.errorType == WebResourceErrorType.hostLookup ||
                  error.errorType == WebResourceErrorType.timeout ||
                  error.errorType == WebResourceErrorType.connect) {
                _errorMessage = '載入失敗：${error.description}';
              }
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔗 導航請求: ${request.url}');

            // 檢查是否為返回 URL（Deep Link）
            if (request.url.startsWith('ridebooking://payment-result')) {
              _handlePaymentResult(request.url);
              return NavigationDecision.prevent;
            }

            // 允許所有 HTTPS 和 HTTP 請求
            return NavigationDecision.navigate;
          },
        ),
      );

    // 載入支付 URL
    _controller.loadRequest(
      Uri.parse(widget.paymentUrl),
      headers: {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-TW,zh;q=0.9,en;q=0.8',
      },
    );
  }

  /// 處理 URL 變化
  void _handleUrlChange(String url) {
    print('📱 WebView URL 變化: $url');

    // 檢查是否為返回 URL
    if (url.startsWith('ridebooking://payment-result')) {
      _handlePaymentResult(url);
    }
  }

  /// 處理支付結果
  void _handlePaymentResult(String url) {
    print('💳 收到支付結果: $url');

    try {
      // 解析 URL 參數
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      // 支持兩種參數格式：
      // 1. 後端 Return URL 格式（新）：
      //    - status: success/failed/pending
      //    - orderNo: 我們的訂單編號
      // 2. GOMYPAY 直接回調格式（舊）：
      //    - result: 1=成功, 0=失敗
      //    - ret_msg: 返回訊息（URL 編碼）
      //    - OrderID: GOMYPAY 生成的訂單號
      //    - e_orderno: 我們的訂單編號
      //    - AvCode: 授權碼
      //    - str_check: 檢查碼

      // 檢查是否為新格式（後端 Return URL）
      final status = params['status'];
      final orderNo = params['orderNo'];

      // 檢查是否為舊格式（GOMYPAY 直接回調）
      final result = params['result'];
      final retMsg = params['ret_msg'];
      final gomypayOrderId = params['OrderID'];
      final ourOrderNo = params['e_orderno'];
      final avCode = params['AvCode'];

      print('  [新格式] status: $status');
      print('  [新格式] orderNo: $orderNo');
      print('  [舊格式] result: $result');
      print('  [舊格式] ret_msg: $retMsg');
      print('  [舊格式] GOMYPAY OrderID: $gomypayOrderId');
      print('  [舊格式] Our Order No: $ourOrderNo');
      print('  [舊格式] AvCode: $avCode');

      // 判斷支付狀態
      bool isSuccess = false;

      if (status != null) {
        // 新格式：使用 status 參數
        isSuccess = status == 'success';
        print('  使用新格式判斷: status=$status, isSuccess=$isSuccess');
      } else if (result != null) {
        // 舊格式：使用 result 參數
        isSuccess = result == '1';
        print('  使用舊格式判斷: result=$result, isSuccess=$isSuccess');
      } else {
        // 無法判斷，預設為失敗
        print('  ⚠️ 無法判斷支付狀態，預設為失敗');
        isSuccess = false;
      }

      // 根據支付狀態處理
      if (isSuccess) {
        // 支付成功
        _handlePaymentSuccess(params);
      } else {
        // 支付失敗
        _handlePaymentFailure(params);
      }
    } catch (e) {
      print('❌ 解析支付結果失敗: $e');
      _handlePaymentError('解析支付結果失敗');
    }
  }

  /// 處理支付成功
  void _handlePaymentSuccess(Map<String, String> params) async {
    print('✅ 支付成功');

    if (!mounted) return;

    // ⚠️ 暫時停用輪詢機制，恢復直接導航方式
    // 目的：測試 GOMYPAY 回調是否能正常觸發
    // 如需恢復輪詢機制，請取消下面的註釋並註釋掉直接導航代碼

    // 根據支付類型處理
    if (widget.paymentType == PaymentType.deposit) {
      // 訂金支付成功 -> 直接導航到預約成功頁面
      context.pushReplacement('/booking-success/${widget.bookingId}');

      // ⚠️ 輪詢機制已暫時停用
      // await _verifyDepositPaymentAndNavigate();
    } else {
      // 尾款支付成功 -> 直接導航到完成頁面
      context.pushReplacement('/booking-complete/${widget.bookingId}');

      // ⚠️ 輪詢機制已暫時停用
      // await _verifyBalancePaymentAndNavigate();
    }
  }

  // ⚠️ ========== 以下方法暫時停用 ==========
  // 目的：測試 GOMYPAY 回調是否能正常觸發
  // 如需恢復輪詢機制，請取消 _handlePaymentSuccess() 中的註釋
  // ============================================

  /// 驗證訂金支付狀態並導航
  ///
  /// 輪詢訂單狀態，確認訂單已更新為 'paid_deposit' 後才導航到成功頁面
  ///
  /// ⚠️ 此方法暫時停用
  Future<void> _verifyDepositPaymentAndNavigate() async {
    if (!mounted) return;

    // 顯示載入狀態
    setState(() {
      _isVerifyingPayment = true;
    });

    try {
      // 輪詢訂單狀態（最多 20 秒）
      final booking = await _waitForDepositPayment();

      if (!mounted) return;

      if (booking != null && booking.depositPaid) {
        // 訂單狀態已確認為 'paid_deposit'，導航到成功頁面
        debugPrint('✅ 訂金支付狀態已確認，導航到預約成功頁面');
        context.pushReplacement('/booking-success/${widget.bookingId}');
      } else {
        // 超時或訂單狀態未更新
        debugPrint('⚠️  訂金支付狀態未在 20 秒內更新');
        _showDepositTimeoutDialog();
      }
    } catch (e) {
      debugPrint('❌ 驗證訂金支付狀態失敗: $e');
      if (mounted) {
        _showErrorDialog('驗證支付狀態失敗，請稍後在訂單列表中查看', canRetry: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPayment = false;
        });
      }
    }
  }

  /// 等待訂金支付完成
  ///
  /// 輪詢訂單狀態，直到 depositPaid 為 true 或超時（20 秒）
  Future<BookingOrder?> _waitForDepositPayment() async {
    const maxAttempts = 20; // 最多 20 次
    const delayBetweenAttempts = Duration(seconds: 1); // 每次間隔 1 秒

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      debugPrint('🔄 輪詢訂金支付狀態 (嘗試 $attempt/$maxAttempts)');

      try {
        // 從 Supabase 直接獲取最新訂單狀態
        final booking = await _bookingService.getBooking(widget.bookingId);

        if (booking != null) {
          debugPrint('   訂單狀態: ${booking.status.name}');
          debugPrint('   訂金已付: ${booking.depositPaid}');

          // 檢查訂金是否已支付
          if (booking.depositPaid) {
            debugPrint('✅ 訂金支付狀態已更新！');
            return booking;
          }
        }

        // 如果還沒更新，等待後再試
        if (attempt < maxAttempts) {
          await Future.delayed(delayBetweenAttempts);
        }
      } catch (e) {
        debugPrint('❌ 獲取訂單狀態失敗: $e');
        // 繼續嘗試
        if (attempt < maxAttempts) {
          await Future.delayed(delayBetweenAttempts);
        }
      }
    }

    debugPrint('⏱️  輪詢超時：訂金支付狀態未在 20 秒內更新');
    return null;
  }

  /// 顯示訂金支付超時對話框
  void _showDepositTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('支付處理中'),
        content: const Text(
          '您的支付已成功，但訂單狀態更新需要一些時間。\n\n'
          '您可以：\n'
          '1. 前往「我的訂單」查看訂單狀態\n'
          '2. 稍後系統會自動更新訂單狀態',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 導航到訂單列表
              context.go('/orders');
            },
            child: const Text('查看我的訂單'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 導航到預約成功頁面（即使狀態未更新）
              context.pushReplacement('/booking-success/${widget.bookingId}');
            },
            child: const Text('前往訂單詳情'),
          ),
        ],
      ),
    );
  }

  /// 驗證尾款支付狀態並導航
  ///
  /// 輪詢訂單狀態，確認訂單已更新為 'completed' 後才導航到完成頁面
  ///
  /// ⚠️ 此方法暫時停用
  Future<void> _verifyBalancePaymentAndNavigate() async {
    if (!mounted) return;

    // 顯示載入狀態
    setState(() {
      _isVerifyingPayment = true;
    });

    try {
      // 輪詢訂單狀態
      final booking = await _waitForBookingCompletion();

      if (!mounted) return;

      if (booking != null && booking.status == BookingStatus.completed) {
        // 訂單狀態已確認為 'completed'，導航到完成頁面
        debugPrint('✅ 訂單狀態已確認為 completed，導航到完成頁面');
        context.pushReplacement('/booking-complete/${widget.bookingId}');
      } else {
        // 超時或訂單狀態未更新
        debugPrint('⚠️  訂單狀態未在 10 秒內更新為 completed');
        _showTimeoutDialog();
      }
    } catch (e) {
      debugPrint('❌ 驗證支付狀態失敗: $e');
      if (mounted) {
        _showErrorDialog('驗證支付狀態失敗，請稍後在訂單列表中查看', canRetry: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPayment = false;
        });
      }
    }
  }

  /// 等待訂單狀態更新為 'completed'
  ///
  /// 輪詢檢查訂單狀態，最多等待 10 秒
  /// 如果 10 秒後訂單狀態還不是 'completed'，則返回當前訂單
  Future<BookingOrder?> _waitForBookingCompletion() async {
    const maxAttempts = 20; // 最多嘗試 20 次
    const delayBetweenAttempts = Duration(milliseconds: 500); // 每次間隔 500ms

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      debugPrint('🔄 檢查訂單狀態 (嘗試 ${attempt + 1}/$maxAttempts)');

      try {
        // 直接從 Supabase 讀取訂單狀態
        final booking = await _bookingService.getBooking(widget.bookingId);

        if (booking == null) {
          debugPrint('❌ 訂單不存在');
          return null;
        }

        debugPrint('📊 當前訂單狀態: ${booking.status}');

        // 檢查訂單狀態是否為 'completed'
        if (booking.status == BookingStatus.completed) {
          debugPrint('✅ 訂單狀態已更新為 completed');
          return booking;
        }

        // 如果還不是 'completed'，等待一下再重試
        if (attempt < maxAttempts - 1) {
          await Future.delayed(delayBetweenAttempts);
        }
      } catch (e) {
        debugPrint('❌ 查詢訂單狀態失敗: $e');
        // 繼續重試
        if (attempt < maxAttempts - 1) {
          await Future.delayed(delayBetweenAttempts);
        }
      }
    }

    // 如果 10 秒後還沒有更新，返回最後一次獲取的訂單
    debugPrint('⚠️  訂單狀態未在 10 秒內更新為 completed');
    try {
      return await _bookingService.getBooking(widget.bookingId);
    } catch (e) {
      debugPrint('❌ 最後一次查詢訂單失敗: $e');
      return null;
    }
  }

  /// 顯示超時對話框
  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('訂單狀態確認中'),
        content: const Text('支付已成功，但訂單狀態正在確認中。\n\n您可以稍後在訂單列表中查看訂單狀態。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 返回到訂單列表
              context.go('/order-list');
            },
            child: const Text('查看訂單列表'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 返回首頁
              context.go('/');
            },
            child: const Text('返回首頁'),
          ),
        ],
      ),
    );
  }

  /// 處理支付失敗
  void _handlePaymentFailure(Map<String, String> params) {
    final message = params['Message'] ?? params['errmsg'] ?? '支付失敗';
    print('❌ 支付失敗: $message');

    if (!mounted) return;

    _showErrorDialog(message, canRetry: true);
  }

  /// 處理支付錯誤
  void _handlePaymentError(String message) {
    print('❌ 支付錯誤: $message');

    if (!mounted) return;

    _showErrorDialog(message, canRetry: true);
  }

  /// 顯示錯誤對話框
  void _showErrorDialog(String message, {bool canRetry = false}) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          if (canRetry)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 重新載入支付頁面
                _controller.loadRequest(Uri.parse(widget.paymentUrl));
              },
              child: const Text('重試'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 返回上一頁
              context.pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  /// 處理返回按鈕
  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context)!;

    // 詢問用戶是否確定取消支付
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消支付'),
        content: const Text('確定要取消支付嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('繼續支付'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.paymentType == PaymentType.deposit
                ? '支付訂金'
                : '支付尾款',
          ),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                context.pop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            // WebView
            if (_errorMessage == null)
              WebViewWidget(controller: _controller)
            else
              // 錯誤訊息
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                          _controller.loadRequest(Uri.parse(widget.paymentUrl));
                        },
                        child: const Text('重試'),
                      ),
                    ],
                  ),
                ),
              ),

            // 載入指示器（WebView 載入中）
            if (_isLoading && !_isVerifyingPayment)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // 驗證支付狀態載入覆蓋層
            if (_isVerifyingPayment)
              Container(
                color: Colors.white.withOpacity(0.95),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 載入指示器
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 提示文字
                        const Text(
                          '正在確認訂單狀態，請稍候...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // 說明文字
                        const Text(
                          '支付已成功，正在等待系統更新訂單狀態',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

