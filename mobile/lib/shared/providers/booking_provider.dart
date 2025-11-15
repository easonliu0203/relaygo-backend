import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/booking_order.dart';
import '../../core/services/booking_service.dart';

/// 預約服務 Provider
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

/// 當前預約狀態
sealed class BookingState {
  const BookingState();
}

class BookingStateInitial extends BookingState {
  const BookingStateInitial();
}

class BookingStateLoading extends BookingState {
  const BookingStateLoading();
}

class BookingStateSuccess extends BookingState {
  final BookingOrder order;
  const BookingStateSuccess(this.order);
}

class BookingStateError extends BookingState {
  final String message;
  const BookingStateError(this.message);
}

/// 預約狀態 Notifier
class BookingStateNotifier extends StateNotifier<BookingState> {
  final BookingService _bookingService;

  BookingStateNotifier(this._bookingService) : super(const BookingStateInitial());

  /// 創建預約（使用 Supabase API）
  Future<void> createBookingWithSupabase(BookingRequest request) async {
    state = const BookingStateLoading();

    try {
      final result = await _bookingService.createBookingWithSupabase(request);

      // 創建一個臨時的 BookingOrder 對象來保持兼容性
      final order = BookingOrder(
        id: result['id'] ?? '',
        customerId: '', // 將由 Supabase 處理
        pickupAddress: request.pickupAddress,
        pickupLocation: request.pickupLocation,
        dropoffAddress: request.dropoffAddress,
        dropoffLocation: request.dropoffLocation,
        bookingTime: request.bookingTime,
        passengerCount: request.passengerCount,
        luggageCount: request.luggageCount,
        notes: request.notes,
        estimatedFare: result['totalAmount']?.toDouble() ?? 0.0,
        depositAmount: result['depositAmount']?.toDouble() ?? 0.0,
        depositPaid: false,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      state = BookingStateSuccess(order);
    } catch (e) {
      state = BookingStateError(e.toString());
    }
  }

  /// 創建預約（原有的 Firestore 方法，已棄用）
  ///
  /// ⚠️ 已棄用：此方法違反 CQRS 架構原則
  /// 請使用 [createBookingWithSupabase] 方法
  @Deprecated('請使用 createBookingWithSupabase 方法')
  Future<void> createBooking(BookingRequest request) async {
    state = const BookingStateLoading();

    try {
      // ignore: deprecated_member_use
      final order = await _bookingService.createBooking(request);
      state = BookingStateSuccess(order);
    } catch (e) {
      state = BookingStateError(e.toString());
    }
  }

  /// 支付訂金（使用 Supabase API）
  ///
  /// 返回支付結果，包含 paymentUrl（如果需要跳轉）
  Future<Map<String, dynamic>> payDepositWithSupabase(String bookingId, String paymentMethod) async {
    state = const BookingStateLoading();

    try {
      final result = await _bookingService.payDepositWithSupabase(bookingId, paymentMethod);

      // 如果是自動支付，等待支付完成
      if (result['isAutoPayment'] == true) {
        final estimatedTime = result['estimatedProcessingTime'] ?? 2;
        await Future.delayed(Duration(seconds: estimatedTime + 1));
      }

      // 更新當前狀態中的訂單（如果存在）
      final currentState = state;
      if (currentState is BookingStateSuccess) {
        final updatedOrder = currentState.order.copyWith(
          depositPaid: true,
          status: BookingStatus.matched, // 支付成功後變為已配對狀態
        );
        state = BookingStateSuccess(updatedOrder);
      }

      // ✅ 返回支付結果（包含 paymentUrl 等資訊）
      return result;
    } catch (e) {
      state = BookingStateError(e.toString());
      rethrow;  // ✅ 重新拋出異常，讓調用方處理
    }
  }

  /// 支付訂金（原有的 Firestore 方法，已棄用）
  ///
  /// ⚠️ 已棄用：此方法違反 CQRS 架構原則
  /// 請使用 [payDepositWithSupabase] 方法
  @Deprecated('請使用 payDepositWithSupabase 方法')
  Future<void> payDeposit(String orderId) async {
    state = const BookingStateLoading();

    try {
      // ignore: deprecated_member_use
      await _bookingService.payDeposit(orderId);
      // 重新獲取訂單資訊
      final order = await _bookingService.getBooking(orderId);
      if (order != null) {
        state = BookingStateSuccess(order);
      } else {
        state = const BookingStateError('訂單不存在');
      }
    } catch (e) {
      state = BookingStateError(e.toString());
    }
  }

  /// 取消預約（使用 Supabase API）
  Future<void> cancelBookingWithSupabase(String bookingId, String reason) async {
    state = const BookingStateLoading();

    try {
      await _bookingService.cancelBookingWithSupabase(bookingId, reason);

      // 更新當前狀態中的訂單（如果存在）
      final currentState = state;
      if (currentState is BookingStateSuccess) {
        final updatedOrder = currentState.order.copyWith(
          status: BookingStatus.cancelled,
        );
        state = BookingStateSuccess(updatedOrder);
      }
    } catch (e) {
      state = BookingStateError(e.toString());
    }
  }

  /// 取消預約（原有的 Firestore 方法，已棄用）
  ///
  /// ⚠️ 已棄用：此方法違反 CQRS 架構原則
  /// 請使用 [cancelBookingWithSupabase] 方法
  @Deprecated('請使用 cancelBookingWithSupabase 方法')
  Future<void> cancelBooking(String orderId) async {
    state = const BookingStateLoading();

    try {
      // ignore: deprecated_member_use
      await _bookingService.cancelBooking(orderId);
      // 重新獲取訂單資訊
      final order = await _bookingService.getBooking(orderId);
      if (order != null) {
        state = BookingStateSuccess(order);
      } else {
        state = const BookingStateError('訂單不存在');
      }
    } catch (e) {
      state = BookingStateError(e.toString());
    }
  }

  /// 重置狀態
  void reset() {
    state = const BookingStateInitial();
  }
}

/// 預約狀態 Provider
final bookingStateProvider = StateNotifierProvider<BookingStateNotifier, BookingState>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  return BookingStateNotifier(bookingService);
});

