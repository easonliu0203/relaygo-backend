import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/booking_order.dart';
import '../../../../shared/providers/booking_provider.dart';

class BookingSuccessPage extends ConsumerWidget {
  final String orderId;

  const BookingSuccessPage({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(bookingProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('預約成功'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // 隱藏返回按鈕
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(
              child: Text('訂單不存在'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 成功圖示
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // 成功訊息
                const Text(
                  '預約成功！',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '您的預約已成功建立，正在為您配對司機',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 訂單資訊卡片
                _buildOrderInfoCard(order),
                const SizedBox(height: 24),

                // 狀態卡片
                _buildStatusCard(order),
                const SizedBox(height: 32),

                // 操作按鈕
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => context.push('/order-detail/$orderId'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '查看訂單詳情',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          // 清除預約請求狀態
                          ref.read(bookingRequestProvider.notifier).reset();
                          // 返回首頁
                          context.go('/home');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2196F3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '返回首頁',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
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
                '載入訂單失敗',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('返回首頁'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(BookingOrder order) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF2196F3),
                ),
                const SizedBox(width: 8),
                const Text(
                  '訂單資訊',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('訂單編號', order.id),
            const SizedBox(height: 8),
            _buildInfoRow('上車地點', order.pickupAddress),
            const SizedBox(height: 8),
            _buildInfoRow('下車地點', order.dropoffAddress),
            const SizedBox(height: 8),
            _buildInfoRow(
              '預約時間',
              '${order.bookingTime.year}/${order.bookingTime.month}/${order.bookingTime.day} ${order.bookingTime.hour.toString().padLeft(2, '0')}:${order.bookingTime.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow('乘客人數', '${order.passengerCount} 人'),
            if (order.luggageCount != null && order.luggageCount! > 0) ...[
              const SizedBox(height: 8),
              _buildInfoRow('行李數量', '${order.luggageCount} 件'),
            ],
            
            const Divider(height: 24),
            
            _buildInfoRow(
              '預估費用',
              'NT\$ ${order.estimatedFare.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              '已付訂金',
              'NT\$ ${order.depositAmount.toStringAsFixed(0)}',
              valueColor: const Color(0xFF4CAF50),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BookingOrder order) {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  color: order.status.color,
                ),
                const SizedBox(width: 8),
                Text(
                  '當前狀態：${order.status.displayName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: order.status.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '我們正在為您尋找合適的司機，請耐心等待。\n配對成功後會立即通知您司機資訊。',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // 進度指示器
            LinearProgressIndicator(
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(order.status.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
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
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
