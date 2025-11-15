import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// 用戶個人資料模型
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String userId,
    String? email,  // ✅ 添加 email 欄位（從 users 表獲取，唯讀）
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    required DateTime createdAt,
    required DateTime updatedAt,

    // 新增：語言偏好設定（階段 1: 多語言翻譯系統）
    @Default('zh-TW') String preferredLang,           // 偏好語言
    @Default('zh-TW') String inputLangHint,           // 輸入語言提示
    @Default(false) bool hasCompletedLanguageWizard,  // 是否完成語言精靈
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

/// 用戶資料更新請求模型
@freezed
class UserProfileUpdateRequest with _$UserProfileUpdateRequest {
  const factory UserProfileUpdateRequest({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) = _UserProfileUpdateRequest;

  factory UserProfileUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$UserProfileUpdateRequestFromJson(json);
}

