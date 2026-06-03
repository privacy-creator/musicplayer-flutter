import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/constants.dart';

void main() {
  group('AppConstants.fixUrl', () {
    test('replaces http://localhost/backend with production baseUrl', () {
      expect(
        AppConstants.fixUrl('http://localhost/backend/uploads/song.mp3'),
        'https://api.hiddebalestra.nl/muziek/uploads/song.mp3',
      );
    });

    test('replaces http://127.0.0.1/backend with production baseUrl', () {
      expect(
        AppConstants.fixUrl('http://127.0.0.1/backend/uploads/song.mp3'),
        'https://api.hiddebalestra.nl/muziek/uploads/song.mp3',
      );
    });

    test('replaces http://10.0.2.2/backend with production baseUrl', () {
      expect(
        AppConstants.fixUrl('http://10.0.2.2/backend/uploads/song.mp3'),
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

    test('preserves the path after /backend', () {
      expect(
        AppConstants.fixUrl('http://localhost/backend/uploads/sub/file.mp3'),
        'https://api.hiddebalestra.nl/muziek/uploads/sub/file.mp3',
      );
    });

    test('apiUrl is built from baseUrl', () {
      expect(AppConstants.apiUrl, startsWith(AppConstants.baseUrl));
      expect(AppConstants.apiUrl, '${AppConstants.baseUrl}/api');
    });
  });
}
