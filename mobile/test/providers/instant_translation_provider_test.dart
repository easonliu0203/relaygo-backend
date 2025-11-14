import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_booking_app/shared/providers/instant_translation_provider.dart';

void main() {
  group('InstantTranslationProvider', () {
    test('initial state should have default values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(instantTranslationProvider);

      expect(state.sourceLang, 'zh-TW');
      expect(state.targetLang, 'en');
      expect(state.inputText, '');
      expect(state.translatedText, null);
      expect(state.isTranslating, false);
      expect(state.error, null);
    });

    test('setSourceLang should update source language', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(instantTranslationProvider.notifier)
          .setSourceLang('ja');

      final state = container.read(instantTranslationProvider);
      expect(state.sourceLang, 'ja');
    });

    test('setTargetLang should update target language', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(instantTranslationProvider.notifier)
          .setTargetLang('ko');

      final state = container.read(instantTranslationProvider);
      expect(state.targetLang, 'ko');
    });

    test('swapLanguages should swap source and target languages', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set initial languages
      container
          .read(instantTranslationProvider.notifier)
          .setSourceLang('zh-TW');
      container
          .read(instantTranslationProvider.notifier)
          .setTargetLang('en');

      // Swap languages
      container.read(instantTranslationProvider.notifier).swapLanguages();

      final state = container.read(instantTranslationProvider);
      expect(state.sourceLang, 'en');
      expect(state.targetLang, 'zh-TW');
    });

    test('setInputText should update input text', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(instantTranslationProvider.notifier)
          .setInputText('Hello, world!');

      final state = container.read(instantTranslationProvider);
      expect(state.inputText, 'Hello, world!');
    });

    test('clearInput should reset all fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set some values
      container
          .read(instantTranslationProvider.notifier)
          .setInputText('Hello');

      // Clear input
      container.read(instantTranslationProvider.notifier).clearInput();

      final state = container.read(instantTranslationProvider);
      expect(state.inputText, '');
      expect(state.translatedText, null);
      expect(state.error, null);
    });

    test('translate should set error if input is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(instantTranslationProvider.notifier).translate();

      final state = container.read(instantTranslationProvider);
      expect(state.error, '請輸入要翻譯的文字');
    });

    test('translate should set error if source and target languages are same',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set same language
      container
          .read(instantTranslationProvider.notifier)
          .setSourceLang('en');
      container
          .read(instantTranslationProvider.notifier)
          .setTargetLang('en');
      container
          .read(instantTranslationProvider.notifier)
          .setInputText('Hello');

      await container.read(instantTranslationProvider.notifier).translate();

      final state = container.read(instantTranslationProvider);
      expect(state.error, '來源語言和目標語言不能相同');
    });
  });
}

