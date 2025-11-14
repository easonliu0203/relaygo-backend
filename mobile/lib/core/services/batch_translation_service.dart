import 'dart:async';
import 'translation_api_service.dart';
import 'translation_cache_service.dart';

/// 批次翻譯請求項目
class BatchTranslationRequest {
  final String text;
  final String targetLang;
  final Completer<String> completer;

  BatchTranslationRequest({
    required this.text,
    required this.targetLang,
    required this.completer,
  });
}

/// 批次翻譯服務
/// 將多個翻譯請求合併，減少 API 調用次數
class BatchTranslationService {
  final TranslationApiService _apiService;
  final TranslationCacheService _cacheService;
  final Duration _debounceDelay;

  final List<BatchTranslationRequest> _pendingRequests = [];
  Timer? _debounceTimer;

  BatchTranslationService({
    required TranslationApiService apiService,
    required TranslationCacheService cacheService,
    Duration debounceDelay = const Duration(milliseconds: 300),
  })  : _apiService = apiService,
        _cacheService = cacheService,
        _debounceDelay = debounceDelay;

  /// 請求翻譯（會被批次處理）
  /// @param text - 原文
  /// @param targetLang - 目標語言
  /// @returns Future<String> - 翻譯結果
  Future<String> translate(String text, String targetLang) async {
    // 先檢查快取
    final cachedTranslation = await _cacheService.getTranslation(text, targetLang);
    if (cachedTranslation != null) {
      return cachedTranslation;
    }

    // 創建請求
    final completer = Completer<String>();
    final request = BatchTranslationRequest(
      text: text,
      targetLang: targetLang,
      completer: completer,
    );

    // 添加到待處理列表
    _pendingRequests.add(request);

    // 重置 debounce 計時器
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, _processBatch);

    return completer.future;
  }

  /// 處理批次請求
  Future<void> _processBatch() async {
    if (_pendingRequests.isEmpty) {
      return;
    }

    // 取出所有待處理請求
    final requests = List<BatchTranslationRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    // 按目標語言分組
    final groupedRequests = <String, List<BatchTranslationRequest>>{};
    for (final request in requests) {
      groupedRequests.putIfAbsent(request.targetLang, () => []).add(request);
    }

    // 對每個語言組進行批次翻譯
    for (final entry in groupedRequests.entries) {
      final targetLang = entry.key;
      final langRequests = entry.value;

      try {
        // 提取文字列表
        final texts = langRequests.map((r) => r.text).toList();

        // 批次翻譯
        final translations = await _apiService.translateBatch(texts, targetLang);

        // 將結果寫入快取並返回給請求者
        for (int i = 0; i < langRequests.length; i++) {
          final request = langRequests[i];
          final translation = translations[i];

          // 寫入快取
          await _cacheService.setTranslation(
            request.text,
            targetLang,
            translation,
          );

          // 完成 Future
          request.completer.complete(translation);
        }
      } catch (e) {
        // 批次翻譯失敗，所有請求都返回原文
        for (final request in langRequests) {
          request.completer.complete(request.text);
        }
      }
    }
  }

  /// 清理資源
  void dispose() {
    _debounceTimer?.cancel();
    
    // 取消所有待處理請求
    for (final request in _pendingRequests) {
      request.completer.completeError(Exception('Service disposed'));
    }
    _pendingRequests.clear();
  }
}

