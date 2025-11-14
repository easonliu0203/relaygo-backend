import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../config/environment_config.dart';

/// 評價服務異常
class ReviewServiceException implements Exception {
  final String message;
  final dynamic originalError;

  ReviewServiceException(this.message, [this.originalError]);

  @override
  String toString() => 'ReviewServiceException: $message';
}

/// 評價數據模型
class Review {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String? comment;
  final bool isAnonymous;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reviewedAt;
  final String? reviewedBy;
  final int helpfulCount;
  final int reportCount;
  final String? reviewerName;

  Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.isAnonymous,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.reviewedAt,
    this.reviewedBy,
    required this.helpfulCount,
    required this.reportCount,
    this.reviewerName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      reviewerId: json['reviewerId'] as String,
      revieweeId: json['revieweeId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      isAnonymous: json['isAnonymous'] as bool,
      status: json['status'] as String,
      adminNotes: json['adminNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      reviewedAt: json['reviewedAt'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      helpfulCount: json['helpfulCount'] as int? ?? 0,
      reportCount: json['reportCount'] as int? ?? 0,
      reviewerName: json['reviewerName'] as String?,
    );
  }
}

/// 評價統計數據模型
class ReviewStatistics {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final DateTime? lastReviewAt;
  final List<RecentReview> recentReviews;

  ReviewStatistics({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    this.lastReviewAt,
    required this.recentReviews,
  });

  factory ReviewStatistics.fromJson(Map<String, dynamic> json) {
    final distribution = json['ratingDistribution'] as Map<String, dynamic>;
    final ratingDist = <int, int>{};
    distribution.forEach((key, value) {
      ratingDist[int.parse(key)] = value as int;
    });

    final recentList = json['recentReviews'] as List<dynamic>? ?? [];
    final recent = recentList.map((r) => RecentReview.fromJson(r as Map<String, dynamic>)).toList();

    return ReviewStatistics(
      averageRating: (json['averageRating'] as num).toDouble(),
      totalReviews: json['totalReviews'] as int,
      ratingDistribution: ratingDist,
      lastReviewAt: json['lastReviewAt'] != null ? DateTime.parse(json['lastReviewAt'] as String) : null,
      recentReviews: recent,
    );
  }
}

/// 最近評價數據模型
class RecentReview {
  final String id;
  final int rating;
  final String? comment;
  final bool isAnonymous;
  final DateTime createdAt;
  final String reviewerName;

  RecentReview({
    required this.id,
    required this.rating,
    this.comment,
    required this.isAnonymous,
    required this.createdAt,
    required this.reviewerName,
  });

  factory RecentReview.fromJson(Map<String, dynamic> json) {
    return RecentReview(
      id: json['id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      isAnonymous: json['isAnonymous'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewerName: json['reviewerName'] as String,
    );
  }
}

/// 評價列表響應模型
class ReviewListResponse {
  final List<Review> reviews;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final ReviewStatistics? statistics;

  ReviewListResponse({
    required this.reviews,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    this.statistics,
  });

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) {
    final reviewsList = json['reviews'] as List<dynamic>;
    final reviews = reviewsList.map((r) => Review.fromJson(r as Map<String, dynamic>)).toList();

    final pagination = json['pagination'] as Map<String, dynamic>;

    return ReviewListResponse(
      reviews: reviews,
      page: pagination['page'] as int,
      limit: pagination['limit'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
      statistics: json['statistics'] != null ? ReviewStatistics.fromJson(json['statistics'] as Map<String, dynamic>) : null,
    );
  }
}

/// 評價服務
class ReviewService {
  // Backend API 基礎 URL (port 3000)
  // 使用環境配置，並將端口從 3001 轉換為 3000
  static String get _backendApiBaseUrl {
    final apiUrl = EnvironmentConfig.apiBaseUrl;
    // 將 3001 端口替換為 3000（後端 API 端口）
    return apiUrl.replaceAll(':3001/api', ':3000/api');
  }

