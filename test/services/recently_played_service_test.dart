import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/recently_played_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Song makeSong(int id) => Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist',
      genre: 'Pop',
      language: 'Dutch',
      year: 2024,
      duration: 180,
      audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/$id.mp3',
    );

void main() {
  late RecentlyPlayedService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = RecentlyPlayedService();
  });

  group('Beginwaarden', () {
    test('recentSongs is leeg bij aanmaak', () {
      expect(service.recentSongs, isEmpty);
    });
  });

  group('recordPlay()', () {
    test('song verschijnt in recentSongs na recordPlay()', () async {
      await service.recordPlay(makeSong(1));
      expect(service.recentSongs.length, 1);
      expect(service.recentSongs.first.id, 1);
    });

    test('nogmaals afspelen dupliceert het nummer niet', () async {
      await service.recordPlay(makeSong(1));
      await service.recordPlay(makeSong(1));
      expect(service.recentSongs.length, 1);
    });

    test('nogmaals afspelen zet het nummer weer vooraan', () async {
      await service.recordPlay(makeSong(1));
      await service.recordPlay(makeSong(2));
      await service.recordPlay(makeSong(1));
      expect(service.recentSongs.map((s) => s.id).toList(), [1, 2]);
    });
  });

  group('volgorde van recentSongs', () {
    test('meest recent afgespeeld staat vooraan', () async {
      await service.recordPlay(makeSong(1));
      await service.recordPlay(makeSong(2));
      await service.recordPlay(makeSong(3));
      expect(service.recentSongs.map((s) => s.id).toList(), [3, 2, 1]);
    });
  });

  group('maximum aantal entries', () {
    test('houdt maximaal 30 nummers bij', () async {
      for (var i = 1; i <= 35; i++) {
        await service.recordPlay(makeSong(i));
      }
      expect(service.recentSongs.length, 30);
    });

    test('oudste nummers vallen als eerste weg', () async {
      for (var i = 1; i <= 35; i++) {
        await service.recordPlay(makeSong(i));
      }
      expect(service.recentSongs.map((s) => s.id), isNot(contains(1)));
      expect(service.recentSongs.map((s) => s.id), contains(35));
    });
  });

  group('persistentie via SharedPreferences', () {
    test('init() laadt eerder afgespeelde nummers', () async {
      await service.recordPlay(makeSong(1));
      await service.recordPlay(makeSong(2));

      final service2 = RecentlyPlayedService();
      await service2.init();

      expect(service2.recentSongs.map((s) => s.id).toList(), [2, 1]);
    });

    test('init() bewaart songgegevens', () async {
      await service.recordPlay(makeSong(42));

      final service2 = RecentlyPlayedService();
      await service2.init();

      expect(service2.recentSongs.first.title, 'Song 42');
      expect(service2.recentSongs.first.artist, 'Artist');
    });
  });
}
