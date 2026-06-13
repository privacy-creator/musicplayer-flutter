import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/api_service.dart';
import 'package:music_player_flutter/services/auth_service.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/download_service.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:music_player_flutter/screens/song_detail_screen.dart';

class MockApiService extends Mock implements ApiService {}
class MockAudioPlayer extends Mock implements AudioPlayer {}

Song _makeSong({bool withLyrics = false}) => Song(
      id: 42,
      title: 'Detail Song',
      artist: 'Cool Artist',
      genre: 'Pop',
      language: 'English',
      year: 2024,
      duration: 210,
      audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/42.mp3',
      lyrics: withLyrics ? 'Verse one\nChorus' : null,
    );

void main() {
  late MockApiService mockApi;
  late MockAudioPlayer mockPlayer;
  late PlayerService playerService;
  late DownloadService downloadService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockApi = MockApiService();
    mockPlayer = MockAudioPlayer();
    downloadService = DownloadService();

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
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});

    final handler = MusicAudioHandler(player: mockPlayer);
    playerService = PlayerService(handler: handler);
  });

  tearDown(() => playerService.dispose());

  Widget buildScreen(Song song) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DownloadService>.value(value: downloadService),
        Provider<ApiService>.value(value: mockApi),
        ChangeNotifierProvider<AuthService>(
          create: (ctx) => AuthService(ctx.read<ApiService>()),
        ),
        ChangeNotifierProvider<PlayerService>.value(value: playerService),
      ],
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: SongDetailScreen(song: song),
      ),
    );
  }

  group('SongDetailScreen — laden', () {
    testWidgets('toont laad-indicator tijdens het laden', (tester) async {
      final song = _makeSong();
      final completer = Completer<Song>();
      when(() => mockApi.getSong(any())).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(song);
      await tester.pump();
    });

    testWidgets('toont songtitel na laden', (tester) async {
      final song = _makeSong();
      when(() => mockApi.getSong(any())).thenAnswer((_) async => song);

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Detail Song'), findsWidgets);
    });

    testWidgets('toont artiest en genre info', (tester) async {
      final song = _makeSong();
      when(() => mockApi.getSong(any())).thenAnswer((_) async => song);

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Cool Artist'), findsOneWidget);
    });

    testWidgets('gebruikt widget.song als API mislukt', (tester) async {
      final song = _makeSong();
      when(() => mockApi.getSong(any())).thenThrow(Exception('offline'));

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Detail Song'), findsWidgets);
    });
  });

  group('SongDetailScreen — knoppen', () {
    testWidgets('deel-knop zichtbaar in AppBar', (tester) async {
      final song = _makeSong();
      when(() => mockApi.getSong(any())).thenAnswer((_) async => song);

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('download-knop zichtbaar in AppBar', (tester) async {
      final song = _makeSong();
      when(() => mockApi.getSong(any())).thenAnswer((_) async => song);

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    });

    testWidgets('play-knop zichtbaar', (tester) async {
      final song = _makeSong();
      when(() => mockApi.getSong(any())).thenAnswer((_) async => song);

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('wachtrij-knop zichtbaar', (tester) async {
      final song = _makeSong();
      when(() => mockApi.getSong(any())).thenAnswer((_) async => song);

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    });

  });


  group('SongDetailScreen — offline badge', () {
    testWidgets('geen offline badge als niet gedownload', (tester) async {
      final song = _makeSong();
      when(() => mockApi.getSong(any())).thenAnswer((_) async => song);

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.offline_pin), findsNothing);
    });
  });

  group('SongDetailScreen — duur', () {
    testWidgets('toont geformatteerde duur', (tester) async {
      final song = _makeSong();
      when(() => mockApi.getSong(any())).thenAnswer((_) async => song);

      await tester.pumpWidget(buildScreen(song));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3:30'), findsOneWidget);
    });
  });
}
