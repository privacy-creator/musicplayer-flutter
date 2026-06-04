import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/player_service.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

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
  late MockAudioPlayer mockPlayer;
  late PlayerService service;

  final songs = List.generate(5, (i) => makeSong(i + 1));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPlayer = MockAudioPlayer();

    when(() => mockPlayer.playerStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.durationStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.playing).thenReturn(false);
    when(() => mockPlayer.position).thenReturn(Duration.zero);
    when(() => mockPlayer.duration).thenReturn(null);
    when(() => mockPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(() => mockPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.idle));
    when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.setFilePath(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    final handler = MusicAudioHandler(player: mockPlayer);
    service = PlayerService(handler: handler);
  });

  tearDown(() => service.dispose());

  group('Beginwaarden wachtrij', () {
    test('queue is leeg bij aanmaak', () {
      expect(service.queue, isEmpty);
    });

    test('upcomingInPlaylist is leeg zonder playlist', () {
      expect(service.upcomingInPlaylist, isEmpty);
    });
  });

  group('addToQueue()', () {
    test('voegt nummer toe aan wachtrij', () {
      service.addToQueue(songs[0]);
      expect(service.queue.length, 1);
      expect(service.queue.first.id, songs[0].id);
    });

    test('meerdere nummers worden in volgorde toegevoegd', () {
      service.addToQueue(songs[0]);
      service.addToQueue(songs[1]);
      expect(service.queue[0].id, songs[0].id);
      expect(service.queue[1].id, songs[1].id);
    });

    test('zelfde nummer kan meerdere keren worden toegevoegd', () {
      service.addToQueue(songs[0]);
      service.addToQueue(songs[0]);
      expect(service.queue.length, 2);
    });
  });

  group('removeFromQueue()', () {
    test('verwijdert nummer op index 0', () {
      service.addToQueue(songs[0]);
      service.addToQueue(songs[1]);
      service.removeFromQueue(0);
      expect(service.queue.length, 1);
      expect(service.queue.first.id, songs[1].id);
    });

    test('verwijdert nummer op index 1', () {
      service.addToQueue(songs[0]);
      service.addToQueue(songs[1]);
      service.removeFromQueue(1);
      expect(service.queue.length, 1);
      expect(service.queue.first.id, songs[0].id);
    });

    test('doet niets bij ongeldige index', () {
      service.addToQueue(songs[0]);
      service.removeFromQueue(5);
      expect(service.queue.length, 1);
    });

    test('doet niets bij negatieve index', () {
      service.addToQueue(songs[0]);
      service.removeFromQueue(-1);
      expect(service.queue.length, 1);
    });
  });

  group('clearQueue()', () {
    test('leegt de wachtrij', () {
      service.addToQueue(songs[0]);
      service.addToQueue(songs[1]);
      service.clearQueue();
      expect(service.queue, isEmpty);
    });

    test('clearQueue() op lege wachtrij geeft geen fout', () {
      expect(() => service.clearQueue(), returnsNormally);
    });
  });

  group('playNext() met wachtrij', () {
    test('speelt wachtrijnummer als wachtrij niet leeg is', () async {
      await service.playSong(songs[0], songs, 0);
      service.addToQueue(songs[4]);
      await service.playNext();
      expect(service.currentSong?.id, songs[4].id);
    });

    test('wachtrij wordt in volgorde geconsumeerd', () async {
      await service.playSong(songs[0], songs, 0);
      service.addToQueue(songs[3]);
      service.addToQueue(songs[4]);
      await service.playNext();
      expect(service.currentSong?.id, songs[3].id);
      expect(service.queue.length, 1);
      expect(service.queue.first.id, songs[4].id);
    });

    test('na wachtrij gaat playlist sequentieel verder', () async {
      await service.playSong(songs[0], songs, 0);
      service.addToQueue(songs[4]);
      await service.playNext(); // wachtrij: songs[4]
      await service.playNext(); // playlist: songs[1] (index 1)
      expect(service.queue, isEmpty);
      expect(service.currentSong?.id, songs[1].id);
    });

    test('wachtrij heeft prioriteit boven shuffle', () async {
      await service.playSong(songs[0], songs, 0);
      service.toggleShuffle();
      service.addToQueue(songs[4]);
      await service.playNext();
      expect(service.currentSong?.id, songs[4].id);
    });
  });

  group('smart shuffle - alle nummers voor herhaling', () {
    test('alle nummers worden gespeeld voor herhaling', () async {
      await service.playSong(songs[0], songs, 0);
      service.toggleShuffle();

      final played = <int>{songs[0].id};
      for (var i = 0; i < songs.length - 1; i++) {
        await service.playNext();
        played.add(service.currentSong!.id);
      }
      expect(played.length, songs.length);
    });

    test('geen direct herhaling na cyclus', () async {
      await service.playSong(songs[0], songs, 0);
      service.toggleShuffle();

      for (var i = 0; i < songs.length * 2; i++) {
        final before = service.currentSong!.id;
        await service.playNext();
        expect(service.currentSong!.id, isNot(before),
            reason: 'Herhaling op iteratie $i');
      }
    });

    test('upcomingInPlaylist heeft alle resterende nummers bij shuffle', () async {
      await service.playSong(songs[0], songs, 0);
      service.toggleShuffle();
      expect(service.upcomingInPlaylist.length, songs.length - 1);
    });

    test('upcomingInPlaylist verkleint na playNext bij shuffle', () async {
      await service.playSong(songs[0], songs, 0);
      service.toggleShuffle();
      final startLen = service.upcomingInPlaylist.length;
      await service.playNext();
      expect(service.upcomingInPlaylist.length, lessThan(startLen));
    });
  });

  group('upcomingInPlaylist - sequentieel', () {
    test('geeft volgende nummers in volgorde', () async {
      await service.playSong(songs[0], songs, 0);
      final upcoming = service.upcomingInPlaylist;
      expect(upcoming.first.id, songs[1].id);
      expect(upcoming.length, songs.length - 1);
    });

    test('wrapround naar begin bij laatste nummer', () async {
      await service.playSong(songs[4], songs, 4);
      final upcoming = service.upcomingInPlaylist;
      expect(upcoming.first.id, songs[0].id);
    });

    test('leeg bij playlist met één nummer', () async {
      await service.playSong(songs[0], [songs[0]], 0);
      expect(service.upcomingInPlaylist, isEmpty);
    });
  });
}
