import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/models/playlist.dart';

void main() {
  group('Playlist.fromJson', () {
    test('parses id, name and description', () {
      final playlist = Playlist.fromJson({
        'id': 5,
        'name': 'Favorieten',
        'description': 'Mijn favoriete nummers',
        'songs': [],
      });

      expect(playlist.id, 5);
      expect(playlist.name, 'Favorieten');
      expect(playlist.description, 'Mijn favoriete nummers');
    });

    test('description is null when not present', () {
      final playlist = Playlist.fromJson({'id': 1, 'name': 'Test', 'songs': []});
      expect(playlist.description, isNull);
    });

    test('parses empty songs list', () {
      final playlist = Playlist.fromJson({'id': 1, 'name': 'Leeg', 'songs': []});
      expect(playlist.songs, isEmpty);
    });

    test('parses songs list with one song', () {
      final playlist = Playlist.fromJson({
        'id': 2,
        'name': 'Met nummers',
        'songs': [
          {
            'id': 10,
            'title': 'Nummer 1',
            'artist': 'Artiest',
            'genre': 'Pop',
            'language': 'Dutch',
            'year': 2023,
            'duration': 200,
            'audio_url': 'http://10.0.2.2/backend/uploads/a.mp3',
          },
        ],
      });

      expect(playlist.songs.length, 1);
      expect(playlist.songs.first.id, 10);
      expect(playlist.songs.first.title, 'Nummer 1');
    });

    test('parses multiple songs', () {
      final playlist = Playlist.fromJson({
        'id': 3,
        'name': 'Meerdere',
        'songs': List.generate(
          5,
          (i) => {
            'id': i + 1,
            'title': 'Song $i',
            'artist': '',
            'genre': '',
            'language': '',
            'year': 2000,
            'duration': 180,
            'audio_url': '',
          },
        ),
      });

      expect(playlist.songs.length, 5);
    });

    test('songs is empty list when key missing from JSON', () {
      final playlist = Playlist.fromJson({'id': 1, 'name': 'Geen songs key'});
      expect(playlist.songs, isEmpty);
    });

    test('uses empty string for missing name', () {
      final playlist = Playlist.fromJson({'id': 1, 'songs': []});
      expect(playlist.name, '');
    });

    test('rewrites localhost URL in nested songs', () {
      final playlist = Playlist.fromJson({
        'id': 1,
        'name': 'Test',
        'songs': [
          {
            'id': 1,
            'title': 'Song',
            'artist': '',
            'genre': '',
            'language': '',
            'year': 0,
            'duration': 0,
            'audio_url': 'http://localhost/backend/uploads/song.mp3',
          },
        ],
      });

      expect(playlist.songs.first.audioUrl, 'http://10.0.2.2/backend/uploads/song.mp3');
    });
  });
}
