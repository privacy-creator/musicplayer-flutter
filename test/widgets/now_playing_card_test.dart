import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:music_player_flutter/widgets/now_playing_card.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

Song _song(int id) => Song(
      id: id,
      title: 'Track $id',
      artist: 'Artist $id',
      genre: 'Pop',
      language: 'English',
      year: 2024,
      duration: 200,
      audioUrl: 'https://example.com/$id.mp3',
    );

void main() {
  late MockAudioPlayer mockPlayer;
  late PlayerService playerService;

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
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    final handler = MusicAudioHandler(player: mockPlayer);
    playerService = PlayerService(handler: handler);
  });

  tearDown(() => playerService.dispose());

  Widget buildWidget() => ChangeNotifierProvider<PlayerService>.value(
        value: playerService,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: const Scaffold(body: NowPlayingCard()),
        ),
      );

  group('NowPlayingCard', () {
    testWidgets('is hidden when nothing is playing', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byKey(const Key('np_play_pause')), findsNothing);
      expect(find.byKey(const Key('np_progress')), findsNothing);
    });

    testWidgets('shows song title when a song is active', (tester) async {
      await playerService.playSong(_song(1), [_song(1)], 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Track 1'), findsOneWidget);
    });

    testWidgets('shows artist name when a song is active', (tester) async {
      await playerService.playSong(_song(1), [_song(1)], 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Artist 1'), findsOneWidget);
    });

    testWidgets('shows play icon when paused', (tester) async {
      when(() => mockPlayer.playing).thenReturn(false);
      await playerService.playSong(_song(1), [_song(1)], 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows pause icon when playing', (tester) async {
      when(() => mockPlayer.playing).thenReturn(true);
      await playerService.playSong(_song(1), [_song(1)], 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('shows skip_previous and skip_next buttons', (tester) async {
      await playerService.playSong(_song(1), [_song(1)], 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byKey(const Key('np_prev')), findsOneWidget);
      expect(find.byKey(const Key('np_next')), findsOneWidget);
    });

    testWidgets('shows progress indicator', (tester) async {
      await playerService.playSong(_song(1), [_song(1)], 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byKey(const Key('np_progress')), findsOneWidget);
    });

    testWidgets('tapping play/pause calls togglePlayPause', (tester) async {
      when(() => mockPlayer.playing).thenReturn(false);
      await playerService.playSong(_song(1), [_song(1)], 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byKey(const Key('np_play_pause')));
      await tester.pump();

      verify(() => mockPlayer.play()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('tapping next calls playNext', (tester) async {
      final playlist = [_song(1), _song(2)];
      await playerService.playSong(_song(1), playlist, 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.tap(find.byKey(const Key('np_next')));
      await tester.pump();

      verify(() => mockPlayer.setUrl(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('updates when song changes', (tester) async {
      await playerService.playSong(_song(1), [_song(1), _song(2)], 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Track 1'), findsOneWidget);

      await playerService.playSong(_song(2), [_song(1), _song(2)], 1);
      await tester.pump();

      expect(find.text('Track 2'), findsOneWidget);
      expect(find.text('Track 1'), findsNothing);
    });

    testWidgets('music note icon shown when no imageUrl', (tester) async {
      await playerService.playSong(_song(1), [_song(1)], 0);

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });
  });
}
