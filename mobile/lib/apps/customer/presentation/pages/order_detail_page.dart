import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/booking_order.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../shared/providers/booking_provider.dart';

class OrderDetailPage extends ConsumerWidget {
  final String orderId;

  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(bookingProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單詳情'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 訂單狀態卡片
                _buildStatusCard(order),
                const SizedBox(height: 16),

                // 訂單基本資訊
                _buildOrderInfoCard(order),
                const SizedBox(height: 16),

                // 司機資訊（如果已配對）
                if (order.status == BookingStatus.matched ||
                    order.status == BookingStatus.inProgress ||
                    order.status == BookingStatus.awaitingBalance ||
                    order.status == BookingStatus.completed)
                  _buildDriverInfoCard(context, order),

                // 費用資訊
                _buildPaymentInfoCard(order),
                const SizedBox(height: 24),

                // 操作按鈕
                _buildActionButtons(context, ref, order),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BookingOrder order) {
    return Card(
      elevation: 2,
      color: order.status.color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: order.status.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(order.status),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: order.status.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(order.status),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            const Text(
              '訂單資訊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('訂單編號', order.id),
            const SizedBox(height: 12),
            _buildInfoRow('上車地點', order.pickupAddress),
            const SizedBox(height: 12),
            _buildInfoRow('下車地點', order.dropoffAddress),
            const SizedBox(height: 12),
            _buildInfoRow(
              '預約時間',
              '${order.bookingTime.year}/${order.bookingTime.month}/${order.bookingTime.day} ${order.bookingTime.hour.toString().padLeft(2, '0')}:${order.bookingTime.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow('乘客人數', '${order.passengerCount} 人'),
            if (order.luggageCount != null && order.luggageCount! > 0) ...[
              const SizedBox(height: 12),
              _buildInfoRow('行李數量', '${order.luggageCount} 件'),
            ],
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow('備註', order.notes!),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              '建立時間',
              '${order.createdAt.year}/${order.createdAt.month}/${order.createdAt.day} ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard(BuildContext context, BookingOrder order) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '司機資訊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF4CAF50),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.driverName ?? '司機資訊載入中...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (order.driverRating != null) ...[
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 4),
                            Text(order.driverRating!.toStringAsFixed(1)),
                            const SizedBox(width: 8),
                          ],
                          if (order.driverVehiclePlate != null)
                            Text(
                              '車牌：${order.driverVehiclePlate}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                      if (order.driverVehicleModel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '車型：${order.driverVehicleModel}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: 實作聊天功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('聊天功能開發中')),
                    );
                  },
                  icon: const Icon(
                    Icons.chat,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(BookingOrder order) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '費用資訊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              '預估總費用',
              'NT\$ ${order.estimatedFare.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              '已付訂金',
              'NT\$ ${order.depositAmount.toStringAsFixed(0)}',
              valueColor: order.depositPaid ? const Color(0xFF4CAF50) : Colors.red,
            ),
            const SizedBox(height: 8),

            // 根據訂單狀態顯示不同的費用資訊
            if (order.balancePaid) ...[
              // 訂單已完成，顯示已付尾款和已付總額
              _buildInfoRow(
                '已付尾款',
                'NT\$ ${order.balanceAmount.toStringAsFixed(0)}',
                valueColor: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                '已付總額',
                'NT\$ ${order.totalPaid.toStringAsFixed(0)}',
                valueColor: const Color(0xFF4CAF50),
                isBold: true,
              ),
            ] else ...[
              // 訂單未完成，顯示剩餘費用
              _buildInfoRow(
                '剩餘費用',
                'NT\$ ${order.balanceAmount.toStringAsFixed(0)}',
                valueColor: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, BookingOrder order) {
    return Column(
      children: [
        // 取消訂單按鈕（僅在待配對或待司機確認狀態可用）
        if (order.status == BookingStatus.pending ||
            order.status == BookingStatus.awaitingDriver) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(context, ref, order),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '取消訂單',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 開始行程按鈕（司機已確認或已到達時顯示）
        // 邏輯說明：
        // 1. 司機確認接單後，Firestore 狀態為 'matched'
        // 2. 司機到達後，Firestore 狀態為 'inProgress'
        // 3. 客戶點擊「開始行程」後，Supabase 狀態變為 'trip_started'
        if (order.status == BookingStatus.matched ||
            order.status == BookingStatus.inProgress ||
            order.status == BookingStatus.awaitingBalance) ...[
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // 顯示確認對話框
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('確認開始行程'),
                        content: const Text(
                          '確定要開始行程嗎？\n\n⚠️ 請確認您已與司機見面，避免金額計算錯誤。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('確認開始'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    // 顯示載入對話框
                    if (!context.mounted) return;

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      useRootNavigator: true,
                      builder: (dialogContext) => const PopScope(
                        canPop: false,
                        child: Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('正在開始行程...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    try {
                      // 調用 API 開始行程
                      final bookingService = BookingService();
                      await bookingService.startTrip(order.id);

                      // 關閉載入對話框
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      // 顯示成功訊息
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ 行程已開始！'),
                            backgroundColor: Color(0xFF4CAF50),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }

                      // 刷新訂單資料
                      ref.invalidate(bookingProvider(order.id));
                    } catch (e) {
                      // 關閉載入對話框
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      // 顯示錯誤訊息
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ 開始行程失敗: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '開始行程 🚀',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '⚠️ 請務必在與司機見面時按下，避免金額計算錯誤',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 結束行程按鈕（行程進行中時顯示）
        // 注意：由於 Flutter 的 BookingStatus 枚舉較簡化，
        // inProgress 狀態包含了 driver_departed, driver_arrived, trip_started 等多個 Supabase 狀態
        // 這裡暫時在 inProgress 狀態下顯示「結束行程」按鈕
        // TODO: 需要根據訂單的實際 Supabase 狀態來判斷是否顯示此按鈕
        if (order.status == BookingStatus.inProgress) ...[
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // 顯示確認對話框
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('確認結束行程'),
                        content: const Text(
                          '確定要結束行程嗎？\n\n⚠️ 結束後將需要支付尾款，請確認行程已完成。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('確認結束'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    // 顯示載入對話框
                    if (!context.mounted) return;

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      useRootNavigator: true,
                      builder: (dialogContext) => const PopScope(
                        canPop: false,
                        child: Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('正在結束行程...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    try {
                      // 調用 API 結束行程
                      final bookingService = BookingService();
                      await bookingService.endTrip(order.id);

                      // 關閉載入對話框
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      // 顯示成功訊息
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ 行程已結束！請支付尾款'),
                            backgroundColor: Color(0xFFFF9800),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }

                      // 刷新訂單資料
                      ref.invalidate(bookingProvider(order.id));

                      // 自動導航到支付尾款頁面
                      if (context.mounted) {
                        context.push('/payment-balance/${order.id}');
                      }
                    } catch (e) {
                      // 關閉載入對話框
                      if (context.mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      // 顯示錯誤訊息
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ 結束行程失敗: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '結束行程 🏁',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '⚠️ 請務必在確定結束行程時按下，避免金額計算錯誤',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 支付尾款按鈕（行程已結束，等待支付尾款時顯示）
        if (order.status == BookingStatus.awaitingBalance) ...[
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // 導航到支付尾款頁面
                    context.push('/payment-balance/${order.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D), // 金色（與 awaitingBalance 狀態顏色一致）
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '立即支付尾款 (NT\$ ${order.balanceAmount.toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '💡 行程已結束，請盡快完成尾款支付',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 聯絡司機按鈕（配對成功後可用）
        if (order.status == BookingStatus.matched ||
            order.status == BookingStatus.inProgress ||
            order.status == BookingStatus.awaitingBalance) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                // TODO: 實作聊天功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('聊天功能開發中')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4CAF50)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '聊天聯絡司機',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 返回按鈕
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              // 檢查是否可以返回上一頁
              // 如果可以（例如：從訂單列表頁面進入），則返回上一頁
              // 如果不可以（例如：從訂單完成頁面使用 context.go() 進入），則導航到訂單列表頁面
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/orders');
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2196F3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '返回',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
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
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingPayment:
        return Icons.payment;
      case BookingStatus.pending:
        return Icons.hourglass_empty;
      case BookingStatus.awaitingDriver:
        return Icons.person_search;
      case BookingStatus.matched:
        return Icons.person_pin;
      case BookingStatus.onTheWay:
        return Icons.local_taxi;
      case BookingStatus.inProgress:
        return Icons.directions_car;
      case BookingStatus.awaitingBalance:
        return Icons.payment;
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingPayment:
        return '請支付訂金以確認訂單';
      case BookingStatus.pending:
        return '正在為您尋找合適的司機';
      case BookingStatus.awaitingDriver:
        return '已為您分配司機，等待司機確認接單';
      case BookingStatus.matched:
        return '已為您配對司機，請準備上車';
      case BookingStatus.onTheWay:
        return '司機正在前往接您';
      case BookingStatus.inProgress:
        return '行程進行中';
      case BookingStatus.awaitingBalance:
        return '行程已結束，請支付尾款';
      case BookingStatus.completed:
        return '行程已完成';
      case BookingStatus.cancelled:
        return '訂單已取消';
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, BookingOrder order) {
    showDialog<String?>(
      context: context,
      builder: (dialogContext) => const _CancelOrderDialog(),
    ).then((reason) async {
      // 等待對話框關閉動畫完成，避免 _dependents.isEmpty 錯誤
      await Future.delayed(const Duration(milliseconds: 300));

      // 檢查 context 是否仍然有效
      if (!context.mounted) return;

      // 如果用戶確認取消（返回了取消原因）
      if (reason != null && reason.isNotEmpty) {
        try {
          await ref.read(bookingStateProvider.notifier).cancelBookingWithSupabase(
            order.id,
            reason,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('訂單已取消')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('取消失敗：$e')),
            );
          }
        }
      }
    });
  }
}

/// 取消訂單對話框 (使用 StatefulWidget 管理 TextEditingController 生命週期)
class _CancelOrderDialog extends StatefulWidget {
  const _CancelOrderDialog();

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    // ✅ 在 StatefulWidget 的 dispose 中釋放 controller
    // 這樣可以確保在正確的時機釋放資源
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('取消訂單'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('確定要取消此訂單嗎？已支付的訂金將會退還。'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: '取消原因',
              hintText: '請輸入取消原因（至少 5 個字元）',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: const Text('不取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _reasonController.text.trim();

            // 驗證取消原因
            if (reason.length < 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('取消原因至少需要 5 個字元')),
              );
              return;
            }

            // 返回取消原因
            Navigator.of(context).pop(reason);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('確認取消'),
        ),
      ],
    );
  }
}