/// 用戶訂單列表 Provider
final userBookingsProvider = StreamProvider<List<BookingOrder>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getUserBookings();
});

/// 進行中訂單 Provider
final activeBookingsProvider = StreamProvider<List<BookingOrder>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getActiveBookings();
});

/// 歷史訂單 Provider（客戶端）
final completedBookingsProvider = StreamProvider<List<BookingOrder>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getUserCompletedBookings();
});

/// 特定訂單 Provider
final bookingProvider = StreamProvider.family<BookingOrder?, String>((ref, orderId) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.watchBooking(orderId);
});

/// 當前預約請求狀態
class BookingRequestState {
  final String? pickupAddress;
  final LocationPoint? pickupLocation;
  final String? dropoffAddress;
  final LocationPoint? dropoffLocation;
  final DateTime? bookingTime;
  final int passengerCount;
  final int? luggageCount;
  final String? notes;
  final String? packageId;
  final String? packageName;
  final double? estimatedFare;

  const BookingRequestState({
    this.pickupAddress,
    this.pickupLocation,
    this.dropoffAddress,
    this.dropoffLocation,
    this.bookingTime,
    this.passengerCount = 1,
    this.luggageCount,
    this.notes,
    this.packageId,
    this.packageName,
    this.estimatedFare,
  });

  BookingRequestState copyWith({
    String? pickupAddress,
    LocationPoint? pickupLocation,
    String? dropoffAddress,
    LocationPoint? dropoffLocation,
    DateTime? bookingTime,
    int? passengerCount,
    int? luggageCount,
    String? notes,
    String? packageId,
    String? packageName,
    double? estimatedFare,
  }) {
    return BookingRequestState(
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      bookingTime: bookingTime ?? this.bookingTime,
      passengerCount: passengerCount ?? this.passengerCount,
      luggageCount: luggageCount ?? this.luggageCount,
      notes: notes ?? this.notes,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      estimatedFare: estimatedFare ?? this.estimatedFare,
    );
  }

  bool get isValid {
    return pickupAddress != null &&
           pickupLocation != null &&
           dropoffAddress != null &&
           dropoffLocation != null &&
           bookingTime != null &&
           passengerCount > 0;
  }

  BookingRequest toBookingRequest() {
    if (!isValid) {
      throw Exception('預約資訊不完整');
    }

    // ✅ 修復：包含套餐資訊（packageId, packageName, estimatedFare）
    // 確保客戶選擇的套餐價格正確傳遞到 Backend
    return BookingRequest(
      pickupAddress: pickupAddress!,
      pickupLocation: pickupLocation!,
      dropoffAddress: dropoffAddress!,
      dropoffLocation: dropoffLocation!,
      bookingTime: bookingTime!,
      passengerCount: passengerCount,
      luggageCount: luggageCount,
      notes: notes,
      packageId: packageId,           // ✅ 添加套餐 ID
      packageName: packageName,       // ✅ 添加套餐名稱
      estimatedFare: estimatedFare,   // ✅ 添加套餐價格
    );
  }
}

/// 預約請求狀態 Notifier
class BookingRequestNotifier extends StateNotifier<BookingRequestState> {
  BookingRequestNotifier() : super(const BookingRequestState());

  void updatePickup(String address, LocationPoint location) {
    state = state.copyWith(
      pickupAddress: address,
      pickupLocation: location,
    );
  }

  void updateDropoff(String address, LocationPoint location) {
    state = state.copyWith(
      dropoffAddress: address,
      dropoffLocation: location,
    );
  }

  void updateBookingTime(DateTime time) {
    state = state.copyWith(bookingTime: time);
  }

  void updatePassengerCount(int count) {
    state = state.copyWith(passengerCount: count);
  }

  void updateLuggageCount(int? count) {
    state = state.copyWith(luggageCount: count);
  }

  void updateNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void updatePackage({
    required String packageId,
    required String packageName,
    required double estimatedFare,
  }) {
    state = state.copyWith(
      packageId: packageId,
      packageName: packageName,
      estimatedFare: estimatedFare,
    );
  }

  void reset() {
    state = const BookingRequestState();
  }
}

/// 預約請求狀態 Provider
final bookingRequestProvider = StateNotifierProvider<BookingRequestNotifier, BookingRequestState>((ref) {
  return BookingRequestNotifier();
});
