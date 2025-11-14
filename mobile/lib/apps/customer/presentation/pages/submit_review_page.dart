import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/review_service.dart';
import '../../../../shared/widgets/rating_stars_widget.dart';
import '../../../../core/l10n/app_localizations.dart';

/// 評價提交頁面
class SubmitReviewPage extends StatefulWidget {
  /// 訂單 ID
  final String bookingId;

  /// 訂單號
  final String? bookingNumber;

  /// 司機姓名
  final String? driverName;

  /// 行程日期
  final DateTime? tripDate;

  const SubmitReviewPage({
    Key? key,
    required this.bookingId,
    this.bookingNumber,
    this.driverName,
    this.tripDate,
  }) : super(key: key);

  @override
  State<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  final _reviewService = ReviewService();
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

    if (!_formKey.currentState!.validate()) {
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
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        isAnonymous: _isAnonymous,
      );

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      // 顯示成功訊息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.reviewSubmitted),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 延遲一下再返回，讓用戶看到成功訊息
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.of(context).pop(true); // 返回 true 表示提交成功
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
          duration: const Duration(seconds: 3),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rateDriver),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 訂單資訊卡片
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.orderInfo,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.bookingNumber != null) ...[
                          _buildInfoRow(
                            icon: Icons.confirmation_number,
                            label: l10n.orderNumber,
                            value: widget.bookingNumber!,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (widget.driverName != null) ...[
                          _buildInfoRow(
                            icon: Icons.person,
                            label: l10n.driver,
                            value: widget.driverName!,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (widget.tripDate != null) ...[
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: l10n.tripDate,
                            value: _formatDate(widget.tripDate!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 評分區域
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          l10n.yourRating,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        RatingStarsWithLabel(
                          rating: _rating,
                          onRatingChanged: (rating) {
                            setState(() {
                              _rating = rating;
                            });
                          },
                          size: 40.0,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 評論輸入
                Text(
                  l10n.detailedReview,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commentController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: l10n.shareYourExperience,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),

                const SizedBox(height: 16),

                // 匿名評價選項
                Card(
                  elevation: 1,
                  child: CheckboxListTile(
                    title: Text(l10n.anonymousReview),
                    subtitle: Text(l10n.driverWontSeeYourName),
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value ?? false;
                      });
                    },
                    secondary: const Icon(Icons.visibility_off),
                  ),
                ),

                const SizedBox(height: 24),

                // 提交按鈕
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.submitReview,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // 提示文字
                Text(
                  l10n.reviewHelpsImprove,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

