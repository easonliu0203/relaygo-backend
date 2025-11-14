import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../models/user_profile.dart';

/// Supabase 服務異常
class SupabaseServiceException implements Exception {
  final String message;
  final dynamic originalError;

  SupabaseServiceException(this.message, [this.originalError]);

  @override
  String toString() => 'SupabaseServiceException: $message';
}

/// Supabase 服務
/// 注意：個人資料相關操作已遷移到中台 API
class SupabaseService {
  late final SupabaseClient _client;

  // 中台 API 基礎 URL
  // 注意：
  // - Android 模擬器使用 10.0.2.2 訪問主機的 localhost
  // - iOS 模擬器使用 localhost 或 127.0.0.1
  // - 真機需要使用開發機器的 IP 地址
  static String get _apiBaseUrl {
    // 檢測平台並返回正確的 URL
    try {
      if (Platform.isAndroid) {
        // Android 模擬器使用 10.0.2.2 訪問主機的 localhost
        return 'http://10.0.2.2:3000/api';
      } else if (Platform.isIOS) {
        // iOS 模擬器可以直接使用 localhost
        return 'http://localhost:3000/api';
      } else {
        // 其他平台（Web、Desktop）使用 localhost
        return 'http://localhost:3000/api';
      }
    } catch (e) {
      // 如果無法檢測平台，默認使用 Android 模擬器的地址
      return 'http://10.0.2.2:3000/api';
    }
  }

  SupabaseService() {
    try {
      _client = Supabase.instance.client;
    } catch (e) {
      throw SupabaseServiceException(
        'Supabase 未初始化。請確保在應用啟動時調用 Supabase.initialize()',
        e,
      );
    }
  }

  /// 獲取當前用戶的個人資料
  /// [firebaseUid] Firebase 用戶 UID
  /// 注意：此方法現在調用中台 API 而不是直接訪問 Supabase
  Future<UserProfile?> getUserProfile(String firebaseUid) async {
    try {
      final url = Uri.parse('$_apiBaseUrl/profile/upsert?firebaseUid=$firebaseUid');

      print('📥 [SupabaseService] 獲取用戶資料');
      print('   URL: $url');
      print('   Firebase UID: $firebaseUid');

      final response = await http.get(url);

      print('📤 [SupabaseService] 響應狀態: ${response.statusCode}');

      if (response.statusCode == 404) {
        // 用戶不存在
        print('⚠️ [SupabaseService] 用戶不存在');
        return null;
      }

      if (response.statusCode != 200) {
        print('❌ [SupabaseService] 請求失敗');
        print('   狀態碼: ${response.statusCode}');
        print('   響應: ${response.body}');
        throw SupabaseServiceException(
          '獲取用戶資料失敗: ${response.statusCode}',
          response.body,
        );
      }

      final jsonData = json.decode(response.body);

      if (jsonData['success'] != true) {
        print('❌ [SupabaseService] API 返回錯誤');
        print('   錯誤: ${jsonData['error']}');
        throw SupabaseServiceException('獲取用戶資料失敗', jsonData['error']);
      }

      if (jsonData['data'] == null) {
        print('⚠️ [SupabaseService] 無資料');
        return null;
      }

      print('✅ [SupabaseService] 獲取成功');
      // API 返回的數據已經是 camelCase 格式
      return UserProfile.fromJson(jsonData['data']);
    } catch (e) {
      print('❌ [SupabaseService] 異常: $e');
      if (e is SupabaseServiceException) {
        rethrow;
      }
      throw SupabaseServiceException('獲取用戶資料失敗', e);
    }
  }

  // 注意：createUserProfile 和 updateUserProfile 方法已移除
  // 請使用 upsertUserProfile 方法，它會自動判斷是創建還是更新
  // 並通過中台 API 進行操作

  /// 創建或更新用戶個人資料
  /// [firebaseUid] Firebase 用戶 UID
  /// 注意：此方法現在調用中台 API 而不是直接訪問 Supabase
  Future<UserProfile> upsertUserProfile({
    required String firebaseUid,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    try {
      final url = Uri.parse('$_apiBaseUrl/profile/upsert');

      // 準備請求數據
      final requestData = {
        'firebaseUid': firebaseUid,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
        if (gender != null) 'gender': gender,
        if (address != null) 'address': address,
        if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
        if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
      };

      print('📥 [SupabaseService] 保存用戶資料');
      print('   URL: $url');
      print('   Firebase UID: $firebaseUid');
      print('   數據: $requestData');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print('📤 [SupabaseService] 響應狀態: ${response.statusCode}');
      print('   響應內容: ${response.body}');

      if (response.statusCode != 200) {
        print('❌ [SupabaseService] 請求失敗');
        try {
          final errorData = json.decode(response.body);
          print('   錯誤: ${errorData['error']}');
          print('   訊息: ${errorData['message']}');
          throw SupabaseServiceException(
            '保存用戶資料失敗: ${errorData['error'] ?? response.statusCode}',
            errorData['message'],
          );
        } catch (e) {
          print('   無法解析錯誤響應: $e');
          throw SupabaseServiceException(
            '保存用戶資料失敗: ${response.statusCode}',
            response.body,
          );
        }
      }

      final jsonData = json.decode(response.body);

      if (jsonData['success'] != true) {
        print('❌ [SupabaseService] API 返回錯誤');
        print('   錯誤: ${jsonData['error']}');
        throw SupabaseServiceException('保存用戶資料失敗', jsonData['error']);
      }

      print('✅ [SupabaseService] 保存成功');
      // API 返回的數據已經是 camelCase 格式
      return UserProfile.fromJson(jsonData['data']);
    } catch (e) {
      print('❌ [SupabaseService] 異常: $e');
      if (e is SupabaseServiceException) {
        rethrow;
      }
      throw SupabaseServiceException('保存用戶資料失敗', e);
    }
  }

  // 注意：deleteUserProfile 方法已移除
  // 如果需要刪除功能，請在中台 API 中實作
}

