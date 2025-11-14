import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/translation_history_provider.dart';
import '../../../../core/models/translation_record.dart';
import '../../../../core/l10n/app_localizations.dart';

/// 翻譯歷史記錄頁面
class TranslationHistoryPage extends ConsumerStatefulWidget {
  const TranslationHistoryPage({super.key});

  @override
  ConsumerState<TranslationHistoryPage> createState() => _TranslationHistoryPageState();
}

class _TranslationHistoryPageState extends ConsumerState<TranslationHistoryPage> {
  @override
  void initState() {
    super.initState();
    // 頁面初始化時載入記錄
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(translationHistoryProvider.notifier).loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(translationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translationHistory),
        elevation: 1,
        actions: [
          // 刪除所有記錄按鈕
          if (state.records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: l10n.deleteAllRecords,
              onPressed: () => _showDeleteAllDialog(context, ref),
            ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  /// 構建頁面主體
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    TranslationHistoryState state,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return _buildErrorState(context, state.error!);
    }

    if (state.records.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(translationHistoryProvider.notifier).loadRecords();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: state.records.length,
        itemBuilder: (context, index) {
          return _buildRecordCard(context, ref, state.records[index]);
        },
      ),
    );
  }

  /// 構建空狀態
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noTranslationRecords,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translationRecordsWillBeSavedHere,
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

  /// 構建錯誤狀態
  Widget _buildErrorState(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loadFailed,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 構建記錄卡片
  Widget _buildRecordCard(
    BuildContext context,
    WidgetRef ref,
    TranslationRecord record,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRecordDetailDialog(context, record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 頂部：語言對和時間
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 語言對
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record.languagePair,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // 時間
                  Text(
                    record.formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 原文
              Text(
                record.sourceText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 分隔線
              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              // 譯文
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.translatedText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 刪除按鈕
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: Colors.red[400],
                    tooltip: l10n.delete,
                    onPressed: () => _showDeleteRecordDialog(
                      context,
                      ref,
                      record,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顯示記錄詳情對話框
  void _showRecordDetailDialog(BuildContext context, TranslationRecord record) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.translate, size: 24),
            const SizedBox(width: 8),
            Text(record.languagePair),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 原文
              Text(
                l10n.sourceText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                record.sourceText,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              // 譯文
              Text(
                l10n.translatedText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                record.translatedText,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              // 時間
              Text(
                '${l10n.time}：${record.formattedTime}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // 複製原文
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: record.sourceText));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.sourceTextCopied)),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l10n.copySourceText),
          ),
          // 複製譯文
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: record.translatedText));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.translatedTextCopied)),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l10n.copyTranslatedText),
          ),
          // 關閉
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// 顯示刪除單條記錄確認對話框
  void _showDeleteRecordDialog(
    BuildContext context,
    WidgetRef ref,
    TranslationRecord record,
  ) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.confirmDeleteRecord),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(translationHistoryProvider.notifier)
                  .deleteRecord(record.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.recordDeleted)),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  /// 顯示刪除所有記錄確認對話框
  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAllRecords),
        content: Text(l10n.confirmDeleteAllRecords),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(translationHistoryProvider.notifier)
                  .deleteAllRecords();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.allRecordsDeleted)),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

