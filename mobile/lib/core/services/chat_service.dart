import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'firebase_service.dart';

/// 聊天服務
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService;

  ChatService(this._firebaseService);

  /// 發送訊息（直接寫入 Firestore）
  Future<ChatMessage> sendMessage({
    required String bookingId,
    required String receiverId,
    required String messageText,
    String? inputLangHint, // 用戶的輸入語言提示（可選）
  }) async {
    try {
      // 獲取當前用戶
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('用戶未登入');
      }

      print('[ChatService] 開始發送訊息: bookingId=$bookingId, receiverId=$receiverId');

      // 獲取聊天室資訊
      final chatRoom = await getChatRoom(bookingId);
      if (chatRoom == null) {
        throw Exception('聊天室不存在');
      }

      // 獲取對方姓名
      final receiverName = chatRoom.getOtherUserName(currentUser.uid);
      final senderName = currentUser.uid == chatRoom.customerId
          ? chatRoom.customerName
          : chatRoom.driverName;

      // 獲取用戶的語言偏好（如果未提供）
      String detectedLang = inputLangHint ?? 'zh-TW';
      if (inputLangHint == null) {
        try {
          final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
          if (userDoc.exists) {
            detectedLang = userDoc.data()?['inputLangHint'] ?? 'zh-TW';
          }
        } catch (e) {
          print('[ChatService] 無法獲取用戶語言偏好，使用預設值: zh-TW');
        }
      }

      // 創建訊息對象
      final now = DateTime.now();
      final messageData = {
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'senderName': senderName ?? '用戶',
        'receiverName': receiverName,
        'messageText': messageText,
        'translatedText': null,
        'detectedLang': detectedLang, // 使用用戶的 inputLangHint 作為 detectedLang
        'createdAt': Timestamp.fromDate(now),
        'readAt': null,
      };

      // 寫入 Firestore
      final docRef = await _firestore
          .collection('chat_rooms')
          .doc(bookingId)
          .collection('messages')
          .add(messageData);

      print('[ChatService] ✅ 訊息已寫入 Firestore: ${docRef.id}');

      // 更新聊天室的最後訊息
      await _firestore
          .collection('chat_rooms')
          .doc(bookingId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        // 增加對方的未讀數量
        if (currentUser.uid == chatRoom.customerId)
          'driverUnreadCount': FieldValue.increment(1)
        else
          'customerUnreadCount': FieldValue.increment(1),
      });

      print('[ChatService] ✅ 聊天室已更新');

      // 返回訊息對象
      return ChatMessage(
        id: docRef.id,
        senderId: currentUser.uid,
        receiverId: receiverId,
        senderName: senderName,
        receiverName: receiverName,
        messageText: messageText,
        translatedText: null,
        createdAt: now,
        readAt: null,
      );
    } catch (e) {
      print('❌ 發送訊息失敗: $e');
      rethrow;
    }
  }

  /// 獲取聊天室列表（Stream）
  Stream<List<ChatRoom>> getChatRoomsStream() {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        return Stream.value([]);
      }

      // 由於 Firestore 不支持 OR 查詢，我們需要創建兩個獨立的查詢
      // 一個查詢 customerId，一個查詢 driverId
      final customerRoomsStream = _firestore
          .collection('chat_rooms')
          .where('customerId', isEqualTo: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());

      final driverRoomsStream = _firestore
          .collection('chat_rooms')
          .where('driverId', isEqualTo: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());

      // 合併兩個 Stream
      return Rx.combineLatest2<List<ChatRoom>, List<ChatRoom>, List<ChatRoom>>(
        customerRoomsStream,
        driverRoomsStream,
        (customerRooms, driverRooms) {
          // 合併並去重（使用 bookingId）
          final allRooms = <String, ChatRoom>{};
          for (final room in customerRooms) {
            allRooms[room.bookingId] = room;
          }
          for (final room in driverRooms) {
            allRooms[room.bookingId] = room;
          }

          // 按最後訊息時間排序
          final sortedRooms = allRooms.values.toList()
            ..sort((a, b) {
              if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
              if (a.lastMessageTime == null) return 1;
              if (b.lastMessageTime == null) return -1;
              return b.lastMessageTime!.compareTo(a.lastMessageTime!);
            });

          return sortedRooms;
        },
      );
    } catch (e) {
      print('❌ 獲取聊天室列表失敗: $e');
      return Stream.value([]);
    }
  }

  /// 獲取聊天訊息列表（Stream）
  Stream<List<ChatMessage>> getMessagesStream(String bookingId) {
    try {
      return _firestore
          .collection('chat_rooms')
          .doc(bookingId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('❌ 獲取聊天訊息失敗: $e');
      return Stream.value([]);
    }
  }

  /// 標記訊息為已讀（直接更新 Firestore）
  Future<void> markMessagesAsRead(String bookingId) async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('用戶未登入');
      }

      print('[ChatService] 開始標記訊息為已讀: bookingId=$bookingId');

      // 獲取聊天室資訊
      final chatRoom = await getChatRoom(bookingId);
      if (chatRoom == null) {
        print('[ChatService] ⚠️  聊天室不存在，跳過標記已讀');
        return;
      }

      // 更新聊天室的未讀數量
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // 根據當前用戶角色重置未讀數量
      if (currentUser.uid == chatRoom.customerId) {
        updateData['customerUnreadCount'] = 0;
      } else if (currentUser.uid == chatRoom.driverId) {
        updateData['driverUnreadCount'] = 0;
      }

      await _firestore
          .collection('chat_rooms')
          .doc(bookingId)
          .update(updateData);

      print('[ChatService] ✅ 訊息已標記為已讀');
    } catch (e) {
      print('[ChatService] ❌ 標記訊息失敗: $e');
      // 不拋出錯誤，因為這不是關鍵操作
    }
  }

  /// 獲取聊天室資訊
  Future<ChatRoom?> getChatRoom(String bookingId) async {
    try {
      final doc = await _firestore
          .collection('chat_rooms')
          .doc(bookingId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return ChatRoom.fromFirestore(doc);
    } catch (e) {
      print('❌ 獲取聊天室資訊失敗: $e');
      return null;
    }
  }

  /// 檢查是否可以發送訊息（24 小時限制）
  Future<bool> canSendMessage(String bookingId) async {
    try {
      final room = await getChatRoom(bookingId);
      if (room == null || room.bookingTime == null) {
        return false;
      }

      final now = DateTime.now();
      final hoursUntilBooking = room.bookingTime!.difference(now).inHours;

      // 訂單開始前 24 小時內可以發送訊息
      // 或訂單已經開始（時間為負數）
      return hoursUntilBooking <= 24;
    } catch (e) {
      print('❌ 檢查發送權限失敗: $e');
      return false;
    }
  }

  /// 獲取未讀訊息總數
  Stream<int> getTotalUnreadCountStream() {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        return Stream.value(0);
      }

      return getChatRoomsStream().map((rooms) {
        return rooms.fold<int>(
          0,
          (sum, room) => sum + room.getUnreadCount(currentUser.uid),
        );
      });
    } catch (e) {
      print('❌ 獲取未讀訊息總數失敗: $e');
      return Stream.value(0);
    }
  }
}

