import 'package:flutter/material.dart';

/// 評分分布圖表組件
class RatingDistributionChart extends StatelessWidget {
  /// 評分分布數據 {1: count, 2: count, 3: count, 4: count, 5: count}
  final Map<int, int> distribution;

  /// 總評價數
  final int totalReviews;

  const RatingDistributionChart({
    Key? key,
    required this.distribution,
    required this.totalReviews,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.star_border,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                '暫無評價數據',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 5 星到 1 星的分布條
        for (int star = 5; star >= 1; star--)
          _buildDistributionBar(
            context,
            star: star,
            count: distribution[star] ?? 0,
            totalReviews: totalReviews,
          ),
      ],
    );
  }

  Widget _buildDistributionBar(
    BuildContext context, {
    required int star,
    required int count,
    required int totalReviews,
  }) {
    final percentage = totalReviews > 0 ? (count / totalReviews) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // 星級標籤
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$star',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 進度條
          Expanded(
            child: Stack(
              children: [
                // 背景條
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // 填充條
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getColorForStar(star),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 數量和百分比
          SizedBox(
            width: 80,
            child: Text(
              '$count (${(percentage * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForStar(int star) {
    switch (star) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// 評分統計卡片
class RatingStatisticsCard extends StatelessWidget {
  /// 平均評分
  final double averageRating;

  /// 總評價數
  final int totalReviews;

  /// 評分分布
  final Map<int, int> distribution;

  const RatingStatisticsCard({
    Key? key,
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '評價統計',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // 平均評分顯示
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final fullStars = averageRating.floor();
                          final hasHalfStar = (averageRating - fullStars) >= 0.5;

                          if (index < fullStars) {
                            return const Icon(Icons.star, color: Colors.amber, size: 20);
                          } else if (index == fullStars && hasHalfStar) {
                            return const Icon(Icons.star_half, color: Colors.amber, size: 20);
                          } else {
                            return Icon(Icons.star_border, color: Colors.grey[300], size: 20);
                          }
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '共 $totalReviews 條評價',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 評分分布
                Expanded(
                  flex: 3,
                  child: RatingDistributionChart(
                    distribution: distribution,
                    totalReviews: totalReviews,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

