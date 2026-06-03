import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/constants.dart';

void main() {
  group('AppConstants.fixUrl', () {
    test('replaces http://localhost with configured host', () {
      expect(
        AppConstants.fixUrl('http://localhost/muziek/uploads/song.mp3'),
        'https://api.hiddebalestra.nl/muziek/uploads/song.mp3',
      );
    });

    test('replaces http://127.0.0.1 with configured host', () {
      expect(
        AppConstants.fixUrl('http://127.0.0.1/muziek/uploads/song.mp3'),
        'https://api.hiddebalestra.nl/muziek/uploads/song.mp3',
      );
    });

    test('does not modify a URL that already uses the correct host', () {
      const url = 'https://api.hiddebalestra.nl/muziek/uploads/song.mp3';
      expect(AppConstants.fixUrl(url), url);
    });

    test('returns empty string unchanged', () {
      expect(AppConstants.fixUrl(''), '');
    });

    test('does not modify external URLs', () {
      const url = 'https://cdn.example.com/song.mp3';
      expect(AppConstants.fixUrl(url), url);
    });

    test('only replaces the first occurrence', () {
      final result = AppConstants.fixUrl('http://localhost/muziek/localhost/file.mp3');
      expect(result, 'https://api.hiddebalestra.nl/muziek/localhost/file.mp3');
    });

    test('apiUrl is built from baseUrl', () {
      expect(AppConstants.apiUrl, startsWith(AppConstants.baseUrl));
      expect(AppConstants.apiUrl, '${AppConstants.baseUrl}/api');
    });
  });
}
