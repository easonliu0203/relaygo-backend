import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('🚀 [SplashPage] 開始初始化...');

    // 等待初始化完成
    await Future.delayed(const Duration(seconds: 1));
    print('⏰ [SplashPage] 初始化等待完成');

    // 等待認證狀態確定（最多等待 3 秒）
    int attempts = 0;
    while (attempts < 30) {
      final authState = ref.read(authStateProvider);
      print('🔍 [SplashPage] 嘗試 $attempts: 認證狀態 = ${authState.runtimeType}');

      // 如果狀態不再是 Initial 或 Loading，就可以導航了
      if (authState is! AuthStateInitial && authState is! AuthStateLoading) {
        print('✅ [SplashPage] 認證狀態已確定');
        if (mounted) {
          if (authState is AuthStateAuthenticated) {
            print('👤 [SplashPage] 用戶已登入，導航到主頁');
            context.go('/home');
          } else {
            print('🔓 [SplashPage] 用戶未登入，導航到登入頁');
            context.go('/login');
          }
        }
        return;
      }

      // 等待 100ms 後再檢查
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // 如果超時，強制導航到登入頁面
    print('⏱️ [SplashPage] 超時，強制導航到登入頁');
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 應用程式圖示
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_taxi,
                size: 60,
                color: Color(0xFF2196F3),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 應用程式名稱
            Text(
              'Relay GO',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '安全、便捷、專業',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // 載入指示器
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
