import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_booking_app/core/models/booking_order.dart';
import 'package:ride_booking_app/shared/providers/booking_provider.dart';

/// 司機的所有訂單列表 Provider
final driverBookingsProvider = StreamProvider<List<BookingOrder>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getDriverBookings();
});

/// 司機的進行中訂單列表 Provider
final driverActiveBookingsProvider = StreamProvider<List<BookingOrder>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getDriverActiveBookings();
});

/// 司機的歷史訂單列表 Provider
final driverCompletedBookingsProvider = StreamProvider<List<BookingOrder>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getDriverCompletedBookings();
});

