import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/models/translation_record.dart';
import '../../core/services/translation_history_service.dart';

part 'translation_history_provider.freezed.dart';

/// 翻譯歷史記錄服務 Provider（單例）
final translationHistoryServiceProvider = Provider<TranslationHistoryService>((ref) {
  return TranslationHistoryService();
});

/// 翻譯歷史記錄狀態
@freezed
class TranslationHistoryState with _$TranslationHistoryState {
  const factory TranslationHistoryState({
    @Default([]) List<TranslationRecord> records,
    @Default(false) bool isLoading,
    String? error,
  }) = _TranslationHistoryState;
}

/// 翻譯歷史記錄 Provider
final translationHistoryProvider =
    StateNotifierProvider<TranslationHistoryNotifier, TranslationHistoryState>(
  (ref) => TranslationHistoryNotifier(ref.read(translationHistoryServiceProvider)),
);

/// 翻譯歷史記錄 Notifier
class TranslationHistoryNotifier extends StateNotifier<TranslationHistoryState> {
  final TranslationHistoryService _service;

  TranslationHistoryNotifier(this._service) : super(const TranslationHistoryState()) {
    _initialize();
  }

  /// 初始化服務並載入記錄
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _service.initialize();
      await loadRecords();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '初始化失敗: ${e.toString()}',
      );
    }
  }

  /// 載入所有記錄
  Future<void> loadRecords() async {
    try {
      final records = _service.getAllRecords();
      state = state.copyWith(records: records, error: null);
    } catch (e) {
      state = state.copyWith(error: '載入記錄失敗: ${e.toString()}');
    }
  }

  /// 儲存翻譯記錄
  Future<void> saveRecord(TranslationRecord record) async {
    try {
      await _service.saveRecord(record);
      await loadRecords(); // 重新載入記錄
    } catch (e) {
      state = state.copyWith(error: '儲存記錄失敗: ${e.toString()}');
    }
  }

  /// 刪除單條記錄
  Future<void> deleteRecord(String recordId) async {
    try {
      await _service.deleteRecord(recordId);
      await loadRecords(); // 重新載入記錄
    } catch (e) {
      state = state.copyWith(error: '刪除記錄失敗: ${e.toString()}');
    }
  }

  /// 刪除所有記錄
  Future<void> deleteAllRecords() async {
    try {
      await _service.deleteAllRecords();
      await loadRecords(); // 重新載入記錄
    } catch (e) {
      state = state.copyWith(error: '刪除所有記錄失敗: ${e.toString()}');
    }
  }

  /// 清理過期記錄
  Future<void> cleanupExpiredRecords() async {
    try {
      await _service.cleanupExpiredRecords();
      await loadRecords(); // 重新載入記錄
    } catch (e) {
      state = state.copyWith(error: '清理過期記錄失敗: ${e.toString()}');
    }
  }

  /// 獲取統計資訊
  Map<String, dynamic> getStats() {
    return _service.getStats();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

