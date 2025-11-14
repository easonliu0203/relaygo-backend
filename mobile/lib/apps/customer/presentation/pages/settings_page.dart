import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/user_language_preferences_provider.dart';
import '../../../../shared/utils/language_detector.dart';

/// 客戶端設定頁面
class CustomerSettingsPage extends ConsumerWidget {
  const CustomerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagePrefs = ref.watch(userLanguagePreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: const Color(0xFF2196F3), // 客戶端藍色主題
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // 語言設定區塊
          _buildSectionHeader('語言設定'),
          _buildLanguageSettingTile(
            context: context,
            ref: ref,
            title: '偏好語言',
            subtitle: '選擇您的顯示和輸入語言',
            currentValue: languagePrefs.preferredLang,
            onChanged: (value) async {
              try {
                // 同時更新 preferredLang 和 inputLangHint
                await ref
                    .read(userLanguagePreferencesProvider.notifier)
                    .updateBothLanguages(
                      preferredLang: value,
                      inputLangHint: value,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('語言設定已更新'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('更新失敗: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '💡 提示：此為全域設定，影響所有聊天室的預設語言。您也可以在個別聊天室中使用地球按鈕臨時切換語言。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Divider(height: 32),

          // 其他設定區塊（預留）
          _buildSectionHeader('通知設定'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('推播通知'),
            subtitle: const Text('管理推播通知偏好'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('通知設定功能開發中...')),
              );
            },
          ),
          const Divider(height: 32),

          _buildSectionHeader('關於'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('應用程式版本'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLanguageSettingTile({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required String currentValue,
    required Function(String) onChanged,
  }) {
    final languageName = LanguageDetector.supportedLanguages
        .firstWhere((lang) => lang['code'] == currentValue)['name']!;
    final languageFlag = LanguageDetector.supportedLanguages
        .firstWhere((lang) => lang['code'] == currentValue)['flag']!;

    return ListTile(
      leading: Text(languageFlag, style: const TextStyle(fontSize: 28)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageName,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        _showLanguageSelectionDialog(
          context: context,
          title: title,
          currentValue: currentValue,
          onChanged: onChanged,
        );
      },
    );
  }

  void _showLanguageSelectionDialog({
    required BuildContext context,
    required String title,
    required String currentValue,
    required Function(String) onChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
              final isSelected = code == currentValue;

              return ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 24)),
                title: Text(name),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                selected: isSelected,
                onTap: () {
                  Navigator.of(context).pop();
                  onChanged(code);
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

