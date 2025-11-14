// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'instant_translation_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$InstantTranslationState {
  /// 來源語言
  String get sourceLang => throw _privateConstructorUsedError;

  /// 目標語言
  String get targetLang => throw _privateConstructorUsedError;

  /// 輸入的文字
  String get inputText => throw _privateConstructorUsedError;

  /// 翻譯結果
  String? get translatedText => throw _privateConstructorUsedError;

  /// 是否正在翻譯
  bool get isTranslating => throw _privateConstructorUsedError;

  /// 錯誤訊息
  String? get error => throw _privateConstructorUsedError;

  /// 翻譯使用的模型
  String? get model => throw _privateConstructorUsedError;

  /// 翻譯耗時（毫秒）
  int? get duration => throw _privateConstructorUsedError;

  /// 使用的 Token 數量
  int? get tokensUsed => throw _privateConstructorUsedError;

  /// Create a copy of InstantTranslationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InstantTranslationStateCopyWith<InstantTranslationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InstantTranslationStateCopyWith<$Res> {
  factory $InstantTranslationStateCopyWith(InstantTranslationState value,
          $Res Function(InstantTranslationState) then) =
      _$InstantTranslationStateCopyWithImpl<$Res, InstantTranslationState>;
  @useResult
  $Res call(
      {String sourceLang,
      String targetLang,
      String inputText,
      String? translatedText,
      bool isTranslating,
      String? error,
      String? model,
      int? duration,
      int? tokensUsed});
}

