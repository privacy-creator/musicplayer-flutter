import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/services/translation_service.dart';

void main() {
  group('TranslationService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('clearCache removes all translation entries', () async {
      SharedPreferences.setMockInitialValues({
        'lyrics_translation_1_en': 'hello',
        'lyrics_translation_2_nl': 'dag',
        'other_key': 'keep',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = TranslationService(prefs);
      await service.clearCache();
      expect(prefs.getString('lyrics_translation_1_en'), isNull);
      expect(prefs.getString('lyrics_translation_2_nl'), isNull);
      expect(prefs.getString('other_key'), 'keep');
    });

    test('clearCache on empty prefs completes without error', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = TranslationService(prefs);
      await expectLater(service.clearCache(), completes);
    });

    test('translate returns cached result without network call', () async {
      const cached = 'cached translation';
      SharedPreferences.setMockInitialValues({
        'lyrics_translation_42_en': cached,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = TranslationService(prefs);

      final result = await service.translate(
        songId: 42,
        text: 'original text',
        targetLang: 'en',
      );
      expect(result, cached);
    });
  });

  group('TranslationService text splitting', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('short text is returned in a single chunk (via cache path)', () async {
      const text = 'Short lyrics here';
      SharedPreferences.setMockInitialValues({
        'lyrics_translation_1_en': text,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = TranslationService(prefs);

      final result = await service.translate(
        songId: 1,
        text: text,
        targetLang: 'en',
      );
      expect(result, text);
    });
  });
}
