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

// Drains the async event queue so unawaited futures inside PlayerService
// (like _updateHomeWidget) have time to complete before we assert.
Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final recorded = <MethodCall>[];
  late MockAudioPlayer mockPlayer;
  late PlayerService playerService;

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
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    final handler = MusicAudioHandler(player: mockPlayer);
    playerService = PlayerService(handler: handler);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
    playerService.dispose();
  });

  Iterable<MethodCall> _saves(String id) => recorded.where(
        (c) => c.method == 'saveWidgetData' && c.arguments['id'] == id,
      );

  group('PlayerService → home widget data', () {
    test('slaat titel op na playSong', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final calls = _saves('title').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], equals('Track 1'));
    });

    test('slaat artiest op na playSong', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final calls = _saves('artist').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], equals('Artist 1'));
    });

    test('slaat is_playing true op na playSong', () async {
      when(() => mockPlayer.playing).thenReturn(true);
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final calls = _saves('is_playing').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], isTrue);
    });

    test('slaat lege art_path op als imageUrl null is', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final calls = _saves('art_path').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], equals(''));
    });

    test('roept updateWidget aan na playSong', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();

      final updates =
          recorded.where((c) => c.method == 'updateWidget').toList();
      expect(updates, isNotEmpty);
      expect(updates.last.arguments['android'], equals('NowPlayingWidgetProvider'));
    });

    test('slaat is_playing false op na pauzeren', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      when(() => mockPlayer.playing).thenReturn(false);
      await playerService.togglePlayPause();
      await _pump();

      final calls = _saves('is_playing').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], isFalse);
    });

    test('roept updateWidget aan na togglePlayPause', () async {
      await playerService.playSong(_song(1), [_song(1)], 0);
      await _pump();
      recorded.clear();

      await playerService.togglePlayPause();
      await _pump();

      expect(
        recorded.where((c) => c.method == 'updateWidget'),
        isNotEmpty,
      );
    });

    test('werkt bij wisseling van nummer', () async {
      await playerService.playSong(_song(1), [_song(1), _song(2)], 0);
      await _pump();
      recorded.clear();

      await playerService.playSong(_song(2), [_song(1), _song(2)], 1);
      await _pump();

      final calls = _saves('title').toList();
      expect(calls, isNotEmpty);
      expect(calls.last.arguments['data'], equals('Track 2'));
    });

    test('gooit geen exception als het widget niet beschikbaar is', () async {
      // Simuleer een fout vanuit het platform (bijv. geen widget geïnstalleerd).
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('home_widget'),
        (call) async => throw PlatformException(code: 'error'),
      );

      // Mag nooit een exception gooien — widget-updates zijn niet-kritisch.
      await expectLater(
        playerService.playSong(_song(1), [_song(1)], 0),
        completes,
      );
      await _pump();
    });
  });
}
