import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/player_service.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

Song _song(int id) => Song(
      id: id,
      title: 'Track $id',
      artist: 'Artist $id',
      genre: 'Pop',
      language: 'English',
      year: 2024,
      duration: 180,
      audioUrl: 'https://example.com/$id.mp3',
    );

// Drain the async event queue so unawaited futures (like _updateHomeWidget)
// have time to complete before asserting.
Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final recorded = <MethodCall>[];
  late MockAudioPlayer mockPlayer;
  late MusicAudioHandler handler;
  late PlayerService playerService;
  late StreamController<PlayerState> stateCtrl;

  setUp(() {
    recorded.clear();
    SharedPreferences.setMockInitialValues({});

    // Intercept all home_widget platform-channel calls.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (call) async {
        recorded.add(call);
        return true;
      },
    );

    stateCtrl = StreamController<PlayerState>.broadcast();

    mockPlayer = MockAudioPlayer();
    when(() => mockPlayer.playerStateStream)
        .thenAnswer((_) => stateCtrl.stream);
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
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.seek(any())).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    handler = MusicAudioHandler(player: mockPlayer);
    playerService = PlayerService(handler: handler);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
    await stateCtrl.close();
    playerService.dispose();
  });

  Iterable<MethodCall> saves(String id) => recorded.where(
        (c) => c.method == 'saveWidgetData' && c.arguments['id'] == id,
      );

  // ─── Bestaande data-flow tests ───────────────────────────────────────────

  group('PlayerService → home widget data', () {
    test('slaat titel op na playSong', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final calls = saves('title').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], equals('Track 1'));
    });

    test('slaat artiest op na playSong', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final calls = saves('artist').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], equals('Artist 1'));
    });

    test('slaat is_playing true op na playSong', () async {
      when(() => mockPlayer.playing).thenReturn(true);
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final calls = saves('is_playing').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], isTrue);
    });

    test('slaat lege art_path op als imageUrl null is', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final calls = saves('art_path').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], equals(''));
    });

    test('roept updateWidget aan na playSong', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final updates = recorded.where((c) => c.method == 'updateWidget').toList();
      expect(updates, isNotEmpty);
      expect(updates.last.arguments['android'], equals('NowPlayingWidgetProvider'));
    });

    test('slaat is_playing false op na pauzeren via togglePlayPause', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      when(() => mockPlayer.playing).thenReturn(false);
      await playerService.togglePlayPause();
      await _pump();

      final calls = saves('is_playing').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], isFalse);
    });

    test('roept updateWidget aan na togglePlayPause', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      await playerService.togglePlayPause();
      await _pump();

      expect(recorded.where((c) => c.method == 'updateWidget'), isNotEmpty);
    });

    test('werkt bij wisseling van nummer', () async {
      await playerService.playSong(_song(1), [_song(1), _song(2)], 0);
      await _pump();
      recorded.clear();

      await playerService.playSong(_song(2), [_song(1), _song(2)], 1);
      await _pump();

      final calls = saves('title').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], equals('Track 2'));
    });

    test('gooit geen exception als het widget niet beschikbaar is', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (call) async => throw PlatformException(code: 'error'),
      );

      await expectLater(
        playerService.playSong(_song(1), [_song(1)], 0),
        completes,
      );
      await _pump();
    });
  });

  // ─── Progressbar widget data ──────────────────────────────────────────────

  group('PlayerService → progress widget data', () {
    test('slaat position en duration op na playSong', () async {
      when(() => mockPlayer.position)
          .thenReturn(const Duration(seconds: 42));
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final positions = saves('position').toList();
      final durations = saves('duration').toList();
      expect(positions, isNotEmpty);
      expect(positions.last.arguments['data'], 42);
      expect(durations, isNotEmpty);
      // Speler kent nog geen duur → valt terug op song.duration (180).
      expect(durations.last.arguments['data'], 180);
    });

    test('gebruikt de duur van de speler wanneer die bekend is', () async {
      when(() => mockPlayer.duration)
          .thenReturn(const Duration(seconds: 200));
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final durations = saves('duration').toList();
      expect(durations, isNotEmpty);
      expect(durations.last.arguments['data'], 200);
    });

    test('seek stuurt een widget-update met nieuwe positie', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      when(() => mockPlayer.position)
          .thenReturn(const Duration(seconds: 90));
      await playerService.seek(const Duration(seconds: 90));
      await _pump();

      final positions = saves('position').toList();
      expect(positions, isNotEmpty);
      expect(positions.last.arguments['data'], 90);
      expect(recorded.where((c) => c.method == 'updateWidget'), isNotEmpty);
    });
  });

  // ─── Shuffle widget data ──────────────────────────────────────────────────

  group('PlayerService → shuffle_mode widget data', () {
    test('slaat shuffle_mode false op bij initieel playSong', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final calls = saves('shuffle_mode').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], isFalse);
    });

    test('slaat shuffle_mode true op na toggleShuffle', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      playerService.toggleShuffle();
      await _pump();

      final calls = saves('shuffle_mode').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], isTrue);
    });

    test('slaat shuffle_mode false op na dubbel toggleShuffle', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      playerService.toggleShuffle();
      await _pump();
      recorded.clear();

      playerService.toggleShuffle();
      await _pump();

      final calls = saves('shuffle_mode').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], isFalse);
    });

    test('roept updateWidget aan na toggleShuffle', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      playerService.toggleShuffle();
      await _pump();

      expect(recorded.where((c) => c.method == 'updateWidget'), isNotEmpty);
    });

    test('handler.setShuffleMode slaat shuffle_mode true op via onSetShuffle callback', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      // Simulate notification shuffle button / KEYCODE_MEDIA_SHUFFLE from the
      // home widget — both route through handler.setShuffleMode().
      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      await _pump();

      final calls = saves('shuffle_mode').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], isTrue);
      expect(playerService.shuffleMode, isTrue);
    });

    test('handler.setShuffleMode negeert identieke waarde', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      // shuffle is already false — requesting AudioServiceShuffleMode.none again
      // should not trigger a widget update.
      await handler.setShuffleMode(AudioServiceShuffleMode.none);
      await _pump();

      expect(
        recorded.where((c) => c.method == 'updateWidget'),
        isEmpty,
        reason: 'Geen widget-update als shuffle-status niet verandert',
      );
    });
  });

  // ─── Externe play/pause via playerStateStream (widget-knop fix) ──────────

  group('PlayerService → widget update via playerStateStream', () {
    test('updatet widget bij extern afspelen (bijv. widget-knop → play)', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      // Simuleer dat audio_service play() aanroept van buiten de app.
      when(() => mockPlayer.playing).thenReturn(true);
      stateCtrl.add(PlayerState(true, ProcessingState.ready));
      await _pump();

      final calls = saves('is_playing').toList();
      expect(calls, isNotEmpty, reason: 'is_playing moet worden opgeslagen');
      expect(calls.last.arguments['data'], isTrue);
      expect(recorded.where((c) => c.method == 'updateWidget'), isNotEmpty);
    });

    test('updatet widget bij externe pause (widget-knop → pause)', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      // Zet eerst op playing zodat _lastWidgetPlaying = true
      when(() => mockPlayer.playing).thenReturn(true);
      stateCtrl.add(PlayerState(true, ProcessingState.ready));
      await _pump();
      recorded.clear();

      // Simuleer externe pause.
      when(() => mockPlayer.playing).thenReturn(false);
      stateCtrl.add(PlayerState(false, ProcessingState.ready));
      await _pump();

      final calls = saves('is_playing').toList();
      expect(calls, isNotEmpty, reason: 'is_playing moet worden opgeslagen');
      expect(calls.last.arguments['data'], isFalse);
      expect(recorded.where((c) => c.method == 'updateWidget'), isNotEmpty);
    });

    test('updatet widget NIET als playing-status ongewijzigd is', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      when(() => mockPlayer.playing).thenReturn(true);
      stateCtrl.add(PlayerState(true, ProcessingState.ready));
      await _pump();
      recorded.clear();

      // Zelfde status nogmaals — mag geen update triggeren.
      stateCtrl.add(PlayerState(true, ProcessingState.ready));
      await _pump();

      expect(
        recorded.where((c) => c.method == 'updateWidget'),
        isEmpty,
        reason: 'Geen onnodige widget-updates als status niet verandert',
      );
    });

    test('updatet widget bij processingState.completed (lied afgelopen)', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      when(() => mockPlayer.playing).thenReturn(true);
      stateCtrl.add(PlayerState(true, ProcessingState.ready));
      await _pump();
      recorded.clear();

      // Lied afgelopen → playing wordt false.
      when(() => mockPlayer.playing).thenReturn(false);
      stateCtrl.add(PlayerState(false, ProcessingState.completed));
      await _pump();

      expect(recorded.where((c) => c.method == 'updateWidget'), isNotEmpty);
    });
  });
}
