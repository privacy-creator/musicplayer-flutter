import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/liked_songs_service.dart';
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
  late LikedSongsService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = LikedSongsService();
  });

  group('Beginwaarden', () {
    test('isLiked() is false bij aanmaak', () {
      expect(service.isLiked(1), false);
    });

    test('likedSongs is leeg bij aanmaak', () {
      expect(service.likedSongs, isEmpty);
    });
  });

  group('like()', () {
    test('isLiked() is true na like()', () async {
      await service.like(makeSong(1));
      expect(service.isLiked(1), true);
    });

    test('song verschijnt in likedSongs na like()', () async {
      await service.like(makeSong(1));
      expect(service.likedSongs.length, 1);
      expect(service.likedSongs.first.id, 1);
    });

    test('nogmaals liken van hetzelfde nummer heeft geen effect', () async {
      await service.like(makeSong(1));
      await service.like(makeSong(1));
      expect(service.likedSongs.length, 1);
    });
  });

  group('unlike()', () {
    test('isLiked() is false na unlike()', () async {
      await service.like(makeSong(1));
      await service.unlike(1);
      expect(service.isLiked(1), false);
    });

    test('song verdwijnt uit likedSongs na unlike()', () async {
      await service.like(makeSong(1));
      await service.unlike(1);
      expect(service.likedSongs, isEmpty);
    });

    test('unlike() op niet-geliket nummer doet niets', () async {
      await service.unlike(99);
      expect(service.isLiked(99), false);
    });
  });

  group('toggle()', () {
    test('toggle() liket een nog niet geliket nummer', () async {
      await service.toggle(makeSong(1));
      expect(service.isLiked(1), true);
    });

    test('toggle() unliket een reeds geliket nummer', () async {
      await service.like(makeSong(1));
      await service.toggle(makeSong(1));
      expect(service.isLiked(1), false);
    });
  });

  group('volgorde van likedSongs', () {
    test('meest recent geliket staat vooraan', () async {
      await service.like(makeSong(1));
      await service.like(makeSong(2));
      await service.like(makeSong(3));
      expect(service.likedSongs.map((s) => s.id).toList(), [3, 2, 1]);
    });
  });

  group('persistentie via SharedPreferences', () {
    test('init() laadt eerder geliketet nummers', () async {
      await service.like(makeSong(1));
      await service.like(makeSong(2));

      final service2 = LikedSongsService();
      await service2.init();

      expect(service2.isLiked(1), true);
      expect(service2.isLiked(2), true);
      expect(service2.likedSongs.length, 2);
    });

    test('init() bewaart volgorde en songgegevens', () async {
      await service.like(makeSong(42));

      final service2 = LikedSongsService();
      await service2.init();

      expect(service2.likedSongs.first.id, 42);
      expect(service2.likedSongs.first.title, 'Song 42');
      expect(service2.likedSongs.first.artist, 'Artist');
    });

    test('unlike() wordt gepersisteerd', () async {
      await service.like(makeSong(1));
      await service.unlike(1);

      final service2 = LikedSongsService();
      await service2.init();

      expect(service2.isLiked(1), false);
    });
  });
}
