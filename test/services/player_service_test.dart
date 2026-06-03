import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late MusicAudioHandler handler;
  late PlayerService service;

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
    when(() => mockPlayer.playerState).thenReturn(
      PlayerState(false, ProcessingState.idle),
    );

    when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.seek(any())).thenAnswer((_) async {});
    when(() => mockPlayer.stop()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    handler = MusicAudioHandler(player: mockPlayer);
    service = PlayerService(handler: handler);
  });

  tearDown(() => service.dispose());

  group('Beginwaarden', () {
    test('currentSong is null bij aanmaak', () {
      expect(service.currentSong, isNull);
    });

    test('shuffleMode is false bij aanmaak', () {
      expect(service.shuffleMode, false);
    });

    test('isPlaying retourneert speler playing status', () {
      expect(service.isPlaying, false);
    });
  });

  group('toggleShuffle', () {
    test('zet shuffleMode aan', () {
      service.toggleShuffle();
      expect(service.shuffleMode, true);
    });

    test('zet shuffleMode uit wanneer al aan', () {
      service.toggleShuffle();
      service.toggleShuffle();
      expect(service.shuffleMode, false);
    });

    test('kan meerdere keren worden omgeschakeld', () {
      for (int i = 0; i < 6; i++) {
        service.toggleShuffle();
      }
      expect(service.shuffleMode, false);
    });
  });

  group('playSong', () {
    test('stelt currentSong in', () async {
      final song = makeSong(1);
      await service.playSong(song, [song], 0);
      expect(service.currentSong, song);
    });

    test('roept setUrl en play aan voor een nieuw nummer', () async {
      final song = makeSong(1);
      await service.playSong(song, [song], 0);

      verify(() => mockPlayer.setUrl(song.audioUrl)).called(1);
      verify(() => mockPlayer.play()).called(1);
    });

    test('roept togglePlayPause aan in plaats van setUrl bij hetzelfde nummer', () async {
      final song = makeSong(1);
      await service.playSong(song, [song], 0);

      clearInteractions(mockPlayer);

      await service.playSong(song, [song], 0);

      verifyNever(() => mockPlayer.setUrl(any()));
      verify(() => mockPlayer.play()).called(1);
    });

    test('laadt een ander nummer na een wissel', () async {
      final song1 = makeSong(1);
      final song2 = makeSong(2);
      final playlist = [song1, song2];

      await service.playSong(song1, playlist, 0);
      await service.playSong(song2, playlist, 1);

      expect(service.currentSong, song2);
      verify(() => mockPlayer.setUrl(song2.audioUrl)).called(1);
    });
  });

  group('playNext', () {
    test('doet niets bij lege playlist', () async {
      await service.playNext();
      expect(service.currentSong, isNull);
    });

    test('speelt het volgende nummer in de rij', () async {
      final songs = [makeSong(1), makeSong(2), makeSong(3)];
      await service.playSong(songs[0], songs, 0);

      clearInteractions(mockPlayer);
      await service.playNext();

      expect(service.currentSong?.id, 2);
    });

    test('gaat terug naar het eerste nummer aan het einde van de playlist', () async {
      final songs = [makeSong(1), makeSong(2)];
      await service.playSong(songs[1], songs, 1);

      await service.playNext();

      expect(service.currentSong?.id, 1);
    });

    test('kiest een willekeurig nummer in shuffle mode', () async {
      final songs = List.generate(10, (i) => makeSong(i + 1));
      await service.playSong(songs[0], songs, 0);
      service.toggleShuffle();

      final playedIds = <int>{};
      for (int i = 0; i < 20; i++) {
        await service.playNext();
        playedIds.add(service.currentSong!.id);
      }

      expect(playedIds.length, greaterThan(1));
    });

    test('speelt nooit hetzelfde nummer in shuffle met 2+ nummers', () async {
      final songs = [makeSong(1), makeSong(2), makeSong(3)];
      await service.playSong(songs[0], songs, 0);
      service.toggleShuffle();

      for (int i = 0; i < 10; i++) {
        final before = service.currentSong!.id;
        await service.playNext();
        expect(service.currentSong!.id, isNot(before));
      }
    });
  });

  group('playPrevious', () {
    test('doet niets bij lege playlist', () async {
      await service.playPrevious();
      expect(service.currentSong, isNull);
    });

    test('speelt het vorige nummer', () async {
      final songs = [makeSong(1), makeSong(2), makeSong(3)];
      await service.playSong(songs[2], songs, 2);

      await service.playPrevious();

      expect(service.currentSong?.id, 2);
    });

    test('gaat naar het laatste nummer wanneer op het eerste', () async {
      final songs = [makeSong(1), makeSong(2), makeSong(3)];
      await service.playSong(songs[0], songs, 0);

      await service.playPrevious();

      expect(service.currentSong?.id, 3);
    });
  });

  group('shufflePlay', () {
    test('doet niets bij lege lijst', () async {
      await service.shufflePlay([]);
      expect(service.currentSong, isNull);
    });

    test('zet shuffleMode aan', () async {
      final songs = [makeSong(1), makeSong(2)];
      await service.shufflePlay(songs);
      expect(service.shuffleMode, true);
    });

    test('start afspelen', () async {
      final songs = [makeSong(1), makeSong(2)];
      await service.shufflePlay(songs);
      expect(service.currentSong, isNotNull);
    });

    test('kiest een nummer uit de meegegeven lijst', () async {
      final songs = [makeSong(10), makeSong(20), makeSong(30)];
      await service.shufflePlay(songs);
      final ids = songs.map((s) => s.id).toSet();
      expect(ids.contains(service.currentSong!.id), true);
    });
  });

  group('seek', () {
    test('roept seek aan op de speler', () async {
      const pos = Duration(seconds: 30);
      await service.seek(pos);
      verify(() => mockPlayer.seek(pos)).called(1);
    });
  });

  group('shuffle persistentie', () {
    test('toggleShuffle slaat true op in SharedPreferences', () async {
      service.toggleShuffle();
      await Future.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('shuffle_mode'), true);
    });

    test('toggleShuffle slaat false op na twee keer omschakelen', () async {
      service.toggleShuffle();
      service.toggleShuffle();
      await Future.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('shuffle_mode'), false);
    });

    test('shufflePlay slaat shuffle aan op in SharedPreferences', () async {
      final songs = [makeSong(1), makeSong(2)];
      await service.shufflePlay(songs);
      await Future.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('shuffle_mode'), true);
    });

    test('nieuwe PlayerService laadt opgeslagen shuffle staat', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shuffle_mode', true);

      final newHandler = MusicAudioHandler(player: mockPlayer);
      final newService = PlayerService(handler: newHandler);
      await Future.delayed(Duration.zero);

      expect(newService.shuffleMode, true);
      newService.dispose();
    });

    test('nieuwe PlayerService begint met false als niets opgeslagen', () async {
      final newHandler = MusicAudioHandler(player: mockPlayer);
      final newService = PlayerService(handler: newHandler);
      await Future.delayed(Duration.zero);

      expect(newService.shuffleMode, false);
      newService.dispose();
    });
  });
}
