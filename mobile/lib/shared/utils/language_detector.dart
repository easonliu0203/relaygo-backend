import 'dart:ui' as ui;

/// 語言偵測工具
/// 用於偵測系統語言並返回支援的語言代碼
class LanguageDetector {
  /// 支援的語言列表
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'zh-TW', 'name': '繁體中文', 'flag': '🇹🇼'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'th', 'name': 'ไทย', 'flag': '🇹🇭'},
    {'code': 'ms', 'name': 'Bahasa Melayu', 'flag': '🇲🇾'},
    {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
  ];

  /// 支援的語言代碼列表
  static List<String> get supportedLanguageCodes =>
      supportedLanguages.map((lang) => lang['code']!).toList();

  /// 偵測系統語言
  /// 返回支援的語言代碼，如果系統語言不在支援列表中，返回預設語言 'zh-TW'
  static String detectSystemLanguage() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    print('🌍 [LanguageDetector] 系統語言: $languageCode-$countryCode');

    // 處理繁體中文
    if (languageCode == 'zh') {
      if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
        print('✅ [LanguageDetector] 偵測到繁體中文');
        return 'zh-TW';
      }
      // 簡體中文不支援，預設為繁體中文
      print('⚠️ [LanguageDetector] 簡體中文不支援，使用繁體中文');
      return 'zh-TW';
    }

    // 檢查是否在支援列表中
    if (supportedLanguageCodes.contains(languageCode)) {
      print('✅ [LanguageDetector] 支援的語言: $languageCode');
      return languageCode;
    }

    // 預設為繁體中文
    print('⚠️ [LanguageDetector] 不支援的語言: $languageCode，使用預設語言 zh-TW');
    return 'zh-TW';
  }

  /// 根據語言代碼獲取語言資訊
  static Map<String, String>? getLanguageInfo(String languageCode) {
    try {
      return supportedLanguages.firstWhere(
        (lang) => lang['code'] == languageCode,
      );
    } catch (e) {
      return null;
    }
  }

  /// 根據語言代碼獲取語言名稱
  static String getLanguageName(String languageCode) {
    final info = getLanguageInfo(languageCode);
    return info?['name'] ?? languageCode;
  }

  /// 根據語言代碼獲取國旗圖示
  static String getLanguageFlag(String languageCode) {
    final info = getLanguageInfo(languageCode);
    return info?['flag'] ?? '🌐';
  }

  /// 檢查語言代碼是否支援
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguageCodes.contains(languageCode);
  }
}

