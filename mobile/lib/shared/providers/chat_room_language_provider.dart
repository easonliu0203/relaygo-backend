import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_language_preferences_provider.dart';
import '../utils/language_detector.dart';

/// 聊天室語言狀態
class ChatRoomLanguageState {
  final String? roomViewLang; // null 表示「跟隨個人設定」
  final bool isLoading;

  const ChatRoomLanguageState({
    this.roomViewLang,
    this.isLoading = false,
  });

  ChatRoomLanguageState copyWith({
    String? roomViewLang,
    bool? isLoading,
  }) {
    return ChatRoomLanguageState(
      roomViewLang: roomViewLang,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 聊天室語言 Notifier
class ChatRoomLanguageNotifier extends StateNotifier<ChatRoomLanguageState> {
  final String bookingId;
  final Ref ref;

  ChatRoomLanguageNotifier(this.bookingId, this.ref)
      : super(const ChatRoomLanguageState()) {
    _loadSavedLanguage();
  }

  /// 載入保存的語言選擇
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('room_lang_$bookingId');
      state = ChatRoomLanguageState(roomViewLang: savedLang);
    } catch (e) {
      // 載入失敗，使用預設值（跟隨個人設定）
      state = const ChatRoomLanguageState();
    }
  }

  /// 設置聊天室語言
  Future<void> setRoomLanguage(String? languageCode) async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (languageCode == null) {
        // 移除保存的語言（跟隨個人設定）
        await prefs.remove('room_lang_$bookingId');
      } else {
        // 保存語言選擇
        await prefs.setString('room_lang_$bookingId', languageCode);
      }

      state = ChatRoomLanguageState(roomViewLang: languageCode);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// 獲取當前有效的顯示語言（考慮優先順序）
  /// 優先順序：設定頁面 (preferredLang) > 聊天室臨時切換 (roomViewLang) > 系統語言
  ///
  /// 說明：
  /// - 設定頁面的 preferredLang 是用戶的全域偏好，具有最高優先權
  /// - 聊天室的 roomViewLang 是臨時覆蓋，只在該聊天室生效
  /// - 如果用戶沒有設定 preferredLang，則使用 roomViewLang
  /// - 如果兩者都沒有，則使用系統預設語言
  String getEffectiveLanguage() {
    final userPrefs = ref.read(userLanguagePreferencesProvider);

    // 優先順序 1: 設定頁面的偏好語言（全域設定）
    // 優先順序 2: 聊天室臨時語言（per-room 覆蓋）
    // 優先順序 3: 系統預設語言

    // 如果聊天室有臨時語言設定，使用聊天室語言
    if (state.roomViewLang != null) {
      return state.roomViewLang!;
    }

    // 否則使用用戶的偏好語言（可能是設定頁面設定的，或首次登入選擇的，或系統預設）
    return userPrefs.preferredLang;
  }
}

/// 聊天室語言 Provider（每個聊天室一個實例）
final chatRoomLanguageProvider = StateNotifierProvider.family<
    ChatRoomLanguageNotifier,
    ChatRoomLanguageState,
    String>((ref, bookingId) {
  return ChatRoomLanguageNotifier(bookingId, ref);
});

/// 獲取聊天室有效語言的便捷 Provider
/// 這個 Provider 會監聽 chatRoomLanguageProvider 和 userLanguagePreferencesProvider 的變化
/// 當任一 Provider 改變時，都會重新計算有效語言
final effectiveRoomLanguageProvider = Provider.family<String, String>((ref, bookingId) {
  // 監聽聊天室語言狀態（roomViewLang）
  final roomLanguageState = ref.watch(chatRoomLanguageProvider(bookingId));

  // 監聽用戶語言偏好（preferredLang）
  final userPrefs = ref.watch(userLanguagePreferencesProvider);

  // 優先順序：roomViewLang > preferredLang > 系統預設
  if (roomLanguageState.roomViewLang != null) {
    return roomLanguageState.roomViewLang!;
  }

  return userPrefs.preferredLang;
});

