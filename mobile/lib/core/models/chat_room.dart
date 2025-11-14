import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room.freezed.dart';
part 'chat_room.g.dart';

/// 聊天室模型
@freezed
class ChatRoom with _$ChatRoom {
  const factory ChatRoom({
    required String bookingId,             // 訂單 ID
    required String customerId,            // 客戶 Firebase UID
    required String driverId,              // 司機 Firebase UID
    String? customerName,                  // 客戶姓名
    String? driverName,                    // 司機姓名
    String? pickupAddress,                 // 上車地點
    DateTime? bookingTime,                 // 預約時間
    String? lastMessage,                   // 最後一則訊息
    DateTime? lastMessageTime,             // 最後訊息時間
    @Default(0) int customerUnreadCount,   // 客戶未讀數量
    @Default(0) int driverUnreadCount,     // 司機未讀數量
    DateTime? updatedAt,                   // 更新時間

    // 新增：成員列表和語言覆蓋（階段 1: 多語言翻譯系統）
    @Default([]) List<String> memberIds,   // 成員 UID 列表
    String? roomLangOverride,              // 聊天室語言覆蓋（可選）
  }) = _ChatRoom;

  const ChatRoom._();

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);

  /// 從 Firestore 文檔創建聊天室
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatRoom(
      bookingId: doc.id,
      customerId: data['customerId'] ?? '',
      driverId: data['driverId'] ?? '',
      customerName: data['customerName'],
      driverName: data['driverName'],
      pickupAddress: data['pickupAddress'],
      bookingTime: _parseOptionalTimestamp(data['bookingTime']),
      lastMessage: data['lastMessage'],
      lastMessageTime: _parseOptionalTimestamp(data['lastMessageTime']),
      customerUnreadCount: data['customerUnreadCount'] ?? 0,
      driverUnreadCount: data['driverUnreadCount'] ?? 0,
      updatedAt: _parseOptionalTimestamp(data['updatedAt']),

      // 新增欄位（階段 1: 多語言翻譯系統）
      memberIds: data['memberIds'] != null
        ? List<String>.from(data['memberIds'])
        : [data['customerId'] ?? '', data['driverId'] ?? ''],
      roomLangOverride: data['roomLangOverride'],
    );
  }

  /// 轉換為 Firestore 文檔
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'driverId': driverId,
      'customerName': customerName,
      'driverName': driverName,
      'pickupAddress': pickupAddress,
      'bookingTime': bookingTime != null ? Timestamp.fromDate(bookingTime!) : null,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'customerUnreadCount': customerUnreadCount,
      'driverUnreadCount': driverUnreadCount,
      'updatedAt': Timestamp.fromDate(DateTime.now()),

      // 新增欄位（階段 1: 多語言翻譯系統）
      'memberIds': memberIds.isNotEmpty ? memberIds : [customerId, driverId],
      if (roomLangOverride != null) 'roomLangOverride': roomLangOverride,
    };
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

  /// 獲取對方的姓名
  String getOtherUserName(String currentUserId) {
    return currentUserId == customerId ? (driverName ?? '司機') : (customerName ?? '客戶');
  }

  /// 獲取對方的 ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == customerId ? driverId : customerId;
  }

  /// 獲取未讀數量
  int getUnreadCount(String currentUserId) {
    return currentUserId == customerId ? customerUnreadCount : driverUnreadCount;
  }

  /// 格式化預約時間顯示
  String get formattedBookingTime {
    if (bookingTime == null) return '';

    final now = DateTime.now();
    final difference = bookingTime!.difference(now);

    if (difference.inDays == 0) {
      // 今天
      return '今天 ${bookingTime!.hour.toString().padLeft(2, '0')}:${bookingTime!.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // 明天
      return '明天 ${bookingTime!.hour.toString().padLeft(2, '0')}:${bookingTime!.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // 一週內
      const weekdays = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
      final weekday = weekdays[bookingTime!.weekday - 1];
      return '$weekday ${bookingTime!.hour.toString().padLeft(2, '0')}:${bookingTime!.minute.toString().padLeft(2, '0')}';
    } else {
      // 超過一週
      return '${bookingTime!.month}/${bookingTime!.day} ${bookingTime!.hour.toString().padLeft(2, '0')}:${bookingTime!.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化最後訊息時間顯示
  String get formattedLastMessageTime {
    if (lastMessageTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);

    if (difference.inMinutes < 1) {
      return '剛剛';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分鐘前';
    } else if (difference.inDays == 0) {
      return '${difference.inHours} 小時前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      const weekdays = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
      return weekdays[lastMessageTime!.weekday - 1];
    } else {
      return '${lastMessageTime!.month}/${lastMessageTime!.day}';
    }
  }
}

