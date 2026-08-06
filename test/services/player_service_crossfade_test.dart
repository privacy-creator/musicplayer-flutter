import 'dart:async';

import 'package:fake_async/fake_async.dart';
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
  late StreamController<Duration> positionController;
  late PlayerService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPlayer = MockAudioPlayer();
    positionController = StreamController<Duration>.broadcast();

    when(() => mockPlayer.playerStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => positionController.stream);
    when(() => mockPlayer.durationStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.playing).thenReturn(false);
    when(() => mockPlayer.position).thenReturn(Duration.zero);
    when(() => mockPlayer.duration).thenReturn(const Duration(seconds: 10));
    when(() => mockPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(() => mockPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.idle));
    when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.setFilePath(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.setVolume(any())).thenAnswer((_) async {});
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    final handler = MusicAudioHandler(player: mockPlayer);
    service = PlayerService(handler: handler);
  });

  tearDown(() {
    service.dispose();
    positionController.close();
  });

  group('Beginwaarden', () {
    test('crossfade staat standaard uit', () {
      expect(service.crossfadeEnabled, false);
    });

    test('standaard crossfade-duur is 4 seconden', () {
      expect(service.crossfadeSeconds, 4);
    });
  });

  group('setCrossfadeEnabled() / setCrossfadeSeconds()', () {
    test('zet crossfadeEnabled aan', () async {
      await service.setCrossfadeEnabled(true);
      expect(service.crossfadeEnabled, true);
    });

    test('zet crossfadeSeconds', () async {
      await service.setCrossfadeSeconds(8);
      expect(service.crossfadeSeconds, 8);
    });

    test('uitzetten reset het volume naar 1', () async {
      await service.setCrossfadeEnabled(true);
      await service.setCrossfadeEnabled(false);
      verify(() => mockPlayer.setVolume(1)).called(greaterThanOrEqualTo(1));
    });
  });

  // PlayerService subscribes to positionStream once, at construction time.
  // fakeAsync only fakes Timers/microtasks scheduled *within* its zone, so a
  // service built in setUp() (outside any fakeAsync zone) never gets its
  // stream-delivery microtask flushed by async.flushMicrotasks() — the
  // listener silently never fires. Building a fresh instance inside each
  // fakeAsync callback keeps construction (and thus the subscription) in
  // the faked zone.
  PlayerService buildFakeAsyncService() =>
      PlayerService(handler: MusicAudioHandler(player: mockPlayer));

  group('fade-out bij het einde van een nummer', () {
    test('verlaagt het volume geleidelijk naar 0', () {
      fakeAsync((async) {
        final fadeService = buildFakeAsyncService();
        fadeService.setCrossfadeEnabled(true);
        async.flushMicrotasks();

        positionController.add(const Duration(seconds: 7)); // nog 3s te gaan
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));

        final captured =
            verify(() => mockPlayer.setVolume(captureAny())).captured;
        expect(captured.last, closeTo(0.0, 0.01));
        fadeService.dispose();
      });
    });

    test('start niet als crossfade uit staat', () {
      fakeAsync((async) {
        final fadeService = buildFakeAsyncService();
        positionController.add(const Duration(seconds: 7));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));

        verifyNever(() => mockPlayer.setVolume(any()));
        fadeService.dispose();
      });
    });

    test('start niet zolang er meer dan crossfadeSeconds resteert', () {
      fakeAsync((async) {
        final fadeService = buildFakeAsyncService();
        fadeService.setCrossfadeEnabled(true);
        async.flushMicrotasks();

        positionController.add(const Duration(seconds: 2)); // nog 8s te gaan
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));

        verifyNever(() => mockPlayer.setVolume(any()));
        fadeService.dispose();
      });
    });
  });

  group('fade-in bij een nieuw nummer', () {
    test('begint gedempt en faded naar volledig volume', () {
      fakeAsync((async) {
        final fadeService = buildFakeAsyncService();
        fadeService.setCrossfadeEnabled(true);
        async.flushMicrotasks();

        fadeService.playSong(makeSong(1), [makeSong(1)], 0);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 4));

        final captured =
            verify(() => mockPlayer.setVolume(captureAny())).captured;
        expect(captured.first, 0.0);
        expect(captured.last, closeTo(1.0, 0.01));
        fadeService.dispose();
      });
    });

    test('blijft op vol volume als crossfade uit staat', () {
      fakeAsync((async) {
        final fadeService = buildFakeAsyncService();
        fadeService.playSong(makeSong(1), [makeSong(1)], 0);
        async.flushMicrotasks();

        verify(() => mockPlayer.setVolume(1)).called(greaterThanOrEqualTo(1));
        fadeService.dispose();
      });
    });
  });
}
