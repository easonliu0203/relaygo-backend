import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/translation_record.dart';

/// 翻譯歷史記錄服務
/// 使用 Hive 進行本地儲存
class TranslationHistoryService {
  static const String _boxName = 'translation_history';
  static const int _maxRecords = 500; // 最多保存 500 條記錄
  static const int _expirationDays = 30; // 30 天過期

  final Logger _logger = Logger();
  Box<TranslationRecord>? _box;

  /// 初始化服務
  Future<void> initialize() async {
    try {
      if (_box != null && _box!.isOpen) {
        _logger.i('📚 [翻譯記錄] 服務已初始化');
        return;
      }

      // 註冊 Hive Adapter（如果尚未註冊）
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(TranslationRecordAdapter());
        _logger.i('📚 [翻譯記錄] TranslationRecordAdapter 已註冊');
      }

      // 打開 Hive Box
      _box = await Hive.openBox<TranslationRecord>(_boxName);
      _logger.i('📚 [翻譯記錄] Hive Box 已打開，當前記錄數: ${_box!.length}');

      // 初始化時清理過期記錄
      await cleanupExpiredRecords();

      _logger.i('📚 [翻譯記錄] 服務初始化成功');
    } catch (e, stackTrace) {
      _logger.e('📚 [翻譯記錄] 服務初始化失敗: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// 儲存翻譯記錄
  Future<void> saveRecord(TranslationRecord record) async {
    try {
      if (_box == null || !_box!.isOpen) {
        _logger.w('📚 [翻譯記錄] Box 未初始化，嘗試重新初始化');
        await initialize();
      }

      await _box?.put(record.id, record);
      _logger.i('📚 [翻譯記錄] 記錄已儲存: ${record.id}');
      _logger.d('📚 [翻譯記錄] 原文: "${record.sourceText}"');
      _logger.d('📚 [翻譯記錄] 譯文: "${record.translatedText}"');
      _logger.d('📚 [翻譯記錄] 語言對: ${record.languagePair}');

      // 檢查記錄數量，超過限制則刪除最舊的記錄
      if (_box!.length > _maxRecords) {
        _logger.w('📚 [翻譯記錄] 記錄數量超過限制 ($_maxRecords)，刪除最舊的記錄');
        await _cleanupOldestRecords();
      }
    } catch (e, stackTrace) {
      _logger.e('📚 [翻譯記錄] 儲存記錄失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 獲取所有翻譯記錄（按時間倒序）
  List<TranslationRecord> getAllRecords() {
    try {
      if (_box == null || !_box!.isOpen) {
        _logger.w('📚 [翻譯記錄] Box 未初始化，返回空列表');
        return [];
      }

      final records = _box!.values.toList();
      
      // 按創建時間倒序排序（最新的在最上方）
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _logger.i('📚 [翻譯記錄] 獲取所有記錄: ${records.length} 條');
      return records;
    } catch (e, stackTrace) {
      _logger.e('📚 [翻譯記錄] 獲取記錄失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      return [];
    }
  }

  /// 刪除單條記錄
  Future<void> deleteRecord(String recordId) async {
    try {
      if (_box == null || !_box!.isOpen) {
        _logger.w('📚 [翻譯記錄] Box 未初始化');
        return;
      }

      await _box?.delete(recordId);
      _logger.i('📚 [翻譯記錄] 記錄已刪除: $recordId');
    } catch (e, stackTrace) {
      _logger.e('📚 [翻譯記錄] 刪除記錄失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 刪除所有記錄
  Future<void> deleteAllRecords() async {
    try {
      if (_box == null || !_box!.isOpen) {
        _logger.w('📚 [翻譯記錄] Box 未初始化');
        return;
      }

      final count = _box!.length;
      await _box?.clear();
      _logger.i('📚 [翻譯記錄] 所有記錄已刪除: $count 條');
    } catch (e, stackTrace) {
      _logger.e('📚 [翻譯記錄] 刪除所有記錄失敗: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 清理過期記錄（30 天前的非收藏記錄）
  Future<void> cleanupExpiredRecords() async {
    try {
      if (_box == null || !_box!.isOpen) {
        _logger.w('📚 [翻譯記錄] Box 未初始化');
        return;
      }

      final now = DateTime.now();
      final expiredKeys = <String>[];

      for (var record in _box!.values) {
        // 收藏的記錄不刪除
        if (record.isFavorite) {
          continue;
        }

        final daysSinceCreation = now.difference(record.createdAt).inDays;
        if (daysSinceCreation > _expirationDays) {
          expiredKeys.add(record.id);
        }
      }

      if (expiredKeys.isNotEmpty) {
        await _box?.deleteAll(expiredKeys);
        _logger.i('📚 [翻譯記錄] 清理過期記錄: ${expiredKeys.length} 條');
      } else {
        _logger.d('📚 [翻譯記錄] 無過期記錄需要清理');
      }
    } catch (e, stackTrace) {
      _logger.e('📚 [翻譯記錄] 清理過期記錄失敗: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// 清理最舊的記錄（當記錄數量超過限制時）
  Future<void> _cleanupOldestRecords() async {
    try {
      if (_box == null || !_box!.isOpen) {
        return;
      }

      final records = _box!.values.toList();
      
      // 按創建時間排序（最舊的在最前面）
      records.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // 計算需要刪除的記錄數量
      final deleteCount = records.length - _maxRecords;
      if (deleteCount <= 0) {
        return;
      }

      // 刪除最舊的記錄（但保留收藏的記錄）
      final keysToDelete = <String>[];
      for (var i = 0; i < records.length && keysToDelete.length < deleteCount; i++) {
        if (!records[i].isFavorite) {
          keysToDelete.add(records[i].id);
        }
      }

      if (keysToDelete.isNotEmpty) {
        await _box?.deleteAll(keysToDelete);
        _logger.i('📚 [翻譯記錄] 清理最舊記錄: ${keysToDelete.length} 條');
      }
    } catch (e, stackTrace) {
      _logger.e('📚 [翻譯記錄] 清理最舊記錄失敗: $e');
      _logger.e('Stack trace: $stackTrace');
    }
  }

  /// 獲取記錄統計資訊
  Map<String, dynamic> getStats() {
    try {
      if (_box == null || !_box!.isOpen) {
        return {
          'totalRecords': 0,
          'favoriteRecords': 0,
        };
      }

      final totalRecords = _box!.length;
      final favoriteRecords = _box!.values.where((r) => r.isFavorite).length;

      return {
        'totalRecords': totalRecords,
        'favoriteRecords': favoriteRecords,
      };
    } catch (e) {
      _logger.e('📚 [翻譯記錄] 獲取統計資訊失敗: $e');
      return {
        'totalRecords': 0,
        'favoriteRecords': 0,
      };
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    try {
      await _box?.close();
      _logger.i('📚 [翻譯記錄] 服務已釋放');
    } catch (e) {
      _logger.e('📚 [翻譯記錄] 釋放服務失敗: $e');
    }
  }
}

