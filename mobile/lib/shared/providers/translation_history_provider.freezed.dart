// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'translation_history_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TranslationHistoryState {
  List<TranslationRecord> get records => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of TranslationHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranslationHistoryStateCopyWith<TranslationHistoryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranslationHistoryStateCopyWith<$Res> {
  factory $TranslationHistoryStateCopyWith(TranslationHistoryState value,
          $Res Function(TranslationHistoryState) then) =
      _$TranslationHistoryStateCopyWithImpl<$Res, TranslationHistoryState>;
  @useResult
  $Res call({List<TranslationRecord> records, bool isLoading, String? error});
}

/// @nodoc
class _$TranslationHistoryStateCopyWithImpl<$Res,
        $Val extends TranslationHistoryState>
    implements $TranslationHistoryStateCopyWith<$Res> {
  _$TranslationHistoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TranslationHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? records = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      records: null == records
          ? _value.records
          : records // ignore: cast_nullable_to_non_nullable
              as List<TranslationRecord>,
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
abstract class _$$TranslationHistoryStateImplCopyWith<$Res>
    implements $TranslationHistoryStateCopyWith<$Res> {
  factory _$$TranslationHistoryStateImplCopyWith(
          _$TranslationHistoryStateImpl value,
          $Res Function(_$TranslationHistoryStateImpl) then) =
      __$$TranslationHistoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<TranslationRecord> records, bool isLoading, String? error});
}

/// @nodoc
class __$$TranslationHistoryStateImplCopyWithImpl<$Res>
    extends _$TranslationHistoryStateCopyWithImpl<$Res,
        _$TranslationHistoryStateImpl>
    implements _$$TranslationHistoryStateImplCopyWith<$Res> {
  __$$TranslationHistoryStateImplCopyWithImpl(
      _$TranslationHistoryStateImpl _value,
      $Res Function(_$TranslationHistoryStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of TranslationHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? records = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$TranslationHistoryStateImpl(
      records: null == records
          ? _value._records
          : records // ignore: cast_nullable_to_non_nullable
              as List<TranslationRecord>,
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

class _$TranslationHistoryStateImpl implements _TranslationHistoryState {
  const _$TranslationHistoryStateImpl(
      {final List<TranslationRecord> records = const [],
      this.isLoading = false,
      this.error})
      : _records = records;

  final List<TranslationRecord> _records;
  @override
  @JsonKey()
  List<TranslationRecord> get records {
    if (_records is EqualUnmodifiableListView) return _records;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_records);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'TranslationHistoryState(records: $records, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranslationHistoryStateImpl &&
            const DeepCollectionEquality().equals(other._records, _records) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_records), isLoading, error);

  /// Create a copy of TranslationHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranslationHistoryStateImplCopyWith<_$TranslationHistoryStateImpl>
      get copyWith => __$$TranslationHistoryStateImplCopyWithImpl<
          _$TranslationHistoryStateImpl>(this, _$identity);
}

abstract class _TranslationHistoryState implements TranslationHistoryState {
  const factory _TranslationHistoryState(
      {final List<TranslationRecord> records,
      final bool isLoading,
      final String? error}) = _$TranslationHistoryStateImpl;

  @override
  List<TranslationRecord> get records;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of TranslationHistoryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranslationHistoryStateImplCopyWith<_$TranslationHistoryStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
