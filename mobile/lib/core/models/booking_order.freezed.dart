// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LocationPoint _$LocationPointFromJson(Map<String, dynamic> json) {
  return _LocationPoint.fromJson(json);
}

/// @nodoc
mixin _$LocationPoint {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

  /// Serializes this LocationPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LocationPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocationPointCopyWith<LocationPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationPointCopyWith<$Res> {
  factory $LocationPointCopyWith(
          LocationPoint value, $Res Function(LocationPoint) then) =
      _$LocationPointCopyWithImpl<$Res, LocationPoint>;
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class _$LocationPointCopyWithImpl<$Res, $Val extends LocationPoint>
    implements $LocationPointCopyWith<$Res> {
  _$LocationPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocationPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(_value.copyWith(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LocationPointImplCopyWith<$Res>
    implements $LocationPointCopyWith<$Res> {
  factory _$$LocationPointImplCopyWith(
          _$LocationPointImpl value, $Res Function(_$LocationPointImpl) then) =
      __$$LocationPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class __$$LocationPointImplCopyWithImpl<$Res>
    extends _$LocationPointCopyWithImpl<$Res, _$LocationPointImpl>
    implements _$$LocationPointImplCopyWith<$Res> {
  __$$LocationPointImplCopyWithImpl(
      _$LocationPointImpl _value, $Res Function(_$LocationPointImpl) _then)
      : super(_value, _then);

  /// Create a copy of LocationPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
  }) {
    return _then(_$LocationPointImpl(
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LocationPointImpl extends _LocationPoint {
  const _$LocationPointImpl({required this.latitude, required this.longitude})
      : super._();

  factory _$LocationPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocationPointImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;

  @override
  String toString() {
    return 'LocationPoint(latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationPointImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, latitude, longitude);

  /// Create a copy of LocationPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationPointImplCopyWith<_$LocationPointImpl> get copyWith =>
      __$$LocationPointImplCopyWithImpl<_$LocationPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocationPointImplToJson(
      this,
    );
  }
}

abstract class _LocationPoint extends LocationPoint {
  const factory _LocationPoint(
      {required final double latitude,
      required final double longitude}) = _$LocationPointImpl;
  const _LocationPoint._() : super._();

  factory _LocationPoint.fromJson(Map<String, dynamic> json) =
      _$LocationPointImpl.fromJson;

  @override
  double get latitude;
  @override
  double get longitude;

  /// Create a copy of LocationPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocationPointImplCopyWith<_$LocationPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BookingOrder _$BookingOrderFromJson(Map<String, dynamic> json) {
  return _BookingOrder.fromJson(json);
}

/// @nodoc
mixin _$BookingOrder {
  String get id => throw _privateConstructorUsedError; // 訂單編號
  String get customerId => throw _privateConstructorUsedError; // 客戶 ID
  String? get driverId => throw _privateConstructorUsedError; // 司機 ID（配對後）
  String? get customerName => throw _privateConstructorUsedError; // 客戶姓名
  String? get customerPhone => throw _privateConstructorUsedError; // 客戶電話
  String? get driverName => throw _privateConstructorUsedError; // 司機姓名
  String? get driverPhone => throw _privateConstructorUsedError; // 司機電話
  String? get driverVehiclePlate => throw _privateConstructorUsedError; // 司機車牌
  String? get driverVehicleModel => throw _privateConstructorUsedError; // 司機車型
  double? get driverRating => throw _privateConstructorUsedError; // 司機評分
  String get pickupAddress => throw _privateConstructorUsedError; // 上車地點
  LocationPoint? get pickupLocation =>
      throw _privateConstructorUsedError; // 上車座標（可選，某些訂單可能缺少座標）
  String get dropoffAddress => throw _privateConstructorUsedError; // 下車地點
  LocationPoint? get dropoffLocation =>
      throw _privateConstructorUsedError; // 下車座標（可選，某些訂單可能缺少座標）
  DateTime get bookingTime => throw _privateConstructorUsedError; // 預約時間
  int get passengerCount => throw _privateConstructorUsedError; // 乘客人數
  int? get luggageCount => throw _privateConstructorUsedError; // 行李數量
  String? get notes => throw _privateConstructorUsedError; // 備註
  double get estimatedFare => throw _privateConstructorUsedError; // 預估費用
  double get depositAmount => throw _privateConstructorUsedError; // 訂金金額
  bool get depositPaid => throw _privateConstructorUsedError; // 訂金是否已支付
  double get overtimeFee => throw _privateConstructorUsedError; // 超時費用
  double get tipAmount => throw _privateConstructorUsedError; // 小費金額
  BookingStatus get status => throw _privateConstructorUsedError; // 訂單狀態
  DateTime get createdAt => throw _privateConstructorUsedError; // 建立時間
  DateTime? get matchedAt => throw _privateConstructorUsedError; // 配對時間
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this BookingOrder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BookingOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingOrderCopyWith<BookingOrder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingOrderCopyWith<$Res> {
  factory $BookingOrderCopyWith(
          BookingOrder value, $Res Function(BookingOrder) then) =
      _$BookingOrderCopyWithImpl<$Res, BookingOrder>;
  @useResult
  $Res call(
      {String id,
      String customerId,
      String? driverId,
      String? customerName,
      String? customerPhone,
      String? driverName,
      String? driverPhone,
      String? driverVehiclePlate,
      String? driverVehicleModel,
      double? driverRating,
      String pickupAddress,
      LocationPoint? pickupLocation,
      String dropoffAddress,
      LocationPoint? dropoffLocation,
      DateTime bookingTime,
      int passengerCount,
      int? luggageCount,
      String? notes,
      double estimatedFare,
      double depositAmount,
      bool depositPaid,
      double overtimeFee,
      double tipAmount,
      BookingStatus status,
      DateTime createdAt,
      DateTime? matchedAt,
      DateTime? completedAt});

  $LocationPointCopyWith<$Res>? get pickupLocation;
  $LocationPointCopyWith<$Res>? get dropoffLocation;
}

/// @nodoc
class _$BookingOrderCopyWithImpl<$Res, $Val extends BookingOrder>
    implements $BookingOrderCopyWith<$Res> {
  _$BookingOrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? driverId = freezed,
    Object? customerName = freezed,
    Object? customerPhone = freezed,
    Object? driverName = freezed,
    Object? driverPhone = freezed,
    Object? driverVehiclePlate = freezed,
    Object? driverVehicleModel = freezed,
    Object? driverRating = freezed,
    Object? pickupAddress = null,
    Object? pickupLocation = freezed,
    Object? dropoffAddress = null,
    Object? dropoffLocation = freezed,
    Object? bookingTime = null,
    Object? passengerCount = null,
    Object? luggageCount = freezed,
    Object? notes = freezed,
    Object? estimatedFare = null,
    Object? depositAmount = null,
    Object? depositPaid = null,
    Object? overtimeFee = null,
    Object? tipAmount = null,
    Object? status = null,
    Object? createdAt = null,
    Object? matchedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      driverId: freezed == driverId
          ? _value.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as String?,
      customerName: freezed == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerPhone: freezed == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      driverName: freezed == driverName
          ? _value.driverName
          : driverName // ignore: cast_nullable_to_non_nullable
              as String?,
      driverPhone: freezed == driverPhone
          ? _value.driverPhone
          : driverPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      driverVehiclePlate: freezed == driverVehiclePlate
          ? _value.driverVehiclePlate
          : driverVehiclePlate // ignore: cast_nullable_to_non_nullable
              as String?,
      driverVehicleModel: freezed == driverVehicleModel
          ? _value.driverVehicleModel
          : driverVehicleModel // ignore: cast_nullable_to_non_nullable
              as String?,
      driverRating: freezed == driverRating
          ? _value.driverRating
          : driverRating // ignore: cast_nullable_to_non_nullable
              as double?,
      pickupAddress: null == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String,
      pickupLocation: freezed == pickupLocation
          ? _value.pickupLocation
          : pickupLocation // ignore: cast_nullable_to_non_nullable
              as LocationPoint?,
      dropoffAddress: null == dropoffAddress
          ? _value.dropoffAddress
          : dropoffAddress // ignore: cast_nullable_to_non_nullable
              as String,
      dropoffLocation: freezed == dropoffLocation
          ? _value.dropoffLocation
          : dropoffLocation // ignore: cast_nullable_to_non_nullable
              as LocationPoint?,
      bookingTime: null == bookingTime
          ? _value.bookingTime
          : bookingTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      passengerCount: null == passengerCount
          ? _value.passengerCount
          : passengerCount // ignore: cast_nullable_to_non_nullable
              as int,
      luggageCount: freezed == luggageCount
          ? _value.luggageCount
          : luggageCount // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedFare: null == estimatedFare
          ? _value.estimatedFare
          : estimatedFare // ignore: cast_nullable_to_non_nullable
              as double,
      depositAmount: null == depositAmount
          ? _value.depositAmount
          : depositAmount // ignore: cast_nullable_to_non_nullable
              as double,
      depositPaid: null == depositPaid
          ? _value.depositPaid
          : depositPaid // ignore: cast_nullable_to_non_nullable
              as bool,
      overtimeFee: null == overtimeFee
          ? _value.overtimeFee
          : overtimeFee // ignore: cast_nullable_to_non_nullable
              as double,
      tipAmount: null == tipAmount
          ? _value.tipAmount
          : tipAmount // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as BookingStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      matchedAt: freezed == matchedAt
          ? _value.matchedAt
          : matchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of BookingOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationPointCopyWith<$Res>? get pickupLocation {
    if (_value.pickupLocation == null) {
      return null;
    }

    return $LocationPointCopyWith<$Res>(_value.pickupLocation!, (value) {
      return _then(_value.copyWith(pickupLocation: value) as $Val);
    });
  }

  /// Create a copy of BookingOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationPointCopyWith<$Res>? get dropoffLocation {
    if (_value.dropoffLocation == null) {
      return null;
    }

    return $LocationPointCopyWith<$Res>(_value.dropoffLocation!, (value) {
      return _then(_value.copyWith(dropoffLocation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BookingOrderImplCopyWith<$Res>
    implements $BookingOrderCopyWith<$Res> {
  factory _$$BookingOrderImplCopyWith(
          _$BookingOrderImpl value, $Res Function(_$BookingOrderImpl) then) =
      __$$BookingOrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String customerId,
      String? driverId,
      String? customerName,
      String? customerPhone,
      String? driverName,
      String? driverPhone,
      String? driverVehiclePlate,
      String? driverVehicleModel,
      double? driverRating,
      String pickupAddress,
      LocationPoint? pickupLocation,
      String dropoffAddress,
      LocationPoint? dropoffLocation,
      DateTime bookingTime,
      int passengerCount,
      int? luggageCount,
      String? notes,
      double estimatedFare,
      double depositAmount,
      bool depositPaid,
      double overtimeFee,
      double tipAmount,
      BookingStatus status,
      DateTime createdAt,
      DateTime? matchedAt,
      DateTime? completedAt});

  @override
  $LocationPointCopyWith<$Res>? get pickupLocation;
  @override
  $LocationPointCopyWith<$Res>? get dropoffLocation;
}

/// @nodoc
class __$$BookingOrderImplCopyWithImpl<$Res>
    extends _$BookingOrderCopyWithImpl<$Res, _$BookingOrderImpl>
    implements _$$BookingOrderImplCopyWith<$Res> {
  __$$BookingOrderImplCopyWithImpl(
      _$BookingOrderImpl _value, $Res Function(_$BookingOrderImpl) _then)
      : super(_value, _then);

  /// Create a copy of BookingOrder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = null,
    Object? driverId = freezed,
    Object? customerName = freezed,
    Object? customerPhone = freezed,
    Object? driverName = freezed,
    Object? driverPhone = freezed,
    Object? driverVehiclePlate = freezed,
    Object? driverVehicleModel = freezed,
    Object? driverRating = freezed,
    Object? pickupAddress = null,
    Object? pickupLocation = freezed,
    Object? dropoffAddress = null,
    Object? dropoffLocation = freezed,
    Object? bookingTime = null,
    Object? passengerCount = null,
    Object? luggageCount = freezed,
    Object? notes = freezed,
    Object? estimatedFare = null,
    Object? depositAmount = null,
    Object? depositPaid = null,
    Object? overtimeFee = null,
    Object? tipAmount = null,
    Object? status = null,
    Object? createdAt = null,
    Object? matchedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(_$BookingOrderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      driverId: freezed == driverId
          ? _value.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as String?,
      customerName: freezed == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerPhone: freezed == customerPhone
          ? _value.customerPhone
          : customerPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      driverName: freezed == driverName
          ? _value.driverName
          : driverName // ignore: cast_nullable_to_non_nullable
              as String?,
      driverPhone: freezed == driverPhone
          ? _value.driverPhone
          : driverPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      driverVehiclePlate: freezed == driverVehiclePlate
          ? _value.driverVehiclePlate
          : driverVehiclePlate // ignore: cast_nullable_to_non_nullable
              as String?,
      driverVehicleModel: freezed == driverVehicleModel
          ? _value.driverVehicleModel
          : driverVehicleModel // ignore: cast_nullable_to_non_nullable
              as String?,
      driverRating: freezed == driverRating
          ? _value.driverRating
          : driverRating // ignore: cast_nullable_to_non_nullable
              as double?,
      pickupAddress: null == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String,
      pickupLocation: freezed == pickupLocation
          ? _value.pickupLocation
          : pickupLocation // ignore: cast_nullable_to_non_nullable
              as LocationPoint?,
      dropoffAddress: null == dropoffAddress
          ? _value.dropoffAddress
          : dropoffAddress // ignore: cast_nullable_to_non_nullable
              as String,
      dropoffLocation: freezed == dropoffLocation
          ? _value.dropoffLocation
          : dropoffLocation // ignore: cast_nullable_to_non_nullable
              as LocationPoint?,
      bookingTime: null == bookingTime
          ? _value.bookingTime
          : bookingTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      passengerCount: null == passengerCount
          ? _value.passengerCount
          : passengerCount // ignore: cast_nullable_to_non_nullable
              as int,
      luggageCount: freezed == luggageCount
          ? _value.luggageCount
          : luggageCount // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedFare: null == estimatedFare
          ? _value.estimatedFare
          : estimatedFare // ignore: cast_nullable_to_non_nullable
              as double,
      depositAmount: null == depositAmount
          ? _value.depositAmount
          : depositAmount // ignore: cast_nullable_to_non_nullable
              as double,
      depositPaid: null == depositPaid
          ? _value.depositPaid
          : depositPaid // ignore: cast_nullable_to_non_nullable
              as bool,
      overtimeFee: null == overtimeFee
          ? _value.overtimeFee
          : overtimeFee // ignore: cast_nullable_to_non_nullable
              as double,
      tipAmount: null == tipAmount
          ? _value.tipAmount
          : tipAmount // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as BookingStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      matchedAt: freezed == matchedAt
          ? _value.matchedAt
          : matchedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingOrderImpl extends _BookingOrder {
  const _$BookingOrderImpl(
      {required this.id,
      required this.customerId,
      this.driverId,
      this.customerName,
      this.customerPhone,
      this.driverName,
      this.driverPhone,
      this.driverVehiclePlate,
      this.driverVehicleModel,
      this.driverRating,
      required this.pickupAddress,
      this.pickupLocation,
      required this.dropoffAddress,
      this.dropoffLocation,
      required this.bookingTime,
      required this.passengerCount,
      this.luggageCount,
      this.notes,
      required this.estimatedFare,
      required this.depositAmount,
      this.depositPaid = false,
      this.overtimeFee = 0.0,
      this.tipAmount = 0.0,
      this.status = BookingStatus.pending,
      required this.createdAt,
      this.matchedAt,
      this.completedAt})
      : super._();

  factory _$BookingOrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingOrderImplFromJson(json);

  @override
  final String id;
// 訂單編號
  @override
  final String customerId;
// 客戶 ID
  @override
  final String? driverId;
// 司機 ID（配對後）
  @override
  final String? customerName;
// 客戶姓名
  @override
  final String? customerPhone;
// 客戶電話
  @override
  final String? driverName;
// 司機姓名
  @override
  final String? driverPhone;
// 司機電話
  @override
  final String? driverVehiclePlate;
// 司機車牌
  @override
  final String? driverVehicleModel;
// 司機車型
  @override
  final double? driverRating;
// 司機評分
  @override
  final String pickupAddress;
// 上車地點
  @override
  final LocationPoint? pickupLocation;
// 上車座標（可選，某些訂單可能缺少座標）
  @override
  final String dropoffAddress;
// 下車地點
  @override
  final LocationPoint? dropoffLocation;
// 下車座標（可選，某些訂單可能缺少座標）
  @override
  final DateTime bookingTime;
// 預約時間
  @override
  final int passengerCount;
// 乘客人數
  @override
  final int? luggageCount;
// 行李數量
  @override
  final String? notes;
// 備註
  @override
  final double estimatedFare;
// 預估費用
  @override
  final double depositAmount;
// 訂金金額
  @override
  @JsonKey()
  final bool depositPaid;
// 訂金是否已支付
  @override
  @JsonKey()
  final double overtimeFee;
// 超時費用
  @override
  @JsonKey()
  final double tipAmount;
// 小費金額
  @override
  @JsonKey()
  final BookingStatus status;
// 訂單狀態
  @override
  final DateTime createdAt;
// 建立時間
  @override
  final DateTime? matchedAt;
// 配對時間
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'BookingOrder(id: $id, customerId: $customerId, driverId: $driverId, customerName: $customerName, customerPhone: $customerPhone, driverName: $driverName, driverPhone: $driverPhone, driverVehiclePlate: $driverVehiclePlate, driverVehicleModel: $driverVehicleModel, driverRating: $driverRating, pickupAddress: $pickupAddress, pickupLocation: $pickupLocation, dropoffAddress: $dropoffAddress, dropoffLocation: $dropoffLocation, bookingTime: $bookingTime, passengerCount: $passengerCount, luggageCount: $luggageCount, notes: $notes, estimatedFare: $estimatedFare, depositAmount: $depositAmount, depositPaid: $depositPaid, overtimeFee: $overtimeFee, tipAmount: $tipAmount, status: $status, createdAt: $createdAt, matchedAt: $matchedAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingOrderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.customerPhone, customerPhone) ||
                other.customerPhone == customerPhone) &&
            (identical(other.driverName, driverName) ||
                other.driverName == driverName) &&
            (identical(other.driverPhone, driverPhone) ||
                other.driverPhone == driverPhone) &&
            (identical(other.driverVehiclePlate, driverVehiclePlate) ||
                other.driverVehiclePlate == driverVehiclePlate) &&
            (identical(other.driverVehicleModel, driverVehicleModel) ||
                other.driverVehicleModel == driverVehicleModel) &&
            (identical(other.driverRating, driverRating) ||
                other.driverRating == driverRating) &&
            (identical(other.pickupAddress, pickupAddress) ||
                other.pickupAddress == pickupAddress) &&
            (identical(other.pickupLocation, pickupLocation) ||
                other.pickupLocation == pickupLocation) &&
            (identical(other.dropoffAddress, dropoffAddress) ||
                other.dropoffAddress == dropoffAddress) &&
            (identical(other.dropoffLocation, dropoffLocation) ||
                other.dropoffLocation == dropoffLocation) &&
            (identical(other.bookingTime, bookingTime) ||
                other.bookingTime == bookingTime) &&
            (identical(other.passengerCount, passengerCount) ||
                other.passengerCount == passengerCount) &&
            (identical(other.luggageCount, luggageCount) ||
                other.luggageCount == luggageCount) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.estimatedFare, estimatedFare) ||
                other.estimatedFare == estimatedFare) &&
            (identical(other.depositAmount, depositAmount) ||
                other.depositAmount == depositAmount) &&
            (identical(other.depositPaid, depositPaid) ||
                other.depositPaid == depositPaid) &&
            (identical(other.overtimeFee, overtimeFee) ||
                other.overtimeFee == overtimeFee) &&
            (identical(other.tipAmount, tipAmount) ||
                other.tipAmount == tipAmount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.matchedAt, matchedAt) ||
                other.matchedAt == matchedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        customerId,
        driverId,
        customerName,
        customerPhone,
        driverName,
        driverPhone,
        driverVehiclePlate,
        driverVehicleModel,
        driverRating,
        pickupAddress,
        pickupLocation,
        dropoffAddress,
        dropoffLocation,
        bookingTime,
        passengerCount,
        luggageCount,
        notes,
        estimatedFare,
        depositAmount,
        depositPaid,
        overtimeFee,
        tipAmount,
        status,
        createdAt,
        matchedAt,
        completedAt
      ]);

  /// Create a copy of BookingOrder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingOrderImplCopyWith<_$BookingOrderImpl> get copyWith =>
      __$$BookingOrderImplCopyWithImpl<_$BookingOrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingOrderImplToJson(
      this,
    );
  }
}

abstract class _BookingOrder extends BookingOrder {
  const factory _BookingOrder(
      {required final String id,
      required final String customerId,
      final String? driverId,
      final String? customerName,
      final String? customerPhone,
      final String? driverName,
      final String? driverPhone,
      final String? driverVehiclePlate,
      final String? driverVehicleModel,
      final double? driverRating,
      required final String pickupAddress,
      final LocationPoint? pickupLocation,
      required final String dropoffAddress,
      final LocationPoint? dropoffLocation,
      required final DateTime bookingTime,
      required final int passengerCount,
      final int? luggageCount,
      final String? notes,
      required final double estimatedFare,
      required final double depositAmount,
      final bool depositPaid,
      final double overtimeFee,
      final double tipAmount,
      final BookingStatus status,
      required final DateTime createdAt,
      final DateTime? matchedAt,
      final DateTime? completedAt}) = _$BookingOrderImpl;
  const _BookingOrder._() : super._();

  factory _BookingOrder.fromJson(Map<String, dynamic> json) =
      _$BookingOrderImpl.fromJson;

  @override
  String get id; // 訂單編號
  @override
  String get customerId; // 客戶 ID
  @override
  String? get driverId; // 司機 ID（配對後）
  @override
  String? get customerName; // 客戶姓名
  @override
  String? get customerPhone; // 客戶電話
  @override
  String? get driverName; // 司機姓名
  @override
  String? get driverPhone; // 司機電話
  @override
  String? get driverVehiclePlate; // 司機車牌
  @override
  String? get driverVehicleModel; // 司機車型
  @override
  double? get driverRating; // 司機評分
  @override
  String get pickupAddress; // 上車地點
  @override
  LocationPoint? get pickupLocation; // 上車座標（可選，某些訂單可能缺少座標）
  @override
  String get dropoffAddress; // 下車地點
  @override
  LocationPoint? get dropoffLocation; // 下車座標（可選，某些訂單可能缺少座標）
  @override
  DateTime get bookingTime; // 預約時間
  @override
  int get passengerCount; // 乘客人數
  @override
  int? get luggageCount; // 行李數量
  @override
  String? get notes; // 備註
  @override
  double get estimatedFare; // 預估費用
  @override
  double get depositAmount; // 訂金金額
  @override
  bool get depositPaid; // 訂金是否已支付
  @override
  double get overtimeFee; // 超時費用
  @override
  double get tipAmount; // 小費金額
  @override
  BookingStatus get status; // 訂單狀態
  @override
  DateTime get createdAt; // 建立時間
  @override
  DateTime? get matchedAt; // 配對時間
  @override
  DateTime? get completedAt;

  /// Create a copy of BookingOrder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingOrderImplCopyWith<_$BookingOrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BookingRequest _$BookingRequestFromJson(Map<String, dynamic> json) {
  return _BookingRequest.fromJson(json);
}

/// @nodoc
mixin _$BookingRequest {
  String get pickupAddress => throw _privateConstructorUsedError;
  LocationPoint get pickupLocation => throw _privateConstructorUsedError;
  String get dropoffAddress => throw _privateConstructorUsedError;
  LocationPoint get dropoffLocation => throw _privateConstructorUsedError;
  DateTime get bookingTime => throw _privateConstructorUsedError;
  int get passengerCount => throw _privateConstructorUsedError;
  int? get luggageCount => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get packageId => throw _privateConstructorUsedError;
  String? get packageName => throw _privateConstructorUsedError;
  double? get estimatedFare => throw _privateConstructorUsedError;

  /// Serializes this BookingRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BookingRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingRequestCopyWith<BookingRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingRequestCopyWith<$Res> {
  factory $BookingRequestCopyWith(
          BookingRequest value, $Res Function(BookingRequest) then) =
      _$BookingRequestCopyWithImpl<$Res, BookingRequest>;
  @useResult
  $Res call(
      {String pickupAddress,
      LocationPoint pickupLocation,
      String dropoffAddress,
      LocationPoint dropoffLocation,
      DateTime bookingTime,
      int passengerCount,
      int? luggageCount,
      String? notes,
      String? packageId,
      String? packageName,
      double? estimatedFare});

  $LocationPointCopyWith<$Res> get pickupLocation;
  $LocationPointCopyWith<$Res> get dropoffLocation;
}

/// @nodoc
class _$BookingRequestCopyWithImpl<$Res, $Val extends BookingRequest>
    implements $BookingRequestCopyWith<$Res> {
  _$BookingRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookingRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pickupAddress = null,
    Object? pickupLocation = null,
    Object? dropoffAddress = null,
    Object? dropoffLocation = null,
    Object? bookingTime = null,
    Object? passengerCount = null,
    Object? luggageCount = freezed,
    Object? notes = freezed,
    Object? packageId = freezed,
    Object? packageName = freezed,
    Object? estimatedFare = freezed,
  }) {
    return _then(_value.copyWith(
      pickupAddress: null == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String,
      pickupLocation: null == pickupLocation
          ? _value.pickupLocation
          : pickupLocation // ignore: cast_nullable_to_non_nullable
              as LocationPoint,
      dropoffAddress: null == dropoffAddress
          ? _value.dropoffAddress
          : dropoffAddress // ignore: cast_nullable_to_non_nullable
              as String,
      dropoffLocation: null == dropoffLocation
          ? _value.dropoffLocation
          : dropoffLocation // ignore: cast_nullable_to_non_nullable
              as LocationPoint,
      bookingTime: null == bookingTime
          ? _value.bookingTime
          : bookingTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      passengerCount: null == passengerCount
          ? _value.passengerCount
          : passengerCount // ignore: cast_nullable_to_non_nullable
              as int,
      luggageCount: freezed == luggageCount
          ? _value.luggageCount
          : luggageCount // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      packageId: freezed == packageId
          ? _value.packageId
          : packageId // ignore: cast_nullable_to_non_nullable
              as String?,
      packageName: freezed == packageName
          ? _value.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedFare: freezed == estimatedFare
          ? _value.estimatedFare
          : estimatedFare // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }

  /// Create a copy of BookingRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationPointCopyWith<$Res> get pickupLocation {
    return $LocationPointCopyWith<$Res>(_value.pickupLocation, (value) {
      return _then(_value.copyWith(pickupLocation: value) as $Val);
    });
  }

  /// Create a copy of BookingRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LocationPointCopyWith<$Res> get dropoffLocation {
    return $LocationPointCopyWith<$Res>(_value.dropoffLocation, (value) {
      return _then(_value.copyWith(dropoffLocation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BookingRequestImplCopyWith<$Res>
    implements $BookingRequestCopyWith<$Res> {
  factory _$$BookingRequestImplCopyWith(_$BookingRequestImpl value,
          $Res Function(_$BookingRequestImpl) then) =
      __$$BookingRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String pickupAddress,
      LocationPoint pickupLocation,
      String dropoffAddress,
      LocationPoint dropoffLocation,
      DateTime bookingTime,
      int passengerCount,
      int? luggageCount,
      String? notes,
      String? packageId,
      String? packageName,
      double? estimatedFare});

  @override
  $LocationPointCopyWith<$Res> get pickupLocation;
  @override
  $LocationPointCopyWith<$Res> get dropoffLocation;
}

/// @nodoc
class __$$BookingRequestImplCopyWithImpl<$Res>
    extends _$BookingRequestCopyWithImpl<$Res, _$BookingRequestImpl>
    implements _$$BookingRequestImplCopyWith<$Res> {
  __$$BookingRequestImplCopyWithImpl(
      _$BookingRequestImpl _value, $Res Function(_$BookingRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of BookingRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pickupAddress = null,
    Object? pickupLocation = null,
    Object? dropoffAddress = null,
    Object? dropoffLocation = null,
    Object? bookingTime = null,
    Object? passengerCount = null,
    Object? luggageCount = freezed,
    Object? notes = freezed,
    Object? packageId = freezed,
    Object? packageName = freezed,
    Object? estimatedFare = freezed,
  }) {
    return _then(_$BookingRequestImpl(
      pickupAddress: null == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String,
      pickupLocation: null == pickupLocation
          ? _value.pickupLocation
          : pickupLocation // ignore: cast_nullable_to_non_nullable
              as LocationPoint,
      dropoffAddress: null == dropoffAddress
          ? _value.dropoffAddress
          : dropoffAddress // ignore: cast_nullable_to_non_nullable
              as String,
      dropoffLocation: null == dropoffLocation
          ? _value.dropoffLocation
          : dropoffLocation // ignore: cast_nullable_to_non_nullable
              as LocationPoint,
      bookingTime: null == bookingTime
          ? _value.bookingTime
          : bookingTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      passengerCount: null == passengerCount
          ? _value.passengerCount
          : passengerCount // ignore: cast_nullable_to_non_nullable
              as int,
      luggageCount: freezed == luggageCount
          ? _value.luggageCount
          : luggageCount // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      packageId: freezed == packageId
          ? _value.packageId
          : packageId // ignore: cast_nullable_to_non_nullable
              as String?,
      packageName: freezed == packageName
          ? _value.packageName
          : packageName // ignore: cast_nullable_to_non_nullable
              as String?,
      estimatedFare: freezed == estimatedFare
          ? _value.estimatedFare
          : estimatedFare // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingRequestImpl implements _BookingRequest {
  const _$BookingRequestImpl(
      {required this.pickupAddress,
      required this.pickupLocation,
      required this.dropoffAddress,
      required this.dropoffLocation,
      required this.bookingTime,
      required this.passengerCount,
      this.luggageCount,
      this.notes,
      this.packageId,
      this.packageName,
      this.estimatedFare});

  factory _$BookingRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingRequestImplFromJson(json);

  @override
  final String pickupAddress;
  @override
  final LocationPoint pickupLocation;
  @override
  final String dropoffAddress;
  @override
  final LocationPoint dropoffLocation;
  @override
  final DateTime bookingTime;
  @override
  final int passengerCount;
  @override
  final int? luggageCount;
  @override
  final String? notes;
  @override
  final String? packageId;
  @override
  final String? packageName;
  @override
  final double? estimatedFare;

  @override
  String toString() {
    return 'BookingRequest(pickupAddress: $pickupAddress, pickupLocation: $pickupLocation, dropoffAddress: $dropoffAddress, dropoffLocation: $dropoffLocation, bookingTime: $bookingTime, passengerCount: $passengerCount, luggageCount: $luggageCount, notes: $notes, packageId: $packageId, packageName: $packageName, estimatedFare: $estimatedFare)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingRequestImpl &&
            (identical(other.pickupAddress, pickupAddress) ||
                other.pickupAddress == pickupAddress) &&
            (identical(other.pickupLocation, pickupLocation) ||
                other.pickupLocation == pickupLocation) &&
            (identical(other.dropoffAddress, dropoffAddress) ||
                other.dropoffAddress == dropoffAddress) &&
            (identical(other.dropoffLocation, dropoffLocation) ||
                other.dropoffLocation == dropoffLocation) &&
            (identical(other.bookingTime, bookingTime) ||
                other.bookingTime == bookingTime) &&
            (identical(other.passengerCount, passengerCount) ||
                other.passengerCount == passengerCount) &&
            (identical(other.luggageCount, luggageCount) ||
                other.luggageCount == luggageCount) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.packageId, packageId) ||
                other.packageId == packageId) &&
            (identical(other.packageName, packageName) ||
                other.packageName == packageName) &&
            (identical(other.estimatedFare, estimatedFare) ||
                other.estimatedFare == estimatedFare));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      pickupAddress,
      pickupLocation,
      dropoffAddress,
      dropoffLocation,
      bookingTime,
      passengerCount,
      luggageCount,
      notes,
      packageId,
      packageName,
      estimatedFare);

  /// Create a copy of BookingRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingRequestImplCopyWith<_$BookingRequestImpl> get copyWith =>
      __$$BookingRequestImplCopyWithImpl<_$BookingRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingRequestImplToJson(
      this,
    );
  }
}

abstract class _BookingRequest implements BookingRequest {
  const factory _BookingRequest(
      {required final String pickupAddress,
      required final LocationPoint pickupLocation,
      required final String dropoffAddress,
      required final LocationPoint dropoffLocation,
      required final DateTime bookingTime,
      required final int passengerCount,
      final int? luggageCount,
      final String? notes,
      final String? packageId,
      final String? packageName,
      final double? estimatedFare}) = _$BookingRequestImpl;

  factory _BookingRequest.fromJson(Map<String, dynamic> json) =
      _$BookingRequestImpl.fromJson;

  @override
  String get pickupAddress;
  @override
  LocationPoint get pickupLocation;
  @override
  String get dropoffAddress;
  @override
  LocationPoint get dropoffLocation;
  @override
  DateTime get bookingTime;
  @override
  int get passengerCount;
  @override
  int? get luggageCount;
  @override
  String? get notes;
  @override
  String? get packageId;
  @override
  String? get packageName;
  @override
  double? get estimatedFare;

  /// Create a copy of BookingRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingRequestImplCopyWith<_$BookingRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
