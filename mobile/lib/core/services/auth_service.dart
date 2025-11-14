import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';  // 暫時移除
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Firebase Authentication 服務類別
/// 支援 Email/Password、Google、Apple 登入方式
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 當前用戶
  User? get currentUser => _auth.currentUser;

  /// 用戶認證狀態流
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 是否已登入
  bool get isSignedIn => currentUser != null;

  /// 測試帳號配置
  static const Map<String, TestAccount> testAccounts = {
    'customer': TestAccount(
      email: 'customer.test@relaygo.com',
      password: 'RelayGO2024!Customer',
      displayName: '測試客戶',
    ),
    'driver': TestAccount(
      email: 'driver.test@relaygo.com',
      password: 'RelayGO2024!Driver',
      displayName: '測試司機',
    ),
  };

  /// 使用 Email/Password 登入
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('登入失敗：$e');
    }
  }

  /// 使用 Email/Password 註冊
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 更新用戶顯示名稱
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('註冊失敗：$e');
    }
  }

  /// 使用 Google 登入
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 觸發 Google 登入流程
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // 用戶取消登入
        return null;
      }

      // 獲取認證詳細資訊
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // 建立新的認證憑證
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 使用憑證登入 Firebase
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Google 登入失敗：$e');
    }
  }

  /// 使用 Apple 登入 (暫時停用)
  Future<UserCredential?> signInWithApple() async {
    throw AuthException('Apple 登入功能暫時停用，等待插件兼容性修復');

    // TODO: 重新啟用 Apple 登入功能
    // try {
    //   // 檢查是否支援 Apple 登入
    //   if (!await SignInWithApple.isAvailable()) {
    //     throw AuthException('此設備不支援 Apple 登入');
    //   }
    //
    //   // 請求 Apple 登入
    //   final appleCredential = await SignInWithApple.getAppleIDCredential(
    //     scopes: [
    //       AppleIDAuthorizationScopes.email,
    //       AppleIDAuthorizationScopes.fullName,
    //     ],
    //   );
    //
    //   // 建立 OAuth 憑證
    //   final oauthCredential = OAuthProvider("apple.com").credential(
    //     idToken: appleCredential.identityToken,
    //     accessToken: appleCredential.authorizationCode,
    //   );
    //
    //   // 使用憑證登入 Firebase
    //   final userCredential = await _auth.signInWithCredential(oauthCredential);
    //
    //   // 更新用戶顯示名稱（如果提供）
    //   if (appleCredential.givenName != null || appleCredential.familyName != null) {
    //     final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
    //     if (displayName.isNotEmpty && userCredential.user != null) {
    //       await userCredential.user!.updateDisplayName(displayName);
    //     }
    //   }
    //
    //   return userCredential;
    // } on FirebaseAuthException catch (e) {
    //   throw _handleAuthException(e);
    // } catch (e) {
    //   throw AuthException('Apple 登入失敗：$e');
    // }
  }

  /// 使用測試帳號登入（如果不存在則自動創建）
  Future<UserCredential?> signInWithTestAccount(String accountType) async {
    final testAccount = testAccounts[accountType];
    if (testAccount == null) {
      throw AuthException('無效的測試帳號類型：$accountType');
    }

    // 在開發環境中才允許使用測試帳號
    if (kReleaseMode) {
      throw AuthException('測試帳號僅在開發環境中可用');
    }

    try {
      // 嘗試直接登入
      final credential = await _auth.signInWithEmailAndPassword(
        email: testAccount.email,
        password: testAccount.password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      // 檢查是否為用戶不存在的錯誤
      if (e.code == 'user-not-found') {
        try {
          // 測試帳號不存在，自動創建
          print('測試帳號不存在，正在自動創建: ${testAccount.email}');

          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: testAccount.email,
            password: testAccount.password,
          );

          // 等待 Firebase 狀態同步
          await Future.delayed(const Duration(milliseconds: 500));

          // 設定顯示名稱（使用更安全的方式）
          try {
            final user = userCredential.user;
            if (user != null) {
              await user.updateDisplayName(testAccount.displayName);
              // 重新載入用戶資料以確保同步
              await user.reload();
              print('測試帳號顯示名稱設定成功: ${testAccount.displayName}');
            }
          } catch (displayNameError) {
            // 顯示名稱設定失敗不應該阻止登入
            print('警告：設定顯示名稱失敗，但帳號創建成功: $displayNameError');
          }

          print('測試帳號創建成功: ${testAccount.email}');
          return userCredential;
        } on FirebaseAuthException catch (createError) {
          throw _handleAuthException(createError);
        } catch (createError) {
          // 檢查是否為 PigeonUserDetails 類型轉換錯誤
          if (createError.toString().contains('PigeonUserDetails') ||
              createError.toString().contains('type cast')) {
            print('警告：遇到 Firebase Auth 插件類型轉換問題，但登入可能已成功');

            // 嘗試重新獲取當前用戶
            await Future.delayed(const Duration(milliseconds: 1000));
            final currentUser = _auth.currentUser;
            if (currentUser != null && currentUser.email == testAccount.email) {
              print('用戶實際上已成功登入: ${currentUser.email}');
              // 創建一個模擬的 UserCredential（因為實際登入已成功）
              return await _auth.signInWithEmailAndPassword(
                email: testAccount.email,
                password: testAccount.password,
              );
            }
          }
          throw AuthException('創建測試帳號失敗：$createError');
        }
      } else {
        // 其他 Firebase 錯誤，使用標準錯誤處理
        throw _handleAuthException(e);
      }
    } catch (e) {
      throw AuthException('測試帳號登入失敗：$e');
    }
  }

  /// 登出
  Future<void> signOut() async {
    try {
      // Google 登出
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Firebase 登出
      await _auth.signOut();
    } catch (e) {
      throw AuthException('登出失敗：$e');
    }
  }

  /// 發送密碼重設郵件
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('發送密碼重設郵件失敗：$e');
    }
  }

  /// 更新用戶資料
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('用戶未登入');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw AuthException('更新用戶資料失敗：$e');
    }
  }

  /// 刪除用戶帳號
  Future<void> deleteUser() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw AuthException('用戶未登入');
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('刪除帳號失敗：$e');
    }
  }

  /// 處理 Firebase Auth 異常
  AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('找不到此電子郵件對應的帳號');
      case 'wrong-password':
        return AuthException('密碼錯誤');
      case 'email-already-in-use':
        return AuthException('此電子郵件已被使用');
      case 'weak-password':
        return AuthException('密碼強度不足');
      case 'invalid-email':
        return AuthException('電子郵件格式無效');
      case 'user-disabled':
        return AuthException('此帳號已被停用');
      case 'too-many-requests':
        return AuthException('請求過於頻繁，請稍後再試');
      case 'operation-not-allowed':
        return AuthException('此登入方式未啟用');
      case 'invalid-credential':
        return AuthException('認證憑證無效');
      case 'account-exists-with-different-credential':
        return AuthException('此帳號已使用其他登入方式註冊');
      case 'requires-recent-login':
        return AuthException('此操作需要重新登入');
      default:
        return AuthException('認證失敗：${e.message}');
    }
  }
}

/// 測試帳號資料類別
class TestAccount {
  final String email;
  final String password;
  final String displayName;

  const TestAccount({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

/// 認證異常類別
class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}
