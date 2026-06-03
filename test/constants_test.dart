import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/constants.dart';

void main() {
  group('AppConstants.fixUrl', () {
    test('replaces http://localhost with configured host', () {
      expect(
        AppConstants.fixUrl('http://localhost/backend/uploads/song.mp3'),
        'http://10.0.2.2/backend/uploads/song.mp3',
      );
    });

    test('replaces http://127.0.0.1 with configured host', () {
      expect(
        AppConstants.fixUrl('http://127.0.0.1/backend/uploads/song.mp3'),
        'http://10.0.2.2/backend/uploads/song.mp3',
      );
    });

    test('does not modify a URL that already uses the correct host', () {
      const url = 'http://10.0.2.2/backend/uploads/song.mp3';
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
      // Edge case: localhost appears in the path (unlikely but safe to verify)
      final result = AppConstants.fixUrl('http://localhost/backend/localhost/file.mp3');
      expect(result, 'http://10.0.2.2/backend/localhost/file.mp3');
    });

    test('apiUrl is built from baseUrl', () {
      expect(AppConstants.apiUrl, startsWith(AppConstants.baseUrl));
      expect(AppConstants.apiUrl, '${AppConstants.baseUrl}/api');
    });
  });
}
