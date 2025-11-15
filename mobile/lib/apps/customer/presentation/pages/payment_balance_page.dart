import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/services/payment/payment_models.dart';

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
  final TextEditingController _customTipController = TextEditingController();

  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessing = false;
  bool _isLoading = true;

  // 訂單資訊
  double _totalAmount = 0.0;
  double _depositAmount = 0.0;
  double _balanceAmount = 0.0;
  String _bookingNumber = '';

  // 小費相關
  double _tipAmount = 0.0;
  String _selectedTipOption = 'none'; // 'none', '300', '500', '1000', 'custom'

  @override
  void initState() {
    super.initState();
    _loadBookingInfo();
  }

  @override
  void dispose() {
    _customTipController.dispose();
    super.dispose();
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

            // 小費選擇
            _buildTipSection(),
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
    final totalPayable = _balanceAmount + _tipAmount;

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
            if (_tipAmount > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow('小費', _tipAmount, const Color(0xFFFFB74D)),
            ],
            const Divider(height: 24),
            _buildPriceRow(
              '應付尾款',
              totalPayable,
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
      final paymentResult = await _bookingService.payBalance(
        widget.bookingId,
        _selectedPaymentMethod,
        tipAmount: _tipAmount,
      );

      if (!mounted) return;

      // ✅ 檢查是否需要跳轉到支付頁面（GoMyPay 等第三方支付）
      if (paymentResult['requiresRedirect'] == true && paymentResult['paymentUrl'] != null) {
        // 跳轉到 GoMyPay 支付頁面
        debugPrint('[PaymentBalance] 跳轉到支付頁面: ${paymentResult['paymentUrl']}');
        await context.push('/payment-webview', extra: {
          'url': paymentResult['paymentUrl'],
          'bookingId': widget.bookingId,
          'paymentType': PaymentType.balance,
        });

        // 支付完成後，跳轉到訂單完成頁面
        if (mounted) {
          context.pushReplacement('/booking-complete/${widget.bookingId}');
        }
      } else {
        // 自動支付（Mock）或不需要跳轉，直接導航到訂單完成頁面
        debugPrint('[PaymentBalance] 自動支付完成，跳轉到訂單完成頁面');
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

  Widget _buildTipSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.volunteer_activism, color: Color(0xFFFFB74D)),
                SizedBox(width: 8),
                Text(
                  '支付小費 (選填)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 快速選擇按鈕
            Row(
              children: [
                Expanded(
                  child: _buildTipButton('300', 300),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTipButton('500', 500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTipButton('1000', 1000),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTipButton('自填', 0, isCustom: true),
                ),
              ],
            ),

            // 自訂金額輸入框
            if (_selectedTipOption == 'custom') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customTipController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '自訂小費金額',
                  prefixText: 'NT\$ ',
                  border: OutlineInputBorder(),
                  hintText: '請輸入金額',
                ),
                onChanged: (value) {
                  setState(() {
                    _tipAmount = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
            ],

            // 清除小費按鈕
            if (_tipAmount > 0) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _tipAmount = 0.0;
                      _selectedTipOption = 'none';
                      _customTipController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('清除小費'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipButton(String label, double amount, {bool isCustom = false}) {
    final isSelected = isCustom
        ? _selectedTipOption == 'custom'
        : _selectedTipOption == amount.toString();

    return OutlinedButton(
      onPressed: () {
        setState(() {
          if (isCustom) {
            _selectedTipOption = 'custom';
            _tipAmount = 0.0;
            _customTipController.clear();
          } else {
            _selectedTipOption = amount.toString();
            _tipAmount = amount;
            _customTipController.clear();
          }
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFFFB74D).withOpacity(0.1) : null,
        side: BorderSide(
          color: isSelected ? const Color(0xFFFFB74D) : Colors.grey,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        isCustom ? label : 'NT\$ $label',
        style: TextStyle(
          color: isSelected ? const Color(0xFFFFB74D) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

