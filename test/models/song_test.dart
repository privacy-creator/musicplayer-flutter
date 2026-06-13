import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/models/song.dart';

void main() {
  group('Song.fromJson', () {
    test('parses all fields correctly', () {
      final song = Song.fromJson({
        'id': 1,
        'title': 'Test Song',
        'artist': 'Test Artist',
        'genre': 'Pop',
        'language': 'English',
        'year': 2024,
        'duration': 180,
        'audio_url': 'https://api.hiddebalestra.nl/muziek/uploads/song.mp3',
        'image_url': 'https://api.hiddebalestra.nl/muziek/uploads/cover.jpg',
        'lyrics': 'Verse 1\nChorus',
      });

      expect(song.id, 1);
      expect(song.title, 'Test Song');
      expect(song.artist, 'Test Artist');
      expect(song.genre, 'Pop');
      expect(song.language, 'English');
      expect(song.year, 2024);
      expect(song.duration, 180);
      expect(song.audioUrl, 'https://api.hiddebalestra.nl/muziek/uploads/song.mp3');
      expect(song.imageUrl, 'https://api.hiddebalestra.nl/muziek/uploads/cover.jpg');
      expect(song.lyrics, 'Verse 1\nChorus');
    });

    test('rewrites localhost audio_url to production host', () {
      final song = Song.fromJson(_minimal({'audio_url': 'http://localhost/backend/uploads/song.mp3'}));
      expect(song.audioUrl, 'https://api.hiddebalestra.nl/muziek/uploads/song.mp3');
    });

    test('rewrites 127.0.0.1 audio_url to production host', () {
      final song = Song.fromJson(_minimal({'audio_url': 'http://127.0.0.1/backend/uploads/song.mp3'}));
      expect(song.audioUrl, 'https://api.hiddebalestra.nl/muziek/uploads/song.mp3');
    });

    test('rewrites 10.0.2.2 audio_url to production host', () {
      final song = Song.fromJson(_minimal({'audio_url': 'http://10.0.2.2/backend/uploads/song.mp3'}));
      expect(song.audioUrl, 'https://api.hiddebalestra.nl/muziek/uploads/song.mp3');
    });

    test('rewrites localhost image_url to production host', () {
      final song = Song.fromJson(_minimal({
        'audio_url': '',
        'image_url': 'http://localhost/backend/uploads/cover.jpg',
      }));
      expect(song.imageUrl, 'https://api.hiddebalestra.nl/muziek/uploads/cover.jpg');
    });

    test('imageUrl is null when not present', () {
      final song = Song.fromJson(_minimal());
      expect(song.imageUrl, isNull);
    });

    test('lyrics is null when not present', () {
      final song = Song.fromJson(_minimal());
      expect(song.lyrics, isNull);
    });

    test('uses empty string for missing title/artist/genre/language', () {
      final song = Song.fromJson({'id': 1, 'year': 0, 'duration': 0, 'audio_url': ''});
      expect(song.title, '');
      expect(song.artist, '');
      expect(song.genre, '');
      expect(song.language, '');
    });

    test('handles numeric year as double from JSON', () {
      final song = Song.fromJson(_minimal({'year': 2020.0}));
      expect(song.year, 2020);
    });
  });

  group('Song.toJson', () {
    test('serializes all fields', () {
      const song = Song(
        id: 7,
        title: 'My Song',
        artist: 'Me',
        genre: 'Jazz',
        language: 'English',
        year: 2023,
        duration: 240,
        audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/7.mp3',
        imageUrl: 'https://api.hiddebalestra.nl/muziek/uploads/7.jpg',
        lyrics: 'La la la',
      );
      final j = song.toJson();
      expect(j['id'], 7);
      expect(j['title'], 'My Song');
      expect(j['artist'], 'Me');
      expect(j['genre'], 'Jazz');
      expect(j['language'], 'English');
      expect(j['year'], 2023);
      expect(j['duration'], 240);
      expect(j['audio_url'], 'https://api.hiddebalestra.nl/muziek/uploads/7.mp3');
      expect(j['image_url'], 'https://api.hiddebalestra.nl/muziek/uploads/7.jpg');
      expect(j['lyrics'], 'La la la');
    });

    test('toJson with null optional fields', () {
      const song = Song(
        id: 1, title: '', artist: '', genre: '',
        language: '', year: 0, duration: 0, audioUrl: '',
      );
      final j = song.toJson();
      expect(j['image_url'], isNull);
      expect(j['lyrics'], isNull);
    });
  });

  group('Song.formattedDuration', () {
    Song withDuration(int seconds) => Song(
          id: 1, title: '', artist: '', genre: '',
          language: '', year: 0, duration: seconds, audioUrl: '',
        );

    test('0 seconds → 0:00', () => expect(withDuration(0).formattedDuration, '0:00'));
    test('59 seconds → 0:59', () => expect(withDuration(59).formattedDuration, '0:59'));
    test('60 seconds → 1:00', () => expect(withDuration(60).formattedDuration, '1:00'));
    test('61 seconds → 1:01', () => expect(withDuration(61).formattedDuration, '1:01'));
    test('3 min 5 sec → 3:05', () => expect(withDuration(185).formattedDuration, '3:05'));
    test('10 min → 10:00', () => expect(withDuration(600).formattedDuration, '10:00'));
    test('1 hour → 60:00', () => expect(withDuration(3600).formattedDuration, '60:00'));
  });
}

Map<String, dynamic> _minimal([Map<String, dynamic>? extra]) => {
      'id': 1,
      'title': 'Song',
      'artist': 'Artist',
      'genre': 'Rock',
      'language': 'English',
      'year': 2000,
      'duration': 120,
      'audio_url': 'https://api.hiddebalestra.nl/muziek/uploads/song.mp3',
      ...?extra,
    };
