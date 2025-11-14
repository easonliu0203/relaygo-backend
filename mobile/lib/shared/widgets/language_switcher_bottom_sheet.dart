import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_room_language_provider.dart';
import '../utils/language_detector.dart';

/// 語言切換底部選單
class LanguageSwitcherBottomSheet extends ConsumerWidget {
  final String bookingId;

  const LanguageSwitcherBottomSheet({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomLangState = ref.watch(chatRoomLanguageProvider(bookingId));
    final currentRoomLang = roomLangState.roomViewLang;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖動指示器
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 標題
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.language, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  '選擇顯示語言',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 「跟隨個人設定」選項
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.grey),
            title: const Text('跟隨個人設定'),
            subtitle: const Text('使用您在設定中選擇的偏好語言'),
            trailing: currentRoomLang == null
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            selected: currentRoomLang == null,
            onTap: () async {
              await ref
                  .read(chatRoomLanguageProvider(bookingId).notifier)
                  .setRoomLanguage(null);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),

          const Divider(height: 1),

          // 語言列表
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: LanguageDetector.supportedLanguages.length,
              itemBuilder: (context, index) {
                final language = LanguageDetector.supportedLanguages[index];
                final code = language['code']!;
                final name = language['name']!;
                final flag = language['flag']!;
                final isSelected = currentRoomLang == code;

                return ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 28)),
                  title: Text(name),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  selected: isSelected,
                  onTap: () async {
                    await ref
                        .read(chatRoomLanguageProvider(bookingId).notifier)
                        .setRoomLanguage(code);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),

          // 底部安全區域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// 顯示底部選單的靜態方法
  static Future<void> show(BuildContext context, String bookingId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LanguageSwitcherBottomSheet(bookingId: bookingId),
    );
  }
}

