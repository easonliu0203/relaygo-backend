import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

part 'instant_translation_provider.freezed.dart';

/// 即時翻譯狀態
@freezed
class InstantTranslationState with _$InstantTranslationState {
  const factory InstantTranslationState({
    /// 來源語言
    @Default('zh-TW') String sourceLang,
    
    /// 目標語言
    @Default('en') String targetLang,
    
    /// 輸入的文字
    @Default('') String inputText,
    
    /// 翻譯結果
    String? translatedText,
    
    /// 是否正在翻譯
    @Default(false) bool isTranslating,
    
    /// 錯誤訊息
    String? error,
    
    /// 翻譯使用的模型
    String? model,
    
    /// 翻譯耗時（毫秒）
    int? duration,
    
    /// 使用的 Token 數量
    int? tokensUsed,
  }) = _InstantTranslationState;
}

/// 即時翻譯 Provider
class InstantTranslationNotifier extends StateNotifier<InstantTranslationState> {
  static const String _baseUrl =
      'https://asia-east1-ride-platform-f1676.cloudfunctions.net';

  InstantTranslationNotifier() : super(const InstantTranslationState());

  /// 設定來源語言
  void setSourceLang(String lang) {
    print('🌍 [InstantTranslation] 設定來源語言: $lang');
    state = state.copyWith(
      sourceLang: lang,
      // 清除翻譯結果（因為語言改變了）
      translatedText: null,
      error: null,
    );
  }

  /// 設定目標語言
  void setTargetLang(String lang) {
    print('🌍 [InstantTranslation] 設定目標語言: $lang');
    state = state.copyWith(
      targetLang: lang,
      // 清除翻譯結果（因為語言改變了）
      translatedText: null,
      error: null,
    );
  }

  /// 交換來源語言和目標語言
  void swapLanguages() {
    print('🔄 [InstantTranslation] 交換語言: ${state.sourceLang} ↔ ${state.targetLang}');
    
    final tempSourceLang = state.sourceLang;
    final tempTargetLang = state.targetLang;
    final tempInputText = state.inputText;
    final tempTranslatedText = state.translatedText;

    state = state.copyWith(
      sourceLang: tempTargetLang,
      targetLang: tempSourceLang,
      // 如果有翻譯結果，交換輸入和輸出
      inputText: tempTranslatedText ?? tempInputText,
      translatedText: tempInputText.isNotEmpty ? tempInputText : null,
    );
  }

  /// 設定輸入文字
  void setInputText(String text) {
    state = state.copyWith(
      inputText: text,
      // 清除錯誤訊息
      error: null,
    );
  }

  /// 清除輸入
  void clearInput() {
    print('🗑️ [InstantTranslation] 清除輸入');
    state = state.copyWith(
      inputText: '',
      translatedText: null,
      error: null,
      model: null,
      duration: null,
      tokensUsed: null,
    );
  }

  /// 執行翻譯
  Future<void> translate() async {
    // 驗證輸入
    if (state.inputText.trim().isEmpty) {
      state = state.copyWith(
        error: '請輸入要翻譯的文字',
      );
      return;
    }

    // 檢查來源語言和目標語言是否相同
    if (state.sourceLang == state.targetLang) {
      state = state.copyWith(
        error: '來源語言和目標語言不能相同',
      );
      return;
    }

    print('🔄 [InstantTranslation] 開始翻譯: ${state.inputText}');
    print('🔄 [InstantTranslation] ${state.sourceLang} → ${state.targetLang}');

    // 設定翻譯中狀態
    state = state.copyWith(
      isTranslating: true,
      error: null,
      translatedText: null,
    );

    try {
      final startTime = DateTime.now();

      // 調用翻譯 API
      final translatedText = await _callTranslationApi(
        text: state.inputText,
        sourceLang: state.sourceLang,
        targetLang: state.targetLang,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      print('✅ [InstantTranslation] 翻譯成功: $translatedText');
      print('⏱️ [InstantTranslation] 耗時: ${duration}ms');

      // 更新狀態
      state = state.copyWith(
        isTranslating: false,
        translatedText: translatedText,
        model: 'gpt-4o-mini',
        duration: duration,
        error: null,
      );
    } catch (e, stackTrace) {
      print('❌ [InstantTranslation] 翻譯失敗: $e');
      print('❌ [InstantTranslation] Stack trace: $stackTrace');

      state = state.copyWith(
        isTranslating: false,
        error: '翻譯失敗: ${e.toString()}',
      );
    }
  }

  /// 調用翻譯 API
  Future<String> _callTranslationApi({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      // 獲取 Firebase ID Token
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      // 發送請求
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'text': text,
          'sourceLang': sourceLang,
          'targetLang': targetLang,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('翻譯請求超時');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'] as String;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        final data = jsonDecode(response.body);
        final retryAfter = data['retryAfter'] ?? 60;
        throw Exception('請求過於頻繁，請在 $retryAfter 秒後重試');
      } else if (response.statusCode == 401) {
        throw Exception('未授權，請重新登入');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? '翻譯失敗');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('翻譯錯誤: ${e.toString()}');
    }
  }

  /// 重試翻譯
  Future<void> retry() async {
    print('🔄 [InstantTranslation] 重試翻譯');
    await translate();
  }
}

/// 即時翻譯 Provider
final instantTranslationProvider =
    StateNotifierProvider<InstantTranslationNotifier, InstantTranslationState>(
  (ref) {
    return InstantTranslationNotifier();
  },
);

