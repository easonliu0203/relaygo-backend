import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'earnings_service.freezed.dart';
part 'earnings_service.g.dart';

/// 每日收入資料模型
@freezed
class DailyEarnings with _$DailyEarnings {
  const factory DailyEarnings({
    required String date,
    required double earnings,
    required int orders,
  }) = _DailyEarnings;

  factory DailyEarnings.fromJson(Map<String, dynamic> json) =>
      _$DailyEarningsFromJson(json);
}

/// 收入統計資料模型
@freezed
class EarningsData with _$EarningsData {
  const factory EarningsData({
    @Default(0.0) double totalEarnings,
    @Default(0) int totalOrders,
    @Default(0.0) double averageEarnings,
    @Default([]) List<DailyEarnings> dailyEarnings,
  }) = _EarningsData;

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    // 解析 dailyEarnings 陣列
    final dailyEarningsList = (json['dailyEarnings'] as List<dynamic>?)
            ?.map((e) => DailyEarnings.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return EarningsData(
      totalEarnings: (json['totalEarnings'] ?? 0.0) is int
          ? (json['totalEarnings'] as int).toDouble()
          : (json['totalEarnings'] ?? 0.0).toDouble(),
      totalOrders: (json['totalOrders'] ?? 0) as int,
      averageEarnings: (json['averageEarnings'] ?? 0.0) is int
          ? (json['averageEarnings'] as int).toDouble()
          : (json['averageEarnings'] ?? 0.0).toDouble(),
      dailyEarnings: dailyEarningsList,
    );
  }
}

/// 收入服務（使用 Firestore）
class EarningsService {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  EarningsService(this._firestore);

  /// 獲取司機收入統計
  ///
  /// [driverId] 司機 Firebase UID
  /// [startDate] 開始日期
  /// [endDate] 結束日期
  ///
  /// 返回 [EarningsData] 收入統計資料
  Future<EarningsData> getDriverEarnings({
    required String driverId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.i(
          '📊 [Earnings] 獲取司機收入統計: $driverId, ${startDate.toIso8601String().split('T')[0]} - ${endDate.toIso8601String().split('T')[0]}');

      // 查詢 Firestore orders_rt collection
      // 只使用 driverId 和 status 篩選（避免需要複合索引）
      // 然後在客戶端過濾時間範圍
      final querySnapshot = await _firestore
          .collection('orders_rt')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .get();

      _logger.i('✅ [Earnings] 查詢到 ${querySnapshot.docs.length} 筆已完成訂單');

      // 計算總收入、訂單數、每日收入
      double totalEarnings = 0.0;
      int totalOrders = querySnapshot.docs.length;
      final Map<String, DailyEarnings> dailyEarningsMap = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // 客戶端過濾時間範圍
        if (data['completedAt'] == null) continue;
        final completedAt = (data['completedAt'] as Timestamp).toDate();
        if (completedAt.isBefore(startDate) || completedAt.isAfter(endDate)) {
          continue;
        }

        final totalAmount = (data['estimatedFare'] ?? 0.0) is int
            ? (data['estimatedFare'] as int).toDouble()
            : (data['estimatedFare'] ?? 0.0).toDouble();

        // 司機收入 = 總金額 * 75%
        final driverEarning = totalAmount * 0.75;
        totalEarnings += driverEarning;

        // 按日期分組
        final dateKey = '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';

        if (dailyEarningsMap.containsKey(dateKey)) {
          final existing = dailyEarningsMap[dateKey]!;
          dailyEarningsMap[dateKey] = DailyEarnings(
            date: dateKey,
            earnings: existing.earnings + driverEarning,
            orders: existing.orders + 1,
          );
        } else {
          dailyEarningsMap[dateKey] = DailyEarnings(
            date: dateKey,
            earnings: driverEarning,
            orders: 1,
          );
        }
      }

      // 轉換為列表並排序
      final dailyEarningsList = dailyEarningsMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // 計算平均收入
      final averageEarnings = totalOrders > 0 ? totalEarnings / totalOrders : 0.0;

      _logger.i('📊 [Earnings] 總收入: NT\$ ${totalEarnings.toStringAsFixed(2)}, 訂單數: $totalOrders, 平均收入: NT\$ ${averageEarnings.toStringAsFixed(2)}');

      return EarningsData(
        totalEarnings: totalEarnings,
        totalOrders: totalOrders,
        averageEarnings: averageEarnings,
        dailyEarnings: dailyEarningsList,
      );
    } catch (e, stackTrace) {
      _logger.e('❌ [Earnings] 獲取收入統計失敗', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}

