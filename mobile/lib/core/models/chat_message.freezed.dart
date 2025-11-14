// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError; // 訊息 ID
  String get senderId => throw _privateConstructorUsedError; // 發送者 Firebase UID
  String get receiverId =>
      throw _privateConstructorUsedError; // 接收者 Firebase UID
  String? get senderName => throw _privateConstructorUsedError; // 發送者姓名
  String? get receiverName => throw _privateConstructorUsedError; // 接收者姓名
  String get messageText => throw _privateConstructorUsedError; // 訊息原文
  String? get translatedText =>
      throw _privateConstructorUsedError; // 翻譯文字（保留，向後兼容）
  DateTime get createdAt => throw _privateConstructorUsedError; // 發送時間
  DateTime? get readAt => throw _privateConstructorUsedError; // 已讀時間
// 新增：偵測到的語言（階段 1: 多語言翻譯系統）
  String get detectedLang => throw _privateConstructorUsedError; // 偵測到的語言
// 新增：多語言翻譯結果（階段 10: 完整多語言支援）
// translations 格式：{ 'en': { 'text': '...', 'model': '...', ... }, 'ja': { ... } }
  Map<String, dynamic> get translations => throw _privateConstructorUsedError;

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {String id,
      String senderId,
      String receiverId,
      String? senderName,
      String? receiverName,
      String messageText,
      String? translatedText,
      DateTime createdAt,
      DateTime? readAt,
      String detectedLang,
      Map<String, dynamic> translations});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? receiverId = null,
    Object? senderName = freezed,
    Object? receiverName = freezed,
    Object? messageText = null,
    Object? translatedText = freezed,
    Object? createdAt = null,
    Object? readAt = freezed,
    Object? detectedLang = null,
    Object? translations = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      receiverId: null == receiverId
          ? _value.receiverId
          : receiverId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      receiverName: freezed == receiverName
          ? _value.receiverName
          : receiverName // ignore: cast_nullable_to_non_nullable
              as String?,
      messageText: null == messageText
          ? _value.messageText
          : messageText // ignore: cast_nullable_to_non_nullable
              as String,
      translatedText: freezed == translatedText
          ? _value.translatedText
          : translatedText // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      detectedLang: null == detectedLang
          ? _value.detectedLang
          : detectedLang // ignore: cast_nullable_to_non_nullable
              as String,
      translations: null == translations
          ? _value.translations
          : translations // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String senderId,
      String receiverId,
      String? senderName,
      String? receiverName,
      String messageText,
      String? translatedText,
      DateTime createdAt,
      DateTime? readAt,
      String detectedLang,
      Map<String, dynamic> translations});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? receiverId = null,
    Object? senderName = freezed,
    Object? receiverName = freezed,
    Object? messageText = null,
    Object? translatedText = freezed,
    Object? createdAt = null,
    Object? readAt = freezed,
    Object? detectedLang = null,
    Object? translations = null,
  }) {
    return _then(_$ChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      receiverId: null == receiverId
          ? _value.receiverId
          : receiverId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      receiverName: freezed == receiverName
          ? _value.receiverName
          : receiverName // ignore: cast_nullable_to_non_nullable
              as String?,
      messageText: null == messageText
          ? _value.messageText
          : messageText // ignore: cast_nullable_to_non_nullable
              as String,
      translatedText: freezed == translatedText
          ? _value.translatedText
          : translatedText // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      detectedLang: null == detectedLang
          ? _value.detectedLang
          : detectedLang // ignore: cast_nullable_to_non_nullable
              as String,
      translations: null == translations
          ? _value._translations
          : translations // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl extends _ChatMessage {
  const _$ChatMessageImpl(
      {required this.id,
      required this.senderId,
      required this.receiverId,
      this.senderName,
      this.receiverName,
      required this.messageText,
      this.translatedText,
      required this.createdAt,
      this.readAt,
      this.detectedLang = 'zh-TW',
      final Map<String, dynamic> translations = const {}})
      : _translations = translations,
        super._();

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final String id;
// 訊息 ID
  @override
  final String senderId;
// 發送者 Firebase UID
  @override
  final String receiverId;
// 接收者 Firebase UID
  @override
  final String? senderName;
// 發送者姓名
  @override
  final String? receiverName;
// 接收者姓名
  @override
  final String messageText;
// 訊息原文
  @override
  final String? translatedText;
// 翻譯文字（保留，向後兼容）
  @override
  final DateTime createdAt;
// 發送時間
  @override
  final DateTime? readAt;
// 已讀時間
// 新增：偵測到的語言（階段 1: 多語言翻譯系統）
  @override
  @JsonKey()
  final String detectedLang;
// 偵測到的語言
// 新增：多語言翻譯結果（階段 10: 完整多語言支援）
// translations 格式：{ 'en': { 'text': '...', 'model': '...', ... }, 'ja': { ... } }
  final Map<String, dynamic> _translations;
// 偵測到的語言
// 新增：多語言翻譯結果（階段 10: 完整多語言支援）
// translations 格式：{ 'en': { 'text': '...', 'model': '...', ... }, 'ja': { ... } }
  @override
  @JsonKey()
  Map<String, dynamic> get translations {
    if (_translations is EqualUnmodifiableMapView) return _translations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_translations);
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, receiverId: $receiverId, senderName: $senderName, receiverName: $receiverName, messageText: $messageText, translatedText: $translatedText, createdAt: $createdAt, readAt: $readAt, detectedLang: $detectedLang, translations: $translations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.receiverId, receiverId) ||
                other.receiverId == receiverId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.receiverName, receiverName) ||
                other.receiverName == receiverName) &&
            (identical(other.messageText, messageText) ||
                other.messageText == messageText) &&
            (identical(other.translatedText, translatedText) ||
                other.translatedText == translatedText) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            (identical(other.detectedLang, detectedLang) ||
                other.detectedLang == detectedLang) &&
            const DeepCollectionEquality()
                .equals(other._translations, _translations));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      senderId,
      receiverId,
      senderName,
      receiverName,
      messageText,
      translatedText,
      createdAt,
      readAt,
      detectedLang,
      const DeepCollectionEquality().hash(_translations));

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage extends ChatMessage {
  const factory _ChatMessage(
      {required final String id,
      required final String senderId,
      required final String receiverId,
      final String? senderName,
      final String? receiverName,
      required final String messageText,
      final String? translatedText,
      required final DateTime createdAt,
      final DateTime? readAt,
      final String detectedLang,
      final Map<String, dynamic> translations}) = _$ChatMessageImpl;
  const _ChatMessage._() : super._();

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get id; // 訊息 ID
  @override
  String get senderId; // 發送者 Firebase UID
  @override
  String get receiverId; // 接收者 Firebase UID
  @override
  String? get senderName; // 發送者姓名
  @override
  String? get receiverName; // 接收者姓名
  @override
  String get messageText; // 訊息原文
  @override
  String? get translatedText; // 翻譯文字（保留，向後兼容）
  @override
  DateTime get createdAt; // 發送時間
  @override
  DateTime? get readAt; // 已讀時間
// 新增：偵測到的語言（階段 1: 多語言翻譯系統）
  @override
  String get detectedLang; // 偵測到的語言
// 新增：多語言翻譯結果（階段 10: 完整多語言支援）
// translations 格式：{ 'en': { 'text': '...', 'model': '...', ... }, 'ja': { ... } }
  @override
  Map<String, dynamic> get translations;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
