import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/chat_room.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/providers/chat_providers.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../shared/widgets/message_bubble.dart';
import '../../../../shared/widgets/translated_message_bubble.dart';
import '../../../../shared/widgets/language_switcher_bottom_sheet.dart';

/// 客戶端聊天室詳情頁面
class ChatDetailPage extends ConsumerStatefulWidget {
  final ChatRoom chatRoom;

  const ChatDetailPage({
    Key? key,
    required this.chatRoom,
  }) : super(key: key);

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // 進入頁面時標記訊息為已讀
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 標記訊息為已讀
  Future<void> _markMessagesAsRead() async {
    final markAsRead = ref.read(markMessagesAsReadProvider);
    try {
      await markAsRead(widget.chatRoom.bookingId);
    } catch (e) {
      print('標記訊息為已讀失敗: $e');
    }
  }

  /// 發送訊息
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = ref.read(firebaseServiceProvider).currentUser;
      if (currentUser == null) {
        throw Exception('用戶未登入');
      }

      final sendMessage = ref.read(sendMessageProvider);
      final receiverId = widget.chatRoom.getOtherUserId(currentUser.uid);

      if (receiverId == null) {
        throw Exception('無法獲取接收者 ID');
      }

      await sendMessage(
        bookingId: widget.chatRoom.bookingId,
        receiverId: receiverId,
        messageText: messageText,
      );

      _messageController.clear();
      
      // 滾動到底部
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('發送失敗: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  /// 滾動到底部
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(firebaseServiceProvider).currentUser;
    final messagesAsync = ref.watch(
      chatMessagesStreamProvider(widget.chatRoom.bookingId),
    );
    final otherUserName = widget.chatRoom.getOtherUserName(currentUser?.uid ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherUserName ?? '未知用戶'),
            if (widget.chatRoom.pickupAddress != null)
              Text(
                widget.chatRoom.pickupAddress!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        elevation: 1,
        actions: [
          // 語言切換按鈕
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: '切換顯示語言',
            onPressed: () {
              LanguageSwitcherBottomSheet.show(context, widget.chatRoom.bookingId);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 訂單資訊卡片
          if (widget.chatRoom.bookingTime != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '預約時間: ${widget.chatRoom.formattedBookingTime}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 訊息列表
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                // 滾動到底部（新訊息時）
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.isMine(currentUser?.uid ?? '');

                    // 檢查是否需要顯示日期分隔線
                    bool showDateDivider = false;
                    if (index == 0) {
                      showDateDivider = true;
                    } else {
                      final prevMessage = messages[index - 1];
                      final currentDate = DateTime(
                        message.createdAt.year,
                        message.createdAt.month,
                        message.createdAt.day,
                      );
                      final prevDate = DateTime(
                        prevMessage.createdAt.year,
                        prevMessage.createdAt.month,
                        prevMessage.createdAt.day,
                      );
                      showDateDivider = !currentDate.isAtSameMomentAs(prevDate);
                    }

                    return Column(
                      children: [
                        if (showDateDivider)
                          DateDivider(
                            date: _formatDate(message.createdAt),
                          ),
                        TranslatedMessageBubble(
                          message: message,
                          bookingId: widget.chatRoom.bookingId,
                          isMine: isMine,
                          showAvatar: true,
                        ),
                      ],
                    );
                  },
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
                      '載入訊息失敗',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(
                          chatMessagesStreamProvider(widget.chatRoom.bookingId),
                        );
                      },
                      child: const Text('重試'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 輸入框
          _buildInputArea(),
        ],
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
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '開始聊天吧！',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 構建輸入區域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '輸入訊息...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '今天';
    } else if (messageDate == yesterday) {
      return '昨天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}

