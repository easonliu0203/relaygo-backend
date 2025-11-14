import 'translation_api_service.dart';
import 'translation_cache_service.dart';
import '../models/chat_message.dart';

/// 翻譯顯示服務
/// 實現語言優先順序邏輯和按需翻譯
class TranslationDisplayService {
  final TranslationApiService _apiService;
  final TranslationCacheService _cacheService;

  TranslationDisplayService({
    required TranslationApiService apiService,
    required TranslationCacheService cacheService,
  })  : _apiService = apiService,
        _cacheService = cacheService;

  /// 判斷是否需要翻譯
  /// @param detectedLang - 訊息的偵測語言
  /// @param targetLang - 目標顯示語言
  /// @returns true 如果需要翻譯
  bool shouldTranslate(String detectedLang, String targetLang) {
    return detectedLang != targetLang;
  }

  /// 獲取訊息的顯示文字
  /// @param message - 聊天訊息
  /// @param targetLang - 目標顯示語言
  /// @returns 顯示文字（原文或翻譯）
  Future<String> getDisplayText(ChatMessage message, String targetLang) async {
    // 如果不需要翻譯，直接返回原文
    if (!shouldTranslate(message.detectedLang, targetLang)) {
      return message.messageText;
    }

    // 需要翻譯，先檢查快取
    final cachedTranslation = await _cacheService.getTranslation(
      message.messageText,
      targetLang,
    );

    if (cachedTranslation != null) {
      return cachedTranslation;
    }

    // 快取未命中，調用 API
    try {
      final translatedText = await _apiService.translateText(
        message.messageText,
        targetLang,
      );

      // 寫入快取
      await _cacheService.setTranslation(
        message.messageText,
        targetLang,
        translatedText,
      );

      return translatedText;
    } catch (e) {
      // 翻譯失敗，返回原文
      return message.messageText;
    }
  }

  /// 批次獲取訊息的顯示文字
  /// @param messages - 聊天訊息列表
  /// @param targetLang - 目標顯示語言
  /// @returns 顯示文字列表
  Future<List<String>> getDisplayTextBatch(
    List<ChatMessage> messages,
    String targetLang,
  ) async {
    final results = <String>[];

    for (final message in messages) {
      final displayText = await getDisplayText(message, targetLang);
      results.add(displayText);
    }

    return results;
  }

  /// 預載入可視區訊息的翻譯
  /// @param messages - 可視區的訊息列表
  /// @param targetLang - 目標顯示語言
  Future<void> preloadTranslations(
    List<ChatMessage> messages,
    String targetLang,
  ) async {
    // 過濾出需要翻譯的訊息
    final messagesToTranslate = messages.where((message) {
      return shouldTranslate(message.detectedLang, targetLang);
    }).toList();

    if (messagesToTranslate.isEmpty) {
      return;
    }

    // 批次預載入（不等待結果）
    for (final message in messagesToTranslate) {
      // 異步預載入，不阻塞 UI
      getDisplayText(message, targetLang).catchError((e) {
        // 忽略預載入錯誤
      });
    }
  }
}

