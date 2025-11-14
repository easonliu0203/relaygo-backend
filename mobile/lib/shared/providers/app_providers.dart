import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firebase_service.dart';

// Firebase 服務提供者
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// SharedPreferences 提供者
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// 主題模式提供者
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref ref;
  static const String _key = 'theme_mode';

  ThemeModeNotifier(this.ref) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final themeModeString = prefs.getString(_key);
      if (themeModeString != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      // 如果載入失敗，使用預設值
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setString(_key, themeMode.toString());
      state = themeMode;
    } catch (e) {
      // 處理錯誤
    }
  }
}

// 語言設定提供者
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale?> {
  final Ref ref;
  static const String _key = 'locale';

  LocaleNotifier(this.ref) : super(null) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final localeString = prefs.getString(_key);
      if (localeString != null) {
        final parts = localeString.split('_');
        if (parts.length == 2) {
          state = Locale(parts[0], parts[1]);
        }
      }
    } catch (e) {
      // 如果載入失敗，使用預設值
      state = null;
    }
  }

  Future<void> setLocale(Locale? locale) async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      if (locale != null) {
        await prefs.setString(_key, '${locale.languageCode}_${locale.countryCode}');
      } else {
        await prefs.remove(_key);
      }
      state = locale;
    } catch (e) {
      // 處理錯誤
    }
  }
}

// 應用程式狀態提供者
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class AppState {
  final bool isLoading;
  final String? error;

  const AppState({
    this.isLoading = false,
    this.error,
  });

  AppState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 網路連線狀態提供者
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    // TODO: 實作網路連線監聽
  }

  void setConnected(bool isConnected) {
    state = isConnected;
  }
}
