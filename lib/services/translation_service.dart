import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  final Dio _dio;
  final SharedPreferences _prefs;

  TranslationService(this._prefs, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.mymemory.translated.net',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  String _cacheKey(int songId, String targetLang) =>
      'lyrics_translation_${songId}_$targetLang';

  Future<String> translate({
    required int songId,
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    final key = _cacheKey(songId, targetLang);
    final cached = _prefs.getString(key);
    if (cached != null) return cached;

    final langPair = sourceLang == 'auto'
        ? 'autodetect|$targetLang'
        : '$sourceLang|$targetLang';

    final chunks = _splitText(text, 500);
    final translatedChunks = <String>[];

    for (final chunk in chunks) {
      final response = await _dio.get<Map<String, dynamic>>(
        '/get',
        queryParameters: {'q': chunk, 'langpair': langPair},
      );
      final data = response.data;
      if (data == null) throw Exception('Empty response');

      final status = data['responseStatus'];
      if (status != 200 && status != '200') {
        throw Exception('Translation error: $status');
      }

      final translated =
          data['responseData']?['translatedText'] as String? ?? chunk;
      translatedChunks.add(translated);
    }

    final result = translatedChunks.join('\n');
    await _prefs.setString(key, result);
    return result;
  }

  int get cachedTranslationCount =>
      _prefs.getKeys().where((k) => k.startsWith('lyrics_translation_')).length;

  int get cacheSizeBytes => _prefs
      .getKeys()
      .where((k) => k.startsWith('lyrics_translation_'))
      .fold<int>(0, (sum, k) => sum + (_prefs.getString(k)?.length ?? 0) * 2);

  Future<void> clearCache() async {
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith('lyrics_translation_'))
        .toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  List<String> _splitText(String text, int maxLength) {
    if (text.length <= maxLength) return [text];
    final lines = text.split('\n');
    final chunks = <String>[];
    var current = StringBuffer();

    for (final line in lines) {
      if (current.length + line.length + 1 > maxLength && current.isNotEmpty) {
        chunks.add(current.toString().trim());
        current.clear();
      }
      if (current.isNotEmpty) current.write('\n');
      current.write(line);
    }
    if (current.isNotEmpty) chunks.add(current.toString().trim());
    return chunks;
  }
}
