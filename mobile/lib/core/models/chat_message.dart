import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// 聊天訊息模型
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,                    // 訊息 ID
    required String senderId,              // 發送者 Firebase UID
    required String receiverId,            // 接收者 Firebase UID
    String? senderName,                    // 發送者姓名
    String? receiverName,                  // 接收者姓名
    required String messageText,           // 訊息原文
    String? translatedText,                // 翻譯文字（保留，向後兼容）
    required DateTime createdAt,           // 發送時間
    DateTime? readAt,                      // 已讀時間

    // 新增：偵測到的語言（階段 1: 多語言翻譯系統）
    @Default('zh-TW') String detectedLang, // 偵測到的語言

    // 新增：多語言翻譯結果（階段 10: 完整多語言支援）
    // translations 格式：{ 'en': { 'text': '...', 'model': '...', ... }, 'ja': { ... } }
    @Default({}) Map<String, dynamic> translations, // 多語言翻譯結果
  }) = _ChatMessage;

  const ChatMessage._();

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// 從 Firestore 文檔創建訊息
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderName: data['senderName'],
      receiverName: data['receiverName'],
      messageText: data['messageText'] ?? '',
      translatedText: data['translatedText'],
      createdAt: _parseTimestamp(data['createdAt']),
      readAt: _parseOptionalTimestamp(data['readAt']),

      // 新增欄位（階段 1: 多語言翻譯系統）
      detectedLang: data['detectedLang'] ?? 'zh-TW',  // 默認繁體中文

      // 新增欄位（階段 10: 完整多語言支援）
      translations: data['translations'] != null
          ? Map<String, dynamic>.from(data['translations'] as Map)
          : {},
    );
  }

  /// 轉換為 Firestore 文檔
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'messageText': messageText,
      'translatedText': translatedText,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,

      // 新增欄位（階段 1: 多語言翻譯系統）
      'detectedLang': detectedLang,
    };
  }

  /// 解析 Timestamp（必填）
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  /// 解析 Timestamp（可選）
  static DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    return null;
  }

  /// 是否為我發送的訊息
  bool isMine(String currentUserId) {
    return senderId == currentUserId;
  }

  /// 是否已讀
  bool get isRead => readAt != null;

  /// 格式化時間顯示
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      // 今天：顯示時間
      return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // 昨天
      return '昨天 ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // 一週內：顯示星期
      const weekdays = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
      final weekday = weekdays[createdAt.weekday - 1];
      return '$weekday ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      // 超過一週：顯示日期
      return '${createdAt.month}/${createdAt.day} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    }
  }

}

/// ChatMessage 擴展方法
extension ChatMessageExtension on ChatMessage {
  /// 從 translations 中獲取特定語言的翻譯文字
  /// @param targetLang - 目標語言代碼（如 'en', 'ja', 'th'）
  /// @returns 翻譯文字，如果不存在則返回 null
  String? getTranslation(String targetLang) {
    if (translations.isEmpty) {
      return null;
    }

    final translation = translations[targetLang];
    if (translation == null) {
      return null;
    }

    // translation 可能是 Map<String, dynamic>
    if (translation is Map) {
      return translation['text'] as String?;
    }

    return null;
  }
}

