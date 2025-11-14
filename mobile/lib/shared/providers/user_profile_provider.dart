import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/user_profile.dart';
import 'auth_provider.dart';

/// Supabase 服務提供者
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// 用戶資料提供者
final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  final currentUser = ref.watch(currentUserProvider).value;

  if (currentUser == null) {
    return null;
  }

  final supabaseService = ref.watch(supabaseServiceProvider);

  try {
    return await supabaseService.getUserProfile(currentUser.uid);
  } catch (e) {
    // 如果獲取失敗，返回 null
    return null;
  }
});

/// 用戶資料狀態通知器
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final SupabaseService _supabaseService;
  final User? _currentUser;

  UserProfileNotifier(this._supabaseService, this._currentUser)
      : super(const AsyncValue.loading()) {
    _loadUserProfile();
  }

  /// 載入用戶資料
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final profile = await _supabaseService.getUserProfile(_currentUser.uid);
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 重新載入用戶資料
  Future<void> reload() async {
    state = const AsyncValue.loading();
    await _loadUserProfile();
  }

  /// 更新用戶資料
  Future<void> updateProfile({
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
    if (_currentUser == null) {
      state = AsyncValue.error(
        Exception('用戶未登入'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final updatedProfile = await _supabaseService.upsertUserProfile(
        firebaseUid: _currentUser.uid,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        avatarUrl: avatarUrl,
        dateOfBirth: dateOfBirth,
        gender: gender,
        address: address,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );

      state = AsyncValue.data(updatedProfile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// 用戶資料狀態提供者
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
        (ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  return UserProfileNotifier(supabaseService, currentUser);
});

/// Firestore 用戶資料 Stream Provider
/// 監聽當前用戶的 Firestore 資料（包含語言偏好設定）
final firestoreUserProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState is! AuthStateAuthenticated) {
    return Stream.value(null);
  }

  final userId = authState.user.uid;

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        return snapshot.data();
      });
});

/// 檢查用戶是否完成語言精靈
final hasCompletedLanguageWizardProvider = Provider<bool>((ref) {
  final userDataAsync = ref.watch(firestoreUserProfileStreamProvider);

  return userDataAsync.when(
    data: (data) => data?['hasCompletedLanguageWizard'] ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});
