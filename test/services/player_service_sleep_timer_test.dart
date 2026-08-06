import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/player_service.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockAudioPlayer mockPlayer;
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
    when(() => mockPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.idle));
    when(() => mockPlayer.setVolume(any())).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    final handler = MusicAudioHandler(player: mockPlayer);
    service = PlayerService(handler: handler);
  });

  tearDown(() => service.dispose());

  group('Beginwaarden', () {
    test('sleepTimerRemaining is null bij aanmaak', () {
      expect(service.sleepTimerRemaining, isNull);
    });
  });

  group('startSleepTimer()', () {
    test('sleepTimerRemaining wordt direct gezet', () {
      fakeAsync((async) {
        service.startSleepTimer(const Duration(seconds: 5));
        expect(service.sleepTimerRemaining, const Duration(seconds: 5));
      });
    });

    test('sleepTimerRemaining telt elke seconde af', () {
      fakeAsync((async) {
        service.startSleepTimer(const Duration(seconds: 5));
        async.elapse(const Duration(seconds: 2));
        expect(service.sleepTimerRemaining, const Duration(seconds: 3));
      });
    });

    test('pauzeert de speler zodra de timer afloopt', () {
      fakeAsync((async) {
        service.startSleepTimer(const Duration(seconds: 3));
        async.elapse(const Duration(seconds: 3));
        verify(() => mockPlayer.pause()).called(1);
      });
    });

    test('sleepTimerRemaining is null zodra de timer afloopt', () {
      fakeAsync((async) {
        service.startSleepTimer(const Duration(seconds: 3));
        async.elapse(const Duration(seconds: 3));
        expect(service.sleepTimerRemaining, isNull);
      });
    });

    test('een nieuwe timer vervangt de vorige', () {
      fakeAsync((async) {
        service.startSleepTimer(const Duration(seconds: 10));
        async.elapse(const Duration(seconds: 2));
        service.startSleepTimer(const Duration(seconds: 5));
        expect(service.sleepTimerRemaining, const Duration(seconds: 5));
        async.elapse(const Duration(seconds: 5));
        verify(() => mockPlayer.pause()).called(1);
      });
    });
  });

  group('cancelSleepTimer()', () {
    test('zet sleepTimerRemaining terug op null', () {
      fakeAsync((async) {
        service.startSleepTimer(const Duration(seconds: 5));
        service.cancelSleepTimer();
        expect(service.sleepTimerRemaining, isNull);
      });
    });

    test('pauzeert de speler niet meer na annuleren', () {
      fakeAsync((async) {
        service.startSleepTimer(const Duration(seconds: 3));
        service.cancelSleepTimer();
        async.elapse(const Duration(seconds: 5));
        verifyNever(() => mockPlayer.pause());
      });
    });
  });
}
