import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// 用戶語言偏好狀態
class UserLanguagePreferences {
  final String preferredLang;
  final String inputLangHint;
  final bool isLoading;
  final String? error;

  const UserLanguagePreferences({
    required this.preferredLang,
    required this.inputLangHint,
    this.isLoading = false,
    this.error,
  });

  UserLanguagePreferences copyWith({
    String? preferredLang,
    String? inputLangHint,
    bool? isLoading,
    String? error,
  }) {
    return UserLanguagePreferences(
      preferredLang: preferredLang ?? this.preferredLang,
      inputLangHint: inputLangHint ?? this.inputLangHint,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 用戶語言偏好 Notifier
class UserLanguagePreferencesNotifier extends StateNotifier<UserLanguagePreferences> {
  final String userId;

  UserLanguagePreferencesNotifier(this.userId)
      : super(const UserLanguagePreferences(
          preferredLang: 'zh-TW',
          inputLangHint: 'zh-TW',
        )) {
    _loadPreferences();
  }

  /// 載入用戶語言偏好
  Future<void> _loadPreferences() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        state = UserLanguagePreferences(
          preferredLang: data['preferredLang'] ?? 'zh-TW',
          inputLangHint: data['inputLangHint'] ?? 'zh-TW',
        );
      }
    } catch (e) {
      state = state.copyWith(error: '載入語言偏好失敗: ${e.toString()}');
    }
  }

  /// 更新顯示語言偏好
  Future<void> updatePreferredLang(String languageCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'preferredLang': languageCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(
        preferredLang: languageCode,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '更新顯示語言失敗: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// 更新輸入語言提示
  Future<void> updateInputLangHint(String languageCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'inputLangHint': languageCode,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(
        inputLangHint: languageCode,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '更新輸入語言失敗: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// 同時更新兩個語言設定
  Future<void> updateBothLanguages({
    required String preferredLang,
    required String inputLangHint,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'preferredLang': preferredLang,
        'inputLangHint': inputLangHint,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(
        preferredLang: preferredLang,
        inputLangHint: inputLangHint,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '更新語言設定失敗: ${e.toString()}',
      );
      rethrow;
    }
  }
}

/// 用戶語言偏好 Provider
final userLanguagePreferencesProvider =
    StateNotifierProvider<UserLanguagePreferencesNotifier, UserLanguagePreferences>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState is AuthStateAuthenticated) {
    return UserLanguagePreferencesNotifier(authState.user.uid);
  }

  // 未登入時返回預設值
  return UserLanguagePreferencesNotifier('');
});

