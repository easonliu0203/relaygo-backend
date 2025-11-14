import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/review_service.dart';
import '../widgets/review_card_widget.dart';
import '../widgets/rating_distribution_chart.dart';

/// 司機評價列表頁面
class DriverReviewsPage extends StatefulWidget {
  const DriverReviewsPage({Key? key}) : super(key: key);

  @override
  State<DriverReviewsPage> createState() => _DriverReviewsPageState();
}

class _DriverReviewsPageState extends State<DriverReviewsPage> {
  final _reviewService = ReviewService();
  final _scrollController = ScrollController();

  List<Review> _reviews = [];
  ReviewStatistics? _statistics;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreReviews();
      }
    }
  }

  Future<void> _loadReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = '請先登入';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _reviewService.getDriverReviews(
        driverUid: user.uid,
        page: 1,
        limit: _pageSize,
        status: 'approved',
      );

      if (!mounted) return;

      setState(() {
        _reviews = response.reviews;
        _statistics = response.statistics;
        _currentPage = 1;
        _hasMore = response.reviews.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e is ReviewServiceException ? e.message : '載入評價失敗';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _reviewService.getDriverReviews(
        driverUid: user.uid,
        page: _currentPage + 1,
        limit: _pageSize,
        status: 'approved',
      );

      if (!mounted) return;

      setState(() {
        _reviews.addAll(response.reviews);
        _currentPage++;
        _hasMore = response.reviews.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ReviewServiceException ? e.message : '載入更多評價失敗'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的評價'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReviews,
            tooltip: '重新整理',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReviews,
              icon: const Icon(Icons.refresh),
              label: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return ListView(
        children: [
          if (_statistics != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: RatingStatisticsCard(
                averageRating: _statistics!.averageRating,
                totalReviews: _statistics!.totalReviews,
                distribution: _statistics!.ratingDistribution,
              ),
            ),
          ],
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  '暫無評價',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '完成訂單後，客戶可以對您進行評價',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _reviews.length + 2, // +1 for statistics card, +1 for loading indicator
      itemBuilder: (context, index) {
        // 統計卡片
        if (index == 0) {
          if (_statistics == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: RatingStatisticsCard(
              averageRating: _statistics!.averageRating,
              totalReviews: _statistics!.totalReviews,
              distribution: _statistics!.ratingDistribution,
            ),
          );
        }

        // 載入更多指示器
        if (index == _reviews.length + 1) {
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (!_hasMore && _reviews.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '已載入全部評價',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        // 評價卡片
        final review = _reviews[index - 1];
        return ReviewCardWidget(review: review);
      },
    );
  }
}

