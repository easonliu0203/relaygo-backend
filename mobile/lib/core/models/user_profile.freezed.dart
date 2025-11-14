// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  DateTime? get dateOfBirth => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get emergencyContactName => throw _privateConstructorUsedError;
  String? get emergencyContactPhone => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // 新增：語言偏好設定（階段 1: 多語言翻譯系統）
  String get preferredLang => throw _privateConstructorUsedError; // 偏好語言
  String get inputLangHint => throw _privateConstructorUsedError; // 輸入語言提示
  bool get hasCompletedLanguageWizard => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String? firstName,
      String? lastName,
      String? phone,
      String? avatarUrl,
      DateTime? dateOfBirth,
      String? gender,
      String? address,
      String? emergencyContactName,
      String? emergencyContactPhone,
      DateTime createdAt,
      DateTime updatedAt,
      String preferredLang,
      String inputLangHint,
      bool hasCompletedLanguageWizard});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? dateOfBirth = freezed,
    Object? gender = freezed,
    Object? address = freezed,
    Object? emergencyContactName = freezed,
    Object? emergencyContactPhone = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? preferredLang = null,
    Object? inputLangHint = null,
    Object? hasCompletedLanguageWizard = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContactName: freezed == emergencyContactName
          ? _value.emergencyContactName
          : emergencyContactName // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContactPhone: freezed == emergencyContactPhone
          ? _value.emergencyContactPhone
          : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      preferredLang: null == preferredLang
          ? _value.preferredLang
          : preferredLang // ignore: cast_nullable_to_non_nullable
              as String,
      inputLangHint: null == inputLangHint
          ? _value.inputLangHint
          : inputLangHint // ignore: cast_nullable_to_non_nullable
              as String,
      hasCompletedLanguageWizard: null == hasCompletedLanguageWizard
          ? _value.hasCompletedLanguageWizard
          : hasCompletedLanguageWizard // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String? firstName,
      String? lastName,
      String? phone,
      String? avatarUrl,
      DateTime? dateOfBirth,
      String? gender,
      String? address,
      String? emergencyContactName,
      String? emergencyContactPhone,
      DateTime createdAt,
      DateTime updatedAt,
      String preferredLang,
      String inputLangHint,
      bool hasCompletedLanguageWizard});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? dateOfBirth = freezed,
    Object? gender = freezed,
    Object? address = freezed,
    Object? emergencyContactName = freezed,
    Object? emergencyContactPhone = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? preferredLang = null,
    Object? inputLangHint = null,
    Object? hasCompletedLanguageWizard = null,
  }) {
    return _then(_$UserProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContactName: freezed == emergencyContactName
          ? _value.emergencyContactName
          : emergencyContactName // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContactPhone: freezed == emergencyContactPhone
          ? _value.emergencyContactPhone
          : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      preferredLang: null == preferredLang
          ? _value.preferredLang
          : preferredLang // ignore: cast_nullable_to_non_nullable
              as String,
      inputLangHint: null == inputLangHint
          ? _value.inputLangHint
          : inputLangHint // ignore: cast_nullable_to_non_nullable
              as String,
      hasCompletedLanguageWizard: null == hasCompletedLanguageWizard
          ? _value.hasCompletedLanguageWizard
          : hasCompletedLanguageWizard // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {required this.id,
      required this.userId,
      this.firstName,
      this.lastName,
      this.phone,
      this.avatarUrl,
      this.dateOfBirth,
      this.gender,
      this.address,
      this.emergencyContactName,
      this.emergencyContactPhone,
      required this.createdAt,
      required this.updatedAt,
      this.preferredLang = 'zh-TW',
      this.inputLangHint = 'zh-TW',
      this.hasCompletedLanguageWizard = false});

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String? phone;
  @override
  final String? avatarUrl;
  @override
  final DateTime? dateOfBirth;
  @override
  final String? gender;
  @override
  final String? address;
  @override
  final String? emergencyContactName;
  @override
  final String? emergencyContactPhone;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
// 新增：語言偏好設定（階段 1: 多語言翻譯系統）
  @override
  @JsonKey()
  final String preferredLang;
// 偏好語言
  @override
  @JsonKey()
  final String inputLangHint;
