import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/user_profile_provider.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';

class CustomerProfilePage extends ConsumerWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);
    final userProfile = ref.watch(userProfileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人資料'),
        backgroundColor: const Color(0xFF2196F3), // 客戶端藍色主題
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 用戶資訊卡片
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // 用戶頭像
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                      backgroundImage: currentUser.value?.photoURL != null
                          ? NetworkImage(currentUser.value!.photoURL!)
                          : null,
                      child: currentUser.value?.photoURL == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Color(0xFF2196F3),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 用戶名稱
                    Text(
                      currentUser.value?.displayName ?? '客戶用戶',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 用戶 Email
                    Text(
                      currentUser.value?.email ?? '未設定 Email',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 用戶類型標籤
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '客戶',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 功能選項列表
            Expanded(
              child: ListView(
                children: [
                  _buildProfileOption(
                    context,
                    icon: Icons.edit,
                    title: '編輯個人資料',
                    subtitle: '修改姓名、頭像等資訊',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.history,
                    title: '行程記錄',
                    subtitle: '查看過往的叫車記錄',
                    onTap: () {
                      // TODO: 實作行程記錄功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('行程記錄功能開發中...')),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.payment,
                    title: '付款方式',
                    subtitle: '管理信用卡和付款設定',
                    onTap: () {
                      // TODO: 實作付款方式功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('付款方式功能開發中...')),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.settings,
                    title: '設定',
                    subtitle: '應用程式偏好設定',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CustomerSettingsPage(),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    icon: Icons.help,
                    title: '幫助與支援',
                    subtitle: '常見問題和客服聯絡',
                    onTap: () {
                      // TODO: 實作幫助與支援功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('幫助與支援功能開發中...')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 登出按鈕
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                onPressed: authState is AuthStateLoading
                    ? null
                    : () => _showSignOutDialog(context, ref),
                icon: authState is AuthStateLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  authState is AuthStateLoading ? '登出中...' : '登出帳號',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
          child: Icon(
            icon,
            color: const Color(0xFF2196F3),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認登出'),
          content: const Text('您確定要登出帳號嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref.read(authStateProvider.notifier).signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已成功登出'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('登出失敗：$e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('確認登出'),
            ),
          ],
        );
      },
    );
  }
}
