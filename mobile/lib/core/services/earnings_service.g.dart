// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DailyEarningsImpl _$$DailyEarningsImplFromJson(Map<String, dynamic> json) =>
    _$DailyEarningsImpl(
      date: json['date'] as String,
      earnings: (json['earnings'] as num).toDouble(),
      orders: (json['orders'] as num).toInt(),
    );

Map<String, dynamic> _$$DailyEarningsImplToJson(_$DailyEarningsImpl instance) =>
    <String, dynamic>{
      'date': instance.date,
      'earnings': instance.earnings,
      'orders': instance.orders,
    };