/// @nodoc
class _$InstantTranslationStateCopyWithImpl<$Res,
        $Val extends InstantTranslationState>
    implements $InstantTranslationStateCopyWith<$Res> {
  _$InstantTranslationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InstantTranslationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceLang = null,
    Object? targetLang = null,
    Object? inputText = null,
    Object? translatedText = freezed,
    Object? isTranslating = null,
    Object? error = freezed,
    Object? model = freezed,
    Object? duration = freezed,
    Object? tokensUsed = freezed,
  }) {
    return _then(_value.copyWith(
      sourceLang: null == sourceLang
          ? _value.sourceLang
          : sourceLang // ignore: cast_nullable_to_non_nullable
              as String,
      targetLang: null == targetLang
          ? _value.targetLang
          : targetLang // ignore: cast_nullable_to_non_nullable
              as String,
      inputText: null == inputText
          ? _value.inputText
          : inputText // ignore: cast_nullable_to_non_nullable
              as String,
      translatedText: freezed == translatedText
          ? _value.translatedText
          : translatedText // ignore: cast_nullable_to_non_nullable
              as String?,
      isTranslating: null == isTranslating
          ? _value.isTranslating
          : isTranslating // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      model: freezed == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String?,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int?,
      tokensUsed: freezed == tokensUsed
          ? _value.tokensUsed
          : tokensUsed // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InstantTranslationStateImplCopyWith<$Res>
    implements $InstantTranslationStateCopyWith<$Res> {
  factory _$$InstantTranslationStateImplCopyWith(
          _$InstantTranslationStateImpl value,
          $Res Function(_$InstantTranslationStateImpl) then) =
      __$$InstantTranslationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sourceLang,
      String targetLang,
      String inputText,
      String? translatedText,
      bool isTranslating,
      String? error,
      String? model,
      int? duration,
      int? tokensUsed});
}

/// @nodoc
class __$$InstantTranslationStateImplCopyWithImpl<$Res>
    extends _$InstantTranslationStateCopyWithImpl<$Res,
        _$InstantTranslationStateImpl>
    implements _$$InstantTranslationStateImplCopyWith<$Res> {
  __$$InstantTranslationStateImplCopyWithImpl(
      _$InstantTranslationStateImpl _value,
      $Res Function(_$InstantTranslationStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of InstantTranslationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sourceLang = null,
    Object? targetLang = null,
    Object? inputText = null,
    Object? translatedText = freezed,
    Object? isTranslating = null,
    Object? error = freezed,
    Object? model = freezed,
    Object? duration = freezed,
    Object? tokensUsed = freezed,
  }) {
    return _then(_$InstantTranslationStateImpl(
      sourceLang: null == sourceLang
          ? _value.sourceLang
          : sourceLang // ignore: cast_nullable_to_non_nullable
              as String,
      targetLang: null == targetLang
          ? _value.targetLang
          : targetLang // ignore: cast_nullable_to_non_nullable
              as String,
      inputText: null == inputText
          ? _value.inputText
          : inputText // ignore: cast_nullable_to_non_nullable
              as String,
      translatedText: freezed == translatedText
          ? _value.translatedText
          : translatedText // ignore: cast_nullable_to_non_nullable
              as String?,
      isTranslating: null == isTranslating
          ? _value.isTranslating
          : isTranslating // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      model: freezed == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String?,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int?,
      tokensUsed: freezed == tokensUsed
          ? _value.tokensUsed
          : tokensUsed // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$InstantTranslationStateImpl implements _InstantTranslationState {
  const _$InstantTranslationStateImpl(
      {this.sourceLang = 'zh-TW',
      this.targetLang = 'en',
      this.inputText = '',
      this.translatedText,
      this.isTranslating = false,
      this.error,
      this.model,
      this.duration,
      this.tokensUsed});

  /// 來源語言
  @override
  @JsonKey()
  final String sourceLang;

  /// 目標語言
  @override
  @JsonKey()
  final String targetLang;

  /// 輸入的文字
  @override
  @JsonKey()
  final String inputText;

  /// 翻譯結果
  @override
  final String? translatedText;

  /// 是否正在翻譯
  @override
  @JsonKey()
  final bool isTranslating;

  /// 錯誤訊息
  @override
  final String? error;

  /// 翻譯使用的模型
  @override
  final String? model;

  /// 翻譯耗時（毫秒）
  @override
  final int? duration;

  /// 使用的 Token 數量
  @override
  final int? tokensUsed;

  @override
  String toString() {
    return 'InstantTranslationState(sourceLang: $sourceLang, targetLang: $targetLang, inputText: $inputText, translatedText: $translatedText, isTranslating: $isTranslating, error: $error, model: $model, duration: $duration, tokensUsed: $tokensUsed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InstantTranslationStateImpl &&
            (identical(other.sourceLang, sourceLang) ||
                other.sourceLang == sourceLang) &&
            (identical(other.targetLang, targetLang) ||
                other.targetLang == targetLang) &&
            (identical(other.inputText, inputText) ||
                other.inputText == inputText) &&
            (identical(other.translatedText, translatedText) ||
                other.translatedText == translatedText) &&
            (identical(other.isTranslating, isTranslating) ||
                other.isTranslating == isTranslating) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.tokensUsed, tokensUsed) ||
                other.tokensUsed == tokensUsed));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      sourceLang,
      targetLang,
      inputText,
      translatedText,
      isTranslating,
      error,
      model,
      duration,
      tokensUsed);

  /// Create a copy of InstantTranslationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InstantTranslationStateImplCopyWith<_$InstantTranslationStateImpl>
      get copyWith => __$$InstantTranslationStateImplCopyWithImpl<
          _$InstantTranslationStateImpl>(this, _$identity);
}

abstract class _InstantTranslationState implements InstantTranslationState {
  const factory _InstantTranslationState(
      {final String sourceLang,
      final String targetLang,
      final String inputText,
      final String? translatedText,
      final bool isTranslating,
      final String? error,
      final String? model,
      final int? duration,
      final int? tokensUsed}) = _$InstantTranslationStateImpl;

  /// 來源語言
  @override
  String get sourceLang;

  /// 目標語言
  @override
  String get targetLang;

  /// 輸入的文字
  @override
  String get inputText;

  /// 翻譯結果
  @override
  String? get translatedText;

  /// 是否正在翻譯
  @override
  bool get isTranslating;

  /// 錯誤訊息
  @override
  String? get error;

  /// 翻譯使用的模型
  @override
  String? get model;

  /// 翻譯耗時（毫秒）
  @override
  int? get duration;

  /// 使用的 Token 數量
  @override
  int? get tokensUsed;

  /// Create a copy of InstantTranslationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InstantTranslationStateImplCopyWith<_$InstantTranslationStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
