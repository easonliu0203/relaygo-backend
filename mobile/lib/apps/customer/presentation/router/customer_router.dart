import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/customer_home_page.dart';
import '../pages/customer_booking_page.dart';
import '../pages/customer_profile_page.dart';
import '../pages/chat_list_page.dart';
import '../pages/instant_translation_page.dart';
import '../pages/payment_deposit_page.dart';
import '../pages/payment_balance_page.dart';
import '../pages/payment_webview_page.dart';
import '../pages/booking_success_page.dart';
import '../pages/booking_complete_page.dart';
import '../pages/order_detail_page.dart';
import '../pages/order_list_page.dart';
import '../pages/package_selection_page.dart';
import '../../../../core/services/payment/payment_models.dart';
import '../../../../shared/presentation/pages/auth/login_page.dart';
import '../../../../shared/presentation/pages/auth/register_page.dart';
import '../../../../shared/presentation/pages/splash_page.dart';
import '../../../../shared/presentation/pages/language_wizard_page.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/user_profile_provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/chat_providers.dart';

final customerRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasCompletedWizard = ref.watch(hasCompletedLanguageWizardProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is AuthStateAuthenticated;
      final isLoading = authState is AuthStateLoading || authState is AuthStateInitial;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplashRoute = state.matchedLocation == '/';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isLanguageWizardRoute = state.matchedLocation == '/language-wizard';

      print('🔀 [Router] 路由重定向: ${state.matchedLocation}, 認證狀態: ${authState.runtimeType}, 完成精靈: $hasCompletedWizard');

      // 如果正在載入且在啟動頁，允許顯示啟動頁
      if (isLoading && isSplashRoute) {
        print('⏳ [Router] 載入中，顯示啟動頁');
        return null;
      }

      // 如果正在載入且不在啟動頁，重定向到啟動頁
      if (isLoading && !isSplashRoute) {
        print('⏳ [Router] 載入中，重定向到啟動頁');
        return '/';
      }

      // 如果在啟動頁且已認證，檢查是否完成語言精靈
      if (isSplashRoute && isAuthenticated) {
        if (!hasCompletedWizard) {
          print('🌍 [Router] 未完成語言精靈，重定向到語言精靈');
          return '/language-wizard';
        }
        print('✅ [Router] 已認證且完成精靈，重定向到主頁');
        return '/home';
      }

      // 如果在啟動頁且未認證，重定向到登入頁面
      if (isSplashRoute && !isAuthenticated) {
        print('🔓 [Router] 未認證，重定向到登入頁');
        return '/login';
      }

      // 如果未認證且不在登入/註冊頁面，重定向到登入頁面
      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
        print('🔓 [Router] 未認證，重定向到登入頁');
        return '/login';
      }

      // 如果已認證且在登入頁面，檢查是否完成語言精靈
      if (isAuthenticated && isLoginRoute) {
        if (!hasCompletedWizard) {
          print('🌍 [Router] 未完成語言精靈，重定向到語言精靈');
          return '/language-wizard';
        }
        print('✅ [Router] 已認證且完成精靈，重定向到主頁');
        return '/home';
      }

      // 如果已認證但未完成語言精靈，且不在語言精靈頁面，重定向到語言精靈
      if (isAuthenticated && !hasCompletedWizard && !isLanguageWizardRoute) {
        print('🌍 [Router] 未完成語言精靈，重定向到語言精靈');
        return '/language-wizard';
      }

      // 如果已認證且完成語言精靈，但在語言精靈頁面，重定向到主頁
      if (isAuthenticated && hasCompletedWizard && isLanguageWizardRoute) {
        print('✅ [Router] 已完成精靈，重定向到主頁');
        return '/home';
      }

      return null;
    },
    routes: [
      // 啟動頁
      GoRoute(
        path: '/',
        name: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // 認證相關
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(appType: 'customer'),
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

      // 客戶端主要功能
      ShellRoute(
        builder: (context, state, child) {
          return CustomerShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const CustomerHomePage(), // 客戶首頁
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatListPage(),
          ),
          GoRoute(
            path: '/instant-translation',
            name: 'instant-translation',
            builder: (context, state) => const InstantTranslationPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const CustomerProfilePage(),
          ),
        ],
      ),

      // 預約相關頁面（不在 Shell 中）
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) => const CustomerBookingPage(),
      ),
      GoRoute(
        path: '/package-selection',
        name: 'package-selection',
        builder: (context, state) => const PackageSelectionPage(),
      ),
      GoRoute(
        path: '/payment-deposit',
        name: 'payment-deposit',
        builder: (context, state) => const PaymentDepositPage(),
      ),
      GoRoute(
        path: '/payment-webview',
        name: 'payment-webview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final paymentUrl = extra?['url'] as String? ?? '';
          final bookingId = extra?['bookingId'] as String? ?? '';
          final paymentType = extra?['paymentType'] as PaymentType? ?? PaymentType.deposit;

          return PaymentWebViewPage(
            paymentUrl: paymentUrl,
            bookingId: bookingId,
            paymentType: paymentType,
          );
        },
      ),
      GoRoute(
        path: '/booking-success/:orderId',
        name: 'booking-success',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return BookingSuccessPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-detail/:orderId',
        name: 'order-detail',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/payment-balance/:bookingId',
        name: 'payment-balance',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return PaymentBalancePage(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/booking-complete/:bookingId',
        name: 'booking-complete',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return BookingCompletePage(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrderListPage(),
      ),
    ],
  );
});

// 客戶端 Shell
class CustomerShell extends ConsumerStatefulWidget {
  final Widget child;

  const CustomerShell({super.key, required this.child});

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
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
              context.go('/instant-translation');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: '預約叫車',
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
            icon: Icon(Icons.translate),
            label: '即時翻譯',
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
