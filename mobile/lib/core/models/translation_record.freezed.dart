// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'translation_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TranslationRecord _$TranslationRecordFromJson(Map<String, dynamic> json) {
  return _TranslationRecord.fromJson(json);
}

/// @nodoc
mixin _$TranslationRecord {
  @HiveField(0)
  String get id => throw _privateConstructorUsedError;
  @HiveField(1)
  String get sourceText => throw _privateConstructorUsedError;
  @HiveField(2)
  String get translatedText => throw _privateConstructorUsedError;
  @HiveField(3)
  String get sourceLang => throw _privateConstructorUsedError;
  @HiveField(4)
  String get targetLang => throw _privateConstructorUsedError;
  @HiveField(5)
  DateTime get createdAt => throw _privateConstructorUsedError;
  @HiveField(6)
  String get userId => throw _privateConstructorUsedError;
  @HiveField(7)
  bool get isFavorite => throw _privateConstructorUsedError;

  /// Serializes this TranslationRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TranslationRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranslationRecordCopyWith<TranslationRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranslationRecordCopyWith<$Res> {
  factory $TranslationRecordCopyWith(
          TranslationRecord value, $Res Function(TranslationRecord) then) =
      _$TranslationRecordCopyWithImpl<$Res, TranslationRecord>;
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String sourceText,
      @HiveField(2) String translatedText,
      @HiveField(3) String sourceLang,
      @HiveField(4) String targetLang,
      @HiveField(5) DateTime createdAt,
      @HiveField(6) String userId,
      @HiveField(7) bool isFavorite});
}

/// @nodoc
class _$TranslationRecordCopyWithImpl<$Res, $Val extends TranslationRecord>
    implements $TranslationRecordCopyWith<$Res> {
  _$TranslationRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TranslationRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceText = null,
    Object? translatedText = null,
    Object? sourceLang = null,
    Object? targetLang = null,
    Object? createdAt = null,
    Object? userId = null,
    Object? isFavorite = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceText: null == sourceText
          ? _value.sourceText
          : sourceText // ignore: cast_nullable_to_non_nullable
              as String,
      translatedText: null == translatedText
          ? _value.translatedText
          : translatedText // ignore: cast_nullable_to_non_nullable
              as String,
      sourceLang: null == sourceLang
          ? _value.sourceLang
          : sourceLang // ignore: cast_nullable_to_non_nullable
              as String,
      targetLang: null == targetLang
          ? _value.targetLang
          : targetLang // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TranslationRecordImplCopyWith<$Res>
    implements $TranslationRecordCopyWith<$Res> {
  factory _$$TranslationRecordImplCopyWith(_$TranslationRecordImpl value,
          $Res Function(_$TranslationRecordImpl) then) =
      __$$TranslationRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@HiveField(0) String id,
      @HiveField(1) String sourceText,
      @HiveField(2) String translatedText,
      @HiveField(3) String sourceLang,
      @HiveField(4) String targetLang,
      @HiveField(5) DateTime createdAt,
      @HiveField(6) String userId,
      @HiveField(7) bool isFavorite});
}

/// @nodoc
class __$$TranslationRecordImplCopyWithImpl<$Res>
    extends _$TranslationRecordCopyWithImpl<$Res, _$TranslationRecordImpl>
    implements _$$TranslationRecordImplCopyWith<$Res> {
  __$$TranslationRecordImplCopyWithImpl(_$TranslationRecordImpl _value,
      $Res Function(_$TranslationRecordImpl) _then)
      : super(_value, _then);

  /// Create a copy of TranslationRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceText = null,
    Object? translatedText = null,
    Object? sourceLang = null,
    Object? targetLang = null,
    Object? createdAt = null,
    Object? userId = null,
    Object? isFavorite = null,
  }) {
    return _then(_$TranslationRecordImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceText: null == sourceText
          ? _value.sourceText
          : sourceText // ignore: cast_nullable_to_non_nullable
              as String,
      translatedText: null == translatedText
          ? _value.translatedText
          : translatedText // ignore: cast_nullable_to_non_nullable
              as String,
      sourceLang: null == sourceLang
          ? _value.sourceLang
          : sourceLang // ignore: cast_nullable_to_non_nullable
              as String,
      targetLang: null == targetLang
          ? _value.targetLang
          : targetLang // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
@HiveType(typeId: 2, adapterName: 'TranslationRecordAdapter')
class _$TranslationRecordImpl extends _TranslationRecord {
  const _$TranslationRecordImpl(
      {@HiveField(0) required this.id,
      @HiveField(1) required this.sourceText,
      @HiveField(2) required this.translatedText,
      @HiveField(3) required this.sourceLang,
      @HiveField(4) required this.targetLang,
      @HiveField(5) required this.createdAt,
      @HiveField(6) required this.userId,
      @HiveField(7) this.isFavorite = false})
      : super._();

  factory _$TranslationRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranslationRecordImplFromJson(json);

  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String sourceText;
  @override
  @HiveField(2)
  final String translatedText;
  @override
  @HiveField(3)
  final String sourceLang;
  @override
  @HiveField(4)
  final String targetLang;
  @override
  @HiveField(5)
  final DateTime createdAt;
  @override
  @HiveField(6)
  final String userId;
  @override
  @JsonKey()
  @HiveField(7)
  final bool isFavorite;

  @override
  String toString() {
    return 'TranslationRecord(id: $id, sourceText: $sourceText, translatedText: $translatedText, sourceLang: $sourceLang, targetLang: $targetLang, createdAt: $createdAt, userId: $userId, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranslationRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sourceText, sourceText) ||
                other.sourceText == sourceText) &&
            (identical(other.translatedText, translatedText) ||
                other.translatedText == translatedText) &&
            (identical(other.sourceLang, sourceLang) ||
                other.sourceLang == sourceLang) &&
            (identical(other.targetLang, targetLang) ||
                other.targetLang == targetLang) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, sourceText, translatedText,
      sourceLang, targetLang, createdAt, userId, isFavorite);

  /// Create a copy of TranslationRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranslationRecordImplCopyWith<_$TranslationRecordImpl> get copyWith =>
      __$$TranslationRecordImplCopyWithImpl<_$TranslationRecordImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TranslationRecordImplToJson(
      this,
    );
  }
}

abstract class _TranslationRecord extends TranslationRecord {
  const factory _TranslationRecord(
      {@HiveField(0) required final String id,
      @HiveField(1) required final String sourceText,
      @HiveField(2) required final String translatedText,
      @HiveField(3) required final String sourceLang,
      @HiveField(4) required final String targetLang,
      @HiveField(5) required final DateTime createdAt,
      @HiveField(6) required final String userId,
      @HiveField(7) final bool isFavorite}) = _$TranslationRecordImpl;
  const _TranslationRecord._() : super._();

  factory _TranslationRecord.fromJson(Map<String, dynamic> json) =
      _$TranslationRecordImpl.fromJson;

  @override
  @HiveField(0)
  String get id;
  @override
  @HiveField(1)
  String get sourceText;
  @override
  @HiveField(2)
  String get translatedText;
  @override
  @HiveField(3)
  String get sourceLang;
  @override
  @HiveField(4)
  String get targetLang;
  @override
  @HiveField(5)
  DateTime get createdAt;
  @override
  @HiveField(6)
  String get userId;
  @override
  @HiveField(7)
  bool get isFavorite;

  /// Create a copy of TranslationRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranslationRecordImplCopyWith<_$TranslationRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
