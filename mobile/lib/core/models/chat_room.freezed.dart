// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatRoom _$ChatRoomFromJson(Map<String, dynamic> json) {
  return _ChatRoom.fromJson(json);
}

/// @nodoc
mixin _$ChatRoom {
  String get bookingId => throw _privateConstructorUsedError; // 訂單 ID
  String get customerId =>
      throw _privateConstructorUsedError; // 客戶 Firebase UID
  String get driverId => throw _privateConstructorUsedError; // 司機 Firebase UID
  String? get customerName => throw _privateConstructorUsedError; // 客戶姓名
  String? get driverName => throw _privateConstructorUsedError; // 司機姓名
  String? get pickupAddress => throw _privateConstructorUsedError; // 上車地點
  DateTime? get bookingTime => throw _privateConstructorUsedError; // 預約時間
  String? get lastMessage => throw _privateConstructorUsedError; // 最後一則訊息
  DateTime? get lastMessageTime => throw _privateConstructorUsedError; // 最後訊息時間
  int get customerUnreadCount => throw _privateConstructorUsedError; // 客戶未讀數量
  int get driverUnreadCount => throw _privateConstructorUsedError; // 司機未讀數量
  DateTime? get updatedAt => throw _privateConstructorUsedError; // 更新時間
// 新增：成員列表和語言覆蓋（階段 1: 多語言翻譯系統）
  List<String> get memberIds => throw _privateConstructorUsedError; // 成員 UID 列表
  String? get roomLangOverride => throw _privateConstructorUsedError;

  /// Serializes this ChatRoom to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatRoomCopyWith<ChatRoom> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatRoomCopyWith<$Res> {
  factory $ChatRoomCopyWith(ChatRoom value, $Res Function(ChatRoom) then) =
      _$ChatRoomCopyWithImpl<$Res, ChatRoom>;
  @useResult
  $Res call(
      {String bookingId,
      String customerId,
      String driverId,
      String? customerName,
      String? driverName,
      String? pickupAddress,
      DateTime? bookingTime,
      String? lastMessage,
      DateTime? lastMessageTime,
      int customerUnreadCount,
      int driverUnreadCount,
      DateTime? updatedAt,
      List<String> memberIds,
      String? roomLangOverride});
}

