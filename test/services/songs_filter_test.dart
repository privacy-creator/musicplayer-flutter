import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/api_service.dart';

Song make(int id, {
  String title = 'Song',
  String artist = 'Artist',
  String genre = 'Pop',
  String language = 'Dutch',
  int year = 2024,
}) =>
    Song(
      id: id,
      title: title,
      artist: artist,
      genre: genre,
      language: language,
      year: year,
      duration: 180,
      audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/$id.mp3',
    );

void main() {
  final songs = [
    make(1, title: 'Bohemian Rhapsody', artist: 'Queen', genre: 'Rock', language: 'English', year: 1975),
    make(2, title: 'Blinding Lights', artist: 'The Weeknd', genre: 'Pop', language: 'English', year: 2019),
    make(3, title: 'Afgelopen', artist: 'Die Antwoord', genre: 'Hip-hop', language: 'Dutch', year: 2012),
    make(4, title: 'Viva la Vida', artist: 'Coldplay', genre: 'Rock', language: 'English', year: 2008),
  ];

  group('filterSongs — geen filters', () {
    test('geeft alle nummers terug bij geen filters', () {
      expect(filterSongs(songs).length, 4);
    });

    test('geeft lege lijst terug bij lege invoer', () {
      expect(filterSongs([]), isEmpty);
    });
  });

  group('filterSongs — zoekterm', () {
    test('filtert op titeltekst', () {
      final result = filterSongs(songs, search: 'bohemian');
      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('filtert op artiestennaam', () {
      final result = filterSongs(songs, search: 'coldplay');
      expect(result.length, 1);
      expect(result.first.id, 4);
    });

    test('zoeken is hoofdletterongevoelig', () {
      expect(filterSongs(songs, search: 'QUEEN').length, 1);
      expect(filterSongs(songs, search: 'queen').length, 1);
    });

    test('lege zoekterm geeft alle nummers terug', () {
      expect(filterSongs(songs, search: '').length, 4);
    });

    test('geen resultaat als niets overeenkomt', () {
      expect(filterSongs(songs, search: 'xyznotfound'), isEmpty);
    });
  });

  group('filterSongs — taal', () {
    test('filtert Engelse nummers', () {
      final result = filterSongs(songs, language: 'English');
      expect(result.length, 3);
      expect(result.every((s) => s.language == 'English'), isTrue);
    });

    test('filtert Nederlandse nummers', () {
      final result = filterSongs(songs, language: 'Dutch');
      expect(result.length, 1);
      expect(result.first.id, 3);
    });

    test('lege taal geeft alle nummers terug', () {
      expect(filterSongs(songs, language: '').length, 4);
    });
  });

  group('filterSongs — genre', () {
    test('filtert op Rock', () {
      final result = filterSongs(songs, genre: 'Rock');
      expect(result.length, 2);
      expect(result.map((s) => s.id).toList(), containsAll([1, 4]));
    });

    test('filtert op Pop', () {
      final result = filterSongs(songs, genre: 'Pop');
      expect(result.length, 1);
      expect(result.first.id, 2);
    });

    test('lege genre geeft alle nummers terug', () {
      expect(filterSongs(songs, genre: '').length, 4);
    });
  });

  group('filterSongs — jaar', () {
    test('filtert op specifiek jaar', () {
      final result = filterSongs(songs, year: '2019');
      expect(result.length, 1);
      expect(result.first.id, 2);
    });

    test('lege jaar geeft alle nummers terug', () {
      expect(filterSongs(songs, year: '').length, 4);
    });
  });

  group('filterSongs — meerdere filters', () {
    test('taal + genre samen', () {
      final result = filterSongs(songs, language: 'English', genre: 'Rock');
      expect(result.length, 2);
    });

    test('zoek + taal samen', () {
      final result = filterSongs(songs, search: 'lights', language: 'English');
      expect(result.length, 1);
      expect(result.first.id, 2);
    });

    test('alles gecombineerd zonder resultaat', () {
      final result = filterSongs(songs,
          search: 'bohemian', language: 'Dutch', genre: 'Rock');
      expect(result, isEmpty);
    });
  });
}