// 輸入語言提示
  @override
  @JsonKey()
  final bool hasCompletedLanguageWizard;

  @override
  String toString() {
    return 'UserProfile(id: $id, userId: $userId, firstName: $firstName, lastName: $lastName, phone: $phone, avatarUrl: $avatarUrl, dateOfBirth: $dateOfBirth, gender: $gender, address: $address, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, createdAt: $createdAt, updatedAt: $updatedAt, preferredLang: $preferredLang, inputLangHint: $inputLangHint, hasCompletedLanguageWizard: $hasCompletedLanguageWizard)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.emergencyContactName, emergencyContactName) ||
                other.emergencyContactName == emergencyContactName) &&
            (identical(other.emergencyContactPhone, emergencyContactPhone) ||
                other.emergencyContactPhone == emergencyContactPhone) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.preferredLang, preferredLang) ||
                other.preferredLang == preferredLang) &&
            (identical(other.inputLangHint, inputLangHint) ||
                other.inputLangHint == inputLangHint) &&
            (identical(other.hasCompletedLanguageWizard,
                    hasCompletedLanguageWizard) ||
                other.hasCompletedLanguageWizard ==
                    hasCompletedLanguageWizard));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      firstName,
      lastName,
      phone,
      avatarUrl,
      dateOfBirth,
      gender,
      address,
      emergencyContactName,
      emergencyContactPhone,
      createdAt,
      updatedAt,
      preferredLang,
      inputLangHint,
      hasCompletedLanguageWizard);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
      {required final String id,
      required final String userId,
      final String? firstName,
      final String? lastName,
      final String? phone,
      final String? avatarUrl,
      final DateTime? dateOfBirth,
      final String? gender,
      final String? address,
      final String? emergencyContactName,
      final String? emergencyContactPhone,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String preferredLang,
      final String inputLangHint,
      final bool hasCompletedLanguageWizard}) = _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  String? get phone;
  @override
  String? get avatarUrl;
  @override
  DateTime? get dateOfBirth;
  @override
  String? get gender;
  @override
  String? get address;
  @override
  String? get emergencyContactName;
  @override
  String? get emergencyContactPhone;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt; // 新增：語言偏好設定（階段 1: 多語言翻譯系統）
  @override
  String get preferredLang; // 偏好語言
  @override
  String get inputLangHint; // 輸入語言提示
  @override
  bool get hasCompletedLanguageWizard;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProfileUpdateRequest _$UserProfileUpdateRequestFromJson(
    Map<String, dynamic> json) {
  return _UserProfileUpdateRequest.fromJson(json);
}

/// @nodoc
mixin _$UserProfileUpdateRequest {
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  DateTime? get dateOfBirth => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get emergencyContactName => throw _privateConstructorUsedError;
  String? get emergencyContactPhone => throw _privateConstructorUsedError;

  /// Serializes this UserProfileUpdateRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfileUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileUpdateRequestCopyWith<UserProfileUpdateRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileUpdateRequestCopyWith<$Res> {
  factory $UserProfileUpdateRequestCopyWith(UserProfileUpdateRequest value,
          $Res Function(UserProfileUpdateRequest) then) =
      _$UserProfileUpdateRequestCopyWithImpl<$Res, UserProfileUpdateRequest>;
  @useResult
  $Res call(
      {String? firstName,
      String? lastName,
      String? phone,
      String? avatarUrl,
      DateTime? dateOfBirth,
      String? gender,
      String? address,
      String? emergencyContactName,
      String? emergencyContactPhone});
}