/// @nodoc
class _$ChatRoomCopyWithImpl<$Res, $Val extends ChatRoom>
    implements $ChatRoomCopyWith<$Res> {
  _$ChatRoomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookingId = null,
    Object? customerId = null,
    Object? driverId = null,
    Object? customerName = freezed,
    Object? driverName = freezed,
    Object? pickupAddress = freezed,
    Object? bookingTime = freezed,
    Object? lastMessage = freezed,
    Object? lastMessageTime = freezed,
    Object? customerUnreadCount = null,
    Object? driverUnreadCount = null,
    Object? updatedAt = freezed,
    Object? memberIds = null,
    Object? roomLangOverride = freezed,
  }) {
    return _then(_value.copyWith(
      bookingId: null == bookingId
          ? _value.bookingId
          : bookingId // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      driverId: null == driverId
          ? _value.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: freezed == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      driverName: freezed == driverName
          ? _value.driverName
          : driverName // ignore: cast_nullable_to_non_nullable
              as String?,
      pickupAddress: freezed == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingTime: freezed == bookingTime
          ? _value.bookingTime
          : bookingTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageTime: freezed == lastMessageTime
          ? _value.lastMessageTime
          : lastMessageTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      customerUnreadCount: null == customerUnreadCount
          ? _value.customerUnreadCount
          : customerUnreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      driverUnreadCount: null == driverUnreadCount
          ? _value.driverUnreadCount
          : driverUnreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      memberIds: null == memberIds
          ? _value.memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      roomLangOverride: freezed == roomLangOverride
          ? _value.roomLangOverride
          : roomLangOverride // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatRoomImplCopyWith<$Res>
    implements $ChatRoomCopyWith<$Res> {
  factory _$$ChatRoomImplCopyWith(
          _$ChatRoomImpl value, $Res Function(_$ChatRoomImpl) then) =
      __$$ChatRoomImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String bookingId,
      String customerId,
      String driverId,
      String? customerName,
      String? driverName,
      String? pickupAddress,
      DateTime? bookingTime,
      String? lastMessage,
      DateTime? lastMessageTime,
      int customerUnreadCount,
      int driverUnreadCount,
      DateTime? updatedAt,
      List<String> memberIds,
      String? roomLangOverride});
}

/// @nodoc
class __$$ChatRoomImplCopyWithImpl<$Res>
    extends _$ChatRoomCopyWithImpl<$Res, _$ChatRoomImpl>
    implements _$$ChatRoomImplCopyWith<$Res> {
  __$$ChatRoomImplCopyWithImpl(
      _$ChatRoomImpl _value, $Res Function(_$ChatRoomImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookingId = null,
    Object? customerId = null,
    Object? driverId = null,
    Object? customerName = freezed,
    Object? driverName = freezed,
    Object? pickupAddress = freezed,
    Object? bookingTime = freezed,
    Object? lastMessage = freezed,
    Object? lastMessageTime = freezed,
    Object? customerUnreadCount = null,
    Object? driverUnreadCount = null,
    Object? updatedAt = freezed,
    Object? memberIds = null,
    Object? roomLangOverride = freezed,
  }) {
    return _then(_$ChatRoomImpl(
      bookingId: null == bookingId
          ? _value.bookingId
          : bookingId // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: null == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String,
      driverId: null == driverId
          ? _value.driverId
          : driverId // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: freezed == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      driverName: freezed == driverName
          ? _value.driverName
          : driverName // ignore: cast_nullable_to_non_nullable
              as String?,
      pickupAddress: freezed == pickupAddress
          ? _value.pickupAddress
          : pickupAddress // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingTime: freezed == bookingTime
          ? _value.bookingTime
          : bookingTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageTime: freezed == lastMessageTime
          ? _value.lastMessageTime
          : lastMessageTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      customerUnreadCount: null == customerUnreadCount
          ? _value.customerUnreadCount
          : customerUnreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      driverUnreadCount: null == driverUnreadCount
          ? _value.driverUnreadCount
          : driverUnreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      memberIds: null == memberIds
          ? _value._memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      roomLangOverride: freezed == roomLangOverride
          ? _value.roomLangOverride
          : roomLangOverride // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatRoomImpl extends _ChatRoom {
  const _$ChatRoomImpl(
      {required this.bookingId,
      required this.customerId,
      required this.driverId,
      this.customerName,
      this.driverName,
      this.pickupAddress,
      this.bookingTime,
      this.lastMessage,
      this.lastMessageTime,
      this.customerUnreadCount = 0,
      this.driverUnreadCount = 0,
      this.updatedAt,
      final List<String> memberIds = const [],
      this.roomLangOverride})
      : _memberIds = memberIds,
        super._();

  factory _$ChatRoomImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatRoomImplFromJson(json);

  @override
  final String bookingId;
// 訂單 ID
  @override
  final String customerId;
// 客戶 Firebase UID
  @override
  final String driverId;
// 司機 Firebase UID
  @override
  final String? customerName;
// 客戶姓名
  @override
  final String? driverName;
// 司機姓名
  @override
  final String? pickupAddress;
// 上車地點
  @override
  final DateTime? bookingTime;
// 預約時間
  @override
  final String? lastMessage;
// 最後一則訊息
  @override
  final DateTime? lastMessageTime;
// 最後訊息時間
  @override
  @JsonKey()
  final int customerUnreadCount;
// 客戶未讀數量
  @override
  @JsonKey()
  final int driverUnreadCount;
// 司機未讀數量
  @override
  final DateTime? updatedAt;
// 更新時間
// 新增：成員列表和語言覆蓋（階段 1: 多語言翻譯系統）
  final List<String> _memberIds;
// 更新時間
// 新增：成員列表和語言覆蓋（階段 1: 多語言翻譯系統）
  @override
  @JsonKey()
  List<String> get memberIds {
    if (_memberIds is EqualUnmodifiableListView) return _memberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memberIds);
  }

// 成員 UID 列表
  @override
  final String? roomLangOverride;

  @override
  String toString() {
    return 'ChatRoom(bookingId: $bookingId, customerId: $customerId, driverId: $driverId, customerName: $customerName, driverName: $driverName, pickupAddress: $pickupAddress, bookingTime: $bookingTime, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, customerUnreadCount: $customerUnreadCount, driverUnreadCount: $driverUnreadCount, updatedAt: $updatedAt, memberIds: $memberIds, roomLangOverride: $roomLangOverride)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatRoomImpl &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.driverId, driverId) ||
                other.driverId == driverId) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.driverName, driverName) ||
                other.driverName == driverName) &&
            (identical(other.pickupAddress, pickupAddress) ||
                other.pickupAddress == pickupAddress) &&
            (identical(other.bookingTime, bookingTime) ||
                other.bookingTime == bookingTime) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageTime, lastMessageTime) ||
                other.lastMessageTime == lastMessageTime) &&
            (identical(other.customerUnreadCount, customerUnreadCount) ||
                other.customerUnreadCount == customerUnreadCount) &&
            (identical(other.driverUnreadCount, driverUnreadCount) ||
                other.driverUnreadCount == driverUnreadCount) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality()
                .equals(other._memberIds, _memberIds) &&
            (identical(other.roomLangOverride, roomLangOverride) ||
                other.roomLangOverride == roomLangOverride));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      bookingId,
      customerId,
      driverId,
      customerName,
      driverName,
      pickupAddress,
      bookingTime,
      lastMessage,
      lastMessageTime,
      customerUnreadCount,
      driverUnreadCount,
      updatedAt,
      const DeepCollectionEquality().hash(_memberIds),
      roomLangOverride);

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatRoomImplCopyWith<_$ChatRoomImpl> get copyWith =>
      __$$ChatRoomImplCopyWithImpl<_$ChatRoomImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatRoomImplToJson(
      this,
    );
  }
}

