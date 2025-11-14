// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earnings_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EarningsState {
  TimeRange get timeRange => throw _privateConstructorUsedError;
  double get totalEarnings => throw _privateConstructorUsedError;
  int get totalOrders => throw _privateConstructorUsedError;
  double get averageEarnings => throw _privateConstructorUsedError;
  List<DailyEarnings> get dailyEarnings => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of EarningsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EarningsStateCopyWith<EarningsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EarningsStateCopyWith<$Res> {
  factory $EarningsStateCopyWith(
          EarningsState value, $Res Function(EarningsState) then) =
      _$EarningsStateCopyWithImpl<$Res, EarningsState>;
  @useResult
  $Res call(
      {TimeRange timeRange,
      double totalEarnings,
      int totalOrders,
      double averageEarnings,
      List<DailyEarnings> dailyEarnings,
      bool isLoading,
      String? error});
}

/// @nodoc
class _$EarningsStateCopyWithImpl<$Res, $Val extends EarningsState>
    implements $EarningsStateCopyWith<$Res> {
  _$EarningsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EarningsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timeRange = null,
    Object? totalEarnings = null,
    Object? totalOrders = null,
    Object? averageEarnings = null,
    Object? dailyEarnings = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      timeRange: null == timeRange
          ? _value.timeRange
          : timeRange // ignore: cast_nullable_to_non_nullable
              as TimeRange,
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
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EarningsStateImplCopyWith<$Res>
    implements $EarningsStateCopyWith<$Res> {
  factory _$$EarningsStateImplCopyWith(
          _$EarningsStateImpl value, $Res Function(_$EarningsStateImpl) then) =
      __$$EarningsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {TimeRange timeRange,
      double totalEarnings,
      int totalOrders,
      double averageEarnings,
      List<DailyEarnings> dailyEarnings,
      bool isLoading,
      String? error});
}

/// @nodoc
class __$$EarningsStateImplCopyWithImpl<$Res>
    extends _$EarningsStateCopyWithImpl<$Res, _$EarningsStateImpl>
    implements _$$EarningsStateImplCopyWith<$Res> {
  __$$EarningsStateImplCopyWithImpl(
      _$EarningsStateImpl _value, $Res Function(_$EarningsStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of EarningsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timeRange = null,
    Object? totalEarnings = null,
    Object? totalOrders = null,
    Object? averageEarnings = null,
    Object? dailyEarnings = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$EarningsStateImpl(
      timeRange: null == timeRange
          ? _value.timeRange
          : timeRange // ignore: cast_nullable_to_non_nullable
              as TimeRange,
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
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$EarningsStateImpl implements _EarningsState {
  const _$EarningsStateImpl(
      {this.timeRange = TimeRange.today,
      this.totalEarnings = 0.0,
      this.totalOrders = 0,
      this.averageEarnings = 0.0,
      final List<DailyEarnings> dailyEarnings = const [],
      this.isLoading = false,
      this.error})
      : _dailyEarnings = dailyEarnings;

  @override
  @JsonKey()
  final TimeRange timeRange;
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
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'EarningsState(timeRange: $timeRange, totalEarnings: $totalEarnings, totalOrders: $totalOrders, averageEarnings: $averageEarnings, dailyEarnings: $dailyEarnings, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EarningsStateImpl &&
            (identical(other.timeRange, timeRange) ||
                other.timeRange == timeRange) &&
            (identical(other.totalEarnings, totalEarnings) ||
                other.totalEarnings == totalEarnings) &&
            (identical(other.totalOrders, totalOrders) ||
                other.totalOrders == totalOrders) &&
            (identical(other.averageEarnings, averageEarnings) ||
                other.averageEarnings == averageEarnings) &&
            const DeepCollectionEquality()
                .equals(other._dailyEarnings, _dailyEarnings) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      timeRange,
      totalEarnings,
      totalOrders,
      averageEarnings,
      const DeepCollectionEquality().hash(_dailyEarnings),
      isLoading,
      error);

  /// Create a copy of EarningsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EarningsStateImplCopyWith<_$EarningsStateImpl> get copyWith =>
      __$$EarningsStateImplCopyWithImpl<_$EarningsStateImpl>(this, _$identity);
}

abstract class _EarningsState implements EarningsState {
  const factory _EarningsState(
      {final TimeRange timeRange,
      final double totalEarnings,
      final int totalOrders,
      final double averageEarnings,
      final List<DailyEarnings> dailyEarnings,
      final bool isLoading,
      final String? error}) = _$EarningsStateImpl;

  @override
  TimeRange get timeRange;
  @override
  double get totalEarnings;
  @override
  int get totalOrders;
  @override
  double get averageEarnings;
  @override
  List<DailyEarnings> get dailyEarnings;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of EarningsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EarningsStateImplCopyWith<_$EarningsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
