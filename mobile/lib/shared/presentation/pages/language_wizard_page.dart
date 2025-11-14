import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/language_wizard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/language_detector.dart';
import '../../widgets/language_option_tile.dart';

/// 語言精靈畫面
/// 首次登入時引導用戶選擇偏好語言
class LanguageWizardPage extends ConsumerWidget {
  const LanguageWizardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(languageWizardProvider);
    final authState = ref.watch(authStateProvider);

    // 獲取當前用戶 ID
    String? userId;
    if (authState is AuthStateAuthenticated) {
      userId = authState.user.uid;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 標題區域
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    '選擇您的偏好語言',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '您可以隨時在設定中更改',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // 語言列表
            Expanded(
              child: ListView.builder(
                itemCount: LanguageDetector.supportedLanguages.length,
                itemBuilder: (context, index) {
                  final language = LanguageDetector.supportedLanguages[index];
                  final languageCode = language['code']!;
                  final languageName = language['name']!;
                  final flag = language['flag']!;
                  final isSelected = wizardState.selectedLanguage == languageCode;

                  return LanguageOptionTile(
                    languageCode: languageCode,
                    languageName: languageName,
                    flag: flag,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(languageWizardProvider.notifier).selectLanguage(languageCode);
                    },
                  );
                },
              ),
            ),

            // 錯誤訊息
            if (wizardState.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  wizardState.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // 按鈕區域
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // 跳過按鈕
                  Expanded(
                    child: OutlinedButton(
                      onPressed: wizardState.isLoading || userId == null
                          ? null
                          : () async {
                              try {
                                await ref.read(languageWizardProvider.notifier).skip(userId!);
                                if (context.mounted) {
                                  context.go('/home');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('跳過失敗: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '跳過',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 確認按鈕
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: wizardState.isLoading || 
                                 wizardState.selectedLanguage == null || 
                                 userId == null
                          ? null
                          : () async {
                              try {
                                await ref.read(languageWizardProvider.notifier).saveLanguagePreference(userId!);
                                if (context.mounted) {
                                  context.go('/home');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('保存失敗: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: wizardState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '確認',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

