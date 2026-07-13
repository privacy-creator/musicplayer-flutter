import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/models/playlist.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/screens/playlist_detail_screen.dart';
import 'package:music_player_flutter/services/api_service.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/download_service.dart';
import 'package:music_player_flutter/services/player_service.dart';

class MockApiService extends Mock implements ApiService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockDio extends Mock implements Dio {}

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

Playlist makePlaylist(List<Song> songs) => Playlist(
      id: 1,
      name: 'Mijn lijst',
      description: 'Test playlist',
      songs: songs,
    );

void main() {
  late MockApiService mockApi;
  late MockDio mockDio;
  late MockAudioPlayer mockPlayer;
  late PlayerService playerService;
  late DownloadService downloadService;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('playlist_dl_test_');
    mockApi = MockApiService();
    mockDio = MockDio();
    mockPlayer = MockAudioPlayer();
    downloadService = DownloadService(testBaseDir: tempDir.path);

    when(() => mockApi.dio).thenReturn(mockDio);

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
    playerService = PlayerService(
      handler: handler,
      downloadService: downloadService,
    );
  });

  tearDown(() async {
    playerService.dispose();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget buildScreen(Playlist playlist) {
    when(() => mockApi.getPlaylist(playlist.id))
        .thenAnswer((_) async => playlist);
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApi),
        ChangeNotifierProvider<DownloadService>.value(value: downloadService),
        ChangeNotifierProvider<PlayerService>.value(value: playerService),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void stubDownload(String url) {
    when(() => mockDio.download(
          url,
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
          deleteOnError: any(named: 'deleteOnError'),
          lengthHeader: any(named: 'lengthHeader'),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((inv) async {
      final path = inv.positionalArguments[1] as String;
      await File(path).writeAsBytes([1, 2, 3]);
      return Response(
          requestOptions: RequestOptions(path: ''), statusCode: 200);
    });
  }

  group('PlaylistDetailScreen download-alles', () {
    testWidgets('toont de download-alles knop', (tester) async {
      final playlist = makePlaylist([makeSong(1), makeSong(2)]);
      await tester.pumpWidget(buildScreen(playlist));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_for_offline_outlined), findsOneWidget);
    });

    testWidgets('geen download-alles knop bij lege playlist', (tester) async {
      final playlist = makePlaylist([]);
      await tester.pumpWidget(buildScreen(playlist));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_for_offline_outlined), findsNothing);
    });

    testWidgets('tik op de knop downloadt alle nummers', (tester) async {
      final songs = [makeSong(1), makeSong(2)];
      for (final s in songs) {
        stubDownload(s.audioUrl);
      }
      final playlist = makePlaylist(songs);
      await tester.pumpWidget(buildScreen(playlist));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.download_for_offline_outlined));
      await tester.pumpAndSettle();

      expect(downloadService.isDownloaded(1), isTrue);
      expect(downloadService.isDownloaded(2), isTrue);
    });

    testWidgets('toont vinkje wanneer alles al gedownload is', (tester) async {
      final songs = [makeSong(1), makeSong(2)];
      for (final s in songs) {
        stubDownload(s.audioUrl);
      }
      await downloadService.downloadAll(songs, mockDio);

      final playlist = makePlaylist(songs);
      await tester.pumpWidget(buildScreen(playlist));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_done), findsOneWidget);
      expect(find.byIcon(Icons.download_for_offline_outlined), findsNothing);
    });
  });

  group('PlaylistDetailScreen shuffle', () {
    testWidgets('toont de shuffle-knop', (tester) async {
      final playlist = makePlaylist([makeSong(1), makeSong(2)]);
      await tester.pumpWidget(buildScreen(playlist));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shuffle), findsOneWidget);
    });

    testWidgets('tik op shuffle start shufflePlay', (tester) async {
      final playlist = makePlaylist([makeSong(1), makeSong(2)]);
      await tester.pumpWidget(buildScreen(playlist));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.shuffle));
      await tester.pumpAndSettle();

      expect(playerService.shuffleMode, isTrue);
      expect(playerService.currentSong, isNotNull);
    });
  });
}
