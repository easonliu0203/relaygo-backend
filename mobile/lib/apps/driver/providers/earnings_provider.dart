import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ride_booking_app/core/services/earnings_service.dart';
import 'package:ride_booking_app/shared/providers/auth_provider.dart';

// Export DailyEarnings for Freezed generated code
export 'package:ride_booking_app/core/services/earnings_service.dart' show DailyEarnings;

part 'earnings_provider.freezed.dart';

/// 時間範圍枚舉
enum TimeRange {
  today,  // 今日
  week,   // 本週
  month,  // 本月
}

/// 時間範圍擴展方法
extension TimeRangeExtension on TimeRange {
  String get displayName {
    switch (this) {
      case TimeRange.today:
        return '今日';
      case TimeRange.week:
        return '本週';
      case TimeRange.month:
        return '本月';
    }
  }
}

/// 收入統計狀態
@freezed
class EarningsState with _$EarningsState {
  const factory EarningsState({
    @Default(TimeRange.today) TimeRange timeRange,
    @Default(0.0) double totalEarnings,
    @Default(0) int totalOrders,
    @Default(0.0) double averageEarnings,
    @Default([]) List<DailyEarnings> dailyEarnings,
    @Default(false) bool isLoading,
    String? error,
  }) = _EarningsState;
}

/// Earnings Service Provider
final earningsServiceProvider = Provider<EarningsService>((ref) {
  final firestore = FirebaseFirestore.instance;
  return EarningsService(firestore);
});

/// Earnings Provider
final earningsProvider =
    StateNotifierProvider<EarningsNotifier, EarningsState>((ref) {
  return EarningsNotifier(ref);
});

/// 收入統計 Notifier
class EarningsNotifier extends StateNotifier<EarningsState> {
  final Ref ref;

  EarningsNotifier(this.ref) : super(const EarningsState()) {
    _init();
  }

  void _init() {
    // 初始載入
    _fetchEarnings();
  }

  /// 切換時間範圍
  void setTimeRange(TimeRange timeRange) {
    state = state.copyWith(timeRange: timeRange);
    _fetchEarnings();
  }

  /// 刷新資料
  Future<void> refresh() async {
    await _fetchEarnings();
  }

  /// 從 Supabase 獲取收入統計
  Future<void> _fetchEarnings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 獲取當前用戶 ID
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        throw Exception('用戶未登入');
      }

      // 計算時間範圍
      final now = DateTime.now();
      final (startDate, endDate) = _getDateRange(now, state.timeRange);

      // 呼叫 Supabase RPC
      final earningsService = ref.read(earningsServiceProvider);
      final earningsData = await earningsService.getDriverEarnings(
        driverId: currentUser.uid,
        startDate: startDate,
        endDate: endDate,
      );

      // 更新狀態
      state = state.copyWith(
        totalEarnings: earningsData.totalEarnings,
        totalOrders: earningsData.totalOrders,
        averageEarnings: earningsData.averageEarnings,
        dailyEarnings: earningsData.dailyEarnings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// 計算時間範圍
  (DateTime, DateTime) _getDateRange(DateTime now, TimeRange timeRange) {
    switch (timeRange) {
      case TimeRange.today:
        final startDate = DateTime(now.year, now.month, now.day);
        return (startDate, now);

      case TimeRange.week:
        final weekday = now.weekday;
        final startDate = now.subtract(Duration(days: weekday - 1));
        final startOfWeek =
            DateTime(startDate.year, startDate.month, startDate.day);
        return (startOfWeek, now);

      case TimeRange.month:
        final startDate = DateTime(now.year, now.month, 1);
        return (startDate, now);
    }
  }
}