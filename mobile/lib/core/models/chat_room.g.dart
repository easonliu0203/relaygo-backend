// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatRoomImpl _$$ChatRoomImplFromJson(Map<String, dynamic> json) =>
    _$ChatRoomImpl(
      bookingId: json['bookingId'] as String,
      customerId: json['customerId'] as String,
      driverId: json['driverId'] as String,
      customerName: json['customerName'] as String?,
      driverName: json['driverName'] as String?,
      pickupAddress: json['pickupAddress'] as String?,
      bookingTime: json['bookingTime'] == null
          ? null
          : DateTime.parse(json['bookingTime'] as String),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] == null
          ? null
          : DateTime.parse(json['lastMessageTime'] as String),
      customerUnreadCount: (json['customerUnreadCount'] as num?)?.toInt() ?? 0,
      driverUnreadCount: (json['driverUnreadCount'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      memberIds: (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      roomLangOverride: json['roomLangOverride'] as String?,
    );

Map<String, dynamic> _$$ChatRoomImplToJson(_$ChatRoomImpl instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'customerId': instance.customerId,
      'driverId': instance.driverId,
      'customerName': instance.customerName,
      'driverName': instance.driverName,
      'pickupAddress': instance.pickupAddress,
      'bookingTime': instance.bookingTime?.toIso8601String(),
      'lastMessage': instance.lastMessage,
      'lastMessageTime': instance.lastMessageTime?.toIso8601String(),
      'customerUnreadCount': instance.customerUnreadCount,
      'driverUnreadCount': instance.driverUnreadCount,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'memberIds': instance.memberIds,
      'roomLangOverride': instance.roomLangOverride,
    };
