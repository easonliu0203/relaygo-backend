import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

/// 評價對話框
class RatingDialog extends ConsumerStatefulWidget {
  final String bookingId;
  final String bookingNumber;
  final VoidCallback? onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.bookingId,
    required this.bookingNumber,
    this.onRatingSubmitted,
  });

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇評分')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final response = await http.post(
        Uri.parse('https://api.relaygo.pro/api/bookings/${widget.bookingId}/rating'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerUid': user.uid,
          'rating': _rating,
          'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true); // 返回 true 表示評價成功
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('評價提交成功！感謝您的回饋'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRatingSubmitted?.call();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '評價提交失敗');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('評價提交失敗: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題
            const Text(
              '評價司機服務',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '訂單編號: ${widget.bookingNumber}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // 星星評分
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: index < _rating ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            if (_rating > 0)
              Text(
                _getRatingText(_rating),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2196F3),
                ),
              ),
            const SizedBox(height: 24),

            // 留言輸入框
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '分享您的乘車體驗（選填）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 按鈕
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('稍後再說'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('提交評價'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return '非常不滿意';
      case 2:
        return '不滿意';
      case 3:
        return '普通';
      case 4:
        return '滿意';
      case 5:
        return '非常滿意';
      default:
        return '';
    }
  }
}

