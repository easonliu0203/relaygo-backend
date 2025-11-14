// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earnings_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DailyEarnings _$DailyEarningsFromJson(Map<String, dynamic> json) {
  return _DailyEarnings.fromJson(json);
}

/// @nodoc
mixin _$DailyEarnings {
  String get date => throw _privateConstructorUsedError;
  double get earnings => throw _privateConstructorUsedError;
  int get orders => throw _privateConstructorUsedError;

  /// Serializes this DailyEarnings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DailyEarnings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyEarningsCopyWith<DailyEarnings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyEarningsCopyWith<$Res> {
  factory $DailyEarningsCopyWith(
          DailyEarnings value, $Res Function(DailyEarnings) then) =
      _$DailyEarningsCopyWithImpl<$Res, DailyEarnings>;
  @useResult
  $Res call({String date, double earnings, int orders});
}

/// @nodoc
class _$DailyEarningsCopyWithImpl<$Res, $Val extends DailyEarnings>
    implements $DailyEarningsCopyWith<$Res> {
  _$DailyEarningsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyEarnings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? earnings = null,
    Object? orders = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      earnings: null == earnings
          ? _value.earnings
          : earnings // ignore: cast_nullable_to_non_nullable
              as double,
      orders: null == orders
          ? _value.orders
          : orders // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DailyEarningsImplCopyWith<$Res>
    implements $DailyEarningsCopyWith<$Res> {
  factory _$$DailyEarningsImplCopyWith(
          _$DailyEarningsImpl value, $Res Function(_$DailyEarningsImpl) then) =
      __$$DailyEarningsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String date, double earnings, int orders});
}

/// @nodoc
class __$$DailyEarningsImplCopyWithImpl<$Res>
    extends _$DailyEarningsCopyWithImpl<$Res, _$DailyEarningsImpl>
    implements _$$DailyEarningsImplCopyWith<$Res> {
  __$$DailyEarningsImplCopyWithImpl(
      _$DailyEarningsImpl _value, $Res Function(_$DailyEarningsImpl) _then)
      : super(_value, _then);

  /// Create a copy of DailyEarnings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? earnings = null,
    Object? orders = null,
  }) {
    return _then(_$DailyEarningsImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      earnings: null == earnings
          ? _value.earnings
          : earnings // ignore: cast_nullable_to_non_nullable
              as double,
      orders: null == orders
          ? _value.orders
          : orders // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DailyEarningsImpl implements _DailyEarnings {
  const _$DailyEarningsImpl(
      {required this.date, required this.earnings, required this.orders});

  factory _$DailyEarningsImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyEarningsImplFromJson(json);

  @override
  final String date;
  @override
  final double earnings;
  @override
  final int orders;

  @override
  String toString() {
    return 'DailyEarnings(date: $date, earnings: $earnings, orders: $orders)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyEarningsImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.earnings, earnings) ||
                other.earnings == earnings) &&
            (identical(other.orders, orders) || other.orders == orders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, earnings, orders);

  /// Create a copy of DailyEarnings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyEarningsImplCopyWith<_$DailyEarningsImpl> get copyWith =>
      __$$DailyEarningsImplCopyWithImpl<_$DailyEarningsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyEarningsImplToJson(
      this,
    );
  }
}

abstract class _DailyEarnings implements DailyEarnings {
  const factory _DailyEarnings(
      {required final String date,
      required final double earnings,
      required final int orders}) = _$DailyEarningsImpl;

  factory _DailyEarnings.fromJson(Map<String, dynamic> json) =
      _$DailyEarningsImpl.fromJson;

  @override
  String get date;
  @override
  double get earnings;
  @override
  int get orders;

  /// Create a copy of DailyEarnings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyEarningsImplCopyWith<_$DailyEarningsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$EarningsData {
  double get totalEarnings => throw _privateConstructorUsedError;
  int get totalOrders => throw _privateConstructorUsedError;
  double get averageEarnings => throw _privateConstructorUsedError;
  List<DailyEarnings> get dailyEarnings => throw _privateConstructorUsedError;

  /// Create a copy of EarningsData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EarningsDataCopyWith<EarningsData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EarningsDataCopyWith<$Res> {
  factory $EarningsDataCopyWith(
          EarningsData value, $Res Function(EarningsData) then) =
      _$EarningsDataCopyWithImpl<$Res, EarningsData>;
  @useResult
  $Res call(
      {double totalEarnings,
      int totalOrders,
      double averageEarnings,
      List<DailyEarnings> dailyEarnings});
}

