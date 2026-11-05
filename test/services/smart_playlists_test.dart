import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/models/history_entry.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/history_service.dart';
import 'package:music_player_flutter/services/smart_playlists.dart';
import 'package:shared_preferences/shared_preferences.dart';

Song makeSong(int id, {String genre = 'Pop', int year = 2024}) => Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist',
      genre: genre,
      language: 'Dutch',
      year: year,
      duration: 180,
      audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/$id.mp3',
    );

final now = DateTime(2026, 11, 5);

HistoryEntry played(int id, {int count = 1, int daysAgo = 0}) => HistoryEntry(
      songId: id,
      playedAt: now.subtract(Duration(days: daysAgo)),
      playCount: count,
    );

SmartPlaylist? find(List<SmartPlaylist> lists, SmartPlaylistKind kind) {
  for (final p in lists) {
    if (p.kind == kind) return p;
  }
  return null;
}

void main() {
  group('buildSmartPlaylists()', () {
    test('lege lijsten worden weggelaten', () {
      final lists =
          buildSmartPlaylists(songs: [], history: [], liked: [], now: now);
      expect(lists, isEmpty);
    });

    test('meest gespeeld sorteert op aantal keer afgespeeld', () {
      final songs = [makeSong(1), makeSong(2), makeSong(3)];
      final lists = buildSmartPlaylists(
        songs: songs,
        history: [played(1, count: 2), played(2, count: 5), played(3)],
        liked: [],
        now: now,
      );
      final ids = find(lists, SmartPlaylistKind.mostPlayed)!
          .songs
          .map((s) => s.id);
      expect(ids, [2, 1, 3]);
    });

    test('vergeten favorieten: geliked en ruim een maand niet gehoord', () {
      final songs = [makeSong(1), makeSong(2), makeSong(3)];
      final lists = buildSmartPlaylists(
        songs: songs,
        history: [played(1, daysAgo: 40), played(2, daysAgo: 2)],
        liked: songs,
        now: now,
      );
      final ids = find(lists, SmartPlaylistKind.forgottenFavorites)!
          .songs
          .map((s) => s.id);
      expect(ids, [1, 3]);
    });

    test('nog nooit gespeeld bevat alleen nummers zonder geschiedenis', () {
      final lists = buildSmartPlaylists(
        songs: [makeSong(1), makeSong(2)],
        history: [played(1)],
        liked: [],
        now: now,
      );
      expect(
          find(lists, SmartPlaylistKind.neverPlayed)!.songs.map((s) => s.id),
          [2]);
    });

    test('nieuw dit jaar gebruikt het huidige jaar als label', () {
      final lists = buildSmartPlaylists(
        songs: [makeSong(1, year: 2026), makeSong(2, year: 2025)],
        history: [],
        liked: [],
        now: now,
      );
      final p = find(lists, SmartPlaylistKind.newThisYear)!;
      expect(p.label, '2026');
      expect(p.songs.map((s) => s.id), [1]);
    });

    test('genre-mix kiest het genre met de meeste afspeelbeurten', () {
      final songs = [
        makeSong(1, genre: 'Jazz'),
        makeSong(2, genre: 'Jazz'),
        makeSong(3, genre: 'Blues'),
      ];
      final lists = buildSmartPlaylists(
        songs: songs,
        history: [played(1), played(3, count: 4)],
        liked: [],
        now: now,
      );
      final p = find(lists, SmartPlaylistKind.genreMix)!;
      expect(p.label, 'Blues');
      expect(p.songs.map((s) => s.id), [3]);
    });
  });

  group('HistoryService playCount', () {
    test('telt het aantal keer dat een nummer is afgespeeld', () async {
      SharedPreferences.setMockInitialValues({});
      final service = HistoryService(await SharedPreferences.getInstance());
      await service.recordPlay(1);
      await service.recordPlay(2);
      await service.recordPlay(1);
      expect(service.entries.first.songId, 1);
      expect(service.entries.first.playCount, 2);
      expect(service.entries.last.playCount, 1);
    });

    test('oude geschiedenis zonder playCount telt als 1', () {
      final entry = HistoryEntry.fromJson({'songId': 1, 'playedAt': 0});
      expect(entry.playCount, 1);
    });
  });
}
