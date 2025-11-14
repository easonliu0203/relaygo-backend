import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 司機端幫助與支援頁面
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  /// 打開郵件應用程式
  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@relaygo.com',
      query: 'subject=Relay GO 司機支援',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('無法打開郵件應用程式'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('發生錯誤: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('幫助與支援'),
        backgroundColor: const Color(0xFF4CAF50), // 司機端綠色主題
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // 頁面說明
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '如有任何問題或需要協助，請透過以下方式聯絡我們：',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),

          const Divider(height: 1),

          // 客服電子郵件
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.email,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
            title: const Text(
              '客服電子郵件',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'support@relaygo.com',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4CAF50),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchEmail(context),
          ),

          const Divider(height: 1),

          // 提示訊息
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '💡 提示：點擊上方郵件地址即可打開您的郵件應用程式，直接發送郵件給我們。我們會盡快回覆您的問題。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // 預留空間給未來的功能
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.construction,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '更多支援功能即將推出',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '常見問題、線上客服等功能正在開發中...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