/// @nodoc
class _$EarningsDataCopyWithImpl<$Res, $Val extends EarningsData>
    implements $EarningsDataCopyWith<$Res> {
  _$EarningsDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EarningsData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalEarnings = null,
    Object? totalOrders = null,
    Object? averageEarnings = null,
    Object? dailyEarnings = null,
  }) {
    return _then(_value.copyWith(
      totalEarnings: null == totalEarnings
          ? _value.totalEarnings
          : totalEarnings // ignore: cast_nullable_to_non_nullable
              as double,
      totalOrders: null == totalOrders
          ? _value.totalOrders
          : totalOrders // ignore: cast_nullable_to_non_nullable
              as int,
      averageEarnings: null == averageEarnings
          ? _value.averageEarnings
          : averageEarnings // ignore: cast_nullable_to_non_nullable
              as double,
      dailyEarnings: null == dailyEarnings
          ? _value.dailyEarnings
          : dailyEarnings // ignore: cast_nullable_to_non_nullable
              as List<DailyEarnings>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EarningsDataImplCopyWith<$Res>
    implements $EarningsDataCopyWith<$Res> {
  factory _$$EarningsDataImplCopyWith(
          _$EarningsDataImpl value, $Res Function(_$EarningsDataImpl) then) =
      __$$EarningsDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double totalEarnings,
      int totalOrders,
      double averageEarnings,
      List<DailyEarnings> dailyEarnings});
}

/// @nodoc
class __$$EarningsDataImplCopyWithImpl<$Res>
    extends _$EarningsDataCopyWithImpl<$Res, _$EarningsDataImpl>
    implements _$$EarningsDataImplCopyWith<$Res> {
  __$$EarningsDataImplCopyWithImpl(
      _$EarningsDataImpl _value, $Res Function(_$EarningsDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of EarningsData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalEarnings = null,
    Object? totalOrders = null,
    Object? averageEarnings = null,
    Object? dailyEarnings = null,
  }) {
    return _then(_$EarningsDataImpl(
      totalEarnings: null == totalEarnings
          ? _value.totalEarnings
          : totalEarnings // ignore: cast_nullable_to_non_nullable
              as double,
      totalOrders: null == totalOrders
          ? _value.totalOrders
          : totalOrders // ignore: cast_nullable_to_non_nullable
              as int,
      averageEarnings: null == averageEarnings
          ? _value.averageEarnings
          : averageEarnings // ignore: cast_nullable_to_non_nullable
              as double,
      dailyEarnings: null == dailyEarnings
          ? _value._dailyEarnings
          : dailyEarnings // ignore: cast_nullable_to_non_nullable
              as List<DailyEarnings>,
    ));
  }
}

/// @nodoc

class _$EarningsDataImpl implements _EarningsData {
  const _$EarningsDataImpl(
      {this.totalEarnings = 0.0,
      this.totalOrders = 0,
      this.averageEarnings = 0.0,
      final List<DailyEarnings> dailyEarnings = const []})
      : _dailyEarnings = dailyEarnings;

  @override
  @JsonKey()
  final double totalEarnings;
  @override
  @JsonKey()
  final int totalOrders;
  @override
  @JsonKey()
  final double averageEarnings;
  final List<DailyEarnings> _dailyEarnings;
  @override
  @JsonKey()
  List<DailyEarnings> get dailyEarnings {
    if (_dailyEarnings is EqualUnmodifiableListView) return _dailyEarnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dailyEarnings);
  }

  @override
  String toString() {
    return 'EarningsData(totalEarnings: $totalEarnings, totalOrders: $totalOrders, averageEarnings: $averageEarnings, dailyEarnings: $dailyEarnings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EarningsDataImpl &&
            (identical(other.totalEarnings, totalEarnings) ||
                other.totalEarnings == totalEarnings) &&
            (identical(other.totalOrders, totalOrders) ||
                other.totalOrders == totalOrders) &&
            (identical(other.averageEarnings, averageEarnings) ||
                other.averageEarnings == averageEarnings) &&
            const DeepCollectionEquality()
                .equals(other._dailyEarnings, _dailyEarnings));
  }

  @override
  int get hashCode => Object.hash(runtimeType, totalEarnings, totalOrders,
      averageEarnings, const DeepCollectionEquality().hash(_dailyEarnings));

  /// Create a copy of EarningsData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EarningsDataImplCopyWith<_$EarningsDataImpl> get copyWith =>
      __$$EarningsDataImplCopyWithImpl<_$EarningsDataImpl>(this, _$identity);
}

abstract class _EarningsData implements EarningsData {
  const factory _EarningsData(
      {final double totalEarnings,
      final int totalOrders,
      final double averageEarnings,
      final List<DailyEarnings> dailyEarnings}) = _$EarningsDataImpl;

  @override
  double get totalEarnings;
  @override
  int get totalOrders;
  @override
  double get averageEarnings;
  @override
  List<DailyEarnings> get dailyEarnings;

  /// Create a copy of EarningsData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EarningsDataImplCopyWith<_$EarningsDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