  /// 提交評價
  /// [customerUid] 客戶 Firebase UID
  /// [bookingId] 訂單 ID
  /// [rating] 評分 (1-5)
  /// [comment] 評論內容（可選）
  /// [isAnonymous] 是否匿名評價
  Future<Review> submitReview({
    required String customerUid,
    required String bookingId,
    required int rating,
    String? comment,
    bool isAnonymous = false,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        throw ReviewServiceException('評分必須在 1-5 之間');
      }

      final url = Uri.parse('$_backendApiBaseUrl/reviews');

      print('📤 [ReviewService] 提交評價');
      print('   URL: $url');
      print('   Customer UID: $customerUid');
      print('   Booking ID: $bookingId');
      print('   Rating: $rating');
      print('   Is Anonymous: $isAnonymous');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerUid': customerUid,
          'bookingId': bookingId,
          'rating': rating,
          'comment': comment,
          'isAnonymous': isAnonymous,
        }),
      );

      print('📥 [ReviewService] 響應狀態: ${response.statusCode}');

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        print('❌ [ReviewService] 提交失敗');
        print('   錯誤: ${errorData['error']}');
        throw ReviewServiceException(
          errorData['error'] ?? '提交評價失敗',
          errorData,
        );
      }

      final jsonData = json.decode(response.body);

      if (jsonData['success'] != true) {
        throw ReviewServiceException('提交評價失敗', jsonData['error']);
      }

      print('✅ [ReviewService] 評價提交成功');
      return Review.fromJson(jsonData['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ReviewServiceException) {
        rethrow;
      }
      print('❌ [ReviewService] 提交評價異常: $e');
      throw ReviewServiceException('提交評價失敗', e);
    }
  }

  /// 獲取司機評價列表
  /// [driverUid] 司機 Firebase UID
  /// [page] 頁碼（從 1 開始）
  /// [limit] 每頁數量
  /// [status] 評價狀態篩選（可選）
  Future<ReviewListResponse> getDriverReviews({
    required String driverUid,
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = {
        'driverUid': driverUid,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final url = Uri.parse('$_backendApiBaseUrl/reviews/driver').replace(queryParameters: queryParams);

      print('📤 [ReviewService] 獲取司機評價列表');
      print('   URL: $url');

      final response = await http.get(url);

      print('📥 [ReviewService] 響應狀態: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        print('❌ [ReviewService] 獲取失敗');
        print('   錯誤: ${errorData['error']}');
        throw ReviewServiceException(
          errorData['error'] ?? '獲取評價列表失敗',
          errorData,
        );
      }

      final jsonData = json.decode(response.body);

      if (jsonData['success'] != true) {
        throw ReviewServiceException('獲取評價列表失敗', jsonData['error']);
      }

      print('✅ [ReviewService] 獲取評價列表成功');
      return ReviewListResponse.fromJson(jsonData['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ReviewServiceException) {
        rethrow;
      }
      print('❌ [ReviewService] 獲取評價列表異常: $e');
      throw ReviewServiceException('獲取評價列表失敗', e);
    }
  }

  /// 獲取司機評價統計
  /// [driverUid] 司機 Firebase UID
  Future<ReviewStatistics> getDriverStatistics({
    required String driverUid,
  }) async {
    try {
      final url = Uri.parse('$_backendApiBaseUrl/reviews/driver/statistics').replace(
        queryParameters: {'driverUid': driverUid},
      );

      print('📤 [ReviewService] 獲取司機評價統計');
      print('   URL: $url');

      final response = await http.get(url);

      print('📥 [ReviewService] 響應狀態: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        print('❌ [ReviewService] 獲取失敗');
        print('   錯誤: ${errorData['error']}');
        throw ReviewServiceException(
          errorData['error'] ?? '獲取評價統計失敗',
          errorData,
        );
      }

      final jsonData = json.decode(response.body);

      if (jsonData['success'] != true) {
        throw ReviewServiceException('獲取評價統計失敗', jsonData['error']);
      }

      print('✅ [ReviewService] 獲取評價統計成功');
      return ReviewStatistics.fromJson(jsonData['data'] as Map<String, dynamic>);
    } catch (e) {
      if (e is ReviewServiceException) {
        rethrow;
      }
      print('❌ [ReviewService] 獲取評價統計異常: $e');
      throw ReviewServiceException('獲取評價統計失敗', e);
    }
  }

  /// 檢查訂單是否已評價
  /// [bookingId] 訂單 ID
  /// 返回 true 表示已評價，false 表示未評價
  Future<bool> checkIfReviewed({
    required String bookingId,
  }) async {
    try {
      final url = Uri.parse('$_backendApiBaseUrl/reviews/check/$bookingId');

      print('📤 [ReviewService] 檢查訂單是否已評價');
      print('   URL: $url');

      final response = await http.get(url);

      print('📥 [ReviewService] 響應狀態: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        print('❌ [ReviewService] 檢查失敗');
        print('   錯誤: ${errorData['error']}');
        throw ReviewServiceException(
          errorData['error'] ?? '檢查評價失敗',
          errorData,
        );
      }

      final jsonData = json.decode(response.body);

      if (jsonData['success'] != true) {
        throw ReviewServiceException('檢查評價失敗', jsonData['error']);
      }

      final hasReviewed = jsonData['data']['hasReviewed'] as bool;
      print('✅ [ReviewService] 檢查成功: ${hasReviewed ? "已評價" : "未評價"}');

      return hasReviewed;
    } catch (e) {
      if (e is ReviewServiceException) {
        rethrow;
      }
      print('❌ [ReviewService] 檢查評價異常: $e');
      throw ReviewServiceException('檢查評價失敗', e);
    }
  }
}

