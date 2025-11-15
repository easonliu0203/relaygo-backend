import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_order.freezed.dart';
part 'booking_order.g.dart';

/// 訂單狀態枚舉
enum BookingStatus {
  @JsonValue('PENDING_PAYMENT')
  pendingPayment, // 待付訂金（客戶尚未支付訂金）

  @JsonValue('pending')
  pending,        // 待配對（已付訂金，等待派單）

  @JsonValue('awaitingDriver')
  awaitingDriver, // 待司機確認

  @JsonValue('matched')
  matched,        // 已配對

  @JsonValue('ON_THE_WAY')
  onTheWay,       // 正在路上（司機已出發或已到達）

  @JsonValue('inProgress')
  inProgress,     // 進行中

  @JsonValue('awaitingBalance')
  awaitingBalance, // 待付尾款

  @JsonValue('completed')
  completed,      // 已完成

  @JsonValue('cancelled')
  cancelled,      // 已取消
}

/// 訂單狀態擴展方法
extension BookingStatusExtension on BookingStatus {
  /// 獲取 Firestore 存儲的狀態值（對應 @JsonValue）
  String get firestoreValue {
    switch (this) {
      case BookingStatus.pendingPayment:
        return 'PENDING_PAYMENT';
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.awaitingDriver:
        return 'awaitingDriver';
      case BookingStatus.matched:
        return 'matched';
      case BookingStatus.onTheWay:
        return 'ON_THE_WAY';
      case BookingStatus.inProgress:
        return 'inProgress';
      case BookingStatus.awaitingBalance:
        return 'awaitingBalance';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pendingPayment:
        return '待付訂金';
      case BookingStatus.pending:
        return '待配對';
      case BookingStatus.awaitingDriver:
        return '待司機確認';
      case BookingStatus.matched:
        return '已配對';
      case BookingStatus.onTheWay:
        return '正在路上';
      case BookingStatus.inProgress:
        return '進行中';
      case BookingStatus.awaitingBalance:
        return '待付尾款';
      case BookingStatus.completed:
        return '已完成';
      case BookingStatus.cancelled:
        return '已取消';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pendingPayment:
        return const Color(0xFFFF5252); // 紅色（待付訂金，需要立即處理）
      case BookingStatus.pending:
        return const Color(0xFFFF9800); // 橙色
      case BookingStatus.awaitingDriver:
        return const Color(0xFFFFA726); // 淺橙色
      case BookingStatus.matched:
        return const Color(0xFF2196F3); // 藍色
      case BookingStatus.onTheWay:
        return const Color(0xFF03A9F4); // 淺藍色
      case BookingStatus.inProgress:
        return const Color(0xFF4CAF50); // 綠色
      case BookingStatus.awaitingBalance:
        return const Color(0xFFFFB74D); // 金色
      case BookingStatus.completed:
        return const Color(0xFF9E9E9E); // 灰色
      case BookingStatus.cancelled:
        return const Color(0xFFF44336); // 紅色
    }
  }
}

/// 地理位置模型
@freezed
class LocationPoint with _$LocationPoint {
  const factory LocationPoint({
    required double latitude,
    required double longitude,
  }) = _LocationPoint;

  const LocationPoint._();

  factory LocationPoint.fromJson(Map<String, dynamic> json) =>
      _$LocationPointFromJson(json);

  factory LocationPoint.fromGeoPoint(GeoPoint geoPoint) {
    return LocationPoint(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
    );
  }

  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }
}

/// 預約訂單模型
@freezed
class BookingOrder with _$BookingOrder {
  const factory BookingOrder({
    required String id,                    // 訂單編號
    required String customerId,            // 客戶 ID
    String? driverId,                      // 司機 ID（配對後）
    String? customerName,                  // 客戶姓名
    String? customerPhone,                 // 客戶電話
    String? driverName,                    // 司機姓名
    String? driverPhone,                   // 司機電話
    String? driverVehiclePlate,            // 司機車牌
    String? driverVehicleModel,            // 司機車型
    double? driverRating,                  // 司機評分
    required String pickupAddress,         // 上車地點
    LocationPoint? pickupLocation,         // 上車座標（可選，某些訂單可能缺少座標）
    required String dropoffAddress,        // 下車地點
    LocationPoint? dropoffLocation,        // 下車座標（可選，某些訂單可能缺少座標）
    required DateTime bookingTime,         // 預約時間
    required int passengerCount,           // 乘客人數
    int? luggageCount,                     // 行李數量
    String? notes,                         // 備註
    required double estimatedFare,         // 預估費用
    required double depositAmount,         // 訂金金額
    @Default(false) bool depositPaid,      // 訂金是否已支付
    @Default(0.0) double overtimeFee,      // 超時費用
    @Default(0.0) double tipAmount,        // 小費金額
    @Default(BookingStatus.pending) BookingStatus status, // 訂單狀態
    required DateTime createdAt,           // 建立時間
    DateTime? matchedAt,                   // 配對時間
    DateTime? completedAt,                 // 完成時間
  }) = _BookingOrder;

