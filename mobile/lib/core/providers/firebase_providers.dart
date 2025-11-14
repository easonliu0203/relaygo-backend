import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

/// Firebase Service Provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// Current User Provider
/// 提供當前登入的 Firebase 用戶
final currentUserProvider = StreamProvider<User?>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.auth.authStateChanges();
});

/// Current User ID Provider
/// 提供當前登入用戶的 UID
final currentUserIdProvider = Provider<String?>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);
  return currentUserAsync.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
});

