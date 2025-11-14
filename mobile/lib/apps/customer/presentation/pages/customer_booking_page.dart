import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/booking_order.dart';
import '../../../../shared/providers/booking_provider.dart';

class CustomerBookingPage extends ConsumerStatefulWidget {
  const CustomerBookingPage({super.key});

  @override
  ConsumerState<CustomerBookingPage> createState() => _CustomerBookingPageState();
}

class _CustomerBookingPageState extends ConsumerState<CustomerBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _selectedDateTime;
  int _passengerCount = 1;
  int _luggageCount = 0;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingRequest = ref.watch(bookingRequestProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('預約叫車'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上車地點
              _buildSectionTitle('上車地點'),
              const SizedBox(height: 8),
              _buildLocationField(
                controller: _pickupController,
                hintText: '請輸入上車地點',
                icon: Icons.my_location,
                onTap: () => _selectLocation(true),
              ),
              const SizedBox(height: 24),

              // 下車地點
              _buildSectionTitle('下車地點'),
              const SizedBox(height: 8),
              _buildLocationField(
                controller: _dropoffController,
                hintText: '請輸入下車地點',
                icon: Icons.location_on,
                onTap: () => _selectLocation(false),
              ),
              const SizedBox(height: 24),

              // 預約時間
              _buildSectionTitle('預約時間'),
              const SizedBox(height: 8),
              _buildDateTimeField(),
              const SizedBox(height: 24),

              // 乘客人數
              _buildSectionTitle('乘客人數'),
              const SizedBox(height: 8),
              _buildPassengerCountField(),
              const SizedBox(height: 24),

              // 行李數量
              _buildSectionTitle('行李數量（可選）'),
              const SizedBox(height: 8),
              _buildLuggageCountField(),
              const SizedBox(height: 24),

              // 備註
              _buildSectionTitle('備註（可選）'),
              const SizedBox(height: 8),
              _buildNotesField(),
              const SizedBox(height: 32),

              // 選擇方案按鈕
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSubmit() ? _goToPackageSelection : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '選擇方案',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
        suffixIcon: const Icon(Icons.search, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '請選擇${hintText.replaceAll('請輸入', '')}';
        }
        return null;
      },
    );
  }

  Widget _buildDateTimeField() {
    return InkWell(
      onTap: _selectDateTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Color(0xFF2196F3)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDateTime != null
                    ? '${_selectedDateTime!.year}/${_selectedDateTime!.month}/${_selectedDateTime!.day} ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'
                    : '請選擇預約時間',
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedDateTime != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFF2196F3)),
          const SizedBox(width: 12),
          const Text('乘客人數：', style: TextStyle(fontSize: 16)),
          const Spacer(),
          IconButton(
            onPressed: _passengerCount > 1 ? () => setState(() => _passengerCount--) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: const Color(0xFF2196F3),
          ),
          Text(
            '$_passengerCount',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: _passengerCount < 8 ? () => setState(() => _passengerCount++) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildLuggageCountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.luggage, color: Color(0xFF2196F3)),
          const SizedBox(width: 12),
          const Text('行李數量：', style: TextStyle(fontSize: 16)),
          const Spacer(),
          IconButton(
            onPressed: _luggageCount > 0 ? () => setState(() => _luggageCount--) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: const Color(0xFF2196F3),
          ),
          Text(
            '$_luggageCount',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: _luggageCount < 10 ? () => setState(() => _luggageCount++) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: '請輸入特殊需求或備註（可選）',
        prefixIcon: const Icon(Icons.note, color: Color(0xFF2196F3)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
        ),
      ),
    );
  }

  Widget _buildEstimatedFare() {
    // 簡化的費用計算（實際應該從服務層獲取）
    final estimatedFare = _calculateEstimatedFare();
    final depositAmount = estimatedFare * 0.25;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '費用預估',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('預估總費用：'),
              Text(
                'NT\$ ${estimatedFare.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('需付訂金（25%）：'),
              Text(
                'NT\$ ${depositAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateEstimatedFare() {
    // 簡化的費用計算邏輯
    double fare = 150.0; // 基本費用
    fare += _passengerCount > 2 ? (_passengerCount - 2) * 20.0 : 0.0;
    fare += _luggageCount * 10.0;
    return fare;
  }

  bool _canSubmit() {
    return _pickupController.text.isNotEmpty &&
           _dropoffController.text.isNotEmpty &&
           _selectedDateTime != null &&
           _passengerCount > 0;
  }

  void _selectLocation(bool isPickup) {
    // TODO: 實作地點選擇功能（可以使用 Google Places API 或地圖選擇）
    // 目前使用簡化的輸入對話框
    showDialog(
      context: context,
      builder: (context) => _LocationInputDialog(
        title: isPickup ? '選擇上車地點' : '選擇下車地點',
        onLocationSelected: (address) {
          setState(() {
            if (isPickup) {
              _pickupController.text = address;
            } else {
              _dropoffController.text = address;
            }
          });
        },
      ),
    );
  }

  void _selectDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _goToPackageSelection() {
    if (!_formKey.currentState!.validate() || !_canSubmit()) return;

    // 更新預約請求狀態
    final notifier = ref.read(bookingRequestProvider.notifier);

    // 模擬地理座標（實際應該從地址解析獲取）
    const pickupLocation = LocationPoint(latitude: 25.0330, longitude: 121.5654);
    const dropoffLocation = LocationPoint(latitude: 25.0478, longitude: 121.5318);

    notifier.updatePickup(_pickupController.text, pickupLocation);
    notifier.updateDropoff(_dropoffController.text, dropoffLocation);
    notifier.updateBookingTime(_selectedDateTime!);
    notifier.updatePassengerCount(_passengerCount);
    notifier.updateLuggageCount(_luggageCount > 0 ? _luggageCount : null);
    notifier.updateNotes(_notesController.text.isNotEmpty ? _notesController.text : null);

    // 導航到價目表選擇頁面
    context.push('/package-selection');
  }


}

class _LocationInputDialog extends StatefulWidget {
  final String title;
  final Function(String) onLocationSelected;

  const _LocationInputDialog({
    required this.title,
    required this.onLocationSelected,
  });

  @override
  State<_LocationInputDialog> createState() => _LocationInputDialogState();
}

class _LocationInputDialogState extends State<_LocationInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: '請輸入地址',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onLocationSelected(_controller.text);
              Navigator.of(context).pop();
            }
          },
          child: const Text('確認'),
        ),
      ],
    );
  }
}