  const BookingOrder._();

  factory BookingOrder.fromJson(Map<String, dynamic> json) =>
      _$BookingOrderFromJson(json);

  /// 計算尾款金額
  double get balanceAmount => estimatedFare - depositAmount;

  /// 判斷尾款是否已支付（基於訂單狀態）
  /// 當訂單狀態為 completed 時，表示尾款已支付
  bool get balancePaid => status == BookingStatus.completed;

  /// 計算已支付總額（包含超時費和小費）
  double get totalPaid {
    if (balancePaid) {
      return estimatedFare + overtimeFee + tipAmount; // 訂金 + 尾款 + 超時費 + 小費 = 總額
    } else if (depositPaid) {
      return depositAmount; // 只支付了訂金
    } else {
      return 0.0; // 尚未支付
    }
  }

  /// 從 Firestore 文檔創建訂單
  factory BookingOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 解析 createdAt (必填欄位)
    final createdAt = _parseTimestamp(data['createdAt']);

    // 解析 bookingTime,如果為 null 則使用 createdAt 作為後備值
    // 這是為了處理某些訂單可能缺少 bookingTime 的情況
    final bookingTime = data['bookingTime'] != null
        ? _parseTimestamp(data['bookingTime'])
        : createdAt;

    return BookingOrder(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      driverId: data['driverId'],
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      driverVehiclePlate: data['driverVehiclePlate'],
      driverVehicleModel: data['driverVehicleModel'],
      driverRating: data['driverRating'] != null ? (data['driverRating'] as num).toDouble() : null,
      pickupAddress: data['pickupAddress'] ?? '',
      pickupLocation: _parseOptionalGeoPoint(data['pickupLocation']),
      dropoffAddress: data['dropoffAddress'] ?? '',
      dropoffLocation: _parseOptionalGeoPoint(data['dropoffLocation']),
      bookingTime: bookingTime,
      passengerCount: _parseInt(data['passengerCount'], defaultValue: 1),
      luggageCount: _parseOptionalInt(data['luggageCount']),
      notes: data['notes'],
      estimatedFare: (data['estimatedFare'] ?? 0.0).toDouble(),
      depositAmount: (data['depositAmount'] ?? 0.0).toDouble(),
      depositPaid: data['depositPaid'] ?? false,
      overtimeFee: (data['overtimeFee'] ?? 0.0).toDouble(),
      tipAmount: (data['tipAmount'] ?? 0.0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (status) => status.firestoreValue == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: createdAt,
      matchedAt: _parseOptionalTimestamp(data['matchedAt']),
      completedAt: _parseOptionalTimestamp(data['completedAt']),
    );
  }

