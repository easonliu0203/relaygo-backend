import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/chat_message.dart';
import '../../core/providers/translation_providers.dart';
import '../../shared/providers/chat_room_language_provider.dart';

/// 翻譯訊息氣泡組件
/// 根據語言優先順序顯示翻譯版本或原文
class TranslatedMessageBubble extends ConsumerStatefulWidget {
  final ChatMessage message;
  final String bookingId;
  final bool isMine;
  final bool showAvatar;
  final String? avatarUrl;

  const TranslatedMessageBubble({
    Key? key,
    required this.message,
    required this.bookingId,
    required this.isMine,
    this.showAvatar = true,
    this.avatarUrl,
  }) : super(key: key);

  @override
  ConsumerState<TranslatedMessageBubble> createState() => _TranslatedMessageBubbleState();
}

class _TranslatedMessageBubbleState extends ConsumerState<TranslatedMessageBubble> {
  String? _translatedText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTranslation();
  }

  /// 載入翻譯
  Future<void> _loadTranslation() async {
    // 獲取當前有效的顯示語言（使用 read，因為這是在異步方法中）
    final effectiveLanguage = ref.read(effectiveRoomLanguageProvider(widget.bookingId));

    // 如果訊息的語言與顯示語言相同，不需要翻譯
    if (widget.message.detectedLang == effectiveLanguage) {
      setState(() {
        _translatedText = null;
        _isLoading = false;
      });
      return;
    }

    // 優先順序 1: 使用 Firestore 中的 translations 物件（新系統）
    final translationFromMap = widget.message.getTranslation(effectiveLanguage);
    if (translationFromMap != null && translationFromMap.isNotEmpty) {
      setState(() {
        _translatedText = translationFromMap;
        _isLoading = false;
      });
      return;
    }

    // 優先順序 2: 使用 Firestore 中的 translatedText 欄位（舊系統，向後兼容）
    // 注意：translatedText 通常只包含英文翻譯，所以只在目標語言是英文時使用
    if (effectiveLanguage == 'en' &&
        widget.message.translatedText != null &&
        widget.message.translatedText!.isNotEmpty &&
        widget.message.translatedText != widget.message.messageText) {
      setState(() {
        _translatedText = widget.message.translatedText;
        _isLoading = false;
      });
      return;
    }

    // 優先順序 3: 調用翻譯服務（API 或快取）
    setState(() {
      _isLoading = true;
    });

    try {
      final displayService = ref.read(translationDisplayServiceProvider);
      final displayText = await displayService.getDisplayText(
        widget.message,
        effectiveLanguage,
      );

      // 如果翻譯結果與原文相同，表示翻譯失敗或不需要翻譯
      if (displayText == widget.message.messageText) {
        setState(() {
          _translatedText = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _translatedText = displayText;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 監聽有效語言變化（包括 roomViewLang 和 preferredLang 的變化）
    // 當語言改變時，重新載入翻譯
    ref.listen(effectiveRoomLanguageProvider(widget.bookingId), (previous, next) {
      if (previous != next) {
        _loadTranslation();
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 對方的頭像（左側）
          if (!widget.isMine && widget.showAvatar) _buildAvatar(),
          if (!widget.isMine && widget.showAvatar) const SizedBox(width: 8),

          // 訊息氣泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isMine
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(widget.isMine ? 16 : 4),
                  bottomRight: Radius.circular(widget.isMine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 翻譯文字（主要顯示，正常大小）
                  if (_translatedText != null && !_isLoading) ...[
                    Text(
                      _translatedText!,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.isMine ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 原文（灰色，正常大小）
                    Text(
                      widget.message.messageText,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.isMine
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ]
                  // 沒有翻譯時，只顯示原文
                  else if (!_isLoading)
                    Text(
                      widget.message.messageText,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.isMine ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    )
                  // 翻譯中
                  else
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isMine ? Colors.white : Colors.grey[600]!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '翻譯中...',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isMine
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),

                  // 時間和已讀狀態
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.message.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isMine
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black45,
                        ),
                      ),
                      // 已讀狀態（只顯示在自己的訊息上）
                      if (widget.isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          widget.message.isRead
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: widget.message.isRead
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
          if (widget.isMine && widget.showAvatar) const SizedBox(width: 8),
          if (widget.isMine && widget.showAvatar) _buildAvatar(),
        ],
      ),
    );
  }

  /// 構建頭像
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
      child: widget.avatarUrl == null
          ? Icon(
              Icons.person,
              size: 18,
              color: Colors.grey[600],
            )
          : null,
    );
  }
}

