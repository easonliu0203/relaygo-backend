import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/instant_translation_provider.dart';
import '../../../../shared/utils/language_detector.dart';

/// 即時翻譯頁面
class InstantTranslationPage extends ConsumerStatefulWidget {
  const InstantTranslationPage({super.key});

  @override
  ConsumerState<InstantTranslationPage> createState() =>
      _InstantTranslationPageState();
}

class _InstantTranslationPageState
    extends ConsumerState<InstantTranslationPage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // 監聽輸入變化
    _inputController.addListener(() {
      ref
          .read(instantTranslationProvider.notifier)
          .setInputText(_inputController.text);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantTranslationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('即時翻譯'),
        elevation: 1,
        actions: [
          // 清除按鈕
          if (state.inputText.isNotEmpty || state.translatedText != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: '清除全部',
              onPressed: () {
                _inputController.clear();
                ref.read(instantTranslationProvider.notifier).clearInput();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 語言選擇器區域
          _buildLanguageSelector(context, state),

          const Divider(height: 1),

          // 翻譯結果顯示區
          if (state.translatedText != null)
            _buildTranslationResult(context, state),

          // 輸入區域
          Expanded(
            child: _buildInputArea(context, state),
          ),

          // 底部操作欄
          _buildBottomBar(context, state),
        ],
      ),
    );
  }

  /// 語言選擇器
  Widget _buildLanguageSelector(
      BuildContext context, InstantTranslationState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // 來源語言選擇器
          Expanded(
            child: _buildLanguageButton(
              context: context,
              languageCode: state.sourceLang,
              onTap: () => _showLanguageSelector(
                context: context,
                title: '選擇來源語言',
                currentLang: state.sourceLang,
                onSelect: (lang) {
                  ref
                      .read(instantTranslationProvider.notifier)
                      .setSourceLang(lang);
                },
              ),
            ),
          ),

          // 交換按鈕
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: '交換語言',
            onPressed: () {
              ref.read(instantTranslationProvider.notifier).swapLanguages();
              // 如果有翻譯結果，更新輸入框
              final newState = ref.read(instantTranslationProvider);
              _inputController.text = newState.inputText;
            },
          ),

          // 目標語言選擇器
          Expanded(
            child: _buildLanguageButton(
              context: context,
              languageCode: state.targetLang,
              onTap: () => _showLanguageSelector(
                context: context,
                title: '選擇目標語言',
                currentLang: state.targetLang,
                onSelect: (lang) {
                  ref
                      .read(instantTranslationProvider.notifier)
                      .setTargetLang(lang);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 語言按鈕
  Widget _buildLanguageButton({
    required BuildContext context,
    required String languageCode,
    required VoidCallback onTap,
  }) {
    final languageInfo = LanguageDetector.getLanguageInfo(languageCode);
    final languageName = languageInfo?['name'] ?? languageCode;
    final languageFlag = languageInfo?['flag'] ?? '🌐';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(languageFlag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                languageName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  /// 翻譯結果顯示區
  Widget _buildTranslationResult(
      BuildContext context, InstantTranslationState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 翻譯結果文字
          SelectableText(
            state.translatedText!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // 操作按鈕行
          Row(
            children: [
              // 複製按鈕
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: state.translatedText!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已複製翻譯結果'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('複製'),
              ),

              const Spacer(),

              // 翻譯資訊
              if (state.model != null)
                Text(
                  '${state.model} • ${state.duration}ms',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 輸入區域
  Widget _buildInputArea(BuildContext context, InstantTranslationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 輸入框
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              maxLines: null,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '輸入要翻譯的文字...',
                border: InputBorder.none,
                counterText: '${state.inputText.length} / 500',
              ),
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),

          // 錯誤訊息
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 16, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 底部操作欄
  Widget _buildBottomBar(BuildContext context, InstantTranslationState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // 字數統計
          Text(
            '${state.inputText.length} / 500',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),

          const Spacer(),

          // 翻譯按鈕
          ElevatedButton.icon(
            onPressed: state.isTranslating || state.inputText.trim().isEmpty
                ? null
                : () {
                    _inputFocusNode.unfocus();
                    ref.read(instantTranslationProvider.notifier).translate();
                  },
            icon: state.isTranslating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.translate),
            label: Text(state.isTranslating ? '翻譯中...' : '翻譯'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 顯示語言選擇器
  void _showLanguageSelector({
    required BuildContext context,
    required String title,
    required String currentLang,
    required Function(String) onSelect,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: LanguageDetector.supportedLanguages.length,
            itemBuilder: (context, index) {
              final language = LanguageDetector.supportedLanguages[index];
              final code = language['code']!;
              final name = language['name']!;
              final flag = language['flag']!;
              final isSelected = code == currentLang;

              return ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 28)),
                title: Text(name),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                selected: isSelected,
                onTap: () {
                  onSelect(code);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}