abstract class _ChatRoom extends ChatRoom {
  const factory _ChatRoom(
      {required final String bookingId,
      required final String customerId,
      required final String driverId,
      final String? customerName,
      final String? driverName,
      final String? pickupAddress,
      final DateTime? bookingTime,
      final String? lastMessage,
      final DateTime? lastMessageTime,
      final int customerUnreadCount,
      final int driverUnreadCount,
      final DateTime? updatedAt,
      final List<String> memberIds,
      final String? roomLangOverride}) = _$ChatRoomImpl;
  const _ChatRoom._() : super._();

  factory _ChatRoom.fromJson(Map<String, dynamic> json) =
      _$ChatRoomImpl.fromJson;

  @override
  String get bookingId; // 訂單 ID
  @override
  String get customerId; // 客戶 Firebase UID
  @override
  String get driverId; // 司機 Firebase UID
  @override
  String? get customerName; // 客戶姓名
  @override
  String? get driverName; // 司機姓名
  @override
  String? get pickupAddress; // 上車地點
  @override
  DateTime? get bookingTime; // 預約時間
  @override
  String? get lastMessage; // 最後一則訊息
  @override
  DateTime? get lastMessageTime; // 最後訊息時間
  @override
  int get customerUnreadCount; // 客戶未讀數量
  @override
  int get driverUnreadCount; // 司機未讀數量
  @override
  DateTime? get updatedAt; // 更新時間
// 新增：成員列表和語言覆蓋（階段 1: 多語言翻譯系統）
  @override
  List<String> get memberIds; // 成員 UID 列表
  @override
  String? get roomLangOverride;

  /// Create a copy of ChatRoom
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatRoomImplCopyWith<_$ChatRoomImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
