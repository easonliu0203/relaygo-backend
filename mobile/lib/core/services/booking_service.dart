import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_order.dart';
import '../config/environment_config.dart';

/// 預約服務類
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Backend API 基礎 URL
  ///
  /// ✅ 使用 EnvironmentConfig 自動根據環境選擇正確的 URL：
  /// - Development: http://10.0.2.2:3001/api (Android 模擬器) 或 http://localhost:3001/api (iOS 模擬器)
  /// - Staging: https://api.relaygo.pro/api (Railway Backend)
  /// - Production: https://api.relaygo.pro/api (Railway Backend)
  String get _baseUrl => EnvironmentConfig.apiBaseUrl;

  /// 獲取當前用戶 ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// 創建新的預約訂單
  ///
  /// ⚠️ 已棄用：此方法違反 CQRS 架構原則，直接寫入 Firestore
  /// 請使用 [createBookingWithSupabase] 方法，通過 Supabase API 創建訂單
  ///
  /// 違反原因：
  /// - 繞過 Supabase（單一真實源）
  /// - 無法觸發 Outbox Pattern 同步
  /// - 造成資料不一致
  @Deprecated('請使用 createBookingWithSupabase 方法')
  Future<BookingOrder> createBooking(BookingRequest request) async {
    throw Exception(
      '此方法已棄用，違反 CQRS 架構原則。\n'
      '請使用 createBookingWithSupabase() 方法。\n'
      '所有寫入操作必須通過 Supabase API。'
    );
  }

  /// 創建新的預約訂單（使用 Supabase API）
  Future<Map<String, dynamic>> createBookingWithSupabase(BookingRequest request) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final url = '$_baseUrl/bookings';
      debugPrint('[BookingService] 開始創建訂單');
      debugPrint('[BookingService] 請求 URL: $url');

      final requestBody = {
        'customerUid': user.uid,
        'pickupAddress': request.pickupAddress ?? '',
        'pickupLatitude': request.pickupLocation.latitude,
        'pickupLongitude': request.pickupLocation.longitude,
        'dropoffAddress': request.dropoffAddress ?? '',
        'dropoffLatitude': request.dropoffLocation.latitude,
        'dropoffLongitude': request.dropoffLocation.longitude,
        'bookingTime': request.bookingTime.toIso8601String(),
        'passengerCount': request.passengerCount,
        'luggageCount': request.luggageCount ?? 0,
        'notes': request.notes ?? '',
        'packageId': request.packageId ?? '',
        'packageName': request.packageName ?? '',
        'estimatedFare': request.estimatedFare ?? 0.0,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      debugPrint('[BookingService] 響應狀態碼: ${response.statusCode}');
      debugPrint('[BookingService] 響應 Content-Type: ${response.headers['content-type']}');
      final bodyPreview = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
      debugPrint('[BookingService] 響應內容: $bodyPreview');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final bookingData = data['data'];
          debugPrint('[BookingService] API 返回訂單 ID: ${bookingData['id']}');

          // 資料將由 Supabase Trigger 自動鏡像到 Firestore
          // 不再從客戶端直接寫入 Firebase

          return bookingData;
        } else {
          throw Exception(data['error'] ?? '創建訂單失敗');
        }
      } else {
        // 檢查是否為 JSON 響應
        if (response.headers['content-type']?.contains('application/json') == true) {
          try {
            final errorData = json.decode(response.body);
            throw Exception(errorData['error'] ?? '創建訂單失敗');
          } catch (e) {
            if (e is FormatException) {
              throw Exception('API 返回無效的 JSON (${response.statusCode})');
            }
            rethrow;
          }
        } else {
          // 非 JSON 響應（可能是 HTML 錯誤頁面）
          throw Exception('API 返回非 JSON 響應 (${response.statusCode})，請檢查管理後台是否正常運行');
        }
      }
    } catch (e) {
      debugPrint('[BookingService] 創建預約失敗: $e');
      throw Exception('創建預約失敗: $e');
    }
  }

  /// 支付訂金（使用 Supabase API）
  Future<Map<String, dynamic>> payDepositWithSupabase(String bookingId, String paymentMethod) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final url = '$_baseUrl/bookings/$bookingId/pay-deposit';
      debugPrint('[BookingService] 開始支付訂金: $bookingId');
      debugPrint('[BookingService] 請求 URL: $url');

      final requestBody = {
        'paymentMethod': paymentMethod,
        'customerUid': user.uid,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      debugPrint('[BookingService] 響應狀態碼: ${response.statusCode}');
      debugPrint('[BookingService] 響應 Content-Type: ${response.headers['content-type']}');
      debugPrint('[BookingService] 完整響應內容: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('[BookingService] 支付成功');
          debugPrint('[BookingService] 返回數據: ${data['data']}');

          // 資料將由 Supabase Trigger 自動鏡像到 Firestore
          // 不再從客戶端直接寫入 Firebase

          return data['data'];
        } else {
          throw Exception(data['error'] ?? '支付失敗');
        }
      } else {
        // 檢查是否為 JSON 響應
        if (response.headers['content-type']?.contains('application/json') == true) {
          try {
            final errorData = json.decode(response.body);
            throw Exception(errorData['error'] ?? '支付失敗');
          } catch (e) {
            if (e is FormatException) {
              throw Exception('API 返回無效的 JSON (${response.statusCode})');
            }
            rethrow;
          }
        } else {
          // 非 JSON 響應（可能是 HTML 錯誤頁面）
          throw Exception('API 返回非 JSON 響應 (${response.statusCode})，請檢查管理後台是否正常運行');
        }
      }
    } catch (e) {
      debugPrint('[BookingService] 支付訂金失敗: $e');
      throw Exception('支付訂金失敗: $e');
    }
  }

  /// 支付訂金（封測階段模擬支付）
  ///
  /// ⚠️ 已棄用：此方法違反 CQRS 架構原則，直接寫入 Firestore
  /// 請使用 [payDepositWithSupabase] 方法，通過 Supabase API 支付訂金
  ///
  /// 違反原因：
  /// - 繞過 Supabase（單一真實源）
  /// - 無法觸發 Outbox Pattern 同步
  /// - 造成資料不一致
  @Deprecated('請使用 payDepositWithSupabase 方法')
  Future<void> payDeposit(String orderId) async {
    throw Exception(
      '此方法已棄用，違反 CQRS 架構原則。\n'
      '請使用 payDepositWithSupabase() 方法。\n'
      '所有寫入操作必須通過 Supabase API。'
    );
  }

  /// 取消訂單（使用 Supabase API）
  Future<Map<String, dynamic>> cancelBookingWithSupabase(
    String bookingId,
    String reason,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      final url = '$_baseUrl/bookings/$bookingId/cancel';
      debugPrint('[BookingService] 開始取消訂單: $bookingId');
      debugPrint('[BookingService] 請求 URL: $url');

      final requestBody = {
        'customerUid': user.uid,
        'reason': reason,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      debugPrint('[BookingService] 響應狀態碼: ${response.statusCode}');
      debugPrint('[BookingService] 響應 Content-Type: ${response.headers['content-type']}');
      final bodyPreview = response.body.length > 200
          ? response.body.substring(0, 200)
          : response.body;
      debugPrint('[BookingService] 響應內容: $bodyPreview');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('[BookingService] 取消成功');

          // 資料將由 Supabase Trigger 自動鏡像到 Firestore
          // 不再從客戶端直接寫入 Firebase

          return data['data'];
        } else {
          throw Exception(data['error'] ?? '取消訂單失敗');
        }
      } else {
        // 檢查是否為 JSON 響應
        if (response.headers['content-type']?.contains('application/json') == true) {
          try {
            final errorData = json.decode(response.body);
            throw Exception(errorData['error'] ?? '取消訂單失敗');
          } catch (e) {
            if (e is FormatException) {
              throw Exception('API 返回無效的 JSON (${response.statusCode})');
            }
            rethrow;
          }
        } else {
          // 非 JSON 響應（可能是 HTML 錯誤頁面）
          throw Exception('API 返回非 JSON 響應 (${response.statusCode})，請檢查管理後台是否正常運行');
        }
      }
    } catch (e) {
      debugPrint('[BookingService] 取消訂單失敗: $e');
      throw Exception('取消訂單失敗: $e');
    }
  }

  /// 取消訂單
  ///
  /// ⚠️ 已棄用：此方法違反 CQRS 架構原則，直接寫入 Firestore
  /// 請使用 [cancelBookingWithSupabase] 方法，通過 Supabase API 取消訂單
  ///
  /// 違反原因：
  /// - 繞過 Supabase（單一真實源）
  /// - 無法觸發 Outbox Pattern 同步
  /// - 造成資料不一致
  @Deprecated('請使用 cancelBookingWithSupabase 方法')
  Future<void> cancelBooking(String orderId) async {
    throw Exception(
      '此方法已棄用，違反 CQRS 架構原則。\n'
      '請使用 cancelBookingWithSupabase() 方法。\n'
      '所有寫入操作必須通過 Supabase API。'
    );
  }

  /// 獲取用戶的訂單列表（從 Firestore 鏡像讀取）
  /// 用於即時畫面展示，資料來自 Supabase 的單向鏡像
  Stream<List<BookingOrder>> getUserBookings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // 從 orders_rt 鏡像集合讀取（Read-Only）
    return _firestore
        .collection('orders_rt')
        .where('customerId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingOrder.fromFirestore(doc))
            .toList());
  }

  /// 獲取特定訂單（從 Firestore 鏡像讀取）
  /// 用於即時畫面展示，資料來自 Supabase 的單向鏡像
  Future<BookingOrder?> getBooking(String orderId) async {
    // 從 orders_rt 鏡像集合讀取（Read-Only）
    final doc = await _firestore
        .collection('orders_rt')
        .doc(orderId)
        .get();

    if (!doc.exists) return null;

    return BookingOrder.fromFirestore(doc);
  }

  /// 從 Supabase 直接獲取訂單（用於支付後驗證）
  ///
  /// 這個方法直接從 Supabase（單一真實源）讀取訂單狀態，
  /// 用於支付完成後立即驗證訂單狀態是否已更新。
  ///
  /// 注意：這是讀取操作，符合 CQRS 架構原則。
  Future<BookingOrder?> getBookingFromSupabase(String bookingId) async {
    try {
      final supabase = Supabase.instance.client;

      // 從 Supabase bookings 表直接查詢
      final response = await supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ 訂單不存在: $bookingId');
        return null;
      }

      // 將 Supabase 資料轉換為 BookingOrder
      return _convertSupabaseToBookingOrder(response);
    } catch (e) {
      debugPrint('❌ 從 Supabase 獲取訂單失敗: $e');
      return null;
    }
  }

  /// 將 Supabase 資料轉換為 BookingOrder 模型
  BookingOrder _convertSupabaseToBookingOrder(Map<String, dynamic> data) {
    // 解析時間戳
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    DateTime? parseOptionalTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return null;
    }

    // 解析地理位置
    LocationPoint? parseLocation(dynamic lat, dynamic lng) {
      if (lat == null || lng == null) return null;
      return LocationPoint(
        latitude: (lat as num).toDouble(),
        longitude: (lng as num).toDouble(),
      );
    }

    return BookingOrder(
      id: data['id'] ?? '',
      customerId: data['customer_id'] ?? '',
      driverId: data['driver_id'],
      customerName: data['customer_name'],
      customerPhone: data['customer_phone'],
      driverName: data['driver_name'],
      driverPhone: data['driver_phone'],
      driverVehiclePlate: data['driver_vehicle_plate'],
      driverVehicleModel: data['driver_vehicle_model'],
      driverRating: data['driver_rating'] != null
          ? (data['driver_rating'] as num).toDouble()
          : null,
      pickupAddress: data['pickup_location'] ?? '',
      pickupLocation: parseLocation(
        data['pickup_latitude'],
        data['pickup_longitude'],
      ),
      dropoffAddress: data['destination'] ?? '',
      dropoffLocation: parseLocation(
        data['dropoff_latitude'],
        data['dropoff_longitude'],
      ),
      bookingTime: parseTimestamp(data['start_date'] ?? data['created_at']),
      passengerCount: data['passenger_count'] ?? 1,
      luggageCount: data['luggage_count'],
      notes: data['notes'],
      estimatedFare: (data['total_price'] ?? 0.0).toDouble(),
      depositAmount: (data['deposit_amount'] ?? 0.0).toDouble(),
      depositPaid: data['deposit_paid'] ?? false,
      status: BookingStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: parseTimestamp(data['created_at']),
      matchedAt: parseOptionalTimestamp(data['matched_at']),
      completedAt: parseOptionalTimestamp(data['completed_at']),
    );
  }

  /// 監聽特定訂單的變化（從 Firestore 鏡像讀取）
  /// 用於即時畫面展示，資料來自 Supabase 的單向鏡像
  Stream<BookingOrder?> watchBooking(String orderId) {
    // 從 orders_rt 鏡像集合讀取（Read-Only）
    return _firestore
        .collection('orders_rt')
        .doc(orderId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return BookingOrder.fromFirestore(doc);
        });
  }

  /// 獲取進行中的訂單（從 Firestore 鏡像讀取）
  /// 用於即時畫面展示，資料來自 Supabase 的單向鏡像
  ///
  /// 進行中訂單包含以下狀態：
  /// - pending: 待配對（待付訂金或待派單）
  /// - awaitingDriver: 待司機確認（已分配司機，等待司機確認接單）
  /// - matched: 已配對（司機已確認接單）
  /// - inProgress: 行程進行中
  /// - awaitingBalance: 待付尾款（行程已結束，等待支付尾款）
  Stream<List<BookingOrder>> getActiveBookings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // 從 orders_rt 鏡像集合讀取（Read-Only）
    return _firestore
        .collection('orders_rt')
        .where('customerId', isEqualTo: currentUserId)
        .where('status', whereIn: [
          BookingStatus.pending.name,
          BookingStatus.awaitingDriver.name,      // ⭐ 新增：待司機確認
          BookingStatus.matched.name,
          BookingStatus.inProgress.name,
          BookingStatus.awaitingBalance.name,     // ⭐ 新增：待付尾款
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingOrder.fromFirestore(doc))
            .toList());
  }

  /// 獲取司機的訂單列表（從 Firestore 鏡像讀取）
  /// 用於司機端即時畫面展示，資料來自 Supabase 的單向鏡像
  Stream<List<BookingOrder>> getDriverBookings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // 從 orders_rt 鏡像集合讀取（Read-Only）
    // 查詢 driverId 等於當前司機的訂單
    return _firestore
        .collection('orders_rt')
        .where('driverId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingOrder.fromFirestore(doc))
            .toList());
  }

  /// 獲取司機的進行中訂單（從 Firestore 鏡像讀取）
  /// 用於司機端即時畫面展示，資料來自 Supabase 的單向鏡像
  ///
  /// 進行中訂單包含以下狀態：
  /// - pending: 待配對（司機可以看到待接單的訂單）
  /// - awaitingDriver: 待司機確認（已分配司機，等待司機確認接單）
  /// - matched: 已配對（司機已確認接單）
  /// - inProgress: 行程進行中
  /// - awaitingBalance: 待付尾款（行程已結束，等待客戶支付尾款）
  ///
  /// 不包含：
  /// - completed: 已完成
  /// - cancelled: 已取消
  Stream<List<BookingOrder>> getDriverActiveBookings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // 從 orders_rt 鏡像集合讀取（Read-Only）
    // 查詢 driverId 等於當前司機且狀態為進行中的訂單
    // ✅ 修復：包含所有未完成且未取消的訂單狀態
    return _firestore
        .collection('orders_rt')
        .where('driverId', isEqualTo: currentUserId)
        .where('status', whereIn: [
          BookingStatus.pending.name,
          BookingStatus.awaitingDriver.name,      // ⭐ 新增：待司機確認
          BookingStatus.matched.name,
          BookingStatus.inProgress.name,
          BookingStatus.awaitingBalance.name,     // ⭐ 新增：待付尾款
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingOrder.fromFirestore(doc))
            .toList());
  }

  /// 獲取司機的歷史訂單（從 Firestore 鏡像讀取）
  /// 用於司機端即時畫面展示，資料來自 Supabase 的單向鏡像
  ///
  /// 歷史訂單只包含以下狀態：
  /// - completed: 已完成
  /// - cancelled: 已取消
  Stream<List<BookingOrder>> getDriverCompletedBookings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // 從 orders_rt 鏡像集合讀取（Read-Only）
    // 查詢 driverId 等於當前司機且狀態為已完成或已取消的訂單
    return _firestore
        .collection('orders_rt')
        .where('driverId', isEqualTo: currentUserId)
        .where('status', whereIn: [
          BookingStatus.completed.name,
          BookingStatus.cancelled.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingOrder.fromFirestore(doc))
            .toList());
  }

  /// 獲取客戶的歷史訂單（從 Firestore 鏡像讀取）
  /// 用於客戶端即時畫面展示，資料來自 Supabase 的單向鏡像
  ///
  /// 歷史訂單只包含以下狀態：
  /// - completed: 已完成
  /// - cancelled: 已取消
  Stream<List<BookingOrder>> getUserCompletedBookings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    // 從 orders_rt 鏡像集合讀取（Read-Only）
    // 查詢 customerId 等於當前客戶且狀態為已完成或已取消的訂單
    return _firestore
        .collection('orders_rt')
        .where('customerId', isEqualTo: currentUserId)
        .where('status', whereIn: [
          BookingStatus.completed.name,
          BookingStatus.cancelled.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingOrder.fromFirestore(doc))
            .toList());
  }

  /// 司機確認接單（使用 Backend API）
  ///
  /// 流程：
  /// 1. 調用 Backend API: POST /api/booking-flow/bookings/:bookingId/accept
  /// 2. Backend 驗證司機權限
  /// 3. Backend 更新訂單狀態為 driver_confirmed
  /// 4. Backend 自動創建聊天室
  /// 5. Supabase Trigger 自動鏡像到 Firestore
  ///
  /// 參數：
  /// - [bookingId] 訂單 ID
  ///
  /// 返回：
  /// - 更新後的訂單資料
  ///
  /// 異常：
  /// - 用戶未登入
  /// - 司機無權限（不是被分配的司機）
  /// - 訂單狀態不正確
  /// - API 調用失敗
  Future<Map<String, dynamic>> driverAcceptBooking(String bookingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      // 🔍 詳細日誌
      debugPrint('[BookingService] ========== 開始確認接單 ==========');
      debugPrint('[BookingService] bookingId: $bookingId');
      debugPrint('[BookingService] driverUid: ${user.uid}');
      debugPrint('[BookingService] _baseUrl: $_baseUrl');

      // 調用 Backend API
      final url = '$_baseUrl/booking-flow/bookings/$bookingId/accept';
      debugPrint('[BookingService] 完整 URL: $url');

      final requestBody = {
        'driverUid': user.uid,
      };
      debugPrint('[BookingService] 請求體: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      // 🔍 詳細響應日誌
      debugPrint('[BookingService] 響應狀態碼: ${response.statusCode}');
      debugPrint('[BookingService] Content-Type: ${response.headers['content-type']}');
      debugPrint('[BookingService] 響應內容前 200 字符: ${response.body.substring(0, min(200, response.body.length))}');

      // 🔍 檢查 Content-Type
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        throw Exception('收到非 JSON 響應（Content-Type: $contentType）。可能打到錯誤的服務或端口。響應內容: ${response.body.substring(0, min(200, response.body.length))}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('[BookingService] ✅ 司機確認接單成功');
          debugPrint('[BookingService] 聊天室資訊: ${data['data']['chatRoom']}');

          // 聊天室將由 Backend API 或 Edge Function 創建
          // 不再從客戶端直接寫入 Firestore

          return data['data'];
        } else {
          throw Exception(data['error'] ?? '確認接單失敗');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? '確認接單失敗');
      }
    } catch (e) {
      debugPrint('[BookingService] ========== 確認接單失敗 ==========');
      debugPrint('[BookingService] 錯誤詳情: $e');
      rethrow;
    }
  }

  /// 司機出發前往載客
  ///
  /// 功能：
  /// 1. 調用 Backend API 更新訂單狀態為 driver_departed
  /// 2. Backend 會自動發送系統訊息到聊天室
  /// 3. Supabase Trigger 自動鏡像到 Firestore
  ///
  /// 參數：
  /// - [bookingId] 訂單 ID
  ///
  /// 返回：
  /// - 更新後的訂單資料
  ///
  /// 異常：
  /// - 用戶未登入
  /// - 司機無權限（不是被分配的司機）
  /// - 訂單狀態不正確
  /// - API 調用失敗
  Future<Map<String, dynamic>> driverDepart(String bookingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      debugPrint('[BookingService] 司機出發: bookingId=$bookingId');

      final url = '$_baseUrl/booking-flow/bookings/$bookingId/depart';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'driverUid': user.uid}),
      );

      debugPrint('[BookingService] 響應狀態碼: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('[BookingService] ✅ 司機出發成功');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? '出發失敗');
      }
    } catch (e) {
      debugPrint('[BookingService] ❌ 司機出發失敗: $e');
      rethrow;
    }
  }

  /// 司機到達上車地點
  ///
  /// 功能：
  /// 1. 調用 Backend API 更新訂單狀態為 driver_arrived
  /// 2. Backend 會自動發送系統訊息到聊天室
  /// 3. Supabase Trigger 自動鏡像到 Firestore
  ///
  /// 參數：
  /// - [bookingId] 訂單 ID
  ///
  /// 返回：
  /// - 更新後的訂單資料
  ///
  /// 異常：
  /// - 用戶未登入
  /// - 司機無權限（不是被分配的司機）
  /// - 訂單狀態不正確
  /// - API 調用失敗
  Future<Map<String, dynamic>> driverArrive(String bookingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      debugPrint('[BookingService] 司機到達: bookingId=$bookingId');

      final url = '$_baseUrl/booking-flow/bookings/$bookingId/arrive';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'driverUid': user.uid}),
      );

      debugPrint('[BookingService] 響應狀態碼: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('[BookingService] ✅ 司機到達成功');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? '到達失敗');
      }
    } catch (e) {
      debugPrint('[BookingService] ❌ 司機到達失敗: $e');
      rethrow;
    }
  }

  /// 客戶開始行程
  ///
  /// 功能：
  /// 1. 調用 Backend API 更新訂單狀態為 trip_started
  /// 2. Backend 會自動發送系統訊息到聊天室
  /// 3. Supabase Trigger 自動鏡像到 Firestore
  ///
  /// 參數：
  /// - [bookingId] 訂單 ID
  ///
  /// 返回：
  /// - 更新後的訂單資料
  ///
  /// 異常：
  /// - 用戶未登入
  /// - 客戶無權限（不是該訂單的客戶）
  /// - 訂單狀態不正確
  /// - API 調用失敗
  Future<Map<String, dynamic>> startTrip(String bookingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      debugPrint('[BookingService] 客戶開始行程: bookingId=$bookingId');

      final url = '$_baseUrl/booking-flow/bookings/$bookingId/start-trip';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'customerUid': user.uid}),
      );

      debugPrint('[BookingService] 響應狀態碼: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('[BookingService] ✅ 開始行程成功');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? '開始行程失敗');
      }
    } catch (e) {
      debugPrint('[BookingService] ❌ 開始行程失敗: $e');
      rethrow;
    }
  }

  /// 客戶結束行程
  ///
  /// 功能：
  /// 1. 調用 Backend API 更新訂單狀態為 trip_ended
  /// 2. Backend 會自動發送系統訊息到聊天室
  /// 3. Supabase Trigger 自動鏡像到 Firestore
  ///
  /// 參數：
  /// - [bookingId] 訂單 ID
  ///
  /// 返回：
  /// - 更新後的訂單資料
  ///
  /// 異常：
  /// - 用戶未登入
  /// - 客戶無權限（不是該訂單的客戶）
  /// - 訂單狀態不正確
  /// - API 調用失敗
  Future<Map<String, dynamic>> endTrip(String bookingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      debugPrint('[BookingService] 客戶結束行程: bookingId=$bookingId');

      final url = '$_baseUrl/booking-flow/bookings/$bookingId/end-trip';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'customerUid': user.uid}),
      );

      debugPrint('[BookingService] 響應狀態碼: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('[BookingService] ✅ 結束行程成功');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? '結束行程失敗');
      }
    } catch (e) {
      debugPrint('[BookingService] ❌ 結束行程失敗: $e');
      rethrow;
    }
  }

  /// 支付尾款（使用 Supabase API）
  ///
  /// 功能：
  /// 1. 調用 Backend API 處理尾款支付
  /// 2. 創建支付記錄到 payments 表
  /// 3. 更新訂單狀態為 completed
  /// 4. Backend 會自動發送系統訊息到聊天室
  /// 5. Supabase Trigger 自動鏡像到 Firestore
  ///
  /// 參數：
  /// - [bookingId] 訂單 ID
  /// - [paymentMethod] 支付方式（credit_card, cash, etc.）
  ///
  /// 返回：
  /// - 支付結果資料（包含 paymentId, transactionId, amount 等）
  ///
  /// 異常：
  /// - 用戶未登入
  /// - 客戶無權限（不是該訂單的客戶）
  /// - 訂單狀態不正確（需要 trip_ended）
  /// - 尾款金額錯誤
  /// - API 調用失敗
  Future<Map<String, dynamic>> payBalance(String bookingId, String paymentMethod) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      debugPrint('[BookingService] 開始支付尾款: bookingId=$bookingId');
      debugPrint('[BookingService] 支付方式: $paymentMethod');

      final url = '$_baseUrl/booking-flow/bookings/$bookingId/pay-balance';
      final requestBody = {
        'paymentMethod': paymentMethod,
        'customerUid': user.uid,
      };

      debugPrint('[BookingService] 請求 URL: $url');
      debugPrint('[BookingService] 請求內容: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('[BookingService] 響應狀態碼: ${response.statusCode}');
      debugPrint('[BookingService] 響應內容: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          debugPrint('[BookingService] ✅ 尾款支付成功');
          debugPrint('[BookingService] 支付 ID: ${data['data']['paymentId']}');
          debugPrint('[BookingService] 交易 ID: ${data['data']['transactionId']}');
          debugPrint('[BookingService] 金額: ${data['data']['amount']}');
          return data['data'];
        } else {
          throw Exception(data['error'] ?? '支付尾款失敗');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? '支付尾款失敗');
      }
    } catch (e) {
      debugPrint('[BookingService] ❌ 支付尾款失敗: $e');
      throw Exception('支付尾款失敗: $e');
    }
  }

  /// 計算預估費用（簡化版本）
  double _calculateEstimatedFare(
    LocationPoint pickup,
    LocationPoint dropoff,
    int passengerCount,
  ) {
    // 簡化的費用計算邏輯
    // 實際應該考慮距離、時間、交通狀況等因素

    // 計算直線距離（公里）
    final distance = _calculateDistance(pickup, dropoff);

    // 基本費用：起步價 100 元
    double fare = 100.0;

    // 距離費用：每公里 15 元
    fare += distance * 15.0;

    // 人數加成：超過 2 人每人加 20 元
    if (passengerCount > 2) {
      fare += (passengerCount - 2) * 20.0;
    }

    // 最低費用 150 元
    return fare < 150.0 ? 150.0 : fare;
  }

  /// 計算兩點間的直線距離（公里）
  double _calculateDistance(LocationPoint point1, LocationPoint point2) {
    // 使用 Haversine 公式計算地球表面兩點間的距離
    const double earthRadius = 6371.0; // 地球半徑（公里）
    
    final double lat1Rad = point1.latitude * (3.14159265359 / 180.0);
    final double lat2Rad = point2.latitude * (3.14159265359 / 180.0);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180.0);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180.0);
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);

    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }
}

/// 預約服務異常
class BookingException implements Exception {
  final String message;
  const BookingException(this.message);

  @override
  String toString() => 'BookingException: $message';
}
