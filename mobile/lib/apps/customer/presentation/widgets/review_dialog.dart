import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/models/booking_order.dart';
import '../../../../core/services/review_service.dart';
import '../../../../core/l10n/app_localizations.dart';

/// 評價對話框組件
/// 
/// 用於客戶評價司機的對話框
/// 可在訂單完成頁面或訂單詳情頁面中使用
class ReviewDialog extends StatefulWidget {
  final String bookingId;
  final BookingOrder? booking;
  final VoidCallback? onReviewSubmitted;

  const ReviewDialog({
    super.key,
    required this.bookingId,
    this.booking,
    this.onReviewSubmitted,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _reviewService = ReviewService();
  final _commentController = TextEditingController();

  int _rating = 0;
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final l10n = AppLocalizations.of(context)!;

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectRating),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseLogin),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reviewService.submitReview(
        customerUid: user.uid,
        bookingId: widget.bookingId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        isAnonymous: _isAnonymous,
      );

      if (!mounted) return;

      // 關閉對話框
      Navigator.of(context).pop(true); // 返回 true 表示評價成功

      // 調用回調
      widget.onReviewSubmitted?.call();
    } catch (e) {
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      String errorMessage = l10n.reviewSubmitFailed;
      if (e is ReviewServiceException) {
        errorMessage = e.message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 標題
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Color(0xFFFF9800),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.rateDriver,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 司機資訊（如果有）
              if (widget.booking?.driverName != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2196F3),
                        child: Text(
                          widget.booking!.driverName![0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.booking!.driverName!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.booking!.driverVehiclePlate != null)
                              Text(
                                '${l10n.vehiclePlate}：${widget.booking!.driverVehiclePlate}',
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
                const SizedBox(height: 24),
              ],

              // 評分選擇
              Text(
                l10n.pleaseRateService,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _rating = starValue;
                            });
                          },
                    icon: Icon(
                      starValue <= _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: starValue <= _rating
                          ? const Color(0xFFFF9800)
                          : Colors.grey[400],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // 評論輸入
              TextField(
                controller: _commentController,
                enabled: !_isSubmitting,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.reviewOptional,
                  hintText: l10n.shareRideExperience,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // 匿名選項
              Row(
                children: [
                  Checkbox(
                    value: _isAnonymous,
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _isAnonymous = value ?? false;
                            });
                          },
                  ),
                  Text(l10n.anonymousReview),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: l10n.driverWontSeeYourName,
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 按鈕
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop(false); // 返回 false 表示取消
                            },
                      child: Text(l10n.rateLater),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(l10n.submitReview),
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
}

