import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'translation_record.freezed.dart';
part 'translation_record.g.dart';

/// 翻譯記錄資料模型
@freezed
class TranslationRecord with _$TranslationRecord {
  const TranslationRecord._();

  @HiveType(typeId: 2, adapterName: 'TranslationRecordAdapter')
  const factory TranslationRecord({
    @HiveField(0) required String id,
    @HiveField(1) required String sourceText,
    @HiveField(2) required String translatedText,
    @HiveField(3) required String sourceLang,
    @HiveField(4) required String targetLang,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) required String userId,
    @HiveField(7) @Default(false) bool isFavorite,
  }) = _TranslationRecord;

  /// 從 JSON 創建
  factory TranslationRecord.fromJson(Map<String, dynamic> json) =>
      _$TranslationRecordFromJson(json);

  /// 獲取語言對顯示文字（例如：zh-TW → en）
  String get languagePair => '$sourceLang → $targetLang';

  /// 獲取格式化的創建時間
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return '剛剛';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分鐘前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小時前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${createdAt.year}/${createdAt.month}/${createdAt.day}';
    }
  }
}

