import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 翻譯快取項目
class TranslationCacheItem {
  final String text;
  final String targetLang;
  final String translatedText;
  final DateTime createdAt;

  TranslationCacheItem({
    required this.text,
    required this.targetLang,
    required this.translatedText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'targetLang': targetLang,
        'translatedText': translatedText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TranslationCacheItem.fromJson(Map<String, dynamic> json) {
    return TranslationCacheItem(
      text: json['text'] as String,
      targetLang: json['targetLang'] as String,
      translatedText: json['translatedText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// 客戶端翻譯快取服務
/// 使用 Hive 進行持久化快取
class TranslationCacheService {
  static const String _boxName = 'translation_cache';
  static const int _cacheExpirationDays = 7; // 快取過期時間：7 天

  Box<String>? _box;

  /// 初始化快取服務
  Future<void> init() async {
    if (_box != null) return;

    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  /// 生成快取鍵（SHA256 hash）
  String _generateCacheKey(String text, String targetLang) {
    final input = '$text|$targetLang';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 從快取中獲取翻譯
  Future<String?> getTranslation(String text, String targetLang) async {
    await init();

    try {
      final cacheKey = _generateCacheKey(text, targetLang);
      final cachedJson = _box!.get(cacheKey);

      if (cachedJson == null) {
        return null;
      }

      final cacheItem = TranslationCacheItem.fromJson(
        jsonDecode(cachedJson) as Map<String, dynamic>,
      );

      // 檢查是否過期
      final now = DateTime.now();
      final expirationDate = cacheItem.createdAt.add(
        Duration(days: _cacheExpirationDays),
      );

      if (now.isAfter(expirationDate)) {
        // 過期，刪除快取
        await _box!.delete(cacheKey);
        return null;
      }

      return cacheItem.translatedText;
    } catch (e) {
      // 快取讀取失敗，返回 null
      return null;
    }
  }

  /// 將翻譯結果寫入快取
  Future<void> setTranslation(
    String text,
    String targetLang,
    String translatedText,
  ) async {
    await init();

    try {
      final cacheKey = _generateCacheKey(text, targetLang);
      final cacheItem = TranslationCacheItem(
        text: text,
        targetLang: targetLang,
        translatedText: translatedText,
        createdAt: DateTime.now(),
      );

      await _box!.put(cacheKey, jsonEncode(cacheItem.toJson()));
    } catch (e) {
      // 快取寫入失敗，不拋出錯誤
      // 快取失敗不應影響翻譯功能
    }
  }

  /// 清理過期的快取
  Future<int> cleanupExpiredCache() async {
    await init();

    try {
      final now = DateTime.now();
      int deletedCount = 0;

      final keysToDelete = <String>[];

      for (final key in _box!.keys) {
        try {
          final cachedJson = _box!.get(key);
          if (cachedJson == null) continue;

          final cacheItem = TranslationCacheItem.fromJson(
            jsonDecode(cachedJson) as Map<String, dynamic>,
          );

          final expirationDate = cacheItem.createdAt.add(
            Duration(days: _cacheExpirationDays),
          );

          if (now.isAfter(expirationDate)) {
            keysToDelete.add(key as String);
          }
        } catch (e) {
          // 無法解析的快取項目，標記為刪除
          keysToDelete.add(key as String);
        }
      }

      for (final key in keysToDelete) {
        await _box!.delete(key);
        deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      return 0;
    }
  }

  /// 清空所有快取
  Future<void> clearAll() async {
    await init();
    await _box!.clear();
  }

  /// 獲取快取大小
  Future<int> getCacheSize() async {
    await init();
    return _box!.length;
  }
}

