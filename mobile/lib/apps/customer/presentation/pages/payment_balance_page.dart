import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/booking_service.dart';

/// 支付尾款頁面
/// 
/// 功能：
/// 1. 顯示訂單資訊和尾款金額
/// 2. 選擇支付方式
/// 3. 處理支付流程
/// 4. 支付成功後導航到訂單完成頁面
class PaymentBalancePage extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentBalancePage({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<PaymentBalancePage> createState() => _PaymentBalancePageState();
}

class _PaymentBalancePageState extends ConsumerState<PaymentBalancePage> {
  final BookingService _bookingService = BookingService();
  
  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessing = false;
  bool _isLoading = true;
  
  // 訂單資訊
  double _totalAmount = 0.0;
  double _depositAmount = 0.0;
  double _balanceAmount = 0.0;
  String _bookingNumber = '';

  @override
  void initState() {
    super.initState();
    _loadBookingInfo();
  }

  /// 載入訂單資訊
  Future<void> _loadBookingInfo() async {
    try {
      setState(() => _isLoading = true);
      
      final booking = await _bookingService.getBooking(widget.bookingId);
      
      if (booking != null) {
        setState(() {
          _totalAmount = booking.estimatedFare;
          _depositAmount = booking.depositAmount;
          _balanceAmount = _totalAmount - _depositAmount;
          _bookingNumber = booking.id;  // 使用 id 而不是 bookingNumber
          _isLoading = false;
        });
      } else {
        throw Exception('訂單不存在');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('載入訂單資訊失敗：$e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('支付尾款'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 訂單資訊卡片
            _buildOrderInfoCard(),
            const SizedBox(height: 24),

            // 費用明細卡片
            _buildPriceBreakdownCard(),
            const SizedBox(height: 24),

            // 支付方式選擇
            _buildPaymentMethodSection(),
            const SizedBox(height: 32),

            // 支付按鈕
            _buildPaymentButton(),
            const SizedBox(height: 16),

            // 提示文字
            _buildNoticeText(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '訂單資訊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '訂單編號',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  _bookingNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdownCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '費用明細',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPriceRow('總費用', _totalAmount, Colors.black),
            const SizedBox(height: 8),
            _buildPriceRow('已付訂金', _depositAmount, const Color(0xFF4CAF50)),
            const Divider(height: 24),
            _buildPriceRow(
              '應付尾款',
              _balanceAmount,
              const Color(0xFFFF9800),
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, Color color, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 18 : 16,
            fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          'NT\$ ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isLarge ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '選擇支付方式',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildPaymentMethodOption(
          'credit_card',
          '信用卡',
          Icons.credit_card,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodOption(
          'cash',
          '現金',
          Icons.money,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
              size: 32,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF2196F3) : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2196F3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
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
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                '支付 NT\$ ${_balanceAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildNoticeText() {
    return const Text(
      '⚠️ 這是模擬支付，不會產生實際費用。\n正式版將串接藍新或綠界支付。',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
      textAlign: TextAlign.center,
    );
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // 調用支付尾款 API
      await _bookingService.payBalance(
        widget.bookingId,
        _selectedPaymentMethod,
      );

      // 支付成功，導航到訂單完成頁面
      if (mounted) {
        context.pushReplacement('/booking-complete/${widget.bookingId}');
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
        title: const Text('錯誤'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}

