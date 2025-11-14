import 'package:flutter/material.dart';
import '../../core/models/chat_message.dart';

/// 聊天訊息氣泡組件
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool showAvatar;
  final String? avatarUrl;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMine,
    this.showAvatar = true,
    this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 對方的頭像（左側）
          if (!isMine && showAvatar) _buildAvatar(),
          if (!isMine && showAvatar) const SizedBox(width: 8),

          // 訊息氣泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 原文
                  Text(
                    message.messageText,
                    style: TextStyle(
                      fontSize: 16,
                      color: isMine ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),

                  // 翻譯文字（如果有）
                  if (message.translatedText != null &&
                      message.translatedText!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isMine
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        message.translatedText!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMine
                              ? Colors.white.withOpacity(0.9)
                              : Colors.black54,
                          height: 1.3,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  // 時間和已讀狀態
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMine
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black45,
                        ),
                      ),
                      // 已讀狀態（只顯示在自己的訊息上）
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? Colors.blue[300]
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 自己的頭像（右側）
          if (isMine && showAvatar) const SizedBox(width: 8),
          if (isMine && showAvatar) _buildAvatar(),
        ],
      ),
    );
  }

  /// 構建頭像
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Icon(
              Icons.person,
              size: 18,
              color: Colors.grey[600],
            )
          : null,
    );
  }
}

/// 日期分隔線組件
class DateDivider extends StatelessWidget {
  final String date;

  const DateDivider({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }
}

/// 系統訊息組件（例如：「聊天已開啟」）
class SystemMessage extends StatelessWidget {
  final String message;

  const SystemMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

/// 輸入中指示器組件
class TypingIndicator extends StatefulWidget {
  final String userName;

  const TypingIndicator({
    Key? key,
    required this.userName,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            child: Icon(
              Icons.person,
              size: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.userName} 正在輸入',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  height: 12,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (index) {
                          final delay = index * 0.2;
                          final value = (_controller.value - delay) % 1.0;
                          final opacity = value < 0.5
                              ? value * 2
                              : (1.0 - value) * 2;
                          return Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[600]!.withOpacity(opacity),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

