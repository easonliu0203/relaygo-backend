// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocationPointImpl _$$LocationPointImplFromJson(Map<String, dynamic> json) =>
    _$LocationPointImpl(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$$LocationPointImplToJson(_$LocationPointImpl instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

_$BookingOrderImpl _$$BookingOrderImplFromJson(Map<String, dynamic> json) =>
    _$BookingOrderImpl(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      driverId: json['driverId'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      driverVehiclePlate: json['driverVehiclePlate'] as String?,
      driverVehicleModel: json['driverVehicleModel'] as String?,
      driverRating: (json['driverRating'] as num?)?.toDouble(),
      pickupAddress: json['pickupAddress'] as String,
      pickupLocation: json['pickupLocation'] == null
          ? null
          : LocationPoint.fromJson(
              json['pickupLocation'] as Map<String, dynamic>),
      dropoffAddress: json['dropoffAddress'] as String,
      dropoffLocation: json['dropoffLocation'] == null
          ? null
          : LocationPoint.fromJson(
              json['dropoffLocation'] as Map<String, dynamic>),
      bookingTime: DateTime.parse(json['bookingTime'] as String),
      passengerCount: (json['passengerCount'] as num).toInt(),
      luggageCount: (json['luggageCount'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      estimatedFare: (json['estimatedFare'] as num).toDouble(),
      depositAmount: (json['depositAmount'] as num).toDouble(),
      depositPaid: json['depositPaid'] as bool? ?? false,
      overtimeFee: (json['overtimeFee'] as num?)?.toDouble() ?? 0.0,
      tipAmount: (json['tipAmount'] as num?)?.toDouble() ?? 0.0,
      status: $enumDecodeNullable(_$BookingStatusEnumMap, json['status']) ??
          BookingStatus.pending,
      createdAt: DateTime.parse(json['createdAt'] as String),
      matchedAt: json['matchedAt'] == null
          ? null
          : DateTime.parse(json['matchedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$$BookingOrderImplToJson(_$BookingOrderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'driverId': instance.driverId,
      'customerName': instance.customerName,
      'customerPhone': instance.customerPhone,
      'driverName': instance.driverName,
      'driverPhone': instance.driverPhone,
      'driverVehiclePlate': instance.driverVehiclePlate,
      'driverVehicleModel': instance.driverVehicleModel,
      'driverRating': instance.driverRating,
      'pickupAddress': instance.pickupAddress,
      'pickupLocation': instance.pickupLocation,
      'dropoffAddress': instance.dropoffAddress,
      'dropoffLocation': instance.dropoffLocation,
      'bookingTime': instance.bookingTime.toIso8601String(),
      'passengerCount': instance.passengerCount,
      'luggageCount': instance.luggageCount,
      'notes': instance.notes,
      'estimatedFare': instance.estimatedFare,
      'depositAmount': instance.depositAmount,
      'depositPaid': instance.depositPaid,
      'overtimeFee': instance.overtimeFee,
      'tipAmount': instance.tipAmount,
      'status': _$BookingStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'matchedAt': instance.matchedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pendingPayment: 'PENDING_PAYMENT',
  BookingStatus.pending: 'pending',
  BookingStatus.awaitingDriver: 'awaitingDriver',
  BookingStatus.matched: 'matched',
  BookingStatus.onTheWay: 'ON_THE_WAY',
  BookingStatus.inProgress: 'inProgress',
  BookingStatus.awaitingBalance: 'awaitingBalance',
  BookingStatus.completed: 'completed',
  BookingStatus.cancelled: 'cancelled',
};

_$BookingRequestImpl _$$BookingRequestImplFromJson(Map<String, dynamic> json) =>
    _$BookingRequestImpl(
      pickupAddress: json['pickupAddress'] as String,
      pickupLocation: LocationPoint.fromJson(
          json['pickupLocation'] as Map<String, dynamic>),
      dropoffAddress: json['dropoffAddress'] as String,
      dropoffLocation: LocationPoint.fromJson(
          json['dropoffLocation'] as Map<String, dynamic>),
      bookingTime: DateTime.parse(json['bookingTime'] as String),
      passengerCount: (json['passengerCount'] as num).toInt(),
      luggageCount: (json['luggageCount'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      packageId: json['packageId'] as String?,
      packageName: json['packageName'] as String?,
      estimatedFare: (json['estimatedFare'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$BookingRequestImplToJson(
        _$BookingRequestImpl instance) =>
    <String, dynamic>{
      'pickupAddress': instance.pickupAddress,
      'pickupLocation': instance.pickupLocation,
      'dropoffAddress': instance.dropoffAddress,
      'dropoffLocation': instance.dropoffLocation,
      'bookingTime': instance.bookingTime.toIso8601String(),
      'passengerCount': instance.passengerCount,
      'luggageCount': instance.luggageCount,
      'notes': instance.notes,
      'packageId': instance.packageId,
      'packageName': instance.packageName,
      'estimatedFare': instance.estimatedFare,
    };
