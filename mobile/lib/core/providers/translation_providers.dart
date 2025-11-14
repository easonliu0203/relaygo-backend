import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/translation_api_service.dart';
import '../services/translation_cache_service.dart';
import '../services/translation_display_service.dart';
import '../services/batch_translation_service.dart';

/// 翻譯 API 服務 Provider
final translationApiServiceProvider = Provider<TranslationApiService>((ref) {
  // TODO: 從環境變數或配置中讀取 baseUrl
  const baseUrl = 'https://asia-east1-ride-platform-f1676.cloudfunctions.net';
  return TranslationApiService(baseUrl: baseUrl);
});

/// 翻譯快取服務 Provider
final translationCacheServiceProvider = Provider<TranslationCacheService>((ref) {
  final service = TranslationCacheService();
  // 初始化快取服務
  service.init();
  return service;
});

/// 翻譯顯示服務 Provider
final translationDisplayServiceProvider = Provider<TranslationDisplayService>((ref) {
  final apiService = ref.watch(translationApiServiceProvider);
  final cacheService = ref.watch(translationCacheServiceProvider);
  
  return TranslationDisplayService(
    apiService: apiService,
    cacheService: cacheService,
  );
});

/// 批次翻譯服務 Provider
final batchTranslationServiceProvider = Provider<BatchTranslationService>((ref) {
  final apiService = ref.watch(translationApiServiceProvider);
  final cacheService = ref.watch(translationCacheServiceProvider);
  
  final service = BatchTranslationService(
    apiService: apiService,
    cacheService: cacheService,
  );

  // 當 Provider 被銷毀時清理資源
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

