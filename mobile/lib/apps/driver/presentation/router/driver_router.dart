import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/driver_order_page.dart';
import '../pages/driver_order_detail_page.dart';
import '../pages/driver_profile_page.dart';
import '../pages/chat_list_page.dart';
import '../../../../shared/presentation/pages/auth/login_page.dart';
import '../../../../shared/presentation/pages/auth/register_page.dart';
import '../../../../shared/presentation/pages/splash_page.dart';
import '../../../../shared/presentation/pages/language_wizard_page.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/user_profile_provider.dart';
import '../../../../core/providers/chat_providers.dart';

final driverRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasCompletedWizard = ref.watch(hasCompletedLanguageWizardProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is AuthStateAuthenticated;
      final isLoading = authState is AuthStateLoading || authState is AuthStateInitial;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplashRoute = state.matchedLocation == '/';
      final isLanguageWizardRoute = state.matchedLocation == '/language-wizard';

      // 如果正在載入，保持當前路由
      if (isLoading) return null;

      // 如果在啟動頁且已認證，檢查是否完成語言精靈
      if (isSplashRoute && isAuthenticated) {
        if (!hasCompletedWizard) {
          return '/language-wizard';
        }
        return '/home';
      }

      // 如果在啟動頁且未認證，重定向到登入頁面
      if (isSplashRoute && !isAuthenticated) {
        return '/login';
      }

      // 如果未認證且不在登入頁面，重定向到登入頁面
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // 如果已認證且在登入頁面，檢查是否完成語言精靈
      if (isAuthenticated && isLoginRoute) {
        if (!hasCompletedWizard) {
          return '/language-wizard';
        }
        return '/home';
      }

      // 如果已認證但未完成語言精靈，且不在語言精靈頁面，重定向到語言精靈
      if (isAuthenticated && !hasCompletedWizard && !isLanguageWizardRoute) {
        return '/language-wizard';
      }

      // 如果已認證且完成語言精靈，但在語言精靈頁面，重定向到主頁
      if (isAuthenticated && hasCompletedWizard && isLanguageWizardRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // 啟動頁
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // 認證相關
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(appType: 'driver'),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // 語言精靈
      GoRoute(
        path: '/language-wizard',
        name: 'language-wizard',
        builder: (context, state) => const LanguageWizardPage(),
      ),

      // 司機端主要功能
      ShellRoute(
        builder: (context, state, child) {
          return DriverShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const DriverOrderPage(), // 訂單管理作為主頁
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatListPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const DriverProfilePage(),
          ),
        ],
      ),

      // 訂單詳情頁面（不在 Shell 中，以便全屏顯示）
      GoRoute(
        path: '/driver/order-detail/:orderId',
        name: 'driver-order-detail',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return DriverOrderDetailPage(orderId: orderId);
        },
      ),
    ],
  );
});

// 司機端 Shell
class DriverShell extends ConsumerStatefulWidget {
  final Widget child;

  const DriverShell({super.key, required this.child});

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final totalUnreadCountAsync = ref.watch(totalUnreadCountStreamProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/chat');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: '訂單',
          ),
          BottomNavigationBarItem(
            icon: totalUnreadCountAsync.when(
              data: (count) => count > 0
                  ? Badge(
                      label: Text(count > 99 ? '99+' : count.toString()),
                      child: const Icon(Icons.chat),
                    )
                  : const Icon(Icons.chat),
              loading: () => const Icon(Icons.chat),
              error: (_, __) => const Icon(Icons.chat),
            ),
            label: '聊天',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '個人檔案',
          ),
        ],
      ),
    );
  }
}
