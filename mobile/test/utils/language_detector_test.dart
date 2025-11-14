import 'package:flutter_test/flutter_test.dart';
import 'package:ride_booking_app/shared/utils/language_detector.dart';

void main() {
  group('LanguageDetector', () {
    test('supportedLanguages should contain 8 languages', () {
      expect(LanguageDetector.supportedLanguages.length, 8);
    });

    test('supportedLanguageCodes should contain correct codes', () {
      final codes = LanguageDetector.supportedLanguageCodes;
      expect(codes, contains('zh-TW'));
      expect(codes, contains('en'));
      expect(codes, contains('ja'));
      expect(codes, contains('ko'));
      expect(codes, contains('vi'));
      expect(codes, contains('th'));
      expect(codes, contains('ms'));
      expect(codes, contains('id'));
    });

    test('getLanguageName should return correct names', () {
      expect(LanguageDetector.getLanguageName('zh-TW'), '繁體中文');
      expect(LanguageDetector.getLanguageName('en'), 'English');
      expect(LanguageDetector.getLanguageName('ja'), '日本語');
      expect(LanguageDetector.getLanguageName('ko'), '한국어');
      expect(LanguageDetector.getLanguageName('vi'), 'Tiếng Việt');
      expect(LanguageDetector.getLanguageName('th'), 'ไทย');
      expect(LanguageDetector.getLanguageName('ms'), 'Bahasa Melayu');
      expect(LanguageDetector.getLanguageName('id'), 'Bahasa Indonesia');
    });

    test('getLanguageName should return code for unknown language', () {
      expect(LanguageDetector.getLanguageName('unknown'), 'unknown');
    });

    test('getLanguageFlag should return correct flags', () {
      expect(LanguageDetector.getLanguageFlag('zh-TW'), '🇹🇼');
      expect(LanguageDetector.getLanguageFlag('en'), '🇺🇸');
      expect(LanguageDetector.getLanguageFlag('ja'), '🇯🇵');
      expect(LanguageDetector.getLanguageFlag('ko'), '🇰🇷');
      expect(LanguageDetector.getLanguageFlag('vi'), '🇻🇳');
      expect(LanguageDetector.getLanguageFlag('th'), '🇹🇭');
      expect(LanguageDetector.getLanguageFlag('ms'), '🇲🇾');
      expect(LanguageDetector.getLanguageFlag('id'), '🇮🇩');
    });

    test('getLanguageFlag should return globe emoji for unknown language', () {
      expect(LanguageDetector.getLanguageFlag('unknown'), '🌐');
    });

    // Note: detectSystemLanguage() tests require platform-specific setup
    // and are better suited for integration tests
  });
}

