import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/audio_handler.dart';
import 'package:music_player_flutter/services/download_service.dart';
import 'package:music_player_flutter/services/player_service.dart';
import 'package:music_player_flutter/services/streaming_service.dart';
import 'package:music_player_flutter/screens/player_detail_screen.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockDio extends Mock implements Dio {}

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

final _testSong = Song(
  id: 1,
  title: 'Song 1',
  artist: 'Artist',
  genre: 'Pop',
  language: 'Dutch',
  year: 2024,
  duration: 180,
  audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/1.mp3',
);

StreamingService _fakeStreaming() {
  final dio = MockDio();
  when(() => dio.options).thenReturn(BaseOptions(baseUrl: 'http://test'));
  final ws = MockWebSocketChannel();
  final sink = MockWebSocketSink();
  when(() => ws.stream).thenAnswer((_) => const Stream.empty());
  when(() => ws.sink).thenReturn(sink);
  when(() => sink.add(any())).thenReturn(null);
  when(() => sink.close()).thenAnswer((_) async {});
  return StreamingService(dio, wsFactory: (_) => ws);
}

void main() {
  late MockAudioPlayer mockPlayer;
  late PlayerService playerService;
  late DownloadService downloadService;
  late StreamingService streamingService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPlayer = MockAudioPlayer();
    downloadService = DownloadService();
    streamingService = _fakeStreaming();

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
    when(() => mockPlayer.setUrl(any())).thenAnswer((_) async => null);
    when(() => mockPlayer.play()).thenAnswer((_) async {});

    final handler = MusicAudioHandler(player: mockPlayer);
    playerService = PlayerService(handler: handler);
  });

  tearDown(() => playerService.dispose());

  Widget buildScreen() => MultiProvider(
        providers: [
          ChangeNotifierProvider<DownloadService>.value(value: downloadService),
          ChangeNotifierProvider<PlayerService>.value(value: playerService),
          ChangeNotifierProvider<StreamingService>.value(value: streamingService),
        ],
        child: const MaterialApp(
          locale: Locale('nl'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: PlayerDetailScreen(),
        ),
      );

  group('PlayerDetailScreen tablet layout', () {
    testWidgets(
        'phone (400dp): single-column layout — song title near left edge',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await playerService.playSong(_testSong, [_testSong], 0);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // In _phoneBody, controls have horizontal padding of 28dp
      // so the song title starts near the left edge
      final titleDx = tester.getTopLeft(find.text('Song 1')).dx;
      expect(titleDx, lessThan(60));
    });

    testWidgets(
        'tablet (800dp): two-column layout — song title in right column',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await playerService.playSong(_testSong, [_testSong], 0);

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // In _tabletBody, controls start after 40dp padding + 340dp album art + 40dp gap
      // so the song title dx is well past the album art (~420dp)
      final titleDx = tester.getTopLeft(find.text('Song 1')).dx;
      expect(titleDx, greaterThan(300));
    });
  });
}