  /// 解析時間戳 - 支持 Timestamp 和 String 兩種格式
  ///
  /// 這個方法用於處理 Firestore 資料格式的兼容性問題:
  /// - 新資料: Firestore Timestamp 格式 (由 Edge Function 正確轉換)
  /// - 舊資料: String 格式 (歷史遺留問題)
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) {
      throw ArgumentError('Timestamp cannot be null');
    }

    // 處理 Firestore Timestamp 格式 (正確格式)
    if (value is Timestamp) {
      return value.toDate();
    }

    // 處理 String 格式 (舊資料兼容)
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        throw ArgumentError('Invalid timestamp string format: $value');
      }
    }

    throw ArgumentError('Invalid timestamp format: ${value.runtimeType}');
  }

  /// 解析可選的時間戳 - 支持 null 值
  static DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value == null) return null;
    return _parseTimestamp(value);
  }

  /// 解析整數 - 支持 int 和 double 兩種格式
  ///
  /// 這個方法用於處理 Firestore 資料格式的兼容性問題:
  /// - 新資料: Firestore integerValue 格式 (由 Edge Function 正確轉換)
  /// - 舊資料: double 格式 (歷史遺留問題)
  ///
  /// [value] 要解析的值
  /// [defaultValue] 當值為 null 時的預設值
  static int _parseInt(dynamic value, {required int defaultValue}) {
    if (value == null) {
      return defaultValue;
    }

    // 處理整數格式 (正確格式)
    if (value is int) {
      return value;
    }

    // 處理 double 格式 (舊資料兼容)
    if (value is double) {
      return value.toInt();
    }

    // 處理 String 格式 (極少數情況)
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }

    return defaultValue;
  }

  /// 解析可選的整數 - 支持 null 值
  static int? _parseOptionalInt(dynamic value) {
    if (value == null) return null;
    return _parseInt(value, defaultValue: 0);
  }

  /// 解析 GeoPoint - 支持 GeoPoint 和 Map 兩種格式
  ///
  /// 這個方法用於處理 Firestore 資料格式的兼容性問題:
  /// - 新資料: Firestore GeoPoint 格式 (由 Edge Function 正確轉換)
  /// - 舊資料: Map 格式 (歷史遺留問題)
  ///
  /// [value] 要解析的值
  ///
  /// 注意: 此方法要求 value 不能為 null。如果需要支持 null 值,
  /// 請使用 [_parseOptionalGeoPoint] 方法。
  static LocationPoint _parseGeoPoint(dynamic value) {
    if (value == null) {
      throw ArgumentError('GeoPoint cannot be null. Use _parseOptionalGeoPoint for nullable values.');
    }

    // 處理 Firestore GeoPoint 格式 (正確格式)
    if (value is GeoPoint) {
      return LocationPoint.fromGeoPoint(value);
    }

    // 處理 Map 格式 (舊資料兼容)
    if (value is Map) {
      // 嘗試從 Map 中提取 latitude 和 longitude
      final map = value as Map<String, dynamic>;

      // 檢查是否包含 latitude 和 longitude 欄位
      if (map.containsKey('latitude') && map.containsKey('longitude')) {
        final lat = map['latitude'];
        final lng = map['longitude'];

        // 轉換為 double
        final latitude = lat is double ? lat : (lat is int ? lat.toDouble() : double.parse(lat.toString()));
        final longitude = lng is double ? lng : (lng is int ? lng.toDouble() : double.parse(lng.toString()));

        return LocationPoint(
          latitude: latitude,
          longitude: longitude,
        );
      }

      // 檢查是否包含 _latitude 和 _longitude 欄位 (可能的格式)
      if (map.containsKey('_latitude') && map.containsKey('_longitude')) {
        final lat = map['_latitude'];
        final lng = map['_longitude'];

        final latitude = lat is double ? lat : (lat is int ? lat.toDouble() : double.parse(lat.toString()));
        final longitude = lng is double ? lng : (lng is int ? lng.toDouble() : double.parse(lng.toString()));

        return LocationPoint(
          latitude: latitude,
          longitude: longitude,
        );
      }

      throw ArgumentError('Map does not contain valid latitude/longitude fields: $map');
    }

    throw ArgumentError('Invalid GeoPoint format: ${value.runtimeType}');
  }

  /// 解析可選的 GeoPoint - 支持 null 值
  ///
  /// 這個方法用於處理可選的地理位置欄位:
  /// - 如果 value 為 null,返回 null
  /// - 否則使用 [_parseGeoPoint] 解析
  ///
  /// [value] 要解析的值,可以為 null
  ///
  /// 背景說明:
  /// 根據 Supabase schema,pickup_latitude 和 pickup_longitude 是可選欄位。
  /// 某些訂單可能有地址但沒有座標 (例如地址解析失敗的情況)。
  static LocationPoint? _parseOptionalGeoPoint(dynamic value) {
    if (value == null) {
      return null;
    }
    return _parseGeoPoint(value);
  }

  /// 轉換為 Firestore 文檔
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': this.customerId,
      'driverId': this.driverId,
      'customerName': this.customerName,
      'customerPhone': this.customerPhone,
      'driverName': this.driverName,
      'driverPhone': this.driverPhone,
      'driverVehiclePlate': this.driverVehiclePlate,
      'driverVehicleModel': this.driverVehicleModel,
      'driverRating': this.driverRating,
      'pickupAddress': this.pickupAddress,
      'pickupLocation': this.pickupLocation?.toGeoPoint(),
      'dropoffAddress': this.dropoffAddress,
      'dropoffLocation': this.dropoffLocation?.toGeoPoint(),
      'bookingTime': Timestamp.fromDate(this.bookingTime),
      'passengerCount': this.passengerCount,
      'luggageCount': this.luggageCount,
      'notes': this.notes,
      'estimatedFare': this.estimatedFare,
      'depositAmount': this.depositAmount,
      'depositPaid': this.depositPaid,
      'status': this.status.name,
      'createdAt': Timestamp.fromDate(this.createdAt),
      'matchedAt': this.matchedAt != null ? Timestamp.fromDate(this.matchedAt!) : null,
      'completedAt': this.completedAt != null ? Timestamp.fromDate(this.completedAt!) : null,
    };
  }
}

/// 預約請求模型（用於創建新訂單）
@freezed
class BookingRequest with _$BookingRequest {
  const factory BookingRequest({
    required String pickupAddress,
    required LocationPoint pickupLocation,
    required String dropoffAddress,
    required LocationPoint dropoffLocation,
    required DateTime bookingTime,
    required int passengerCount,
    int? luggageCount,
    String? notes,
    String? packageId,
    String? packageName,
    double? estimatedFare,
  }) = _BookingRequest;

  factory BookingRequest.fromJson(Map<String, dynamic> json) =>
      _$BookingRequestFromJson(json);
}
