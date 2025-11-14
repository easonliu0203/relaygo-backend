import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

/// TTS 音訊快取管理器
///
/// Phase 5: 實作音訊快取機制
/// - 為相同的文字+語言組合快取 GPT 生成的音訊檔案
/// - 使用文字內容和語言代碼的 hash 作為快取 key
/// - 設定快取過期時間（7 天）
/// - 實作快取清理機制（避免佔用過多儲存空間）
/// - 快取大小限制（最多 50MB）
class TtsCacheManager {
  static final TtsCacheManager _instance = TtsCacheManager._internal();
  factory TtsCacheManager() => _instance;
  TtsCacheManager._internal();

  final Logger _logger = Logger();

  // 快取配置
  static const int _maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  static const int _cacheExpirationDays = 7; // 7 天
  static const String _cacheDirectoryName = 'tts_cache';
  static const String _cacheMetadataFileName = 'cache_metadata.json';

  Directory? _cacheDirectory;
  Map<String, CacheMetadata> _cacheMetadata = {};

  /// 初始化快取管理器
  Future<void> initialize() async {
    try {
      // 獲取應用的持久化儲存目錄
      final appDocDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDocDir.path}/$_cacheDirectoryName');

      // 創建快取目錄（如果不存在）
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
        _logger.i('🗂️ [TTS Cache] 快取目錄已創建: ${_cacheDirectory!.path}');
      }

      // 載入快取元數據
      await _loadCacheMetadata();

      // 清理過期快取
      await _cleanupExpiredCache();

      // 檢查快取大小並清理（如果超過限制）
      await _ensureCacheSizeLimit();

