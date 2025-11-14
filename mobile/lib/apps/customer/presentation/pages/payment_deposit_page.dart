import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/booking_provider.dart';
import '../../../../core/services/payment/payment_models.dart';

class PaymentDepositPage extends ConsumerStatefulWidget {
  const PaymentDepositPage({super.key});

  @override
  ConsumerState<PaymentDepositPage> createState() => _PaymentDepositPageState();
}

class _PaymentDepositPageState extends ConsumerState<PaymentDepositPage> {
  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final bookingRequest = ref.watch(bookingRequestProvider);
    final bookingState = ref.watch(bookingStateProvider);

    if (!bookingRequest.isValid) {
      // 如果預約資訊無效，返回預約頁面
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/booking');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 計算費用
    final estimatedFare = _calculateEstimatedFare(bookingRequest);
    final depositAmount = estimatedFare * 0.25;

    return Scaffold(
      appBar: AppBar(
        title: const Text('支付訂金'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 訂單摘要
            _buildOrderSummary(bookingRequest, estimatedFare, depositAmount),
            const SizedBox(height: 24),

            // 支付方式選擇
            _buildPaymentMethodSection(),
            const SizedBox(height: 24),

            // 重要提醒
            _buildImportantNotice(),
            const SizedBox(height: 32),

            // 支付按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('處理中...'),
                        ],
                      )
                    : Text(
                        '確認支付 NT\$ ${depositAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // 取消按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '取消預約',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(bookingRequest, double estimatedFare, double depositAmount) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '訂單摘要',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSummaryRow('上車地點', bookingRequest.pickupAddress ?? ''),
            const SizedBox(height: 8),
            _buildSummaryRow('下車地點', bookingRequest.dropoffAddress ?? ''),
            const SizedBox(height: 8),
            _buildSummaryRow(
              '預約時間',
              bookingRequest.bookingTime != null
                  ? '${bookingRequest.bookingTime!.year}/${bookingRequest.bookingTime!.month}/${bookingRequest.bookingTime!.day} ${bookingRequest.bookingTime!.hour.toString().padLeft(2, '0')}:${bookingRequest.bookingTime!.minute.toString().padLeft(2, '0')}'
                  : '',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('乘客人數', '${bookingRequest.passengerCount} 人'),
            if (bookingRequest.luggageCount != null && bookingRequest.luggageCount! > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('行李數量', '${bookingRequest.luggageCount} 件'),
            ],
            if (bookingRequest.notes != null && bookingRequest.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('備註', bookingRequest.notes!),
            ],
            
            const Divider(height: 24),
            
            _buildSummaryRow(
              '預估總費用',
              'NT\$ ${estimatedFare.toStringAsFixed(0)}',
              isHighlight: false,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              '需付訂金（25%）',
              'NT\$ ${depositAmount.toStringAsFixed(0)}',
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label：',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? const Color(0xFF2196F3) : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '支付方式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),
            
            // 信用卡選項（封測階段僅 UI 展示）
            RadioListTile<String>(
              value: 'credit_card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              title: const Row(
                children: [
                  Icon(Icons.credit_card, color: Color(0xFF2196F3)),
                  SizedBox(width: 12),
                  Text('信用卡'),
                ],
              ),
              subtitle: const Text('封測階段 - 模擬支付'),
              activeColor: const Color(0xFF2196F3),
            ),
            
            // 其他支付方式（暫時禁用）
            RadioListTile<String>(
              value: 'line_pay',
              groupValue: _selectedPaymentMethod,
              onChanged: null, // 暫時禁用
              title: const Row(
                children: [
                  Icon(Icons.payment, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('LINE Pay', style: TextStyle(color: Colors.grey)),
                ],
              ),
              subtitle: const Text('即將推出'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNotice() {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  '重要提醒',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• 此為封測階段，使用模擬支付，不會產生實際費用\n'
              '• 支付訂金後將進入配對流程，請耐心等待\n'
              '• 配對成功後會通知您司機資訊\n'
              '• 如需取消訂單，請在配對前進行',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateEstimatedFare(bookingRequest) {
    // 優先使用從套餐選擇頁面傳來的價格
    if (bookingRequest.estimatedFare != null && bookingRequest.estimatedFare! > 0) {
      return bookingRequest.estimatedFare!;
    }

    // 降級：使用簡化的費用計算邏輯
    double fare = 150.0; // 基本費用
    fare += bookingRequest.passengerCount > 2 ? (bookingRequest.passengerCount - 2) * 20.0 : 0.0;
    if (bookingRequest.luggageCount != null) {
      fare += bookingRequest.luggageCount! * 10.0;
    }
    return fare;
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // 創建預約訂單（使用 Supabase API）
      final bookingRequest = ref.read(bookingRequestProvider);
      await ref.read(bookingStateProvider.notifier).createBookingWithSupabase(
        bookingRequest.toBookingRequest(),
      );

      final bookingState = ref.read(bookingStateProvider);
      if (bookingState is BookingStateSuccess) {
        // 使用 Supabase API 處理支付
        final paymentResult = await ref.read(bookingStateProvider.notifier).payDepositWithSupabase(
          bookingState.order.id,
          _selectedPaymentMethod,
        );

        if (!mounted) return;

        // ✅ 檢查是否需要跳轉到支付頁面（GoMyPay 等第三方支付）
        if (paymentResult['requiresRedirect'] == true && paymentResult['paymentUrl'] != null) {
          // 跳轉到 GoMyPay 支付頁面
          debugPrint('[PaymentDeposit] 跳轉到支付頁面: ${paymentResult['paymentUrl']}');
          await context.push('/payment-webview', extra: {
            'url': paymentResult['paymentUrl'],
            'bookingId': bookingState.order.id,
            'paymentType': PaymentType.deposit,
          });

          // 支付完成後，跳轉到預約成功頁面
          if (mounted) {
            context.pushReplacement('/booking-success/${bookingState.order.id}');
          }
        } else {
          // 自動支付（Mock）或不需要跳轉，直接導航到預約成功頁面
          debugPrint('[PaymentDeposit] 自動支付完成，跳轉到預約成功頁面');
          context.pushReplacement('/booking-success/${bookingState.order.id}');
        }
      } else if (bookingState is BookingStateError) {
        _showErrorDialog(bookingState.message);
      }
    } catch (e) {
      _showErrorDialog('支付處理失敗：$e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支付失敗'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }
}