/// @nodoc
class _$UserProfileUpdateRequestCopyWithImpl<$Res,
        $Val extends UserProfileUpdateRequest>
    implements $UserProfileUpdateRequestCopyWith<$Res> {
  _$UserProfileUpdateRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfileUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? dateOfBirth = freezed,
    Object? gender = freezed,
    Object? address = freezed,
    Object? emergencyContactName = freezed,
    Object? emergencyContactPhone = freezed,
  }) {
    return _then(_value.copyWith(
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContactName: freezed == emergencyContactName
          ? _value.emergencyContactName
          : emergencyContactName // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContactPhone: freezed == emergencyContactPhone
          ? _value.emergencyContactPhone
          : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileUpdateRequestImplCopyWith<$Res>
    implements $UserProfileUpdateRequestCopyWith<$Res> {
  factory _$$UserProfileUpdateRequestImplCopyWith(
          _$UserProfileUpdateRequestImpl value,
          $Res Function(_$UserProfileUpdateRequestImpl) then) =
      __$$UserProfileUpdateRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? firstName,
      String? lastName,
      String? phone,
      String? avatarUrl,
      DateTime? dateOfBirth,
      String? gender,
      String? address,
      String? emergencyContactName,
      String? emergencyContactPhone});
}

/// @nodoc
class __$$UserProfileUpdateRequestImplCopyWithImpl<$Res>
    extends _$UserProfileUpdateRequestCopyWithImpl<$Res,
        _$UserProfileUpdateRequestImpl>
    implements _$$UserProfileUpdateRequestImplCopyWith<$Res> {
  __$$UserProfileUpdateRequestImplCopyWithImpl(
      _$UserProfileUpdateRequestImpl _value,
      $Res Function(_$UserProfileUpdateRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfileUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? phone = freezed,
    Object? avatarUrl = freezed,
    Object? dateOfBirth = freezed,
    Object? gender = freezed,
    Object? address = freezed,
    Object? emergencyContactName = freezed,
    Object? emergencyContactPhone = freezed,
  }) {
    return _then(_$UserProfileUpdateRequestImpl(
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      dateOfBirth: freezed == dateOfBirth
          ? _value.dateOfBirth
          : dateOfBirth // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContactName: freezed == emergencyContactName
          ? _value.emergencyContactName
          : emergencyContactName // ignore: cast_nullable_to_non_nullable
              as String?,
      emergencyContactPhone: freezed == emergencyContactPhone
          ? _value.emergencyContactPhone
          : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileUpdateRequestImpl implements _UserProfileUpdateRequest {
  const _$UserProfileUpdateRequestImpl(
      {this.firstName,
      this.lastName,
      this.phone,
      this.avatarUrl,
      this.dateOfBirth,
      this.gender,
      this.address,
      this.emergencyContactName,
      this.emergencyContactPhone});

  factory _$UserProfileUpdateRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileUpdateRequestImplFromJson(json);

  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  final String? phone;
  @override
  final String? avatarUrl;
  @override
  final DateTime? dateOfBirth;
  @override
  final String? gender;
  @override
  final String? address;
  @override
  final String? emergencyContactName;
  @override
  final String? emergencyContactPhone;

  @override
  String toString() {
    return 'UserProfileUpdateRequest(firstName: $firstName, lastName: $lastName, phone: $phone, avatarUrl: $avatarUrl, dateOfBirth: $dateOfBirth, gender: $gender, address: $address, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileUpdateRequestImpl &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.emergencyContactName, emergencyContactName) ||
                other.emergencyContactName == emergencyContactName) &&
            (identical(other.emergencyContactPhone, emergencyContactPhone) ||
                other.emergencyContactPhone == emergencyContactPhone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      firstName,
      lastName,
      phone,
      avatarUrl,
      dateOfBirth,
      gender,
      address,
      emergencyContactName,
      emergencyContactPhone);

  /// Create a copy of UserProfileUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileUpdateRequestImplCopyWith<_$UserProfileUpdateRequestImpl>
      get copyWith => __$$UserProfileUpdateRequestImplCopyWithImpl<
          _$UserProfileUpdateRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileUpdateRequestImplToJson(
      this,
    );
  }
}

abstract class _UserProfileUpdateRequest implements UserProfileUpdateRequest {
  const factory _UserProfileUpdateRequest(
      {final String? firstName,
      final String? lastName,
      final String? phone,
      final String? avatarUrl,
      final DateTime? dateOfBirth,
      final String? gender,
      final String? address,
      final String? emergencyContactName,
      final String? emergencyContactPhone}) = _$UserProfileUpdateRequestImpl;

  factory _UserProfileUpdateRequest.fromJson(Map<String, dynamic> json) =
      _$UserProfileUpdateRequestImpl.fromJson;

  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  String? get phone;
  @override
  String? get avatarUrl;
  @override
  DateTime? get dateOfBirth;
  @override
  String? get gender;
  @override
  String? get address;
  @override
  String? get emergencyContactName;
  @override
  String? get emergencyContactPhone;

  /// Create a copy of UserProfileUpdateRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileUpdateRequestImplCopyWith<_$UserProfileUpdateRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}
