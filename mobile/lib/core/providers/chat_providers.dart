import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import 'firebase_providers.dart';

/// ChatService Provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return ChatService(firebaseService);
});

/// 聊天室列表 Stream Provider
final chatRoomsStreamProvider = StreamProvider<List<ChatRoom>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChatRoomsStream();
});

/// 聊天訊息列表 Stream Provider（需要 bookingId）
final chatMessagesStreamProvider = StreamProvider.family<List<ChatMessage>, String>((ref, bookingId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getMessagesStream(bookingId);
});

/// 未讀訊息總數 Stream Provider
final totalUnreadCountStreamProvider = StreamProvider<int>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getTotalUnreadCountStream();
});

/// 發送訊息 Provider
final sendMessageProvider = Provider<Future<ChatMessage> Function({
  required String bookingId,
  required String receiverId,
  required String messageText,
})>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ({
    required String bookingId,
    required String receiverId,
    required String messageText,
  }) {
    return chatService.sendMessage(
      bookingId: bookingId,
      receiverId: receiverId,
      messageText: messageText,
    );
  };
});

/// 標記訊息為已讀 Provider
final markMessagesAsReadProvider = Provider<Future<void> Function(String)>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return (String bookingId) {
    return chatService.markMessagesAsRead(bookingId);
  };
});

/// 檢查是否可以發送訊息 Provider
final canSendMessageProvider = FutureProvider.family<bool, String>((ref, bookingId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.canSendMessage(bookingId);
});

