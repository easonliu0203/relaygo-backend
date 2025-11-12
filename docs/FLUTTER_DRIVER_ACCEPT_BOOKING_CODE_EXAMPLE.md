# 📱 Flutter 司機端「確認接單」功能代碼範例

**日期**：2025-01-12  
**目的**：提供完整的 Flutter 代碼範例，方便快速實作

---

## 📁 文件結構

```
mobile/lib/
├── core/
│   └── services/
│       └── booking_service.dart          # 添加 driverAcceptBooking 方法
├── features/
│   └── driver/
│       ├── screens/
│       │   └── booking_detail_screen.dart # 添加「確認接單」按鈕
│       └── widgets/
│           └── accept_booking_button.dart # 新增：確認接單按鈕組件（可選）
└── shared/
    └── models/
        └── booking_order.dart             # 確認 BookingStatus 枚舉
```

---

## 1️⃣ BookingService - 添加 API 調用方法

**文件**：`mobile/lib/core/services/booking_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  final String _baseUrl = 'http://localhost:3000'; // 或您的 Backend API URL
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 司機確認接單
  /// 
  /// [bookingId] 訂單 ID
  /// 
  /// 返回：成功時返回 void，失敗時拋出異常
  Future<void> driverAcceptBooking(String bookingId) async {
    try {
      // 1. 獲取當前用戶的 ID Token
      final token = await _auth.currentUser?.getIdToken();
      if (token == null) {
        throw Exception('未登入，請先登入');
      }

      // 2. 調用 Backend API
      final response = await http.post(
        Uri.parse('$_baseUrl/api/booking-flow/bookings/$bookingId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 3. 處理響應
      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? '確認接單失敗');
      }

      final data = json.decode(response.body);
      if (!data['success']) {
        throw Exception(data['error'] ?? '確認接單失敗');
      }

      // 4. 成功日誌
      print('✅ 確認接單成功: ${data['data']}');
      
    } catch (e) {
      print('❌ 確認接單失敗: $e');
      rethrow;
    }
  }

  /// 獲取訂單的即時更新流
  /// 
  /// [bookingId] 訂單 ID
  /// 
  /// 返回：訂單的 Stream，當訂單更新時自動觸發
  Stream<BookingOrder> getBookingStream(String bookingId) {
    return FirebaseFirestore.instance
        .collection('orders_rt')
        .doc(bookingId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('訂單不存在');
          }
          return BookingOrder.fromFirestore(snapshot);
        });
  }
}
```

---

## 2️⃣ BookingDetailScreen - 添加「確認接單」按鈕

