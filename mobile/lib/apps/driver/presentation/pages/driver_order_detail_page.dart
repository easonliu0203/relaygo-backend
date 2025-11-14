import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/booking_order.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../shared/providers/booking_provider.dart';

class DriverOrderDetailPage extends ConsumerWidget {
  final String orderId;

  const DriverOrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(bookingProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單詳情'),
        backgroundColor: const Color(0xFF4CAF50),
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

                // 客戶資訊
                _buildCustomerInfoCard(context, order),
                const SizedBox(height: 16),

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
                '載入失敗: $error',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(bookingProvider(orderId)),
                child: const Text('重試'),
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
            Icon(
              _getStatusIcon(order.status),
              size: 32,
              color: order.status.color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: order.status.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '訂單編號: ${order.id.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
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

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingPayment:
        return Icons.payment;
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.awaitingDriver:
        return Icons.person_search;
      case BookingStatus.matched:
        return Icons.check_circle;
      case BookingStatus.onTheWay:
        return Icons.local_taxi;
      case BookingStatus.inProgress:
        return Icons.directions_car;
      case BookingStatus.awaitingBalance:
        return Icons.payment;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
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
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(
              Icons.location_on,
              '上車地點',
              order.pickupAddress,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on_outlined,
              '下車地點',
              order.dropoffAddress,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              '預約時間',
              DateFormat('yyyy/MM/dd HH:mm').format(order.bookingTime),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.people,
              '乘客人數',
              '${order.passengerCount} 人',
            ),
            if (order.luggageCount != null && order.luggageCount! > 0) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.luggage,
                '行李數量',
                '${order.luggageCount} 件',
              ),
            ],
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.note,
                '備註',
                order.notes!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context, BookingOrder order) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '客戶資訊',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF2196F3),
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName ?? '客戶資訊載入中...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (order.customerPhone != null)
                        Text(
                          order.customerPhone!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
                  onPressed: () {
                    // TODO: 實作撥打電話功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('撥打電話功能開發中')),
                    );
                  },
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
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),

            _buildPaymentRow(
              '預估總費用',
              'NT\$ ${order.estimatedFare.toStringAsFixed(0)}',
              const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 8),
            _buildPaymentRow(
              '已付訂金',
              'NT\$ ${order.depositAmount.toStringAsFixed(0)}',
              order.depositPaid ? const Color(0xFF4CAF50) : Colors.red,
            ),
            const SizedBox(height: 8),

            // 根據訂單狀態顯示不同的費用資訊
            if (order.balancePaid) ...[
              // 訂單已完成，顯示已付尾款和已付總額
              _buildPaymentRow(
                '已付尾款',
                'NT\$ ${order.balanceAmount.toStringAsFixed(0)}',
                const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 8),
              _buildPaymentRow(
                '已付總額',
                'NT\$ ${order.totalPaid.toStringAsFixed(0)}',
                const Color(0xFF4CAF50),
                isBold: true,
              ),
            ] else ...[
              // 訂單未完成，顯示剩餘費用
              _buildPaymentRow(
                '剩餘費用',
                'NT\$ ${order.balanceAmount.toStringAsFixed(0)}',
                Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            color: isBold ? Colors.black87 : Colors.grey,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, BookingOrder order) {
    return Column(
      children: [
        // 當訂單狀態為 awaitingDriver（待司機確認）時，顯示「確認接單」按鈕
        // 邏輯說明：
        // 1. 公司端手動派單後，Supabase 狀態為 'matched'
        // 2. Edge Function 同步到 Firestore 時，映射為 'awaitingDriver'（等待司機確認）
        // 3. 司機確認接單後，Supabase 狀態變為 'driver_confirmed'
        // 4. Edge Function 再次同步，Firestore 狀態變為 'matched'（已配對）
        if (order.status == BookingStatus.awaitingDriver && order.driverId != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // 顯示確認對話框
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('確認接單'),
                    content: const Text('確定要接受這個訂單嗎？\n接單後將自動創建聊天室，您可以與客戶開始溝通。'),
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
                        child: const Text('確認接單'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                // 顯示載入對話框
                if (!context.mounted) return;

                // 使用 showDialog 並使用 root navigator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  useRootNavigator: true,  // 使用 root navigator
                  builder: (dialogContext) => const PopScope(
                    canPop: false,  // 防止用戶按返回鍵關閉
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('正在確認接單...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );

                try {
                  // 調用 API 確認接單
                  final bookingService = BookingService();
                  await bookingService.driverAcceptBooking(order.id);

                  // 關閉載入對話框（使用 root navigator 確保關閉）
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }

                  // 顯示成功訊息
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 接單成功！聊天室已創建，您可以與客戶開始溝通'),
                        backgroundColor: Color(0xFF4CAF50),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }

                  // 刷新訂單資料
                  ref.invalidate(bookingProvider(order.id));

                  // 可選：導航到聊天室頁面
                  // if (context.mounted) {
                  //   context.push('/driver/chat');
                  // }
                } catch (e) {
                  // 關閉載入對話框（使用 root navigator 確保關閉）
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }

                  // 顯示錯誤訊息
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ 接單失敗: $e'),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '確認接單',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // 當訂單狀態為 matched（已配對/司機已確認）時，顯示「出發前往載客」按鈕
        // 邏輯說明：
        // 1. 司機確認接單後，Supabase 狀態為 'driver_confirmed'
        // 2. Edge Function 同步到 Firestore 時，映射為 'matched'（已配對）
        // 3. 司機點擊「出發前往載客」後，Supabase 狀態變為 'driver_departed'
        // 4. Edge Function 再次同步，Firestore 狀態變為 'ON_THE_WAY'（正在路上）
        if (order.status == BookingStatus.matched)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // 顯示確認對話框
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('確認出發'),
                    content: const Text('確定要出發前往上車地點嗎？\n系統將自動通知客戶。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('確認出發'),
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
                              Text('正在更新狀態...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );

                try {
                  // 調用 API 更新狀態
                  final bookingService = BookingService();
                  await bookingService.driverDepart(order.id);

                  // 關閉載入對話框
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }

                  // 顯示成功訊息
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 已出發！客戶已收到通知'),
                        backgroundColor: Color(0xFF2196F3),
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
                        content: Text('❌ 更新失敗: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '出發前往載客 🚗',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // 當訂單狀態為 onTheWay（正在路上）時，顯示「抵達上車地點」按鈕
        // 邏輯說明：
        // 1. 司機點擊「出發前往載客」後，Supabase 狀態變為 'driver_departed'
        // 2. Edge Function 同步到 Firestore 時，映射為 'ON_THE_WAY'（正在路上）
        // 3. 司機點擊「抵達上車地點」後，Supabase 狀態變為 'driver_arrived'
        // 4. Edge Function 再次同步，Firestore 狀態仍為 'ON_THE_WAY'（正在路上）
        // 5. 客戶點擊「開始行程」後，Supabase 狀態變為 'trip_started'
        // 6. Edge Function 同步，Firestore 狀態變為 'inProgress'（進行中）
        if (order.status == BookingStatus.onTheWay)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // 顯示確認對話框
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('確認到達'),
                    content: const Text('確定已到達上車地點嗎？\n系統將自動通知客戶準備上車。'),
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
                        child: const Text('確認到達'),
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
                              Text('正在更新狀態...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );

                try {
                  // 調用 API 更新狀態
                  final bookingService = BookingService();
                  await bookingService.driverArrive(order.id);

                  // 關閉載入對話框
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }

                  // 顯示成功訊息
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 已到達！客戶已收到通知'),
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
                        content: Text('❌ 更新失敗: $e'),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '抵達上車地點 📍',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}

