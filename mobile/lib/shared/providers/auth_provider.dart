import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';

/// 認證服務提供者
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 當前用戶提供者
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// 認證狀態提供者
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthStateNotifier(authService);
});

/// 認證狀態通知器
class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService) : super(const AuthState.initial()) {
    // 監聽認證狀態變化
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    });
  }

  /// 使用 Email/Password 登入
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 狀態會通過 authStateChanges 自動更新
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// 使用 Email/Password 註冊
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AuthState.loading();
    
    try {
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      // 狀態會通過 authStateChanges 自動更新
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// 使用 Google 登入
  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // 用戶取消登入
        state = const AuthState.unauthenticated();
      }
      // 成功登入的狀態會通過 authStateChanges 自動更新
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// 使用 Apple 登入
  Future<void> signInWithApple() async {
    state = const AuthState.loading();
    
    try {
      await _authService.signInWithApple();
      // 狀態會通過 authStateChanges 自動更新
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// 使用測試帳號登入
  Future<void> signInWithTestAccount(String accountType) async {
    state = const AuthState.loading();

    try {
      await _authService.signInWithTestAccount(accountType);
      // 狀態會通過 authStateChanges 自動更新
    } catch (e) {
      // 檢查是否為 Firebase Auth 插件的類型轉換錯誤
      final errorMessage = e.toString();
      if (errorMessage.contains('PigeonUserDetails') ||
          errorMessage.contains('type cast')) {
        // 這是一個已知的 Firebase Auth 插件問題，不影響實際登入
        print('檢測到 Firebase Auth 插件類型轉換問題，檢查登入狀態...');

        // 等待一下讓 Firebase 狀態同步
        await Future.delayed(const Duration(milliseconds: 1500));

        // 檢查用戶是否實際上已經登入
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          print('用戶實際上已成功登入，忽略類型轉換錯誤');
          // 不設置錯誤狀態，讓 authStateChanges 處理狀態更新
          return;
        }
      }

      // 其他錯誤正常處理
      state = AuthState.error(e.toString());
    }
  }

  /// 登出
  Future<void> signOut() async {
    state = const AuthState.loading();
    
    try {
      await _authService.signOut();
      // 狀態會通過 authStateChanges 自動更新
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// 發送密碼重設郵件
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// 清除錯誤狀態
  void clearError() {
    if (state is AuthStateError) {
      if (_authService.isSignedIn) {
        state = AuthState.authenticated(_authService.currentUser!);
      } else {
        state = const AuthState.unauthenticated();
      }
    }
  }
}

/// 認證狀態類別
sealed class AuthState {
  const AuthState();

  /// 初始狀態
  const factory AuthState.initial() = AuthStateInitial;
  
  /// 載入中
  const factory AuthState.loading() = AuthStateLoading;
  
  /// 已認證
  const factory AuthState.authenticated(User user) = AuthStateAuthenticated;
  
  /// 未認證
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  
  /// 錯誤
  const factory AuthState.error(String message) = AuthStateError;
}

/// 初始狀態
class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

/// 載入狀態
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// 已認證狀態
class AuthStateAuthenticated extends AuthState {
  final User user;
  
  const AuthStateAuthenticated(this.user);
}

/// 未認證狀態
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// 錯誤狀態
class AuthStateError extends AuthState {
  final String message;
  
  const AuthStateError(this.message);
}