      _logger.i('🗂️ [TTS Cache] 快取管理器初始化完成');
    } catch (e, stackTrace) {
      _logger.e('🗂️ [TTS Cache] 初始化失敗: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// 生成快取 key（使用文字和語言的 hash）
  String _generateCacheKey(String text, String language) {
    final content = '$text|$language';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 檢查快取是否存在且未過期
  Future<String?> getCachedAudio(String text, String language) async {
    try {
      if (_cacheDirectory == null) {
        await initialize();
      }

      final cacheKey = _generateCacheKey(text, language);
      final metadata = _cacheMetadata[cacheKey];

      if (metadata == null) {
        _logger.d('🗂️ [TTS Cache] 快取未命中: $cacheKey');
        return null;
      }

      // 檢查快取是否過期
      final now = DateTime.now();
      final expirationDate = metadata.createdAt.add(Duration(days: _cacheExpirationDays));
      if (now.isAfter(expirationDate)) {
        _logger.i('🗂️ [TTS Cache] 快取已過期: $cacheKey');
        await _removeCacheEntry(cacheKey);
        return null;
      }

      // 檢查檔案是否存在
      final cacheFile = File(metadata.filePath);
      if (!await cacheFile.exists()) {
        _logger.w('🗂️ [TTS Cache] 快取檔案不存在: ${metadata.filePath}');
        await _removeCacheEntry(cacheKey);
        return null;
      }

      _logger.i('🗂️ [TTS Cache] 快取命中: $cacheKey');
      return metadata.filePath;

    } catch (e, stackTrace) {
      _logger.e('🗂️ [TTS Cache] 獲取快取失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      return null;
    }
  }

  /// 保存音訊到快取
  Future<String?> saveCachedAudio(String text, String language, List<int> audioBytes) async {
    try {
      if (_cacheDirectory == null) {
        await initialize();
      }

      final cacheKey = _generateCacheKey(text, language);
      final fileName = '$cacheKey.mp3';
      final filePath = '${_cacheDirectory!.path}/$fileName';
      final cacheFile = File(filePath);

      // 寫入音訊檔案
      await cacheFile.writeAsBytes(audioBytes);

      // 更新快取元數據
      final metadata = CacheMetadata(
        cacheKey: cacheKey,
        filePath: filePath,
        text: text,
        language: language,
        fileSize: audioBytes.length,
        createdAt: DateTime.now(),
      );

      _cacheMetadata[cacheKey] = metadata;
      await _saveCacheMetadata();

      _logger.i('🗂️ [TTS Cache] 音訊已快取: $cacheKey (${audioBytes.length} bytes)');

      // 檢查快取大小並清理（如果超過限制）
      await _ensureCacheSizeLimit();

      return filePath;

    } catch (e, stackTrace) {
      _logger.e('🗂️ [TTS Cache] 保存快取失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      return null;
    }
  }

  /// 載入快取元數據
  Future<void> _loadCacheMetadata() async {
    try {
      final metadataFile = File('${_cacheDirectory!.path}/$_cacheMetadataFileName');
      if (!await metadataFile.exists()) {
        _cacheMetadata = {};
        return;
      }

      final jsonString = await metadataFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      _cacheMetadata = jsonData.map((key, value) {
        return MapEntry(key, CacheMetadata.fromJson(value as Map<String, dynamic>));
      });

      _logger.i('🗂️ [TTS Cache] 已載入 ${_cacheMetadata.length} 個快取項目');
    } catch (e, stackTrace) {
      _logger.e('🗂️ [TTS Cache] 載入元數據失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      _cacheMetadata = {};
    }
  }

  /// 保存快取元數據
  Future<void> _saveCacheMetadata() async {
    try {
      final metadataFile = File('${_cacheDirectory!.path}/$_cacheMetadataFileName');
      final jsonData = _cacheMetadata.map((key, value) {
        return MapEntry(key, value.toJson());
      });

      final jsonString = jsonEncode(jsonData);
      await metadataFile.writeAsString(jsonString);

      _logger.d('🗂️ [TTS Cache] 元數據已保存');
    } catch (e, stackTrace) {
      _logger.e('🗂️ [TTS Cache] 保存元數據失敗: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// 清理過期快取
  Future<void> _cleanupExpiredCache() async {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];

      for (final entry in _cacheMetadata.entries) {
        final expirationDate = entry.value.createdAt.add(Duration(days: _cacheExpirationDays));
        if (now.isAfter(expirationDate)) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        await _removeCacheEntry(key);
      }

      if (expiredKeys.isNotEmpty) {
        _logger.i('🗂️ [TTS Cache] 已清理 ${expiredKeys.length} 個過期快取項目');
      }
    } catch (e, stackTrace) {
      _logger.e('🗂️ [TTS Cache] 清理過期快取失敗: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// 確保快取大小不超過限制
  Future<void> _ensureCacheSizeLimit() async {
    try {
      // 計算當前快取總大小
      int totalSize = 0;
      for (final metadata in _cacheMetadata.values) {
        totalSize += metadata.fileSize;
      }

      if (totalSize <= _maxCacheSizeBytes) {
        return;
      }

      _logger.i('🗂️ [TTS Cache] 快取大小超過限制: ${totalSize / 1024 / 1024} MB > ${_maxCacheSizeBytes / 1024 / 1024} MB');

      // 按創建時間排序（最舊的優先刪除）
      final sortedEntries = _cacheMetadata.entries.toList()
        ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

      // 刪除最舊的快取項目，直到大小低於限制
      for (final entry in sortedEntries) {
        if (totalSize <= _maxCacheSizeBytes) {
          break;
        }

        await _removeCacheEntry(entry.key);
        totalSize -= entry.value.fileSize;
      }

      _logger.i('🗂️ [TTS Cache] 快取清理完成，當前大小: ${totalSize / 1024 / 1024} MB');
    } catch (e, stackTrace) {
      _logger.e('🗂️ [TTS Cache] 確保快取大小限制失敗: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// 移除快取項目
  Future<void> _removeCacheEntry(String cacheKey) async {
    try {
      final metadata = _cacheMetadata[cacheKey];
      if (metadata == null) {
        return;
      }

      // 刪除檔案
      final cacheFile = File(metadata.filePath);
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }

      // 移除元數據
      _cacheMetadata.remove(cacheKey);
      await _saveCacheMetadata();

      _logger.d('🗂️ [TTS Cache] 已移除快取項目: $cacheKey');
    } catch (e, stackTrace) {
      _logger.e('🗂️ [TTS Cache] 移除快取項目失敗: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// 清空所有快取
  Future<void> clearAllCache() async {
    try {
      if (_cacheDirectory == null) {
        await initialize();
      }

      // 刪除所有快取檔案
      for (final metadata in _cacheMetadata.values) {
        final cacheFile = File(metadata.filePath);
        if (await cacheFile.exists()) {
          await cacheFile.delete();
        }
      }

      // 清空元數據
      _cacheMetadata.clear();
      await _saveCacheMetadata();

      _logger.i('🗂️ [TTS Cache] 所有快取已清空');
    } catch (e, stackTrace) {
      _logger.e('🗂️ [TTS Cache] 清空快取失敗: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// 獲取快取統計資訊
  Map<String, dynamic> getCacheStats() {
    int totalSize = 0;
    for (final metadata in _cacheMetadata.values) {
      totalSize += metadata.fileSize;
    }

    return {
      'totalEntries': _cacheMetadata.length,
      'totalSizeBytes': totalSize,
      'totalSizeMB': totalSize / 1024 / 1024,
      'maxSizeMB': _maxCacheSizeBytes / 1024 / 1024,
      'expirationDays': _cacheExpirationDays,
    };
  }
}

/// 快取元數據
class CacheMetadata {
  final String cacheKey;
  final String filePath;
  final String text;
  final String language;
  final int fileSize;
  final DateTime createdAt;

  CacheMetadata({
    required this.cacheKey,
    required this.filePath,
    required this.text,
    required this.language,
    required this.fileSize,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'cacheKey': cacheKey,
      'filePath': filePath,
      'text': text,
      'language': language,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CacheMetadata.fromJson(Map<String, dynamic> json) {
    return CacheMetadata(
      cacheKey: json['cacheKey'] as String,
      filePath: json['filePath'] as String,
      text: json['text'] as String,
      language: json['language'] as String,
      fileSize: json['fileSize'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

