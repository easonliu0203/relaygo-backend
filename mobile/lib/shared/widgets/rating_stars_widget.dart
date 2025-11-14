import 'package:flutter/material.dart';

/// 星級評分組件
class RatingStarsWidget extends StatelessWidget {
  /// 當前評分（1-5）
  final int rating;

  /// 評分改變回調
  final ValueChanged<int>? onRatingChanged;

  /// 星星大小
  final double size;

  /// 是否可交互
  final bool interactive;

  /// 星星顏色
  final Color? color;

  /// 未選中星星顏色
  final Color? unselectedColor;

  const RatingStarsWidget({
    Key? key,
    required this.rating,
    this.onRatingChanged,
    this.size = 32.0,
    this.interactive = true,
    this.color,
    this.unselectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedColor = color ?? Theme.of(context).colorScheme.primary;
    final unselected = unselectedColor ?? Colors.grey[300]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isSelected = starNumber <= rating;

        return GestureDetector(
          onTap: interactive && onRatingChanged != null
              ? () => onRatingChanged!(starNumber)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              size: size,
              color: isSelected ? selectedColor : unselected,
            ),
          ),
        );
      }),
    );
  }
}

/// 帶文字的星級評分組件
class RatingStarsWithLabel extends StatelessWidget {
  /// 當前評分（1-5）
  final int rating;

  /// 評分改變回調
  final ValueChanged<int>? onRatingChanged;

  /// 星星大小
  final double size;

  /// 是否可交互
  final bool interactive;

  /// 顯示評分數字
  final bool showRatingNumber;

  /// 評分標籤
  final Map<int, String> ratingLabels;

  const RatingStarsWithLabel({
    Key? key,
    required this.rating,
    this.onRatingChanged,
    this.size = 32.0,
    this.interactive = true,
    this.showRatingNumber = true,
    this.ratingLabels = const {
      1: '非常不滿意',
      2: '不滿意',
      3: '一般',
      4: '滿意',
      5: '非常滿意',
    },
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingStarsWidget(
          rating: rating,
          onRatingChanged: onRatingChanged,
          size: size,
          interactive: interactive,
        ),
        const SizedBox(height: 8),
        if (rating > 0) ...[
          Text(
            ratingLabels[rating] ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (showRatingNumber) ...[
            const SizedBox(height: 4),
            Text(
              '$rating / 5',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ],
      ],
    );
  }
}

/// 只讀星級評分顯示組件
class RatingStarsDisplay extends StatelessWidget {
  /// 評分（可以是小數）
  final double rating;

  /// 星星大小
  final double size;

  /// 是否顯示評分數字
  final bool showRatingNumber;

  /// 星星顏色
  final Color? color;

  const RatingStarsDisplay({
    Key? key,
    required this.rating,
    this.size = 20.0,
    this.showRatingNumber = true,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber;
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < fullStars) {
            // 完整星星
            return Icon(
              Icons.star,
              size: size,
              color: starColor,
            );
          } else if (index == fullStars && hasHalfStar) {
            // 半星
            return Icon(
              Icons.star_half,
              size: size,
              color: starColor,
            );
          } else {
            // 空星
            return Icon(
              Icons.star_border,
              size: size,
              color: Colors.grey[300],
            );
          }
        }),
        if (showRatingNumber) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }
}

