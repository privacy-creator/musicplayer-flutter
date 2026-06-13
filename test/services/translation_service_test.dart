import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/services/translation_service.dart';

class _FakeDio extends Fake implements Dio {
  final Map<String, dynamic>? responseData;
  int callCount = 0;

  _FakeDio({this.responseData});

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    callCount++;
    return Response<T>(
      data: responseData != null ? responseData as T : null,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

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

  group('TranslationService network path', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('translates short text via network and caches result', () async {
      final fakeDio = _FakeDio(responseData: {
        'responseStatus': 200,
        'responseData': {'translatedText': 'hallo wereld'},
      });
      final prefs = await SharedPreferences.getInstance();
      final service = TranslationService(prefs, dio: fakeDio);

      final result = await service.translate(
        songId: 99,
        text: 'hello world',
        targetLang: 'nl',
      );

      expect(result, 'hallo wereld');
      expect(fakeDio.callCount, 1);
      expect(prefs.getString('lyrics_translation_99_nl'), 'hallo wereld');
    });

    test('uses explicit sourceLang in langpair', () async {
      final fakeDio = _FakeDio(responseData: {
        'responseStatus': 200,
        'responseData': {'translatedText': 'bonjour'},
      });
      final prefs = await SharedPreferences.getInstance();
      final service = TranslationService(prefs, dio: fakeDio);

      final result = await service.translate(
        songId: 5,
        text: 'hello',
        targetLang: 'fr',
        sourceLang: 'en',
      );

      expect(result, 'bonjour');
    });

    test('throws on error response status', () async {
      final fakeDio = _FakeDio(responseData: {
        'responseStatus': 403,
        'responseData': {'translatedText': ''},
      });
      final prefs = await SharedPreferences.getInstance();
      final service = TranslationService(prefs, dio: fakeDio);

      await expectLater(
        service.translate(songId: 1, text: 'test', targetLang: 'es'),
        throwsException,
      );
    });

    test('throws on null response data', () async {
      final fakeDio = _FakeDio(responseData: null);
      final prefs = await SharedPreferences.getInstance();
      final service = TranslationService(prefs, dio: fakeDio);

      await expectLater(
        service.translate(songId: 2, text: 'test', targetLang: 'de'),
        throwsException,
      );
    });

    test('splits long text and joins translated chunks', () async {
      final fakeDio = _FakeDio(responseData: {
        'responseStatus': 200,
        'responseData': {'translatedText': 'chunk'},
      });
      final prefs = await SharedPreferences.getInstance();
      final service = TranslationService(prefs, dio: fakeDio);

      // Build text > 500 chars with multiple newlines
      final line = 'This is a line of lyrics that is moderately long. ';
      final longText = List.filled(12, line).join('\n');

      final result = await service.translate(
        songId: 10,
        text: longText,
        targetLang: 'nl',
      );

      expect(fakeDio.callCount, greaterThan(1));
      expect(result, isNotEmpty);
    });
  });
}
