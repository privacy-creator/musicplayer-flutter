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
import 'package:music_player_flutter/services/liked_songs_service.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:music_player_flutter/services/recently_played_service.dart';
import 'package:music_player_flutter/services/search_history_service.dart';
import 'package:music_player_flutter/screens/songs_screen.dart';

class MockApiService extends Mock implements ApiService {}

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

  Widget buildScreen() => MultiProvider(
        providers: [
          ChangeNotifierProvider<DownloadService>.value(value: downloadService),
          ChangeNotifierProvider<LikedSongsService>.value(
              value: LikedSongsService()),
          ChangeNotifierProvider<RecentlyPlayedService>.value(
              value: RecentlyPlayedService()),
          ChangeNotifierProvider<SearchHistoryService>.value(
              value: SearchHistoryService()),
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
          home: SongsScreen(connectivityChecker: () async => true),
        ),
      );

  void stubSongs(List<Song> songs) {
    when(() => mockApi.getSongs(
          search: any(named: 'search'),
          language: any(named: 'language'),
          genre: any(named: 'genre'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => songs);
  }

  group('SongsScreen tablet grid columns', () {
    testWidgets(
        'phone (360dp): 2-column grid — Song 1 and 2 share a row, Song 3 is below',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      stubSongs([1, 2, 3, 4].map(makeSong).toList());
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final y1 = tester.getTopLeft(find.text('Song 1')).dy;
      final y2 = tester.getTopLeft(find.text('Song 2')).dy;
      final y3 = tester.getTopLeft(find.text('Song 3')).dy;

      expect(y2, closeTo(y1, 5.0)); // Song 1 and 2 in same row
      expect(y3, greaterThan(y1 + 20)); // Song 3 is in the next row
    });

    testWidgets(
        'tablet (800dp): 3-column grid — Songs 1–3 share a row, Song 4 is below',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      stubSongs([1, 2, 3, 4].map(makeSong).toList());
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final y1 = tester.getTopLeft(find.text('Song 1')).dy;
      final y2 = tester.getTopLeft(find.text('Song 2')).dy;
      final y3 = tester.getTopLeft(find.text('Song 3')).dy;
      final y4 = tester.getTopLeft(find.text('Song 4')).dy;

      expect(y2, closeTo(y1, 5.0)); // Songs 1–3 in same row
      expect(y3, closeTo(y1, 5.0));
      expect(y4, greaterThan(y1 + 20)); // Song 4 is in the next row
    });

    testWidgets(
        'large tablet (1200dp): 4-column grid — Songs 1–4 all share a row',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      stubSongs([1, 2, 3, 4].map(makeSong).toList());
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final y1 = tester.getTopLeft(find.text('Song 1')).dy;
      final y2 = tester.getTopLeft(find.text('Song 2')).dy;
      final y3 = tester.getTopLeft(find.text('Song 3')).dy;
      final y4 = tester.getTopLeft(find.text('Song 4')).dy;

      expect(y2, closeTo(y1, 5.0));
      expect(y3, closeTo(y1, 5.0));
      expect(y4, closeTo(y1, 5.0)); // All 4 songs in the same row
    });
  });
}
