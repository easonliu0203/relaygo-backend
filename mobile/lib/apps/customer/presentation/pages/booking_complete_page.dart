import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/rating_dialog.dart';

/// 訂單完成頁面
///
/// 功能：
/// 1. 顯示訂單完成的成功訊息
/// 2. 提供返回首頁或查看訂單詳情的選項
/// 3. ✅ 新增：彈出評價對話框，讓客戶評價司機服務
class BookingCompletePage extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingCompletePage({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<BookingCompletePage> createState() => _BookingCompletePageState();
}

class _BookingCompletePageState extends ConsumerState<BookingCompletePage> {
  String? _bookingNumber;
  bool _hasShownRatingDialog = false;

  @override
  void initState() {
    super.initState();
    _loadBookingData();
  }

  Future<void> _loadBookingData() async {
    try {
      // 查詢訂單資料以獲取 booking_number
      final response = await http.get(
        Uri.parse('https://api.relaygo.pro/api/bookings/${widget.bookingId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bookingNumber = data['data']['booking_number'];
        });

        // 延遲 500ms 後顯示評價對話框
        if (!_hasShownRatingDialog) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _showRatingDialog();
          }
        }
      }
    } catch (e) {
      debugPrint('[BookingComplete] 載入訂單資料失敗: $e');
    }
  }

  Future<void> _showRatingDialog() async {
    if (_hasShownRatingDialog || _bookingNumber == null) return;

    setState(() {
      _hasShownRatingDialog = true;
    });

    // 先檢查是否已評價過
    try {
      final checkResponse = await http.get(
        Uri.parse('https://api.relaygo.pro/api/bookings/${widget.bookingId}/rating'),
      );

      if (checkResponse.statusCode == 200) {
        // 已評價過，不顯示對話框
        debugPrint('[BookingComplete] 訂單已評價過');
        return;
      }
    } catch (e) {
      // 404 表示未評價，繼續顯示對話框
      debugPrint('[BookingComplete] 訂單尚未評價，顯示評價對話框');
    }

    // 顯示評價對話框
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false, // 不允許點擊外部關閉
      builder: (context) => RatingDialog(
        bookingId: widget.bookingId,
        bookingNumber: _bookingNumber!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單完成'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // 隱藏返回按鈕
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 成功圖標
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 32),

              // 成功標題
              const Text(
                '訂單已完成！',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 16),

              // 成功訊息
              const Text(
                '感謝您的使用！\n尾款已支付成功，訂單已完成。',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // 查看訂單詳情按鈕
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/order-detail/${widget.bookingId}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '查看訂單詳情',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 返回首頁按鈕
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                    side: const BorderSide(
                      color: Color(0xFF2196F3),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '返回首頁',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

