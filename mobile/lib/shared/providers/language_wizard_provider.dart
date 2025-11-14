import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/language_detector.dart';

/// 語言精靈狀態
class LanguageWizardState {
  final String? selectedLanguage;
  final bool isLoading;
  final String? error;

  const LanguageWizardState({
    this.selectedLanguage,
    this.isLoading = false,
    this.error,
  });

  LanguageWizardState copyWith({
    String? selectedLanguage,
    bool? isLoading,
    String? error,
  }) {
    return LanguageWizardState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 語言精靈 Provider
class LanguageWizardNotifier extends StateNotifier<LanguageWizardState> {
  LanguageWizardNotifier() : super(LanguageWizardState(
    selectedLanguage: LanguageDetector.detectSystemLanguage(),
  ));

  /// 選擇語言
  void selectLanguage(String languageCode) {
    print('🌍 [LanguageWizard] 選擇語言: $languageCode');
    state = state.copyWith(selectedLanguage: languageCode);
  }

  /// 保存語言偏好
  Future<void> saveLanguagePreference(String userId) async {
    if (state.selectedLanguage == null) {
      state = state.copyWith(error: '請選擇一個語言');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('💾 [LanguageWizard] 保存語言偏好: ${state.selectedLanguage} for user: $userId');
      
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(userId).update({
        'preferredLang': state.selectedLanguage,
        'inputLangHint': state.selectedLanguage,
        'hasCompletedLanguageWizard': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [LanguageWizard] 語言偏好已保存');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      print('❌ [LanguageWizard] 保存語言偏好失敗: $e');
      state = state.copyWith(
        isLoading: false,
        error: '保存失敗: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// 跳過（使用系統語言）
  Future<void> skip(String userId) async {
    final systemLang = LanguageDetector.detectSystemLanguage();
    print('⏭️ [LanguageWizard] 跳過，使用系統語言: $systemLang');
    
    state = state.copyWith(selectedLanguage: systemLang);
    await saveLanguagePreference(userId);
  }
}

/// 語言精靈 Provider
final languageWizardProvider = StateNotifierProvider<LanguageWizardNotifier, LanguageWizardState>((ref) {
  return LanguageWizardNotifier();
});