**文件**：`mobile/lib/features/driver/screens/booking_detail_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _isLoading = false;

  /// 檢查是否應該顯示「確認接單」按鈕
  bool _shouldShowAcceptButton(BookingOrder booking) {
    // 1. 訂單狀態為「待配對」
    final isPending = booking.status == BookingStatus.pending;
    
    // 2. 訂單已分配給當前司機
    final currentDriverId = ref.read(authProvider).currentUser?.uid;
    final isAssignedToMe = booking.driverId == currentDriverId;
    
    // 3. 司機尚未確認接單
    final notConfirmed = booking.status != BookingStatus.matched;
    
    return isPending && isAssignedToMe && notConfirmed;
  }

  /// 處理確認接單按鈕點擊
  Future<void> _handleAcceptBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 調用 API
      await ref.read(bookingServiceProvider).driverAcceptBooking(widget.bookingId);

      // 顯示成功訊息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 確認接單成功！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Firestore 會自動更新訂單狀態，StreamBuilder 會自動刷新 UI
      // 不需要手動刷新

    } catch (e) {
      // 顯示錯誤訊息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 確認接單失敗: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單詳情'),
      ),
      body: StreamBuilder<BookingOrder>(
        stream: ref.read(bookingServiceProvider).getBookingStream(widget.bookingId),
        builder: (context, snapshot) {
          // 錯誤處理
          if (snapshot.hasError) {
            return Center(
              child: Text('錯誤: ${snapshot.error}'),
            );
          }

          // 載入中
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final booking = snapshot.data!;

          return Column(
            children: [
              // 訂單資訊（展開的內容）
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 訂單編號
                      _buildInfoRow('訂單編號', booking.bookingNumber),
                      const SizedBox(height: 12),

                      // 訂單狀態
                      _buildStatusChip(booking.status),
                      const SizedBox(height: 12),

                      // 客戶資訊
                      _buildSectionTitle('客戶資訊'),
                      _buildInfoRow('客戶姓名', booking.customerName ?? '未提供'),
                      _buildInfoRow('聯絡電話', booking.customerPhone ?? '未提供'),
                      const SizedBox(height: 12),

                      // 行程資訊
                      _buildSectionTitle('行程資訊'),
                      _buildInfoRow('上車地點', booking.pickupLocation),
                      _buildInfoRow('目的地', booking.destination ?? '未提供'),
                      _buildInfoRow('出發日期', booking.startDate),
                      _buildInfoRow('出發時間', booking.startTime),
                      _buildInfoRow('預計時長', '${booking.durationHours} 小時'),
                      const SizedBox(height: 12),

                      // 費用資訊
                      _buildSectionTitle('費用資訊'),
                      _buildInfoRow('預估費用', 'NT\$ ${booking.estimatedFare}'),
                      _buildInfoRow('訂金', 'NT\$ ${booking.depositAmount}'),
                      const SizedBox(height: 12),

                      // 特殊需求
                      if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                        _buildSectionTitle('特殊需求'),
                        Text(
                          booking.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 確認接單按鈕（固定在底部）
              if (_shouldShowAcceptButton(booking))
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAcceptBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '確認接單',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // 輔助方法：構建資訊行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 輔助方法：構建章節標題
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 輔助方法：構建狀態標籤
  Widget _buildStatusChip(BookingStatus status) {
    Color backgroundColor;
    String text;

    switch (status) {
      case BookingStatus.pending:
        backgroundColor = Colors.orange;
        text = '待配對';
        break;
      case BookingStatus.matched:
        backgroundColor = Colors.blue;
        text = '已配對';
        break;
      case BookingStatus.inProgress:
        backgroundColor = Colors.green;
        text = '進行中';
        break;
      case BookingStatus.completed:
        backgroundColor = Colors.grey;
        text = '已完成';
        break;
      case BookingStatus.cancelled:
        backgroundColor = Colors.red;
        text = '已取消';
        break;
      default:
        backgroundColor = Colors.grey;
        text = '未知';
    }

    return Chip(
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
    );
  }
}
```

---

## 3️⃣ Provider 設定（如果使用 Riverpod）

**文件**：`mobile/lib/core/providers/booking_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/booking_service.dart';

// BookingService Provider
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

// Auth Provider（假設已存在）
final authProvider = Provider<AuthService>((ref) {
  return AuthService();
});
```

---

## 📝 總結

**添加的代碼**：
1. `BookingService.driverAcceptBooking()` - API 調用方法
2. `BookingService.getBookingStream()` - Firestore 即時更新流
3. `BookingDetailScreen._shouldShowAcceptButton()` - 按鈕顯示邏輯
4. `BookingDetailScreen._handleAcceptBooking()` - 按鈕點擊處理
5. `BookingDetailScreen.build()` - UI 更新（添加按鈕）

**關鍵特性**：
- ✅ 使用 StreamBuilder 自動監聽 Firestore 訂單狀態變化
- ✅ 按鈕根據訂單狀態自動顯示/隱藏
- ✅ 載入狀態指示器（防止重複點擊）
- ✅ 成功/失敗訊息提示
- ✅ 錯誤處理

**測試步驟**：
1. 手動派單給司機
2. 司機端 APP 顯示「待配對」+ 「確認接單」按鈕
3. 點擊「確認接單」
4. 訂單狀態自動更新為「已配對」
5. 按鈕自動消失

---

**實作完成時間**：2025-01-12  
**實作者**：Augment Agent  
**狀態**：代碼範例已完成

