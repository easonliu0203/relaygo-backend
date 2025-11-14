import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/pricing_service.dart';
import '../../../../shared/providers/booking_provider.dart';

class PackageSelectionPage extends ConsumerStatefulWidget {
  const PackageSelectionPage({super.key});

  @override
  ConsumerState<PackageSelectionPage> createState() => _PackageSelectionPageState();
}

class _PackageSelectionPageState extends ConsumerState<PackageSelectionPage> {
  List<VehiclePackage> _packages = [];
  VehiclePackage? _selectedPackage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final packages = await PricingService().getAvailablePackages();
      setState(() {
        _packages = packages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入價目表失敗: $e')),
        );
      }
    }
  }

  void _selectPackage(VehiclePackage package) {
    setState(() {
      _selectedPackage = package;
    });
  }

  void _confirmSelection() {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇一個方案')),
      );
      return;
    }

    // 更新預約請求中的套餐資訊
    final bookingRequest = ref.read(bookingRequestProvider);
    ref.read(bookingRequestProvider.notifier).updatePackage(
      packageId: _selectedPackage!.id,
      packageName: _selectedPackage!.name,
      estimatedFare: _selectedPackage!.discountPrice,
    );

    // 導航到支付頁面
    context.push('/payment-deposit');
  }

  @override
  Widget build(BuildContext context) {
    final bookingRequest = ref.watch(bookingRequestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇方案'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 預約資訊摘要
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '預約資訊',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('上車地點: ${bookingRequest.pickupAddress}'),
                      Text('下車地點: ${bookingRequest.dropoffAddress}'),
                      Text('預約時間: ${bookingRequest.bookingTime.toString().substring(0, 16)}'),
                      Text('乘客人數: ${bookingRequest.passengerCount}人'),
                      if (bookingRequest.luggageCount != null && bookingRequest.luggageCount! > 0)
                        Text('行李數量: ${bookingRequest.luggageCount}件'),
                    ],
                  ),
                ),
                
                // 方案列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _packages.length,
                    itemBuilder: (context, index) {
                      final package = _packages[index];
                      final isSelected = _selectedPackage?.id == package.id;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isSelected ? 8 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _selectPackage(package),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 方案標題和價格
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            package.name,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? const Color(0xFF2196F3) : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            package.description,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (package.savings > 0) ...[
                                          Text(
                                            PricingService().formatPrice(package.originalPrice),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              decoration: TextDecoration.lineThrough,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                        ],
                                        Text(
                                          PricingService().formatPrice(package.discountPrice),
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF4CAF50),
                                          ),
                                        ),
                                        if (package.savings > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '省 ${PricingService().formatPrice(package.savings)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.red[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // 方案特色
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: package.features.map((feature) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? const Color(0xFF2196F3).withOpacity(0.1)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        feature,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[700],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // 超時費率
                                Text(
                                  '超時費率: ${PricingService().formatPrice(package.overtimeRate)}/小時',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                
                                // 選中指示器
                                if (isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '已選擇',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedPackage != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '選擇的方案:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _selectedPackage!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '方案費用:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    PricingService().formatPrice(_selectedPackage!.discountPrice),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPackage != null ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _selectedPackage != null ? '確認預約' : '請選擇方案',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
