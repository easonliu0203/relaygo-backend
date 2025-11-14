import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ride_booking_app/apps/driver/providers/driver_booking_provider.dart';
import 'package:ride_booking_app/core/models/booking_order.dart';

class DriverOrderPage extends ConsumerStatefulWidget {
  const DriverOrderPage({super.key});

  @override
  ConsumerState<DriverOrderPage> createState() => _DriverOrderPageState();
}

class _DriverOrderPageState extends ConsumerState<DriverOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的訂單'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '進行中'),
            Tab(text: '歷史訂單'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrdersList(),
          _buildAllOrdersList(),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersList() {
    final activeOrdersAsync = ref.watch(driverActiveBookingsProvider);

    return activeOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.assignment_outlined,
            title: '沒有進行中的訂單',
            subtitle: '您目前沒有進行中的訂單',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverActiveBookingsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildAllOrdersList() {
    // ✅ 修復：使用 driverCompletedBookingsProvider 只顯示已完成和已取消的訂單
    final completedOrdersAsync = ref.watch(driverCompletedBookingsProvider);

    return completedOrdersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: '沒有歷史訂單',
            subtitle: '您還沒有已完成或已取消的訂單',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverCompletedBookingsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildOrderCard(BookingOrder order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/driver/order-detail/${order.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 訂單狀態和時間
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: order.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: order.status.color.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: order.status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(order.bookingTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 訂單 ID
              Text(
                '訂單 ID: ${order.id.substring(0, 8)}...',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // 路線資訊
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.pickupAddress,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.flag, size: 16, color: Color(0xFFF44336)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.dropoffAddress,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 金額
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '預估費用',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'NT\$ ${order.estimatedFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            '載入失敗',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(driverBookingsProvider);
              ref.invalidate(driverActiveBookingsProvider);
            },
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }
}
