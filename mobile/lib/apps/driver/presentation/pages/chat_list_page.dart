import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/chat_room.dart';
import '../../../../core/providers/chat_providers.dart';
import '../../../../core/providers/firebase_providers.dart';
import 'chat_detail_page.dart';

/// 司機端聊天室列表頁面
class ChatListPage extends ConsumerWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoomsAsync = ref.watch(chatRoomsStreamProvider);
    final currentUser = ref.watch(firebaseServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天'),
        elevation: 0,
      ),
      body: chatRoomsAsync.when(
        data: (chatRooms) {
          if (chatRooms.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              // 刷新聊天室列表
              ref.invalidate(chatRoomsStreamProvider);
            },
            child: ListView.separated(
              itemCount: chatRooms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chatRoom = chatRooms[index];
                return _ChatRoomListItem(
                  chatRoom: chatRoom,
                  currentUserId: currentUser?.uid ?? '',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailPage(
                          chatRoom: chatRoom,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '載入聊天室失敗',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(chatRoomsStreamProvider);
                },
                child: const Text('重試'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 構建空狀態
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暫無聊天室',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '當接到訂單後，您可以在這裡與客戶聊天',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 聊天室列表項目
class _ChatRoomListItem extends StatelessWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final VoidCallback onTap;

  const _ChatRoomListItem({
    Key? key,
    required this.chatRoom,
    required this.currentUserId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final otherUserName = chatRoom.getOtherUserName(currentUserId);
    final unreadCount = chatRoom.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 頭像
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.grey[600],
                  ),
                ),
                // 未讀標記
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // 聊天室資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 對方姓名和時間
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUserName ?? '未知用戶',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (chatRoom.lastMessageTime != null)
                        Text(
                          chatRoom.formattedLastMessageTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 訂單資訊
                  if (chatRoom.pickupAddress != null)
                    Text(
                      '📍 ${chatRoom.pickupAddress}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),

                  // 最後訊息
                  if (chatRoom.lastMessage != null)
                    Text(
                      chatRoom.lastMessage!,
                      style: TextStyle(
                        fontSize: 14,
                        color: hasUnread ? Colors.black87 : Colors.grey[600],
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // 右箭頭
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

